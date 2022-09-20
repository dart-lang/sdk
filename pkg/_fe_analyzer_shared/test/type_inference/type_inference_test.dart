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
            default_.thenExpr(intLiteral(0)),
          ]).checkIr('switchExpr(expr(int), case(default, 0))').stmt,
        ]);
      });

      test('scrutinee expression context', () {
        h.run([
          switchExpr(expr('int').checkContext('?'), [
            default_.thenExpr(intLiteral(0)),
          ]).inContext('num'),
        ]);
      });

      test('body expression context', () {
        h.run([
          switchExpr(expr('int'), [
            default_.thenExpr(nullLiteral.checkContext('C?')),
          ]).inContext('C?'),
        ]);
      });

      test('least upper bound behavior', () {
        h.run([
          switchExpr(expr('int'), [
            intLiteral(0).pattern.thenExpr(expr('int')),
            default_.thenExpr(expr('double')),
          ]).checkType('num').stmt
        ]);
      });

      test('guard', () {
        var i = Var('i');
        h.run([
          switchExpr(expr('int'), [
            i
                .pattern()
                .when(i.expr
                    .checkType('int')
                    .eq(expr('num'))
                    .checkContext('bool'))
                .thenExpr(expr('String')),
          ])
              .checkIr('switchExpr(expr(int), '
                  'case(head(varPattern(i, matchedType: int, '
                  'staticType: int), ==(i, expr(num))), expr(String)))')
              .stmt,
        ]);
      });

      group('Guard not assignable to bool', () {
        test('int', () {
          var x = Var('x');
          h.run([
            switchExpr(expr('int'), [
              x
                  .pattern()
                  .when(expr('int')..errorId = 'GUARD')
                  .thenExpr(expr('int')),
            ]).stmt,
          ], expectedErrors: {
            'nonBooleanCondition(GUARD)'
          });
        });

        test('bool', () {
          var x = Var('x');
          h.run([
            switchExpr(expr('int'), [
              x.pattern().when(expr('bool')).thenExpr(expr('int')),
            ]).stmt,
          ], expectedErrors: {});
        });

        test('dynamic', () {
          var x = Var('x');
          h.run([
            switchExpr(expr('int'), [
              x.pattern().when(expr('dynamic')).thenExpr(expr('int')),
            ]).stmt,
          ], expectedErrors: {});
        });
      });
    });
  });

  group('Statements:', () {
    group('If:', () {
      test('Condition context', () {
        h.run([
          if_(expr('dynamic').checkContext('bool'), [
            expr('Object').stmt,
          ]).checkIr('if(expr(dynamic), block(stmt(expr(Object))), noop)'),
        ]);
      });

      test('With else', () {
        h.run([
          if_(expr('bool'), [
            expr('Object').stmt,
          ], [
            expr('String').stmt,
          ]).checkIr('if(expr(bool), block(stmt(expr(Object))), '
              'block(stmt(expr(String))))'),
        ]);
      });
    });

    group('If-case:', () {
      test('Type schema', () {
        var x = Var('x');
        h.run([
          ifCase(expr('int').checkContext('?'), x.pattern(type: 'num'), [
            expr('Object').stmt,
          ]).checkIr('ifCase(expr(int), '
              'varPattern(x, matchedType: int, staticType: num), true, '
              'block(stmt(expr(Object))), noop)'),
        ]);
      });

      test('With else', () {
        var x = Var('x');
        h.run([
          ifCase(expr('num'), x.pattern(type: 'int'), [
            expr('Object').stmt,
          ], else_: [
            expr('String').stmt,
          ]).checkIr('ifCase(expr(num), '
              'varPattern(x, matchedType: num, staticType: int), true, '
              'block(stmt(expr(Object))), block(stmt(expr(String))))'),
        ]);
      });

      test('With guard', () {
        var x = Var('x');
        h.run([
          ifCase(expr('num'),
              x.pattern(type: 'int').when(x.expr.eq(intLiteral(0))), [
            expr('Object').stmt,
          ]).checkIr('ifCase(expr(num), '
              'varPattern(x, matchedType: num, staticType: int), ==(x, 0), '
              'block(stmt(expr(Object))), noop)'),
        ]);
      });

      test('Allows refutable patterns', () {
        var x = Var('x');
        h.run([
          ifCase(expr('num').checkContext('?'), x.pattern(type: 'int'), [
            expr('Object').stmt,
          ]).checkIr('ifCase(expr(num), '
              'varPattern(x, matchedType: num, staticType: int), true, '
              'block(stmt(expr(Object))), noop)'),
        ]);
      });

      group('Guard not assignable to bool', () {
        test('int', () {
          var x = Var('x');
          h.run([
            ifCase(expr('int'),
                x.pattern().when(expr('int')..errorId = 'GUARD'), []),
          ], expectedErrors: {
            'nonBooleanCondition(GUARD)'
          });
        });

        test('bool', () {
          var x = Var('x');
          h.run([
            ifCase(expr('int'), x.pattern().when(expr('bool')), []),
          ], expectedErrors: {});
        });

        test('dynamic', () {
          var x = Var('x');
          h.run([
            ifCase(expr('int'), x.pattern().when(expr('dynamic')), []),
          ], expectedErrors: {});
        });
      });
    });

    group('Switch:', () {
      test('Empty', () {
        h.run([
          switch_(expr('int'), [],
              isExhaustive: false, expectLastCaseTerminates: true),
        ]);
      });

      test('Exhaustive', () {
        h.run([
          switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  break_(),
                ]),
              ],
              isExhaustive: true,
              expectIsExhaustive: true),
        ]);
      });

      test('No default', () {
        h.run([
          switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  break_(),
                ]),
              ],
              isExhaustive: false,
              expectHasDefault: false,
              expectIsExhaustive: false),
        ]);
      });

      test('Has default', () {
        h.run([
          switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  break_(),
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isExhaustive: false,
              expectHasDefault: true,
              expectIsExhaustive: true),
        ]);
      });

      test('Last case terminates', () {
        h.run([
          switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int').stmt,
                ]),
                intLiteral(1).pattern.then([
                  break_(),
                ]),
              ],
              isExhaustive: false,
              expectLastCaseTerminates: true),
        ]);
      });

      test("Last case doesn't terminate", () {
        h.run([
          switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  break_(),
                ]),
                intLiteral(1).pattern.then([
                  expr('int').stmt,
                ]),
              ],
              isExhaustive: false,
              expectLastCaseTerminates: false),
        ]);
      });

      test('Scrutinee type', () {
        h.run([
          switch_(expr('int'), [],
              isExhaustive: false, expectScrutineeType: 'int'),
        ]);
      });

      test('const pattern', () {
        h.run([
          switch_(
                  expr('int').checkContext('?'),
                  [
                    intLiteral(0).pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(head(const(0, matchedType: int), true)), '
                  'block(break())))'),
        ]);
      });

      group('var pattern:', () {
        test('untyped', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('int').checkContext('?'),
                    [
                      x.pattern().then([
                        break_(),
                      ]),
                    ],
                    isExhaustive: false)
                .checkIr('switch(expr(int), '
                    'case(heads(head(varPattern(x, matchedType: int, '
                    'staticType: int), true)), block(break())))'),
          ]);
        });

        test('typed', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('int').checkContext('?'),
                    [
                      x.pattern(type: 'num').then([
                        break_(),
                      ]),
                    ],
                    isExhaustive: false)
                .checkIr('switch(expr(int), '
                    'case(heads(head(varPattern(x, matchedType: int, '
                    'staticType: num), true)), block(break())))'),
          ]);
        });
      });

      test('scrutinee expression context', () {
        h.run([
          switch_(
              expr('int').checkContext('?'),
              [
                intLiteral(0).pattern.then([
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
                    intLiteral(0).pattern.then([]),
                    intLiteral(1).pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(head(const(0, matchedType: int), true), '
                  'head(const(1, matchedType: int), true)), block(break())))'),
        ]);
      });

      test('merge labels', () {
        var x = Var('x');
        var l = Label('l');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          x.expr.as_('int').stmt,
          switch_(
                  expr('int'),
                  [
                    l.then(intLiteral(0).pattern).then([]),
                    intLiteral(1).pattern.then([
                      x.expr.checkType('int?').stmt,
                      break_(),
                    ]),
                    intLiteral(2).pattern.then([
                      x.expr.checkType('int').stmt,
                      x.write(nullLiteral).stmt,
                      continue_(),
                    ])
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(head(const(0, matchedType: int), true), '
                  'head(const(1, matchedType: int), true), l), '
                  'block(stmt(x), break())), '
                  'case(heads(head(const(2, matchedType: int), true)), '
                  'block(stmt(x), stmt(null), continue())))'),
        ]);
      });

      test('empty final case', () {
        h.run([
          switch_(
                  expr('int'),
                  [
                    intLiteral(0).pattern.then([
                      break_(),
                    ]),
                    intLiteral(1).pattern.then([]),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(head(const(0, matchedType: int), true)), '
                  'block(break())), '
                  'case(heads(head(const(1, matchedType: int), true)), '
                  'block()))'),
        ]);
      });

      test('guard', () {
        var i = Var('i');
        h.run([
          switch_(
                  expr('int'),
                  [
                    i
                        .pattern()
                        .when(i.expr
                            .checkType('int')
                            .eq(expr('num'))
                            .checkContext('bool'))
                        .then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: true)
              .checkIr('switch(expr(int), '
                  'case(heads(head(varPattern(i, matchedType: int, '
                  'staticType: int), ==(i, expr(num)))), block(break())))'),
        ]);
      });

      group('missing var:', () {
        test('default', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('int'),
                [
                  x.pattern().then([]),
                  (default_..errorId = 'DEFAULT').then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'missingMatchVar(DEFAULT, x)'
          });
        });

        test('case', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('int'),
                [
                  (intLiteral(0).pattern..errorId = 'CASE(0)').then([]),
                  x.pattern().then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'missingMatchVar(CASE(0), x)'
          });
        });

        test('label', () {
          var x = Var('x');
          var l = Label('l')..errorId = 'LABEL';
          h.run([
            switch_(
                expr('int'),
                [
                  l.then(x.pattern()).then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'missingMatchVar(LABEL, x)'
          });
        });
      });

      group('conflicting var:', () {
        test('explicit/explicit type', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('num'),
                [
                  (x.pattern(type: 'int')..errorId = 'PATTERN(int x)').then([]),
                  (x.pattern(type: 'num')..errorId = 'PATTERN(num x)').then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'inconsistentMatchVar(pattern: PATTERN(num x), type: num, '
                'previousPattern: PATTERN(int x), previousType: int)'
          });
        });

        test('explicit/implicit type', () {
          // TODO(paulberry): not sure whether this should be treated as a
          // conflict.  See https://github.com/dart-lang/language/issues/2424.
          var x = Var('x');
          h.run([
            switch_(
                expr('int'),
                [
                  (x.pattern()..errorId = 'PATTERN(x)').then([]),
                  (x.pattern(type: 'int')..errorId = 'PATTERN(int x)').then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'inconsistentMatchVarExplicitness(pattern: PATTERN(int x), '
                'previousPattern: PATTERN(x))'
          });
        });

        test('implicit/implicit type', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('List<int>'),
                [
                  (x.pattern()..errorId = 'PATTERN(List<int> x)').then([]),
                  listPattern([x.pattern()..errorId = 'PATTERN(int x)'])
                      .then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'inconsistentMatchVar(pattern: PATTERN(int x), type: int, '
                'previousPattern: PATTERN(List<int> x), '
                'previousType: List<int>)'
          });
        });
      });

      group('Case completes normally:', () {
        test('Reported when patterns disabled', () {
          h.patternsEnabled = false;
          h.run([
            (switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int').stmt,
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isExhaustive: true,
            )..errorId = 'SWITCH'),
          ], expectedErrors: {
            'switchCaseCompletesNormally(SWITCH, 0, 1)'
          });
        });

        test('Handles cases that share a body', () {
          h.patternsEnabled = false;
          h.run([
            (switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([]),
                intLiteral(1).pattern.then([]),
                intLiteral(2).pattern.then([
                  expr('int').stmt,
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isExhaustive: true,
            )..errorId = 'SWITCH'),
          ], expectedErrors: {
            'switchCaseCompletesNormally(SWITCH, 0, 3)'
          });
        });

        test('Not reported when unreachable', () {
          h.patternsEnabled = false;
          h.run([
            switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  break_(),
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isExhaustive: true,
            ),
          ], expectedErrors: {});
        });

        test('Not reported for final case', () {
          h.patternsEnabled = false;
          h.run([
            switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int').stmt,
                ]),
              ],
              isExhaustive: false,
            ),
          ], expectedErrors: {});
        });

        test('Not reported in legacy mode', () {
          // In legacy mode, the criteria for reporting a switch case that
          // "falls through" are less accurate (since flow analysis isn't
          // available in legacy mode).  This logic is not currently implemented
          // in the shared analyzer.
          h.legacy = true;
          h.run([
            switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int').stmt,
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isExhaustive: false,
            ),
          ], expectedErrors: {});
        });

        test('Not reported when patterns enabled', () {
          // When patterns are enabled, there is an implicit `break` at the end
          // of every switch body.
          h.patternsEnabled = true;
          h.run([
            switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int').stmt,
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isExhaustive: false,
            ),
          ], expectedErrors: {});
        });
      });

      group('Case expression type mismatch:', () {
        group('Pre-null safety:', () {
          test('subtype', () {
            h.legacy = true;
            h.run([
              switch_(
                  expr('num'),
                  [
                    expr('int').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('supertype', () {
            h.legacy = true;
            h.run([
              switch_(
                  expr('int'),
                  [
                    expr('num').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('unrelated types', () {
            h.legacy = true;
            h.run([
              switch_(
                  expr('int')..errorId = 'SCRUTINEE',
                  [
                    (expr('String')..errorId = 'EXPRESSION').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
            ], expectedErrors: {
              'caseExpressionTypeMismatch(scrutinee: SCRUTINEE, '
                  'caseExpression: EXPRESSION, scrutineeType: int, '
                  'caseExpressionType: String, nullSafetyEnabled: false)'
            });
          });

          test('dynamic scrutinee', () {
            h.legacy = true;
            h.run([
              switch_(
                  expr('dynamic'),
                  [
                    expr('int').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('dynamic case', () {
            h.legacy = true;
            h.run([
              switch_(
                  expr('int'),
                  [
                    expr('dynamic').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });
        });

        group('Null safe, patterns disabled:', () {
          test('subtype', () {
            h.patternsEnabled = false;
            h.run([
              switch_(
                  expr('num'),
                  [
                    expr('int').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('supertype', () {
            h.patternsEnabled = false;
            h.run([
              switch_(
                  expr('int')..errorId = 'SCRUTINEE',
                  [
                    (expr('num')..errorId = 'EXPRESSION').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
            ], expectedErrors: {
              'caseExpressionTypeMismatch(scrutinee: SCRUTINEE, '
                  'caseExpression: EXPRESSION, scrutineeType: int, '
                  'caseExpressionType: num, nullSafetyEnabled: true)'
            });
          });

          test('unrelated types', () {
            h.patternsEnabled = false;
            h.run([
              switch_(
                  expr('int')..errorId = 'SCRUTINEE',
                  [
                    (expr('String')..errorId = 'EXPRESSION').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
            ], expectedErrors: {
              'caseExpressionTypeMismatch(scrutinee: SCRUTINEE, '
                  'caseExpression: EXPRESSION, scrutineeType: int, '
                  'caseExpressionType: String, nullSafetyEnabled: true)'
            });
          });

          test('dynamic scrutinee', () {
            h.patternsEnabled = false;
            h.run([
              switch_(
                  expr('dynamic'),
                  [
                    expr('int').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('dynamic case', () {
            h.patternsEnabled = false;
            h.run([
              switch_(
                  expr('int')..errorId = 'SCRUTINEE',
                  [
                    (expr('dynamic')..errorId = 'EXPRESSION').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
            ], expectedErrors: {
              'caseExpressionTypeMismatch(scrutinee: SCRUTINEE, '
                  'caseExpression: EXPRESSION, scrutineeType: int, '
                  'caseExpressionType: dynamic, nullSafetyEnabled: true)'
            });
          });
        });

        group('Patterns enabled:', () {
          test('subtype', () {
            h.run([
              switch_(
                  expr('num'),
                  [
                    expr('int').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('supertype', () {
            h.run([
              switch_(
                  expr('int'),
                  [
                    expr('num').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('unrelated types', () {
            h.run([
              switch_(
                  expr('int'),
                  [
                    expr('String').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('dynamic scrutinee', () {
            h.run([
              switch_(
                  expr('dynamic'),
                  [
                    expr('int').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });

          test('dynamic case', () {
            h.run([
              switch_(
                  expr('int'),
                  [
                    expr('dynamic').pattern.then([
                      break_(),
                    ]),
                  ],
                  isExhaustive: false),
            ]);
          });
        });
      });

      group('Pre-merged', () {
        // The CFE merges cases that share a body at parse time, so make sure we
        // we can handle merged cases
        test('Empty', () {
          // During CFE error recovery, there can be an empty case.
          h.run([
            switch_(
              expr('int'),
              [
                mergedCase([]).then([
                  break_(),
                ]),
              ],
              isExhaustive: false,
            ).checkIr('switch(expr(int), case(heads(), block()))'),
          ], errorRecoveryOk: true);
        });

        test('Multiple', () {
          h.run([
            switch_(
                    expr('int'),
                    [
                      mergedCase([intLiteral(0).pattern, intLiteral(1).pattern])
                          .then([
                        break_(),
                      ]),
                    ],
                    isExhaustive: false)
                .checkIr('switch(expr(int), '
                    'case(heads(head(const(0, matchedType: int), true), '
                    'head(const(1, matchedType: int), true)), '
                    'block(break())))'),
          ]);
        });
      });

      group('Guard not assignable to bool', () {
        test('int', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('int'),
                [
                  x.pattern().when(expr('int')..errorId = 'GUARD').then([
                    break_(),
                  ]),
                ],
                isExhaustive: false),
          ], expectedErrors: {
            'nonBooleanCondition(GUARD)'
          });
        });

        test('bool', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('int'),
                [
                  x.pattern().when(expr('bool')).then([
                    break_(),
                  ]),
                ],
                isExhaustive: false),
          ], expectedErrors: {});
        });

        test('dynamic', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('int'),
                [
                  x.pattern().when(expr('dynamic')).then([
                    break_(),
                  ]),
                ],
                isExhaustive: false),
          ], expectedErrors: {});
        });
      });
    });

    group('Variable declaration:', () {
      test('initialized, typed', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'num', initializer: expr('int').checkContext('num'))
              .checkIr('match(expr(int), '
                  'varPattern(x, matchedType: int, staticType: num))'),
        ]);
      });

      test('initialized, untyped', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('int').checkContext('?'))
              .checkIr('match(expr(int), '
                  'varPattern(x, matchedType: int, staticType: int))'),
        ]);
      });

      test('uninitialized, typed', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int').checkIr(
              'declare(varPattern(x, matchedType: int, staticType: int))'),
        ]);
      });

      test('uninitialized, untyped', () {
        var x = Var('x');
        h.run([
          declare(x).checkIr('declare(varPattern(x, matchedType: dynamic, '
              'staticType: dynamic))'),
        ]);
      });

      test('promoted initializer', () {
        h.addSubtype('T&int', 'T', true);
        h.addSubtype('T&int', 'Object', true);
        h.addFactor('T', 'T&int', 'T');
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('T&int')).checkIr('match(expr(T&int), '
              'varPattern(x, matchedType: T&int, staticType: T))'),
        ]);
      });

      test('legal late pattern', () {
        var x = Var('x');
        h.run([
          match(x.pattern(), intLiteral(0), isLate: true)
              .checkIr('match_late(0, varPattern(x, matchedType: int, '
                  'staticType: int))'),
        ]);
      });

      test('illegal late pattern', () {
        h.run([
          (match(
              listPattern([wildcard()])..errorId = 'PATTERN', expr('List<int>'),
              isLate: true)
            ..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'patternDoesNotAllowLate(PATTERN)'
        });
      });

      test('illegal refutable pattern', () {
        h.run([
          (match(intLiteral(1).pattern..errorId = 'PATTERN', intLiteral(0))
            ..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
        });
      });
    });
  });

  group('Patterns:', () {
    group('Cast:', () {
      test('Type schema', () {
        var x = Var('x');
        h.run([
          switch_(
                  expr('num'),
                  [
                    x.pattern().as_('int').then([]),
                  ],
                  isExhaustive: true)
              .checkIr('switch(expr(num), '
                  'case(heads(head(castPattern(varPattern(x, matchedType: int, '
                  'staticType: int), int, matchedType: num), true)), '
                  'block()))'),
        ]);
      });

      group('Missing var:', () {
        test('default', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('int'),
                [
                  x.pattern().as_('int').then([]),
                  (default_..errorId = 'DEFAULT').then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'missingMatchVar(DEFAULT, x)'
          });
        });

        test('case', () {
          var x = Var('x');
          h.run([
            switch_(
                expr('int'),
                [
                  (intLiteral(0).pattern..errorId = 'CASE_0').then([]),
                  x.pattern().as_('int').then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'missingMatchVar(CASE_0, x)'
          });
        });

        test('label', () {
          var x = Var('x');
          var l = Label('l')..errorId = 'LABEL';
          h.run([
            switch_(
                expr('int'),
                [
                  l.then(x.pattern().as_('int')).then([]),
                ],
                isExhaustive: true),
          ], expectedErrors: {
            'missingMatchVar(LABEL, x)'
          });
        });
      });

      test('conflicting var:', () {
        var x = Var('x');
        h.run([
          switch_(
              expr('num'),
              [
                (x.pattern()..errorId = 'INT_PATTERN').as_('int').then([]),
                (x.pattern()..errorId = 'NUM_PATTERN').as_('num').then([]),
              ],
              isExhaustive: true),
        ], expectedErrors: {
          'inconsistentMatchVar(pattern: NUM_PATTERN, type: num, '
              'previousPattern: INT_PATTERN, previousType: int)'
        });
      });

      group('Refutability:', () {
        test('When matched type is a subtype of variable type', () {
          var x = Var('x');
          h.run([
            match(x.pattern().as_('num'), expr('int'))
                .checkIr('match(expr(int), '
                    'castPattern(varPattern(x, matchedType: num, '
                    'staticType: num), num, matchedType: int))'),
          ]);
        });

        test('When matched type is dynamic', () {
          var x = Var('x');
          h.run([
            match(x.pattern().as_('num'), expr('dynamic'))
                .checkIr('match(expr(dynamic), '
                    'castPattern(varPattern(x, matchedType: num, '
                    'staticType: num), num, matchedType: dynamic))'),
          ]);
        });

        test('When matched type is not a subtype of variable type', () {
          var x = Var('x');
          h.run([
            match(x.pattern().as_('num'), expr('String'))
                .checkIr('match(expr(String), '
                    'castPattern(varPattern(x, matchedType: num, '
                    'staticType: num), num, matchedType: String))'),
          ]);
        });
      });
    });

    group('Const or literal:', () {
      test('Refutability', () {
        h.run([
          (match(intLiteral(1).pattern..errorId = 'PATTERN', intLiteral(0))
            ..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
        });
      });
    });

    group('List:', () {
      group('Type schema:', () {
        test('Explicit element type', () {
          var x = Var('x');
          h.run([
            match(listPattern([x.pattern()], elementType: 'int'),
                expr('dynamic').checkContext('List<int>')),
          ]);
        });

        group('Implicit element type:', () {
          test('Empty', () {
            h.run([
              match(listPattern([]), expr('dynamic').checkContext('Object?')),
            ]);
          });

          test('Non-empty', () {
            var x = Var('x');
            var y = Var('y');
            h.run([
              match(
                  listPattern(
                      [x.pattern(type: 'int?'), y.pattern(type: 'num')]),
                  expr('dynamic').checkContext('List<int>')),
            ]);
          });
        });
      });

      group('Static type:', () {
        test('Explicit type', () {
          var x = Var('x');
          h.run([
            match(listPattern([x.pattern(type: 'num')], elementType: 'int'),
                    expr('dynamic'))
                .checkIr('match(expr(dynamic), '
                    'listPattern(varPattern(x, matchedType: dynamic, '
                    'staticType: num), '
                    'matchedType: dynamic, requiredType: List<int>))'),
          ]);
        });

        test('Matched type is a list', () {
          var x = Var('x');
          h.run([
            match(listPattern([x.pattern(expectInferredType: 'int')]),
                    expr('List<int>'))
                .checkIr('match(expr(List<int>), '
                    'listPattern(varPattern(x, matchedType: int, '
                    'staticType: int), matchedType: List<int>, '
                    'requiredType: List<int>))'),
          ]);
        });

        test('Matched type is dynamic', () {
          var x = Var('x');
          h.run([
            match(listPattern([x.pattern(expectInferredType: 'dynamic')]),
                    expr('dynamic'))
                .checkIr('match(expr(dynamic), '
                    'listPattern(varPattern(x, matchedType: dynamic, '
                    'staticType: dynamic), matchedType: dynamic, '
                    'requiredType: List<dynamic>))'),
          ]);
        });

        test('Matched type is other', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('Object'),
                    [
                      listPattern([x.pattern(expectInferredType: 'Object?')])
                          .then([]),
                    ],
                    isExhaustive: false)
                .checkIr('switch(expr(Object), '
                    'case(heads(head(listPattern(varPattern(x, '
                    'matchedType: Object?, staticType: Object?), '
                    'matchedType: Object, requiredType: List<Object?>), '
                    'true)), block()))'),
          ]);
        });
      });

      group('Refutability:', () {
        test('When matched type is a subtype of pattern type', () {
          h.run([
            match(
              listPattern([wildcard()], elementType: 'num'),
              expr('List<int>'),
            ).checkIr('match(expr(List<int>), '
                'listPattern(varPattern(_, matchedType: int, staticType: int), '
                'matchedType: List<int>, requiredType: List<num>))'),
          ]);
        });

        test('When matched type is dynamic', () {
          h.run([
            match(listPattern([wildcard()], elementType: 'num'),
                    expr('dynamic'))
                .checkIr('match(expr(dynamic), '
                    'listPattern(varPattern(_, matchedType: dynamic, '
                    'staticType: dynamic), matchedType: dynamic, '
                    'requiredType: List<num>))'),
          ]);
        });

        test('When matched type is not a subtype of variable type', () {
          h.run([
            (match(
                listPattern([wildcard()], elementType: 'num')
                  ..errorId = 'PATTERN',
                expr('String'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT, matchedType: String, '
                'requiredType: List<num>)'
          });
        });

        test('Sub-refutability', () {
          h.run([
            (match(
                listPattern([
                  wildcard(type: 'int')..errorId = 'INT',
                  wildcard(type: 'double')..errorId = 'DOUBLE'
                ], elementType: 'num'),
                expr('List<num>'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: INT, '
                'context: CONTEXT, matchedType: num, requiredType: int)',
            'patternTypeMismatchInIrrefutableContext(pattern: DOUBLE, '
                'context: CONTEXT, matchedType: num, requiredType: double)'
          });
        });
      });

      test('Match var overlap', () {
        var x = Var('x');
        h.run([
          match(
              listPattern(
                  [x.pattern()..errorId = 'LHS', x.pattern()..errorId = 'RHS']),
              expr('List<int>')),
        ], expectedErrors: {
          'matchVarOverlap(pattern: RHS, previousPattern: LHS)'
        });
      });
    });

    group('Logical-and:', () {
      test('Type schema', () {
        h.run([
          match(wildcard(type: 'int?').and(wildcard(type: 'double?')),
                  nullLiteral.checkContext('Null'))
              .checkIr('match(null, '
                  'logicalAndPattern(varPattern(_, matchedType: Null, '
                  'staticType: int?), '
                  'varPattern(_, matchedType: Null, staticType: double?), '
                  'matchedType: Null))'),
        ]);
      });

      test('Refutability', () {
        h.run([
          (match(
              (wildcard(type: 'int')..errorId = 'LHS')
                  .and(wildcard(type: 'double')..errorId = 'RHS'),
              expr('num'))
            ..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'patternTypeMismatchInIrrefutableContext(pattern: LHS, '
              'context: CONTEXT, matchedType: num, requiredType: int)',
          'patternTypeMismatchInIrrefutableContext(pattern: RHS, '
              'context: CONTEXT, matchedType: num, requiredType: double)'
        });
      });

      test('Match var overlap', () {
        var x = Var('x');
        h.run([
          match(
              (x.pattern()..errorId = 'LHS').and(x.pattern()..errorId = 'RHS'),
              expr('int')),
        ], expectedErrors: {
          'matchVarOverlap(pattern: RHS, previousPattern: LHS)'
        });
      });
    });

    group('Logical-or:', () {
      test('Type schema', () {
        h.run([
          (match(
            wildcard(type: 'int?').or(wildcard(type: 'double?'))
              ..errorId = 'PATTERN',
            nullLiteral.checkContext('?'),
          )..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
        });
      });

      test('Refutability', () {
        // Note: even though the logical-or contains refutable sub-patterns, we
        // don't issue errors for them because they would overlap with the error
        // we're issuing for the logical-or pattern as a whole.
        h.run([
          (match(
              wildcard(type: 'int').or(wildcard(type: 'double'))
                ..errorId = 'PATTERN',
              expr('num'))
            ..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
        });
      });

      test('Missing var', () {
        var x = Var('x');
        h.run([
          ifCase(expr('int'), x.pattern().or(wildcard()..errorId = 'WILDCARD'),
              []),
        ], expectedErrors: {
          'missingMatchVar(WILDCARD, x)'
        });
      });

      group('Conflicting var:', () {
        test('explicit/explicit type', () {
          var x = Var('x');
          h.run([
            ifCase(
                expr('int'),
                (x.pattern(type: 'int')..errorId = 'PATTERN(int x)')
                    .or(x.pattern(type: 'num')..errorId = 'PATTERN(num x)'),
                []),
          ], expectedErrors: {
            'inconsistentMatchVar(pattern: PATTERN(num x), type: num, '
                'previousPattern: PATTERN(int x), previousType: int)'
          });
        });

        test('explicit/implicit type', () {
          // TODO(paulberry): not sure whether this should be treated as a
          // conflict.  See https://github.com/dart-lang/language/issues/2424.
          var x = Var('x');
          h.run([
            ifCase(
              expr('int'),
              (x.pattern()..errorId = 'PATTERN(x)')
                  .or(x.pattern(type: 'int')..errorId = 'PATTERN(int x)'),
              [],
            ),
          ], expectedErrors: {
            'inconsistentMatchVarExplicitness(pattern: PATTERN(int x), '
                'previousPattern: PATTERN(x))'
          });
        });

        test('implicit/implicit type', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('List<int>'),
              (x.pattern()..errorId = 'PATTERN(List<int> x)')
                  .or(listPattern([x.pattern()..errorId = 'PATTERN(int x)'])),
              [],
            ),
          ], expectedErrors: {
            'inconsistentMatchVar(pattern: PATTERN(int x), type: int, '
                'previousPattern: PATTERN(List<int> x), '
                'previousType: List<int>)'
          });
        });

        group('Error recovery:', () {
          test('Each type compared to previous', () {
            var x = Var('x');
            h.run([
              ifCase(
                  expr('int'),
                  (x.pattern(type: 'int')..errorId = 'PATTERN1')
                      .or(x.pattern(type: 'num')..errorId = 'PATTERN2')
                      .or(x.pattern(type: 'num')..errorId = 'PATTERN3')
                      .or(x.pattern(type: 'int')..errorId = 'PATTERN4'),
                  []),
            ], expectedErrors: {
              'inconsistentMatchVar(pattern: PATTERN2, type: num, '
                  'previousPattern: PATTERN1, previousType: int)',
              'inconsistentMatchVar(pattern: PATTERN4, type: int, '
                  'previousPattern: PATTERN3, previousType: num)'
            });
          });

          test('Each type explicitness compared to previous', () {
            var x = Var('x');
            h.run([
              ifCase(
                  expr('int'),
                  (x.pattern(type: 'int')..errorId = 'PATTERN1')
                      .or(x.pattern()..errorId = 'PATTERN2')
                      .or(x.pattern()..errorId = 'PATTERN3')
                      .or(x.pattern(type: 'int')..errorId = 'PATTERN4'),
                  []),
            ], expectedErrors: {
              'inconsistentMatchVarExplicitness(pattern: PATTERN2, '
                  'previousPattern: PATTERN1)',
              'inconsistentMatchVarExplicitness(pattern: PATTERN4, '
                  'previousPattern: PATTERN3)'
            });
          });
        });
      });
    });

    group('Null-assert:', () {
      test('Type schema', () {
        var x = Var('x');
        h.run([
          match(x.pattern(type: 'int').nullAssert,
                  expr('int').checkContext('int?'))
              .checkIr('match(expr(int), '
                  'nullAssertPattern(varPattern(x, matchedType: int, '
                  'staticType: int), matchedType: int))'),
        ]);
      });

      group('Refutability:', () {
        test('When matched type is nullable', () {
          h.run([
            match(wildcard().nullAssert, expr('int?'))
                .checkIr('match(expr(int?), '
                    'nullAssertPattern(varPattern(_, matchedType: int, '
                    'staticType: int), matchedType: int?))'),
          ]);
        });

        test('When matched type is non-nullable', () {
          h.run([
            match(wildcard().nullAssert, expr('int'))
                .checkIr('match(expr(int), '
                    'nullAssertPattern(varPattern(_, matchedType: int, '
                    'staticType: int), matchedType: int))'),
          ]);
        });

        test('When matched type is dynamic', () {
          h.run([
            match(wildcard().nullAssert, expr('dynamic'))
                .checkIr('match(expr(dynamic), '
                    'nullAssertPattern(varPattern(_, matchedType: dynamic, '
                    'staticType: dynamic), matchedType: dynamic))'),
          ]);
        });

        test('Sub-refutability', () {
          h.run([
            (match((wildcard(type: 'int')..errorId = 'INT').nullAssert,
                expr('num'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: INT, '
                'context: CONTEXT, matchedType: num, requiredType: int)'
          });
        });
      });
    });

    group('Null-check:', () {
      test('Type schema', () {
        var x = Var('x');
        h.run([
          (match(x.pattern(type: 'int').nullCheck..errorId = 'PATTERN',
              expr('int').checkContext('?'))
            ..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
        });
      });

      group('Refutability:', () {
        test('When matched type is nullable', () {
          h.run([
            (match(wildcard().nullCheck..errorId = 'PATTERN', expr('int?'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
          });
        });

        test('When matched type is non-nullable', () {
          h.run([
            (match(wildcard().nullCheck..errorId = 'PATTERN', expr('int'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
          });
        });

        test('When matched type is dynamic', () {
          h.run([
            (match(wildcard().nullCheck..errorId = 'PATTERN', expr('dynamic'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
          });
        });

        test('Sub-refutability', () {
          h.run([
            (match(wildcard(type: 'int').nullCheck..errorId = 'PATTERN',
                expr('num'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
          });
        });
      });
    });

    group('Variable:', () {
      group('Refutability:', () {
        test('When matched type is a subtype of variable type', () {
          var x = Var('x');
          h.run([
            match(x.pattern(type: 'num'), expr('int'))
                .checkIr('match(expr(int), '
                    'varPattern(x, matchedType: int, staticType: num))'),
          ]);
        });

        test('When matched type is dynamic', () {
          var x = Var('x');
          h.run([
            match(x.pattern(type: 'num'), expr('dynamic'))
                .checkIr('match(expr(dynamic), '
                    'varPattern(x, matchedType: dynamic, staticType: num))'),
          ]);
        });

        test('When matched type is not a subtype of variable type', () {
          var x = Var('x');
          h.run([
            (match(x.pattern(type: 'num')..errorId = 'PATTERN', expr('String'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT, matchedType: String, requiredType: num)'
          });
        });
      });
    });

    group('Wildcard:', () {
      test('Untyped', () {
        h.run([
          switch_(
                  expr('int'),
                  [
                    wildcard().then([]),
                  ],
                  isExhaustive: true)
              .checkIr('switch(expr(int), '
                  'case(heads(head(varPattern(_, matchedType: int, '
                  'staticType: int), true)), block()))'),
        ]);
      });

      test('Typed', () {
        h.run([
          switch_(
                  expr('num'),
                  [
                    wildcard(type: 'int').then([]),
                  ],
                  isExhaustive: true)
              .checkIr('switch(expr(num), '
                  'case(heads(head(varPattern(_, matchedType: num, '
                  'staticType: int), true)), block()))'),
        ]);
      });

      group('Exempt from errors:', () {
        group('Missing var:', () {
          test('default', () {
            h.run([
              switch_(
                      expr('int'),
                      [
                        wildcard().then([]),
                        default_.then([]),
                      ],
                      isExhaustive: true)
                  .checkIr('switch(expr(int), '
                      'case(heads(head(varPattern(_, matchedType: int, '
                      'staticType: int), true), default), '
                      'block()))'),
            ]);
          });

          test('case', () {
            h.run([
              switch_(
                      expr('int'),
                      [
                        intLiteral(0).pattern.then([]),
                        wildcard().then([]),
                      ],
                      isExhaustive: true)
                  .checkIr('switch(expr(int), '
                      'case(heads(head(const(0, matchedType: int), true), '
                      'head(varPattern(_, matchedType: int, '
                      'staticType: int), true)), block()))'),
            ]);
          });

          test('label', () {
            var l = Label('l');
            h.run([
              switch_(
                      expr('int'),
                      [
                        l.then(wildcard()).then([]),
                      ],
                      isExhaustive: true)
                  .checkIr('switch(expr(int), '
                      'case(heads(head(varPattern(_, matchedType: int, '
                      'staticType: int), true), l), '
                      'block()))'),
            ]);
          });
        });

        group('conflicting var:', () {
          test('explicit/explicit type', () {
            h.run([
              switch_(
                      expr('num'),
                      [
                        wildcard(type: 'int').then([]),
                        wildcard(type: 'num').then([]),
                      ],
                      isExhaustive: true)
                  .checkIr('switch(expr(num), '
                      'case(heads(head(varPattern(_, matchedType: num, '
                      'staticType: int), true), '
                      'head(varPattern(_, matchedType: num, '
                      'staticType: num), true)), block()))'),
            ]);
          });

          test('explicit/implicit type', () {
            h.run([
              switch_(
                      expr('int'),
                      [
                        wildcard().then([]),
                        wildcard(type: 'int').then([]),
                      ],
                      isExhaustive: true)
                  .checkIr('switch(expr(int), '
                      'case(heads(head(varPattern(_, matchedType: int, '
                      'staticType: int), true), '
                      'head(varPattern(_, matchedType: int, '
                      'staticType: int), true)), block()))'),
            ]);
          });

          test('implicit/implicit type', () {
            h.run([
              switch_(
                      expr('List<int>'),
                      [
                        wildcard().then([]),
                        listPattern([wildcard()]).then([]),
                      ],
                      isExhaustive: true)
                  .checkIr('switch(expr(List<int>), '
                      'case(heads(head(varPattern(_, matchedType: List<int>, '
                      'staticType: List<int>), true), '
                      'head(listPattern(varPattern(_, matchedType: int, '
                      'staticType: int), matchedType: List<int>, '
                      'requiredType: List<int>), true)), block()))'),
            ]);
          });
        });
      });

      group('Refutability:', () {
        test('When matched type is a subtype of variable type', () {
          h.run([
            match(wildcard(type: 'num'), expr('int'))
                .checkIr('match(expr(int), '
                    'varPattern(_, matchedType: int, staticType: num))'),
          ]);
        });

        test('When matched type is dynamic', () {
          h.run([
            match(wildcard(type: 'num'), expr('dynamic'))
                .checkIr('match(expr(dynamic), '
                    'varPattern(_, matchedType: dynamic, staticType: num))'),
          ]);
        });

        test('When matched type is not a subtype of variable type', () {
          h.run([
            (match(wildcard(type: 'num')..errorId = 'PATTERN', expr('String'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT, matchedType: String, requiredType: num)'
          });
        });
      });
    });
  });
}
