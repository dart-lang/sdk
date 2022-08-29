// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../mini_ast.dart';

main() {
  late Harness h;

  setUp(() {
    h = Harness();
  });

  group('Expressions:', () {
    group('integer literal', () {
      test('double context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: true)
              .checkType('double')
              .checkIr('1.0f')
              .inContext('double'),
        ]);
      });

      test('int context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('int'),
        ]);
      });

      test('num context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('num'),
        ]);
      });

      test('double? context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: true)
              .checkType('double')
              .checkIr('1.0f')
              .inContext('double?'),
        ]);
      });

      test('int? context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('int?'),
        ]);
      });

      test('unknown context', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('?'),
        ]);
      });

      test('unrelated context', () {
        // Note: an unrelated context can arise in the case of assigning to a
        // promoted variable, e.g.:
        //
        //   Object x;
        //   if (x is String) {
        //     x = 1;
        //   }
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIr('1')
              .inContext('String'),
        ]);
      });
    });

    group('Switch:', () {
      test('IR', () {
        h.run([
          switchExpr(expr('int'), [
            defaultExpr(intLiteral(0)),
          ]).checkIr('switchExpr(expr(int), case(heads(default), 0))').stmt,
        ]);
      });

      test('scrutinee expression context', () {
        h.run([
          switchExpr(expr('int').checkContext('?'), [
            defaultExpr(intLiteral(0)),
          ]).inContext('num'),
        ]);
      });

      test('body expression context', () {
        h.run([
          switchExpr(expr('int'), [
            defaultExpr(nullLiteral.checkContext('C?')),
          ]).inContext('C?'),
        ]);
      });

      test('least upper bound behavior', () {
        h.run([
          switchExpr(expr('int'), [
            caseExpr(intLiteral(0).pattern, expr('int')),
            defaultExpr(expr('double')),
          ]).checkType('num').stmt
        ]);
      });
    });
  });

  group('Statements:', () {
    group('Switch:', () {
      test('const pattern', () {
        h.run([
          switch_(
                  expr('int').checkContext('?'),
                  [
                    case_(intLiteral(0).pattern, [
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(const(0)), block(break())))'),
        ]);
      });

      group('var pattern:', () {
        test('untyped', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('int').checkContext('?'),
                    [
                      case_(x.pattern(), [
                        break_(),
                      ]),
                    ],
                    isExhaustive: false)
                .checkIr('switch(expr(int), '
                    'case(heads(varPattern(x, int)), '
                    'block(break())))'),
          ]);
        });

        test('typed', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('int').checkContext('?'),
                    [
                      case_(x.pattern(type: 'num'), [
                        break_(),
                      ]),
                    ],
                    isExhaustive: false)
                .checkIr('switch(expr(int), '
                    'case(heads(varPattern(x, num)), '
                    'block(break())))'),
          ]);
        });
      });

      test('scrutinee expression context', () {
        h.run([
          switch_(
              expr('int').checkContext('?'),
              [
                case_(intLiteral(0).pattern, [
                  break_(),
                ]),
              ],
              isExhaustive: false),
        ]);
      });

      test('merge cases', () {
        h.run([
          switch_(
                  expr('int'),
                  [
                    case_(intLiteral(0).pattern, []),
                    case_(intLiteral(1).pattern, [
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(const(0), const(1)), block(break())))'),
        ]);
      });

      test('merge labels', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          x.expr.as_('int').stmt,
          switch_(
              expr('int'),
              [
                case_(intLiteral(0).pattern, [], hasLabel: true),
                case_(intLiteral(1).pattern, [
                  x.expr.checkType('int?').stmt,
                  break_(),
                ]),
                case_(intLiteral(2).pattern, [
                  x.expr.checkType('int').stmt,
                  x.write(nullLiteral).stmt,
                  continue_(),
                ])
              ],
              isExhaustive: false),
        ]);
      });

      test('empty final case', () {
        h.run([
          switch_(
                  expr('int'),
                  [
                    case_(intLiteral(0).pattern, [
                      break_(),
                    ]),
                    case_(intLiteral(1).pattern, []),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(const(0)), block(break())), '
                  'case(heads(const(1)), block()))'),
        ]);
      });

      group('missing var:', () {
        test('default', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('int'),
                    [
                      case_(x.pattern(), []),
                      default_([])..errorId = 'DEFAULT',
                    ],
                    isExhaustive: true)
                .expectErrors({'missingMatchVar(DEFAULT, x)'}),
          ]);
        });

        test('case', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('int'),
                    [
                      case_(intLiteral(0).pattern, [])..errorId = 'CASE(0)',
                      case_(x.pattern(), []),
                    ],
                    isExhaustive: true)
                .expectErrors({'missingMatchVar(CASE(0), x)'}),
          ]);
        });
      });

      group('conflicting var:', () {
        test('explicit/explicit type', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('num'),
                    [
                      case_(x.pattern(type: 'int')..errorId = 'PATTERN(int x)',
                          []),
                      case_(x.pattern(type: 'num')..errorId = 'PATTERN(num x)',
                          []),
                    ],
                    isExhaustive: true)
                .expectErrors({
              'inconsistentMatchVar(pattern: PATTERN(num x), type: num, '
                  'previousPattern: PATTERN(int x), previousType: int)'
            }),
          ]);
        });

        test('explicit/implicit type', () {
          // TODO(paulberry): not sure whether this should be treated as a
          // conflict.  See https://github.com/dart-lang/language/issues/2424.
          var x = Var('x');
          h.run([
            switch_(
                    expr('int'),
                    [
                      case_(x.pattern()..errorId = 'PATTERN(x)', []),
                      case_(x.pattern(type: 'int')..errorId = 'PATTERN(int x)',
                          []),
                    ],
                    isExhaustive: true)
                .expectErrors({
              'inconsistentMatchVarExplicitness(pattern: PATTERN(int x), '
                  'previousPattern: PATTERN(x))'
            }),
          ]);
        });

        test('implicit/implicit type', () {
          // TODO(paulberry): need more support to be able to test this
        });
      });
    });

    group('Variable declaration:', () {
      test('initialized, typed', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'num', initializer: expr('int').checkContext('num'))
              .checkIr('match(expr(int), varPattern(x, num))'),
        ]);
      });

      test('initialized, untyped', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('int').checkContext('?'))
              .checkIr('match(expr(int), varPattern(x, int))'),
        ]);
      });

      test('uninitialized, typed', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int').checkIr('declare(varPattern(x, int))'),
        ]);
      });

      test('uninitialized, untyped', () {
        var x = Var('x');
        h.run([
          declare(x).checkIr('declare(varPattern(x, dynamic))'),
        ]);
      });

      test('promoted initializer', () {
        h.addSubtype('T&int', 'T', true);
        h.addSubtype('T&int', 'Object', true);
        h.addFactor('T', 'T&int', 'T');
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('T&int'))
              .checkIr('match(expr(T&int), varPattern(x, T))'),
        ]);
      });

      test('legal late pattern', () {
        var x = Var('x');
        h.run([
          match(x.pattern(), intLiteral(0), isLate: true)
              .checkIr('match_late(0, varPattern(x, int))'),
        ]);
      });

      test('illegal late pattern', () {
        h.run([
          match(intLiteral(1).pattern..errorId = 'PATTERN', intLiteral(0),
                  isLate: true)
              .expectErrors({'patternDoesNotAllowLate(PATTERN)'}),
        ]);
      });
    });
  });
}
