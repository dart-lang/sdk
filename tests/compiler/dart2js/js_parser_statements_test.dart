// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'mock_compiler.dart';
import 'package:compiler/src/js/js.dart' as jsAst;
import 'package:compiler/src/js/js.dart' show js;

Future testStatement(String statement, arguments, String expect) {
  jsAst.Node node = js.statement(statement, arguments);
  return MockCompiler.create((MockCompiler compiler) {
    String jsText = jsAst.prettyPrint(node, compiler.options,
        allowVariableMinification: false);

    Expect.stringEquals(expect.trim(), jsText.trim());
  });
}

Future testError(String statement, arguments, [String expect = ""]) {
  return new Future.sync(() {
    bool doCheck(exception) {
      String message = '$exception';
      Expect.isTrue(message.contains(expect), '"$message" contains "$expect"');
      return true;
    }

    void action() {
      js.statement(statement, arguments);
    }

    Expect.throws(action, doCheck);
  });
}

// Function declaration and named function.
const NAMED_FUNCTION_1 = r'''
function foo/*function declaration*/() {
  return function harry/*named function*/() { return #; }
}''';

const NAMED_FUNCTION_1_NAMED_HOLE = r'''
function foo/*function declaration*/() {
  return function harry/*named function*/() { return #hole; }
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

const MISC_1_NAMED_HOLE = r'''
function foo() {
  /a/;
  #hole;
}''';

const MISC_1_1 = r'''
function foo() {
  /a/;
  1;
  2;
}''';

void main() {
  var eOne = js('1');
  var eTwo = js('2');
  var eTrue = js('true');
  var eVar = js('x');
  var block12 = js.statement('{ 1; 2; }');
  var stm = js.statement('foo();');
  var seq1 = js('1, 2, 3');

  Expect.isTrue(eOne is jsAst.LiteralNumber);
  Expect.isTrue(eTrue is jsAst.LiteralBool);
  Expect.isTrue(block12 is jsAst.Block);

  asyncTest(() => Future.wait([
        // Interpolated Expressions are upgraded to ExpressionStatements.
        testStatement('{ #; #; }', [eOne, eOne], '{\n  1;\n  1;\n}'),
        testStatement(
            '{ #a; #b; }', {'a': eOne, 'b': eOne}, '{\n  1;\n  1;\n}'),

        // Interpolated sub-blocks are spliced.
        testStatement(
            '{ #; #; }', [block12, block12], '{\n  1;\n  2;\n  1;\n  2;\n}\n'),
        testStatement('{ #a; #b; }', {'a': block12, 'b': block12},
            '{\n  1;\n  2;\n  1;\n  2;\n}\n'),

        // If-condition.  Dart booleans are evaluated, JS Expression booleans are
        // substituted.
        testStatement('if (#) #', [eOne, block12], 'if (1) {\n  1;\n  2;\n}'),
        testStatement(
            'if (#) #;', [eTrue, block12], 'if (true) {\n  1;\n  2;\n}'),
        testStatement('if (#) #;', [eVar, block12], 'if (x) {\n  1;\n  2;\n}'),
        testStatement('if (#) #;', ['a', block12], 'if (a) {\n  1;\n  2;\n}'),
        testStatement('if (#) #;', [true, block12], '{\n  1;\n  2;\n}'),
        testStatement('if (#) #;', [false, block12], ';'),
        testStatement('if (#) 3; else #;', [true, block12], '3;'),
        testStatement(
            'if (#) 3; else #;', [false, block12], '{\n  1;\n  2;\n}'),
        testStatement(
            'if (#a) #b', {'a': eOne, 'b': block12}, 'if (1) {\n  1;\n  2;\n}'),
        testStatement('if (#a) #b;', {'a': eTrue, 'b': block12},
            'if (true) {\n  1;\n  2;\n}'),
        testStatement('if (#a) #b;', {'a': eVar, 'b': block12},
            'if (x) {\n  1;\n  2;\n}'),
        testStatement(
            'if (#a) #b;', {'a': 'a', 'b': block12}, 'if (a) {\n  1;\n  2;\n}'),
        testStatement(
            'if (#a) #b;', {'a': true, 'b': block12}, '{\n  1;\n  2;\n}'),
        testStatement('if (#a) #b;', {'a': false, 'b': block12}, ';'),
        testStatement('if (#a) 3; else #b;', {'a': true, 'b': block12}, '3;'),
        testStatement('if (#a) 3; else #b;', {'a': false, 'b': block12},
            '{\n  1;\n  2;\n}'),

        testStatement(
            'while (#) #', [eOne, block12], 'while (1) {\n  1;\n  2;\n}'),
        testStatement(
            'while (#) #;', [eTrue, block12], 'while (true) {\n  1;\n  2;\n}'),
        testStatement(
            'while (#) #;', [eVar, block12], 'while (x) {\n  1;\n  2;\n}'),
        testStatement(
            'while (#) #;', ['a', block12], 'while (a) {\n  1;\n  2;\n}'),
        testStatement('while (#) #;', ['a', stm], 'while (a)\n  foo();'),

        testStatement(
            'do { {print(1);} do while(true); while (false) } while ( true )',
            [],
            '''
do {
  print(1);
  do
    while (true)
      ;
  while (false);
} while (true);
'''),
        testStatement('do #; while ( # )', [block12, eOne],
            'do {\n  1;\n  2;\n} while (1); '),
        testStatement('do #; while ( # )', [block12, eTrue],
            'do {\n  1;\n  2;\n} while (true); '),
        testStatement('do #; while ( # );', [block12, eVar],
            'do {\n  1;\n  2;\n} while (x);'),
        testStatement('do { # } while ( # )', [block12, 'a'],
            'do {\n  1;\n  2;\n} while (a);'),
        testStatement(
            'do #; while ( # )', [stm, 'a'], 'do\n  foo();\nwhile (a);'),

        testStatement('switch (#) {}', [eOne], 'switch (1) {\n}'),
        testStatement('''
        switch (#) {
          case #: { # }
        }''', [eTrue, eOne, block12],
            'switch (true) {\n  case 1:\n    1;\n    2;\n}'),
        testStatement('''
        switch (#) {
          case #: { # }
            break;
          case #: { # }
          default: { # }
        }''', [eTrue, eOne, block12, eTwo, block12, stm], '''
switch (true) {
  case 1:
    1;
    2;
    break;
  case 2:
    1;
    2;
  default:
    foo();
}'''),

        testStatement(NAMED_FUNCTION_1, [eOne], NAMED_FUNCTION_1_ONE),
        testStatement(
            NAMED_FUNCTION_1_NAMED_HOLE, {'hole': eOne}, NAMED_FUNCTION_1_ONE),

        testStatement(MISC_1, [block12], MISC_1_1),
        testStatement(MISC_1_NAMED_HOLE, {'hole': block12}, MISC_1_1),

        // Argument list splicing.
        testStatement('foo(#)', [[]], 'foo();'),
        testStatement(
            'foo(#)',
            [
              [eOne]
            ],
            'foo(1);'),
        testStatement('foo(#)', [eOne], 'foo(1);'),
        testStatement(
            'foo(#)',
            [
              [eTrue, eOne]
            ],
            'foo(true, 1);'),
        testStatement('foo(#a)', {'a': []}, 'foo();'),
        testStatement(
            'foo(#a)',
            {
              'a': [eOne]
            },
            'foo(1);'),
        testStatement('foo(#a)', {'a': eOne}, 'foo(1);'),
        testStatement(
            'foo(#a)',
            {
              'a': [eTrue, eOne]
            },
            'foo(true, 1);'),

        testStatement('foo(2,#)', [[]], 'foo(2);'),
        testStatement(
            'foo(2,#)',
            [
              [eOne]
            ],
            'foo(2, 1);'),
        testStatement('foo(2,#)', [eOne], 'foo(2, 1);'),
        testStatement(
            'foo(2,#)',
            [
              [eTrue, eOne]
            ],
            'foo(2, true, 1);'),
        testStatement('foo(2,#a)', {'a': []}, 'foo(2);'),
        testStatement(
            'foo(2,#a)',
            {
              'a': [eOne]
            },
            'foo(2, 1);'),
        testStatement('foo(2,#a)', {'a': eOne}, 'foo(2, 1);'),
        testStatement(
            'foo(2,#a)',
            {
              'a': [eTrue, eOne]
            },
            'foo(2, true, 1);'),

        testStatement('foo(#,3)', [[]], 'foo(3);'),
        testStatement(
            'foo(#,3)',
            [
              [eOne]
            ],
            'foo(1, 3);'),
        testStatement('foo(#,3)', [eOne], 'foo(1, 3);'),
        testStatement(
            'foo(#,3)',
            [
              [eTrue, eOne]
            ],
            'foo(true, 1, 3);'),
        testStatement('foo(#a,3)', {'a': []}, 'foo(3);'),
        testStatement(
            'foo(#a,3)',
            {
              'a': [eOne]
            },
            'foo(1, 3);'),
        testStatement('foo(#a,3)', {'a': eOne}, 'foo(1, 3);'),
        testStatement(
            'foo(#a,3)',
            {
              'a': [eTrue, eOne]
            },
            'foo(true, 1, 3);'),

        testStatement('foo(2,#,3)', [[]], 'foo(2, 3);'),
        testStatement(
            'foo(2,#,3)',
            [
              [eOne]
            ],
            'foo(2, 1, 3);'),
        testStatement('foo(2,#,3)', [eOne], 'foo(2, 1, 3);'),
        testStatement(
            'foo(2,#,3)',
            [
              [eTrue, eOne]
            ],
            'foo(2, true, 1, 3);'),
        testStatement('foo(2,#a,3)', {'a': []}, 'foo(2, 3);'),
        testStatement(
            'foo(2,#a,3)',
            {
              'a': [eOne]
            },
            'foo(2, 1, 3);'),
        testStatement('foo(2,#a,3)', {'a': eOne}, 'foo(2, 1, 3);'),
        testStatement(
            'foo(2,#a,3)',
            {
              'a': [eTrue, eOne]
            },
            'foo(2, true, 1, 3);'),

        // Interpolated Literals
        testStatement('a = {#: 1}', [eOne], 'a = {1: 1};'),
        testStatement('a = {#a: 1}', {'a': eOne}, 'a = {1: 1};'),
        // Maybe we should make this work?
        testError('a = {#: 1}', [1], 'is not a Literal: 1'),
        testError('a = {#a: 1}', {'a': 1}, 'is not a Literal: 1'),

        // Interpolated parameter splicing.
        testStatement('function foo(#){}', [new jsAst.Parameter('x')],
            'function foo(x) {\n}'),
        testStatement('function foo(#){}', ['x'], 'function foo(x) {\n}'),
        testStatement('function foo(#){}', [[]], 'function foo() {\n}'),
        testStatement(
            'function foo(#){}',
            [
              ['x']
            ],
            'function foo(x) {\n}'),
        testStatement(
            'function foo(#){}',
            [
              ['x', 'y']
            ],
            'function foo(x, y) {\n}'),
        testStatement('function foo(#a){}', {'a': new jsAst.Parameter('x')},
            'function foo(x) {\n}'),
        testStatement('function foo(#a){}', {'a': 'x'}, 'function foo(x) {\n}'),
        testStatement('function foo(#a){}', {'a': []}, 'function foo() {\n}'),
        testStatement(
            'function foo(#a){}',
            {
              'a': ['x']
            },
            'function foo(x) {\n}'),
        testStatement(
            'function foo(#a){}',
            {
              'a': ['x', 'y']
            },
            'function foo(x, y) {\n}'),

        testStatement(
            'function foo() async {}', [], 'function foo() async {\n}'),
        testStatement(
            'function foo() sync* {}', [], 'function foo() sync* {\n}'),
        testStatement(
            'function foo() async* {}', [], 'function foo() async* {\n}'),

        testStatement('a = #.#', [eVar, eOne], 'a = x[1];'),
        testStatement('a = #.#', [eVar, 'foo'], 'a = x.foo;'),
        testStatement('a = #a.#b', {'a': eVar, 'b': eOne}, 'a = x[1];'),
        testStatement('a = #a.#b', {'a': eVar, 'b': 'foo'}, 'a = x.foo;'),

        testStatement('function f(#) { return #.#; }', ['x', eVar, 'foo'],
            'function f(x) {\n  return x.foo;\n}'),
        testStatement(
            'function f(#a) { return #b.#c; }',
            {'a': 'x', 'b': eVar, 'c': 'foo'},
            'function f(x) {\n  return x.foo;\n}'),

        testStatement(
            '#.prototype.# = function(#) { return #.# };',
            [
              'className',
              'getterName',
              ['r', 'y'],
              'r',
              'fieldName'
            ],
            'className.prototype.getterName = function(r, y) {\n'
            '  return r.fieldName;\n'
            '};'),
        testStatement(
            '#a.prototype.#b = function(#c) { return #d.#e };',
            {
              'a': 'className',
              'b': 'getterName',
              'c': ['r', 'y'],
              'd': 'r',
              'e': 'fieldName'
            },
            'className.prototype.getterName = function(r, y) {\n'
            '  return r.fieldName;\n'
            '};'),

        testStatement(
            'function foo(r, #) { return #[r](#) }',
            [
              ['a', 'b'],
              'g',
              ['b', 'a']
            ],
            'function foo(r, a, b) {\n  return g[r](b, a);\n}'),
        testStatement(
            'function foo(r, #a) { return #b[r](#c) }',
            {
              'a': ['a', 'b'],
              'b': 'g',
              'c': ['b', 'a']
            },
            'function foo(r, a, b) {\n  return g[r](b, a);\n}'),

        // Sequence is printed flattened
        testStatement('x = #', [seq1], 'x = (1, 2, 3);'),
        testStatement('x = (#, #)', [seq1, seq1], 'x = (1, 2, 3, 1, 2, 3);'),
        testStatement('x = #, #', [seq1, seq1], 'x = (1, 2, 3), 1, 2, 3;'),
        testStatement('for (i = 0, j = #, k = 0; ; ++i, ++j, ++k){}', [seq1],
            'for (i = 0, j = (1, 2, 3), k = 0;; ++i, ++j, ++k) {\n}'),
        testStatement('x = #a', {'a': seq1}, 'x = (1, 2, 3);'),
        testStatement(
            'x = (#a, #b)', {'a': seq1, 'b': seq1}, 'x = (1, 2, 3, 1, 2, 3);'),
        testStatement(
            'x = #a, #b', {'a': seq1, 'b': seq1}, 'x = (1, 2, 3), 1, 2, 3;'),
        testStatement(
            'for (i = 0, j = #a, k = 0; ; ++i, ++j, ++k){}',
            {'a': seq1},
            'for (i = 0, j = (1, 2, 3), k = 0;; ++i, ++j, ++k) {\n}'),

        // Use the same name several times.
        testStatement(
            '#a.prototype.#a = function(#b) { return #c.#c };',
            {
              'a': 'name1_2',
              'b': ['r', 'y'],
              'c': 'name4_5'
            },
            'name1_2.prototype.name1_2 = function(r, y) {\n'
            '  return name4_5.name4_5;\n'
            '};'),

        testStatement('label: while (a) { label2: break label;}', [],
            'label:\n  while (a)\n    label2:\n      break label;\n  '),

        testStatement('var # = 3', ['x'], 'var x = 3;'),
        testStatement(
            'var # = 3', [new jsAst.VariableDeclaration('x')], 'var x = 3;'),
        testStatement(
            'var # = 3, # = #', ['x', 'y', js.number(2)], 'var x = 3, y = 2;'),
        testStatement('var #a = 3, #b = #c',
            {"a": 'x', "b": 'y', "c": js.number(2)}, 'var x = 3, y = 2;'),
        testStatement('function #() {}', ['x'], 'function x() {\n}'),
        testStatement('function #() {}', [new jsAst.VariableDeclaration('x')],
            'function x() {\n}'),
        testStatement('try {} catch (#) {}', ['x'], 'try {\n} catch (x) {\n}'),
        testStatement(
            'try {} catch (#a) {}', {"a": 'x'}, 'try {\n} catch (x) {\n}'),
        testStatement(
            'try {} catch (#a) {}',
            {"a": new jsAst.VariableDeclaration('x')},
            'try {\n} catch (x) {\n}'),

        // Test that braces around a single-statement block are removed by printer.
        testStatement('while (a) {foo()}', [], 'while (a)\n  foo();'),
        testStatement('if (a) {foo();}', [], 'if (a)\n  foo();'),
        testStatement('if (a) {foo();} else {foo2();}', [],
            'if (a)\n  foo();\nelse\n  foo2();'),
        testStatement('if (a) foo(); else {foo2();}', [],
            'if (a)\n  foo();\nelse\n  foo2();'),
        testStatement('do {foo();} while(a);', [], 'do\n  foo();\nwhile (a);'),
        testStatement('label: {foo();}', [], 'label:\n  foo();'),
        testStatement(
            'for (var key in a) {foo();}', [], 'for (var key in a)\n  foo();'),
        // `label: break label;` gives problems on IE. Test that it is avoided.
        testStatement('label: {break label;}', [], ';'),
        // This works on IE:
        testStatement('label: {label2: {break label;}}', [],
            'label:\n  label2:\n    break label;\n'),
        // Test dangling else:
        testStatement('if (a) {if (b) {foo1();}} else {foo2();}', [], """
if (a) {
  if (b)
    foo1();
} else
  foo2();"""),
        testStatement('if (a) {if (b) {foo1();} else {foo2();}}', [], """
if (a)
  if (b)
    foo1();
  else
    foo2();
"""),
        testStatement(
            'if (a) {if (b) {foo1();} else {foo2();}} else {foo3();}', [], """
if (a)
  if (b)
    foo1();
  else
    foo2();
else
  foo3();"""),
        testStatement(
            'if (a) {while (true) if (b) {foo1();}} else {foo2();}', [], """
if (a) {
  while (true)
    if (b)
      foo1();
} else
  foo2();"""),
      ]));
}
