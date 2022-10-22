// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:test/test.dart';

import '../mini_ast.dart';
import '../mini_types.dart';
import 'flow_analysis_mini_ast.dart';

main() {
  late FlowAnalysisTestHarness h;

  setUp(() {
    h = FlowAnalysisTestHarness();
  });

  group('API', () {
    test('asExpression_end promotes variables', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
      ]);
    });

    test('asExpression_end handles other expressions', () {
      h.run([
        expr('Object').as_('int').stmt,
      ]);
    });

    test("asExpression_end() sets reachability for Never", () {
      // Note: this is handled by the general mechanism that marks control flow
      // as reachable after any expression with static type `Never`.  This is
      // implemented in the flow analysis client, but we test it here anyway as
      // a validation of the "mini AST" logic.
      h.run([
        checkReachable(true),
        expr('int').as_('Never').stmt,
        checkReachable(false),
      ]);
    });

    test('assert_afterCondition promotes', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        assert_(x.expr.eq(nullLiteral),
            checkPromoted(x, 'int').thenExpr(expr('String'))),
      ]);
    });

    test('assert_end joins previous and ifTrue states', () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        z.expr.as_('int').stmt,
        assert_(block([
          x.write(expr('int?')).stmt,
          z.write(expr('int?')).stmt,
        ]).thenExpr(x.expr.notEq(nullLiteral).and(y.expr.notEq(nullLiteral)))),
        // x should be promoted because it was promoted before the assert, and
        // it is re-promoted within the assert (if it passes)
        checkPromoted(x, 'int'),
        // y should not be promoted because it was not promoted before the
        // assert.
        checkNotPromoted(y),
        // z should not be promoted because it is demoted in the assert
        // condition.
        checkNotPromoted(z),
      ]);
    });

    test('conditional_thenBegin promotes true branch', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr
            .notEq(nullLiteral)
            .conditional(checkPromoted(x, 'int').thenExpr(expr('int')),
                checkNotPromoted(x).thenExpr(expr('int')))
            .stmt,
        checkNotPromoted(x),
      ]);
    });

    test('conditional_elseBegin promotes false branch', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr
            .eq(nullLiteral)
            .conditional(checkNotPromoted(x).thenExpr(expr('Null')),
                checkPromoted(x, 'int').thenExpr(expr('Null')))
            .stmt,
        checkNotPromoted(x),
      ]);
    });

    test('conditional_end keeps promotions common to true and false branches',
        () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        expr('bool')
            .conditional(
                block([
                  x.expr.as_('int').stmt,
                  y.expr.as_('int').stmt,
                ]).thenExpr(expr('Null')),
                block([
                  x.expr.as_('int').stmt,
                  z.expr.as_('int').stmt,
                ]).thenExpr(expr('Null')))
            .stmt,
        checkPromoted(x, 'int'),
        checkNotPromoted(y),
        checkNotPromoted(z),
      ]);
    });

    test('conditional joins true states', () {
      // if (... ? (x != null && y != null) : (x != null && z != null)) {
      //   promotes x, but not y or z
      // }

      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        if_(
            expr('bool').conditional(
                x.expr.notEq(nullLiteral).and(y.expr.notEq(nullLiteral)),
                x.expr.notEq(nullLiteral).and(z.expr.notEq(nullLiteral))),
            [
              checkPromoted(x, 'int'),
              checkNotPromoted(y),
              checkNotPromoted(z),
            ]),
      ]);
    });

    test('conditional joins false states', () {
      // if (... ? (x == null || y == null) : (x == null || z == null)) {
      // } else {
      //   promotes x, but not y or z
      // }

      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        if_(
            expr('bool').conditional(
                x.expr.eq(nullLiteral).or(y.expr.eq(nullLiteral)),
                x.expr.eq(nullLiteral).or(z.expr.eq(nullLiteral))),
            [],
            [
              checkPromoted(x, 'int'),
              checkNotPromoted(y),
              checkNotPromoted(z),
            ]),
      ]);
    });

    test('declare() sets Ssa', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'Object'),
        getSsaNodes((nodes) {
          expect(nodes[x], isNotNull);
        }),
      ]);
    });

    test('equalityOp(x != null) promotes true branch', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(x.expr.notEq(nullLiteral), [
          checkReachable(true),
          checkPromoted(x, 'int'),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ], [
          checkReachable(true),
          checkNotPromoted(x),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ]),
      ]);
    });

    test('equalityOp(x != null) when x is non-nullable', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int', initializer: expr('int')),
        if_(x.expr.notEq(nullLiteral), [
          checkReachable(true),
          checkNotPromoted(x),
        ], [
          checkReachable(true),
          checkNotPromoted(x),
        ])
      ]);
    });

    test('equalityOp(<expr> == <expr>) has no special effect', () {
      h.run([
        if_(expr('int?').eq(expr('int?')), [
          checkReachable(true),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('equalityOp(<expr> != <expr>) has no special effect', () {
      h.run([
        if_(expr('int?').notEq(expr('int?')), [
          checkReachable(true),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('equalityOp(x != <null expr>) does not promote', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.notEq(expr('Null')), [
          checkNotPromoted(x),
        ], [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('equalityOp(x == null) promotes false branch', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(x.expr.eq(nullLiteral), [
          checkReachable(true),
          checkNotPromoted(x),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ], [
          checkReachable(true),
          checkPromoted(x, 'int'),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ]),
      ]);
    });

    test('equalityOp(x == null) when x is non-nullable', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int', initializer: expr('int')),
        if_(x.expr.eq(nullLiteral), [
          checkReachable(true),
          checkNotPromoted(x),
        ], [
          checkReachable(true),
          checkNotPromoted(x),
        ])
      ]);
    });

    test('equalityOp(null != x) promotes true branch', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(nullLiteral.notEq(x.expr), [
          checkPromoted(x, 'int'),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ], [
          checkNotPromoted(x),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ]),
      ]);
    });

    test('equalityOp(<null expr> != x) does not promote', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(expr('Null').notEq(x.expr), [
          checkNotPromoted(x),
        ], [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('equalityOp(null == x) promotes false branch', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(nullLiteral.eq(x.expr), [
          checkNotPromoted(x),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ], [
          checkPromoted(x, 'int'),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ]),
      ]);
    });

    test('equalityOp(null == null) equivalent to true', () {
      h.run([
        if_(expr('Null').eq(expr('Null')), [
          checkReachable(true),
        ], [
          checkReachable(false),
        ]),
      ]);
    });

    test('equalityOp(null != null) equivalent to false', () {
      h.run([
        if_(expr('Null').notEq(expr('Null')), [
          checkReachable(false),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('equalityOp(null == non-null) is not equivalent to false', () {
      h.run([
        if_(expr('Null').eq(expr('int')), [
          checkReachable(true),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('equalityOp(null != non-null) is not equivalent to true', () {
      h.run([
        if_(expr('Null').notEq(expr('int')), [
          checkReachable(true),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('equalityOp(non-null == null) is not equivalent to false', () {
      h.run([
        if_(expr('int').eq(expr('Null')), [
          checkReachable(true),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('equalityOp(non-null != null) is not equivalent to true', () {
      h.run([
        if_(expr('int').notEq(expr('Null')), [
          checkReachable(true),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('conditionEqNull() does not promote write-captured vars', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.notEq(nullLiteral), [
          checkPromoted(x, 'int'),
        ]),
        localFunction([
          x.write(expr('int?')).stmt,
        ]),
        if_(x.expr.notEq(nullLiteral), [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('declare(initialized: false) assigns new SSA ids', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?'),
        declare(y, type: 'int?'),
        getSsaNodes((nodes) => expect(nodes[y], isNot(nodes[x]))),
      ]);
    });

    test('declare(initialized: true) assigns new SSA ids', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => expect(nodes[y], isNot(nodes[x]))),
      ]);
    });

    test('doStatement_bodyBegin() un-promotes', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforeLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeLoop = nodes[x]!),
        do_([
          getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeLoop))),
          checkNotPromoted(x),
          x.write(expr('Null')).stmt,
        ], expr('bool')),
      ]);
    });

    test('doStatement_bodyBegin() handles write captures in the loop', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        do_([
          x.expr.as_('int').stmt,
          // The promotion should have no effect, because the second time
          // through the loop, x has been write-captured.
          checkNotPromoted(x),
          localFunction([
            x.write(expr('int?')).stmt,
          ]),
        ], expr('bool')),
      ]);
    });

    test('doStatement_conditionBegin() joins continue state', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        do_(
            [
              if_(x.expr.notEq(nullLiteral), [
                continue_(),
              ]),
              return_(),
              checkReachable(false),
              checkNotPromoted(x),
            ],
            block([
              checkReachable(true),
              checkPromoted(x, 'int'),
            ]).thenExpr(expr('bool'))),
      ]);
    });

    test('doStatement_end() promotes', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        do_([], checkNotPromoted(x).thenExpr(x.expr.eq(nullLiteral))),
        checkPromoted(x, 'int'),
      ]);
    });

    test('equalityOp_end on property get preserves target variable', () {
      // This is a regression test for a mistake made during the implementation
      // of "why not promoted" functionality: when storing information about an
      // attempt to promote a field (e.g. `x.y != null`) we need to make sure we
      // don't wipe out information about the target variable (`x`).
      h.addMember('C', 'y', 'Object?');
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        checkAssigned(x, true),
        if_(x.expr.property('y').notEq(nullLiteral), [
          checkAssigned(x, true),
        ], [
          checkAssigned(x, true),
        ]),
      ]);
    });

    test('equalityOp_end does not set reachability for `this`', () {
      h.thisType = 'C';
      h.addSubtype('Null', 'C', false);
      h.addFactor('C', 'Null', 'C');
      h.addSubtype('C', 'Object', true);
      h.run([
        if_(this_.is_('Null'), [
          if_(this_.eq(nullLiteral), [
            checkReachable(true),
          ], [
            checkReachable(true),
          ]),
        ]),
      ]);
    });

    group('equalityOp_end does not set reachability for property gets', () {
      test('on a variable', () {
        h.addMember('C', 'f', 'Object?');
        var x = Var('x');
        h.run([
          declare(x, type: 'C', initializer: expr('C')),
          if_(x.expr.property('f').is_('Null'), [
            if_(x.expr.property('f').eq(nullLiteral), [
              checkReachable(true),
            ], [
              checkReachable(true),
            ]),
          ]),
        ]);
      });

      test('on an arbitrary expression', () {
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(expr('C').property('f').is_('Null'), [
            if_(expr('C').property('f').eq(nullLiteral), [
              checkReachable(true),
            ], [
              checkReachable(true),
            ]),
          ]),
        ]);
      });

      test('on explicit this', () {
        h.thisType = 'C';
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(this_.property('f').is_('Null'), [
            if_(this_.property('f').eq(nullLiteral), [
              checkReachable(true),
            ], [
              checkReachable(true),
            ]),
          ]),
        ]);
      });

      test('on implicit this/super', () {
        h.thisType = 'C';
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(thisOrSuperProperty('f').is_('Null'), [
            if_(thisOrSuperProperty('f').eq(nullLiteral), [
              checkReachable(true),
            ], [
              checkReachable(true),
            ]),
          ]),
        ]);
      });
    });

    test('finish checks proper nesting', () {
      var e = expr('Null');
      var s = if_(e, []);
      var flow = FlowAnalysis<Node, Statement, Expression, Var, Type>(
          h.typeOperations, AssignedVariables<Node, Var>(),
          respectImplicitlyTypedVarInitializers: true);
      flow.ifStatement_conditionBegin();
      flow.ifStatement_thenBegin(e, s);
      expect(() => flow.finish(), _asserts);
    });

    test('for_conditionBegin() un-promotes', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforeLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeLoop = nodes[x]!),
        for_(
            null,
            block([
              checkNotPromoted(x),
              getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeLoop))),
            ]).thenExpr(expr('bool')),
            null,
            [
              x.write(expr('int?')).stmt,
            ]),
      ]);
    });

    test('for_conditionBegin() handles write captures in the loop', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        for_(
            null,
            block([
              x.expr.as_('int').stmt,
              checkNotPromoted(x),
              localFunction([
                x.write(expr('int?')).stmt,
              ]),
            ]).thenExpr(expr('bool')),
            null,
            []),
      ]);
    });

    test('for_conditionBegin() handles not-yet-seen variables', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        y.expr.as_('int').stmt,
        for_(
            null,
            declare(x, type: 'int?', initializer: expr('int?'))
                .thenExpr(expr('bool')),
            null,
            [
              x.write(expr('Null')).stmt,
            ]),
      ]);
    });

    test('for_bodyBegin() handles empty condition', () {
      h.run([
        for_(null, null, checkReachable(true).thenExpr(expr('Null')), []),
        checkReachable(false),
      ]);
    });

    test('for_bodyBegin() promotes', () {
      var x = Var('x');
      h.run([
        for_(declare(x, type: 'int?', initializer: expr('int?')),
            x.expr.notEq(nullLiteral), null, [
          checkPromoted(x, 'int'),
        ]),
      ]);
    });

    test('for_bodyBegin() can be used with a null statement', () {
      // This is needed for collection elements that are for-loops.

      var x = Var('x');
      h.run([
        for_(declare(x, type: 'int?', initializer: expr('int?')),
            x.expr.notEq(nullLiteral), null, [],
            forCollection: true),
      ]);
    });

    test('for_updaterBegin() joins current and continue states', () {
      // To test that the states are properly joined, we have three variables:
      // x, y, and z.  We promote x and y in the continue path, and x and z in
      // the current path.  Inside the updater, only x should be promoted.

      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        for_(
            null,
            expr('bool'),
            block([
              checkPromoted(x, 'int'),
              checkNotPromoted(y),
              checkNotPromoted(z),
            ]).thenExpr(expr('Null')),
            [
              if_(expr('bool'), [
                x.expr.as_('int').stmt,
                y.expr.as_('int').stmt,
                continue_(),
              ]),
              x.expr.as_('int').stmt,
              z.expr.as_('int').stmt,
            ]),
      ]);
    });

    test('for_end() joins break and condition-false states', () {
      // To test that the states are properly joined, we have three variables:
      // x, y, and z.  We promote x and y in the break path, and x and z in the
      // condition-false path.  After the loop, only x should be promoted.

      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        for_(null, x.expr.eq(nullLiteral).or(z.expr.eq(nullLiteral)), null, [
          if_(expr('bool'), [
            x.expr.as_('int').stmt,
            y.expr.as_('int').stmt,
            break_(),
          ]),
        ]),
        checkPromoted(x, 'int'),
        checkNotPromoted(y),
        checkNotPromoted(z),
      ]);
    });

    test('for_end() with break updates Ssa of modified vars', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> xSsaInsideLoop;
      late SsaNode<Type> ySsaInsideLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        for_(null, expr('bool'), null, [
          x.write(expr('int?')).stmt,
          if_(expr('bool'), [break_()]),
          getSsaNodes((nodes) {
            xSsaInsideLoop = nodes[x]!;
            ySsaInsideLoop = nodes[y]!;
          }),
        ]),
        getSsaNodes((nodes) {
          // x's Ssa should have been changed because of the join at the end of
          // of the loop.  y's should not, since it retains the value it had
          // prior to the loop.
          expect(nodes[x], isNot(xSsaInsideLoop));
          expect(nodes[y], same(ySsaInsideLoop));
        }),
      ]);
    });

    test(
        'for_end() with break updates Ssa of modified vars when types were '
        'tested', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> xSsaInsideLoop;
      late SsaNode<Type> ySsaInsideLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        for_(null, expr('bool'), null, [
          x.write(expr('int?')).stmt,
          if_(expr('bool'), [break_()]),
          if_(x.expr.is_('int'), []),
          getSsaNodes((nodes) {
            xSsaInsideLoop = nodes[x]!;
            ySsaInsideLoop = nodes[y]!;
          }),
        ]),
        getSsaNodes((nodes) {
          // x's Ssa should have been changed because of the join at the end of
          // the loop.  y's should not, since it retains the value it had prior
          // to the loop.
          expect(nodes[x], isNot(xSsaInsideLoop));
          expect(nodes[y], same(ySsaInsideLoop));
        }),
      ]);
    });

    test('forEach_bodyBegin() un-promotes', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforeLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeLoop = nodes[x]!),
        forEachWithNonVariable(expr('List<int?>'), [
          checkNotPromoted(x),
          getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeLoop))),
          x.write(expr('int?')).stmt,
        ]),
      ]);
    });

    test('forEach_bodyBegin() handles write captures in the loop', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        forEachWithNonVariable(expr('List<int?>'), [
          x.expr.as_('int').stmt,
          checkNotPromoted(x),
          localFunction([
            x.write(expr('int?')).stmt,
          ]),
        ]),
      ]);
    });

    test('forEach_bodyBegin() writes to loop variable', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?'),
        checkAssigned(x, false),
        forEachWithVariableSet(x, expr('List<int?>'), [
          checkAssigned(x, true),
        ]),
        checkAssigned(x, false),
      ]);
    });

    test('forEach_bodyBegin() does not write capture loop variable', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?'),
        checkAssigned(x, false),
        forEachWithVariableSet(x, expr('List<int?>'), [
          checkAssigned(x, true),
          if_(x.expr.notEq(nullLiteral), [checkPromoted(x, 'int')]),
        ]),
        checkAssigned(x, false),
      ]);
    });

    test('forEach_bodyBegin() pushes conservative join state', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int'),
        checkUnassigned(x, true),
        forEachWithNonVariable(expr('List<int>'), [
          // Since a write to x occurs somewhere in the loop, x should no
          // longer be considered unassigned.
          checkUnassigned(x, false),
          break_(), x.write(expr('int')).stmt,
        ]),
        // Even though the write to x is unreachable (since it occurs after a
        // break), x should still be considered "possibly assigned" because of
        // the conservative join done at the top of the loop.
        checkUnassigned(x, false),
      ]);
    });

    test('forEach_end() restores state before loop', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        forEachWithNonVariable(expr('List<int?>'), [
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'),
        ]),
        checkNotPromoted(x),
      ]);
    });

    test('functionExpression_begin() cancels promotions of self-captured vars',
        () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        y.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        checkPromoted(y, 'int'),
        getSsaNodes((nodes) {
          expect(nodes[x], isNotNull);
          expect(nodes[y], isNotNull);
        }),
        localFunction([
          // x is unpromoted within the local function
          checkNotPromoted(x), checkPromoted(y, 'int'),
          getSsaNodes((nodes) {
            expect(nodes[x], isNull);
            expect(nodes[y], isNotNull);
          }),
          x.write(expr('int?')).stmt, x.expr.as_('int').stmt,
        ]),
        // x is unpromoted after the local function too
        checkNotPromoted(x), checkPromoted(y, 'int'),
        getSsaNodes((nodes) {
          expect(nodes[x], isNull);
          expect(nodes[y], isNotNull);
        }),
      ]);
    });

    test('functionExpression_begin() cancels promotions of other-captured vars',
        () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt, y.expr.as_('int').stmt,
        checkPromoted(x, 'int'), checkPromoted(y, 'int'),
        localFunction([
          // x is unpromoted within the local function, because the write
          // might have been captured by the time the local function executes.
          checkNotPromoted(x), checkPromoted(y, 'int'),
          // And any effort to promote x fails, because there is no way of
          // knowing when the captured write might occur.
          x.expr.as_('int').stmt,
          checkNotPromoted(x), checkPromoted(y, 'int'),
        ]),
        // x is still promoted after the local function, though, because the
        // write hasn't been captured yet.
        checkPromoted(x, 'int'), checkPromoted(y, 'int'),
        localFunction([
          // x is unpromoted inside this local function too.
          checkNotPromoted(x), checkPromoted(y, 'int'),
          x.write(expr('int?')).stmt,
        ]),
        // And since the second local function captured x, it remains
        // unpromoted.
        checkNotPromoted(x), checkPromoted(y, 'int'),
      ]);
    });

    test('functionExpression_begin() cancels promotions of written vars', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> ssaBeforeFunction;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt, y.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeFunction = nodes[x]!),
        checkPromoted(y, 'int'),
        localFunction([
          // x is unpromoted within the local function, because the write
          // might have happened by the time the local function executes.
          checkNotPromoted(x),
          getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeFunction))),
          checkPromoted(y, 'int'),
          // But it can be re-promoted because the write isn't captured.
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'), checkPromoted(y, 'int'),
        ]),
        // x is still promoted after the local function, though, because the
        // write hasn't occurred yet.
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforeFunction))),
        checkPromoted(y, 'int'),
        x.write(expr('int?')).stmt,
        // x is unpromoted now.
        checkNotPromoted(x), checkPromoted(y, 'int'),
      ]);
    });

    test('functionExpression_begin() handles not-yet-seen variables', () {
      var x = Var('x');
      h.run([
        localFunction([]),
        // x is declared after the local function, so the local function
        // cannot possibly write to x.
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'), x.write(expr('Null')).stmt,
      ]);
    });

    test('functionExpression_begin() handles not-yet-seen write-captured vars',
        () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        y.expr.as_('int').stmt,
        getSsaNodes((nodes) => expect(nodes[x], isNotNull)),
        localFunction([
          getSsaNodes((nodes) => expect(nodes[x], isNot(nodes[y]))),
          x.expr.as_('int').stmt,
          // Promotion should not occur, because x might be write-captured by
          // the time this code is reached.
          checkNotPromoted(x),
        ]),
        localFunction([
          x.write(expr('Null')).stmt,
        ]),
      ]);
    });

    test(
        'functionExpression_end does not propagate "definitely unassigned" '
        'data', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int'),
        checkUnassigned(x, true),
        localFunction([
          // The function expression could be called at any time, so x might
          // be assigned now.
          checkUnassigned(x, false),
        ]),
        // But now that we are back outside the function expression, we once
        // again know that x is unassigned.
        checkUnassigned(x, true),
        x.write(expr('int')).stmt,
        checkUnassigned(x, false),
      ]);
    });

    test('handleBreak handles deep nesting', () {
      h.run([
        while_(booleanLiteral(true), [
          if_(expr('bool'), [
            if_(expr('bool'), [
              break_(),
            ]),
          ]),
          return_(),
          checkReachable(false),
        ]),
        checkReachable(true),
      ]);
    });

    test('handleBreak handles mixed nesting', () {
      h.run([
        while_(booleanLiteral(true), [
          if_(expr('bool'), [
            if_(expr('bool'), [
              break_(),
            ]),
            break_(),
          ]),
          break_(),
          checkReachable(false),
        ]),
        checkReachable(true),
      ]);
    });

    test('handleContinue handles deep nesting', () {
      h.run([
        do_([
          if_(expr('bool'), [
            if_(expr('bool'), [
              continue_(),
            ]),
          ]),
          return_(),
          checkReachable(false),
        ], checkReachable(true).thenExpr(booleanLiteral(true))),
        checkReachable(false),
      ]);
    });

    test('handleContinue handles mixed nesting', () {
      h.run([
        do_([
          if_(expr('bool'), [
            if_(expr('bool'), [
              continue_(),
            ]),
            continue_(),
          ]),
          continue_(),
          checkReachable(false),
        ], checkReachable(true).thenExpr(booleanLiteral(true))),
        checkReachable(false),
      ]);
    });

    test('ifNullExpression allows ensure guarding', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr
            .ifNull(block([
              checkReachable(true),
              x.write(expr('int')).stmt,
              checkPromoted(x, 'int'),
            ]).thenExpr(expr('int?')))
            .thenStmt(block([
              checkReachable(true),
              checkPromoted(x, 'int'),
            ]))
            .stmt,
      ]);
    });

    test('ifNullExpression allows promotion of tested var', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr
            .ifNull(block([
              checkReachable(true),
              x.expr.as_('int').stmt,
              checkPromoted(x, 'int'),
            ]).thenExpr(expr('int?')))
            .thenStmt(block([
              checkReachable(true),
              checkPromoted(x, 'int'),
            ]))
            .stmt,
      ]);
    });

    test('ifNullExpression discards promotions unrelated to tested expr', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        expr('int?')
            .ifNull(block([
              checkReachable(true),
              x.expr.as_('int').stmt,
              checkPromoted(x, 'int'),
            ]).thenExpr(expr('int?')))
            .thenStmt(block([
              checkReachable(true),
              checkNotPromoted(x),
            ]))
            .stmt,
      ]);
    });

    test('ifNullExpression does not detect when RHS is unreachable', () {
      h.run([
        expr('int')
            .ifNull(checkReachable(true).thenExpr(expr('int')))
            .thenStmt(checkReachable(true))
            .stmt,
      ]);
    });

    test('ifNullExpression determines reachability correctly for `Null` type',
        () {
      h.run([
        expr('Null')
            .ifNull(checkReachable(true).thenExpr(expr('Null')))
            .thenStmt(checkReachable(true))
            .stmt,
      ]);
    });

    test(
        'ifNullExpression sets shortcut reachability correctly for `Null` type',
        () {
      h.run([
        expr('Null')
            .ifNull(checkReachable(true).thenExpr(throw_(expr('Object'))))
            .thenStmt(checkReachable(false))
            .stmt,
      ]);
    });

    test(
        'ifNullExpression sets shortcut reachability correctly for non-null '
        'type', () {
      h.run([
        expr('Object')
            .ifNull(checkReachable(true).thenExpr(throw_(expr('Object'))))
            .thenStmt(checkReachable(true))
            .stmt,
      ]);
    });

    test('ifStatement with early exit promotes in unreachable code', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        return_(),
        checkReachable(false),
        if_(x.expr.eq(nullLiteral), [
          return_(),
        ]),
        checkReachable(false),
        checkPromoted(x, 'int'),
      ]);
    });

    test('ifStatement_end(false) keeps else branch if then branch exits', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(x, 'int'),
      ]);
    });

    test(
        'ifStatement_end() discards non-matching expression info from joined '
        'branches', () {
      var w = Var('w');
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      late SsaNode<Type> xSsaNodeBeforeIf;
      h.run([
        declare(w, type: 'Object', initializer: expr('Object')),
        declare(x, type: 'bool', initializer: expr('bool')),
        declare(y, type: 'bool', initializer: expr('bool')),
        declare(z, type: 'bool', initializer: expr('bool')),
        x.write(w.expr.is_('int')).stmt,
        getSsaNodes((nodes) {
          xSsaNodeBeforeIf = nodes[x]!;
          expect(xSsaNodeBeforeIf.expressionInfo, isNotNull);
        }),
        if_(expr('bool'), [
          y.write(w.expr.is_('String')).stmt,
        ], [
          z.write(w.expr.is_('bool')).stmt,
        ]),
        getSsaNodes((nodes) {
          expect(nodes[x], same(xSsaNodeBeforeIf));
          expect(nodes[y]!.expressionInfo, isNull);
          expect(nodes[z]!.expressionInfo, isNull);
        }),
      ]);
    });

    test(
        'ifStatement_end() ignores non-matching SSA info from "then" path if '
        'unreachable', () {
      var x = Var('x');
      late SsaNode<Type> xSsaNodeBeforeIf;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        getSsaNodes((nodes) {
          xSsaNodeBeforeIf = nodes[x]!;
        }),
        if_(expr('bool'), [
          x.write(expr('Object')).stmt,
          return_(),
        ]),
        getSsaNodes((nodes) {
          expect(nodes[x], same(xSsaNodeBeforeIf));
        }),
      ]);
    });

    test(
        'ifStatement_end() ignores non-matching SSA info from "else" path if '
        'unreachable', () {
      var x = Var('x');
      late SsaNode<Type> xSsaNodeBeforeIf;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        getSsaNodes((nodes) {
          xSsaNodeBeforeIf = nodes[x]!;
        }),
        if_(expr('bool'), [], [
          x.write(expr('Object')).stmt,
          return_(),
        ]),
        getSsaNodes((nodes) {
          expect(nodes[x], same(xSsaNodeBeforeIf));
        }),
      ]);
    });

    test('initialize() promotes when not final', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int')),
        checkPromoted(x, 'int'),
      ]);
    });

    test('initialize() does not promote when final', () {
      var x = Var('x');
      h.run([
        declare(x, isFinal: true, type: 'int?', initializer: expr('int')),
        checkNotPromoted(x),
      ]);
    });

    group('initialize() promotes implicitly typed vars to type parameter types',
        () {
      test('when not final', () {
        h.addSubtype('T&int', 'T', true);
        h.addSubtype('T&int', 'Object', true);
        h.addFactor('T', 'T&int', 'T');
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('T&int')),
          checkPromoted(x, 'T&int'),
        ]);
      });

      test('when final', () {
        h.addSubtype('T&int', 'T', true);
        h.addSubtype('T&int', 'Object', true);
        h.addFactor('T', 'T&int', 'T');
        var x = Var('x');
        h.run([
          declare(x,
              isFinal: true,
              initializer: expr('T&int'),
              expectInferredType: 'T'),
          checkPromoted(x, 'T&int'),
        ]);
      });
    });

    group(
        "initialize() doesn't promote explicitly typed vars to type "
        'parameter types', () {
      test('when not final', () {
        var x = Var('x');
        h.addSubtype('T&int', 'T', true);
        h.run([
          declare(x, type: 'T', initializer: expr('T&int')),
          checkNotPromoted(x),
        ]);
      });

      test('when final', () {
        var x = Var('x');
        h.addSubtype('T&int', 'T', true);
        h.run([
          declare(x, isFinal: true, type: 'T', initializer: expr('T&int')),
          checkNotPromoted(x),
        ]);
      });
    });

    group(
        "initialize() doesn't promote implicitly typed vars to ordinary types",
        () {
      test('when not final', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Null'), expectInferredType: 'dynamic'),
          checkNotPromoted(x),
        ]);
      });

      test('when final', () {
        var x = Var('x');
        h.run([
          declare(x,
              isFinal: true,
              initializer: expr('Null'),
              expectInferredType: 'dynamic'),
          checkNotPromoted(x),
        ]);
      });
    });

    test('initialize() stores expressionInfo when not late', () {
      var x = Var('x');
      var y = Var('y');
      late ExpressionInfo<Type> writtenValueInfo;
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x,
            type: 'Object',
            initializer: y.expr.eq(nullLiteral).getExpressionInfo((info) {
              expect(info, isNotNull);
              writtenValueInfo = info!;
            })),
        getSsaNodes((nodes) {
          expect(nodes[x]!.expressionInfo, same(writtenValueInfo));
        }),
      ]);
    });

    test('initialize() does not store expressionInfo when late', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x,
            isLate: true, type: 'Object', initializer: y.expr.eq(nullLiteral)),
        getSsaNodes((nodes) {
          expect(nodes[x]!.expressionInfo, isNull);
        }),
      ]);
    });

    test(
        'initialize() does not store expressionInfo for implicitly typed '
        'vars, pre-bug fix', () {
      h.respectImplicitlyTypedVarInitializers = false;
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x,
            initializer: y.expr.eq(nullLiteral), expectInferredType: 'bool'),
        getSsaNodes((nodes) {
          expect(nodes[x]!.expressionInfo, isNull);
        }),
      ]);
    });

    test(
        'initialize() stores expressionInfo for implicitly typed '
        'vars, post-bug fix', () {
      h.respectImplicitlyTypedVarInitializers = true;
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x,
            initializer: y.expr.eq(nullLiteral), expectInferredType: 'bool'),
        getSsaNodes((nodes) {
          expect(nodes[x]!.expressionInfo, isNotNull);
        }),
      ]);
    });

    test(
        'initialize() stores expressionInfo for explicitly typed '
        'vars, pre-bug fix', () {
      h.respectImplicitlyTypedVarInitializers = false;
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x, type: 'Object', initializer: y.expr.eq(nullLiteral)),
        getSsaNodes((nodes) {
          expect(nodes[x]!.expressionInfo, isNotNull);
        }),
      ]);
    });

    test('initialize() does not store expressionInfo for trivial expressions',
        () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        localFunction([
          y.write(expr('int?')).stmt,
        ]),
        declare(x,
            type: 'Object',
            // `y == null` is a trivial expression because y has been write
            // captured.
            initializer: y.expr
                .eq(nullLiteral)
                .getExpressionInfo((info) => expect(info, isNotNull))),
        getSsaNodes((nodes) {
          expect(nodes[x]!.expressionInfo, isNull);
        }),
      ]);
    });

    void _checkIs(String declaredType, String tryPromoteType,
        String? expectedPromotedTypeThen, String? expectedPromotedTypeElse,
        {bool inverted = false}) {
      var x = Var('x');
      late SsaNode<Type> ssaBeforePromotion;
      h.run([
        declare(x, type: declaredType, initializer: expr(declaredType)),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(x.expr.is_(tryPromoteType, isInverted: inverted), [
          checkReachable(true),
          checkPromoted(x, expectedPromotedTypeThen),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ], [
          checkReachable(true),
          checkPromoted(x, expectedPromotedTypeElse),
          getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
        ])
      ]);
    }

    test('isExpression_end promotes to a subtype', () {
      _checkIs('int?', 'int', 'int', 'Never?');
    });

    test('isExpression_end promotes to a subtype, inverted', () {
      _checkIs('int?', 'int', 'Never?', 'int', inverted: true);
    });

    test('isExpression_end does not promote to a supertype', () {
      _checkIs('int', 'int?', null, null);
    });

    test('isExpression_end does not promote to a supertype, inverted', () {
      _checkIs('int', 'int?', null, null, inverted: true);
    });

    test('isExpression_end does not promote to an unrelated type', () {
      _checkIs('int', 'String', null, null);
    });

    test('isExpression_end does not promote to an unrelated type, inverted',
        () {
      _checkIs('int', 'String', null, null, inverted: true);
    });

    test('isExpression_end does nothing if applied to a non-variable', () {
      h.run([
        if_(expr('Null').is_('int'), [
          checkReachable(true),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('isExpression_end does nothing if applied to a non-variable, inverted',
        () {
      h.run([
        if_(expr('Null').isNot('int'), [
          checkReachable(true),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('isExpression_end() does not promote write-captured vars', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.is_('int'), [
          checkPromoted(x, 'int'),
        ]),
        localFunction([
          x.write(expr('int?')).stmt,
        ]),
        if_(x.expr.is_('int'), [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('isExpression_end() sets reachability for `this`', () {
      h.thisType = 'C';
      h.addSubtype('Never', 'C', true);
      h.addFactor('C', 'Never', 'C');
      h.run([
        if_(this_.is_('Never'), [
          checkReachable(false),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    group('isExpression_end() sets reachability for property gets', () {
      test('on a variable', () {
        h.addMember('C', 'f', 'Object?');
        var x = Var('x');
        h.run([
          declare(x, type: 'C', initializer: expr('C')),
          if_(x.expr.property('f').is_('Never'), [
            checkReachable(false),
          ], [
            checkReachable(true),
          ]),
        ]);
      });

      test('on an arbitrary expression', () {
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(expr('C').property('f').is_('Never'), [
            checkReachable(false),
          ], [
            checkReachable(true),
          ]),
        ]);
      });

      test('on explicit this', () {
        h.thisType = 'C';
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(this_.property('f').is_('Never'), [
            checkReachable(false),
          ], [
            checkReachable(true),
          ]),
        ]);
      });

      test('on implicit this/super', () {
        h.thisType = 'C';
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(thisOrSuperProperty('f').is_('Never'), [
            checkReachable(false),
          ], [
            checkReachable(true),
          ]),
        ]);
      });
    });

    test('isExpression_end() sets reachability for arbitrary exprs', () {
      h.run([
        if_(expr('int').is_('Never'), [
          checkReachable(false),
        ], [
          checkReachable(true),
        ]),
      ]);
    });

    test('labeledBlock without break', () {
      var x = Var('x');
      var l = Label('l');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.isNot('int'), [
          l.thenStmt(return_()),
        ]),
        checkPromoted(x, 'int'),
      ]);
    });

    test('labeledBlock with break joins', () {
      var x = Var('x');
      var l = Label('l');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.isNot('int'), [
          l.thenStmt(block([
            if_(expr('bool'), [
              break_(l),
            ]),
            return_(),
          ])),
        ]),
        checkNotPromoted(x),
      ]);
    });

    test('logicalBinaryOp_rightBegin(isAnd: true) promotes in RHS', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr
            .notEq(nullLiteral)
            .and(checkPromoted(x, 'int').thenExpr(expr('bool')))
            .stmt,
      ]);
    });

    test('logicalBinaryOp_rightEnd(isAnd: true) keeps promotions from RHS', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(expr('bool').and(x.expr.notEq(nullLiteral)), [
          checkPromoted(x, 'int'),
        ]),
      ]);
    });

    test('logicalBinaryOp_rightEnd(isAnd: false) keeps promotions from RHS',
        () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(expr('bool').or(x.expr.eq(nullLiteral)), [], [
          checkPromoted(x, 'int'),
        ]),
      ]);
    });

    test('logicalBinaryOp_rightBegin(isAnd: false) promotes in RHS', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr
            .eq(nullLiteral)
            .or(checkPromoted(x, 'int').thenExpr(expr('bool')))
            .stmt,
      ]);
    });

    test('logicalBinaryOp(isAnd: true) joins promotions', () {
      // if (x != null && y != null) {
      //   promotes x and y
      // }

      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        if_(x.expr.notEq(nullLiteral).and(y.expr.notEq(nullLiteral)), [
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
        ]),
      ]);
    });

    test('logicalBinaryOp(isAnd: false) joins promotions', () {
      // if (x == null || y == null) {} else {
      //   promotes x and y
      // }

      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        if_(x.expr.eq(nullLiteral).or(y.expr.eq(nullLiteral)), [], [
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
        ]),
      ]);
    });

    test('logicalNot_end() inverts a condition', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.eq(nullLiteral).not, [
          checkPromoted(x, 'int'),
        ], [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('logicalNot_end() handles null literals', () {
      h.run([
        // `!null` would be a compile error, but we need to make sure we don't
        // crash.
        if_(nullLiteral.not, [], []),
      ]);
    });

    test('nonNullAssert_end(x) promotes', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        x.expr.nonNullAssert.stmt,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
      ]);
    });

    test('nonNullAssert_end sets reachability if type is `Null`', () {
      // Note: this is handled by the general mechanism that marks control flow
      // as reachable after any expression with static type `Never`.  This is
      // implemented in the flow analysis client, but we test it here anyway as
      // a validation of the "mini AST" logic.
      h.run([
        expr('Null').nonNullAssert.thenStmt(checkReachable(false)).stmt,
      ]);
    });

    test('nullAwareAccess temporarily promotes', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        x.expr
            .nullAwareAccess(block([
              checkReachable(true),
              checkPromoted(x, 'int'),
              getSsaNodes(
                  (nodes) => expect(nodes[x], same(ssaBeforePromotion))),
            ]).thenExpr(expr('Null')))
            .stmt,
        checkNotPromoted(x),
        getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
      ]);
    });

    test('nullAwareAccess does not promote the target of a cascade', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr
            .nullAwareAccess(
                block([
                  checkReachable(true),
                  checkNotPromoted(x),
                ]).thenExpr(expr('Null')),
                isCascaded: true)
            .stmt,
      ]);
    });

    test('nullAwareAccess preserves demotions', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        expr('int')
            .nullAwareAccess(block([
              checkReachable(true),
              checkPromoted(x, 'int'),
            ]).thenExpr(x.write(expr('int?'))).thenStmt(checkNotPromoted(x)))
            .stmt,
        checkNotPromoted(x),
      ]);
    });

    test('nullAwareAccess sets reachability correctly for `Null` type', () {
      h.run([
        expr('Null')
            .nullAwareAccess(block([
              checkReachable(false),
            ]).thenExpr(expr('Object?')))
            .thenStmt(checkReachable(true))
            .stmt,
      ]);
    });

    test('nullAwareAccess_end ignores shorting if target is non-nullable', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        expr('int')
            .nullAwareAccess(block([
              checkReachable(true),
              x.expr.as_('int').stmt,
              checkPromoted(x, 'int'),
            ]).thenExpr(expr('Null')))
            .stmt,
        // Since the null-shorting path was reachable, promotion of `x` should
        // be cancelled.
        checkNotPromoted(x),
      ]);
    });

    test('parenthesizedExpression preserves promotion behaviors', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(
            x.expr.parenthesized.notEq(nullLiteral.parenthesized).parenthesized,
            [
              checkPromoted(x, 'int'),
            ]),
      ]);
    });

    test('ifCase splits control flow', () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      var w = Var('w');
      h.run([
        declare(x, type: 'int'),
        declare(y, type: 'int'),
        declare(z, type: 'int'),
        ifCase(expr('num'), w.pattern(type: 'int'), [
          x.write(expr('int')).stmt,
          y.write(expr('int')).stmt,
        ], else_: [
          y.write(expr('int')).stmt,
          z.write(expr('int')).stmt,
        ]),
        checkAssigned(x, false),
        checkAssigned(y, true),
        checkAssigned(z, false),
      ]);
    });

    test('ifCase does not promote when expression true', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        ifCase(x.expr.notEq(nullLiteral), intLiteral(0).pattern, [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('promote promotes to a subtype and sets type of interest', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'num?', initializer: expr('num?')),
        checkNotPromoted(x),
        x.expr.as_('num').stmt,
        checkPromoted(x, 'num'),
        // Check that it's a type of interest by promoting and de-promoting.
        if_(x.expr.is_('int'), [
          checkPromoted(x, 'int'),
          x.write(expr('num')).stmt,
          checkPromoted(x, 'num'),
        ]),
      ]);
    });

    test('promote does not promote to a non-subtype', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'num?', initializer: expr('num?')),
        checkNotPromoted(x),
        x.expr.as_('String').stmt,
        checkNotPromoted(x),
      ]);
    });

    test('promote does not promote if variable is write-captured', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'num?', initializer: expr('num?')),
        checkNotPromoted(x),
        localFunction([
          x.write(expr('num')).stmt,
        ]),
        x.expr.as_('num').stmt,
        checkNotPromoted(x),
      ]);
    });

    test('promotedType handles not-yet-seen variables', () {
      // Note: this is needed for error recovery in the analyzer.

      var x = Var('x');
      h.run([
        checkNotPromoted(x),
        declare(x, type: 'int', initializer: expr('int')),
      ]);
    });

    test('switchExpression throw in scrutinee makes all cases unreachable', () {
      h.run([
        switchExpr(throw_(expr('C')), [
          intLiteral(0)
              .pattern
              .thenExpr(checkReachable(false).thenExpr(intLiteral(1))),
          default_.thenExpr(checkReachable(false).thenExpr(intLiteral(2))),
        ]).stmt,
        checkReachable(false),
      ]);
    });

    test('switchExpression throw in case body has isolated effect', () {
      h.run([
        switchExpr(expr('int'), [
          intLiteral(0).pattern.thenExpr(throw_(expr('C'))),
          default_.thenExpr(checkReachable(true).thenExpr(intLiteral(2))),
        ]).stmt,
        checkReachable(true),
      ]);
    });

    test('switchExpression throw in all case bodies affects flow after', () {
      h.run([
        switchExpr(expr('int'), [
          intLiteral(0).pattern.thenExpr(throw_(expr('C'))),
          default_.thenExpr(throw_(expr('C'))),
        ]).stmt,
        checkReachable(false),
      ]);
    });

    test('switchExpression var promotes', () {
      var x = Var('x');
      h.run([
        switchExpr(expr('int'), [
          x
              .pattern(type: 'int?')
              .thenExpr(checkPromoted(x, 'int').thenExpr(nullLiteral)),
        ]).stmt,
      ]);
    });

    test('switchStatement throw in scrutinee makes all cases unreachable', () {
      h.run([
        switch_(
            throw_(expr('C')),
            [
              intLiteral(0).pattern.then([
                checkReachable(false),
              ]),
              intLiteral(1).pattern.then([
                checkReachable(false),
              ]),
            ],
            isExhaustive: false),
        checkReachable(false),
      ]);
    });

    test('switchStatement var promotes', () {
      var x = Var('x');
      h.run([
        switch_(
            expr('int'),
            [
              x.pattern(type: 'int?').then([
                checkPromoted(x, 'int'),
              ]),
            ],
            isExhaustive: true),
      ]);
    });

    test('switchStatement_afterWhen() promotes', () {
      var x = Var('x');
      h.run([
        switch_(
            expr('num'),
            [
              x.pattern().when(x.expr.is_('int')).then([
                checkPromoted(x, 'int'),
              ]),
            ],
            isExhaustive: true),
      ]);
    });

    test('switchStatement_afterWhen() called for switch expressions', () {
      var x = Var('x');
      h.run([
        switchExpr(expr('num'), [
          x
              .pattern()
              .when(x.expr.is_('int'))
              .thenExpr(checkPromoted(x, 'int').thenExpr(expr('String'))),
        ]).stmt,
      ]);
    });

    test('switchStatement_beginCase(false) restores previous promotions', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        switch_(
            expr('int'),
            [
              intLiteral(0).pattern.then([
                checkPromoted(x, 'int'),
                x.write(expr('int?')).stmt,
                checkNotPromoted(x),
              ]),
              intLiteral(1).pattern.then([
                checkPromoted(x, 'int'),
                x.write(expr('int?')).stmt,
                checkNotPromoted(x),
              ]),
            ],
            isExhaustive: false),
      ]);
    });

    test('switchStatement_beginCase(false) does not un-promote', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        switch_(
            expr('int'),
            [
              intLiteral(0).pattern.then([
                checkPromoted(x, 'int'),
                x.write(expr('int?')).stmt,
                checkNotPromoted(x),
              ])
            ],
            isExhaustive: false),
      ]);
    });

    test('switchStatement_beginCase(false) handles write captures in cases',
        () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        switch_(
            expr('int'),
            [
              intLiteral(0).pattern.then([
                checkPromoted(x, 'int'),
                localFunction([
                  x.write(expr('int?')).stmt,
                ]),
                checkNotPromoted(x),
              ]),
            ],
            isExhaustive: false),
      ]);
    });

    test('switchStatement_beginCase(true) un-promotes', () {
      var x = Var('x');
      var l = Label('l');
      late SsaNode<Type> ssaBeforeSwitch;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        switch_(
            expr('int').thenStmt(block([
              checkPromoted(x, 'int'),
              getSsaNodes((nodes) => ssaBeforeSwitch = nodes[x]!),
            ])),
            [
              l.then(intLiteral(0).pattern).then([
                checkNotPromoted(x),
                getSsaNodes(
                    (nodes) => expect(nodes[x], isNot(ssaBeforeSwitch))),
                x.write(expr('int?')).stmt,
                checkNotPromoted(x),
              ]),
            ],
            isExhaustive: false),
      ]);
    });

    test('switchStatement_beginCase(true) handles write captures in cases', () {
      var x = Var('x');
      var l = Label('l');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        switch_(
            expr('int'),
            [
              l.then(intLiteral(0).pattern).then([
                x.expr.as_('int').stmt,
                checkNotPromoted(x),
                localFunction([
                  x.write(expr('int?')).stmt,
                ]),
                checkNotPromoted(x),
              ]),
            ],
            isExhaustive: false),
      ]);
    });

    test('switchStatement_end(false) joins break and default', () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        y.expr.as_('int').stmt,
        z.expr.as_('int').stmt,
        switch_(
            expr('int'),
            [
              intLiteral(0).pattern.then([
                x.expr.as_('int').stmt,
                y.write(expr('int?')).stmt,
                break_(),
              ]),
            ],
            isExhaustive: false),
        checkNotPromoted(x),
        checkNotPromoted(y),
        checkPromoted(z, 'int'),
      ]);
    });

    test('switchStatement_end(true) joins breaks', () {
      var w = Var('w');
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(w, type: 'int?', initializer: expr('int?')),
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        y.expr.as_('int').stmt,
        z.expr.as_('int').stmt,
        switch_(
            expr('int'),
            [
              intLiteral(0).pattern.then([
                w.expr.as_('int').stmt,
                y.expr.as_('int').stmt,
                x.write(expr('int?')).stmt,
                break_(),
              ]),
              default_.then([
                w.expr.as_('int').stmt,
                x.expr.as_('int').stmt,
                y.write(expr('int?')).stmt,
                break_(),
              ]),
            ],
            isExhaustive: true),
        checkPromoted(w, 'int'),
        checkNotPromoted(x),
        checkNotPromoted(y),
        checkPromoted(z, 'int'),
      ]);
    });

    test('switchStatement_end(true) allows fall-through of last case', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        switch_(
            expr('int'),
            [
              intLiteral(0).pattern.then([
                x.expr.as_('int').stmt,
                break_(),
              ]),
              default_.then([]),
            ],
            isExhaustive: true),
        checkNotPromoted(x),
      ]);
    });

    test('switchStatement_endAlternative() joins branches', () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(y, type: 'num'),
        declare(z, type: 'num'),
        switch_(
            expr('num'),
            [
              x
                  .pattern()
                  .when(x.expr.is_('int').and(y.expr.is_('int')))
                  .then([]),
              x.pattern().when(y.expr.is_('int').and(z.expr.is_('int'))).then([
                checkNotPromoted(x),
                checkPromoted(y, 'int'),
                checkNotPromoted(z),
              ]),
            ],
            isExhaustive: true),
      ]);
    });

    test('tryCatchStatement_bodyEnd() restores pre-try state', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        y.expr.as_('int').stmt,
        try_([
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
        ]).catch_(body: [
          checkNotPromoted(x),
          checkPromoted(y, 'int'),
        ]),
      ]);
    });

    test('tryCatchStatement_bodyEnd() un-promotes variables assigned in body',
        () {
      var x = Var('x');
      late SsaNode<Type> ssaAfterTry;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        try_([
          x.write(expr('int?')).stmt,
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'),
          getSsaNodes((nodes) => ssaAfterTry = nodes[x]!),
        ]).catch_(body: [
          checkNotPromoted(x),
          getSsaNodes((nodes) => expect(nodes[x], isNot(ssaAfterTry))),
        ]),
      ]);
    });

    test('tryCatchStatement_bodyEnd() preserves write captures in body', () {
      // Note: it's not necessary for the write capture to survive to the end of
      // the try body, because an exception could occur at any time.  We check
      // this by putting an exit in the try body.

      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        try_([
          localFunction([
            x.write(expr('int?')).stmt,
          ]),
          return_(),
        ]).catch_(body: [
          x.expr.as_('int').stmt,
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('tryCatchStatement_catchBegin() restores previous post-body state',
        () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        try_([]).catch_(body: [
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'),
        ]).catch_(body: [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('tryCatchStatement_catchBegin() initializes vars', () {
      var e = Var('e');
      var st = Var('st');
      h.run([
        try_([]).catch_(exception: e, stackTrace: st, body: [
          checkAssigned(e, true),
          checkAssigned(st, true),
        ]),
      ]);
    });

    test('tryCatchStatement_catchEnd() joins catch state with after-try state',
        () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        try_([
          x.expr.as_('int').stmt,
          y.expr.as_('int').stmt,
        ]).catch_(body: [
          x.expr.as_('int').stmt,
          z.expr.as_('int').stmt,
        ]),
        // Only x should be promoted, because it's the only variable
        // promoted in both the try body and the catch handler.
        checkPromoted(x, 'int'), checkNotPromoted(y), checkNotPromoted(z),
      ]);
    });

    test('tryCatchStatement_catchEnd() joins catch states', () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        try_([
          return_(),
        ]).catch_(body: [
          x.expr.as_('int').stmt,
          y.expr.as_('int').stmt,
        ]).catch_(body: [
          x.expr.as_('int').stmt,
          z.expr.as_('int').stmt,
        ]),
        // Only x should be promoted, because it's the only variable promoted
        // in both catch handlers.
        checkPromoted(x, 'int'), checkNotPromoted(y), checkNotPromoted(z),
      ]);
    });

    test('tryFinallyStatement_finallyBegin() restores pre-try state', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        y.expr.as_('int').stmt,
        try_([
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
        ]).finally_([
          checkNotPromoted(x),
          checkPromoted(y, 'int'),
        ]),
      ]);
    });

    test(
        'tryFinallyStatement_finallyBegin() un-promotes variables assigned in '
        'body', () {
      var x = Var('x');
      late SsaNode<Type> ssaAtStartOfTry;
      late SsaNode<Type> ssaAfterTry;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        try_([
          getSsaNodes((nodes) => ssaAtStartOfTry = nodes[x]!),
          x.write(expr('int?')).stmt,
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'),
          getSsaNodes((nodes) => ssaAfterTry = nodes[x]!),
        ]).finally_([
          checkNotPromoted(x),
          // The SSA node for X should be different from what it was at any time
          // during the try block, because there is no telling at what point an
          // exception might have occurred.
          getSsaNodes((nodes) {
            expect(nodes[x], isNot(ssaAtStartOfTry));
            expect(nodes[x], isNot(ssaAfterTry));
          }),
        ]),
      ]);
    });

    test('tryFinallyStatement_finallyBegin() preserves write captures in body',
        () {
      // Note: it's not necessary for the write capture to survive to the end of
      // the try body, because an exception could occur at any time.  We check
      // this by putting an exit in the try body.

      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        try_([
          localFunction([
            x.write(expr('int?')).stmt,
          ]),
          return_(),
        ]).finally_([
          x.expr.as_('int').stmt,
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('tryFinallyStatement_end() restores promotions from try body', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        try_([
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'),
        ]).finally_([
          checkNotPromoted(x),
          y.expr.as_('int').stmt,
          checkPromoted(y, 'int'),
        ]),
        // Both x and y should now be promoted.
        checkPromoted(x, 'int'), checkPromoted(y, 'int'),
      ]);
    });

    test(
        'tryFinallyStatement_end() does not restore try body promotions for '
        'variables assigned in finally', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> xSsaAtEndOfFinally;
      late SsaNode<Type> ySsaAtEndOfFinally;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        try_([
          x.expr.as_('int').stmt,
          checkPromoted(x, 'int'),
        ]).finally_([
          checkNotPromoted(x),
          x.write(expr('int?')).stmt,
          y.write(expr('int?')).stmt,
          y.expr.as_('int').stmt,
          checkPromoted(y, 'int'),
          getSsaNodes((nodes) {
            xSsaAtEndOfFinally = nodes[x]!;
            ySsaAtEndOfFinally = nodes[y]!;
          }),
        ]),
        // x should not be re-promoted, because it might have been assigned a
        // non-promoted value in the "finally" block.  But y's promotion still
        // stands, because y was promoted in the finally block.
        checkNotPromoted(x), checkPromoted(y, 'int'),
        // Both x and y should have the same SSA nodes they had at the end of
        // the finally block, since the finally block is guaranteed to have
        // executed.
        getSsaNodes((nodes) {
          expect(nodes[x], same(xSsaAtEndOfFinally));
          expect(nodes[y], same(ySsaAtEndOfFinally));
        }),
      ]);
    });

    group('allowLocalBooleanVarsToPromote', () {
      test(
          'tryFinallyStatement_end() restores SSA nodes from try block when it'
          'is sound to do so', () {
        var x = Var('x');
        var y = Var('y');
        late SsaNode<Type> xSsaAtEndOfTry;
        late SsaNode<Type> ySsaAtEndOfTry;
        late SsaNode<Type> xSsaAtEndOfFinally;
        late SsaNode<Type> ySsaAtEndOfFinally;
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?')),
          try_([
            x.write(expr('int?')).stmt,
            y.write(expr('int?')).stmt,
            getSsaNodes((nodes) {
              xSsaAtEndOfTry = nodes[x]!;
              ySsaAtEndOfTry = nodes[y]!;
            }),
          ]).finally_([
            if_(expr('bool'), [
              x.write(expr('int?')).stmt,
            ]),
            if_(expr('bool'), [
              y.write(expr('int?')).stmt,
              return_(),
            ]),
            getSsaNodes((nodes) {
              xSsaAtEndOfFinally = nodes[x]!;
              ySsaAtEndOfFinally = nodes[y]!;
              expect(xSsaAtEndOfFinally, isNot(same(xSsaAtEndOfTry)));
              expect(ySsaAtEndOfFinally, isNot(same(ySsaAtEndOfTry)));
            }),
          ]),
          // x's SSA node should still match what it was at the end of the
          // finally block, because it might have been written to.  But y
          // can't have been written to, because once we reach here, we know
          // that the finally block completed normally, and the write to y
          // always leads to the explicit return.  So y's SSA node should be
          // restored back to match that from the end of the try block.
          getSsaNodes((nodes) {
            expect(nodes[x], same(xSsaAtEndOfFinally));
            expect(nodes[y], same(ySsaAtEndOfTry));
          }),
        ]);
      });

      test(
          'tryFinallyStatement_end() sets unreachable if end of try block '
          'unreachable', () {
        h.run([
          try_([
            return_(),
            checkReachable(false),
          ]).finally_([
            checkReachable(true),
          ]),
          checkReachable(false),
        ]);
      });

      test(
          'tryFinallyStatement_end() sets unreachable if end of finally block '
          'unreachable', () {
        h.run([
          try_([
            checkReachable(true),
          ]).finally_([
            return_(),
            checkReachable(false),
          ]),
          checkReachable(false),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles a variable declared only in the '
          'try block', () {
        var x = Var('x');
        h.run([
          try_([
            declare(x, type: 'int?', initializer: expr('int?')),
          ]).finally_([]),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles a variable declared only in the '
          'finally block', () {
        var x = Var('x');
        h.run([
          try_([]).finally_([
            declare(x, type: 'int?', initializer: expr('int?')),
          ]),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles a variable that was write '
          'captured in the try block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          try_([
            localFunction([
              x.write(expr('int?')).stmt,
            ]),
          ]).finally_([]),
          if_(x.expr.notEq(nullLiteral), [
            checkNotPromoted(x),
          ]),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles a variable that was write '
          'captured in the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          try_([]).finally_([
            localFunction([
              x.write(expr('int?')).stmt,
            ]),
          ]),
          if_(x.expr.notEq(nullLiteral), [
            checkNotPromoted(x),
          ]),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles a variable that was promoted in '
          'the try block and write captured in the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          try_([
            if_(x.expr.eq(nullLiteral), [
              return_(),
            ]),
            checkPromoted(x, 'int'),
          ]).finally_([
            localFunction([
              x.write(expr('int?')).stmt,
            ]),
          ]),
          // The capture in the `finally` cancels old promotions and prevents
          // future promotions.
          checkNotPromoted(x),
          if_(x.expr.notEq(nullLiteral), [
            checkNotPromoted(x),
          ]),
        ]);
      });

      test(
          'tryFinallyStatement_end() keeps promotions from both try and '
          'finally blocks when there is no write in the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object', initializer: expr('Object')),
          try_([
            if_(x.expr.is_('num', isInverted: true), [
              return_(),
            ]),
            checkPromoted(x, 'num'),
          ]).finally_([
            if_(x.expr.is_('int', isInverted: true), [
              return_(),
            ]),
          ]),
          // The promotion chain now contains both `num` and `int`.
          checkPromoted(x, 'int'),
          x.write(expr('num')).stmt,
          checkPromoted(x, 'num'),
        ]);
      });

      test(
          'tryFinallyStatement_end() keeps promotions from the finally block '
          'when there is a write in the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object', initializer: expr('Object')),
          try_([
            if_(x.expr.is_('String', isInverted: true), [
              return_(),
            ]),
            checkPromoted(x, 'String'),
          ]).finally_([
            x.write(expr('Object')).stmt,
            if_(x.expr.is_('int', isInverted: true), [
              return_(),
            ]),
          ]),
          checkPromoted(x, 'int'),
        ]);
      });

      test(
          'tryFinallyStatement_end() keeps tests from both the try and finally '
          'blocks', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object', initializer: expr('Object')),
          try_([
            if_(x.expr.is_('String', isInverted: true), []),
            checkNotPromoted(x),
          ]).finally_([
            if_(x.expr.is_('int', isInverted: true), []),
            checkNotPromoted(x),
          ]),
          checkNotPromoted(x),
          if_(expr('bool'), [
            x.write(expr('String')).stmt,
            checkPromoted(x, 'String'),
          ], [
            x.write(expr('int')).stmt,
            checkPromoted(x, 'int'),
          ]),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles variables not definitely assigned '
          'in either the try or finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkAssigned(x, false),
          try_([
            if_(expr('bool'), [
              x.write(expr('Object')).stmt,
            ]),
            checkAssigned(x, false),
          ]).finally_([
            if_(expr('bool'), [
              x.write(expr('Object')).stmt,
            ]),
            checkAssigned(x, false),
          ]),
          checkAssigned(x, false),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles variables definitely assigned in '
          'the try block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkAssigned(x, false),
          try_([
            x.write(expr('Object')).stmt,
            checkAssigned(x, true),
          ]).finally_([
            if_(expr('bool'), [
              x.write(expr('Object')).stmt,
            ]),
            checkAssigned(x, false),
          ]),
          checkAssigned(x, true),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles variables definitely assigned in '
          'the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkAssigned(x, false),
          try_([
            if_(expr('bool'), [
              x.write(expr('Object')).stmt,
            ]),
            checkAssigned(x, false),
          ]).finally_([
            x.write(expr('Object')).stmt,
            checkAssigned(x, true),
          ]),
          checkAssigned(x, true),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles variables definitely unassigned '
          'in both the try and finally blocks', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkUnassigned(x, true),
          try_([
            checkUnassigned(x, true),
          ]).finally_([
            checkUnassigned(x, true),
          ]),
          checkUnassigned(x, true),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles variables definitely unassigned '
          'in the try but not the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkUnassigned(x, true),
          try_([
            checkUnassigned(x, true),
          ]).finally_([
            if_(expr('bool'), [
              x.write(expr('Object')).stmt,
            ]),
            checkUnassigned(x, false),
          ]),
          checkUnassigned(x, false),
        ]);
      });

      test(
          'tryFinallyStatement_end() handles variables definitely unassigned '
          'in the finally but not the try block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkUnassigned(x, true),
          try_([
            if_(expr('bool'), [
              x.write(expr('Object')).stmt,
            ]),
            checkUnassigned(x, false),
          ]).finally_([
            checkUnassigned(x, false),
          ]),
          checkUnassigned(x, false),
        ]);
      });
    });

    test('variableRead() restores promotions from previous write()', () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'bool', initializer: expr('bool')),
        // Create a variable that promotes x if its value is true, and y if its
        // value is false.
        z
            .write(x.expr.notEq(nullLiteral).conditional(
                booleanLiteral(true),
                y.expr.notEq(nullLiteral).conditional(
                    booleanLiteral(false), throw_(expr('Object')))))
            .stmt,
        checkNotPromoted(x),
        checkNotPromoted(y),
        // Simply reading the variable shouldn't promote anything.
        z.expr.stmt,
        checkNotPromoted(x),
        checkNotPromoted(y),
        // But reading it in an "if" condition should promote.
        if_(z.expr, [
          checkPromoted(x, 'int'),
          checkNotPromoted(y),
        ], [
          checkNotPromoted(x),
          checkPromoted(y, 'int'),
        ]),
      ]);
    });

    test('variableRead() restores promotions from previous initialization', () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        // Create a variable that promotes x if its value is true, and y if its
        // value is false.
        declare(z,
            initializer: x.expr.notEq(nullLiteral).conditional(
                booleanLiteral(true),
                y.expr.notEq(nullLiteral).conditional(
                    booleanLiteral(false), throw_(expr('Object'))))),
        checkNotPromoted(x),
        checkNotPromoted(y),
        // Simply reading the variable shouldn't promote anything.
        z.expr.stmt,
        checkNotPromoted(x),
        checkNotPromoted(y),
        // But reading it in an "if" condition should promote.
        if_(z.expr, [
          checkPromoted(x, 'int'),
          checkNotPromoted(y),
        ], [
          checkNotPromoted(x),
          checkPromoted(y, 'int'),
        ]),
      ]);
    });

    test('variableRead() rebases old promotions', () {
      var w = Var('w');
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(w, type: 'int?', initializer: expr('int?')),
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'bool', initializer: expr('bool')),
        // Create a variable that promotes x if its value is true, and y if its
        // value is false.
        z
            .write(x.expr.notEq(nullLiteral).conditional(
                booleanLiteral(true),
                y.expr.notEq(nullLiteral).conditional(
                    booleanLiteral(false), throw_(expr('Object')))))
            .stmt,
        checkNotPromoted(w),
        checkNotPromoted(x),
        checkNotPromoted(y),
        w.expr.nonNullAssert.stmt,
        checkPromoted(w, 'int'),
        // Reading the value of z in an "if" condition should promote x or y,
        // and keep the promotion of w.
        if_(z.expr, [
          checkPromoted(w, 'int'),
          checkPromoted(x, 'int'),
          checkNotPromoted(y),
        ], [
          checkPromoted(w, 'int'),
          checkNotPromoted(x),
          checkPromoted(y, 'int'),
        ]),
      ]);
    });

    test("variableRead() doesn't restore the notion of whether a value is null",
        () {
      // Note: we have the available infrastructure to do this if we want, but
      // we think it will give an inconsistent feel because comparisons like
      // `if (i == null)` *don't* promote.

      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        y.write(nullLiteral).stmt,
        checkNotPromoted(x),
        checkNotPromoted(y),
        if_(x.expr.eq(y.expr), [
          checkNotPromoted(x),
          checkNotPromoted(y),
        ], [
          // Even though x != y and y is known to contain the value `null`, we
          // don't promote x.
          checkNotPromoted(x),
          checkNotPromoted(y),
        ]),
      ]);
    });

    test('whileStatement_conditionBegin() un-promotes', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforeLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeLoop = nodes[x]!),
        while_(
            block([
              checkNotPromoted(x),
              getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeLoop))),
            ]).thenExpr(expr('bool')),
            [
              x.write(expr('Null')).stmt,
            ]),
      ]);
    });

    test('whileStatement_conditionBegin() handles write captures in the loop',
        () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        while_(
            block([
              x.expr.as_('int').stmt,
              checkNotPromoted(x),
              localFunction([
                x.write(expr('int?')).stmt,
              ]),
            ]).thenExpr(expr('bool')),
            []),
      ]);
    });

    test('whileStatement_conditionBegin() handles not-yet-seen variables', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        y.expr.as_('int').stmt,
        while_(
            declare(x, type: 'int?', initializer: expr('int?'))
                .thenExpr(expr('bool')),
            [
              x.write(expr('Null')).stmt,
            ]),
      ]);
    });

    test('whileStatement_bodyBegin() promotes', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        while_(x.expr.notEq(nullLiteral), [
          checkPromoted(x, 'int'),
        ]),
      ]);
    });

    test('whileStatement_end() joins break and condition-false states', () {
      // To test that the states are properly joined, we have three variables:
      // x, y, and z.  We promote x and y in the break path, and x and z in the
      // condition-false path.  After the loop, only x should be promoted.

      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        while_(x.expr.eq(nullLiteral).or(z.expr.eq(nullLiteral)), [
          if_(expr('bool'), [
            x.expr.as_('int').stmt,
            y.expr.as_('int').stmt,
            break_(),
          ]),
        ]),
        checkPromoted(x, 'int'),
        checkNotPromoted(y),
        checkNotPromoted(z),
      ]);
    });

    test('whileStatement_end() with break updates Ssa of modified vars', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> xSsaInsideLoop;
      late SsaNode<Type> ySsaInsideLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        while_(expr('bool'), [
          x.write(expr('int?')).stmt,
          if_(expr('bool'), [break_()]),
          getSsaNodes((nodes) {
            xSsaInsideLoop = nodes[x]!;
            ySsaInsideLoop = nodes[y]!;
          }),
        ]),
        getSsaNodes((nodes) {
          // x's Ssa should have been changed because of the join at the end of
          // the loop.  y's should not, since it retains the value it had prior
          // to the loop.
          expect(nodes[x], isNot(xSsaInsideLoop));
          expect(nodes[y], same(ySsaInsideLoop));
        }),
      ]);
    });

    test(
        'whileStatement_end() with break updates Ssa of modified vars when '
        'types were tested', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> xSsaInsideLoop;
      late SsaNode<Type> ySsaInsideLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        while_(expr('bool'), [
          x.write(expr('int?')).stmt,
          if_(expr('bool'), [break_()]),
          if_(x.expr.is_('int'), []),
          getSsaNodes((nodes) {
            xSsaInsideLoop = nodes[x]!;
            ySsaInsideLoop = nodes[y]!;
          }),
        ]),
        getSsaNodes((nodes) {
          // x's Ssa should have been changed because of the join at the end of
          // the loop.  y's should not, since it retains the value it had prior
          // to the loop.
          expect(nodes[x], isNot(xSsaInsideLoop));
          expect(nodes[y], same(ySsaInsideLoop));
        }),
      ]);
    });

    test('write() de-promotes and updates Ssa of a promoted variable', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> ssaBeforeWrite;
      late ExpressionInfo<Type> writtenValueInfo;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        declare(y, type: 'int?', initializer: expr('int?')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeWrite = nodes[x]!),
        x
            .write(y.expr.eq(nullLiteral).getExpressionInfo((info) {
              expect(info, isNotNull);
              writtenValueInfo = info!;
            }))
            .stmt,
        checkNotPromoted(x),
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(ssaBeforeWrite));
          expect(nodes[x]!.expressionInfo, same(writtenValueInfo));
        }),
      ]);
    });

    test('write() updates Ssa', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> ssaBeforeWrite;
      late ExpressionInfo<Type> writtenValueInfo;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        declare(y, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforeWrite = nodes[x]!),
        x
            .write(y.expr.eq(nullLiteral).getExpressionInfo((info) {
              expect(info, isNotNull);
              writtenValueInfo = info!;
            }))
            .stmt,
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(ssaBeforeWrite));
          expect(nodes[x]!.expressionInfo, same(writtenValueInfo));
        }),
      ]);
    });

    test('write() does not copy Ssa from one variable to another', () {
      // We could do so, and it would enable us to promote in slightly more
      // situations, e.g.:
      //   bool b = x != null;
      //   if (b) { /* x promoted here */ }
      //   var tmp = x;
      //   x = ...;
      //   if (b) { /* x not promoted here */ }
      //   x = tmp;
      //   if (b) { /* x promoted again */ }
      // But there are a lot of corner cases to test and it's not clear how much
      // the benefit will be, so for now we're not doing it.

      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> xSsaBeforeWrite;
      late SsaNode<Type> ySsa;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) {
          xSsaBeforeWrite = nodes[x]!;
          ySsa = nodes[y]!;
        }),
        x.write(y.expr).stmt,
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(xSsaBeforeWrite));
          expect(nodes[x], isNot(ySsa));
        }),
      ]);
    });

    test('write() does not store expressionInfo for trivial expressions', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<Type> ssaBeforeWrite;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        declare(y, type: 'int?', initializer: expr('int?')),
        localFunction([
          y.write(expr('int?')).stmt,
        ]),
        getSsaNodes((nodes) => ssaBeforeWrite = nodes[x]!),
        // `y == null` is a trivial expression because y has been write
        // captured.
        x
            .write(y.expr
                .eq(nullLiteral)
                .getExpressionInfo((info) => expect(info, isNotNull)))
            .stmt,
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(ssaBeforeWrite));
          expect(nodes[x]!.expressionInfo, isNull);
        }),
      ]);
    });

    test('write() permits expression to be null', () {
      var x = Var('x');
      late SsaNode<Type> ssaBeforeWrite;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        getSsaNodes((nodes) => ssaBeforeWrite = nodes[x]!),
        x.write(null).stmt,
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(ssaBeforeWrite));
          expect(nodes[x]!.expressionInfo, isNull);
        }),
      ]);
    });

    test('Infinite loop does not implicitly assign variables', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int'),
        while_(booleanLiteral(true), [
          x.write(expr('Null')).stmt,
        ]),
        checkAssigned(x, false),
      ]);
    });

    test('If(false) does not discard promotions', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        x.expr.as_('int').stmt,
        checkPromoted(x, 'int'),
        if_(booleanLiteral(false), [
          checkPromoted(x, 'int'),
        ]),
      ]);
    });

    test('Promotions do not occur when a variable is write-captured', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        localFunction([
          x.write(expr('Object')).stmt,
        ]),
        getSsaNodes((nodes) => expect(nodes[x], isNull)),
        x.expr.as_('int').stmt,
        checkNotPromoted(x),
        getSsaNodes((nodes) => expect(nodes[x], isNull)),
      ]);
    });

    test('Promotion cancellation of write-captured vars survives join', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        if_(expr('bool'), [
          localFunction([
            x.write(expr('Object')).stmt,
          ]),
        ], [
          // Promotion should work here because the write capture is in the
          // other branch.
          x.expr.as_('int').stmt, checkPromoted(x, 'int'),
        ]),
        // But the promotion should be cancelled now, after the join.
        checkNotPromoted(x),
        // And further attempts to promote should fail due to the write capture.
        x.expr.as_('int').stmt, checkNotPromoted(x),
      ]);
    });

    test('issue 47991', () {
      var b = Var('b');
      var i = Var('i');
      h.run([
        localFunction([
          declare(b, type: 'bool', initializer: expr('bool').or(expr('bool'))),
          declare(i, isFinal: true, type: 'int'),
          if_(b.expr, [
            checkUnassigned(i, true),
            i.write(expr('int')).stmt,
          ], [
            checkUnassigned(i, true),
            i.write(expr('int')).stmt,
          ]),
        ]),
      ]);
    });
  });

  group('Reachability', () {
    test('initial state', () {
      expect(Reachability.initial.parent, isNull);
      expect(Reachability.initial.locallyReachable, true);
      expect(Reachability.initial.overallReachable, true);
    });

    test('split', () {
      var reachableSplit = Reachability.initial.split();
      expect(reachableSplit.parent, same(Reachability.initial));
      expect(reachableSplit.overallReachable, true);
      expect(reachableSplit.locallyReachable, true);
      var unreachable = reachableSplit.setUnreachable();
      var unreachableSplit = unreachable.split();
      expect(unreachableSplit.parent, same(unreachable));
      expect(unreachableSplit.overallReachable, false);
      expect(unreachableSplit.locallyReachable, true);
    });

    test('unsplit', () {
      var base = Reachability.initial.split();
      var reachableSplit = base.split();
      var reachableSplitUnsplit = reachableSplit.unsplit();
      expect(reachableSplitUnsplit.parent, same(base.parent));
      expect(reachableSplitUnsplit.overallReachable, true);
      expect(reachableSplitUnsplit.locallyReachable, true);
      var reachableSplitUnreachable = reachableSplit.setUnreachable();
      var reachableSplitUnreachableUnsplit =
          reachableSplitUnreachable.unsplit();
      expect(reachableSplitUnreachableUnsplit.parent, same(base.parent));
      expect(reachableSplitUnreachableUnsplit.overallReachable, false);
      expect(reachableSplitUnreachableUnsplit.locallyReachable, false);
      var unreachable = base.setUnreachable();
      var unreachableSplit = unreachable.split();
      var unreachableSplitUnsplit = unreachableSplit.unsplit();
      expect(unreachableSplitUnsplit, same(unreachable));
      var unreachableSplitUnreachable = unreachableSplit.setUnreachable();
      var unreachableSplitUnreachableUnsplit =
          unreachableSplitUnreachable.unsplit();
      expect(unreachableSplitUnreachableUnsplit, same(unreachable));
    });

    test('setUnreachable', () {
      var reachable = Reachability.initial.split();
      var unreachable = reachable.setUnreachable();
      expect(unreachable.parent, same(reachable.parent));
      expect(unreachable.locallyReachable, false);
      expect(unreachable.overallReachable, false);
      expect(unreachable.setUnreachable(), same(unreachable));
      var provisionallyReachable = unreachable.split();
      var provisionallyUnreachable = provisionallyReachable.setUnreachable();
      expect(
          provisionallyUnreachable.parent, same(provisionallyReachable.parent));
      expect(provisionallyUnreachable.locallyReachable, false);
      expect(provisionallyUnreachable.overallReachable, false);
      expect(provisionallyUnreachable.setUnreachable(),
          same(provisionallyUnreachable));
    });

    test('restrict', () {
      var previous = Reachability.initial.split();
      var reachable = previous.split();
      var unreachable = reachable.setUnreachable();
      expect(Reachability.restrict(reachable, reachable), same(reachable));
      expect(Reachability.restrict(reachable, unreachable), same(unreachable));
      expect(Reachability.restrict(unreachable, reachable), same(unreachable));
      expect(
          Reachability.restrict(unreachable, unreachable), same(unreachable));
    });

    test('rebaseForward', () {
      var previous = Reachability.initial;
      var reachable = previous.split();
      var reachable2 = previous.split();
      var unreachable = reachable.setUnreachable();
      var unreachablePrevious = previous.setUnreachable();
      var reachable3 = unreachablePrevious.split();
      expect(reachable.rebaseForward(reachable), same(reachable));
      expect(reachable.rebaseForward(reachable2), same(reachable2));
      expect(reachable.rebaseForward(unreachable), same(unreachable));
      expect(unreachable.rebaseForward(reachable).parent, same(previous));
      expect(unreachable.rebaseForward(reachable).locallyReachable, false);
      expect(unreachable.rebaseForward(unreachable), same(unreachable));
      expect(reachable.rebaseForward(unreachablePrevious),
          same(unreachablePrevious));
      expect(
          unreachablePrevious.rebaseForward(reachable).parent, same(previous));
      expect(
          unreachablePrevious.rebaseForward(reachable).locallyReachable, false);
      expect(reachable.rebaseForward(reachable3), same(reachable3));
      expect(reachable3.rebaseForward(reachable).parent, same(previous));
      expect(reachable3.rebaseForward(reachable).locallyReachable, false);
    });

    test('join', () {
      var previous = Reachability.initial.split();
      var reachable = previous.split();
      var unreachable = reachable.setUnreachable();
      expect(Reachability.join(reachable, reachable), same(reachable));
      expect(Reachability.join(reachable, unreachable), same(reachable));
      expect(Reachability.join(unreachable, reachable), same(reachable));
      expect(Reachability.join(unreachable, unreachable), same(unreachable));
    });

    test('commonAncestor', () {
      var parent1 = Reachability.initial;
      var parent2 = parent1.setUnreachable();
      var child1 = parent1.split();
      var child2 = parent1.split();
      var child3 = child1.split();
      var child4 = child2.split();
      expect(Reachability.commonAncestor(null, null), null);
      expect(Reachability.commonAncestor(null, parent1), null);
      expect(Reachability.commonAncestor(parent1, null), null);
      expect(Reachability.commonAncestor(null, child1), null);
      expect(Reachability.commonAncestor(child1, null), null);
      expect(Reachability.commonAncestor(null, child3), null);
      expect(Reachability.commonAncestor(child3, null), null);
      expect(Reachability.commonAncestor(parent1, parent1), same(parent1));
      expect(Reachability.commonAncestor(parent1, parent2), null);
      expect(Reachability.commonAncestor(parent2, child1), null);
      expect(Reachability.commonAncestor(child1, parent2), null);
      expect(Reachability.commonAncestor(parent2, child3), null);
      expect(Reachability.commonAncestor(child3, parent2), null);
      expect(Reachability.commonAncestor(parent1, child1), same(parent1));
      expect(Reachability.commonAncestor(child1, parent1), same(parent1));
      expect(Reachability.commonAncestor(parent1, child3), same(parent1));
      expect(Reachability.commonAncestor(child3, parent1), same(parent1));
      expect(Reachability.commonAncestor(child1, child1), same(child1));
      expect(Reachability.commonAncestor(child1, child2), same(parent1));
      expect(Reachability.commonAncestor(child1, child3), same(child1));
      expect(Reachability.commonAncestor(child3, child1), same(child1));
      expect(Reachability.commonAncestor(child1, child4), same(parent1));
      expect(Reachability.commonAncestor(child4, child1), same(parent1));
      expect(Reachability.commonAncestor(child3, child3), same(child3));
      expect(Reachability.commonAncestor(child3, child4), same(parent1));
    });
  });

  group('State', () {
    var intVar = Var('x')..type = Type('int');
    var intQVar = Var('x')..type = Type('int?');
    var objectQVar = Var('x')..type = Type('Object?');
    var nullVar = Var('x')..type = Type('Null');

    group('setUnreachable', () {
      var unreachable = FlowModel<Type>(Reachability.initial.setUnreachable());
      var reachable = FlowModel<Type>(Reachability.initial);
      test('unchanged', () {
        expect(unreachable.setUnreachable(), same(unreachable));
      });

      test('changed', () {
        void _check(FlowModel<Type> initial) {
          var s = initial.setUnreachable();
          expect(s, isNot(same(initial)));
          expect(s.reachable.overallReachable, false);
          expect(s.variableInfo, same(initial.variableInfo));
        }

        _check(reachable);
      });
    });

    test('split', () {
      var s1 = FlowModel<Type>(Reachability.initial);
      var s2 = s1.split();
      expect(s2.reachable.parent, same(s1.reachable));
    });

    test('unsplit', () {
      var s1 = FlowModel<Type>(Reachability.initial.split());
      var s2 = s1.unsplit();
      expect(s2.reachable, same(Reachability.initial));
    });

    group('unsplitTo', () {
      test('no change', () {
        var s1 = FlowModel<Type>(Reachability.initial.split());
        var result = s1.unsplitTo(s1.reachable.parent!);
        expect(result, same(s1));
      });

      test('unsplit once, reachable', () {
        var s1 = FlowModel<Type>(Reachability.initial.split());
        var s2 = s1.split();
        var result = s2.unsplitTo(s1.reachable.parent!);
        expect(result.reachable, same(s1.reachable));
      });

      test('unsplit once, unreachable', () {
        var s1 = FlowModel<Type>(Reachability.initial.split());
        var s2 = s1.split().setUnreachable();
        var result = s2.unsplitTo(s1.reachable.parent!);
        expect(result.reachable.locallyReachable, false);
        expect(result.reachable.parent, same(s1.reachable.parent));
      });

      test('unsplit twice, reachable', () {
        var s1 = FlowModel<Type>(Reachability.initial.split());
        var s2 = s1.split();
        var s3 = s2.split();
        var result = s3.unsplitTo(s1.reachable.parent!);
        expect(result.reachable, same(s1.reachable));
      });

      test('unsplit twice, top unreachable', () {
        var s1 = FlowModel<Type>(Reachability.initial.split());
        var s2 = s1.split();
        var s3 = s2.split().setUnreachable();
        var result = s3.unsplitTo(s1.reachable.parent!);
        expect(result.reachable.locallyReachable, false);
        expect(result.reachable.parent, same(s1.reachable.parent));
      });

      test('unsplit twice, previous unreachable', () {
        var s1 = FlowModel<Type>(Reachability.initial.split());
        var s2 = s1.split().setUnreachable();
        var s3 = s2.split();
        var result = s3.unsplitTo(s1.reachable.parent!);
        expect(result.reachable.locallyReachable, false);
        expect(result.reachable.parent, same(s1.reachable.parent));
      });
    });

    group('tryPromoteForTypeCheck', () {
      test('unpromoted -> unchanged (same)', () {
        var s1 = FlowModel<Type>(Reachability.initial);
        var s2 = s1._tryPromoteForTypeCheck(h, intVar, 'int').ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (supertype)', () {
        var s1 = FlowModel<Type>(Reachability.initial);
        var s2 = s1._tryPromoteForTypeCheck(h, intVar, 'Object').ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (unrelated)', () {
        var s1 = FlowModel<Type>(Reachability.initial);
        var s2 = s1._tryPromoteForTypeCheck(h, intVar, 'String').ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> subtype', () {
        var s1 = FlowModel<Type>(Reachability.initial);
        var s2 = s1._tryPromoteForTypeCheck(h, intQVar, 'int').ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(intQVar):
              _matchVariableModel(chain: ['int'], ofInterest: ['int'])
        });
      });

      test('promoted -> unchanged (same)', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        var s2 = s1._tryPromoteForTypeCheck(h, objectQVar, 'int').ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (supertype)', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        var s2 = s1._tryPromoteForTypeCheck(h, objectQVar, 'Object').ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (unrelated)', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        var s2 = s1._tryPromoteForTypeCheck(h, objectQVar, 'String').ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> subtype', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int?')
            .ifTrue;
        var s2 = s1._tryPromoteForTypeCheck(h, objectQVar, 'int').ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['int?', 'int'], ofInterest: ['int?', 'int'])
        });
      });
    });

    group('write', () {
      var objectQVar = Var('x')..type = Type('Object?');

      test('without declaration', () {
        // This should not happen in valid code, but test that we don't crash.

        var s = FlowModel<Type>(Reachability.initial)._write(
            h, null, objectQVar, Type('Object?'), new SsaNode<Type>(null));
        expect(s.variableInfo[objectQVar], isNull);
      });

      test('unchanged', () {
        var s1 =
            FlowModel<Type>(Reachability.initial)._declare(h, objectQVar, true);
        var s2 = s1._write(
            h, null, objectQVar, Type('Object?'), new SsaNode<Type>(null));
        expect(s2, isNot(same(s1)));
        expect(s2.reachable, same(s1.reachable));
        expect(
            s2._infoFor(h, objectQVar),
            _matchVariableModel(
                chain: null,
                ofInterest: isEmpty,
                assigned: true,
                unassigned: false));
      });

      test('marks as assigned', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, false);
        var s2 = s1._write(
            h, null, objectQVar, Type('int?'), new SsaNode<Type>(null));
        expect(s2.reachable.overallReachable, true);
        expect(
            s2._infoFor(h, objectQVar),
            _matchVariableModel(
                chain: null,
                ofInterest: isEmpty,
                assigned: true,
                unassigned: false));
      });

      test('un-promotes fully', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        expect(s1.variableInfo,
            contains(h.promotionKeyStore.keyForVariable(objectQVar)));
        var s2 = s1._write(h, _MockNonPromotionReason(), objectQVar,
            Type('int?'), new SsaNode<Type>(null));
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: null,
              ofInterest: isEmpty,
              assigned: true,
              unassigned: false)
        });
      });

      test('un-promotes partially, when no exact match', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        expect(s1.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?', 'int'],
              ofInterest: ['num?', 'int'],
              assigned: true,
              unassigned: false)
        });
        var s2 = s1._write(h, _MockNonPromotionReason(), objectQVar,
            Type('num'), new SsaNode<Type>(null));
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'int'],
              assigned: true,
              unassigned: false)
        });
      });

      test('un-promotes partially, when exact match', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'num')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        expect(s1.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?', 'num', 'int'],
              ofInterest: ['num?', 'num', 'int'],
              assigned: true,
              unassigned: false)
        });
        var s2 = s1._write(h, _MockNonPromotionReason(), objectQVar,
            Type('num'), new SsaNode<Type>(null));
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'num', 'int'],
              assigned: true,
              unassigned: false)
        });
      });

      test('leaves promoted, when exact match', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'num')
            .ifTrue;
        expect(s1.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'num'],
              assigned: true,
              unassigned: false)
        });
        var s2 = s1._write(
            h, null, objectQVar, Type('num'), new SsaNode<Type>(null));
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, isNot(same(s1.variableInfo)));
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'num'],
              assigned: true,
              unassigned: false)
        });
      });

      test('leaves promoted, when writing a subtype', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'num')
            .ifTrue;
        expect(s1.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'num'],
              assigned: true,
              unassigned: false)
        });
        var s2 = s1._write(
            h, null, objectQVar, Type('int'), new SsaNode<Type>(null));
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, isNot(same(s1.variableInfo)));
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'num'],
              assigned: true,
              unassigned: false)
        });
      });

      group('Promotes to NonNull of a type of interest', () {
        test('when declared type', () {
          var x = Var('x')..type = Type('int?');

          var s1 = FlowModel<Type>(Reachability.initial)._declare(h, x, true);
          expect(s1.variableInfo, {
            h.promotionKeyStore.keyForVariable(x):
                _matchVariableModel(chain: null),
          });

          var s2 = s1._write(h, null, x, Type('int'), new SsaNode<Type>(null));
          expect(s2.variableInfo, {
            h.promotionKeyStore.keyForVariable(x):
                _matchVariableModel(chain: ['int']),
          });
        });

        test('when declared type, if write-captured', () {
          var x = Var('x')..type = Type('int?');

          var s1 = FlowModel<Type>(Reachability.initial)._declare(h, x, true);
          expect(s1.variableInfo, {
            h.promotionKeyStore.keyForVariable(x):
                _matchVariableModel(chain: null),
          });

          var s2 = s1._conservativeJoin(h, [], [x]);
          expect(s2.variableInfo, {
            h.promotionKeyStore.keyForVariable(x):
                _matchVariableModel(chain: null, writeCaptured: true),
          });

          // 'x' is write-captured, so not promoted
          var s3 = s2._write(h, null, x, Type('int'), new SsaNode<Type>(null));
          expect(s3.variableInfo, {
            h.promotionKeyStore.keyForVariable(x):
                _matchVariableModel(chain: null, writeCaptured: true),
          });
        });

        test('when promoted', () {
          var s1 = FlowModel<Type>(Reachability.initial)
              ._declare(h, objectQVar, true)
              ._tryPromoteForTypeCheck(h, objectQVar, 'int?')
              .ifTrue;
          expect(s1.variableInfo, {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['int?'],
              ofInterest: ['int?'],
            ),
          });
          var s2 = s1._write(
              h, null, objectQVar, Type('int'), new SsaNode<Type>(null));
          expect(s2.variableInfo, {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['int?', 'int'],
              ofInterest: ['int?'],
            ),
          });
        });

        test('when not promoted', () {
          var s1 = FlowModel<Type>(Reachability.initial)
              ._declare(h, objectQVar, true)
              ._tryPromoteForTypeCheck(h, objectQVar, 'int?')
              .ifFalse;
          expect(s1.variableInfo, {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['Object'],
              ofInterest: ['int?'],
            ),
          });
          var s2 = s1._write(
              h, null, objectQVar, Type('int'), new SsaNode<Type>(null));
          expect(s2.variableInfo, {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['Object', 'int'],
              ofInterest: ['int?'],
            ),
          });
        });
      });

      test('Promotes to type of interest when not previously promoted', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifFalse;
        expect(s1.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['Object'],
            ofInterest: ['num?'],
          ),
        });
        var s2 = s1._write(h, _MockNonPromotionReason(), objectQVar,
            Type('num?'), new SsaNode<Type>(null));
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?'],
            ofInterest: ['num?'],
          ),
        });
      });

      test('Promotes to type of interest when previously promoted', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'int?')
            .ifFalse;
        expect(s1.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'int?'],
          ),
        });
        var s2 = s1._write(h, _MockNonPromotionReason(), objectQVar,
            Type('int?'), new SsaNode<Type>(null));
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'int?'],
            ofInterest: ['num?', 'int?'],
          ),
        });
      });

      group('Multiple candidate types of interest', () {
        group('; choose most specific', () {
          setUp(() {
            // class A {}
            // class B extends A {}
            // class C extends B {}
            h.addSubtype('Object', 'A', false);
            h.addSubtype('Object', 'A?', false);
            h.addSubtype('Object', 'B?', false);
            h.addSubtype('A', 'Object', true);
            h.addSubtype('A', 'Object?', true);
            h.addSubtype('A', 'A?', true);
            h.addSubtype('A', 'B', false);
            h.addSubtype('A', 'B?', false);
            h.addSubtype('A?', 'Object', false);
            h.addSubtype('A?', 'Object?', true);
            h.addSubtype('A?', 'A', false);
            h.addSubtype('A?', 'B?', false);
            h.addSubtype('B', 'Object', true);
            h.addSubtype('B', 'A', true);
            h.addSubtype('B', 'A?', true);
            h.addSubtype('B', 'B?', true);
            h.addSubtype('B?', 'Object', false);
            h.addSubtype('B?', 'Object?', true);
            h.addSubtype('B?', 'A', false);
            h.addSubtype('B?', 'A?', true);
            h.addSubtype('B?', 'B', false);
            h.addSubtype('C', 'Object', true);
            h.addSubtype('C', 'A', true);
            h.addSubtype('C', 'A?', true);
            h.addSubtype('C', 'B', true);
            h.addSubtype('C', 'B?', true);

            h.addFactor('Object', 'A?', 'Object');
            h.addFactor('Object', 'B?', 'Object');
            h.addFactor('Object?', 'A', 'Object?');
            h.addFactor('Object?', 'A?', 'Object');
            h.addFactor('Object?', 'B?', 'Object');
          });

          test('; first', () {
            var x = Var('x')..type = Type('Object?');

            var s1 = FlowModel<Type>(Reachability.initial)
                ._declare(h, x, true)
                ._tryPromoteForTypeCheck(h, x, 'B?')
                .ifFalse
                ._tryPromoteForTypeCheck(h, x, 'A?')
                .ifFalse;
            expect(s1.variableInfo, {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A?', 'B?'],
              ),
            });

            var s2 = s1._write(h, null, x, Type('C'), new SsaNode<Type>(null));
            expect(s2.variableInfo, {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object', 'B'],
                ofInterest: ['A?', 'B?'],
              ),
            });
          });

          test('; second', () {
            var x = Var('x')..type = Type('Object?');

            var s1 = FlowModel<Type>(Reachability.initial)
                ._declare(h, x, true)
                ._tryPromoteForTypeCheck(h, x, 'A?')
                .ifFalse
                ._tryPromoteForTypeCheck(h, x, 'B?')
                .ifFalse;
            expect(s1.variableInfo, {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A?', 'B?'],
              ),
            });

            var s2 = s1._write(h, null, x, Type('C'), new SsaNode<Type>(null));
            expect(s2.variableInfo, {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object', 'B'],
                ofInterest: ['A?', 'B?'],
              ),
            });
          });

          test('; nullable and non-nullable', () {
            var x = Var('x')..type = Type('Object?');

            var s1 = FlowModel<Type>(Reachability.initial)
                ._declare(h, x, true)
                ._tryPromoteForTypeCheck(h, x, 'A')
                .ifFalse
                ._tryPromoteForTypeCheck(h, x, 'A?')
                .ifFalse;
            expect(s1.variableInfo, {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A', 'A?'],
              ),
            });

            var s2 = s1._write(h, null, x, Type('B'), new SsaNode<Type>(null));
            expect(s2.variableInfo, {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object', 'A'],
                ofInterest: ['A', 'A?'],
              ),
            });
          });
        });

        group('; ambiguous', () {
          test('; no promotion', () {
            var s1 = FlowModel<Type>(Reachability.initial)
                ._declare(h, objectQVar, true)
                ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
                .ifFalse
                ._tryPromoteForTypeCheck(h, objectQVar, 'num*')
                .ifFalse;
            expect(s1.variableInfo, {
              h.promotionKeyStore.keyForVariable(objectQVar):
                  _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['num?', 'num*'],
              ),
            });
            var s2 = s1._write(
                h, null, objectQVar, Type('int'), new SsaNode<Type>(null));
            // It's ambiguous whether to promote to num? or num*, so we don't
            // promote.
            expect(s2, isNot(same(s1)));
            expect(s2.variableInfo, {
              h.promotionKeyStore.keyForVariable(objectQVar):
                  _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['num?', 'num*'],
              ),
            });
          });
        });

        test('exact match', () {
          var s1 = FlowModel<Type>(Reachability.initial)
              ._declare(h, objectQVar, true)
              ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
              .ifFalse
              ._tryPromoteForTypeCheck(h, objectQVar, 'num*')
              .ifFalse;
          expect(s1.variableInfo, {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['Object'],
              ofInterest: ['num?', 'num*'],
            ),
          });
          var s2 = s1._write(h, _MockNonPromotionReason(), objectQVar,
              Type('num?'), new SsaNode<Type>(null));
          // It's ambiguous whether to promote to num? or num*, but since the
          // written type is exactly num?, we use that.
          expect(s2.variableInfo, {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['num?'],
              ofInterest: ['num?', 'num*'],
            ),
          });
        });
      });
    });

    group('demotion, to NonNull', () {
      test('when promoted via test', () {
        var x = Var('x')..type = Type('Object?');

        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, x, true)
            ._tryPromoteForTypeCheck(h, x, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, x, 'int?')
            .ifTrue;
        expect(s1.variableInfo, {
          h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
            chain: ['num?', 'int?'],
            ofInterest: ['num?', 'int?'],
          ),
        });

        var s2 = s1._write(h, _MockNonPromotionReason(), x, Type('double'),
            new SsaNode<Type>(null));
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'int?'],
          ),
        });
      });
    });

    group('declare', () {
      var objectQVar = Var('x')..type = Type('Object?');

      test('initialized', () {
        var s =
            FlowModel<Type>(Reachability.initial)._declare(h, objectQVar, true);
        expect(s.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar):
              _matchVariableModel(assigned: true, unassigned: false),
        });
      });

      test('not initialized', () {
        var s = FlowModel<Type>(Reachability.initial)
            ._declare(h, objectQVar, false);
        expect(s.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar):
              _matchVariableModel(assigned: false, unassigned: true),
        });
      });
    });

    group('markNonNullable', () {
      test('unpromoted -> unchanged', () {
        var s1 = FlowModel<Type>(Reachability.initial);
        var s2 = s1._tryMarkNonNullable(h, intVar).ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> promoted', () {
        var s1 = FlowModel<Type>(Reachability.initial);
        var s2 = s1._tryMarkNonNullable(h, intQVar).ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(s2._infoFor(h, intQVar),
            _matchVariableModel(chain: ['int'], ofInterest: []));
      });

      test('promoted -> unchanged', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        var s2 = s1._tryMarkNonNullable(h, objectQVar).ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> re-promoted', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int?')
            .ifTrue;
        var s2 = s1._tryMarkNonNullable(h, objectQVar).ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar):
              _matchVariableModel(chain: ['int?', 'int'], ofInterest: ['int?'])
        });
      });

      test('promote to Never', () {
        var s1 = FlowModel<Type>(Reachability.initial);
        var s2 = s1._tryMarkNonNullable(h, nullVar).ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(s2._infoFor(h, nullVar),
            _matchVariableModel(chain: ['Never'], ofInterest: []));
      });
    });

    group('conservativeJoin', () {
      test('unchanged', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._declare(h, intQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        var s2 = s1._conservativeJoin(h, [intQVar], []);
        expect(s2, isNot(same(s1)));
        expect(s2.reachable, same(s1.reachable));
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar):
              _matchVariableModel(chain: ['int'], ofInterest: ['int']),
          h.promotionKeyStore.keyForVariable(intQVar):
              _matchVariableModel(chain: null, ofInterest: [])
        });
      });

      test('written', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue
            ._tryPromoteForTypeCheck(h, intQVar, 'int')
            .ifTrue;
        var s2 = s1._conservativeJoin(h, [intQVar], []);
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar):
              _matchVariableModel(chain: ['int'], ofInterest: ['int']),
          h.promotionKeyStore.keyForVariable(intQVar):
              _matchVariableModel(chain: null, ofInterest: ['int'])
        });
      });

      test('write captured', () {
        var s1 = FlowModel<Type>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue
            ._tryPromoteForTypeCheck(h, intQVar, 'int')
            .ifTrue;
        var s2 = s1._conservativeJoin(h, [], [intQVar]);
        expect(s2.reachable.overallReachable, true);
        expect(s2.variableInfo, {
          h.promotionKeyStore.keyForVariable(objectQVar):
              _matchVariableModel(chain: ['int'], ofInterest: ['int']),
          h.promotionKeyStore.keyForVariable(intQVar): _matchVariableModel(
              chain: null, ofInterest: isEmpty, unassigned: false)
        });
      });
    });

    group('rebaseForward', () {
      test('reachability', () {
        var reachable = FlowModel<Type>(Reachability.initial);
        var unreachable = reachable.setUnreachable();
        expect(reachable.rebaseForward(h.typeOperations, reachable),
            same(reachable));
        expect(reachable.rebaseForward(h.typeOperations, unreachable),
            same(unreachable));
        expect(
            unreachable
                .rebaseForward(h.typeOperations, reachable)
                .reachable
                .overallReachable,
            false);
        expect(
            unreachable.rebaseForward(h.typeOperations, reachable).variableInfo,
            same(unreachable.variableInfo));
        expect(unreachable.rebaseForward(h.typeOperations, unreachable),
            same(unreachable));
      });

      test('assignments', () {
        var a = Var('a')..type = Type('int');
        var b = Var('b')..type = Type('int');
        var c = Var('c')..type = Type('int');
        var d = Var('d')..type = Type('int');
        var s0 = FlowModel<Type>(Reachability.initial)
            ._declare(h, a, false)
            ._declare(h, b, false)
            ._declare(h, c, false)
            ._declare(h, d, false);
        var s1 = s0
            ._write(h, null, a, Type('int'), new SsaNode<Type>(null))
            ._write(h, null, b, Type('int'), new SsaNode<Type>(null));
        var s2 = s0
            ._write(h, null, a, Type('int'), new SsaNode<Type>(null))
            ._write(h, null, c, Type('int'), new SsaNode<Type>(null));
        var result = s1.rebaseForward(h.typeOperations, s2);
        expect(result._infoFor(h, a).assigned, true);
        expect(result._infoFor(h, b).assigned, true);
        expect(result._infoFor(h, c).assigned, true);
        expect(result._infoFor(h, d).assigned, false);
      });

      test('write captured', () {
        var a = Var('a')..type = Type('int');
        var b = Var('b')..type = Type('int');
        var c = Var('c')..type = Type('int');
        var d = Var('d')..type = Type('int');
        var s0 = FlowModel<Type>(Reachability.initial)
            ._declare(h, a, false)
            ._declare(h, b, false)
            ._declare(h, c, false)
            ._declare(h, d, false);
        // In s1, a and b are write captured.  In s2, a and c are.
        var s1 = s0._conservativeJoin(h, [a, b], [a, b]);
        var s2 = s1._conservativeJoin(h, [a, c], [a, c]);
        var result = s1.rebaseForward(h.typeOperations, s2);
        expect(
          result._infoFor(h, a),
          _matchVariableModel(writeCaptured: true, unassigned: false),
        );
        expect(
          result._infoFor(h, b),
          _matchVariableModel(writeCaptured: true, unassigned: false),
        );
        expect(
          result._infoFor(h, c),
          _matchVariableModel(writeCaptured: true, unassigned: false),
        );
        expect(
          result._infoFor(h, d),
          _matchVariableModel(writeCaptured: false, unassigned: true),
        );
      });

      test('write captured and promoted', () {
        var a = Var('a')..type = Type('num');
        var s0 = FlowModel<Type>(Reachability.initial)._declare(h, a, false);
        // In s1, a is write captured.  In s2 it's promoted.
        var s1 = s0._conservativeJoin(h, [a], [a]);
        var s2 = s0._tryPromoteForTypeCheck(h, a, 'int').ifTrue;
        expect(
          s1.rebaseForward(h.typeOperations, s2)._infoFor(h, a),
          _matchVariableModel(writeCaptured: true, chain: isNull),
        );
        expect(
          s2.rebaseForward(h.typeOperations, s1)._infoFor(h, a),
          _matchVariableModel(writeCaptured: true, chain: isNull),
        );
      });

      test('promotion', () {
        void _check(String? thisType, String? otherType, bool unsafe,
            List<String>? expectedChain) {
          var x = Var('x')..type = Type('Object?');
          var s0 = FlowModel<Type>(Reachability.initial)._declare(h, x, true);
          var s1 = s0;
          if (unsafe) {
            s1 =
                s1._write(h, null, x, Type('Object?'), new SsaNode<Type>(null));
          }
          if (thisType != null) {
            s1 = s1._tryPromoteForTypeCheck(h, x, thisType).ifTrue;
          }
          var s2 = otherType == null
              ? s0
              : s0._tryPromoteForTypeCheck(h, x, otherType).ifTrue;
          var result = s2.rebaseForward(h.typeOperations, s1);
          if (expectedChain == null) {
            expect(result.variableInfo,
                contains(h.promotionKeyStore.keyForVariable(x)));
            expect(result._infoFor(h, x).promotedTypes, isNull);
          } else {
            expect(
                result
                    ._infoFor(h, x)
                    .promotedTypes!
                    .map((t) => t.type)
                    .toList(),
                expectedChain);
          }
        }

        _check(null, null, false, null);
        _check(null, null, true, null);
        _check('int', null, false, ['int']);
        _check('int', null, true, ['int']);
        _check(null, 'int', false, ['int']);
        _check(null, 'int', true, null);
        _check('int?', 'int', false, ['int?', 'int']);
        _check('int', 'int?', false, ['int']);
        _check('int', 'String', false, ['int']);
        _check('int?', 'int', true, ['int?']);
        _check('int', 'int?', true, ['int']);
        _check('int', 'String', true, ['int']);
      });

      test('promotion chains', () {
        // Verify that the given promotion chain matches the expected list of
        // strings.
        void _checkChain(List<Type>? chain, List<String> expected) {
          var strings = (chain ?? <Type>[]).map((t) => t.type).toList();
          expect(strings, expected);
        }

        // Test the following scenario:
        // - Prior to the try/finally block, the sequence of promotions in
        //   [before] is done.
        // - During the try block, the sequence of promotions in [inTry] is
        //   done.
        // - During the finally block, the sequence of promotions in
        //   [inFinally] is done.
        // - After calling `restrict` to refine the state from the finally
        //   block, the expected promotion chain is [expectedResult].
        void _check(List<String> before, List<String> inTry,
            List<String> inFinally, List<String> expectedResult) {
          var x = Var('x')..type = Type('Object?');
          var initialModel =
              FlowModel<Type>(Reachability.initial)._declare(h, x, true);
          for (var t in before) {
            initialModel = initialModel._tryPromoteForTypeCheck(h, x, t).ifTrue;
          }
          _checkChain(initialModel._infoFor(h, x).promotedTypes, before);
          var tryModel = initialModel;
          for (var t in inTry) {
            tryModel = tryModel._tryPromoteForTypeCheck(h, x, t).ifTrue;
          }
          var expectedTryChain = before.toList()..addAll(inTry);
          _checkChain(tryModel._infoFor(h, x).promotedTypes, expectedTryChain);
          var finallyModel = initialModel;
          for (var t in inFinally) {
            finallyModel = finallyModel._tryPromoteForTypeCheck(h, x, t).ifTrue;
          }
          var expectedFinallyChain = before.toList()..addAll(inFinally);
          _checkChain(
              finallyModel._infoFor(h, x).promotedTypes, expectedFinallyChain);
          var result = tryModel.rebaseForward(h.typeOperations, finallyModel);
          _checkChain(result._infoFor(h, x).promotedTypes, expectedResult);
          // And verify that the inputs are unchanged.
          _checkChain(initialModel._infoFor(h, x).promotedTypes, before);
          _checkChain(tryModel._infoFor(h, x).promotedTypes, expectedTryChain);
          _checkChain(
              finallyModel._infoFor(h, x).promotedTypes, expectedFinallyChain);
        }

        _check(['Object'], ['num', 'int'], ['Iterable', 'List'],
            ['Object', 'Iterable', 'List']);
        _check([], ['num', 'int'], ['Iterable', 'List'], ['Iterable', 'List']);
        _check(['Object'], [], ['Iterable', 'List'],
            ['Object', 'Iterable', 'List']);
        _check([], [], ['Iterable', 'List'], ['Iterable', 'List']);
        _check(['Object'], ['num', 'int'], [], ['Object', 'num', 'int']);
        _check([], ['num', 'int'], [], ['num', 'int']);
        _check(['Object'], [], [], ['Object']);
        _check([], [], [], []);
        _check(
            [], ['num', 'int'], ['Object', 'Iterable'], ['Object', 'Iterable']);
        _check([], ['num', 'int'], ['Object'], ['Object', 'num', 'int']);
        _check([], ['Object', 'Iterable'], ['num', 'int'], ['num', 'int']);
        _check([], ['Object'], ['num', 'int'], ['num', 'int']);
        _check([], ['num'], ['Object', 'int'], ['Object', 'int']);
        _check([], ['int'], ['Object', 'num'], ['Object', 'num', 'int']);
        _check([], ['Object', 'int'], ['num'], ['num', 'int']);
        _check([], ['Object', 'num'], ['int'], ['int']);
      });

      test('types of interest', () {
        var a = Var('a')..type = Type('Object');
        var s0 = FlowModel<Type>(Reachability.initial)._declare(h, a, false);
        var s1 = s0._tryPromoteForTypeCheck(h, a, 'int').ifFalse;
        var s2 = s0._tryPromoteForTypeCheck(h, a, 'String').ifFalse;
        expect(
          s1.rebaseForward(h.typeOperations, s2)._infoFor(h, a),
          _matchVariableModel(ofInterest: ['int', 'String']),
        );
        expect(
          s2.rebaseForward(h.typeOperations, s1)._infoFor(h, a),
          _matchVariableModel(ofInterest: ['int', 'String']),
        );
      });

      test('variable present in one state but not the other', () {
        var x = Var('x')..type = Type('Object?');
        var s0 = FlowModel<Type>(Reachability.initial);
        var s1 = s0._declare(h, x, true);
        expect(s1.rebaseForward(h.typeOperations, s0), same(s0));
        expect(s0.rebaseForward(h.typeOperations, s1), same(s1));
      });
    });
  });

  group('joinPromotionChains', () {
    var doubleType = Type('double');
    var intType = Type('int');
    var numType = Type('num');
    var objectType = Type('Object');

    test('should handle nulls', () {
      expect(
          VariableModel.joinPromotedTypes(null, null, h.typeOperations), null);
      expect(VariableModel.joinPromotedTypes(null, [intType], h.typeOperations),
          null);
      expect(VariableModel.joinPromotedTypes([intType], null, h.typeOperations),
          null);
    });

    test('should return null if there are no common types', () {
      expect(
          VariableModel.joinPromotedTypes(
              [intType], [doubleType], h.typeOperations),
          null);
    });

    test('should return common prefix if there are common types', () {
      expect(
          VariableModel.joinPromotedTypes([objectType, intType],
              [objectType, doubleType], h.typeOperations),
          _matchPromotionChain(['Object']));
      expect(
          VariableModel.joinPromotedTypes([objectType, numType, intType],
              [objectType, numType, doubleType], h.typeOperations),
          _matchPromotionChain(['Object', 'num']));
    });

    test('should return an input if it is a prefix of the other', () {
      var prefix = [objectType, numType];
      var largerChain = [objectType, numType, intType];
      expect(
          VariableModel.joinPromotedTypes(
              prefix, largerChain, h.typeOperations),
          same(prefix));
      expect(
          VariableModel.joinPromotedTypes(
              largerChain, prefix, h.typeOperations),
          same(prefix));
      expect(VariableModel.joinPromotedTypes(prefix, prefix, h.typeOperations),
          same(prefix));
    });

    test('should intersect', () {
      // F <: E <: D <: C <: B <: A
      var A = Type('A');
      var B = Type('B');
      var C = Type('C');
      var D = Type('D');
      var E = Type('E');
      var F = Type('F');
      h.addSubtype('A', 'B', false);
      h.addSubtype('B', 'A', true);
      h.addSubtype('B', 'C', false);
      h.addSubtype('B', 'D', false);
      h.addSubtype('C', 'B', true);
      h.addSubtype('C', 'D', false);
      h.addSubtype('C', 'E', false);
      h.addSubtype('D', 'B', true);
      h.addSubtype('D', 'C', true);
      h.addSubtype('D', 'E', false);
      h.addSubtype('D', 'F', false);
      h.addSubtype('E', 'C', true);
      h.addSubtype('E', 'D', true);
      h.addSubtype('E', 'F', false);
      h.addSubtype('F', 'D', true);
      h.addSubtype('F', 'E', true);

      void check(List<Type> chain1, List<Type> chain2, Matcher matcher) {
        expect(
          VariableModel.joinPromotedTypes(chain1, chain2, h.typeOperations),
          matcher,
        );

        expect(
          VariableModel.joinPromotedTypes(chain2, chain1, h.typeOperations),
          matcher,
        );
      }

      {
        var chain1 = [A, B, C];
        var chain2 = [A, C];
        check(chain1, chain2, same(chain2));
      }

      check(
        [A, B, C, F],
        [A, D, E, F],
        _matchPromotionChain(['A', 'F']),
      );

      check(
        [A, B, E, F],
        [A, C, D, F],
        _matchPromotionChain(['A', 'F']),
      );

      check(
        [A, C, E],
        [B, C, D],
        _matchPromotionChain(['C']),
      );

      check(
        [A, C, E, F],
        [B, C, D, F],
        _matchPromotionChain(['C', 'F']),
      );

      check(
        [A, B, C],
        [A, B, D],
        _matchPromotionChain(['A', 'B']),
      );
    });
  });

  group('joinTypesOfInterest', () {
    List<Type> _makeTypes(List<String> typeNames) =>
        typeNames.map((t) => Type(t)).toList();

    test('simple prefix', () {
      var s1 = _makeTypes(['double', 'int']);
      var s2 = _makeTypes(['double', 'int', 'bool']);
      var expected = _matchOfInterestSet(['double', 'int', 'bool']);
      expect(VariableModel.joinTested(s1, s2, h.typeOperations), expected);
      expect(VariableModel.joinTested(s2, s1, h.typeOperations), expected);
    });

    test('common prefix', () {
      var s1 = _makeTypes(['double', 'int', 'String']);
      var s2 = _makeTypes(['double', 'int', 'bool']);
      var expected = _matchOfInterestSet(['double', 'int', 'String', 'bool']);
      expect(VariableModel.joinTested(s1, s2, h.typeOperations), expected);
      expect(VariableModel.joinTested(s2, s1, h.typeOperations), expected);
    });

    test('order mismatch', () {
      var s1 = _makeTypes(['double', 'int']);
      var s2 = _makeTypes(['int', 'double']);
      var expected = _matchOfInterestSet(['double', 'int']);
      expect(VariableModel.joinTested(s1, s2, h.typeOperations), expected);
      expect(VariableModel.joinTested(s2, s1, h.typeOperations), expected);
    });

    test('small common prefix', () {
      var s1 = _makeTypes(['int', 'double', 'String', 'bool']);
      var s2 = _makeTypes(['int', 'List', 'bool', 'Future']);
      var expected = _matchOfInterestSet(
          ['int', 'double', 'String', 'bool', 'List', 'Future']);
      expect(VariableModel.joinTested(s1, s2, h.typeOperations), expected);
      expect(VariableModel.joinTested(s2, s1, h.typeOperations), expected);
    });
  });

  group('join', () {
    late int x;
    late int y;
    late int z;
    late int w;
    var intType = Type('int');
    var intQType = Type('int?');
    var stringType = Type('String');
    const emptyMap = const <int, VariableModel<Type>>{};

    setUp(() {
      x = h.promotionKeyStore.keyForVariable(Var('x')..type = Type('Object?'));
      y = h.promotionKeyStore.keyForVariable(Var('y')..type = Type('Object?'));
      z = h.promotionKeyStore.keyForVariable(Var('z')..type = Type('Object?'));
      w = h.promotionKeyStore.keyForVariable(Var('w')..type = Type('Object?'));
    });

    VariableModel<Type> model(List<Type>? promotionChain,
            {List<Type>? typesOfInterest, bool assigned = false}) =>
        VariableModel<Type>(
            promotedTypes: promotionChain,
            tested: typesOfInterest ?? promotionChain ?? [],
            assigned: assigned,
            unassigned: !assigned,
            ssaNode: new SsaNode<Type>(null));

    group('without input reuse', () {
      test('promoted with unpromoted', () {
        var p1 = {
          x: model([intType]),
          y: model(null)
        };
        var p2 = {
          x: model(null),
          y: model([intType])
        };
        expect(FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap), {
          x: _matchVariableModel(chain: null, ofInterest: ['int']),
          y: _matchVariableModel(chain: null, ofInterest: ['int'])
        });
      });
    });
    group('should re-use an input if possible', () {
      test('identical inputs', () {
        var p = {
          x: model([intType]),
          y: model([stringType])
        };
        expect(FlowModel.joinVariableInfo(h.typeOperations, p, p, emptyMap),
            same(p));
      });

      test('one input empty', () {
        var p1 = {
          x: model([intType]),
          y: model([stringType])
        };
        var p2 = <int, VariableModel<Type>>{};
        expect(FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap),
            same(emptyMap));
        expect(FlowModel.joinVariableInfo(h.typeOperations, p2, p1, emptyMap),
            same(emptyMap));
      });

      test('promoted with unpromoted', () {
        var p1 = {
          x: model([intType])
        };
        var p2 = {x: model(null)};
        var expected = {
          x: _matchVariableModel(chain: null, ofInterest: ['int'])
        };
        expect(FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap),
            expected);
        expect(FlowModel.joinVariableInfo(h.typeOperations, p2, p1, emptyMap),
            expected);
      });

      test('related type chains', () {
        var p1 = {
          x: model([intQType, intType])
        };
        var p2 = {
          x: model([intQType])
        };
        var expected = {
          x: _matchVariableModel(chain: ['int?'], ofInterest: ['int?', 'int'])
        };
        expect(FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap),
            expected);
        expect(FlowModel.joinVariableInfo(h.typeOperations, p2, p1, emptyMap),
            expected);
      });

      test('unrelated type chains', () {
        var p1 = {
          x: model([intType])
        };
        var p2 = {
          x: model([stringType])
        };
        var expected = {
          x: _matchVariableModel(chain: null, ofInterest: ['String', 'int'])
        };
        expect(FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap),
            expected);
        expect(FlowModel.joinVariableInfo(h.typeOperations, p2, p1, emptyMap),
            expected);
      });

      test('sub-map', () {
        var xModel = model([intType]);
        var p1 = {
          x: xModel,
          y: model([stringType])
        };
        var p2 = {x: xModel};
        expect(FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap),
            same(p2));
        expect(FlowModel.joinVariableInfo(h.typeOperations, p2, p1, emptyMap),
            same(p2));
      });

      test('sub-map with matched subtype', () {
        var p1 = {
          x: model([intQType, intType]),
          y: model([stringType])
        };
        var p2 = {
          x: model([intQType])
        };
        var expected = {
          x: _matchVariableModel(chain: ['int?'], ofInterest: ['int?', 'int'])
        };
        expect(FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap),
            expected);
        expect(FlowModel.joinVariableInfo(h.typeOperations, p2, p1, emptyMap),
            expected);
      });

      test('sub-map with mismatched subtype', () {
        var p1 = {
          x: model([intQType]),
          y: model([stringType])
        };
        var p2 = {
          x: model([intQType, intType])
        };
        var expected = {
          x: _matchVariableModel(chain: ['int?'], ofInterest: ['int?', 'int'])
        };
        expect(FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap),
            expected);
        expect(FlowModel.joinVariableInfo(h.typeOperations, p2, p1, emptyMap),
            expected);
      });

      test('assigned', () {
        var unassigned = model(null, assigned: false);
        var assigned = model(null, assigned: true);
        var p1 = {x: assigned, y: assigned, z: unassigned, w: unassigned};
        var p2 = {x: assigned, y: unassigned, z: assigned, w: unassigned};
        var joined =
            FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap);
        expect(joined, {
          x: same(assigned),
          y: _matchVariableModel(
              chain: null, assigned: false, unassigned: false),
          z: _matchVariableModel(
              chain: null, assigned: false, unassigned: false),
          w: same(unassigned)
        });
      });

      test('write captured', () {
        var intQModel = model([intQType]);
        var writeCapturedModel = intQModel.writeCapture();
        var p1 = {
          x: writeCapturedModel,
          y: writeCapturedModel,
          z: intQModel,
          w: intQModel
        };
        var p2 = {
          x: writeCapturedModel,
          y: intQModel,
          z: writeCapturedModel,
          w: intQModel
        };
        var joined =
            FlowModel.joinVariableInfo(h.typeOperations, p1, p2, emptyMap);
        expect(joined, {
          x: same(writeCapturedModel),
          y: same(writeCapturedModel),
          z: same(writeCapturedModel),
          w: same(intQModel)
        });
      });
    });
  });

  group('merge', () {
    late int x;
    var intType = Type('int');
    var stringType = Type('String');
    const emptyMap = const <int, VariableModel<Type>>{};

    setUp(() {
      x = h.promotionKeyStore.keyForVariable(Var('x')..type = Type('Object?'));
    });

    VariableModel<Type> varModel(List<Type>? promotionChain,
            {bool assigned = false}) =>
        VariableModel<Type>(
            promotedTypes: promotionChain,
            tested: promotionChain ?? [],
            assigned: assigned,
            unassigned: !assigned,
            ssaNode: new SsaNode<Type>(null));

    test('first is null', () {
      var s1 = FlowModel.withInfo(Reachability.initial.split(), emptyMap);
      var result = FlowModel.merge(h.typeOperations, null, s1, emptyMap);
      expect(result.reachable, same(Reachability.initial));
    });

    test('second is null', () {
      var splitPoint = Reachability.initial.split();
      var afterSplit = splitPoint.split();
      var s1 = FlowModel.withInfo(afterSplit, emptyMap);
      var result = FlowModel.merge(h.typeOperations, s1, null, emptyMap);
      expect(result.reachable, same(splitPoint));
    });

    test('both are reachable', () {
      var splitPoint = Reachability.initial.split();
      var afterSplit = splitPoint.split();
      var s1 = FlowModel.withInfo(afterSplit, {
        x: varModel([intType])
      });
      var s2 = FlowModel.withInfo(afterSplit, {
        x: varModel([stringType])
      });
      var result = FlowModel.merge(h.typeOperations, s1, s2, emptyMap);
      expect(result.reachable, same(splitPoint));
      expect(result.variableInfo[x]!.promotedTypes, isNull);
    });

    test('first is unreachable', () {
      var splitPoint = Reachability.initial.split();
      var afterSplit = splitPoint.split();
      var s1 = FlowModel.withInfo(afterSplit.setUnreachable(), {
        x: varModel([intType])
      });
      var s2 = FlowModel.withInfo(afterSplit, {
        x: varModel([stringType])
      });
      var result = FlowModel.merge(h.typeOperations, s1, s2, emptyMap);
      expect(result.reachable, same(splitPoint));
      expect(result.variableInfo, same(s2.variableInfo));
    });

    test('second is unreachable', () {
      var splitPoint = Reachability.initial.split();
      var afterSplit = splitPoint.split();
      var s1 = FlowModel.withInfo(afterSplit, {
        x: varModel([intType])
      });
      var s2 = FlowModel.withInfo(afterSplit.setUnreachable(), {
        x: varModel([stringType])
      });
      var result = FlowModel.merge(h.typeOperations, s1, s2, emptyMap);
      expect(result.reachable, same(splitPoint));
      expect(result.variableInfo, same(s1.variableInfo));
    });

    test('both are unreachable', () {
      var splitPoint = Reachability.initial.split();
      var afterSplit = splitPoint.split();
      var s1 = FlowModel.withInfo(afterSplit.setUnreachable(), {
        x: varModel([intType])
      });
      var s2 = FlowModel.withInfo(afterSplit.setUnreachable(), {
        x: varModel([stringType])
      });
      var result = FlowModel.merge(h.typeOperations, s1, s2, emptyMap);
      expect(result.reachable.locallyReachable, false);
      expect(result.reachable.parent, same(splitPoint.parent));
      expect(result.variableInfo[x]!.promotedTypes, isNull);
    });
  });

  group('inheritTested', () {
    late int x;
    var intType = Type('int');
    var stringType = Type('String');
    const emptyMap = const <int, VariableModel<Type>>{};

    setUp(() {
      x = h.promotionKeyStore.keyForVariable(Var('x')..type = Type('Object?'));
    });

    VariableModel<Type> model(List<Type> typesOfInterest) =>
        VariableModel<Type>(
            promotedTypes: null,
            tested: typesOfInterest,
            assigned: true,
            unassigned: false,
            ssaNode: new SsaNode<Type>(null));

    test('inherits types of interest from other', () {
      var m1 = FlowModel.withInfo(Reachability.initial, {
        x: model([intType])
      });
      var m2 = FlowModel.withInfo(Reachability.initial, {
        x: model([stringType])
      });
      expect(m1.inheritTested(h.typeOperations, m2).variableInfo[x]!.tested,
          _matchOfInterestSet(['int', 'String']));
    });

    test('handles variable missing from other', () {
      var m1 = FlowModel.withInfo(Reachability.initial, {
        x: model([intType])
      });
      var m2 = FlowModel.withInfo(Reachability.initial, emptyMap);
      expect(m1.inheritTested(h.typeOperations, m2), same(m1));
    });

    test('returns identical model when no changes', () {
      var m1 = FlowModel.withInfo(Reachability.initial, {
        x: model([intType])
      });
      var m2 = FlowModel.withInfo(Reachability.initial, {
        x: model([intType])
      });
      expect(m1.inheritTested(h.typeOperations, m2), same(m1));
    });
  });

  group('Legacy promotion', () {
    group('if statement', () {
      group('promotes a variable whose type is shown by its condition', () {
        test('within then-block', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkPromoted(x, 'int'),
            ]),
          ]);
        });

        test('but not within else-block', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [], [
              checkNotPromoted(x),
            ]),
          ]);
        });

        test('unless the then-block mutates it', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkNotPromoted(x),
              x.write(expr('int')).stmt,
            ]),
          ]);
        });

        test('even if the condition mutates it', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(
                x
                    .write(expr('int'))
                    .parenthesized
                    .eq(expr('int'))
                    .and(x.expr.is_('int')),
                [
                  checkPromoted(x, 'int'),
                ]),
          ]);
        });

        test('even if the else-block mutates it', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkPromoted(x, 'int'),
            ], [
              x.write(expr('int')).stmt,
            ]),
          ]);
        });

        test('unless a closure mutates it', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkNotPromoted(x),
            ]),
            localFunction([
              x.write(expr('int')).stmt,
            ]),
          ]);
        });

        test(
            'unless a closure in the then-block accesses it and it is mutated '
            'anywhere', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkNotPromoted(x),
              localFunction([
                x.expr.stmt,
              ]),
            ]),
            x.write(expr('int')).stmt,
          ]);
        });

        test(
            'unless a closure in the then-block accesses it and it is mutated '
            'anywhere, even if the access is deeply nested', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkNotPromoted(x),
              localFunction([
                localFunction([
                  x.expr.stmt,
                ]),
              ]),
            ]),
            x.write(expr('int')).stmt,
          ]);
        });

        test(
            'even if a closure in the condition accesses it and it is mutated '
            'somewhere', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(
                localFunction([
                  x.expr.stmt,
                ]).thenExpr(expr('bool')).and(x.expr.is_('int')),
                [
                  checkPromoted(x, 'int'),
                ]),
            x.write(expr('int')).stmt,
          ]);
        });

        test(
            'even if a closure in the else-block accesses it and it is mutated '
            'somewhere', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkPromoted(x, 'int'),
            ], [
              localFunction([
                x.expr.stmt,
              ]),
            ]),
            x.write(expr('int')).stmt,
          ]);
        });

        test(
            'even if a closure in the then-block accesses it, provided it is '
            'not mutated anywhere', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkPromoted(x, 'int'),
              localFunction([
                x.expr.stmt,
              ]),
            ]),
          ]);
        });
      });

      test('handles arbitrary conditions', () {
        h.legacy = true;
        h.run([
          if_(expr('bool'), []),
        ]);
      });

      test('handles a condition that is a variable', () {
        h.legacy = true;
        var x = Var('x');
        h.run([
          declare(x, type: 'bool'),
          if_(x.expr, []),
        ]);
      });

      test('handles multiple promotions', () {
        h.legacy = true;
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'Object'),
          declare(y, type: 'Object'),
          if_(x.expr.is_('int').and(y.expr.is_('String')), [
            checkPromoted(x, 'int'),
            checkPromoted(y, 'String'),
          ]),
        ]);
      });
    });

    group('conditional expression', () {
      group('promotes a variable whose type is shown by its condition', () {
        test('within then-expression', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x.expr
                .is_('int')
                .conditional(checkPromoted(x, 'int').thenExpr(expr('Object')),
                    expr('Object'))
                .stmt,
          ]);
        });

        test('but not within else-expression', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x.expr
                .is_('int')
                .conditional(expr('Object'),
                    checkNotPromoted(x).thenExpr(expr('Object')))
                .stmt,
          ]);
        });

        test('unless the then-expression mutates it', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x.expr
                .is_('int')
                .conditional(
                    block([
                      checkNotPromoted(x),
                      x.write(expr('int')).stmt,
                    ]).thenExpr(expr('Object')),
                    expr('Object'))
                .stmt,
          ]);
        });

        test('even if the condition mutates it', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x
                .write(expr('int'))
                .parenthesized
                .eq(expr('int'))
                .and(x.expr.is_('int'))
                .conditional(checkPromoted(x, 'int').thenExpr(expr('Object')),
                    expr('Object'))
                .stmt,
          ]);
        });

        test('even if the else-expression mutates it', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x.expr
                .is_('int')
                .conditional(checkPromoted(x, 'int').thenExpr(expr('int')),
                    x.write(expr('int')))
                .stmt,
          ]);
        });

        test('unless a closure mutates it', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x.expr
                .is_('int')
                .conditional(checkNotPromoted(x).thenExpr(expr('Object')),
                    expr('Object'))
                .stmt,
            localFunction([
              x.write(expr('int')).stmt,
            ]),
          ]);
        });

        test(
            'unless a closure in the then-expression accesses it and it is '
            'mutated anywhere', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x.expr
                .is_('int')
                .conditional(
                    block([
                      checkNotPromoted(x),
                      localFunction([
                        x.expr.stmt,
                      ]),
                    ]).thenExpr(expr('Object')),
                    expr('Object'))
                .stmt,
            x.write(expr('int')).stmt,
          ]);
        });

        test(
            'even if a closure in the condition accesses it and it is mutated '
            'somewhere', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            localFunction([
              x.expr.stmt,
            ])
                .thenExpr(expr('Object'))
                .and(x.expr.is_('int'))
                .conditional(checkPromoted(x, 'int').thenExpr(expr('Object')),
                    expr('Object'))
                .stmt,
            x.write(expr('int')).stmt,
          ]);
        });

        test(
            'even if a closure in the else-expression accesses it and it is '
            'mutated somewhere', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x.expr
                .is_('int')
                .conditional(
                    checkPromoted(x, 'int').thenExpr(expr('Object')),
                    localFunction([
                      x.expr.stmt,
                    ]).thenExpr(expr('Object')))
                .stmt,
            x.write(expr('int')).stmt,
          ]);
        });

        test(
            'even if a closure in the then-expression accesses it, provided it '
            'is not mutated anywhere', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            x.expr
                .is_('int')
                .conditional(
                    block([
                      checkPromoted(x, 'int'),
                      localFunction([
                        x.expr.stmt,
                      ]),
                    ]).thenExpr(expr('Object')),
                    expr('Object'))
                .stmt,
          ]);
        });
      });

      test('handles arbitrary conditions', () {
        h.legacy = true;
        h.run([
          expr('bool').conditional(expr('Object'), expr('Object')).stmt,
        ]);
      });

      test('handles a condition that is a variable', () {
        h.legacy = true;
        var x = Var('x');
        h.run([
          declare(x, type: 'bool'),
          x.expr.conditional(expr('Object'), expr('Object')).stmt,
        ]);
      });

      test('handles multiple promotions', () {
        h.legacy = true;
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'Object'),
          declare(y, type: 'Object'),
          x.expr
              .is_('int')
              .and(y.expr.is_('String'))
              .conditional(
                  block([
                    checkPromoted(x, 'int'),
                    checkPromoted(y, 'String'),
                  ]).thenExpr(expr('Object')),
                  expr('Object'))
              .stmt
        ]);
      });
    });

    group('logical', () {
      group('and', () {
        group("shows a variable's type", () {
          test('if the lhs shows the type', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              if_(x.expr.is_('int').and(expr('bool')), [
                checkPromoted(x, 'int'),
              ]),
            ]);
          });

          test('if the rhs shows the type', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              if_(expr('bool').and(x.expr.is_('int')), [
                checkPromoted(x, 'int'),
              ]),
            ]);
          });

          test('unless the rhs mutates it', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              if_(x.expr.is_('int').and(x.write(expr('bool'))), [
                checkNotPromoted(x),
              ]),
            ]);
          });

          test('unless the rhs mutates it, even if the rhs also shows the type',
              () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              if_(
                  expr('bool').and(x
                      .write(expr('Object'))
                      .and(x.expr.is_('int'))
                      .parenthesized),
                  [
                    checkNotPromoted(x),
                  ]),
            ]);
          });

          test('unless a closure mutates it', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              if_(x.expr.is_('int').and(expr('bool')), [
                checkNotPromoted(x),
              ]),
              localFunction([
                x.write(expr('int')).stmt,
              ]),
            ]);
          });
        });

        group('promotes a variable whose type is shown by its lhs', () {
          test('within its rhs', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              x.expr
                  .is_('int')
                  .and(checkPromoted(x, 'int').thenExpr(expr('bool')))
                  .stmt,
            ]);
          });

          test('unless the lhs mutates it', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              x
                  .write(expr('int'))
                  .parenthesized
                  .eq(expr('int'))
                  .and(x.expr.is_('int'))
                  .parenthesized
                  .and(checkNotPromoted(x).thenExpr(expr('bool')))
                  .stmt,
            ]);
          });

          test('unless the rhs mutates it', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              x.expr
                  .is_('int')
                  .and(checkNotPromoted(x).thenExpr(x.write(expr('bool'))))
                  .stmt,
            ]);
          });

          test('unless a closure mutates it', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              x.expr
                  .is_('int')
                  .and(checkNotPromoted(x).thenExpr(expr('bool')))
                  .stmt,
              localFunction([
                x.write(expr('int')).stmt,
              ]),
            ]);
          });

          test(
              'unless a closure in the rhs accesses it and it is mutated '
              'anywhere', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              x.expr
                  .is_('int')
                  .and(block([
                    checkNotPromoted(x),
                    localFunction([
                      x.expr.stmt,
                    ]),
                  ]).thenExpr(expr('bool')))
                  .stmt,
              x.write(expr('int')).stmt,
            ]);
          });

          test(
              'even if a closure in the lhs accesses it and it is mutated '
              'somewhere', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              localFunction([
                x.expr.stmt,
              ])
                  .thenExpr(expr('Object'))
                  .and(x.expr.is_('int'))
                  .parenthesized
                  .and(checkPromoted(x, 'int').thenExpr(expr('bool')))
                  .stmt,
              x.write(expr('int')).stmt,
            ]);
          });

          test(
              'even if a closure in the rhs accesses it, provided it is not '
              'mutated anywhere', () {
            h.legacy = true;
            var x = Var('x');
            h.run([
              declare(x, type: 'Object'),
              x.expr
                  .is_('int')
                  .and(block([
                    checkPromoted(x, 'int'),
                    localFunction([
                      x.expr.stmt,
                    ]),
                  ]).thenExpr(expr('bool')))
                  .stmt,
            ]);
          });
        });

        test('uses lhs promotion if rhs is not to a subtype', () {
          h.legacy = true;
          var x = Var('x');
          // Note: for this to be an effective test, we need to mutate `x` on
          // the LHS of the outer `&&` so that `x` is not promoted on the RHS
          // (and thus the lesser promotion on the RHS can take effect).
          h.run([
            declare(x, type: 'Object'),
            if_(
                x
                    .write(expr('Object'))
                    .parenthesized
                    .and(x.expr.is_('int'))
                    .parenthesized
                    .and(x.expr.is_('num')),
                [
                  checkPromoted(x, 'int'),
                ]),
          ]);
        });

        test('uses rhs promotion if rhs is to a subtype', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('num').and(x.expr.is_('int')), [
              checkPromoted(x, 'int'),
            ]),
          ]);
        });

        test('can handle multiple promotions on lhs', () {
          h.legacy = true;
          var x = Var('x');
          var y = Var('y');
          h.run([
            declare(x, type: 'Object'),
            declare(y, type: 'Object'),
            x.expr
                .is_('int')
                .and(y.expr.is_('String'))
                .parenthesized
                .and(block([
                  checkPromoted(x, 'int'),
                  checkPromoted(y, 'String'),
                ]).thenExpr(expr('bool')))
                .stmt,
          ]);
        });

        test('handles variables', () {
          h.legacy = true;
          var x = Var('x');
          var y = Var('y');
          h.run([
            declare(x, type: 'bool'),
            declare(y, type: 'bool'),
            if_(x.expr.and(y.expr), []),
          ]);
        });

        test('handles arbitrary expressions', () {
          h.legacy = true;
          h.run([
            if_(expr('bool').and(expr('bool')), []),
          ]);
        });
      });

      test('or is ignored', () {
        h.legacy = true;
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          if_(x.expr.is_('int').or(x.expr.is_('int')), [
            checkNotPromoted(x),
          ], [
            checkNotPromoted(x),
          ])
        ]);
      });
    });

    group('is test', () {
      group("shows a variable's type", () {
        test('normally', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int'), [
              checkPromoted(x, 'int'),
            ], [
              checkNotPromoted(x),
            ])
          ]);
        });

        test('unless the test is inverted', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('int', isInverted: true), [
              checkNotPromoted(x),
            ], [
              checkNotPromoted(x),
            ])
          ]);
        });

        test('unless the tested type is not a subtype of the declared type',
            () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'String'),
            if_(x.expr.is_('int'), [
              checkNotPromoted(x),
            ], [
              checkNotPromoted(x),
            ])
          ]);
        });

        test("even when the variable's type has been previously promoted", () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('num'), [
              if_(x.expr.is_('int'), [
                checkPromoted(x, 'int'),
              ], [
                checkPromoted(x, 'num'),
              ])
            ]),
          ]);
        });

        test(
            'unless the tested type is not a subtype of the previously '
            'promoted type', () {
          h.legacy = true;
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            if_(x.expr.is_('String'), [
              if_(x.expr.is_('int'), [
                checkPromoted(x, 'String'),
              ], [
                checkPromoted(x, 'String'),
              ])
            ]),
          ]);
        });

        test('even when the declared type is a type variable', () {
          h.legacy = true;
          h.addPromotionException('T', 'int', 'T&int');
          var x = Var('x');
          h.run([
            declare(x, type: 'T'),
            if_(x.expr.is_('int'), [
              checkPromoted(x, 'T&int'),
            ]),
          ]);
        });
      });

      test('handles arbitrary expressions', () {
        h.legacy = true;
        h.run([
          if_(expr('Object').is_('int'), []),
        ]);
      });
    });

    test('forwardExpression does not re-activate a deeply nested expression',
        () {
      h.legacy = true;
      var x = Var('x');
      h.run([
        declare(x, type: 'Object'),
        if_(x.expr.is_('int').eq(expr('Object')).thenStmt(block([])), [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test(
        'parenthesizedExpression does not re-activate a deeply nested '
        'expression', () {
      h.legacy = true;
      var x = Var('x');
      h.run([
        declare(x, type: 'Object'),
        if_(x.expr.is_('int').eq(expr('Object')).parenthesized, [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('variableRead returns the promoted type if promoted', () {
      h.legacy = true;
      var x = Var('x');
      h.run([
        declare(x, type: 'Object'),
        if_(
            x
                .readAndCheckPromotedType((type) => expect(type, isNull))
                .is_('int'),
            [
              x
                  .readAndCheckPromotedType((type) => expect(type!.type, 'int'))
                  .stmt,
            ]),
      ]);
    });
  });

  group('why not promoted', () {
    test('due to assignment', () {
      var x = Var('x');
      late Expression writeExpression;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(x, 'int'),
        (writeExpression = x.write(expr('int?'))).stmt,
        checkNotPromoted(x),
        x.expr.whyNotPromoted((reasons) {
          expect(reasons.keys, unorderedEquals([Type('int')]));
          var nonPromotionReason =
              reasons.values.single as DemoteViaExplicitWrite<Var>;
          expect(nonPromotionReason.node, same(writeExpression));
        }).stmt,
      ]);
    });

    test('due to assignment, multiple demotions', () {
      var x = Var('x');
      late Expression writeExpression;
      h.run([
        declare(x, type: 'Object?', initializer: expr('Object?')),
        if_(x.expr.isNot('int?'), [
          return_(),
        ]),
        if_(x.expr.eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(x, 'int'),
        (writeExpression = x.write(expr('Object?'))).stmt,
        checkNotPromoted(x),
        x.expr.whyNotPromoted((reasons) {
          expect(reasons.keys, unorderedEquals([Type('int'), Type('int?')]));
          expect((reasons[Type('int')] as DemoteViaExplicitWrite<Var>).node,
              same(writeExpression));
          expect((reasons[Type('int?')] as DemoteViaExplicitWrite<Var>).node,
              same(writeExpression));
        }).stmt,
      ]);
    });

    test('preserved in join when one branch unreachable', () {
      var x = Var('x');
      late Expression writeExpression;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(x, 'int'),
        (writeExpression = x.write(expr('int?'))).stmt,
        checkNotPromoted(x),
        if_(expr('bool'), [
          return_(),
        ]),
        x.expr.whyNotPromoted((reasons) {
          expect(reasons.keys, unorderedEquals([Type('int')]));
          var nonPromotionReason =
              reasons.values.single as DemoteViaExplicitWrite<Var>;
          expect(nonPromotionReason.node, same(writeExpression));
        }).stmt,
      ]);
    });

    test('preserved in later promotions', () {
      var x = Var('x');
      late Expression writeExpression;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        if_(x.expr.is_('int', isInverted: true), [
          return_(),
        ]),
        checkPromoted(x, 'int'),
        (writeExpression = x.write(expr('Object'))).stmt,
        checkNotPromoted(x),
        if_(x.expr.is_('num', isInverted: true), [
          return_(),
        ]),
        checkPromoted(x, 'num'),
        x.expr.whyNotPromoted((reasons) {
          var nonPromotionReason =
              reasons[Type('int')] as DemoteViaExplicitWrite<Var>;
          expect(nonPromotionReason.node, same(writeExpression));
        }).stmt,
      ]);
    });

    test('re-promotion', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.expr.eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(x, 'int'),
        x.write(expr('int?')).stmt,
        checkNotPromoted(x),
        if_(x.expr.eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(x, 'int'),
        x.expr.whyNotPromoted((reasons) {
          expect(reasons, isEmpty);
        }).stmt,
      ]);
    });

    group('because property', () {
      test('via explicit this', () {
        h.thisType = 'C';
        h.addMember('C', 'field', 'Object?');
        h.run([
          if_(this_.property('field').eq(nullLiteral), [
            return_(),
          ]),
          this_.property('field').whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('Object')]));
            var nonPromotionReason = reasons.values.single;
            expect(nonPromotionReason, TypeMatcher<PropertyNotPromoted>());
          }).stmt,
        ]);
      });

      test('via implicit this/super', () {
        h.thisType = 'C';
        h.addMember('C', 'field', 'Object?');
        h.run([
          if_(thisOrSuperProperty('field').eq(nullLiteral), [
            return_(),
          ]),
          thisOrSuperProperty('field').whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('Object')]));
            var nonPromotionReason = reasons.values.single;
            expect(nonPromotionReason, TypeMatcher<PropertyNotPromoted>());
          }).stmt,
        ]);
      });

      test('via variable', () {
        h.addMember('C', 'field', 'Object?');
        var x = Var('x');
        h.run([
          declare(x, type: 'C', initializer: expr('C')),
          if_(x.expr.property('field').eq(nullLiteral), [
            return_(),
          ]),
          x.expr.property('field').whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('Object')]));
            var nonPromotionReason = reasons.values.single;
            expect(nonPromotionReason, TypeMatcher<PropertyNotPromoted>());
          }).stmt,
        ]);
      });
    });

    group('because this', () {
      test('explicit', () {
        h.thisType = 'C';
        h.addSubtype('D', 'C', true);
        h.addFactor('C', 'D', 'C');
        h.run([
          if_(this_.isNot('D'), [
            return_(),
          ]),
          this_.whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('D')]));
            var nonPromotionReason = reasons.values.single;
            expect(nonPromotionReason, TypeMatcher<ThisNotPromoted>());
          }).stmt,
        ]);
      });

      test('implicit', () {
        h.thisType = 'C';
        h.addSubtype('D', 'C', true);
        h.addFactor('C', 'D', 'C');
        h.run([
          if_(this_.isNot('D'), [
            return_(),
          ]),
          implicitThis_whyNotPromoted('C', (reasons) {
            expect(reasons.keys, unorderedEquals([Type('D')]));
            var nonPromotionReason = reasons.values.single;
            expect(nonPromotionReason, TypeMatcher<ThisNotPromoted>());
          }),
        ]);
      });
    });
  });

  group('Field promotion', () {
    test('promotable field', () {
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field').eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field'), 'Object'),
        x.expr.property('_field').checkType('Object').stmt,
      ]);
    });

    test('promotable field, this', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      h.run([
        if_(thisOrSuperProperty('_field').eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(thisOrSuperProperty('_field'), 'Object'),
        thisOrSuperProperty('_field').checkType('Object').stmt,
      ]);
    });

    test('non-promotable field', () {
      h.addMember('C', '_field', 'Object?', promotable: false);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field').eq(nullLiteral), [
          return_(),
        ]),
        checkNotPromoted(x.expr.property('_field')),
        x.expr.property('_field').checkType('Object?').stmt,
      ]);
    });

    test('non-promotable field, this', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: false);
      h.run([
        if_(thisOrSuperProperty('_field').eq(nullLiteral), [
          return_(),
        ]),
        checkNotPromoted(thisOrSuperProperty('_field')),
        thisOrSuperProperty('_field').checkType('Object?').stmt,
      ]);
    });

    test('multiply promoted', () {
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field').eq(nullLiteral), [
          return_(),
        ]),
        if_(x.expr.property('_field').isNot('int'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field'), 'int'),
        x.expr.property('_field').checkType('int').stmt,
      ]);
    });

    test('multiply promoted, this', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      h.run([
        if_(thisOrSuperProperty('_field').eq(nullLiteral), [
          return_(),
        ]),
        if_(thisOrSuperProperty('_field').isNot('int'), [
          return_(),
        ]),
        checkPromoted(thisOrSuperProperty('_field'), 'int'),
        thisOrSuperProperty('_field').checkType('int').stmt,
      ]);
    });

    test('promotion of target breaks field promotion', () {
      h.addMember('B', '_field', 'Object?', promotable: true);
      h.addMember('C', '_field', 'num?', promotable: true);
      h.addSubtype('C', 'B', true);
      h.addFactor('B', 'C', 'B');
      var x = Var('x');
      h.run([
        declare(x, type: 'B', initializer: expr('B')),
        if_(x.expr.property('_field').eq(nullLiteral), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field'), 'Object'),
        x.expr.property('_field').checkType('Object').stmt,
        if_(x.expr.isNot('C'), [
          return_(),
        ]),
        checkNotPromoted(x.expr.property('_field')),
        x.expr.property('_field').checkType('num?').stmt,
      ]);
    });

    test('promotion of target does not break field promotion', () {
      h.addMember('B', '_field', 'Object?', promotable: true);
      h.addMember('C', '_field', 'num?', promotable: true);
      h.addSubtype('C', 'B', true);
      h.addFactor('B', 'C', 'B');
      var x = Var('x');
      h.run([
        declare(x, type: 'B', initializer: expr('B')),
        if_(x.expr.property('_field').isNot('int'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field'), 'int'),
        x.expr.property('_field').checkType('int').stmt,
        if_(x.expr.isNot('C'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field'), 'int'),
        x.expr.property('_field').checkType('int').stmt,
      ]);
    });

    test('field not promotable after outer variable demoted', () {
      h.addMember('B', '_field', 'Object?', promotable: false);
      h.addMember('C', '_field', 'Object?', promotable: true);
      h.addSubtype('C', 'B', true);
      h.addFactor('B', 'C', 'B');
      var x = Var('x');
      h.run([
        declare(x, type: 'B', initializer: expr('B')),
        if_(x.expr.is_('C'), [
          if_(x.expr.property('_field').notEq(nullLiteral), [
            checkPromoted(x.expr.property('_field'), 'Object'),
            x.expr.property('_field').checkType('Object').stmt,
          ]),
        ]),
        if_(x.expr.property('_field').notEq(nullLiteral), [
          checkNotPromoted(x.expr.property('_field')),
          x.expr.property('_field').checkType('Object?').stmt,
        ]),
      ]);
    });

    test('field promotable after outer variable promoted', () {
      h.addMember('B', '_field', 'Object?', promotable: false);
      h.addMember('C', '_field', 'Object?', promotable: true);
      h.addSubtype('C', 'B', true);
      h.addFactor('B', 'C', 'B');
      var x = Var('x');
      h.run([
        declare(x, type: 'B', initializer: expr('B')),
        if_(x.expr.property('_field').notEq(nullLiteral), [
          checkNotPromoted(x.expr.property('_field')),
          x.expr.property('_field').checkType('Object?').stmt,
        ]),
        if_(x.expr.is_('C'), [
          if_(x.expr.property('_field').notEq(nullLiteral), [
            checkPromoted(x.expr.property('_field'), 'Object'),
            x.expr.property('_field').checkType('Object').stmt,
          ]),
        ]),
      ]);
    });

    test('promotion targets properly distinguished', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'Object?', promotable: true);
      h.addMember('C', '_field2', 'Object?', promotable: true);
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        declare(y, type: 'C', initializer: expr('C')),
        if_(thisOrSuperProperty('_field1').isNot('String'), [
          return_(),
        ]),
        if_(this_.property('_field2').isNot('String?'), [
          return_(),
        ]),
        if_(x.expr.property('_field1').isNot('int'), [
          return_(),
        ]),
        if_(y.expr.property('_field1').isNot('double'), [
          return_(),
        ]),
        checkPromoted(thisOrSuperProperty('_field1'), 'String'),
        thisOrSuperProperty('_field1').checkType('String').stmt,
        checkPromoted(this_.property('_field1'), 'String'),
        this_.property('_field1').checkType('String').stmt,
        checkPromoted(thisOrSuperProperty('_field2'), 'String?'),
        thisOrSuperProperty('_field2').checkType('String?').stmt,
        checkPromoted(this_.property('_field2'), 'String?'),
        this_.property('_field2').checkType('String?').stmt,
        checkPromoted(x.expr.property('_field1'), 'int'),
        x.expr.property('_field1').checkType('int').stmt,
        checkNotPromoted(x.expr.property('_field2')),
        x.expr.property('_field2').checkType('Object?').stmt,
        checkPromoted(y.expr.property('_field1'), 'double'),
        y.expr.property('_field1').checkType('double').stmt,
        checkNotPromoted(y.expr.property('_field2')),
        y.expr.property('_field2').checkType('Object?').stmt,
      ]);
    });

    test('cancelled by write to local var', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field'), 'String'),
        x.expr.property('_field').checkType('String').stmt,
        x.write(expr('C')).stmt,
        checkNotPromoted(x.expr.property('_field')),
        x.expr.property('_field').checkType('Object?').stmt,
      ]);
    });

    test('cancelled by write to local var, nested', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: true);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field1').property('_field2'), 'String'),
        x.expr.property('_field1').property('_field2').checkType('String').stmt,
        x.write(expr('C')).stmt,
        checkNotPromoted(x.expr.property('_field1').property('_field2')),
        x.expr
            .property('_field1')
            .property('_field2')
            .checkType('Object?')
            .stmt,
      ]);
    });

    test('cancelled by write to local var later in loop', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field'), 'String'),
        x.expr.property('_field').checkType('String').stmt,
        while_(expr('bool'), [
          checkNotPromoted(x.expr.property('_field')),
          x.expr.property('_field').checkType('Object?').stmt,
          x.write(expr('C')).stmt,
        ]),
      ]);
    });

    test('cancelled by write to local var later in loop, nested', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: true);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field1').property('_field2'), 'String'),
        x.expr.property('_field1').property('_field2').checkType('String').stmt,
        while_(expr('bool'), [
          checkNotPromoted(x.expr.property('_field1').property('_field2')),
          x.expr
              .property('_field1')
              .property('_field2')
              .checkType('Object?')
              .stmt,
          x.write(expr('C')).stmt,
        ]),
      ]);
    });

    test('cancelled by capture of local var', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field'), 'String'),
        x.expr.property('_field').checkType('String').stmt,
        localFunction([
          x.write(expr('C')).stmt,
        ]),
        checkNotPromoted(x.expr.property('_field')),
        x.expr.property('_field').checkType('Object?').stmt,
      ]);
    });

    test('cancelled by capture of local var, nested', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: true);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.expr.property('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.expr.property('_field1').property('_field2'), 'String'),
        x.expr.property('_field1').property('_field2').checkType('String').stmt,
        localFunction([
          x.write(expr('C')).stmt,
        ]),
        checkNotPromoted(x.expr.property('_field1').property('_field2')),
        x.expr
            .property('_field1')
            .property('_field2')
            .checkType('Object?')
            .stmt,
      ]);
    });

    test('prevented by previous capture of local var', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        localFunction([
          x.write(expr('C')).stmt,
        ]),
        if_(x.expr.property('_field').isNot('String'), [
          return_(),
        ]),
        checkNotPromoted(x.expr.property('_field')),
        x.expr.property('_field').checkType('Object?').stmt,
      ]);
    });

    test('prevented by previous capture of local var, nested', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: true);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        localFunction([
          x.write(expr('C')).stmt,
        ]),
        if_(x.expr.property('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkNotPromoted(x.expr.property('_field1').property('_field2')),
        x.expr
            .property('_field1')
            .property('_field2')
            .checkType('Object?')
            .stmt,
      ]);
    });

    test('prevented by non-promotability of target', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: false);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      h.run([
        if_(
            thisOrSuperProperty('_field1').property('_field2').isNot('String'),
            [
              return_(),
            ]),
        checkNotPromoted(thisOrSuperProperty('_field1').property('_field2')),
        thisOrSuperProperty('_field1')
            .property('_field2')
            .checkType('Object?')
            .stmt,
      ]);
    });
  });
}

/// Returns the appropriate matcher for expecting an assertion error to be
/// thrown or not, based on whether assertions are enabled.
Matcher get _asserts {
  var matcher = throwsA(TypeMatcher<AssertionError>());
  bool assertionsEnabled = false;
  assert(assertionsEnabled = true);
  if (!assertionsEnabled) {
    matcher = isNot(matcher);
  }
  return matcher;
}

String _describeMatcher(Matcher matcher) {
  var description = StringDescription();
  matcher.describe(description);
  return description.toString();
}

Matcher _matchOfInterestSet(List<String> expectedTypes) {
  return predicate(
      (List<Type> x) => unorderedEquals(expectedTypes)
          .matches(x.map((t) => t.type).toList(), {}),
      'interest set $expectedTypes');
}

Matcher _matchPromotionChain(List<String>? expectedTypes) {
  if (expectedTypes == null) return isNull;
  return predicate(
      (List<Type> x) =>
          equals(expectedTypes).matches(x.map((t) => t.type).toList(), {}),
      'promotion chain $expectedTypes');
}

Matcher _matchVariableModel(
    {Object? chain,
    Object? ofInterest,
    Object? assigned,
    Object? unassigned,
    Object? writeCaptured}) {
  chain ??= anything;
  ofInterest ??= anything;
  assigned ??= anything;
  unassigned ??= anything;
  writeCaptured ??= anything;
  Matcher chainMatcher =
      chain is List<String> ? _matchPromotionChain(chain) : wrapMatcher(chain);
  Matcher ofInterestMatcher = ofInterest is List<String>
      ? _matchOfInterestSet(ofInterest)
      : wrapMatcher(ofInterest);
  Matcher assignedMatcher = wrapMatcher(assigned);
  Matcher unassignedMatcher = wrapMatcher(unassigned);
  Matcher writeCapturedMatcher = wrapMatcher(writeCaptured);
  return predicate((VariableModel<Type> model) {
    if (!chainMatcher.matches(model.promotedTypes, {})) return false;
    if (!ofInterestMatcher.matches(model.tested, {})) return false;
    if (!assignedMatcher.matches(model.assigned, {})) return false;
    if (!unassignedMatcher.matches(model.unassigned, {})) return false;
    if (!writeCapturedMatcher.matches(model.writeCaptured, {})) return false;
    return true;
  },
      'VariableModel(chain: ${_describeMatcher(chainMatcher)}, '
      'ofInterest: ${_describeMatcher(ofInterestMatcher)}, '
      'assigned: ${_describeMatcher(assignedMatcher)}, '
      'unassigned: ${_describeMatcher(unassignedMatcher)}, '
      'writeCaptured: ${_describeMatcher(writeCapturedMatcher)})');
}

class _MockNonPromotionReason extends NonPromotionReason {
  @override
  String get documentationLink => fail('Unexpected call to documentationLink');

  String get shortName => fail('Unexpected call to shortName');

  R accept<R, Node extends Object, Variable extends Object,
              Type extends Object>(
          NonPromotionReasonVisitor<R, Node, Variable, Type> visitor) =>
      fail('Unexpected call to accept');
}

extension on FlowModel<Type> {
  FlowModel<Type> _conservativeJoin(FlowAnalysisTestHarness h,
          Iterable<Var> writtenVariables, Iterable<Var> capturedVariables) =>
      conservativeJoin(h, [
        for (Var v in writtenVariables) h.promotionKeyStore.keyForVariable(v)
      ], [
        for (Var v in capturedVariables) h.promotionKeyStore.keyForVariable(v)
      ]);

  FlowModel<Type> _declare(
          FlowAnalysisTestHarness h, Var variable, bool initialized) =>
      this.declare(h.promotionKeyStore.keyForVariable(variable), initialized);

  VariableModel<Type> _infoFor(FlowAnalysisTestHarness h, Var variable) =>
      infoFor(h.promotionKeyStore.keyForVariable(variable));

  ExpressionInfo<Type> _tryMarkNonNullable(
          FlowAnalysisTestHarness h, Var variable) =>
      tryMarkNonNullable(h, _varRefWithType(h, variable));

  ExpressionInfo<Type> _tryPromoteForTypeCheck(
          FlowAnalysisTestHarness h, Var variable, String type) =>
      tryPromoteForTypeCheck(h, _varRefWithType(h, variable), Type(type));

  int _varRef(FlowAnalysisTestHarness h, Var variable) =>
      h.promotionKeyStore.keyForVariable(variable);

  ReferenceWithType<Type> _varRefWithType(
          FlowAnalysisTestHarness h, Var variable) =>
      new ReferenceWithType<Type>(
          _varRef(h, variable),
          variableInfo[h.promotionKeyStore.keyForVariable(variable)]
                  ?.promotedTypes
                  ?.last ??
              variable.type,
          isPromotable: true,
          isThisOrSuper: false);

  FlowModel<Type> _write(
          FlowAnalysisTestHarness h,
          NonPromotionReason? nonPromotionReason,
          Var variable,
          Type writtenType,
          SsaNode<Type> newSsaNode) =>
      write(
          h,
          nonPromotionReason,
          variable,
          h.promotionKeyStore.keyForVariable(variable),
          writtenType,
          newSsaNode,
          h.typeOperations);
}
