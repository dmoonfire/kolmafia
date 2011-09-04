/*
  Script: CakeLib

  Contains common features and functionality used by the various Cake
  libraries.
*/

// Imports
import <zlib.ash>
import <rpn.ash>

int CAKE_LIB_VERSION = 0;

// Controls what is considered a survivable hit in combat. The default is set to
// 10% of the given hit points. Like the rest of this library, percentages are
// in terms of 0 to 1.
setvar("survivable", 0.1);

// Controls what determines a productive combat, one where the character can
// defeat the opponent in this number of rounds or less. If this set to a low
// number, such as 1, then an encounter is only productive if the character
// can "one hit" the opponent and win.
setvar("productive", 10);

// Setting this to a higher level will show more debugging information.
int cake_verbose = 0;

/*
  Section: Console Logging
*/

/*
  Variable: cake_indent

  Contains the current indent level, this is for simple formatting
  purposes.
*/
int cake_indent = 0;

/*
  Function: cake_indent

  Indents the output from the various Cake display functions.
*/
void cake_indent()
{
	cake_indent = cake_indent + 1;
}

/*
  Function: cake_indent

  Indents the output from the various Cake display functions.
*/
void cake_indent(boolean display)
{
	if (display)
		cake_indent = cake_indent + 1;
}

/*
  Function: cake_outdent

  Outdents the output from the various Cake display functions.
*/
void cake_outdent()
{
	cake_indent = cake_indent - 1;
}

/*
  Function: cake_outdent

  Outdents the output from the various Cake display functions.
*/
void cake_outdent(boolean display)
{
	if (display)
		cake_indent = cake_indent - 1;
}

/*
  Function: cake_spacer

  Uses the current cake_indent level to create a HTML-formatter spacing.
*/
string cake_spacer()
{
	string spaces = "";
	int count = 0;

	while (count < cake_indent)
	{
		count = count + 1;
		spaces = spaces + "&nbsp;&nbsp;&nbsp;";
	}

	return spaces;
}

/*
  Function: cake_print

  Optionally prints out a message in a given color. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  display - If this is false, nothing is printed.
  message - The text message to display.
  color - The color to print out out the text.
*/
void cake_print(
	boolean display,
	string message,
	string color)
{
	if (display)
		print(cake_spacer() + message, color);
}

/*
  Function: cake_print

  Optionally prints out a message in black. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  display - If this is false, nothing is printed.
  message - The text message to display.
*/
void cake_print(
	boolean display,
	string message)
{
	cake_print(display, message, "black");
}

/*
  Function: cake_print

  Prints out a message in the given color. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  message - The text message to display.
  color - The color to print out out the text.
*/
void cake_print(
	string message,
	string color)
{
	cake_print(true, message, color);
}

/*
  Function: cake_print

  Prints out a message in black. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  message - The text message to display.
*/
void cake_print(
	string message)
{
	cake_print(true, message, "black");
}

/*
  Function: cake_error

  Optionally prints out an error message in red. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  display - If this is false, nothing is printed.
  message - The text message to display.

  Returns:

  This always returns false.
*/
boolean cake_error(
	boolean display,
	string message)
{
	cake_print(display, message, "red");
	return false;
}

/*
  Function: cake_error

  Prints out an error message in red. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  message - The text message to display.

  Returns:

  This always returns false.
*/
boolean cake_error(
	string message)
{
	return cake_error(true, message);
}

/*
  Function: cake_warning

  Optionally prints out a warning message in red. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  display - If this is false, nothing is printed.
  message - The text message to display.
*/
void cake_warning(
	boolean display,
	string message)
{
	cake_print(display, message, "#E56717");
}

/*
  Function: cake_warning

  Prints out a warning message in red. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  message - The text message to display.
*/
void cake_warning(
	string message)
{
	cake_warning(true, message);
}

/*
  Function: cake_info

  Optionally prints out an info message in red. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  display - If this is false, nothing is printed.
  message - The text message to display.
*/
void cake_info(
	boolean display,
	string message)
{
	cake_print(display, message, "#307D7E");
}

/*
  Function: cake_info

  Prints out an info message in red. This will be printed with
  the current indent as determined by the <cake_indent> functions.

  Parameters:

  =		message - The text message to display.
*/
void cake_info(
	string message)
{
	cake_info(true, message);
}

/*
  Section: Array Functions
*/

/*
  Function: cake_append

  Adds the given value to the end of the array.
*/
void cake_append(string [int] array, string value)
{
	array[count(array)] = value;
}

/*
  Section: Useful Functions
*/

/*
  Function: cake_get_current_effects

  Returns:
	
  A map of all the effects the player currently has. The value of the
  map is the number of turns remaining.
*/
int [effect] cake_get_current_effects()
{
	// Build up a list of effects on the player and save those that have more
	// than zero turns.
	int [effect] effects;

	foreach current_effect in $effects[]
	{
		int turns = have_effect(current_effect);
		
		if (turns > 0)
		{
			effects[current_effect] = turns;
		}
	}

	// Return the resulting effects.
	return effects;
}

void main()
{
	// Show the introduction with some information.
	cake_info("CakeLib " + CAKE_LIB_VERSION + " by cakyrespa");
	cake_info("");

	// Show the effects on the player.
	cake_info("Showing the effects currently on the player:");
	cake_indent();
	
	int [effect] current_effects = cake_get_current_effects();

	foreach current_effect in current_effects
	{
		cake_info(to_string(current_effect) + " for "
			+ current_effects[current_effect] + " turns");
	}

	cake_outdent();
	cake_info("...done");
}
