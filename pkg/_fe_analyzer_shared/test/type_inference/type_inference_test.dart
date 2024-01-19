// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../mini_ast.dart';
import '../mini_types.dart';

main() {
  late Harness h;

  setUp(() {
    h = Harness();
  });

  group('Collection elements:', () {
    group('If:', () {
      test('Condition schema', () {
        h.run([
          listLiteral(elementType: 'int', [
            ifElement(
              expr('dynamic').checkSchema('bool'),
              expr('Object'),
            ).checkIR('if(expr(dynamic), celt(expr(Object)), noop)'),
          ]),
        ]);
      });

      test('With else', () {
        h.run([
          listLiteral(elementType: 'int', [
            ifElement(
              expr('bool'),
              expr('Object'),
              expr('Object'),
            ).checkIR('if(expr(bool), celt(expr(Object)), celt(expr(Object)))'),
          ]),
        ]);
      });

      group('Schema:', () {
        test('Element type', () {
          h.run([
            listLiteral(elementType: 'int', [
              ifElement(
                expr('bool'),
                expr('Object').checkSchema('int'),
                expr('Object').checkSchema('int'),
              ).checkIR(
                  'if(expr(bool), celt(expr(Object)), celt(expr(Object)))'),
            ]),
          ]);
        });
      });
    });

    group('If-case:', () {
      test('Expression schema', () {
        h.run([
          listLiteral(elementType: 'int', [
            ifCaseElement(
              expr('Object').checkSchema('?'),
              intLiteral(0).pattern,
              intLiteral(1).checkSchema('int'),
            ).checkIR('if(expression: expr(Object), pattern: '
                'const(0, matchedType: Object), guard: true, '
                'ifTrue: celt(1), ifFalse: noop)'),
          ]),
        ]);
      });

      test('With else', () {
        h.run([
          listLiteral(elementType: 'int', [
            ifCaseElement(
              expr('Object'),
              intLiteral(0).pattern,
              intLiteral(1).checkSchema('int'),
              intLiteral(2).checkSchema('int'),
            ).checkIR('if(expression: expr(Object), pattern: '
                'const(0, matchedType: Object), guard: true, '
                'ifTrue: celt(1), ifFalse: celt(2))'),
          ]),
        ]);
      });

      test('With guard', () {
        var x = Var('x');
        h.run([
          listLiteral(elementType: 'int', [
            ifCaseElement(
              expr('Object'),
              x.pattern().when(x.eq(intLiteral(0))),
              intLiteral(1).checkSchema('int'),
            ).checkIR('if(expression: expr(Object), pattern: '
                'varPattern(x, matchedType: Object, staticType: Object), '
                'guard: ==(x, 0), ifTrue: celt(1), ifFalse: noop)'),
          ]),
        ]);
      });

      test('Allows refutable patterns', () {
        var x = Var('x');
        h.run([
          listLiteral(elementType: 'int', [
            ifCaseElement(
              expr('Object'),
              x.pattern(type: 'int'), // has type, refutable
              intLiteral(1).checkSchema('int'),
            ).checkIR('if(expression: expr(Object), pattern: varPattern(x, '
                'matchedType: Object, staticType: int), guard: true, '
                'ifTrue: celt(1), ifFalse: noop)'),
          ]),
        ]);
      });

      group('Guard not assignable to bool', () {
        test('int', () {
          var x = Var('x');
          h.run([
            listLiteral(elementType: 'int', [
              ifCaseElement(
                expr('Object'),
                x.pattern().when(expr('int')..errorId = 'GUARD'),
                intLiteral(0).checkSchema('int'),
              ),
            ]),
          ], expectedErrors: {
            'nonBooleanCondition(node: GUARD)'
          });
        });

        test('bool', () {
          var x = Var('x');
          h.run([
            listLiteral(elementType: 'int', [
              ifCaseElement(
                expr('Object'),
                x.pattern().when(expr('bool')),
                intLiteral(0).checkSchema('int'),
              ),
            ]),
          ], expectedErrors: {});
        });

        test('dynamic', () {
          var x = Var('x');
          h.run([
            listLiteral(elementType: 'int', [
              ifCaseElement(
                expr('Object'),
                x.pattern().when(expr('dynamic')),
                intLiteral(0).checkSchema('int'),
              ),
            ]),
          ], expectedErrors: {});
        });
      });
    });

    group('Pattern-for-in:', () {
      group('Expression type:', () {
        test('Iterable', () {
          var x = Var('x');
          h.run([
            listLiteral(elementType: 'Object', [
              patternForInElement(
                x.pattern(),
                expr('Iterable<int>'),
                expr('Object'),
              ).checkIR('forEach(expr(Iterable<int>), varPattern(x, '
                  'matchedType: int, staticType: int), celt(expr(Object)))'),
            ]),
          ]);
        });
        test('dynamic', () {
          var x = Var('x');
          h.run([
            listLiteral(elementType: 'Object', [
              patternForInElement(
                x.pattern(),
                expr('dynamic'),
                expr('Object'),
              ).checkIR('forEach(expr(dynamic), varPattern(x, '
                  'matchedType: dynamic, staticType: dynamic), '
                  'celt(expr(Object)))'),
            ]),
          ]);
        });
        test('Object', () {
          var x = Var('x');
          h.run([
            listLiteral(elementType: 'Object', [
              (patternForInElement(
                x.pattern(),
                expr('Object')..errorId = 'EXPRESSION',
                expr('Object'),
              )..errorId = 'FOR')
                  .checkIR('forEach(expr(Object), varPattern(x, '
                      'matchedType: error, staticType: error), '
                      'celt(expr(Object)))'),
            ]),
          ], expectedErrors: {
            'patternForInExpressionIsNotIterable(node: FOR, '
                'expression: EXPRESSION, expressionType: Object)'
          });
        });
      });

      group('Refutability:', () {
        test('When a refutable pattern', () {
          var x = Var('x');
          h.run([
            listLiteral(elementType: 'Object', [
              (patternForInElement(
                x.pattern().nullCheck..errorId = 'PATTERN',
                expr('Iterable<int?>'),
                expr('Object'),
              )..errorId = 'FOR')
                  .checkIR('forEach(expr(Iterable<int?>), nullCheckPattern('
                      'varPattern(x, matchedType: int, staticType: int), '
                      'matchedType: int?), celt(expr(Object)))'),
            ]),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(pattern: PATTERN, '
                'context: FOR)',
          });
        });
        test('When the variable type is not a subtype of the matched type', () {
          var x = Var('x');
          h.run([
            listLiteral(elementType: 'Object', [
              (patternForInElement(
                x.pattern(type: 'String')..errorId = 'PATTERN',
                expr('Iterable<int>'),
                expr('Object'),
              )..errorId = 'FOR')
                  .checkIR('forEach(expr(Iterable<int>), varPattern(x, '
                      'matchedType: int, staticType: String), '
                      'celt(expr(Object)))'),
            ]),
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                'context: FOR, matchedType: int, requiredType: String)',
          });
        });
      });
    });
  });

  group('Expressions:', () {
    group('cascade:', () {
      group('IR:', () {
        test('not null-aware', () {
          h.run([
            expr('dynamic').cascade([
              (t) => t.invokeMethod('f', []),
              (t) => t.invokeMethod('g', [])
            ]).checkIR('let(t0, expr(dynamic), '
                'let(t1, f(t0), let(t2, g(t0), t0)))'),
          ]);
        });

        test('null-aware', () {
          h.run([
            expr('dynamic').cascade(isNullAware: true, [
              (t) => t.invokeMethod('f', []),
              (t) => t.invokeMethod('g', [])
            ]).checkIR('let(t0, expr(dynamic), '
                'if(==(t0, null), t0, let(t1, f(t0), let(t2, g(t0), t0))))'),
          ]);
        });
      });
    });

    group('integer literal', () {
      test('double type schema', () {
        h.run([
          intLiteral(1, expectConversionToDouble: true)
              .checkType('double')
              .checkIR('1.0f')
              .inTypeSchema('double'),
        ]);
      });

      test('int type schema', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIR('1')
              .inTypeSchema('int'),
        ]);
      });

      test('num type schema', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIR('1')
              .inTypeSchema('num'),
        ]);
      });

      test('double? type schema', () {
        h.run([
          intLiteral(1, expectConversionToDouble: true)
              .checkType('double')
              .checkIR('1.0f')
              .inTypeSchema('double?'),
        ]);
      });

      test('int? type schema', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIR('1')
              .inTypeSchema('int?'),
        ]);
      });

      test('unknown type schema', () {
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIR('1')
              .inTypeSchema('?'),
        ]);
      });

      test('unrelated type schema', () {
        // Note: an unrelated type schema can arise in the case of assigning to
        // a promoted variable, e.g.:
        //
        //   Object x;
        //   if (x is String) {
        //     x = 1;
        //   }
        h.run([
          intLiteral(1, expectConversionToDouble: false)
              .checkType('int')
              .checkIR('1')
              .inTypeSchema('String'),
        ]);
      });
    });

    group('Switch:', () {
      test('IR', () {
        h.run([
          switchExpr(expr('int'), [
            default_.thenExpr(intLiteral(0)),
          ]).checkIR('switchExpr(expr(int), case(default, 0))'),
        ]);
      });

      test('scrutinee expression schema', () {
        h.run([
          switchExpr(expr('int').checkSchema('?'), [
            default_.thenExpr(intLiteral(0)),
          ]).inTypeSchema('num'),
        ]);
      });

      test('body expression schema', () {
        h.run([
          switchExpr(expr('int'), [
            default_.thenExpr(nullLiteral.checkSchema('C?')),
          ]).inTypeSchema('C?'),
        ]);
      });

      test('least upper bound behavior', () {
        h.run([
          switchExpr(expr('int'), [
            intLiteral(0).pattern.thenExpr(expr('int')),
            default_.thenExpr(expr('double')),
          ]).checkType('num')
        ]);
      });

      test('no cases', () {
        h.run([switchExpr(expr('A'), []).checkType('Never')]);
      });

      test('guard', () {
        var i = Var('i');
        h.run([
          switchExpr(expr('int'), [
            i
                .pattern()
                .when(i.checkType('int').eq(expr('num')).checkSchema('bool'))
                .thenExpr(expr('String')),
          ]).checkIR('switchExpr(expr(int), case(head(varPattern(i, '
              'matchedType: int, staticType: int), ==(i, expr(num)), '
              'variables(i)), expr(String)))'),
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
            ]),
          ], expectedErrors: {
            'nonBooleanCondition(node: GUARD)'
          });
        });

        test('bool', () {
          var x = Var('x');
          h.run([
            switchExpr(expr('int'), [
              x.pattern().when(expr('bool')).thenExpr(expr('int')),
            ]),
          ], expectedErrors: {});
        });

        test('dynamic', () {
          var x = Var('x');
          h.run([
            switchExpr(expr('int'), [
              x.pattern().when(expr('dynamic')).thenExpr(expr('int')),
            ]),
          ], expectedErrors: {});
        });
      });

      group('Variables:', () {
        group('logical-or:', () {
          test('consistent', () {
            var x1 = Var('x', identity: 'x1');
            var x2 = Var('x', identity: 'x2');
            PatternVariableJoin('x', expectedComponents: [x1, x2]);
            h.run([
              switchExpr(expr('double'), [
                x1.pattern().or(x2.pattern()).thenExpr(expr('int')),
                default_.thenExpr(expr('int')),
              ]).checkType('int').checkIR(
                    'switchExpr(expr(double), case(head(logicalOrPattern('
                    'varPattern(x, matchedType: double, staticType: double), '
                    'varPattern(x, matchedType: double, staticType: double), '
                    'matchedType: double), true, '
                    'variables(double x = [x1, x2])), expr(int)), '
                    'case(default, expr(int)))',
                  ),
            ]);
          });
          group('not consistent:', () {
            test('different finality', () {
              var x1 = Var('x', identity: 'x1', isFinal: true);
              var x2 = Var('x', identity: 'x2')..errorId = 'x2';
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                switchExpr(expr('double'), [
                  x1.pattern().or(x2.pattern()).thenExpr(expr('int')),
                  default_.thenExpr(expr('int')),
                ]).checkType('int').checkIR(
                      'switchExpr(expr(double), case(head(logicalOrPattern('
                      'varPattern(x, matchedType: double, staticType: double), '
                      'varPattern(x, matchedType: double, staticType: '
                      'double), matchedType: double), true, variables('
                      'notConsistent:differentFinalityOrType double x = '
                      '[x1, x2])), expr(int)), case(default, expr(int)))',
                    ),
              ], expectedErrors: {
                'inconsistentJoinedPatternVariable(variable: x = [x1, x2], '
                    'component: x2)'
              });
            });
            test('different types', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2')..errorId = 'x2';
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                switchExpr(expr('double'), [
                  x1
                      .pattern(type: 'double')
                      .or(x2.pattern(type: 'num'))
                      .thenExpr(expr('int')),
                  default_.thenExpr(expr('int')),
                ]).checkType('int').checkIR(
                      'switchExpr(expr(double), case(head(logicalOrPattern('
                      'varPattern(x, matchedType: double, staticType: double), '
                      'varPattern(x, matchedType: double, staticType: '
                      'num), matchedType: double), true, variables('
                      'notConsistent:differentFinalityOrType error x = '
                      '[x1, x2])), expr(int)), case(default, expr(int)))',
                    ),
              ], expectedErrors: {
                'inconsistentJoinedPatternVariable(variable: x = [x1, x2], '
                    'component: x2)'
              });
            });
          });
        });
      });
    });

    group('Map:', () {
      test('downward inference', () {
        h.run([
          mapLiteral(keyType: 'num', valueType: 'Object', [
            mapEntry(expr('int').checkSchema('num'),
                expr('int').checkSchema('Object'))
          ]),
        ]);
      });

      test('upward inference', () {
        h.run([
          mapLiteral(keyType: 'int', valueType: 'String', [])
              .checkType('Map<int, String>'),
        ]);
      });

      test('IR', () {
        h.run([
          mapLiteral(keyType: 'int', valueType: 'String?', [
            mapEntry(intLiteral(0), nullLiteral)
          ]).checkIR('map(mapEntry(0, null))'),
        ]);
      });
    });
  });

  group('Statements:', () {
    group('If:', () {
      test('Condition schema', () {
        h.run([
          if_(expr('dynamic').checkSchema('bool'), [
            expr('Object'),
          ]).checkIR('if(expr(dynamic), block(stmt(expr(Object))), noop)'),
        ]);
      });

      test('With else', () {
        h.run([
          if_(expr('bool'), [
            expr('Object'),
          ], [
            expr('String'),
          ]).checkIR('if(expr(bool), block(stmt(expr(Object))), '
              'block(stmt(expr(String))))'),
        ]);
      });
    });

    group('If-case:', () {
      test('Type schema', () {
        var x = Var('x');
        h.run([
          ifCase(
            expr('int').checkSchema('?'),
            x.pattern(type: 'num'),
            [],
          ).checkIR('ifCase(expr(int), '
              'varPattern(x, matchedType: int, staticType: num), variables(x), '
              'true, block(), noop)'),
        ]);
      });

      test('With else', () {
        var x = Var('x');
        h.run([
          ifCase(
            expr('num'),
            x.pattern(type: 'int'),
            [
              expr('Object'),
            ],
            [
              expr('String'),
            ],
          ).checkIR('ifCase(expr(num), '
              'varPattern(x, matchedType: num, staticType: int), variables(x), '
              'true, block(stmt(expr(Object))), block(stmt(expr(String))))'),
        ]);
      });

      test('With guard', () {
        var x = Var('x');
        h.run([
          ifCase(
            expr('num'),
            x.pattern(type: 'int').when(x.eq(intLiteral(0))),
            [],
          ).checkIR('ifCase(expr(num), '
              'varPattern(x, matchedType: num, staticType: int), variables(x), '
              '==(x, 0), block(), noop)'),
        ]);
      });

      test('Allows refutable patterns', () {
        var x = Var('x');
        h.run([
          ifCase(
            expr('num').checkSchema('?'),
            x.pattern(type: 'int'),
            [],
          ).checkIR('ifCase(expr(num), '
              'varPattern(x, matchedType: num, staticType: int), variables(x), '
              'true, block(), noop)'),
        ]);
      });

      group('Guard not assignable to bool', () {
        test('int', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('int'),
              x.pattern().when(expr('int')..errorId = 'GUARD'),
              [],
            ),
          ], expectedErrors: {
            'nonBooleanCondition(node: GUARD)'
          });
        });

        test('bool', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('int'),
              x.pattern().when(expr('bool')),
              [],
            ),
          ], expectedErrors: {});
        });

        test('dynamic', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('int'),
              x.pattern().when(expr('dynamic')),
              [],
            ),
          ], expectedErrors: {});
        });
      });
    });

    group('Switch:', () {
      test('Empty', () {
        h.run([
          switch_(
            expr('int'),
            [],
            expectLastCaseTerminates: true,
          ),
        ]);
      });

      test('Exhaustive', () {
        h.addExhaustiveness('E', true);
        h.run([
          switch_(
            expr('E'),
            [
              expr('E').pattern.then([
                break_(),
              ]),
            ],
            expectIsExhaustive: true,
          ),
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
            expectHasDefault: false,
            expectIsExhaustive: false,
          ),
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
            expectHasDefault: true,
            expectIsExhaustive: true,
          ),
        ]);
      });

      test('Last case terminates', () {
        h.run([
          switch_(
            expr('int'),
            [
              intLiteral(0).pattern.then([
                expr('int'),
              ]),
              intLiteral(1).pattern.then([
                break_(),
              ]),
            ],
            expectLastCaseTerminates: true,
          ),
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
                expr('int'),
              ]),
            ],
            expectLastCaseTerminates: false,
          ),
        ]);
      });

      test('Scrutinee type', () {
        h.run([
          switch_(expr('int'), [], expectScrutineeType: 'int'),
        ]);
      });

      test('const pattern', () {
        h.run([
          switch_(
            expr('int').checkSchema('?'),
            [
              intLiteral(0).pattern.then([
                break_(),
              ]),
            ],
          ).checkIR('switch(expr(int), case(heads(head(const(0, '
              'matchedType: int), true, variables()), variables()), '
              'block(break())))'),
        ]);
      });

      group('var pattern:', () {
        test('untyped', () {
          var x = Var('x');
          h.run([
            switch_(
              expr('int').checkSchema('?'),
              [
                x.pattern().then([
                  break_(),
                ]),
              ],
            ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                'matchedType: int, staticType: int), true, variables(x)), '
                'variables(x)), block(break())))'),
          ]);
        });

        test('typed', () {
          var x = Var('x');
          h.run([
            switch_(
              expr('int').checkSchema('?'),
              [
                x.pattern(type: 'num').then([
                  break_(),
                ]),
              ],
            ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                'matchedType: int, staticType: num), true, variables(x)), '
                'variables(x)), block(break())))'),
          ]);
        });
      });

      test('scrutinee expression schema', () {
        h.run([
          switch_(
            expr('int').checkSchema('?'),
            [
              intLiteral(0).pattern.then([
                break_(),
              ]),
            ],
          ),
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
          ).checkIR('switch(expr(int), case(heads(head(const(0, '
              'matchedType: int), true, variables()), variables()), '
              'block(break())), case(heads(head(const(1, matchedType: int), '
              'true, variables()), variables()), block(synthetic-break())))'),
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
                  .when(i.checkType('int').eq(expr('num')).checkSchema('bool'))
                  .then([
                break_(),
              ]),
            ],
          ).checkIR('switch(expr(int), case(heads(head(varPattern(i, '
              'matchedType: int, staticType: int), ==(i, expr(num)), '
              'variables(i)), variables(i)), block(break())))'),
        ]);
      });

      group('Variables:', () {
        test('Independent cases', () {
          var x = Var('x');
          var y = Var('y');
          h.run([
            switch_(
              expr('int'),
              [
                x.pattern().then([
                  break_(),
                ]),
                y.pattern().then([
                  break_(),
                ]),
              ],
            ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                'matchedType: int, staticType: int), true, variables(x)), '
                'variables(x)), block(break())), case(heads(head(varPattern(y, '
                'matchedType: int, staticType: int), true, variables(y)), '
                'variables(y)), block(break())))'),
          ]);
        });
        group('Shared case scope:', () {
          group('Present in both cases:', () {
            test('With the same type and finality', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2');
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                switch_(
                  expr('int'),
                  [
                    switchStatementMember([
                      x1.pattern(),
                      x2.pattern(),
                    ], [
                      break_(),
                    ]),
                  ],
                ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                    'matchedType: int, staticType: int), true, variables(x1)), '
                    'head(varPattern(x, matchedType: int, staticType: int), '
                    'true, variables(x2)), variables(int x = [x1, x2])), '
                    'block(break())))'),
              ]);
            });
            test('With the same type and finality, with logical-or', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2');
              var x3 = Var('x', identity: 'x3');
              var x4 = PatternVariableJoin('x',
                  expectedComponents: [x1, x2], identity: 'x4');
              PatternVariableJoin('x', expectedComponents: [x4, x3]);
              h.run([
                switch_(
                  expr('int'),
                  [
                    switchStatementMember([
                      x1.pattern().or(x2.pattern()),
                      x3.pattern(),
                    ], [
                      break_(),
                    ]),
                  ],
                ).checkIR('switch(expr(int), case(heads(head(logicalOrPattern('
                    'varPattern(x, matchedType: int, staticType: int), '
                    'varPattern(x, matchedType: int, staticType: int), '
                    'matchedType: int), true, variables(int x = [x1, x2])), '
                    'head(varPattern(x, matchedType: int, staticType: int), '
                    'true, variables(x3)), variables(int x = '
                    '[int x = [x1, x2], x3])), block(break())))'),
              ]);
            });
            group('With different type:', () {
              test('explicit / explicit', () {
                var x1 = Var('x', identity: 'x1');
                var x2 = Var('x', identity: 'x2');
                PatternVariableJoin('x', expectedComponents: [x1, x2]);
                h.run([
                  switch_(
                    expr('int'),
                    [
                      switchStatementMember([
                        x1.pattern(type: 'num'),
                        x2.pattern(type: 'int'),
                      ], [
                        break_(),
                      ]),
                    ],
                  ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                      'matchedType: int, staticType: num), true, '
                      'variables(x1)), head(varPattern(x, matchedType: int, '
                      'staticType: int), true, variables(x2)), '
                      'variables(notConsistent:differentFinalityOrType error '
                      'x = [x1, x2])), block(break())))'),
                ]);
              });
              test('explicit / implicit', () {
                var x1 = Var('x', identity: 'x1');
                var x2 = Var('x', identity: 'x2');
                PatternVariableJoin('x', expectedComponents: [x1, x2]);
                h.run([
                  switch_(
                    expr('int'),
                    [
                      switchStatementMember([
                        x1.pattern(type: 'num'),
                        x2.pattern(),
                      ], [
                        break_(),
                      ]),
                    ],
                  ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                      'matchedType: int, staticType: num), true, variables('
                      'x1)), head(varPattern(x, matchedType: int, '
                      'staticType: int), true, variables(x2)), '
                      'variables(notConsistent:differentFinalityOrType error '
                      'x = [x1, x2])), block(break())))'),
                ]);
              });
              test('implicit / implicit', () {
                var x1 = Var('x', identity: 'x1');
                var x2 = Var('x', identity: 'x2');
                PatternVariableJoin('x', expectedComponents: [x1, x2]);
                h.run([
                  switch_(
                    expr('List<int>'),
                    [
                      switchStatementMember([
                        x1.pattern(),
                        listPattern([x2.pattern()]),
                      ], [
                        break_(),
                      ]),
                    ],
                  ).checkIR(
                      'switch(expr(List<int>), case(heads(head(varPattern(x, '
                      'matchedType: List<int>, staticType: List<int>), true, '
                      'variables(x1)), head(listPattern(varPattern(x, '
                      'matchedType: int, staticType: int), matchedType: '
                      'List<int>, requiredType: List<int>), true, '
                      'variables(x2)), variables('
                      'notConsistent:differentFinalityOrType error '
                      'x = [x1, x2])), block(break())))'),
                ]);
              });
            });
            test('With different finality', () {
              var x1 = Var('x', isFinal: true, identity: 'x1');
              var x2 = Var('x', identity: 'x2');
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                switch_(
                  expr('int'),
                  [
                    switchStatementMember([
                      x1.pattern(),
                      x2.pattern(),
                    ], [
                      break_(),
                    ]),
                  ],
                ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                    'matchedType: int, staticType: int), true, variables(x1)), '
                    'head(varPattern(x, matchedType: int, staticType: int), '
                    'true, variables(x2)), variables('
                    'notConsistent:differentFinalityOrType int x = [x1, x2])), '
                    'block(break())))'),
              ]);
            });
          });
          test('case has, case not', () {
            var x1 = Var('x', identity: 'x1');
            PatternVariableJoin('x', expectedComponents: [x1]);
            h.run([
              switch_(
                expr('int'),
                [
                  switchStatementMember([
                    x1.pattern(),
                    intLiteral(0).pattern,
                  ], [
                    break_(),
                  ]),
                ],
              ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                  'matchedType: int, staticType: int), true, variables(x1)), '
                  'head(const(0, matchedType: int), true, variables()), '
                  'variables(notConsistent:sharedCaseAbsent int x = [x1])), '
                  'block(break())))'),
            ]);
          });
          test('case not, case has', () {
            var x1 = Var('x', identity: 'x1');
            PatternVariableJoin('x', expectedComponents: [x1]);
            h.run([
              switch_(
                expr('int'),
                [
                  switchStatementMember([
                    intLiteral(0).pattern,
                    x1.pattern(),
                  ], [
                    break_(),
                  ]),
                ],
              ).checkIR('switch(expr(int), case(heads(head(const(0, '
                  'matchedType: int), true, variables()), head(varPattern(x, '
                  'matchedType: int, staticType: int), true, variables(x1)), '
                  'variables(notConsistent:sharedCaseAbsent int x = [x1])), '
                  'block(break())))'),
            ]);
          });
          test('case has, default', () {
            var x1 = Var('x', identity: 'x1');
            PatternVariableJoin('x', expectedComponents: [x1]);
            h.run([
              switch_(
                expr('int'),
                [
                  switchStatementMember([
                    x1.pattern(),
                    default_,
                  ], [
                    break_(),
                  ]),
                ],
              ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                  'matchedType: int, staticType: int), true, variables(x1)), '
                  'default, variables(notConsistent:sharedCaseHasLabel int x '
                  '= [x1])), block(break())))'),
            ]);
          });
          test('case has, with label', () {
            var x1 = Var('x', identity: 'x1');
            PatternVariableJoin('x', expectedComponents: [x1]);
            h.run([
              switch_(
                expr('int'),
                [
                  switchStatementMember([
                    x1.pattern(),
                  ], [
                    break_(),
                  ], hasLabels: true),
                ],
              ).checkIR('switch(expr(int), case(heads(head(varPattern(x, '
                  'matchedType: int, staticType: int), true, variables(x1)), '
                  'variables(notConsistent:sharedCaseHasLabel int x = '
                  '[x1])), block(break())))'),
            ]);
          });
        });
      });

      group('Case completes normally:', () {
        test('Reported when patterns disabled', () {
          h.disablePatterns();
          h.run([
            (switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int'),
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isLegacyExhaustive: true,
            )..errorId = 'SWITCH'),
          ], expectedErrors: {
            'switchCaseCompletesNormally(node: SWITCH, caseIndex: 0)'
          });
        });

        test('Handles cases that share a body', () {
          h.disablePatterns();
          h.run([
            (switch_(
              expr('int'),
              [
                switchStatementMember([
                  intLiteral(0).pattern,
                  intLiteral(1).pattern,
                  intLiteral(2).pattern,
                ], [
                  expr('int'),
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isLegacyExhaustive: true,
            )..errorId = 'SWITCH'),
          ], expectedErrors: {
            'switchCaseCompletesNormally(node: SWITCH, caseIndex: 0)'
          });
        });

        test('Not reported when unreachable', () {
          h.disablePatterns();
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
              isLegacyExhaustive: true,
            ),
          ], expectedErrors: {});
        });

        test('Not reported for final case', () {
          h.disablePatterns();
          h.run([
            switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int'),
                ]),
              ],
              isLegacyExhaustive: false,
            ),
          ], expectedErrors: {});
        });

        test('Not reported in legacy mode', () {
          // In legacy mode, the criteria for reporting a switch case that
          // "falls through" are less accurate (since flow analysis isn't
          // available in legacy mode).  This logic is not currently implemented
          // in the shared analyzer.
          h.enableLegacy();
          h.run([
            switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int'),
                ]),
                default_.then([
                  break_(),
                ]),
              ],
              isLegacyExhaustive: false,
            ),
          ], expectedErrors: {});
        });

        test('Not reported when patterns enabled', () {
          // When patterns are enabled, there is an implicit `break` at the end
          // of every switch body.
          h.run([
            switch_(
              expr('int'),
              [
                intLiteral(0).pattern.then([
                  expr('int'),
                ]),
                default_.then([
                  break_(),
                ]),
              ],
            ),
          ], expectedErrors: {});
        });
      });

      group('Case expression type mismatch:', () {
        group('Pre-null safety:', () {
          test('subtype', () {
            h.enableLegacy();
            h.run([
              switch_(
                expr('num'),
                [
                  expr('int').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              ),
            ]);
          });

          test('supertype', () {
            h.enableLegacy();
            h.run([
              switch_(
                expr('int'),
                [
                  expr('num').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              ),
            ]);
          });

          test('unrelated types', () {
            h.enableLegacy();
            h.run([
              switch_(
                expr('int')..errorId = 'SCRUTINEE',
                [
                  (expr('String')..errorId = 'EXPRESSION').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              )
            ], expectedErrors: {
              'caseExpressionTypeMismatch(scrutinee: SCRUTINEE, '
                  'caseExpression: EXPRESSION, scrutineeType: int, '
                  'caseExpressionType: String, nullSafetyEnabled: false)'
            });
          });

          test('dynamic scrutinee', () {
            h.enableLegacy();
            h.run([
              switch_(
                expr('dynamic'),
                [
                  expr('int').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              ),
            ]);
          });

          test('dynamic case', () {
            h.enableLegacy();
            h.run([
              switch_(
                expr('int'),
                [
                  expr('dynamic').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              ),
            ]);
          });
        });

        group('Null safe, patterns disabled:', () {
          test('subtype', () {
            h.disablePatterns();
            h.run([
              switch_(
                expr('num'),
                [
                  expr('int').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              ),
            ]);
          });

          test('supertype', () {
            h.disablePatterns();
            h.run([
              switch_(
                expr('int')..errorId = 'SCRUTINEE',
                [
                  (expr('num')..errorId = 'EXPRESSION').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              )
            ], expectedErrors: {
              'caseExpressionTypeMismatch(scrutinee: SCRUTINEE, '
                  'caseExpression: EXPRESSION, scrutineeType: int, '
                  'caseExpressionType: num, nullSafetyEnabled: true)'
            });
          });

          test('unrelated types', () {
            h.disablePatterns();
            h.run([
              switch_(
                expr('int')..errorId = 'SCRUTINEE',
                [
                  (expr('String')..errorId = 'EXPRESSION').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              )
            ], expectedErrors: {
              'caseExpressionTypeMismatch(scrutinee: SCRUTINEE, '
                  'caseExpression: EXPRESSION, scrutineeType: int, '
                  'caseExpressionType: String, nullSafetyEnabled: true)'
            });
          });

          test('dynamic scrutinee', () {
            h.disablePatterns();
            h.run([
              switch_(
                expr('dynamic'),
                [
                  expr('int').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              ),
            ]);
          });

          test('dynamic case', () {
            h.disablePatterns();
            h.run([
              switch_(
                expr('int')..errorId = 'SCRUTINEE',
                [
                  (expr('dynamic')..errorId = 'EXPRESSION').pattern.then([
                    break_(),
                  ]),
                ],
                isLegacyExhaustive: false,
              )
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
              ),
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
              ),
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
              ),
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
              ),
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
              ),
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
                switchStatementMember([], [
                  break_(),
                ]),
              ],
            ).checkIR('switch(expr(int), case(heads(variables()), '
                'block(break())))'),
          ], errorRecoveryOK: true);
        });

        test('Multiple', () {
          h.run([
            switch_(
              expr('int'),
              [
                switchStatementMember([
                  intLiteral(0).pattern,
                  intLiteral(1).pattern,
                ], [
                  break_(),
                ]),
              ],
            ).checkIR('switch(expr(int), case(heads(head(const(0, '
                'matchedType: int), true, variables()), head(const(1, '
                'matchedType: int), true, variables()), variables()), '
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
            ),
          ], expectedErrors: {
            'nonBooleanCondition(node: GUARD)'
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
            ),
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
            ),
          ], expectedErrors: {});
        });
      });

      group('requiresExhaustivenessValidation:', () {
        test('When a `default` clause is present', () {
          h.addExhaustiveness('E', true);
          h.run([
            switch_(
              expr('E'),
              [
                default_.then([
                  break_(),
                ]),
              ],
              expectRequiresExhaustivenessValidation: false,
            ),
          ]);
        });

        test('When the scrutinee is an always-exhaustive type', () {
          h.addExhaustiveness('E', true);
          h.run([
            switch_(
              expr('E'),
              [
                expr('E').pattern.then([
                  break_(),
                ]),
              ],
              expectRequiresExhaustivenessValidation: true,
            ),
          ]);
        });

        test('When the scrutinee is not an always-exhaustive type', () {
          h.addExhaustiveness('C', false);
          h.run([
            switch_(
              expr('C'),
              [
                expr('C').pattern.then([
                  break_(),
                ]),
              ],
              expectRequiresExhaustivenessValidation: false,
            ),
          ]);
        });

        test('When pattern support is disabled', () {
          h.disablePatterns();
          h.addExhaustiveness('E', true);
          h.run([
            switch_(
              expr('E'),
              [
                expr('E').pattern.then([
                  break_(),
                ]),
              ],
              isLegacyExhaustive: true,
              expectRequiresExhaustivenessValidation: false,
            ),
          ]);
        });
      });
    });

    group('Variable declaration:', () {
      test('initialized, typed', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'num', initializer: expr('int').checkSchema('num'))
              .checkIR('match(expr(int), '
                  'varPattern(x, matchedType: int, staticType: num))'),
        ]);
      });

      test('initialized, untyped', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('int').checkSchema('?'))
              .checkIR('match(expr(int), '
                  'varPattern(x, matchedType: int, staticType: int))'),
        ]);
      });

      test('uninitialized, typed', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int').checkIR(
              'declare(varPattern(x, matchedType: int, staticType: int))'),
        ]);
      });

      test('uninitialized, untyped', () {
        var x = Var('x');
        h.run([
          declare(x).checkIR('declare(varPattern(x, matchedType: dynamic, '
              'staticType: dynamic))'),
        ]);
      });

      test('promoted initializer', () {
        h.addTypeVariable('T');
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('T&int')).checkIR('match(expr(T&int), '
              'varPattern(x, matchedType: T&int, staticType: T))'),
        ]);
      });

      test('legal late pattern', () {
        var x = Var('x');
        h.run([
          match(x.pattern(), intLiteral(0), isLate: true).checkIR(
              'declare_late(x, 0, initializerType: int, staticType: int)'),
        ]);
      });

      test('illegal refutable pattern', () {
        h.run([
          (match(intLiteral(1).pattern..errorId = 'PATTERN', intLiteral(0))
            ..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(pattern: PATTERN, '
              'context: CONTEXT)'
        });
      });
    });

    group('Pattern-for-in:', () {
      group('sync', () {
        group('Expression context type schema:', () {
          test('Pattern has type', () {
            var x = Var('x');
            h.run([
              patternForIn(x.pattern(type: 'num'),
                      expr('List<int>').checkSchema('Iterable<num>'), [])
                  .checkIR('forEach(expr(List<int>), varPattern(x, '
                      'matchedType: int, staticType: num), block())'),
            ]);
          });
          test('Pattern does not have type', () {
            var x = Var('x');
            h.run([
              patternForIn(x.pattern(),
                      expr('List<int>').checkSchema('Iterable<?>'), [])
                  .checkIR('forEach(expr(List<int>), varPattern(x, '
                      'matchedType: int, staticType: int), block())'),
            ]);
          });
        });
        group('Expression type:', () {
          test('Iterable', () {
            var x = Var('x');
            h.run([
              patternForIn(x.pattern(), expr('Iterable<int>'), [])
                  .checkIR('forEach(expr(Iterable<int>), varPattern(x, '
                      'matchedType: int, staticType: int), block())'),
            ]);
          });
          test('dynamic', () {
            var x = Var('x');
            h.run([
              patternForIn(x.pattern(), expr('dynamic'), [])
                  .checkIR('forEach(expr(dynamic), varPattern(x, '
                      'matchedType: dynamic, staticType: dynamic), block())'),
            ]);
          });
          test('Object', () {
            var x = Var('x');
            h.run([
              (patternForIn(
                      x.pattern(), expr('Object')..errorId = 'EXPRESSION', [])
                    ..errorId = 'FOR')
                  .checkIR('forEach(expr(Object), varPattern(x, '
                      'matchedType: error, staticType: error), block())'),
            ], expectedErrors: {
              'patternForInExpressionIsNotIterable(node: FOR, '
                  'expression: EXPRESSION, expressionType: Object)'
            });
          });
          test('error', () {
            var x = Var('x');
            h.run([
              (patternForIn(x.pattern(), expr('error'), []))
                  .checkIR('forEach(expr(error), varPattern(x, '
                      'matchedType: error, staticType: error), block())'),
            ]);
          });
        });
        group('Refutability:', () {
          test('When a refutable pattern', () {
            var x = Var('x');
            h.run([
              (patternForIn(x.pattern().nullCheck..errorId = 'PATTERN',
                      expr('Iterable<int?>'), [])
                    ..errorId = 'FOR')
                  .checkIR('forEach(expr(Iterable<int?>), nullCheckPattern('
                      'varPattern(x, matchedType: int, staticType: int), '
                      'matchedType: int?), block())'),
            ], expectedErrors: {
              'refutablePatternInIrrefutableContext(pattern: PATTERN, '
                  'context: FOR)',
            });
          });
          test('When the variable type is not a subtype of the matched type',
              () {
            var x = Var('x');
            h.run([
              (patternForIn(x.pattern(type: 'String')..errorId = 'PATTERN',
                      expr('Iterable<int>'), [])
                    ..errorId = 'FOR')
                  .checkIR('forEach(expr(Iterable<int>), varPattern(x, '
                      'matchedType: int, staticType: String), block())'),
            ], expectedErrors: {
              'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                  'context: FOR, matchedType: int, requiredType: String)',
            });
          });
        });
      });
      group('async', () {
        group('Expression context type schema:', () {
          test('Pattern has type', () {
            var x = Var('x');
            h.run([
              patternForIn(
                x.pattern(type: 'num'),
                expr('Stream<int>').checkSchema('Stream<num>'),
                [],
                hasAwait: true,
              ).checkIR('forEach(expr(Stream<int>), varPattern(x, '
                  'matchedType: int, staticType: num), block())'),
            ]);
          });
          test('Pattern does not have type', () {
            var x = Var('x');
            h.run([
              patternForIn(
                x.pattern(),
                expr('Stream<int>').checkSchema('Stream<?>'),
                [],
                hasAwait: true,
              ).checkIR('forEach(expr(Stream<int>), varPattern(x, '
                  'matchedType: int, staticType: int), block())'),
            ]);
          });
        });
        group('Expression type:', () {
          test('Stream', () {
            var x = Var('x');
            h.run([
              patternForIn(
                x.pattern(),
                expr('Stream<int>'),
                [],
                hasAwait: true,
              ).checkIR('forEach(expr(Stream<int>), varPattern(x, '
                  'matchedType: int, staticType: int), block())'),
            ]);
          });
          test('dynamic', () {
            var x = Var('x');
            h.run([
              patternForIn(
                x.pattern(),
                expr('dynamic'),
                [],
                hasAwait: true,
              ).checkIR('forEach(expr(dynamic), varPattern(x, '
                  'matchedType: dynamic, staticType: dynamic), block())'),
            ]);
          });
          test('Object', () {
            var x = Var('x');
            h.run([
              (patternForIn(
                x.pattern(),
                expr('Object')..errorId = 'EXPRESSION',
                [],
                hasAwait: true,
              )..errorId = 'FOR')
                  .checkIR('forEach(expr(Object), varPattern(x, '
                      'matchedType: error, staticType: error), block())'),
            ], expectedErrors: {
              'patternForInExpressionIsNotIterable(node: FOR, '
                  'expression: EXPRESSION, expressionType: Object)'
            });
          });
        });
        group('Refutability:', () {
          test('When a refutable pattern', () {
            var x = Var('x');
            h.run([
              (patternForIn(
                x.pattern().nullCheck..errorId = 'PATTERN',
                expr('Stream<int?>'),
                [],
                hasAwait: true,
              )..errorId = 'FOR')
                  .checkIR('forEach(expr(Stream<int?>), nullCheckPattern('
                      'varPattern(x, matchedType: int, staticType: int), '
                      'matchedType: int?), block())'),
            ], expectedErrors: {
              'refutablePatternInIrrefutableContext(pattern: PATTERN, '
                  'context: FOR)',
            });
          });
          test('When the variable type is not a subtype of the matched type',
              () {
            var x = Var('x');
            h.run([
              (patternForIn(
                x.pattern(type: 'String')..errorId = 'PATTERN',
                expr('Stream<int>'),
                [],
                hasAwait: true,
              )..errorId = 'FOR')
                  .checkIR('forEach(expr(Stream<int>), varPattern(x, '
                      'matchedType: int, staticType: String), block())'),
            ], expectedErrors: {
              'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                  'context: FOR, matchedType: int, requiredType: String)',
            });
          });
        });
      });
    });
  });

  group('Patterns:', () {
    group('Cast:', () {
      test('Type schema', () {
        var x = Var('x');
        h.run([
          ifCase(
            expr('num'),
            x.pattern().as_('int'),
            [],
          ).checkIR('ifCase(expr(num), castPattern(varPattern(x, '
              'matchedType: int, staticType: int), int, matchedType: num), '
              'variables(x), true, block(), noop)'),
        ]);
      });

      group('Refutable context:', () {
        test('When matched type is a subtype of required type', () {
          h.run([
            ifCase(
              expr('int'),
              wildcard().as_('num')..errorId = 'PATTERN',
              [],
            ).checkIR('ifCase(expr(int), castPattern(wildcardPattern('
                'matchedType: num), num, matchedType: int), '
                'variables(), true, block(), noop)'),
          ], expectedErrors: {
            'matchedTypeIsSubtypeOfRequired(pattern: PATTERN, '
                'matchedType: int, requiredType: num)',
          });
        });
      });

      group('Refutability:', () {
        test('When matched type is a subtype of variable type', () {
          var x = Var('x');
          h.run([
            match(x.pattern().as_('num')..errorId = 'PATTERN', expr('int'))
                .checkIR('match(expr(int), '
                    'castPattern(varPattern(x, matchedType: num, '
                    'staticType: num), num, matchedType: int))'),
          ], expectedErrors: {
            'matchedTypeIsSubtypeOfRequired(pattern: PATTERN, '
                'matchedType: int, requiredType: num)',
          });
        });

        test('When matched type is dynamic', () {
          var x = Var('x');
          h.run([
            match(x.pattern().as_('num'), expr('dynamic'))
                .checkIR('match(expr(dynamic), '
                    'castPattern(varPattern(x, matchedType: num, '
                    'staticType: num), num, matchedType: dynamic))'),
          ]);
        });

        test('When matched type is not a subtype of variable type', () {
          var x = Var('x');
          h.run([
            match(x.pattern().as_('num'), expr('String'))
                .checkIR('match(expr(String), '
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
          'refutablePatternInIrrefutableContext(pattern: PATTERN, '
              'context: CONTEXT)'
        });
      });
    });

    group('Map:', () {
      group('Type schema:', () {
        test('Explicit type arguments', () {
          var x = Var('x');
          h.run([
            match(
              mapPatternWithTypeArguments(
                keyType: 'bool',
                valueType: 'int',
                elements: [
                  mapPatternEntry(expr('int'), x.pattern()),
                ],
              ),
              expr('dynamic').checkSchema('Map<bool, int>'),
            ),
          ]);
        });
        group('Implicit element type:', () {
          test('No elements', () {
            h.run([
              match(
                mapPattern([])..errorId = 'PATTERN',
                expr('dynamic').checkSchema('Map<?, ?>'),
              ),
            ], expectedErrors: {
              'emptyMapPattern(pattern: PATTERN)',
            });
          });

          test('Variable patterns', () {
            var x = Var('x');
            var y = Var('y');
            h.run([
              match(
                mapPattern([
                  mapPatternEntry(expr('bool'), x.pattern(type: 'int?')),
                  mapPatternEntry(expr('bool'), y.pattern(type: 'num')),
                ]),
                expr('dynamic').checkSchema('Map<?, int>'),
              ),
            ]);
          });
        });
      });

      group('Static type:', () {
        test('Explicit type arguments', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('dynamic'),
              mapPatternWithTypeArguments(
                keyType: 'bool',
                valueType: 'int',
                elements: [
                  mapPatternEntry(
                    expr('Object').checkSchema('bool'),
                    x.pattern(),
                  ),
                ],
              ),
              [],
            ).checkIR('ifCase(expr(dynamic), mapPattern(mapPatternEntry('
                'expr(Object), varPattern(x, matchedType: int, staticType: '
                'int)), matchedType: dynamic, requiredType: Map<bool, int>), '
                'variables(x), true, block(), noop)'),
          ]);
        });

        test('Matched type is a map', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('Map<bool, int>'),
              mapPattern([
                mapPatternEntry(
                  expr('Object').checkSchema('bool'),
                  x.pattern(),
                ),
              ]),
              [],
            ).checkIR('ifCase(expr(Map<bool, int>), mapPattern(mapPatternEntry('
                'expr(Object), varPattern(x, matchedType: int, staticType: '
                'int)), matchedType: Map<bool, int>, requiredType: '
                'Map<bool, int>), variables(x), true, block(), noop)'),
          ]);
        });

        test('Matched type is dynamic', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('dynamic'),
              mapPattern([
                mapPatternEntry(
                  expr('Object').checkSchema('?'),
                  x.pattern(),
                ),
              ]),
              [],
            ).checkIR('ifCase(expr(dynamic), mapPattern(mapPatternEntry('
                'expr(Object), varPattern(x, matchedType: dynamic, staticType: '
                'dynamic)), matchedType: dynamic, requiredType: '
                'Map<dynamic, dynamic>), variables(x), true, block(), noop)'),
          ]);
        });

        test('Matched type is error', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('error'),
              mapPattern([
                mapPatternEntry(
                  expr('Object').checkSchema('?'),
                  x.pattern(),
                ),
              ]),
              [],
            ).checkIR('ifCase(expr(error), mapPattern(mapPatternEntry('
                'expr(Object), varPattern(x, matchedType: error, staticType: '
                'error)), matchedType: error, requiredType: '
                'Map<error, error>), variables(x), true, block(), noop)'),
          ]);
        });

        test('Matched type is other', () {
          var x = Var('x');
          h.run([
            ifCase(
              expr('String'),
              mapPattern([
                mapPatternEntry(
                  expr('Object').checkSchema('?'),
                  x.pattern(),
                ),
              ]),
              [],
            ).checkIR('ifCase(expr(String), mapPattern(mapPatternEntry('
                'expr(Object), varPattern(x, matchedType: Object?, staticType: '
                'Object?)), matchedType: String, requiredType: '
                'Map<Object?, Object?>), variables(x), true, block(), noop)'),
          ]);
        });
      });

      group('Refutable context:', () {
        test('When matched type is a subtype of required type', () {
          h.run([
            match(
              mapPatternWithTypeArguments(
                keyType: 'Object',
                valueType: 'num',
                elements: [
                  mapPatternEntry(
                    expr('Object').checkSchema('Object'),
                    wildcard(),
                  ),
                ],
              ),
              expr('Map<bool, int>'),
            ).checkIR('match(expr(Map<bool, int>), mapPattern(mapPatternEntry('
                'expr(Object), wildcardPattern(matchedType: num)), '
                'matchedType: Map<bool, int>, '
                'requiredType: Map<Object, num>))'),
          ]);
        });

        test('When matched type is dynamic', () {
          h.run([
            match(
              mapPatternWithTypeArguments(
                keyType: 'Object',
                valueType: 'num',
                elements: [
                  mapPatternEntry(
                    expr('Object').checkSchema('Object'),
                    wildcard(),
                  ),
                ],
              ),
              expr('dynamic'),
            ).checkIR('match(expr(dynamic), mapPattern(mapPatternEntry('
                'expr(Object), wildcardPattern(matchedType: num)), '
                'matchedType: dynamic, requiredType: Map<Object, num>))'),
          ]);
        });

        test('When matched type is not a subtype of required type', () {
          h.run([
            match(
              mapPatternWithTypeArguments(
                keyType: 'bool',
                valueType: 'int',
                elements: [
                  mapPatternEntry(
                    expr('Object').checkSchema('bool'),
                    wildcard(),
                  ),
                ],
              )..errorId = 'PATTERN',
              expr('String'),
            )..errorId = 'CONTEXT',
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT, matchedType: String, '
                'requiredType: Map<bool, int>)'
          });
        });
      });

      group('Errors:', () {
        test('Rest pattern first', () {
          var x = Var('x');
          h.run([
            match(
              mapPattern([
                restPattern()..errorId = 'REST_ELEMENT',
                mapPatternEntry(expr('bool'), x.pattern(type: 'int')),
              ])
                ..errorId = 'MAP_PATTERN',
              expr('dynamic'),
            ),
          ], expectedErrors: {
            'restPatternInMap(node: MAP_PATTERN, element: REST_ELEMENT)'
          });
        });
        test('Rest pattern last', () {
          var x = Var('x');
          h.run([
            match(
              mapPattern([
                mapPatternEntry(expr('bool'), x.pattern(type: 'int')),
                restPattern()..errorId = 'REST_ELEMENT',
              ])
                ..errorId = 'MAP_PATTERN',
              expr('dynamic'),
            ),
          ], expectedErrors: {
            'restPatternInMap(node: MAP_PATTERN, element: REST_ELEMENT)'
          });
        });
        test('Two rest elements at the end', () {
          var x = Var('x');
          h.run([
            match(
              mapPattern([
                mapPatternEntry(expr('bool'), x.pattern(type: 'int')),
                restPattern()..errorId = 'REST_ELEMENT1',
                restPattern()..errorId = 'REST_ELEMENT2',
              ])
                ..errorId = 'MAP_PATTERN',
              expr('dynamic'),
            ),
          ], expectedErrors: {
            'restPatternInMap(node: MAP_PATTERN, element: REST_ELEMENT1)',
            'restPatternInMap(node: MAP_PATTERN, element: REST_ELEMENT2)',
          });
        });
        test('Two rest elements not at the end', () {
          var x = Var('x');
          h.run([
            match(
              mapPattern([
                restPattern()..errorId = 'REST_ELEMENT1',
                restPattern()..errorId = 'REST_ELEMENT2',
                mapPatternEntry(expr('bool'), x.pattern(type: 'int')),
              ])
                ..errorId = 'MAP_PATTERN',
              expr('dynamic'),
            ),
          ], expectedErrors: {
            'restPatternInMap(node: MAP_PATTERN, element: REST_ELEMENT1)',
            'restPatternInMap(node: MAP_PATTERN, element: REST_ELEMENT2)',
          });
        });
        test('Rest pattern with subpattern', () {
          var x = Var('x');
          h.run([
            match(
              mapPattern([
                mapPatternEntry(expr('bool'), x.pattern(type: 'int')),
                restPattern(wildcard())..errorId = 'REST_ELEMENT',
              ])
                ..errorId = 'MAP_PATTERN',
              expr('dynamic'),
            ),
          ], expectedErrors: {
            'restPatternInMap(node: MAP_PATTERN, element: REST_ELEMENT)',
          });
        });
      });
    });

    group('List:', () {
      group('Type schema:', () {
        test('Explicit element type', () {
          var x = Var('x');
          h.run([
            match(listPattern([x.pattern()], elementType: 'int'),
                expr('dynamic').checkSchema('List<int>')),
          ]);
        });

        group('Implicit element type:', () {
          test('No elements', () {
            h.run([
              match(listPattern([]), expr('dynamic').checkSchema('List<?>')),
            ]);
          });

          test('Variable patterns', () {
            var x = Var('x');
            var y = Var('y');
            h.run([
              match(
                  listPattern(
                      [x.pattern(type: 'int?'), y.pattern(type: 'num')]),
                  expr('dynamic').checkSchema('List<int>')),
            ]);
          });

          group('Rest pattern:', () {
            group('With pattern:', () {
              test('Iterable', () {
                var x = Var('x');
                h.run([
                  match(
                    listPattern([
                      restPattern(x.pattern(type: 'Iterable<int>')),
                    ]),
                    expr('List<int>').checkSchema('List<int>'),
                  ),
                ]);
              });
              test('Not Iterable', () {
                var x = Var('x');
                h.run([
                  match(
                    listPattern([
                      restPattern(
                        x.pattern(type: 'String')..errorId = 'VAR(x)',
                      )
                    ]),
                    expr('List<int>').checkSchema('List<?>'),
                  )..errorId = 'CONTEXT',
                ], expectedErrors: {
                  'patternTypeMismatchInIrrefutableContext('
                      'pattern: VAR(x), context: CONTEXT, matchedType: '
                      'List<int>, requiredType: String)'
                });
              });
            });
            group('Without pattern:', () {
              test('No other elements', () {
                h.run([
                  match(
                    listPattern([restPattern()]),
                    expr('dynamic').checkSchema('List<?>'),
                  ),
                ]);
              });
              test('Has other elements', () {
                var x = Var('x');
                h.run([
                  match(
                    listPattern([
                      x.pattern(type: 'int'),
                      restPattern(),
                    ]),
                    expr('dynamic').checkSchema('List<int>'),
                  ),
                ]);
              });
            });
          });
        });
      });

      group('Static type:', () {
        test('Explicit type', () {
          var x = Var('x');
          h.run([
            match(listPattern([x.pattern(type: 'num')], elementType: 'int'),
                    expr('dynamic'))
                .checkIR('match(expr(dynamic), '
                    'listPattern(varPattern(x, matchedType: int, '
                    'staticType: num), '
                    'matchedType: dynamic, requiredType: List<int>))'),
          ]);
        });

        test('Matched type is a list', () {
          var x = Var('x');
          var y = Var('y');
          h.run([
            match(
              listPattern([
                x.pattern(expectInferredType: 'int'),
                restPattern(
                  y.pattern(expectInferredType: 'List<int>'),
                ),
              ]),
              expr('List<int>'),
            ).checkIR('match(expr(List<int>), listPattern(varPattern(x, '
                'matchedType: int, staticType: int), ...(varPattern(y, '
                'matchedType: List<int>, staticType: List<int>)), '
                'matchedType: List<int>, requiredType: List<int>))'),
          ]);
        });

        test('Matched type is dynamic', () {
          var x = Var('x');
          var y = Var('y');
          h.run([
            match(
              listPattern([
                x.pattern(expectInferredType: 'dynamic'),
                restPattern(y.pattern(expectInferredType: 'List<dynamic>')),
              ]),
              expr('dynamic'),
            ).checkIR('match(expr(dynamic), listPattern(varPattern(x, '
                'matchedType: dynamic, staticType: dynamic), ...(varPattern(y, '
                'matchedType: List<dynamic>, staticType: List<dynamic>)), '
                'matchedType: dynamic, requiredType: List<dynamic>))'),
          ]);
        });

        test('Matched type is error', () {
          var x = Var('x');
          var y = Var('y');
          h.run([
            match(
              listPattern([
                x.pattern(expectInferredType: 'error'),
                restPattern(y.pattern(expectInferredType: 'List<error>')),
              ]),
              expr('error'),
            ).checkIR('match(expr(error), listPattern(varPattern(x, '
                'matchedType: error, staticType: error), ...(varPattern(y, '
                'matchedType: List<error>, staticType: List<error>)), '
                'matchedType: error, requiredType: List<error>))'),
          ]);
        });

        test('Matched type is other', () {
          var x = Var('x');
          var y = Var('y');
          h.run([
            ifCase(
              expr('Object'),
              listPattern([
                x.pattern(expectInferredType: 'Object?'),
                restPattern(y.pattern(expectInferredType: 'List<Object?>')),
              ]),
              [],
            ).checkIR('ifCase(expr(Object), listPattern(varPattern(x, '
                'matchedType: Object?, staticType: Object?), ...(varPattern(y, '
                'matchedType: List<Object?>, staticType: List<Object?>)), '
                'matchedType: Object, requiredType: List<Object?>), '
                'variables(x, y), true, block(), noop)'),
          ]);
        });

        group('Rest pattern:', () {
          test('With pattern', () {
            var x = Var('x');
            h.run([
              match(
                listPattern([restPattern(x.pattern())]),
                expr('List<int>'),
              ).checkIR('match(expr(List<int>), listPattern(...(varPattern(x, '
                  'matchedType: List<int>, staticType: List<int>)), '
                  'matchedType: List<int>, requiredType: List<int>))'),
            ]);
          });
          test('Without pattern', () {
            h.run([
              match(
                listPattern([restPattern()]),
                expr('List<int>'),
              ).checkIR('match(expr(List<int>), listPattern(..., '
                  'matchedType: List<int>, requiredType: List<int>))'),
            ]);
          });
        });
      });

      group('Refutability:', () {
        test('When matched type is a subtype of pattern type', () {
          h.run([
            match(
              listPattern([wildcard()], elementType: 'num'),
              expr('List<int>'),
            ).checkIR('match(expr(List<int>), listPattern(wildcardPattern'
                '(matchedType: num), matchedType: List<int>, '
                'requiredType: List<num>))'),
          ]);
        });

        test('When matched type is dynamic', () {
          h.run([
            match(listPattern([wildcard()], elementType: 'num'),
                    expr('dynamic'))
                .checkIR('match(expr(dynamic), listPattern(wildcardPattern('
                    'matchedType: num), matchedType: dynamic, '
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

      group('Rest pattern:', () {
        group('Duplicate:', () {
          test('With pattern', () {
            var x = Var('x');
            var y = Var('y');
            h.run([
              match(
                listPattern([
                  restPattern(x.pattern())..errorId = 'ORI',
                  restPattern(y.pattern())..errorId = 'DUP',
                ])
                  ..errorId = 'LIST_PATTERN',
                expr('List<int>'),
              ).checkIR('match(expr(List<int>), listPattern(...(varPattern(x, '
                  'matchedType: List<int>, staticType: List<int>)), '
                  '...(varPattern(y, matchedType: List<int>, staticType: '
                  'List<int>)), matchedType: List<int>, '
                  'requiredType: List<int>))'),
            ], expectedErrors: {
              'duplicateRestPattern(mapOrListPattern: LIST_PATTERN, '
                  'original: ORI, '
                  'duplicate: DUP)',
            });
          });
          test('Without pattern', () {
            h.run([
              match(
                listPattern([
                  restPattern()..errorId = 'ORI',
                  restPattern()..errorId = 'DUP',
                ])
                  ..errorId = 'LIST_PATTERN',
                expr('List<int>'),
              ).checkIR('match(expr(List<int>), listPattern(..., ..., '
                  'matchedType: List<int>, requiredType: List<int>))'),
            ], expectedErrors: {
              'duplicateRestPattern(mapOrListPattern: LIST_PATTERN, '
                  'original: ORI, '
                  'duplicate: DUP)',
            });
          });
        });
        test('First', () {
          var x = Var('x');
          h.run([
            match(
              listPattern([
                restPattern(),
                x.pattern(),
              ]),
              expr('List<int>'),
            ).checkIR('match(expr(List<int>), listPattern(..., '
                'varPattern(x, matchedType: int, staticType: int), '
                'matchedType: List<int>, requiredType: List<int>))'),
          ]);
        });
        test('Last', () {
          var x = Var('x');
          h.run([
            match(
              listPattern([
                x.pattern(),
                restPattern(),
              ]),
              expr('List<int>'),
            ).checkIR('match(expr(List<int>), listPattern(varPattern(x, '
                'matchedType: int, staticType: int), ..., '
                'matchedType: List<int>, requiredType: List<int>))'),
          ]);
        });
      });

      test('Match var overlap', () {
        var x1 = Var('x', identity: 'x1')..errorId = 'x1';
        var x2 = Var('x', identity: 'x2')..errorId = 'x2';
        h.run([
          match(
            listPattern([
              x1.pattern(),
              x2.pattern(),
            ]),
            expr('List<int>'),
          ),
        ], expectedErrors: {
          'duplicateVariablePattern(name: x, original: x1, duplicate: x2)',
        });
      });
    });

    group('Logical-and:', () {
      test('Type schema', () {
        h.run([
          match(
                  (wildcard(type: 'int?')..errorId = 'WILDCARD1')
                      .and(wildcard(type: 'double?')..errorId = 'WILDCARD2'),
                  nullLiteral.checkSchema('Null'))
              .checkIR('match(null, logicalAndPattern(wildcardPattern('
                  'matchedType: Null), wildcardPattern(matchedType: Null), '
                  'matchedType: Null))'),
        ], expectedErrors: {
          'unnecessaryWildcardPattern(pattern: WILDCARD1, '
              'kind: logicalAndPatternOperand)',
          'unnecessaryWildcardPattern(pattern: WILDCARD2, '
              'kind: logicalAndPatternOperand)'
        });
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
              'context: CONTEXT, matchedType: int, requiredType: double)'
        });
      });

      test('Duplicate variable pattern', () {
        var x1 = Var('x', identity: 'x1')..errorId = 'x1';
        var x2 = Var('x', identity: 'x2')..errorId = 'x2';
        h.run([
          match(x1.pattern().and(x2.pattern()), expr('int')),
        ], expectedErrors: {
          'duplicateVariablePattern(name: x, original: x1, duplicate: x2)',
        });
      });
    });

    group('Logical-or:', () {
      test('Type schema', () {
        h.run([
          (match(
            wildcard(type: 'int?').or(wildcard(type: 'double?'))
              ..errorId = 'PATTERN',
            nullLiteral.checkSchema('?'),
          )..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(pattern: PATTERN, '
              'context: CONTEXT)'
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
          'refutablePatternInIrrefutableContext(pattern: PATTERN, '
              'context: CONTEXT)'
        });
      });

      group('Variables:', () {
        group('Should have same types:', () {
          group('Same:', () {
            test('explicit / explicit', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2');
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                ifCase(
                  expr('Object'),
                  x1.pattern(type: 'int').or(x2.pattern(type: 'int')),
                  [],
                ).checkIR('ifCase(expr(Object), logicalOrPattern(varPattern(x, '
                    'matchedType: Object, staticType: int), varPattern(x, '
                    'matchedType: Object, staticType: int), '
                    'matchedType: Object), variables(int x = [x1, x2]), '
                    'true, block(), noop)'),
              ]);
            });
            test('explicit / explicit, normalized', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2');
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                ifCase(
                  expr('Object'),
                  x1
                      .pattern(type: 'Object')
                      .or(x2.pattern(type: 'FutureOr<Object>')),
                  [],
                ).checkIR('ifCase(expr(Object), logicalOrPattern(varPattern(x, '
                    'matchedType: Object, staticType: Object), varPattern(x, '
                    'matchedType: Object, staticType: FutureOr<Object>), '
                    'matchedType: Object), variables(Object x = [x1, x2]), '
                    'true, block(), noop)'),
              ]);
            });
            test('explicit / implicit', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2');
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                ifCase(
                  expr('int'),
                  x1.pattern(type: 'int').or(x2.pattern()),
                  [],
                ).checkIR('ifCase(expr(int), logicalOrPattern(varPattern(x, '
                    'matchedType: int, staticType: int), varPattern(x, '
                    'matchedType: int, staticType: int), matchedType: int), '
                    'variables(int x = [x1, x2]), true, block(), noop)'),
              ]);
            });
            test('implicit / explicit', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2');
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                ifCase(
                  expr('int'),
                  x1.pattern().or(x2.pattern(type: 'int')),
                  [],
                ).checkIR('ifCase(expr(int), logicalOrPattern(varPattern(x, '
                    'matchedType: int, staticType: int), varPattern(x, '
                    'matchedType: int, staticType: int), matchedType: int), '
                    'variables(int x = [x1, x2]), true, block(), noop)'),
              ]);
            });
            test('implicit / implicit', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2');
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                ifCase(
                  expr('int'),
                  x1.pattern().or(x2.pattern()),
                  [],
                ).checkIR('ifCase(expr(int), logicalOrPattern(varPattern(x, '
                    'matchedType: int, staticType: int), varPattern(x, '
                    'matchedType: int, staticType: int), matchedType: int), '
                    'variables(int x = [x1, x2]), true, block(), noop)'),
              ]);
            });
          });
          group('Not same:', () {
            test('explicit / explicit', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2')..errorId = 'x2';
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                ifCase(
                  expr('Object'),
                  x1.pattern(type: 'int').or(x2.pattern(type: 'num')),
                  [],
                ).checkIR('ifCase(expr(Object), logicalOrPattern(varPattern(x, '
                    'matchedType: Object, staticType: int), varPattern(x, '
                    'matchedType: Object, staticType: num), matchedType: '
                    'Object), variables(notConsistent:differentFinalityOrType '
                    'error x = [x1, x2]), true, block(), noop)'),
              ], expectedErrors: {
                'inconsistentJoinedPatternVariable(variable: x = [x1, x2], '
                    'component: x2)',
              });
            });
            test('explicit / implicit', () {
              var x1 = Var('x', identity: 'x1');
              var x2 = Var('x', identity: 'x2')..errorId = 'x2';
              PatternVariableJoin('x', expectedComponents: [x1, x2]);
              h.run([
                ifCase(
                  expr('num'),
                  x1.pattern(type: 'int').or(x2.pattern()),
                  [],
                ).checkIR('ifCase(expr(num), logicalOrPattern(varPattern(x, '
                    'matchedType: num, staticType: int), varPattern(x, '
                    'matchedType: num, staticType: num), matchedType: num), '
                    'variables(notConsistent:differentFinalityOrType error x = '
                    '[x1, x2]), true, block(), noop)'),
              ], expectedErrors: {
                'inconsistentJoinedPatternVariable(variable: x = [x1, x2], '
                    'component: x2)',
              });
            });
          });
        });
        test('Should have same finality', () {
          var x1 = Var('x', isFinal: true, identity: 'x1');
          var x2 = Var('x', identity: 'x2')..errorId = 'x2';
          PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            ifCase(
              expr('int'),
              x1.pattern().or(x2.pattern()),
              [],
            ).checkIR('ifCase(expr(int), logicalOrPattern(varPattern(x, '
                'matchedType: int, staticType: int), varPattern(x, '
                'matchedType: int, staticType: int), matchedType: int), '
                'variables(notConsistent:differentFinalityOrType int x = '
                '[x1, x2]), true, block(), noop)'),
          ], expectedErrors: {
            'inconsistentJoinedPatternVariable(variable: x = [x1, x2], '
                'component: x2)',
          });
        });
        group('Should be present in both branches:', () {
          test('Both have', () {
            var x1 = Var('x', identity: 'x1');
            var x2 = Var('x', identity: 'x2');
            PatternVariableJoin('x', expectedComponents: [x1, x2]);
            h.run([
              ifCase(
                expr('int'),
                x1.pattern().or(x2.pattern()),
                [],
              ).checkIR('ifCase(expr(int), logicalOrPattern(varPattern(x, '
                  'matchedType: int, staticType: int), varPattern(x, '
                  'matchedType: int, staticType: int), matchedType: int), '
                  'variables(int x = [x1, x2]), true, block(), noop)'),
            ]);
          });
          test('Left has', () {
            var x1 = Var('x', identity: 'x1')..errorId = 'x1';
            PatternVariableJoin('x', expectedComponents: [x1]);
            h.run([
              ifCase(
                expr('int'),
                (x1.pattern().or(wildcard()))..errorId = 'PATTERN',
                [],
              ).checkIR('ifCase(expr(int), logicalOrPattern(varPattern(x, '
                  'matchedType: int, staticType: int), wildcardPattern('
                  'matchedType: int), matchedType: int), variables('
                  'notConsistent:logicalOr int x = [x1]), true, block(), '
                  'noop)'),
            ], expectedErrors: {
              'logicalOrPatternBranchMissingVariable(node: PATTERN, '
                  'hasInLeft: true, name: x, variable: x1)',
            });
          });
          test('Right has', () {
            var x1 = Var('x', identity: 'x1')..errorId = 'x1';
            PatternVariableJoin('x', expectedComponents: [x1]);
            h.run([
              ifCase(
                expr('int'),
                (wildcard().or(x1.pattern()))..errorId = 'PATTERN',
                [],
              ).checkIR('ifCase(expr(int), logicalOrPattern(wildcardPattern('
                  'matchedType: int), varPattern(x, matchedType: int, '
                  'staticType: int), matchedType: int), variables('
                  'notConsistent:logicalOr int x = [x1]), true, block(), '
                  'noop)'),
            ], expectedErrors: {
              'logicalOrPatternBranchMissingVariable(node: PATTERN, '
                  'hasInLeft: false, name: x, variable: x1)',
            });
          });
        });
      });
    });

    group('Null-assert:', () {
      test('Type schema', () {
        var x = Var('x');
        h.run([
          match(x.pattern(type: 'int').nullAssert..errorId = 'PATTERN',
                  expr('int').checkSchema('int?'))
              .checkIR('match(expr(int), '
                  'nullAssertPattern(varPattern(x, matchedType: int, '
                  'staticType: int), matchedType: int))'),
        ], expectedErrors: {
          'matchedTypeIsStrictlyNonNullable(pattern: PATTERN, '
              'matchedType: int)'
        });
      });

      group('Refutability:', () {
        test('When matched type is nullable', () {
          h.run([
            match(wildcard().nullAssert, expr('int?'))
                .checkIR('match(expr(int?), nullAssertPattern('
                    'wildcardPattern(matchedType: int), matchedType: int?))'),
          ]);
        });

        test('When matched type is non-nullable', () {
          h.run([
            match(wildcard().nullAssert..errorId = 'PATTERN', expr('int'))
                .checkIR('match(expr(int), nullAssertPattern('
                    'wildcardPattern(matchedType: int), matchedType: int))'),
          ], expectedErrors: {
            'matchedTypeIsStrictlyNonNullable(pattern: PATTERN, '
                'matchedType: int)'
          });
        });

        test('When matched type is dynamic', () {
          h.run([
            match(wildcard().nullAssert, expr('dynamic'))
                .checkIR('match(expr(dynamic), nullAssertPattern('
                    'wildcardPattern(matchedType: dynamic), '
                    'matchedType: dynamic))'),
          ]);
        });

        test('Sub-refutability', () {
          h.run([
            (match(
                (wildcard(type: 'int')..errorId = 'INT').nullAssert
                  ..errorId = 'PATTERN',
                expr('num'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'matchedTypeIsStrictlyNonNullable(pattern: PATTERN, '
                'matchedType: num)',
            'patternTypeMismatchInIrrefutableContext(pattern: INT, '
                'context: CONTEXT, matchedType: num, requiredType: int)'
          });
        });
      });

      group('Refutable', () {
        test('When matched type is nullable', () {
          h.run([
            ifCase(
              expr('int?'),
              wildcard().nullAssert,
              [],
            ).checkIR('ifCase(expr(int?), nullAssertPattern(wildcardPattern('
                'matchedType: int), matchedType: int?), variables(), true, '
                'block(), noop)'),
          ]);
        });
        test('When matched type is non-nullable', () {
          h.run([
            ifCase(
              expr('int'),
              wildcard().nullAssert..errorId = 'PATTERN',
              [],
            ).checkIR('ifCase(expr(int), nullAssertPattern(wildcardPattern('
                'matchedType: int), matchedType: int), variables(), true, '
                'block(), noop)'),
          ], expectedErrors: {
            'matchedTypeIsStrictlyNonNullable(pattern: PATTERN, '
                'matchedType: int)'
          });
        });
      });
    });

    group('Null-check:', () {
      test('Type schema', () {
        var x = Var('x');
        h.run([
          (match(x.pattern(type: 'int').nullCheck..errorId = 'PATTERN',
              expr('int').checkSchema('?'))
            ..errorId = 'CONTEXT'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(pattern: PATTERN, '
              'context: CONTEXT)'
        });
      });

      group('Refutability:', () {
        test('When matched type is nullable', () {
          h.run([
            (match(wildcard().nullCheck..errorId = 'PATTERN', expr('int?'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT)'
          });
        });

        test('When matched type is non-nullable', () {
          h.run([
            (match(wildcard().nullCheck..errorId = 'PATTERN', expr('int'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT)'
          });
        });

        test('When matched type is dynamic', () {
          h.run([
            (match(wildcard().nullCheck..errorId = 'PATTERN', expr('dynamic'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT)'
          });
        });

        test('Sub-refutability', () {
          h.run([
            (match(wildcard(type: 'int').nullCheck..errorId = 'PATTERN',
                expr('num'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'refutablePatternInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT)'
          });
        });
      });

      group('Refutable', () {
        test('When matched type is nullable', () {
          h.run([
            ifCase(
              expr('int?'),
              wildcard().nullCheck,
              [],
            ).checkIR('ifCase(expr(int?), nullCheckPattern(wildcardPattern('
                'matchedType: int), matchedType: int?), variables(), true, '
                'block(), noop)'),
          ]);
        });
        test('When matched type is non-nullable', () {
          h.run([
            ifCase(
              expr('int'),
              wildcard().nullCheck..errorId = 'PATTERN',
              [],
            ).checkIR('ifCase(expr(int), nullCheckPattern(wildcardPattern('
                'matchedType: int), matchedType: int), variables(), true, '
                'block(), noop)'),
          ], expectedErrors: {
            'matchedTypeIsStrictlyNonNullable(pattern: PATTERN, '
                'matchedType: int)'
          });
        });
      });
    });

    group('Object:', () {
      group('Refutable:', () {
        test('inferred', () {
          h.addDownwardInfer(name: 'B', context: 'A<int>', result: 'B<int>');
          h.addMember('B<int>', 'foo', 'int');
          h.addSuperInterfaces(
              'B', (args) => [PrimaryType('A', args: args), Type('Object')]);
          h.addSuperInterfaces('A', (_) => [Type('Object')]);
          h.run([
            ifCase(
              expr('A<int>').checkSchema('?'),
              objectPattern(
                requiredType: 'B',
                fields: [
                  Var('foo').pattern().recordField('foo'),
                ],
              ),
              [],
            ).checkIR('ifCase(expr(A<int>), objectPattern(varPattern(foo, '
                'matchedType: int, staticType: int), matchedType: A<int>, '
                'requiredType: B<int>), variables(foo), true, block(), noop)'),
          ]);
        });

        test('dynamic type', () {
          h.run([
            ifCase(
              expr('int').checkSchema('?'),
              objectPattern(
                requiredType: 'dynamic',
                fields: [
                  Var('foo').pattern().recordField('foo'),
                ],
              ),
              [],
            ).checkIR('ifCase(expr(int), objectPattern(varPattern(foo, '
                'matchedType: dynamic, staticType: dynamic), matchedType: int, '
                'requiredType: dynamic), variables(foo), true, block(), noop)'),
          ]);
        });

        test('error type', () {
          h.run([
            ifCase(
              expr('int').checkSchema('?'),
              objectPattern(
                requiredType: 'error',
                fields: [
                  Var('foo').pattern().recordField('foo'),
                ],
              ),
              [],
            ).checkIR('ifCase(expr(int), objectPattern(varPattern(foo, '
                'matchedType: error, staticType: error), matchedType: int, '
                'requiredType: error), variables(foo), true, block(), noop)'),
          ]);
        });

        test('Never type', () {
          h.run([
            ifCase(
              expr('int').checkSchema('?'),
              objectPattern(
                requiredType: 'Never',
                fields: [
                  Var('foo').pattern().recordField('foo'),
                ],
              ),
              [],
            ).checkIR('ifCase(expr(int), objectPattern(varPattern(foo, '
                'matchedType: Never, staticType: Never), matchedType: int, '
                'requiredType: Never), variables(foo), true, block(), noop)'),
          ]);
        });

        test('duplicate field name', () {
          h.addMember('A<int>', 'foo', 'int');
          h.run([
            ifCase(
              expr('A<int>'),
              objectPattern(
                requiredType: 'A<int>',
                fields: [
                  Var('a').pattern().recordField('foo')..errorId = 'ORIGINAL',
                  Var('b').pattern().recordField('foo')..errorId = 'DUPLICATE',
                ],
              )..errorId = 'PATTERN',
              [],
            ),
          ], expectedErrors: {
            'duplicateRecordPatternField('
                'objectOrRecordPattern: PATTERN, '
                'name: foo, original: ORIGINAL, '
                'duplicate: DUPLICATE)'
          });
        });
      });

      group('Irrefutable:', () {
        test('assignable', () {
          h.addMember('num', 'foo', 'bool');
          h.run([
            match(
              objectPattern(
                requiredType: 'num',
                fields: [
                  Var('foo').pattern().recordField('foo'),
                ],
              ),
              expr('int').checkSchema('num'),
            ).checkIR('match(expr(int), objectPattern(varPattern(foo, '
                'matchedType: bool, staticType: bool), '
                'matchedType: int, requiredType: num))'),
          ]);
        });

        test('not assignable', () {
          h.addMember('int', 'foo', 'bool');
          h.run([
            (match(
              objectPattern(
                requiredType: 'int',
                fields: [
                  Var('foo').pattern().recordField('foo'),
                ],
              )..errorId = 'PATTERN',
              expr('num').checkSchema('int'),
            )..errorId = 'CONTEXT')
                .checkIR('match(expr(num), objectPattern(varPattern(foo, '
                    'matchedType: bool, staticType: bool), '
                    'matchedType: num, requiredType: int))'),
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT, matchedType: num, requiredType: int)'
          });
        });
      });
    });

    group('Pattern assignment:', () {
      group('Static type:', () {
        test('Matched type is int', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'int'),
            x.pattern().assign(expr('int')).checkType('int'),
          ]);
        });
        test('Matched type is error', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'int'),
            x.pattern().assign(expr('error')).checkType('error'),
          ]);
        });
      });

      test('RHS schema', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'num'),
          x
              .pattern()
              .assign(expr('int').checkSchema('num'))
              .inTypeSchema('Object'),
        ]);
      });

      test('Duplicate assignment to same variable', () {
        var x = Var('x')..errorId = 'x';
        h.run([
          declare(x, type: 'num'),
          recordPattern([
            (x.pattern()..errorId = 'x1').recordField(),
            (x.pattern()..errorId = 'x2').recordField(),
          ]).assign(expr('(int, int)')),
        ], expectedErrors: {
          'duplicateAssignmentPatternVariable(variable: x, original: x1, '
              'duplicate: x2)',
        });
      });

      group('Refutability:', () {
        test('When matched type is a subtype of variable type', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'num'),
            x
                .pattern()
                .assign(expr('int'))
                .checkIR('patternAssignment(expr(int), assignedVarPattern(x))'),
          ]);
        });

        test('When matched type is dynamic', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'num'),
            x.pattern().assign(expr('dynamic')).checkIR(
                'patternAssignment(expr(dynamic), assignedVarPattern(x))'),
          ]);
        });

        test('When matched type is not a subtype of variable type', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'num'),
            ((x.pattern()..errorId = 'PATTERN').assign(expr('String'))
              ..errorId = 'CONTEXT'),
          ], expectedErrors: {
            'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                'context: CONTEXT, matchedType: String, requiredType: num)'
          });
        });
      });
    });

    group('Record:', () {
      group('Positional:', () {
        group('Match dynamic:', () {
          test('refutable', () {
            h.run([
              ifCase(
                expr('dynamic').checkSchema('?'),
                recordPattern([
                  Var('a').pattern(type: 'int').recordField(),
                  Var('b').pattern().recordField(),
                ]),
                [],
              ).checkIR(
                'ifCase(expr(dynamic), recordPattern(varPattern(a, '
                'matchedType: dynamic, staticType: int), varPattern(b, '
                'matchedType: dynamic, staticType: dynamic), matchedType: '
                'dynamic, requiredType: (Object?, Object?)), '
                'variables(a, b), true, block(), noop)',
              ),
            ]);
          });
        });
        group('Match error:', () {
          test('refutable', () {
            h.run([
              ifCase(
                expr('error').checkSchema('?'),
                recordPattern([
                  Var('a').pattern(type: 'int').recordField(),
                  Var('b').pattern().recordField(),
                ]),
                [],
              ).checkIR(
                'ifCase(expr(error), recordPattern(varPattern(a, '
                'matchedType: error, staticType: int), varPattern(b, '
                'matchedType: error, staticType: error), matchedType: '
                'error, requiredType: (Object?, Object?)), '
                'variables(a, b), true, block(), noop)',
              ),
            ]);
          });
        });
        group('Match record type:', () {
          group('Same shape:', () {
            test('irrefutable', () {
              h.run([
                match(
                  recordPattern([
                    Var('a').pattern(type: 'int').recordField(),
                    Var('b').pattern().recordField(),
                  ]),
                  expr('(int, String)').checkSchema('(int, ?)'),
                ).checkIR(
                    'match(expr((int, String)), recordPattern(varPattern(a, '
                    'matchedType: int, staticType: int), varPattern(b, '
                    'matchedType: String, staticType: String), '
                    'matchedType: (int, String), '
                    'requiredType: (Object?, Object?)))')
              ]);
            });
          });
          group('Different shape:', () {
            test('irrefutable', () {
              h.run([
                (match(
                  recordPattern([
                    (Var('a').pattern(type: 'int')..errorId = 'VAR(a)')
                        .recordField(),
                    Var('b').pattern().recordField(),
                  ])
                    ..errorId = 'PATTERN',
                  expr('(int,)').checkSchema('(int, ?)'),
                )..errorId = 'CONTEXT')
                    .checkIR('match(expr((int,)), recordPattern(varPattern(a, '
                        'matchedType: Object?, staticType: int), '
                        'varPattern(b, matchedType: Object?, staticType: '
                        'Object?), matchedType: (int,), requiredType: '
                        '(Object?, Object?)))'),
              ], expectedErrors: {
                'patternTypeMismatchInIrrefutableContext(pattern: VAR(a), '
                    'context: CONTEXT, matchedType: Object?, '
                    'requiredType: int)',
                'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                    'context: CONTEXT, matchedType: (int,), '
                    'requiredType: (Object?, Object?))'
              });
            });
            group('Refutable:', () {
              test('too few', () {
                h.run([
                  ifCase(
                    expr('(int,)').checkSchema('?'),
                    recordPattern([
                      Var('a').pattern().recordField(),
                      Var('b').pattern().recordField(),
                    ]),
                    [],
                  ).checkIR('ifCase(expr((int,)), recordPattern(varPattern(a, '
                      'matchedType: Object?, staticType: Object?), '
                      'varPattern(b, matchedType: Object?, staticType: '
                      'Object?), matchedType: (int,), requiredType: '
                      '(Object?, Object?)), variables(a, b), true, '
                      'block(), noop)'),
                ]);
              });
              test('too many', () {
                h.run([
                  ifCase(
                    expr('(int, String)').checkSchema('?'),
                    recordPattern([
                      Var('a').pattern().recordField(),
                    ]),
                    [],
                  ).checkIR('ifCase(expr((int, String)), '
                      'recordPattern(varPattern(a, matchedType: Object?, '
                      'staticType: Object?), matchedType: (int, String), '
                      'requiredType: (Object?,)), variables(a), true, '
                      'block(), noop)'),
                ]);
              });
            });
          });
        });
        group('Match other type:', () {
          test('refutable', () {
            h.addSuperInterfaces('X', (_) => [Type('Object')]);
            h.run([
              ifCase(
                expr('X').checkSchema('?'),
                recordPattern([
                  Var('a').pattern(type: 'int').recordField(),
                  Var('b').pattern().recordField(),
                ]),
                [],
              ).checkIR('ifCase(expr(X), recordPattern(varPattern(a, '
                  'matchedType: Object?, staticType: int), varPattern(b, '
                  'matchedType: Object?, staticType: Object?), matchedType: X, '
                  'requiredType: (Object?, Object?)), variables(a, b), '
                  'true, block(), noop)'),
            ]);
          });
        });
      });
      group('Named:', () {
        group('Match dynamic:', () {
          test('refutable', () {
            h.run([
              ifCase(
                expr('dynamic').checkSchema('?'),
                recordPattern([
                  Var('a').pattern(type: 'int').recordField('a'),
                  Var('b').pattern().recordField('b'),
                ]),
                [],
              ).checkIR('ifCase(expr(dynamic), recordPattern(varPattern(a, '
                  'matchedType: dynamic, staticType: int), varPattern(b, '
                  'matchedType: dynamic, staticType: dynamic), matchedType: '
                  'dynamic, requiredType: ({Object? a, Object? b})), '
                  'variables(a, b), true, block(), noop)'),
            ]);
          });
        });
        group('Match record type:', () {
          group('Same shape:', () {
            test('irrefutable', () {
              h.run([
                match(
                  recordPattern([
                    Var('a').pattern(type: 'int').recordField('a'),
                    Var('b').pattern().recordField('b'),
                  ]),
                  expr('({int a, String b})').checkSchema('({int a, ? b})'),
                ).checkIR('match(expr(({int a, String b})), '
                    'recordPattern(varPattern(a, matchedType: int, '
                    'staticType: int), varPattern(b, matchedType: String, '
                    'staticType: String), matchedType: ({int a, String b}), '
                    'requiredType: ({Object? a, Object? b})))')
              ]);
            });
          });
          group('Different shape:', () {
            test('irrefutable', () {
              h.run([
                (match(
                  recordPattern([
                    (Var('a').pattern(type: 'int')..errorId = 'VAR(a)')
                        .recordField('a'),
                    Var('b').pattern().recordField('b'),
                  ])
                    ..errorId = 'PATTERN',
                  expr('({int a})').checkSchema('({int a, ? b})'),
                )..errorId = 'CONTEXT')
                    .checkIR('match(expr(({int a})), '
                        'recordPattern(varPattern(a, matchedType: Object?, '
                        'staticType: int), varPattern(b, matchedType: Object?, '
                        'staticType: Object?), matchedType: ({int a}), '
                        'requiredType: ({Object? a, Object? b})))'),
              ], expectedErrors: {
                'patternTypeMismatchInIrrefutableContext(pattern: VAR(a), '
                    'context: CONTEXT, matchedType: Object?, '
                    'requiredType: int)',
                'patternTypeMismatchInIrrefutableContext(pattern: PATTERN, '
                    'context: CONTEXT, matchedType: ({int a}), '
                    'requiredType: ({Object? a, Object? b}))',
              });
            });
            group('Refutable:', () {
              test('too few', () {
                h.run([
                  ifCase(
                    expr('({int a})').checkSchema('?'),
                    recordPattern([
                      Var('a').pattern().recordField('a'),
                      Var('b').pattern().recordField('b'),
                    ]),
                    [],
                  ).checkIR('ifCase(expr(({int a})), recordPattern('
                      'varPattern(a, matchedType: Object?, staticType: '
                      'Object?), varPattern(b, matchedType: Object?, '
                      'staticType: Object?), matchedType: ({int a}), '
                      'requiredType: ({Object? a, Object? b})), '
                      'variables(a, b), true, block(), noop)'),
                ]);
              });
              test('too many', () {
                h.run([
                  ifCase(
                    expr('({int a, String b})').checkSchema('?'),
                    recordPattern([
                      Var('a').pattern().recordField('a'),
                    ]),
                    [],
                  ).checkIR('ifCase(expr(({int a, String b})), '
                      'recordPattern(varPattern(a, matchedType: Object?, '
                      'staticType: Object?), matchedType: ({int a, String b}), '
                      'requiredType: ({Object? a})), variables(a), true, '
                      'block(), noop)'),
                ]);
              });
            });
          });
        });
        group('Match other type:', () {
          test('refutable', () {
            h.addSuperInterfaces('X', (_) => [Type('Object')]);
            h.run([
              ifCase(
                expr('X').checkSchema('?'),
                recordPattern([
                  Var('a').pattern(type: 'int').recordField('a'),
                  Var('b').pattern().recordField('b'),
                ]),
                [],
              ).checkIR('ifCase(expr(X), recordPattern(varPattern(a, '
                  'matchedType: Object?, staticType: int), varPattern(b, '
                  'matchedType: Object?, staticType: Object?), matchedType: X, '
                  'requiredType: ({Object? a, Object? b})), variables(a, b), '
                  'true, block(), noop)'),
            ]);
          });
        });
        test('duplicate field name', () {
          h.run([
            ifCase(
              expr('({int a})'),
              recordPattern([
                Var('a').pattern().recordField('a')..errorId = 'ORIGINAL',
                Var('b').pattern().recordField('a')..errorId = 'DUPLICATE',
              ])
                ..errorId = 'PATTERN',
              [],
            ),
          ], expectedErrors: {
            'duplicateRecordPatternField('
                'objectOrRecordPattern: PATTERN, '
                'name: a, original: ORIGINAL, '
                'duplicate: DUPLICATE)'
          });
        });
      });
    });

    group('Relational:', () {
      test('Refutability', () {
        h.run([
          (match(
            relationalPattern('>', intLiteral(0).checkSchema('num'))
              ..errorId = 'PATTERN',
            intLiteral(1).checkSchema('?'),
          )..errorId = 'CONTEXT')
              .checkIR('match(1, >(0, matchedType: int))'),
        ], expectedErrors: {
          'refutablePatternInIrrefutableContext(pattern: PATTERN, '
              'context: CONTEXT)'
        });
      });
      test('no operator', () {
        h.addMember('C', '>', null);
        h.run([
          ifCase(
            expr('C').checkSchema('?'),
            relationalPattern(
              '>',
              intLiteral(0).checkSchema('?'),
            ),
            [],
          ).checkIR('ifCase(expr(C), >(0, matchedType: C), '
              'variables(), true, block(), noop)')
        ]);
      });
      group('Has operator:', () {
        test('int >=', () {
          h.run([
            ifCase(
              expr('int').checkSchema('?'),
              relationalPattern('>=', intLiteral(0).checkSchema('num')),
              [],
            ).checkIR('ifCase(expr(int), >=(0, matchedType: '
                'int), variables(), true, block(), noop)')
          ]);
        });
        test('Object == nullable', () {
          h.run([
            ifCase(
              expr('Object').checkSchema('?'),
              relationalPattern('==', expr('int?').checkSchema('Object?')),
              [],
            ).checkIR('ifCase(expr(Object), ==(expr(int?), '
                'matchedType: Object), variables(), true, block(), noop)')
          ]);
        });
        test('Object != nullable', () {
          h.run([
            ifCase(
              expr('Object').checkSchema('?'),
              relationalPattern('!=', expr('int?').checkSchema('Object?')),
              [],
            ).checkIR('ifCase(expr(Object), !=(expr(int?), '
                'matchedType: Object), variables(), true, block(), noop)')
          ]);
        });

        group('argument type not assignable:', () {
          test('basic', () {
            h.run([
              ifCase(
                expr('int').checkSchema('?'),
                relationalPattern('>', expr('String'))..errorId = 'PATTERN',
                [],
              ).checkIR('ifCase(expr(int), >(expr(String), '
                  'matchedType: int), variables(), true, block(), noop)')
            ], expectedErrors: {
              'relationalPatternOperandTypeNotAssignable(pattern: PATTERN, '
                  'operandType: String, parameterType: num)'
            });
          });

          test('> nullable', () {
            h.run([
              ifCase(
                expr('int'),
                relationalPattern('>', expr('int?'))..errorId = 'PATTERN',
                [],
              )
            ], expectedErrors: {
              'relationalPatternOperandTypeNotAssignable(pattern: PATTERN, '
                  'operandType: int?, parameterType: num)'
            });
          });

          test('< nullable', () {
            h.run([
              ifCase(
                expr('int'),
                relationalPattern('<', expr('int?'))..errorId = 'PATTERN',
                [],
              )
            ], expectedErrors: {
              'relationalPatternOperandTypeNotAssignable(pattern: PATTERN, '
                  'operandType: int?, parameterType: num)'
            });
          });

          test('>= nullable', () {
            h.run([
              ifCase(
                expr('int'),
                relationalPattern('>=', expr('int?'))..errorId = 'PATTERN',
                [],
              )
            ], expectedErrors: {
              'relationalPatternOperandTypeNotAssignable(pattern: PATTERN, '
                  'operandType: int?, parameterType: num)'
            });
          });

          test('<= nullable', () {
            h.run([
              ifCase(
                expr('int'),
                relationalPattern('<=', expr('int?'))..errorId = 'PATTERN',
                [],
              )
            ], expectedErrors: {
              'relationalPatternOperandTypeNotAssignable(pattern: PATTERN, '
                  'operandType: int?, parameterType: num)'
            });
          });

          test('extension type to representation', () {
            h.addSuperInterfaces('E', (_) => [Type('Object?')]);
            h.addExtensionTypeErasure('E', 'int');
            h.addMember('C', '>', 'bool Function(int)');
            h.run([
              ifCase(
                expr('C'),
                relationalPattern('>', expr('E'))..errorId = 'PATTERN',
                [],
              )
            ], expectedErrors: {
              'relationalPatternOperandTypeNotAssignable(pattern: PATTERN, '
                  'operandType: E, parameterType: int)'
            });
          });

          test('representation to extension type', () {
            h.addSuperInterfaces('E', (_) => [Type('Object?')]);
            h.addExtensionTypeErasure('E', 'int');
            h.addMember('C', '>', 'bool Function(E)');
            h.run([
              ifCase(
                expr('C'),
                relationalPattern('>', expr('int'))..errorId = 'PATTERN',
                [],
              )
            ], expectedErrors: {
              'relationalPatternOperandTypeNotAssignable(pattern: PATTERN, '
                  'operandType: int, parameterType: E)'
            });
          });
        });

        group('argument type assignable:', () {
          test('== nullable', () {
            h.run([
              ifCase(
                expr('int'),
                relationalPattern('==', expr('int?')),
                [],
              )
            ]);
          });

          test('!= nullable', () {
            h.run([
              ifCase(
                expr('int'),
                relationalPattern('!=', expr('int?')),
                [],
              )
            ]);
          });
        });

        test('return type is not assignable to bool', () {
          h.addMember('A', '>', 'int Function(Object)');
          h.run([
            ifCase(
              expr('A').checkSchema('?'),
              relationalPattern(
                '>',
                expr('String').checkSchema('Object'),
                errorId: 'PATTERN',
              ),
              [],
            ).checkIR('ifCase(expr(A), >(expr(String), '
                'matchedType: A), variables(), true, block(), noop)')
          ], expectedErrors: {
            'relationalPatternOperatorReturnTypeNotAssignableToBool('
                'pattern: PATTERN, returnType: int)'
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
                .checkIR('match(expr(int), '
                    'varPattern(x, matchedType: int, staticType: num))'),
          ]);
        });

        test('When matched type is dynamic', () {
          var x = Var('x');
          h.run([
            match(x.pattern(type: 'num'), expr('dynamic'))
                .checkIR('match(expr(dynamic), '
                    'varPattern(x, matchedType: dynamic, staticType: num))'),
          ]);
        });

        test('When matched type is error', () {
          var x = Var('x');
          h.run([
            match(x.pattern(type: 'num'), expr('error'))
                .checkIR('match(expr(error), '
                    'varPattern(x, matchedType: error, staticType: num))'),
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
          ifCase(
            expr('int'),
            wildcard(),
            [],
          ).checkIR('ifCase(expr(int), wildcardPattern(matchedType: int), '
              'variables(), true, block(), noop)'),
        ]);
      });

      test('Typed', () {
        h.run([
          ifCase(
            expr('num'),
            wildcard(type: 'int'),
            [],
          ).checkIR('ifCase(expr(num), wildcardPattern(matchedType: num), '
              'variables(), true, block(), noop)'),
        ]);
      });

      group('Refutability:', () {
        test('When matched type is a subtype of variable type', () {
          h.run([
            match(wildcard(type: 'num'), expr('int'))
                .checkIR('match(expr(int), wildcardPattern(matchedType: int))'),
          ]);
        });

        test('When matched type is dynamic', () {
          h.run([
            match(wildcard(type: 'num'), expr('dynamic'))
                .checkIR('match(expr(dynamic), wildcardPattern('
                    'matchedType: dynamic))'),
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
