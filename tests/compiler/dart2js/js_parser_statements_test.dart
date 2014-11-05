// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'mock_compiler.dart';
import 'package:compiler/src/js/js.dart' as jsAst;
import 'package:compiler/src/js/js.dart' show js;


Future testStatement(String statement, List arguments, String expect) {
  jsAst.Node node = js.statement(statement, arguments);
  return MockCompiler.create((MockCompiler compiler) {
    String jsText =
        jsAst.prettyPrint(node, compiler, allowVariableMinification: false)
        .getText();

    Expect.stringEquals(expect.trim(), jsText.trim());
  });
}

Future testError(String statement, List arguments, [String expect = ""]) {
  return new Future.sync(() {
    bool doCheck(exception) {
      String message = '$exception';
      Expect.isTrue(message.contains(expect), '"$message" contains "$expect"');
      return true;
    }
    void action() {
      jsAst.Node node = js.statement(statement, arguments);
    }
    Expect.throws(action, doCheck);
  });
}

// Function declaration and named function.
const NAMED_FUNCTION_1 = r'''
function foo/*function declaration*/() {
  return function harry/*named function*/() { return #; }
}''';

const NAMED_FUNCTION_1_ONE = r'''
function foo() {
  return function harry() {
    return 1;
  };
}''';

const MISC_1 = r'''
function foo() {
  /a/;
  #;
}''';

const MISC_1_1 = r'''
function foo() {
  /a/;
  1;
  2;
}''';



void main() {

  var eOne = js('1');
  var eTrue = js('true');
  var eVar = js('x');
  var block12 = js.statement('{ 1; 2; }');
  var seq1 = js('1, 2, 3');

  Expect.isTrue(eOne is jsAst.LiteralNumber);
  Expect.isTrue(eTrue is jsAst.LiteralBool);
  Expect.isTrue(block12 is jsAst.Block);

  asyncTest(() => Future.wait([
    // Interpolated Expressions are upgraded to ExpressionStatements.
    testStatement('{ #; #; }', [eOne, eOne], '{\n  1;\n  1;\n}'),

    // Interpolated sub-blocks are spliced.
    testStatement('{ #; #; }', [block12, block12],
        '{\n  1;\n  2;\n  1;\n  2;\n}\n'),

    // If-condition.  Dart booleans are evaluated, JS Expression booleans are
    // substituted.
    testStatement('if (#) #', [eOne, block12], 'if (1) {\n  1;\n  2;\n}'),
    testStatement('if (#) #;', [eTrue, block12], 'if (true) {\n  1;\n  2;\n}'),
    testStatement('if (#) #;', [eVar, block12], 'if (x) {\n  1;\n  2;\n}'),
    testStatement('if (#) #;', ['a', block12], 'if (a) {\n  1;\n  2;\n}'),
    testStatement('if (#) #;', [true, block12], '{\n  1;\n  2;\n}'),
    testStatement('if (#) #;', [false, block12], ';'),
    testStatement('if (#) 3; else #;', [true, block12], '3;'),
    testStatement('if (#) 3; else #;', [false, block12], '{\n  1;\n  2;\n}'),


    testStatement(NAMED_FUNCTION_1, [eOne], NAMED_FUNCTION_1_ONE),

    testStatement(MISC_1, [block12], MISC_1_1),

    // Argument list splicing.
    testStatement('foo(#)', [[]], 'foo();'),
    testStatement('foo(#)', [[eOne]], 'foo(1);'),
    testStatement('foo(#)', [eOne], 'foo(1);'),
    testStatement('foo(#)', [[eTrue,eOne]], 'foo(true, 1);'),

    testStatement('foo(2,#)', [[]], 'foo(2);'),
    testStatement('foo(2,#)', [[eOne]], 'foo(2, 1);'),
    testStatement('foo(2,#)', [eOne], 'foo(2, 1);'),
    testStatement('foo(2,#)', [[eTrue,eOne]], 'foo(2, true, 1);'),

    testStatement('foo(#,3)', [[]], 'foo(3);'),
    testStatement('foo(#,3)', [[eOne]], 'foo(1, 3);'),
    testStatement('foo(#,3)', [eOne], 'foo(1, 3);'),
    testStatement('foo(#,3)', [[eTrue,eOne]], 'foo(true, 1, 3);'),

    testStatement('foo(2,#,3)', [[]], 'foo(2, 3);'),
    testStatement('foo(2,#,3)', [[eOne]], 'foo(2, 1, 3);'),
    testStatement('foo(2,#,3)', [eOne], 'foo(2, 1, 3);'),
    testStatement('foo(2,#,3)', [[eTrue,eOne]], 'foo(2, true, 1, 3);'),

    // Interpolated Literals
    testStatement('a = {#: 1}', [eOne], 'a = {1: 1};'),
    // Maybe we should make this work?
    testError('a = {#: 1}', [1], 'is not a Literal: 1'),

    // Interpolated parameter splicing.
    testStatement('function foo(#){}', [new jsAst.Parameter('x')],
        'function foo(x) {\n}'),
    testStatement('function foo(#){}', ['x'], 'function foo(x) {\n}'),
    testStatement('function foo(#){}', [[]], 'function foo() {\n}'),
    testStatement('function foo(#){}', [['x']], 'function foo(x) {\n}'),
    testStatement('function foo(#){}', [['x', 'y']], 'function foo(x, y) {\n}'),


    testStatement('a = #.#', [eVar,eOne], 'a = x[1];'),
    testStatement('a = #.#', [eVar,'foo'], 'a = x.foo;'),

    testStatement('function f(#) { return #.#; }', ['x', eVar,'foo'],
        'function f(x) {\n  return x.foo;\n}'),

    testStatement('#.prototype.# = function(#) { return #.# };',
        ['className', 'getterName', ['r', 'y'], 'r', 'fieldName'],
        'className.prototype.getterName = function(r, y) {\n'
        '  return r.fieldName;\n'
        '};'),

    testStatement('function foo(r, #) { return #[r](#) }',
        [['a', 'b'], 'g', ['b', 'a']],
        'function foo(r, a, b) {\n  return g[r](b, a);\n}'),

    // Sequence is printed flattened
    testStatement('x = #', [seq1], 'x = (1, 2, 3);'),
    testStatement('x = (#, #)', [seq1, seq1], 'x = (1, 2, 3, 1, 2, 3);'),
    testStatement('x = #, #', [seq1, seq1], 'x = (1, 2, 3), 1, 2, 3;'),
    testStatement(
        'for (i = 0, j = #, k = 0; ; ++i, ++j, ++k){}', [seq1],
        'for (i = 0, j = (1, 2, 3), k = 0;; ++i, ++j, ++k) {\n}'),
  ]));
}
