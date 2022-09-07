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
            defaultExpr(body: intLiteral(0)),
          ]).checkIr('switchExpr(expr(int), case(default, 0))').stmt,
        ]);
      });

      test('scrutinee expression context', () {
        h.run([
          switchExpr(expr('int').checkContext('?'), [
            defaultExpr(body: intLiteral(0)),
          ]).inContext('num'),
        ]);
      });

      test('body expression context', () {
        h.run([
          switchExpr(expr('int'), [
            defaultExpr(body: nullLiteral.checkContext('C?')),
          ]).inContext('C?'),
        ]);
      });

      test('least upper bound behavior', () {
        h.run([
          switchExpr(expr('int'), [
            caseExpr(intLiteral(0).pattern, body: expr('int')),
            defaultExpr(body: expr('double')),
          ]).checkType('num').stmt
        ]);
      });

      test('when clause', () {
        var i = Var('i');
        h.run([
          switchExpr(expr('int'), [
            caseExpr(i.pattern(),
                when: i.expr
                    .checkType('int')
                    .eq(expr('num'))
                    .checkContext('bool'),
                body: expr('String')),
          ])
              .checkIr('switchExpr(expr(int), '
                  'case(head(varPattern(i, matchedType: int, '
                  'staticType: int), ==(i, expr(num))), expr(String)))')
              .stmt,
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
                    case_(intLiteral(0).pattern, body: [
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(head(const(0, matchedType: int))), '
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
                      case_(x.pattern(), body: [
                        break_(),
                      ]),
                    ],
                    isExhaustive: false)
                .checkIr('switch(expr(int), '
                    'case(heads(head(varPattern(x, matchedType: int, '
                    'staticType: int))), block(break())))'),
          ]);
        });

        test('typed', () {
          var x = Var('x');
          h.run([
            switch_(
                    expr('int').checkContext('?'),
                    [
                      case_(x.pattern(type: 'num'), body: [
                        break_(),
                      ]),
                    ],
                    isExhaustive: false)
                .checkIr('switch(expr(int), '
                    'case(heads(head(varPattern(x, matchedType: int, '
                    'staticType: num))), block(break())))'),
          ]);
        });
      });

      test('scrutinee expression context', () {
        h.run([
          switch_(
              expr('int').checkContext('?'),
              [
                case_(intLiteral(0).pattern, body: [
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
                    case_(intLiteral(0).pattern, body: []),
                    case_(intLiteral(1).pattern, body: [
                      break_(),
                    ]),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(head(const(0, matchedType: int)), '
                  'head(const(1, matchedType: int))), block(break())))'),
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
                    l.thenCase(case_(intLiteral(0).pattern, body: [])),
                    case_(intLiteral(1).pattern, body: [
                      x.expr.checkType('int?').stmt,
                      break_(),
                    ]),
                    case_(intLiteral(2).pattern, body: [
                      x.expr.checkType('int').stmt,
                      x.write(nullLiteral).stmt,
                      continue_(),
                    ])
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(head(const(0, matchedType: int)), '
                  'head(const(1, matchedType: int)), l), '
                  'block(stmt(x), break())), '
                  'case(heads(head(const(2, matchedType: int))), '
                  'block(stmt(x), stmt(null), continue())))'),
        ]);
      });

      test('empty final case', () {
        h.run([
          switch_(
                  expr('int'),
                  [
                    case_(intLiteral(0).pattern, body: [
                      break_(),
                    ]),
                    case_(intLiteral(1).pattern, body: []),
                  ],
                  isExhaustive: false)
              .checkIr('switch(expr(int), '
                  'case(heads(head(const(0, matchedType: int))), '
                  'block(break())), '
                  'case(heads(head(const(1, matchedType: int))), block()))'),
        ]);
      });

      test('when clause', () {
        var i = Var('i');
        h.run([
          switch_(
                  expr('int'),
                  [
                    case_(i.pattern(),
                        when: i.expr
                            .checkType('int')
                            .eq(expr('num'))
                            .checkContext('bool'),
                        body: [
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
                      case_(x.pattern(), body: []),
                      default_(body: [])..errorId = 'DEFAULT',
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
                      case_(intLiteral(0).pattern, body: [])
                        ..errorId = 'CASE(0)',
                      case_(x.pattern(), body: []),
                    ],
                    isExhaustive: true)
                .expectErrors({'missingMatchVar(CASE(0), x)'}),
          ]);
        });

        test('label', () {
          var x = Var('x');
          var l = Label('l')..errorId = 'LABEL';
          h.run([
            switch_(
                    expr('int'),
                    [
                      l.thenCase(case_(x.pattern(), body: [])),
                    ],
                    isExhaustive: true)
                .expectErrors({'missingMatchVar(LABEL, x)'}),
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
                          body: []),
                      case_(x.pattern(type: 'num')..errorId = 'PATTERN(num x)',
                          body: []),
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
                      case_(x.pattern()..errorId = 'PATTERN(x)', body: []),
                      case_(x.pattern(type: 'int')..errorId = 'PATTERN(int x)',
                          body: []),
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
        // TODO(paulberry): once we support some kind of irrefutable pattern
        // other than a variable declaration, adjust this test so that the only
        // error it expects is `patternDoesNotAllowLate`.
        h.run([
          (match(intLiteral(1).pattern..errorId = 'PATTERN', intLiteral(0),
                  isLate: true)
                ..errorId = 'CONTEXT')
              .expectErrors({
            'patternDoesNotAllowLate(PATTERN)',
            'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'
          }),
        ]);
      });

      test('illegal refutable pattern', () {
        h.run([
          (match(intLiteral(1).pattern..errorId = 'PATTERN', intLiteral(0))
                ..errorId = 'CONTEXT')
              .expectErrors(
                  {'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'}),
        ]);
      });
    });
  });

  group('Patterns:', () {
    group('Const or literal:', () {
      test('Refutability', () {
        h.run([
          (match(intLiteral(1).pattern..errorId = 'PATTERN', intLiteral(0))
                ..errorId = 'CONTEXT')
              .expectErrors(
                  {'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'}),
        ]);
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
                  ..errorId = 'CONTEXT')
                .expectErrors(
                    {'refutablePatternInIrrefutableContext(PATTERN, CONTEXT)'}),
          ]);
        });
      });
    });
  });
}
