/*
  Script: CakeMechanics

  Provides various functions that simulate Kingdom of Loathing's game
  mechanics. They are intended to make decisions independent of the character
  currently being played. This allows for a script to calculate aspects of
  the game with unbuffed, buffed, or even completely altered values.
*/

// Imports
import <zlib.ash>

/*
  Function: cake_character_absorption

  Calculates the absorption rate of a given DA and returns it. 100%
  absorption would come as 1 while 0% would be 0.

  http://kol.coldfront.net/thekolwiki/index.php/Damage_Absorption
*/
float cake_character_absorption(float da)
{
	return square_root(da * 10) - 10;
}

/*
  Function: cake_character_hit

  Determines the chance that the character is capable of hitting a monster.

  Formula comes from <http://kol.coldfront.net/thekolwiki/index.php/Hit_Chance>

  Parameters:

  character_attack - The characters' attack value, which is normally their
  buffed Muscle but can be others depending on weapon and other
  bonuses.
  character_fumble - The chance a character will fumble as a number
  between 0 (no chance) and 1 (100% chance of fumble).
  character_critical - The chance a character will have a critical attack.
  This is a number between 0 (never) and 1 (every strike is a
  critical).
  monster_defense - The monster's defense value.

  Returns:

  A number where 0 means no chance, 1 is a 100% chance. It is possible
  to have higher than 1 return.
*/
float cake_character_hit(
	float character_attack,
	float character_fumble,
	float character_critical,
	float monster_defense)
{
	float base_rate = max(0, min(1, ((6 + character_attack - monster_defense) / 10.5)));
	float normal_hit_rate = base_rate;

	return normal_hit_rate;
}

/*
  Function: cake_character_hist

  Determines the chance that the character is capable of hitting a monster.

  Returns:

  A number where 0 means no chance, 1 is a 100% chance. It is possible
  to have higher than 1 return.
*/
float cake_character_hit(
	float character_attack,
	float monster_defense)
{
	return cake_character_hit(
		character_attack,
		monster_defense,
		0.045,
		0.09);
}

/*
  Function: cake_character_hist

  Determines the chance that the character is capable of hitting a monster.

  Returns:

  A number where 0 means no chance, 1 is a 100% chance. It is possible
  to have higher than 1 return.
*/
float cake_monster_hit(
	float character_defense,
	float monster_attack)
{
	float base_rate = max(0, min(1, (6.5 + (monster_attack - character_defense)) / 12));
	float critical_rate = 0.06;
	float fumble_rate = 0.06;
	float hit_rate = max(0.88, min(0, (base_rate) * (1 - (critical_rate + fumble_rate))));
	return hit_rate + critical_rate;
}

/*
  Function: cake_character_damage

  Determines the expected HP damage for a single character attack against
  an opposing monster.
*/
float cake_character_damage(
	float character_muscle,
	float character_range,
	float character_weapon,
	float character_bonus_damage,
	float monster_defense)
{
	float player_base = character_muscle * character_range;
	float damage_base = max(0, player_base - monster_defense);

	float weapon_base = 0.15 * character_weapon;
	float weapon_damage = weapon_base;

	return damage_base + weapon_damage + character_bonus_damage;
}

/*
  Function: cake_character_damage

  Determines the expected HP damage for a single character attack against
  an opposing monster.
*/
float cake_character_damage(
	float character_muscle,
	float character_weapon,
	float monster_defense)
{
	return cake_character_damage(
		character_muscle,
		1,
		character_weapon,
		0,
		monster_defense);
}

/*
  Function: cake_monster_damage

  Determines the expected damage a character will suffer from a single
  attack from the monster.
*/
float cake_monster_damage(
	float character_defense,
	float character_absorption,
	float character_reduction,
	float monster_attack)
{
	float difference = monster_attack - character_defense;
	float weapon = monster_attack * 0.225;

	float da1 = character_absorption / 10;
	float da2 = square_root(da1) - 1;
	float da3 = da2 / 10;
	float absorb = (1 - max(0, min(0.9, (da3))));

	return (difference + monster_attack - character_reduction) * absorb;
}


/*
  Section: Other Stuff
*/
// -----------------------------------------------------------------------------
// The idea of "safety" is the same as zlib's, except these libraries are
// designed to work with abstract data instead of pulling modified values from
// KoLmafia. Safe is defined as how willing a character will risk being hit.
// This is controlled by the "threshold" variable, from zlib, so a 0 threshold
// means the player is unwilling to get hit at all and 6 pretty much means
// they will always get hit.
//
// This function will return the difference in defense (i.e. moxie) from the
// safety point. For a buffed version, use zlib's get_safemox().
//
// http://kol.coldfront.net/thekolwiki/index.php/Hit_Chance
// -----------------------------------------------------------------------------

int cake_safe_threshold(
	float monster_attack)
{
	return monster_attack + 7 - to_int(vars["threshold"]);
}

int cake_how_safe(
	float character_defense,
	float monster_attack)
{
	// If the defense >= attack + 7, then there is no chance of being hit.
	// The threshold is added to the defense since higher numbers means the
	// player is more willing to be hit (and therefore is treated as having
	// that much higher defense).
	return (character_defense + to_int(vars["threshold"])) - (monster_attack + 7);
}

boolean cake_is_safe(
	float character_defense,
	float monster_attack)
{
	return cake_how_safe(character_defense, monster_attack) >= 0;
}

// -----------------------------------------------------------------------------
// Survivablity is defined as how much damage a character, in terms of
// percentage of their own hitpoints, they are willing to take in a single
// round of combat. This is controlled by the "survivable" variable which
// defaults to 0.02 or 2% of hit points.
//
// http://kol.coldfront.net/thekolwiki/index.php/Weapon_Damage
// -----------------------------------------------------------------------------

/*
  Function: cake_how_survivable

  This returns the amount of damage a single hit can inflict on the
  character. It calculates the various formulas for fumbling and
  criticals to come up with a "per round" damage.
*/
float cake_how_survivable(
	float character_defense,
	float character_absorption,
	float character_reduction,
	float character_hp,
	float monster_attack)
{
	float expected = cake_monster_damage(
		character_defense,
		character_absorption,
		character_reduction,
		monster_attack);

	float rate = cake_monster_hit(
		character_defense,
		monster_attack);

	cake_print("exp: " + expected + ", rate: " + rate + ", b: " + (expected / character_hp) + ", c: " + to_float(vars["survivable"]));

	return expected / character_hp;
}

boolean cake_is_survivable(
	float character_defense,
	float character_absorption,
	float character_reduction,
	float character_hp,
	float monster_attack)
{
	float percentage = cake_how_survivable(
		monster_attack,
		character_defense,
		character_absorption,
		character_reduction,
		character_hp);
	float survivable = to_float(vars["survivable"]);

	return percentage <= survivable;
}

// -----------------------------------------------------------------------------
// Productivity is the ability to actually hit the opponents and kill them in
// a certain number of combat rounds. This is controlled by the "productive"
// variable and is given in number of combat rounds. A combat is productive if
// the player can be expected to defeat the opponent in that many rounds or less.
// -----------------------------------------------------------------------------

float cake_how_productive(
	float character_attack,
	float character_muscle,
	float character_weapon,
	float monster_defense,
	float monster_hp)
{
	float hit = cake_character_hit(
		character_attack,
		monster_defense);
	float damage = cake_character_damage(
		character_muscle,
		character_weapon,
		monster_defense);
	float damage_per_round = hit * damage;

	return monster_hp / damage_per_round;
}

float cake_how_productive(
	float character_attack,
	float character_weapon,
	float monster_defense,
	float monster_hp)
{
	return cake_how_productive(
		character_attack,
		character_weapon,
		monster_defense,
		monster_hp);
}

boolean cake_is_productive(
	float character_attack,
	float character_weapon,
	float monster_defense,
	float monster_hp)
{
	float rounds = cake_how_productive(
		character_attack,
		character_attack,
		character_weapon,
		monster_defense,
		monster_hp);
	return rounds <= to_float(vars["productive"]);
}

// -----------------------------------------------------------------------------
// An attack or encounter is viable if it all three things: safe, survivable,
// and productive. This function determines all of these conditions at once
// and returns true if all three are true.
// -----------------------------------------------------------------------------

boolean cake_is_viable(
	float character_attack,
	float character_defense,
	float character_weapon,
	float character_absorption,
	float character_reduction,
	float character_hp,
	float monster_attack,
	float monster_defense,
	float monster_hp)
{
	boolean safe = cake_is_safe(
		character_defense,
		monster_attack);

	if (!safe) return false;

	boolean survivable = cake_is_survivable(
		character_defense,
		character_absorption,
		character_reduction,
		character_hp,
		monster_attack);

	if (!survivable) return false;

	boolean productive = cake_is_productive(
		character_attack,
		character_weapon,
		monster_defense,
		monster_hp);

	if (!productive) return false;

	return true;
}
