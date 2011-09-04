/*
	Script: CakeData

	Contains the data loading and retrieval routines for the web-accessible
	data files for Cake.
*/

// Imports
import <zlib.ash>

/*
	Structure: cake_location
*/
record cake_location
{
	float combat_rate;
	string location_type;
	string maximize_hint;
	float combat_meat;
	float combat_stats;
	float average_hp;
	float max_hp;
	float average_defense;
	float max_defense;
	float average_attack;
	float max_attack;
	string noncombat_mus;
	string noncombat_mox;
	string noncombat_mys;
	string noncombat_meat;
	string clover_mus;
	string clover_mox;
	string clover_mys;
	string clover_meat;

	location kolmafia_location;
};

/*
	Section: Data Variables and Functions
*/

/*
	Variable: cake_effect_modifiers_cache

	Contains a map of overridden formulas for effects. This is keyed off the
	effect and modifier name.
*/
string [effect, string] cake_effect_modifiers_cache;

/*
	Variable: cake_item_modifiers_cache

	Contains a map of overridden formulas for items. This is keyed off the
	item and modifier name.
*/
string [item, string] cake_item_modifiers_cache;

/*
	Variable: cake_locations_cache

	Contains the location data loaded into memory.
*/
cake_location [string] cake_locations_cache;

/*
	Function: cake_can_load_maps

	This returns true if the data library can download the maps automatically
	from the Subversion server. This can be set by changing the zlib variable
	"cake_map_downloads" to false. Calling this script directly will force the
	download of the map file.
*/
boolean cake_can_load_maps()
{
	return to_boolean(vars["cake_map_downloads"]);
}

// This controls if map files could be downloaded from the server.
setvar("cake_map_downloads", true);

/*
	Function: cake_load_effect_modifiers_cache

	Ensures that the cake_effect_modifiers_cache is populated from the map
	in the data directory. This will, if it is the first time in a session,
	attempt to download from the server to update it.
*/
void cake_load_effect_modifiers_cache()
{
	// See if we already loaded the map. If we have, then don't bother.
	if (count(cake_effect_modifiers_cache) > 0)
		return;

	// See if we can download the map from the server.
	if (cake_can_load_maps())
	{
		cake_info("Downloading effect modifiers into memory");
		file_to_map(
			"http://svn.mfgames.com/KoLmafia/data/"
			+ "cake_effect_modifiers_000.txt",
			cake_effect_modifiers_cache);
		map_to_file(
			cake_effect_modifiers_cache,
			"cake_effect_modifiers.txt");
		return;
	}

	// Simply load the cache from the local data directory.
	cake_info("Loading cake modifiers into memory");
	file_to_map(
		"cake_effect_modifiers.txt",
		cake_effect_modifiers_cache);
	return;
}

/*
	Function: cake_load_item_modifiers_cache

	Ensures that the cake_item_modifiers_cache is populated from the map
	in the data directory. This will, if it is the first time in a session,
	attempt to download from the server to update it.
*/
void cake_load_item_modifiers_cache()
{
	// See if we already loaded the map. If we have, then don't bother.
	if (count(cake_item_modifiers_cache) > 0)
		return;

	// See if we can download the map from the server.
	if (cake_can_load_maps())
	{
		file_to_map(
			"http://svn.mfgames.com/KoLmafia/data/"
			+ "cake_item_modifiers_000.txt",
			cake_item_modifiers_cache);
		map_to_file(
			cake_item_modifiers_cache,
			"cake_item_modifiers.txt");
		return;
	}

	// Simply load the cache from the local data directory.
	file_to_map(
		"cake_item_modifiers.txt",
		cake_item_modifiers_cache);
	return;
}

/*
	Section: Locations
*/

/*
	Function: cake_load_locations_cache

	Ensures the cake location data is loaded into memory and potentially
	download from the server.
*/
void cake_load_locations_cache()
{
	// See if we already loaded the map. If we have, then don't bother.
	if (count(cake_locations_cache) > 0)
		return;

	// See if we can download the map from the server.
	if (cake_can_load_maps())
	{
		cake_info("Downloading location data");
		file_to_map(
			"http://svn.mfgames.com/KoLmafia/data/"
			+ "cake_locations_000.txt",
			cake_locations_cache);
		map_to_file(
			cake_locations_cache,
			"cake_locations.txt");
	}
	else
	{
		// Simply load the cache from the local data directory.
		cake_info("Loading location data into memory");
		file_to_map(
			"cake_locations.txt",
			cake_locations_cache);
	}

	// Associate the actual records with the locations.
	foreach location_name in cake_locations_cache
	{
		cake_locations_cache[location_name].kolmafia_location =
			to_location(location_name);
	}
}

/*
	Function: cake_get_location

	Returns the <cake_location> record for the given location.
*/
cake_location cake_get_location(string current_location)
{
	// Load the cache, to make sure we have it.
	cake_load_locations_cache();

	// Grab the appropriate location.
	return cake_locations_cache[current_location];
}

/*
	Function: cake_get_location

	Returns the <cake_location> record for the given location.
*/
cake_location cake_get_location(location current_location)
{
	return cake_get_location(to_string(current_location));
}
