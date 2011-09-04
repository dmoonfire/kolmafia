#!/usr/bin/perl

#
# GenerateNoncombatDataForKoLmafia.pl 0.0.0
#

=pod
=head1 Introduction

This programs attempts to generate noncombats.txt and related map files in a
style appropriate for inclusion with KoLmafia itself.

To download the source from the KoL wiki, this uses wikipediafs, a fuse library
for treating MediaWiki pages as normal pages within Linux. This means it won't
work on Windows until an alternative presents itself.

=head1 Usage

./GenerateNoncombatDataForKoLmafia.pl "Name of Location"...
./GenerateNoncombatDataForKoLmafia.pl

=head1 Map Formats

This file generates and combines data into two files. These are both based on
the 'combats.txt' and 'monsters.txt' from the original KoLmafia source files.
These will be stored in ../data/ as a centralized location.

=over
=item noncombats.txt
This file has a variable number of fields. The first column is the name of the
location. The second is zero or more "events" (i.e. non-combat adventures).
Optionally, each event is followed by ": ", an optional code, and a weight.
Weight works line combat adventures, to change the order of events. The
code is as follows:

=over
=item t
This is a ten-leaf clover event.
=item b
This is a bad moon event.
=item c
This is a conditional event.
=item o
This is a one-time event.
=item s
This is a semi-rare event.
=back

=cut

#
# Setup
#

# Directives
use strict;
use warnings;

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

#
# Read in the data files into memory. This lets us run the lookup on a single
# page instead of slamming the wiki for every location known.
#

if (-f "../data/noncombats.txt")
{
	open INPUT, "<../data/noncombats.txt" or die "Cannot open noncombats.txt ($!)";

	while (<INPUT>)
	{
		# Clean up the line for parsing.
		chomp;

		# If we are a comment or blank line, then just add it to header.
		if (/^\#/ || /^\s*$/)
		{
			push @noncombats_headers, $_;
			next;
		}

		# Otherwise, split it on the tab.
		my @parts = split(/\t/, $_);

		if (@parts > 1)
		{
			my $key = shift @parts;
			$noncombats{$key} = \@parts;
		}
	}

	close INPUT;
}

if (-f "../data/events.txt")
{
	open INPUT, "<../data/events.txt" or die "Cannot open events.txt ($!)";

	while (<INPUT>)
	{
		# Clean up the line for parsing.
		chomp;

		# If we are a comment or blank line, then just add it to header.
		if (/^\#/ || /^\s*$/)
		{
			push @events_headers, $_;
			next;
		}

		# Otherwise, split it on the tab.
		my @parts = split(/\t/, $_, 2);

		if (@parts > 1)
		{
			my $key = shift @parts;
			$events{$key} = \@parts;
		}
	}

	close INPUT;
}

#
# Go through the input locations. This will pull the data down from the wiki
# site and process the page elements.
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
	info(0, "Processing '$location_name'");

	# Retrieve the wiki page.
	my $wiki_page = "";
	my $wiki_name = to_wiki_name($location_name);

	if (-f "../wiki-cache/$wiki_name")
	{
		$wiki_name = "../wiki-cache/$wiki_name";
		info(1, "Using cached $wiki_name...");
	}
	else
	{
		info(1, "Skipping $wiki_name because it needs a download.");
		next;
	}

	open INPUT, "<$wiki_name";
	undef $/;
	$wiki_page = <INPUT>;
	close INPUT;

	# Split the name on the newlines, since that seems to be the best break.
	my @lines = split(/\n/, $wiki_page);
	my @events = ();

	while (@lines)
	{
		# Grab the next line.
		my $line = shift @lines;

		# Check to see if we have retired adventures.
		if ($line =~ /Retired Adventures/)
		{
			# We ignore this entire section so just go through the
			# lines until we find the next section or run out of
			# lines.
			info(1, "Skipping retired adventures");
			while (@lines)
			{
				$line = shift @lines;
				last if $line =~ /^==/;
			}

			next if $line =~ /^==/ || @lines == 0;
		}

		# Check to see if the line starts with a {{ and make sure it
		# ends properly.
		while ($line =~ m/^\{\{/ && $line !~ m/\}\}$/)
		{
			if (@lines == 0)
			{
				error(2, "Cannot figure out how to parse line without "
					."additional data: $line");
				exit 1;
			}

			$line .= shift @lines;
		}

		# If we have a {{code}} tag, clean it up and parse it.
		next unless $line =~ m/^\{\{(\w+)\|name=(.*?)\|(.*?)\}\}$/;

		my $type = lc $1;
		my $name = $2;
		my $contents = $3;
		$name =~ s/\s+$//;
		$name =~ s/^.*\{\{!\}\}//;
		$contents =~ s/[\{\}\[\]]//g;
		$contents =~ s/<mainstat>/prime/ig;
		$contents =~ s/<\/?\w+[^>]*>//ig;

		# Determine what to do based on the type of tag we got from the
		# wiki page. Combat adventures we ignore entirely, so the only
		# other two we care about are either "adventure" or "choice".
		next if ($type eq "combat");

		push @events, parse_adventure($location_name, $name, $contents)
			if $type eq "adventure" or $type eq "choice";
	}

	# Print out the final line.
	info(1, "Events: " . join(", ", @events)) if @events;
	$noncombats{$location_name} = \@events;
}

#
# Write out the data files.
#

open OUTPUT, ">../data/noncombats.txt" or die "Cannot write noncombats.txt ($!)";
print OUTPUT join("\n", @noncombats_headers), "\n" if @noncombats_headers;

foreach my $key (sort keys %noncombats)
{
	my $ref = $noncombats{$key};
	my @parts = @$ref;
	print OUTPUT join("\t", $key, @parts), "\n";
}

close OUTPUT;

open OUTPUT, ">../data/events.txt" or die "Cannot write events.txt ($!)";
print OUTPUT join("\n", @events_headers), "\n" if @events_headers;

foreach my $key (sort keys %events)
{
	my $ref = $events{$key};
	my @parts = @$ref;
	print OUTPUT join("\t", $key, @parts), "\n";
}

close OUTPUT;

#
# parse_choice attempts to parse the choice line and return the stats.
#

sub parse_choice
{
	# Grab the parameters.
	my $location_name = shift @_;
	my $event_name = shift @_;
	my $choice_name = shift @_;
	my $line = shift @_;

	# Handle some of the more specific ones.
	if ($location_name eq "The Haunted Ballroom")
	{
		# Strung-Up Quartet doesn't give anything.
		return (0, 0, 0, 0, "") if ($event_name eq "Strung-Up Quartet");
	}

	if ($location_name eq "Palindome")
	{
		# http://kol.coldfront.net/thekolwiki/index.php/Palindome
		if ($event_name eq "No sir, away! A papaya war is on!")
		{
			if ($choice_name eq "Dive into the bunker")
			{
				# Gain 3 papaya
			}
			
			if ($choice_name eq "Leap into the fray!")
			{
				# Gain to all stats (or take damage)
				#return ("prime 300 min", "prime 300 min", "prime 300 min",
				#		0, "");
				return (0, 0, 0, 0, "");
			}

			if ($choice_name eq "Give the men a pep talk")
			{
				# Gain to all stats
				return ("prime 100 min", "prime 100 min", "prime 100 min",
						0, "");
			}
		}

		if ($event_name eq "Sun at Noon, Tan Us")
		{
			if ($choice_name eq "A little while")
			{
				return (0, "prime min 250", 0, 0, "");
			}

			if ($choice_name eq "A medium while")
			{
				return (0, 0, 0, 0, "");
			}

			if ($choice_name eq "A long while")
			{
				return (0, 0, 0, 0, "Sunburned 10");
			}
		}
	}

	info(2, "Choice: $choice_name");

	# Parse it as a stat line.
	return (parse_stat($location_name, $event_name, $line), 0, "");
}

#
# parse_stat parses the stat= lines for choice and adventures.
#

sub parse_stat
{
	# Grab the variables being passed into the method.
	my $location_name = shift @_;
	my $event_name = shift @_;
	my $value = shift @_;

	return (0, 0, 0) if $value =~ /^\s*$/;

	# Check for special locations and formulas.
	if ($location_name eq "The Castle in the Clouds in the Sky")
	{
		if ($event_name eq "Being Taken Out by the Trash")
		{
			return ("prime 110 min 2.25 *", 0, 0);
		}

		if ($event_name eq "The Cat's in the Castle and the Silver Spoon")
		{
			return (0, "prime 110 min 2.25 *", 0);
		}

		if ($event_name eq "Outage, Brief Candle")
		{
			return (0, 0, "prime 110 min 2.25 *");
		}
	}

	if ($location_name eq "The Hidden Temple")
	{
		# http://kol.coldfront.net/thekolwiki/index.php/The_Hidden_Temple
		if ($event_name eq "Rolling Stone Trap" ||
		    $event_name eq "Swinging Blade Trap")
		{
			return ("muscle 2 * 0 muscle 2 / - + 50 min", 0, 0);
		}

		if ($event_name eq "Arrowed!" ||
		    $event_name eq "Cunning Puzzle Trap")
		{
			return (0, "moxie 2 * 0 moxie 2 / - + 50 min", 0);
		}
		
		if ($event_name eq "Lightning Trap" ||
		    $event_name eq "Poison Gas Trap")
		{
			return (0, 0, "mysticality 2 * 0 mysticality 2 / - + 50 min");
		}

		if ($event_name eq "Trapstravaganza")
		{
			# No clue, couldn't find a formula so just divided the
			# above in half.
			return (
				"muscle 2 * 0 muscle 2 / - + 50 min 2 /",
				"moxie 2 * 0 moxie 2 / - + 50 min 2 /",
				"mysticality 2 * 0 mysticality 2 / - + 50 min 2 /");
		}
	}

	# Normalize the line and remove formatting.
	$value =~ s/[\s\.]$//g;
	$value =~ s/<mainstat>/prime/ig;
	$value =~ s/mainstat/prime/ig;
	$value =~ s/<\/?\w+[^>]*>//ig;
	$value =~ s/approximately//ig;
	$value =~ s/gain//ig;

	# We couldn't figure it out through the name, so just parse the line.
	info(2, "parse_stat $location_name - $event_name -> $value");

	# Check for ranges.
	while ($value =~ s/(\d+(\.\d+)?)\s*-\s*(\d+(\.\d+)?)/REPLACE/)
	{
		# This is a numeric range, so we average it because we don't
		# don't have an override above.
		my $average = ($1 + $3) / 2;
		$value =~ s/REPLACE/$average/;
	}

	# Figure out the formulas, if we can.
	my ($mus, $mox, $mys) = (0, 0, 0);

	if ($value =~ s/in moxie//ig)
	{
		$mox = normalize_formula($value);
	}
	elsif ($value =~ /max (\d+) (\w+)\s+\(\s+(\d)\s*\*\s*prime/)
	{
		# Found in the Hauned Bedroom.
		my $formula = "$3 prime * $1 max";

		$mus = $formula if ($2 eq "muscle");
		$mox = $formula if ($2 eq "moxie");
		$mys = $formula if ($2 eq "mysticality");
	}
	else
	{
		$mus = normalize_range($1) if $value =~ /([\d\-]+) muscle/i;
		$mox = normalize_range($1) if $value =~ /([\d\-]+) mox/i;
		$mys = normalize_range($1) if $value =~ /([\d\-]+) mys/i;
	}

	info(3, "mus=$mus, mox=$mox, mys=$mys");

	return ($mus, $mox, $mys);
}

#
# parse_adventure parses the {{Adventure}} wiki tag.
#

sub parse_adventure
{
	# Grab the arguments and make a bit of noise.
	my $location_name = shift @_;
	my $name = shift @_;
	my $tag = shift @_;
	my $need_condition = 0;
	my $flag = "";
	my $long_flag = "normal";
	my $weight = 1;
	info(1, "Adventure: $name");

	# Check for Bad Moon in the text.
	if ($tag =~ /Bad Moon/)
	{
		$need_condition = 1;
		$flag = "b";
		$long_flag = "bad_moon";
		info(2, "Bad Moon adventure");
	}

	if ($tag =~ /ten-leaf clover/)
	{
		$need_condition = 1;
		$flag = "t";
		$long_flag = "clover";
		info(2, "Clover adventure");
	}

	if ($tag =~ /one-time/)
	{
		$need_condition = 1;
		$flag = "o";
		$long_flag = "one_time";
		info(2, "One-Time adventure");
	}

	if ($tag =~ /semi-rare/)
	{
		$need_condition = 1;
		$flag = "s";
		$long_flag = "semi_rare";
		info(2, "Semi-rare adventure");
	}

	if ($tag =~ /occurs.*after using/i ||
	    $tag =~ /only occur/)
	{
		$need_condition = 1;
		$flag = "c";
		$long_flag = "conditional";
		info(2, "Conditional adventure");
	}

	# Split apart the contents on the pipe character.
	my @parts = split(/\|/, $tag);
	my $mus = 0;
	my $mox = 0;
	my $mys = 0;
	my $meat = 0;
	my $drops = "";
	my @choices = ();
	my $choice_count = 0;

	#info(2, "Tag: $tag");
	my $last_choice_name = "";
	foreach my $part (@parts)
	{
		# Each part is in the format of "a=b".
		next unless $part =~ /^(\w+)=(.*)$/;
		my $key = $1;
		my $value = $2;

		# We ignore images, since we don't show them.
		next if $key eq "image";

		if ($key eq "stat")
		{
			($mus, $mox, $mys) = parse_stat($location_name, $name, $value);
		}

		# Keep track of the meat.
		if ($key eq "meat")
		{
			$meat = $value;
			$meat = 0 if $meat =~ /none/i;
		}

		# Just keep a list of item drops.
		$drops = $value if $key eq "drops";

		# Figure out the choices adventures.
		$last_choice_name = $value if $key =~ /^choice\d+name$/;

		if ($key =~ /^choice\d+$/)
		{
			push @choices, parse_choice(
				$location_name,
				$name,
				$last_choice_name,
				$value);
			$choice_count++;
		}
	}

	# If there isn't a choice, then add it as a single choice.
	if ($choice_count == 0)
	{
		info(2, "Stats: mus=$mus, mox=$mox, mys=$mys, meat=$meat, Drops: $drops");
		push @choices, ($mus, $mox, $mys, $meat, $drops);
		$choice_count = 1;
	}

	unshift @choices, $choice_count;
	unshift @choices, $long_flag;
	$events{$name} = \@choices;

	# Return the tag based on the condition.
	return "$name: $flag$weight" if $need_condition;
	return $name;
}

#
# Attempts to normalize the formula and convert it into RPN notation.
#

sub normalize_formula
{
	# Grab the formula.
	my $formula = shift @_;

	# Check for the max.
	my $max = "";

	if ($formula =~ s/\s*\(\s*max\s+(\d+)\)//)
	{
		$max = " $1 min";
	}

	# Convert algebra to RPN.
	$formula =~ s/(\d+)\s*([\*\/])\s*(\w+)/$1 $3 $2/s;
	$formula =~ s/^\s+//;
	$formula =~ s/\s+$//;
	$formula =~ s/\s+/ /sg;

	# Return the results.
	return "$formula$max";
}

sub normalize_range
{
	my $range = shift @_;
	$range = ($1 + $2) / 2 if $range =~ /^(-?\d+)\s*-\s*(-?\d+)$/;
	return $range;
}

#
# Changes the name of a location, such as "The Haunted Ballroom" into the filename
# on the wiki site, such as "The_Haunted_Bedroom.mw".
#

sub to_wiki_name
{
	my $location_name = shift @_;
	$location_name =~ s/ /_/g;
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
