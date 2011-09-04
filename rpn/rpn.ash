// =============================================================================
// rpn.ash (Version 6)
// Written by the_great_cow_guru
// Modified by cakyrespa
// Thanks to Catch-22 for help on the regex stuff
//
// Implements a reverse polish notation (RPN) calculator for use within ASH.
// This performs all functions using floats and will return a single float or
// abort with an error.
//
// The following operations are supported:
//	X Y + => Z		Adds X and Y and pushes the results.
//	X Y - => Z		Subtracts X from Y and pushes the results.
//	X Y * => Z		Multiplies X and Y and pushes the results.
//	X Y / => Z		Divides X by Y and pushes the results.
//	X Y ^ => Z		Raises X to the Y power and pushes the results.
//	X Y min => Z		Pushes the lower of X or Y.
//	X Y max => Z		Pushes the higher of X or Y.
//	X Y C if => Z		If C is 0, pushes Y, otherwise pushes X.
//	C not => Y		If C is 0, pushes 1, otherwise pushes 0.
//	X sqrt => Z		Pops C, then pushes the square root result.
//
// Variables can be defined by populating the variables map and passing that
// into the function.
// =============================================================================

// -----------------------------------------------------------------------------
// Imports
// -----------------------------------------------------------------------------

import <zlib.ash>

// -----------------------------------------------------------------------------
// Variables
// -----------------------------------------------------------------------------

// This is the version we'll use to compare to the project page.
string RPN_VERSION = "4";
check_version("RPN Calculator", "rpn", RPN_VERSION, 2433);

// -----------------------------------------------------------------------------
// Functions
// -----------------------------------------------------------------------------

// Prints out the current tokens in the RPN list.
void debug_rpn_tokens(string [int] rpn) {
	string output = "Tokens: ";

	foreach index in rpn {
		output = output + rpn[count(rpn) - index] + " ";
	}

	print(output, "gray");
}

string pop(string [int] map) {
	if(count(map) == 0) abort("can't pop from empty stack");
	return remove map[count(map)-1];
}

float pop(float [int] map) {
	if(count(map) == 0) abort("can't pop from empty stack");
	return remove map[count(map)-1];
}

void push(string [int] map, string val) {
	map[count(map)] = val;
}

void push(float [int] map, float val) {
	map[count(map)] = val;
}

string [int] reverse(string [int] map) {
	// hmm, the maps obtained from calling split_string appear to be immutable
	// looks like i can't just push the pops :(
	string [int] rev_map;
	for i from count(map)-1 downto 0 {
		push(rev_map, map[i]);
	}
	return rev_map;
}

boolean is_operator(string test) {
	return create_matcher("^([-\\+\\*/\\^]|m(ax|in)|if|not|sqrt)$", test).find();
}

boolean is_numeric(string test) {
    return create_matcher("^-?[0-9]+(\\.[0-9]+)?$", test).find();
}

float eval_rpn(string rpn_str, float [string] variables, boolean debug) {
	string [int] rpn = reverse(split_string(rpn_str, "\\s+"));
	float [int] stack;
	while (count(rpn) > 0) {
		if (debug) debug_rpn_tokens(rpn);
		string val = pop(rpn);
		if (is_numeric(val)) {
			push(stack, to_float(val));
		} else if (is_operator(val)) {
			float a,b,c;
			switch (val) {
				case "+":
					a = pop(stack); 
					b = pop(stack);
					push(stack, b+a);
					break;
				case "-":
					a = pop(stack);
					b = pop(stack);
					push(stack, b-a);
					break;
				case "*":
					a = pop(stack);
					b = pop(stack);
					push(stack, b*a);
					break;
				case "/":
					a = pop(stack);
					b = pop(stack);
					if (a == 0) { push(stack, 0); }
					else { push(stack, b/a); }
					break;
				case "^":
					a = pop(stack);
					b = pop(stack);
					push(stack, b ^ a);
					break;
				case "if":
					c = pop(stack);
					b = pop(stack);
					a = pop(stack);
					if (c == 0) { push(stack, b); } 
					else { push(stack, a); }
					break;
				case "min":
					a = pop(stack);
					b = pop(stack);
					push(stack, min(b, a));
					break;
				case "max":
					a = pop(stack);
					b = pop(stack);
					push(stack, max(b, a));
					break;
				case "not":
					a = pop(stack);
					if (a == 0) { push(stack, 1); } 
					else { push(stack, 0); }
					break;
				case "sqrt":
					a = pop(stack);
					push(stack, square_root(a));
					break;
				default:
					abort("Unknown operator: " + val);
			}
		} else {
			if (!(variables contains val)) abort("failed to supply a value for variable: " + val + " (" + rpn_str + ")");
			push(stack, variables[val]);
		}
	}
	if (count(stack) != 1) { abort("invalid rpn expression (" + rpn_str + ")"); }
	return stack[0];
}

float eval_rpn(string rpn_str, float [string] variables) {
	return eval_rpn(rpn_str, variables, false);
}

float eval_rpn(string rpn_str) {
	float [string] vars;
	return eval_rpn(rpn_str, vars);
}

// Calls eval_rpn() after adding common variables for the player's current
// situation.
float eval_rpn_character(string rpn_str, float [string] variables, boolean debug) {
	// Add in the stat variables.
	variables["prime"] = my_basestat(my_primestat());
	variables["primeBuffed"] = my_buffedstat(my_primestat());
	variables["muscle"] = my_basestat($stat[Muscle]);
	variables["muscleBuffed"] = my_buffedstat($stat[Muscle]);
	variables["moxie"] = my_basestat($stat[Moxie]);
	variables["moxieBuffed"] = my_buffedstat($stat[Moxie]);
	variables["mysticality"] = my_basestat($stat[Mysticality]);
	variables["mysticalityBuffed"] = my_buffedstat($stat[Mysticality]);

	// Add in the class variables.
	variables["isMuscleClass"] = 0;
	variables["isMoxieClass"] = 0;
	variables["isMysticalityClass"] = 0;
	if (my_class() == $class[Seal Clubber] || my_class() == $class[Turtle Tamer]) {
		variables["isMuscleClass"] = 1;
	}
	else if (my_class() == $class[Disco Bandit] || my_class() == $class[Accordion Thief]) {
		variables["isMoxieClass"] = 1;
	}
	else if (my_class() == $class[Pastamancer] || my_class() == $class[Sauceror]) {
		variables["isMysticalityClass"] = 1;
	}

	// Evaluate with the additional variables.
	return eval_rpn(rpn_str, variables, debug);
}

float eval_rpn_character(string rpn_str, float [string] variables) {
	return eval_rpn_character(rpn_str, variables, false);
}

float eval_rpn_character(string rpn_str) {
	float [string] vars;
	return eval_rpn_character(rpn_str, vars);
}

/*
  Section: Formula Manipulations
*/

/*
  Function: rpn_normalize

  Normalizes a RPN formula. If it is blank or a string, it puts in
  0.0.
*/
string rpn_normalize(string formula)
{
	if (formula == "" ||
		formula == "0")
	{
		return "0.0";
	}

	return formula;
}

/*
  Function: rpn_add

  Adds two RPN formulas together, keeping them as simplified as
  possible to reduce processing.
*/
string rpn_add(string formula1, string formula2)
{
	// Normalize the formula strings
	formula1 = rpn_normalize(formula1);
	formula2 = rpn_normalize(formula2);

	// Check for blanks or nulls.
	if (formula1 == "0.0")
	{
		// There is no formula1, so just return formula2.
		return formula2;
	}

	if (formula2 == "0.0")
	{
		// There is no formula2, so just return formula1.
		return formula1;
	}

	// At this point, we have valid formulas for both, so just add
	// them using RPN notation.
	return formula1 + " " + formula2 + " +";
}
