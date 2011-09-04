#!/usr/bin/perl

#
# DownloadLocationWikiPages.pl 0.0.0
#

#
# Variables
#

# The path to where wikipediafs mounts the KoL wiki.
my $wiki_path = "/media/wiki/kol";

# Working variables. The word "events" is used instead of adventures or choices
# which is the terminology on the wiki. This is because adventures already has
# meaning within KoLmafia.
my %noncombats = ();
my @noncombats_headers = ();
my %events = ();
my @events_headers = ();

# Mappings of filenames.
my %mappings = (
	"Dungeons of Doom" => "Dungeons_of_doom.mw",
	"Knob Goblin Treasury" => "Treasury.mw",
	"Hidden Temple" => "The_Hidden_Temple.mw",
	"8-Bit Realm" => "The_Inexplicable_Door.mw",
	"Greater-Than Sign" => "The_Enormous_Greater-Than_Sign.mw",
	"Haunted Wine Cellar (automatic)" => "Wine_Racks.mw",
	"Haunted Wine Cellar (Northwest)" => "Wine_Racks.mw",
	"Haunted Wine Cellar (Northeast)" => "Wine_Racks.mw",
	"Haunted Wine Cellar (Southwest)" => "Wine_Racks.mw",
	"Haunted Wine Cellar (Southeast)" => "Wine_Racks.mw",
	"F'c'le" => "The_F%27c%27le.mw",
	"Oasis in the Desert" => "Oasis.mw",
	"Desert (Unhydrated)" => "The_Arid%2C_Extra-Dry_Desert.mw",
	"Desert (Ultrahydrated)" => "The_Arid%2C_Extra-Dry_Desert.mw",
	"Grim Grimacite Site" => "Grim_grimacite_site.mw",
	"Goat Party" => "Goat_party.mw",
	"Pirate Party" => "Pirate_party.mw",
	"Lemon Party" => "Lemon_party.mw",
	"Roulette Tables" => "Roulette_tables.mw",
	"Poker Room" => "Poker_room.mw",
	"Haiku Dungeon" => "Haiku_dungeon.mw",
	"Unlucky Sewer" => "The_Sewer.mw",
	"Sewer With Clovers" => "The_Sewer.mw",
	"Sleazy Back Alley" => "Sleazy_back_alley.mw",
	"Haunted Pantry" => "Haunted_pantry.mw",
	"Haunted Kitchen" => "Haunted_kitchen.mw",
	"Haunted Conservatory" => "Haunted_conservatory.mw",
	"Haunted Library" => "Haunted_library.mw",
	"Haunted Billiards Room" => "Haunted_billards_room.mw",
	"Haunted Bathroom" => "Haunted_bathroom.mw",
	"Hidden City" => "Hidden_city.mw",
	"Friar's Gate" => "The_Deep_Fat_Friars\\'_Gate.mw",
	"Black Forest" => "Black_forest.mw",
	"Bat Hole Entryway" => "Bat_hole.mw",
	"Boss Bat's Lair" => "The_Boss_Bat\\'s_Lair.mw",
	"Battlefield (No Uniform)" => "A_Battlefield.mw",
	"Battlefield (Cloaca Uniform)" => "A_Battlefield.mw",
	"Battlefield (Dyspepsi Uniform)" => "A_Battlefield.mw",
	"Fun House" => "Fun_house.mw",
	"Pre-Cyrpt Cemetary" => "The_Misspelled_Cemetary_\\(Pre-Cyrpt\\).mw",
	"Post-Cyrpt Cemetary" => "The_Misspelled_Cemetary_\\(Post-Cyrpt\\).mw",
	"Fernswarthy's Ruins" => "The_Ruins_of_Fernswarthy\\'s_Tower.mw",
	"Outskirts of The Knob" => "Outskirts_of_Cobb\\'s_Knob.mw",
	"Knob Goblin Kitchens" => "Kitchens.mw",
	"Knob Goblin Treasury" => "Treasury.mw",
	"Knob Goblin Harem" => "Harem.mw",
	"Dark Heart of the Woods" => "The_Dark_Heart_of_the_Woods.mw",
	"Dark Elbow of the Woods" => "The_Dark_Elbow_of_the_Woods.mw",
	"Friar Ceremony Location" => "Talk_to_the_Deep_Fat_Friars.mw",
	"Defiled Nook" => "Defiled_nook.mw",
	"Defiled Cranny" => "Defiled_cranny.mw",
	"Defiled Alcove" => "Defiled_alcove.mw",
	"Defiled Niche" => "Defiled_niche.mw",
	"Haert of the Cyrpt" => "Haert_of_the_cyrpt.mw",
	"Frat House" => "Frat_house.mw",
	"Frat House In Disguise" => "Orcish_Frat_House.mw",
	"Frat House (Stone Age)" => "The_Orcish_Frat_House_\\(Bombed_Back_to_the_Stone_Age\\).mw",
	"Hippy Camp In Disguise" => "The_Hippy_Camp.mw",
	"Hippy Camp (Stone Age)" => "The_Hippy_Camp_\\(Bombed_Back_to_the_Stone_Age\\).mw",
	"Pirate Cove" => "Pirate_cove.mw",
	"Poop Deck" => "Poop_deck.mw",
	"Post-War Junkyard" => "The_Junkyard_\\(Post-War\\).mw",
	"Post-War Sonofa Beach" => "Sonofa_Beach.mw",
	"Battlefield (Frat Uniform)" => "The_Battlefield_\\(Frat_Warrior_Fatigues\\).mw",
	"Battlefield (Hippy Uniform)" => "The_Battlefield_\\(War_Hippy_Fatigues\\).mw",
	"Wartime Frat House" => "Orcish_Frat_House_\\(Verge_of_War\\).mw",
	"Wartime Frat House (Hippy Disguise)" => "Orcish_Frat_House_\\(Verge_of_War\\).mw",
	"Wartime Hippy Camp" => "The_Hippy_Camp_\\(Verge_of_War\\).mw",
	"Wartime Hippy Camp (Frat Disguise)" => "The_Hippy_Camp_\\(Verge_of_War\\).mw",
	"Wartime Sonofa Beach" => "The_Mysterious_Island_of_Mystery_\\(Wartime\\).mw",
	"Themthar Hills" => "Themthar_hills.mw",
	"Pond" => "The_Pond.mw",
	"Back 40" => "The_Back_40.mw",
	"Other Back 40" => "The_Other_Back_40.mw",
	"Granary" => "The_Granary.mw",
	"Bog" => "The_Bog.mw",
	"Family Plot" => "The_Family_Plot.mw",
	"Shady Thicket" => "Shady_thicket.mw",
	"Hatching Chamber" => "The_Hatching_Chamber.mw",
	"Feeding Chamber" => "The_Feeding_Chamber.mw",
	"Guards' Chamber" => "The_Guards\\'_Chamber.mw",
	"Queen's Chamber" => "The_Queen\\'s_Chamber.mw",
	"Noob Cave" => "Noob_cave.mw",
	"Dire Warren" => "Dire_warren.mw",
	"Orc Chasm" => "Orc_chasm.mw",
	"Ninja Snowmen" => "Ninja_snowmen.mw",
	"eXtreme Slope" => "Extreme_slope.mw",
	"Mine Foremens' Office" => "The_Mine_Foremens\\'_Office.mw",
	"Fantasy Airship" => "Fantasy_airship.mw",
	"Giant's Castle" => "The_Castle_in_the_Clouds_in_the_Sky.mw",
	"Sorceress' Hedge Maze" => "The_Hedge_Maze.mw",
	"Spooky Gravy Barrow" => "Spooky_gravy_barrow.mw",
	"Post-Quest Bugbear Pens" => "Bugbear_Pens.mw",
	"Outskirts of Camp" => "Outskirts_of_camp.mw",
	"Astral Mushroom (Bad Trip)" => "Bad_Trip.mw",
	"Astral Mushroom (Mediocre Trip)" => "Mediocre_Trip.mw",
	"Astral Mushroom (Great Trip)" => "Great_Trip.mw",
	"Mouldering Mansion" => "Mouldering_mansion.mw",
	"Rogue Windmill" => "Rogue_windmill.mw",
	"Yuletide Bonfire" => "A_Yuletide_Bonfire.mw",
	"Spectral Pickle Factory" => "Spectral_pickle_factory.mw",
	"Spectral Salad Factory" => "The_Spectral_Salad_Factory.mw",
	"Atomic Crimbo Toy Factory" => "The_Atomic_Crimbo_Toy_Factory.mw",
	"Spooky Fright Factory" => "The_Spooky_Fright_Factory.mw",
	"Future Market Square" => "",
	"Mall of the Future" => "",
	"Future Wrong Side of the Tracks" => "",
	"Icy Peak of the Past" => "The_Icy_Peak_in_The_Recent_Past.mw",
);

#
# Go through the input locations. This will pull the data down from the wiki.
#

if (@ARGV == 1)
{
	if (-f $ARGV[0])
	{
		info(0, "Reading in data from file: $ARGV[0]");

		open INPUT, "<$ARGV[0]" or die "Cannot open $ARGV[0]";
		@ARGV = ();

		while (<INPUT>)
		{
			chomp;
			next if /^\s*$/;
			next if /^\#/;
			push @ARGV, $_;
		}

		close INPUT;
		info(1, "Read in " . scalar(@ARGV) . " locations.");
	}
}

while (@ARGV)
{
	# Grab the next location name.
	my $location_name = shift @ARGV;
	#info(0, "Processing '$location_name'");

	# Figure out the names including the initial wiki request.
	my $base_name = to_wiki_name($location_name);
	my $cache_name = "../wiki-cache/$base_name";
	my $wiki_name = "$wiki_path/$base_name";
	my $cache_name_fs = $cache_name;
	$cache_name_fs =~ s/\\//g;

	if (exists $mappings{$location_name})
	{
		$wiki_name = "$wiki_path/" . $mappings{$location_name};

		if ($mappings{$location_name} eq "")
		{
			info(0, "Processing '$location_name'");
			info(2, "Skipping because of blank lookup");
			next;
		}
	}

	if (-f $cache_name_fs)
	{
		#info(1, "Skipping because already in cache");
		next;
	}

	# Grab the first file from the Wiki site.
	info(0, "Processing '$location_name'");
	info(1, "Wiki Name: $wiki_name");
	#info(2, "cp $wiki_name $cache_name");
	system("cp $wiki_name $cache_name >& /dev/null");

	if (! -f $cache_name_fs)
	{
		info(1, "Could not download the file");
		next;
	}

	# Check to see if it contains REDIRECT.
	open INPUT, "<$cache_name" or next;
	$/ = undef;
	my $buffer = <INPUT>;
	close INPUT;

	if ($buffer =~ /REDIRECT.*\[\[(.*?)\]\]/i)
	{
		info(1, "Redirected to $1");
		my $new_file = to_wiki_name($1);
		unlink($cache_name);
		system("cp $wiki_path/$new_file $cache_name >& /dev/null");
	}

	# We are done, so just break out.
	sleep 1;
}

#
# Changes the name of a location, such as "The Haunted Ballroom" into the filename
# on the wiki site, such as "The_Haunted_Bedroom.mw".
#

sub to_wiki_name
{
	my $location_name = shift @_;
	$location_name =~ s/ /_/g;
	$location_name =~ s/\'/\\\'/g;
	$location_name =~ s/\(/\\\(/g;
	$location_name =~ s/\)/\\\)/g;
	return "$location_name.mw";
}

#
# Simplified functions for reporting messages to the user.
#

sub error
{
	my $indent = (shift @_) + 0;
	my $message = shift @_;
	print "ERROR " . ("    " x $indent) . "$message\n";
}

sub info
{
	my $indent = (shift @_) + 0;
	my $message = shift @_;
	print " INFO " . ("    " x $indent) . "$message\n";
}
