/*
	Script: CakeMaximize

	Provides features for maximizing equipment and gear for adventuring.
	This also implements functions for identifying the best equipment,
	via provisions, for a given location.
*/

// Imports
import <zlib.ash>
import <CakeLib.ash>
import <CakeMechanics.ash>
import <CakeProvision.ash>

/*
	Property: CAKE_MAXIMIZE_VERSION

	Contains the version of this library.
*/
int CAKE_MAXIMIZE_VERSION = 0;

/*
	Function: cake_get_provision

	Builds up the "best case" provision for a given location.
*/
boolean cake_get_provision(
	cake_provision current_provision,
	cake_location current_cake_location)
{
	// See if the location needs an outfit. If it does, then we lock the
	// provision records for those elements so we don't attempt to change them
	// later either through maximize or in script.
	boolean can_outfit = cake_provision_outfit(
		current_provision,
		current_cake_location.kolmafia_location);

	if (!can_outfit)
	{
		cake_warning("Cannot find the proper outfit for this location");
		return false;
	}

	// Figure out if we are viable.
	boolean is_safe = cake_is_safe(current_provision, current_cake_location);
	boolean is_survivable =
		cake_is_survivable(current_provision, current_cake_location);
	boolean is_productive = true;
	boolean is_viable = is_safe && is_survivable && is_productive;

	// We can "obviously" adventure here.
	if (!is_viable)
	{
		cake_warning("This location is not viable for adventuring");
	}

	return is_viable;
}

/*
	Function: main

	Shows information about the script and runs through a few examples of the
	maximize in no-op mode to give an impression of what to do.
*/
void main()
{
	// Make a bit of noise about the project.
	cake_info("CakeMaximize, a component of CakeLib (Version "
		+ CAKE_MAXIMIZE_VERSION + ")");
	cake_indent();
	cake_info("Written by cakyrespa");
	cake_info("Provides automatic outfiting, effects, and configuration "
		+ "to maximize location adventures.");
	cake_outdent();

	// We show a couple theoretical areas and provisions.
	location [int] show_locations;
	//show_locations[0] = $location[Hole in the Sky];
	//show_locations[1] = $location[Pirate Cove];
	show_locations[2] = $location[Sleazy Back Alley];
	//show_locations[3] = $location[Barrrney's Barr];
	show_locations[4] = $location[Icy Peak];

	foreach index in show_locations
	{
		// Show the user what location we are showing off.
		location current_location = show_locations[index];
		cake_print("Showing results for " + current_location + ":");
		cake_indent();

		cake_location current_cake_location =
			cake_get_location(current_location);
		cake_provision provision = cake_get_provision();
		boolean viable = cake_get_provision(provision, current_cake_location);

		// If we aren't visable, show that.
		if (viable)
		{
			cake_info("This is a viable location to adventure");
		}
		else
		{
			cake_warning("We cannot adventure in this location");
		}

		//cake_dump(provision);
		cake_info("Maximize exclusions: ML"
			+ cake_get_maximize_exclusions(provision));

		cake_print("Safe: "
			+ current_cake_location.max_attack
			+ " attack needs "
			+ cake_safe_threshold(current_cake_location.max_attack)
			+ " Moxie");
		cake_print("Safe: "
			+ cake_how_safe(provision, current_cake_location)
			+ " or "
			+ cake_is_safe(provision, current_cake_location));
		cake_print("Survive: "
			+ cake_how_survivable(provision, current_cake_location)
			+ " or "
			+ cake_is_survivable(provision, current_cake_location));
		cake_print("Productive: "
			+ cake_how_productive(provision, current_cake_location)
			+ " or "
			+ cake_is_productive(provision, current_cake_location));

		// Finish by outdenting for pretty formatting goodness.
		cake_outdent();
	}
}
