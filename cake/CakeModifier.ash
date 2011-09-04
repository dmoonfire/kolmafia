/*
  Script: CakeModifier

  Provides records and functions for gathering modifiers and placing them into
  a simplified object for calculations and integration. Items, effects, and
  equipment can all be used with these modifiers.
*/

// Imports
import <rpn.ash>
import <CakeData.ash>

/*
  Structure: cake_modifier

  The cake modifier uses the same key as the numerical_modifier() built into
  KoLmafia, but provides for RPN formulas to calculate the values.

  There are some modifiers that are modified by this. "Muscle" and "Muscle
  Percent" will be consolidated down to a single "Muscle" formula.
*/
record cake_modifier
{
	/*
	  Variable: modifiers

	  Contains a map of numerical modifiers and a RPN formula to calculate
	  the result of that modifier.
	*/
	string[string] modifiers;
};

/*
  Section: Loading and Caching
*/

string [int] cake_modifier_names;
cake_append(cake_modifier_names, "Monster Level");
cake_append(cake_modifier_names, "Muscle");
cake_append(cake_modifier_names, "Moxie");
cake_append(cake_modifier_names, "Mysticality");
cake_append(cake_modifier_names, "Monster Level");
cake_append(cake_modifier_names, "Damage Absorption");
cake_append(cake_modifier_names, "Damage Reduction");

/*
  Variable: cake_effect_modifiers

  A global variable used to contain all the loaded modifiers for a given
  effect.
*/
cake_modifier [effect] cake_effect_modifiers;

/*
  Variable: cake_item_modifiers

  A global variable used to contain all the calculated or loaded modifiers
  for items.
*/
cake_modifier [item] cake_item_modifiers;

/*
  Function: cake_get_modifier_formula

  Takes the constant modifier to an attribute and the percentage change
  and generates a simplified RPN formula for the modifier.
*/
string cake_get_modifier_formula(
	string modifier_name,
	float constant_value,
	float percent_value)
{
	// Adjust the percent value from the 0...100 range to 0...1 range
	// which works properly with numbers.
	percent_value = percent_value / 100;

	// If we don't have a percent modifier, then just add the
	// constant. Otherwise, add the formula for this element.
	if (percent_value == 0)
	{
		return to_string(constant_value);
	}

	if (constant_value == 0)
	{
		return to_lower_case(modifier_name) + " " +
			percent_value + " * ";
	}

	return constant_value + " " +
		to_lower_case(modifier_name) + " " +
		percent_value + " * +";
}

/*
  Function: cake_to_modifier

  Builds up a <cake_modifier> record for a given effect.
*/
cake_modifier cake_to_modifier(effect current_effect)
{
	// Make sure we have our data elements loaded.
	cake_load_effect_modifiers_cache();

	// Create a modifier set and go through all the numerical names for the
	// modifiers we choose to keep.
	cake_modifier modifier;

	foreach modifier_name_index in cake_modifier_names
	{
		// Get the modifier name, this is the same name that numeric_modifier()
		// uses.
		string modifier_name = cake_modifier_names[modifier_name_index];

		// See if we have an overriden formula from our own data.
		if (cake_effect_modifiers_cache[current_effect] contains modifier_name)
		{
			modifier.modifiers[modifier_name] =
				cake_effect_modifiers_cache[current_effect, modifier_name];
		}

		// We do special processing for the three attributes.
		if (modifier_name == "Muscle" ||
			modifier_name == "Moxie" ||
			modifier_name == "Mysticality")
		{
			// Grab the values from the numerical modifiers and format them
			// into a proper RPN formula.
			float constant = numeric_modifier(current_effect, modifier_name);
			float percent =
				numeric_modifier(current_effect, modifier_name + " Percent");

			modifier.modifiers[modifier_name] =
				cake_get_modifier_formula(modifier_name, constant, percent);
		}
		else
		{
			// We aren't doing anything special, so just grab it.
			modifier.modifiers[modifier_name] =
				to_string(numeric_modifier(current_effect, modifier_name));
		}
	}

	// Return the populated results.
	return modifier;
}

/*
  Function: cake_to_modifier

  Builds up a <cake_modifier> record for a given item.
*/
cake_modifier cake_to_modifier(item current_item)
{
	// Make sure we have our data elements loaded.
	cake_load_item_modifiers_cache();

	// Create a modifier set and go through all the numerical names for the
	// modifiers we choose to keep.
	cake_modifier modifier;

	foreach modifier_name_index in cake_modifier_names
	{
		// Get the modifier name, this is the same name that numeric_modifier()
		// uses.
		string modifier_name = cake_modifier_names[modifier_name_index];

		// See if we have an overriden formula from our own data.
		if (cake_item_modifiers_cache[current_item] contains modifier_name)
		{
			modifier.modifiers[modifier_name] =
				cake_item_modifiers_cache[current_item, modifier_name];
		}

		// We do special processing for the three attributes.
		if (modifier_name == "Muscle" ||
			modifier_name == "Moxie" ||
			modifier_name == "Mysticality")
		{
			// Grab the values from the numerical modifiers and format them
			// into a proper RPN formula.
			float constant = numeric_modifier(current_item, modifier_name);
			float percent =
				numeric_modifier(current_item, modifier_name + " Percent");

			modifier.modifiers[modifier_name] =
				cake_get_modifier_formula(modifier_name, constant, percent);
		}
		else
		{
			// We aren't doing anything special, so just grab it. This is a
			// numerical, so it will translate directly into something we can
			// use in a RPN string.
			modifier.modifiers[modifier_name] =
				to_string(numeric_modifier(current_item, modifier_name));
		}
	}

	// Return the populated results.
	return modifier;
}

/*
  Function: cake_add

  Adds two modifiers together and returns the results.
*/
cake_modifier cake_add(cake_modifier modifier1, cake_modifier modifier2)
{
	cake_modifier modifier3;

	foreach modifier_name_index in cake_modifier_names
	{
		// Get the formulas for the modifiers.
		string name = cake_modifier_names[modifier_name_index];
		string formula1 = modifier1.modifiers[name];
		string formula2 = modifier2.modifiers[name];

		// Add the formulas. We use the RPN formula because it has a
		// bit of intelligence and keeps the formula as clean as
		// possible.
		//print("ccc: " + formula2);
		//print("bbb: " + formula1);
		//print("aaa: " + rpn_add(formula1, formula2));
		modifier3.modifiers[name] = rpn_add(formula1, formula2);
	}

	return modifier3;
}
