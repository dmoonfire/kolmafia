/*
  Script: CakeProvision

  Provides structures and functions to represent a character in memory. A
  provision is a combination of a character's gear, their effects, and
  familiar. It is a in-memory implementation of these settings to allow a
  script to make changes, then view the resulting effects on the character
  without actually calling the server or changing the gear. This is important
  when considering the effects of item usage or just reducing server usage.

  The general intent of the provision system is give the framework for scripts
  to make theoretical changes to a character, then determine what is the best
  or the cost to implement it, then to finally apply the changes to the
  character.

  This script provides the following:

  - The record to represent all these elements in a single object.
  - Functions to retrieve the current provision.
  - Functions for applying the provision to the character.
  - Functions for getting numerical modifiers from the provision instead of
  directly from KoLmafia.
*/

// Imports
import <zlib.ash>
import <rpn.ash>
import <CakeLib.ash>
import <CakeMechanics.ash>
import <CakeData.ash>
import <CakeModifier.ash>

/*
  Constants: Combat Frequencies

  CAKE_INCREASE_COMBAT - Indicates combat frequency should be increased.
  CAKE_NORMAL_COMBAT   - Indicates that combat frequency shouldn't change.
  CAKE_DECREASE_COMBAT - Indicated combat frequency should be decreased.
*/
int CAKE_INCREASE_COMBAT = 1;
int CAKE_NORMAL_COMBAT = 0;
int CAKE_DECREASE_COMBAT = -1;

/*
  Structure: cake_provision
*/
record cake_provision
{
	/*
	  Variable: item_slots
	  
	  Contains a map of the items for every slot for the character. If there
	  is none, $item[none] will be used.
	*/
	item [slot] item_slots;
	
	/*
	  Variable: item_locks
	  
	  Contains the locked state of the appropriate slot. If one of the values
	  is true, then the associated slot should not be changed by scripts.
	*/
	boolean [slot] item_locks;
	
	/*
	  Variable: familiar_slot
	  
	  Contains the familiar for this provision.
	*/
	familiar familiar_slot;

	/*
	  Variable: familiar_lock

	  If this is true, then scripts should not change the familiar slot.
	*/
	boolean familiar_lock;

	/*
	  Variable: effects

	  Contains the effects to activate or keep activated in the
	  provision.
	*/
	int [effect] effects;

	/*
	  Variable: remove_effects

	  Contains the effects that need to be removed. If an effect is not listed
	  in either <effects> or <remove_effects>, then it is ignored by the
	  script.
	*/
	int [effect] remove_effects;

	/*
	  Variable: has_modifier

	  This boolean flag determines if the <modifier> property is valid
	  and calculated for the current provision. If this is false, then
	  <cake_to_modifier> will generate a new modifier.
	*/
	boolean has_modifier;
	
	/*
	  Variable: modifier

	  Contains the modifier set for this provision.
	*/
	cake_modifier modifier;
};

/*
 Function: cake_to_modifier

 Get a <cake_modifier> that represents the entire provision set.
*/
cake_modifier cake_to_modifier(cake_provision provision)
{
	// If we already have a modifier, just return it.
	if (provision.has_modifier)
	{
		return provision.modifier;
	}

	// Build up a modifiers, which contains formulas for every
	// applicable element we process.
	cake_modifier modifier;

	// Get the equipment modifiers.
	foreach current_slot in $slots[]
	{
		cake_modifier next_modifier =
			cake_to_modifier(provision.item_slots[current_slot]);
		modifier = cake_add(modifier, next_modifier);
	}

	// Go through all the effects on the modifier.
	foreach current_effect in provision.effects
	{
		cake_modifier next_modifier = cake_to_modifier(current_effect);
		modifier = cake_add(modifier, next_modifier);
	}

	// Cache and return the modifier.
	provision.modifier = modifier;
	provision.has_modifier = true;
	return modifier;
}

/*
  Section: Mechanics
*/

/*
  Function: cake_character_stat

  Calculates a character stat using the given provision.
*/
float cake_character_stat(cake_provision provision, stat current_stat)
{
	cake_modifier modifier = cake_to_modifier(provision);
	string name = to_string(current_stat);
	float value = eval_rpn_character(modifier.modifiers[name]);
	return my_basestat(current_stat) + value;
}

/*
  Function: cake_character_muscle

  Calculates a character's Muscle from the given provision.
*/
int cake_character_muscle(cake_provision provision)
{
	return cake_character_stat(provision, $stat[Muscle]);
}

int cake_character_attack(cake_provision provision)
{
	// Depending on the weapon, we need to figure out the attack value.
	if (weapon_type(provision.item_slots[$slot[weapon]]) == $stat[Moxie])
	{
		// This is a ranged weapon, so it uses moxie.
		return my_basestat($stat[Moxie]);
	}

	// This is a muscle weapon, so use that.
	return my_basestat($stat[Muscle]);
}

/*
  cake_character_defense
  
  Calculates the character defense value for the given provision.
*/
int cake_character_defense(cake_provision provision)
{
	return cake_character_muscle(provision);
}

/*
  cake_character_absorption

  Calculates the damage absorption value from the given provision.
*/
int cake_character_absorption(cake_provision provision)
{
	cake_modifier modifier = cake_to_modifier(provision);
	float value = eval_rpn_character(modifier.modifiers["Damage Absorption"]);
	return cake_character_absorption(value);
}

/*
  cake_character_reduction

  Calculate the damage reduction from the given provision.

  TODO: This needs to take into account certain skills of the player.
*/
int cake_character_reduction(cake_provision provision)
{
	cake_modifier modifier = cake_to_modifier(provision);
	float value = eval_rpn_character(modifier.modifiers["Damage Absorption"]);
	return value;
}

int cake_character_hp(cake_provision provision)
{
	return my_maxhp();
}

int cake_character_weapon(cake_provision provision)
{
	return 1;
}

int cake_how_safe(
	cake_provision current_provision,
	cake_location current_location)
{
	return cake_how_safe(
		cake_character_defense(current_provision),
		current_location.max_attack);
}

boolean cake_is_safe(
	cake_provision current_provision,
	cake_location current_location)
{
	return cake_how_safe(current_provision, current_location) >= 0;
}

/*
  Function: cake_how_survivable

  This returns the amount of damage a single hit can inflict on the
  character. It calculates the various formulas from the given
  provision to come up with the "per round" damage.
*/
float cake_how_survivable(
	cake_provision current_provision,
	cake_location current_location)
{
	return cake_how_survivable(
		cake_character_defense(current_provision),
		cake_character_absorption(current_provision),
		cake_character_reduction(current_provision),
		cake_character_hp(current_provision),
		current_location.max_attack);
}

boolean cake_is_survivable(
	cake_provision current_provision,
	cake_location current_location)
{
	float percentage = cake_how_survivable(current_provision, current_location);
	float survivable = to_float(vars["survivable"]);
	return percentage <= survivable;
}

float cake_how_productive(
	cake_provision current_provision,
	cake_location current_location)
{
	return cake_how_productive(
		cake_character_attack(current_provision),
		cake_character_muscle(current_provision),
		cake_character_weapon(current_provision),
		current_location.max_defense,
		current_location.max_hp);
}

boolean cake_is_productive(
	cake_provision current_provision,
	cake_location current_location)
{
	float rounds = cake_how_productive(current_provision, current_location);
	return rounds <= to_float(vars["productive"]);
}

/*
  Section: Functions
*/

/*
  Function: cake_current_provision

  Build a provision record from the character's current gear, effects, and
  familiar.

  Returns:

  A cake_provision record that represents the character's gear and
  effects.
*/
cake_provision cake_get_provision()
{
	// Create a provision to populate.
	cake_provision provision;

	// Populate the current provision with the equipment slots.
	provision.item_slots[$slot[hat]]      = equipped_item($slot[hat]);
	provision.item_slots[$slot[weapon]]   = equipped_item($slot[weapon]);
	provision.item_slots[$slot[off-hand]] = equipped_item($slot[off-hand]);
	provision.item_slots[$slot[shirt]]    = equipped_item($slot[shirt]);
	provision.item_slots[$slot[pants]]    = equipped_item($slot[pants]);
	provision.item_slots[$slot[acc1]]     = equipped_item($slot[acc1]);
	provision.item_slots[$slot[acc2]]     = equipped_item($slot[acc2]);
	provision.item_slots[$slot[acc3]]     = equipped_item($slot[acc3]);
	provision.item_slots[$slot[familiar]] = equipped_item($slot[familiar]);

	// Grab the current effects from the provision.
	provision.effects = cake_get_current_effects();

	// Grab the current familiar. If we are in a 100% familiar run, just
	// lock out the familiar slot right away.
	provision.familiar_slot = my_familiar();

	if (to_boolean(vars["is_100_run"]))
	{
		provision.familiar_lock = true;
	}

	// Return the resulting, populated provision record.
	return provision;
}

/*
  Function: cake_get_maximize_exclusions
	
  This returns a formatted string with the exclusions from the provision's
  locked slots. For example, if hat and acc1 are locked, it will return
  "-hat, -acc1" to have them excluded from the `maximize` line. If there
  is at least one exclusion, it will be started with a comma (",").
*/
string cake_get_maximize_exclusions(
	cake_provision provision)
{
	// Build up a string of exclusions based on provision locks.
	string exclusion = "";

	if (provision.item_locks[$slot[hat]])
		exclusion = exclusion + ",-hat";
	if (provision.item_locks[$slot[weapon]])
		exclusion = exclusion + ",-weapon";
	if (provision.item_locks[$slot[off-hand]])
		exclusion = exclusion + ",-offhand";
	if (provision.item_locks[$slot[shirt]])
		exclusion = exclusion + ",-shirt";
	if (provision.item_locks[$slot[pants]])
		exclusion = exclusion + ",-pants";
	if (provision.item_locks[$slot[acc1]])
		exclusion = exclusion + ",-acc1";
	if (provision.item_locks[$slot[acc2]])
		exclusion = exclusion + ",-acc2";
	if (provision.item_locks[$slot[acc3]])
		exclusion = exclusion + ",-acc3";

	// Return the resulting exclusion string.
	return exclusion;
}

/*
  Function: cake_remove_conflicting_effects
	
  This removes anything that would conflict with +combat, such as -combat
  effects. This doesn't actually remove it but adds those effects to the
  effects_to_remove list.

  This only supports +combat, -combat at the moment.
*/
void cake_remove_conflicting_effects(
	cake_provision provision,
	int combat_frequency)
{
	// If we are a zero frequency, don't do anything.
	if (combat_frequency == CAKE_NORMAL_COMBAT)
		return;

	// Go through all the effects and look for ones that are conflicting with
	// the combat frequency.
	foreach current_effect in provision.effects
	{
		float combat_rate = numeric_modifier(current_effect, "Combat Rate");

		if ((combat_frequency < 0 && combat_rate > 0) ||
			(combat_frequency > 0 && combat_rate < 0))
		{
			// This is the opposite of what we want, so mark it to be
			// shrug it off.
			provision.remove_effects[current_effect] = 1;
			remove provision.effects[current_effect];
		}
	}
}

/*
  Function: cake_provision_outfit_accessor
*/
boolean cake_provision_outfit_accessory(
	cake_provision provision,
	item current_item)
{
	// See if we already have it equipped, if we do, lock the slot and continue.
	if (provision.item_slots[$slot[acc1]] == current_item)
	{
		provision.item_locks[$slot[acc1]] = true;
		return true;
	}

	if (provision.item_slots[$slot[acc2]] == current_item)
	{
		provision.item_locks[$slot[acc2]] = true;
		return true;
	}

	if (provision.item_slots[$slot[acc3]] == current_item)
	{
		provision.item_locks[$slot[acc3]] = true;
		return true;
	}

	// See if we actually have the item.
	if (item_amount(current_item) == 0)
	{
		return false;
	}

	// Try to see if we can assign the slot.
	if (!provision.item_locks[$slot[acc1]])
	{
		provision.item_slots[$slot[acc1]] = current_item;
		provision.item_locks[$slot[acc1]] = true;
		return true;
	}

	if (!provision.item_locks[$slot[acc2]])
	{
		provision.item_slots[$slot[acc2]] = current_item;
		provision.item_locks[$slot[acc2]] = true;
		return true;
	}

	if (!provision.item_locks[$slot[acc3]])
	{
		provision.item_slots[$slot[acc3]] = current_item;
		provision.item_locks[$slot[acc3]] = true;
		return true;
	}

	// We can't equip the item.
	return false;
}

/*
  Function: cake_provision_pirate_outfit

  Marks the provision record to wear the best pirate outfit. If the player
  has fledges, it uses that, otherwise it attempts to wear the full outfit.
  If one cannot be worn, then it returns false. Any slot picked will be locked
  to indicate it should not be considered. If the player already has an item
  equipped, this just locks the slot without moving it around.
*/
boolean cake_provision_pirate_outfit(
	cake_provision provision)
{
	// See if we have the pirate fledges, and equip them if possible.
	if (cake_provision_outfit_accessory(provision, $item[pirate fledges]))
	{
		return true;
	}

	// See if we have the components of the swashbuckling outfit.
	item eyepatch = $item[eyepatch];
	item pants = $item[swashbuckling pants];
	item parrot = $item[stuffed shoulder parrot];

	boolean using_eyepatch = (provision.item_slots[$slot[hat]] == eyepatch);
	boolean has_eyepatch = item_amount(eyepatch) > 0;
	boolean got_eyepatch = using_eyepatch || has_eyepatch;

	boolean using_pants = (provision.item_slots[$slot[pants]] == pants);
	boolean has_pants = item_amount(pants) > 0;
	boolean got_pants = using_pants || has_pants;

	boolean using_parrot =
		(provision.item_slots[$slot[acc1]] == parrot) ||
		(provision.item_slots[$slot[acc2]] == parrot) ||
		(provision.item_slots[$slot[acc3]] == parrot);
	boolean has_parrot = item_amount(parrot) > 0;
	boolean got_parrot = using_parrot || has_parrot;

	// If we don't have all three components, then just drop out.
	if (!got_eyepatch || !got_pants || !got_parrot)
	{
		return false;
	}

	// Now make sure we have the equipment in place and locked.
	provision.item_slots[$slot[hat]] = eyepatch;
	provision.item_locks[$slot[hat]] = true;
	provision.item_slots[$slot[pants]] = pants;
	provision.item_locks[$slot[pants]] = true;
	cake_provision_outfit_accessory(provision, parrot);

	// We have to mark the provision as not having a modifier since we
	// changed the equipment set on the user.
	provision.has_modifier = false;

	// We have successfully changed their outfit. Well, we don't know
	// for sure but we assume it all worked.
	return true;
}

/*
  Function: cake_provision_outfit
	
  Applies any outfit or equipment needed to adventure in a specific location.
  The provision record slots will be locked for an outfit needed, but this
  won't unlock a slot.
*/
boolean cake_provision_outfit(
	cake_provision provision,
	location loc)
{
	// Check to see if we are a known location.
	cake_location cake_loc = cake_get_location(loc);

	if (cake_loc.location_type == "pirate")
	{
		return cake_provision_pirate_outfit(provision);
	}

	// We haven't encountered anything that says we can't, so stop.
	return true;
}

/*
  Section: Debugging
*/

/*
  Function: cake_dump

  Dumps out a given modifier from the modifier set.
*/
void cake_dump_stat(cake_modifier modifier, stat current_stat)
{
	// Show the calculated values of the modifier.
	string name = to_string(current_stat);
	float value = eval_rpn_character(modifier.modifiers[name]);

	cake_info(current_stat
		+ ": base "
		+ my_basestat(current_stat)
		+ " + "
		+ value
		+ " => "
		+ (my_basestat(current_stat) + value)
		+ " (actual "
		+ my_buffedstat(current_stat)
		+ ")");

	// Show the formula itself.
	cake_indent();
	cake_info(modifier.modifiers[name]);
	cake_outdent();
}

/*
  Function: cake_dump

  Dumps out the provision to <cake_info>, including all effects and equipment.
  This does not produce a header, but uses <cake_indent> to indent the various
  output.
*/
void cake_dump(cake_provision provision)
{
	// Show the familiar...
	cake_info("Familiar: " + provision.familiar_slot
		+ " - Locked? " + provision.familiar_lock);

	// Show the equipment slots...
	cake_info("Slots");
	cake_indent();

	foreach current_slot in $slots[]
	{
		if (provision.item_slots[current_slot] == $item[none])
			continue;

		cake_info(current_slot + ": " + provision.item_slots[current_slot]
			+ " - Locked? " + provision.item_locks[current_slot]);
	}

	cake_outdent();

	// Show the effects...
	cake_info("Effects");
	cake_indent();

	foreach current_effect in provision.effects
	{
		cake_info("Add " + current_effect
			+ " " + provision.effects[current_effect]);
	}

	foreach current_effect in provision.remove_effects
	{
		cake_info("Rem " + current_effect);
	}

	cake_outdent();

	// Show the final results of this provision. For the current
	// provision should roughly (i.e. identically) produce the same
	// values as KoLmafia.
	cake_modifier modifier = cake_to_modifier(provision);

	cake_info("Results");
	cake_indent();

	cake_dump_stat(modifier, $stat[Muscle]);
	cake_dump_stat(modifier, $stat[Moxie]);
	cake_dump_stat(modifier, $stat[Mysticality]);

	cake_outdent();
}

/*
  Function: main

  Reports information about the CakeProvision library and performs a short
  sanity check/example on the system.
*/
void main()
{
	// Get the current provision.
	cake_provision provision = cake_get_provision();
	cake_dump(provision);
}
