script "Example Script";
notify "cakyrespa";

import <bob>
import <zlib.ash>

call lksjdf;

cli_execute
{
	thjis is a command
		right it is
		of course, it doesn't work that well.'
		};

cli_execute "guild";
cli_execute("guild");

typedef bob2 gary;

record bob
{
    int some_bob_value;
};

// Comment
/*
  Multi-line comment
*/

void main()
{
	// Comment
	string lookup = "";
	string test_this = 'lksdjf';
	string [string] silly;
	silly[lookup] = "23";
	silly[lookup_2()] = "32";
	silly[silly[lookup]] = "32";
	
	string gary = "test";
	boolean gary = false;
	string steve = 'bob';
	string bob = $item[aaa];
	effect current_effect = $effect[aaa];
	strint steve = $item[abaaba baba];
	item current_item = $item[bob's cheese];

	boolean test = user_confirm("gary");

	// Primitives
	int int_value;
	boolean bool_value;
	float int_value;
	string int_value;
	item item_value;
	effect effect_value;
	class class_value;
	stat stat_value;
	skill skill_value;
	familiar familiar_value;
	slot slot_value;
	location location_value;
	zodiac zodic_value = some_value.zodiac_value;

	// Maps
	//item_value = $items[Some's item]; // '];
	
	// If-Else Blocks
	if (some_expression)
		statement();
	else
		statement();
	
	if (true)
	{
		statement();
		statement();
	}
	else
	{
		statement();
		statement();
	}

	while (expression)
	{
	}
	
	for expression from 10 upto 100 by 2
	{
	}
	
	for expression from 100 downto 10 by 5
	{
	}
	
	foreach bob in gary
	{
		statement();
	}
	
	repeat
	{
		statement();
	}
	until (gary);
	
	switch (expression)
	{
		case "bob":
			statement();
			break;
		case 'as':
		default:
			statement();
	}
}

void use_galaktik( int amount )
{
	if ( item_amount( $item[Doc Galaktik's Ailment Ointment] ) < amount )
	{
		buy( amount - item_amount( $item[Doc Galaktik's Ailment Ointment] ), $item[Doc Galaktik's Ailment Ointment] );
	}
	use( amount, $item[Doc Galaktik's Ailment Ointment] );
}

void heal_galaktik()
{
	while( my_maxhp() > my_hp() )
	{
		int toheal = my_maxhp() - my_hp();
		int amount = toheal / 10;
		if ( amount == 0 )
		{
			break;
		}
		use_galaktik( amount );
	}
}

void heal_herbs()
{
	if ( item_amount( $item[Medicinal Herb's medicinal herbs] ) < 1 )
	{
		buy( 1, $item[Medicinal Herb's medicinal herbs] );
	}
	use( 1, $item[Medicinal Herb's medicinal herbs] );
}

void main()
{
	boolean useHerbs = false;
	if ( my_class() == $class[turtle tamer] || my_class() == $class[seal clubber] )
	{
		useHerbs = true;
	}
	if ( my_class() == $class[accordion thief] && my_level() >= 9 )
	{
		useHerbs = true;
	}
	if ( useHerbs )
	{
		heal_herbs();
	}
	else
	{
		heal_galaktik();
	}
}
