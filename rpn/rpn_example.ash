import <rpn.ash>

void test_eval_rpn(string rpn_str) {
	float [string] vars;
	vars["x"] = 3;
	vars["blah"] = 2;

	print(rpn_str + " => " + eval_rpn_character(rpn_str, vars));
}

void main() {
	print("Reverse Polish Notation (RPN) calculator. Version " + RPN_VERSION);

	print("Testing various RPN formulas:");
	test_eval_rpn("1 blah + 4 * 5 + x -");
	test_eval_rpn("10 12 min");
	test_eval_rpn("10 12 max");
	test_eval_rpn("100 200 0 if");
	test_eval_rpn("100 200 1 if");
	test_eval_rpn("prime 1.5 * 300 min");
	test_eval_rpn("prime 1.5 * 300 min prime 200 min isMoxieClass if");
	test_eval_rpn("prime 1.5 * 300 min prime 200 min isMoxieClass not if");
	test_eval_rpn("prime 1.5 * 300 max");
	test_eval_rpn("prime 1.5 * 300 max prime 200 max isMoxieClass if");
	test_eval_rpn("prime 1.5 * 300 max prime 200 max isMoxieClass not if");
	test_eval_rpn("10 2 ^");
	test_eval_rpn("10 1.2 ^");
	test_eval_rpn("0 102 -");
	test_eval_rpn("-102");
	test_eval_rpn("-0.1");
	test_eval_rpn("2.1");
	test_eval_rpn("2 sqrt");
	test_eval_rpn("4 sqrt");
	test_eval_rpn("2 2 ^ sqrt");
}
