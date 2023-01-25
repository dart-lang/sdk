// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:compiler/src/js/js.dart' as jsAst;
import 'package:compiler/src/js/js.dart' show js;

testExpression(String expression, [String expect = ""]) {
  jsAst.Node node = js(expression);
  String jsText = jsAst.prettyPrint(node, allowVariableMinification: false);
  if (expect == "") {
    Expect.stringEquals(expression, jsText);
  } else {
    Expect.stringEquals(expect, jsText);
  }
}

/// Tests an arrow expression with implicit returns allowed and disallowed.
///
/// Only checks the immediate, outermost arrow function.
testArrowFunction(String arrowExpression,
    [String implicitReturnExpect = "", String noImplicitReturnExpect = ""]) {
  jsAst.ArrowFunction fun = js(arrowExpression) as jsAst.ArrowFunction;
  jsAst.ArrowFunction implicitReturnFun = jsAst.ArrowFunction(
      fun.params, fun.body,
      asyncModifier: fun.asyncModifier, implicitReturnAllowed: true);
  jsAst.ArrowFunction noImplicitReturnFun = jsAst.ArrowFunction(
      fun.params, fun.body,
      asyncModifier: fun.asyncModifier, implicitReturnAllowed: false);
  String implicitReturnText =
      jsAst.prettyPrint(implicitReturnFun, allowVariableMinification: false);
  String noImplicitReturnText =
      jsAst.prettyPrint(noImplicitReturnFun, allowVariableMinification: false);
  String comparison =
      implicitReturnExpect == "" ? arrowExpression : implicitReturnExpect;
  Expect.stringEquals(comparison, implicitReturnText);
  if (noImplicitReturnExpect == "") {
    Expect.stringEquals(comparison, noImplicitReturnText);
  } else {
    Expect.stringEquals(noImplicitReturnExpect, noImplicitReturnText);
  }
}

testError(String expression, [String expect = ""]) {
  bool doCheck(exception) {
    final exceptionText = '$exception';
    Expect.isTrue(exceptionText.contains(expect),
        'Missing "$expect" in "$exceptionText"');
    return true;
  }

  Expect.throws(() => js(expression), doCheck);
}

void main() {
  // Asterisk indicates deviations from real JS.
  // Simple var test.
  testExpression('var a = ""');
  // Parse and print will normalize whitespace.
  testExpression(' var  a  =  "" ', 'var a = ""');
  // Operator precedence.
  testExpression('x = a + b * c');
  testExpression('x = a * b + c');
  testExpression('x = a + b * c + d');
  testExpression('x = a * b + c * d');
  testExpression(
      'remaining = (remaining / 88) | 0', 'remaining = remaining / 88 | 0');
  // Binary operators have left associativity.
  testExpression('x = a + b + c');
  // We can cope with relational operators and non-relational.
  testExpression('a + b == c + d');
  // The prettyprinter will insert braces where needed.
  testExpression('a + (b == c) + d');
  // We can handle () for calls.
  testExpression('foo(bar)');
  testExpression('foo(bar, baz)');
  // Chained calls without parentheses.
  testExpression('foo(bar)(baz)');
  // Chained calls with and without new.
  testExpression('new foo(bar)(baz)');
  testExpression('new foo.bar(bar)(baz)');
  testExpression('foo.bar(bar)(baz)');
  testExpression('constructor = new Function(str)()');
  // The prettyprinter understands chained calls without extra parentheses.
  testExpression('(foo(bar))(baz)', 'foo(bar)(baz)');
  // Chains of dotting and calls.
  testExpression('foo.bar(baz)');
  // String literal.
  testExpression('var x = "fisk"');
  // String literal with \n.
  testExpression(r'var x = "\n"');
  // String literal with escaped quote.
  testExpression(r'''var x = "\""''', r"""var x = '"'""");
  // *No clever escapes.
  testError(r'var x = "\x42"', 'Hex escapes not supported');
  // Operator new.
  testExpression('new Foo()');
  // New with dotted access.
  testExpression('new Frobinator.frobinate()');
  testExpression('new Frobinator().frobinate()');
  // The prettyprinter strips some superfluous parentheses.
  testExpression(
      '(new Frobinator()).frobinate()', 'new Frobinator().frobinate()');
  // *We want a bracket on 'new'.
  testError('new Foo', 'Parentheses are required');
  testError('(new Foo)', 'Parentheses are required');
  // Bogus operators.
  testError('a +++ b', 'Unknown operator');
  // This isn't perl.  There are rules.
  testError('a <=> b', 'Unknown operator');
  // Typeof.
  testExpression('typeof foo == "number"');
  // Strange relation.
  testExpression('a < b < c');
  // Chained var.
  testExpression('var x = 0, y = 1.2, z = 42');
  // Empty object literal.
  testExpression('foo({}, {})');
  // *Can't handle non-empty object literals
  testExpression('foo({meaning: 42})');
  // Literals.
  testExpression('x(false, true, null)');
  // *We should really throw here.
  testExpression('var false = 42');
  testExpression('var new = 42');
  // Bad keyword.
  testError('var typeof = 42', "Expected ALPHA");
  // Malformed decimal/hex.
  testError('var x = 1.1.1', "Unparseable number");
  testError('var x = 0xabcdefga', "Unparseable number");
  testError('var x = 0xabcdef\$a', "Unparseable number");
  testError('var x = 0x ', "Unparseable number");
  // Good hex constants.
  testExpression('var x = 0xff');
  testExpression('var x = 0xff + 0xff');
  testExpression('var x = 0xaF + 0x0123456789abcdefA');
  // All sorts of keywords are allowed as property names in ES5.
  testExpression('x.new = 0');
  testExpression('x.delete = 0');
  testExpression('x.for = 0');
  testExpression('x.instanceof = 0');
  testExpression('x.in = 0');
  testExpression('x.void = 0');
  testExpression('x.continue = 0');
  // More unary.
  testExpression('x = !x');
  testExpression('!x == false');
  testExpression('var foo = void 0');
  testExpression('delete foo.bar');
  testExpression('delete foo');
  testExpression('x in y');
  testExpression('x instanceof y');
  testExpression('a * b in c * d');
  testExpression('a * b instanceof c * d');
  testError('x typeof y', 'Unparsed junk');
  testExpression('x &= ~mask');
  // Await is parsed as an unary prefix operator.
  testExpression('var foo = await 0');
  testExpression('await x++');
  testExpression('void (await (x++))', 'void await x++');
  testExpression('void (await x)++');
  testExpression('++(await x)++');
  // Adjacent tokens.
  testExpression('foo[x[bar]]');
  testExpression('foo[[bar]]');
  // Prefix ++ etc.
  testExpression("++x");
  testExpression("++foo.bar");
  testExpression("+x");
  testExpression("+foo.bar");
  testExpression("-x");
  testExpression("-foo.bar");
  testExpression("--x");
  testExpression("--foo.bar");
  // Postfix ++ etc.
  testExpression("x++");
  testExpression("foo.bar++");
  testExpression("x--");
  testExpression("foo.bar--");
  // Both!
  testExpression("++x++");
  testExpression("++foo.bar++");
  testExpression("--x--");
  testExpression("--foo.bar--");
  // *We can't handle stacked unary operators (apart from !).
  testError("x++ ++");
  testError("++ typeof x");
  testExpression(r"var $supportsProtoName = !!{}.__proto__");
  // ++ used as a binary operator.
  testError("x++ ++ 42");
  // Shift operators.
  testExpression("x << 5");
  testExpression("x << y + 1");
  testExpression("x <<= y + 1");
  // Array initializers.
  testExpression('x = ["foo", "bar", x[4]]');
  testExpression("[]");
  testError("[42 42]");
  testExpression('beebop([1, 2, 3])');
  // Array literals with holes in them.
  testExpression("[1,, 2]");
  testExpression("[1,]", "[1]");
  testExpression("[1,,]", "[1,,]");
  testExpression("[,]");
  testExpression("[,,]");
  testExpression("[, 42]");
  // Ternary operator.
  testExpression("x = a ? b : c");
  testExpression("y = a == null ? b : a");
  testExpression("y = a == null ? b + c : a + c");
  testExpression("foo = a ? b : c ? d : e");
  testExpression("foo = a ? b ? c : d : e");
  testExpression("foo = (a = v) ? b = w : c = x ? d = y : e = z");
  testExpression("foo = (a = v) ? b = w ? c = x : d = y : e = z");
  // Stacked assignment.
  testExpression("a = b = c");
  testExpression("var a = b = c");
  // Arrow functions.
  testArrowFunction("(x) => x", "x => x");
  testArrowFunction(
      "(x) => {\n  return x;\n}", "x => x", "x => {\n  return x;\n}");
  testArrowFunction("(x, y) => {\n  return x + y;\n}", "(x, y) => x + y",
      "(x, y) => {\n  return x + y;\n}");
  testArrowFunction("() => 42");
  testArrowFunction('() => ({foo: "bar"})');
  testArrowFunction("() => {}", """
() => {
}""");
  // Arrow function invocation.
  testExpression("(() => 1)()");
  testExpression("((x) => x)(y)", "(x => x)(y)");
  testExpression("(() => {x = 1;})()", """
(() => {
  x = 1;
})()""");
  // Arrow functions with operators.
  testExpression("a = (b) => c", "a = b => c");
  testExpression("a = ((b) => b)(c)", "a = (b => b)(c)");
  testExpression("(x) => (y) => z + y", "x => y => z + y");
  testExpression("!((x) => (y) => x + y)", "!(x => y => x + y)");
  testExpression("(x) => !((y) => x + y)", "x => !(y => x + y)");
  testExpression("(x) => (y) => !(x + y)", "x => y => !(x + y)");
  testExpression("((x) => (y) => x + y) && z", "(x => y => x + y) && z");
  testExpression("(x) => (((y) => x + y) && z)", "x => (y => x + y) && z");
  testExpression("(x) => (y) => ((x + y) && z)", "x => y => x + y && z");
  testExpression("z && ((x) => (y) => x + y)", "z && (x => y => x + y)");
  testExpression("(x) => (z && ((y) => x + y))", "x => z && (y => x + y)");
  testExpression("(x) => (y) => (z && x + y)", "x => y => z && x + y");
  testExpression("(x) => (y) => ((z && x) + y)", "x => y => (z && x) + y");
  // Methods.
  testExpression("{ foo() {}, bar() {}, }", """
{
  foo() {
  },
  bar() {
  }
}""");

  // Exponentiation operator.
  testExpression("a ** b");
  //* Parsed with incorrect association:
  testExpression("a ** b ** c", "(a ** b) ** c");
  testExpression("(a ** b) ** c", "(a ** b) ** c");
  testExpression("a ** (b ** c)", "a ** b ** c");
  testExpression("a **= b");
}
