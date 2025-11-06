// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' as core;
import 'dart:core';

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_link.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:test/test.dart';

import '../mini_ast.dart';
import '../mini_types.dart';
import 'flow_analysis_mini_ast.dart';

main() {
  late FlowAnalysisTestHarness h;

  setUp(() {
    TypeRegistry.init();
    TypeRegistry.addInterfaceTypeName('A');
    TypeRegistry.addInterfaceTypeName('B');
    TypeRegistry.addInterfaceTypeName('C');
    TypeRegistry.addInterfaceTypeName('D');
    TypeRegistry.addInterfaceTypeName('E');
    TypeRegistry.addInterfaceTypeName('F');
    h = FlowAnalysisTestHarness();
  });

  tearDown(() {
    TypeRegistry.uninit();
  });

  group('API', () {
    test('asExpression_end promotes variables', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        x.as_('int'),
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
      ]);
    });

    test('asExpression_end handles other expressions', () {
      h.run([expr('Object').as_('int')]);
    });

    test("asExpression_end() sets reachability for Never", () {
      // Note: this is handled by the general mechanism that marks control flow
      // as reachable after any expression with static type `Never`.  This is
      // implemented in the flow analysis client, but we test it here anyway as
      // a validation of the "mini AST" logic.
      h.run([
        checkReachable(true),
        expr('int').as_('Never'),
        checkReachable(false),
      ]);
    });

    test('assert_afterCondition promotes', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        assert_(
          x.eq(nullLiteral),
          second(checkPromoted(x, 'int'), expr('String')),
        ),
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
        x.as_('int'),
        z.as_('int'),
        assert_(
          second(
            listLiteral(elementType: 'dynamic', [
              x.write(expr('int?')),
              z.write(expr('int?')),
            ]),
            expr('bool'),
          ).and(x.notEq(nullLiteral).and(y.notEq(nullLiteral))),
        ),
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
        x
            .notEq(nullLiteral)
            .conditional(
              second(checkPromoted(x, 'int'), expr('int')),
              second(checkNotPromoted(x), expr('int')),
            ),
        checkNotPromoted(x),
      ]);
    });

    test('conditional_elseBegin promotes false branch', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x
            .eq(nullLiteral)
            .conditional(
              second(checkNotPromoted(x), expr('Null')),
              second(checkPromoted(x, 'int'), expr('Null')),
            ),
        checkNotPromoted(x),
      ]);
    });

    test(
      'conditional_end keeps promotions common to true and false branches',
      () {
        var x = Var('x');
        var y = Var('y');
        var z = Var('z');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?')),
          declare(z, type: 'int?', initializer: expr('int?')),
          expr('bool').conditional(
            second(
              listLiteral(elementType: 'dynamic', [x.as_('int'), y.as_('int')]),
              expr('Null'),
            ),
            second(
              listLiteral(elementType: 'dynamic', [x.as_('int'), z.as_('int')]),
              expr('Null'),
            ),
          ),
          checkPromoted(x, 'int'),
          checkNotPromoted(y),
          checkNotPromoted(z),
        ]);
      },
    );

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
            x.notEq(nullLiteral).and(y.notEq(nullLiteral)),
            x.notEq(nullLiteral).and(z.notEq(nullLiteral)),
          ),
          [checkPromoted(x, 'int'), checkNotPromoted(y), checkNotPromoted(z)],
        ),
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
            x.eq(nullLiteral).or(y.eq(nullLiteral)),
            x.eq(nullLiteral).or(z.eq(nullLiteral)),
          ),
          [],
          [checkPromoted(x, 'int'), checkNotPromoted(y), checkNotPromoted(z)],
        ),
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
      late SsaNode<SharedTypeView> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(
          x.notEq(nullLiteral),
          [
            checkReachable(true),
            checkPromoted(x, 'int'),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
          [
            checkReachable(true),
            checkNotPromoted(x),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
        ),
      ]);
    });

    test('equalityOp(x != null) when x is non-nullable', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int', initializer: expr('int')),
        if_(
          x.notEq(nullLiteral),
          [checkReachable(true), checkNotPromoted(x)],
          [checkReachable(false), checkNotPromoted(x)],
        ),
      ]);
    });

    test('equalityOp(<expr> == <expr>) has no special effect', () {
      h.run([
        if_(
          expr('int?').eq(expr('int?')),
          [checkReachable(true)],
          [checkReachable(true)],
        ),
      ]);
    });

    test('equalityOp(<expr> != <expr>) has no special effect', () {
      h.run([
        if_(
          expr('int?').notEq(expr('int?')),
          [checkReachable(true)],
          [checkReachable(true)],
        ),
      ]);
    });

    test('equalityOp(x != <null expr>) does not promote', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(
          x.notEq(expr('Null')),
          [checkNotPromoted(x)],
          [checkNotPromoted(x)],
        ),
      ]);
    });

    test('equalityOp(x == null) promotes false branch', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(
          x.eq(nullLiteral),
          [
            checkReachable(true),
            checkNotPromoted(x),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
          [
            checkReachable(true),
            checkPromoted(x, 'int'),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
        ),
      ]);
    });

    test('equalityOp(x == null) when x is an assignment expression', () {
      // int? x;
      // if ((x = <int?>) == null) {
      //   return;
      // }
      // x is promoted to `int`.

      var x = Var('x');
      h.run([
        declare(x, type: 'int?'),
        if_(x.write(expr('int?')).eq(nullLiteral), [return_()]),
        checkPromoted(x, 'int'),
      ]);
    });

    test('equalityOp(x == null) when x is an assignment expression'
        'and inference-update-4 is disabled', () {
      var x = Var('x');
      h.disableInferenceUpdate4();
      h.run([
        declare(x, type: 'int?'),
        if_(x.write(expr('int?')).eq(nullLiteral), [return_()]),
        checkNotPromoted(x),
      ]);
    });

    test('equalityOp(x == null) when x is non-nullable', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int', initializer: expr('int')),
        if_(
          x.eq(nullLiteral),
          [checkReachable(false), checkNotPromoted(x)],
          [checkReachable(true), checkNotPromoted(x)],
        ),
      ]);
    });

    test('equalityOp(null != x) promotes true branch', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(
          nullLiteral.notEq(x),
          [
            checkPromoted(x, 'int'),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
          [
            checkNotPromoted(x),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
        ),
      ]);
    });

    test('equalityOp(<null expr> != x) does not promote', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(
          expr('Null').notEq(x),
          [checkNotPromoted(x)],
          [checkNotPromoted(x)],
        ),
      ]);
    });

    test('equalityOp(null == x) promotes false branch', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(
          nullLiteral.eq(x),
          [
            checkNotPromoted(x),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
          [
            checkPromoted(x, 'int'),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
        ),
      ]);
    });

    test('equalityOp(null == null) equivalent to true', () {
      h.run([
        if_(
          expr('Null').eq(expr('Null')),
          [checkReachable(true)],
          [checkReachable(false)],
        ),
      ]);
    });

    test('equalityOp(null != null) equivalent to false', () {
      h.run([
        if_(
          expr('Null').notEq(expr('Null')),
          [checkReachable(false)],
          [checkReachable(true)],
        ),
      ]);
    });

    test('conditionEqNull() does not promote write-captured vars', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.notEq(nullLiteral), [checkPromoted(x, 'int')]),
        localFunction([x.write(expr('int?'))]),
        if_(x.notEq(nullLiteral), [checkNotPromoted(x)]),
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
      late SsaNode<SharedTypeView> ssaBeforeLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeLoop = nodes[x]!),
        do_([
          getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeLoop))),
          checkNotPromoted(x),
          x.write(expr('Null')),
        ], expr('bool')),
      ]);
    });

    test('doStatement_bodyBegin() handles write captures in the loop', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        do_([
          x.as_('int'),
          // The promotion should have no effect, because the second time
          // through the loop, x has been write-captured.
          checkNotPromoted(x),
          localFunction([x.write(expr('int?'))]),
        ], expr('bool')),
      ]);
    });

    test('doStatement_conditionBegin() joins continue state', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        do_(
          [
            if_(x.notEq(nullLiteral), [continue_()]),
            return_(),
            checkReachable(false),
            checkNotPromoted(x),
          ],
          second(
            listLiteral(elementType: 'dynamic', [
              checkReachable(true),
              checkPromoted(x, 'int'),
            ]),
            expr('bool'),
          ),
        ),
      ]);
    });

    test('doStatement_end() promotes', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        do_(
          [],
          second(checkNotPromoted(x), expr('bool')).or(x.eq(nullLiteral)),
        ),
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
        if_(
          x.property('y').notEq(nullLiteral),
          [checkAssigned(x, true)],
          [checkAssigned(x, true)],
        ),
      ]);
    });

    test('equalityOp_end does not set reachability for `this`', () {
      // Note: sound flow analysis changes this behavior.
      h.disableSoundFlowAnalysis();
      h.thisType = 'C';
      h.addSuperInterfaces('C', (_) => [Type('Object')]);
      h.run([
        if_(this_.is_('Null', isInverted: true), [
          if_(
            this_.eq(nullLiteral),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]),
      ]);
    });

    group('equalityOp_end does not set reachability for property gets', () {
      test('on a variable', () {
        h.addMember('C', 'f', 'Object?');
        var x = Var('x');
        h.run([
          declare(x, type: 'C', initializer: expr('C')),
          if_(x.property('f').is_('Null'), [
            if_(
              x.property('f').eq(nullLiteral),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]),
        ]);
      });

      test('on an arbitrary expression', () {
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(expr('C').property('f').is_('Null'), [
            if_(
              expr('C').property('f').eq(nullLiteral),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]),
        ]);
      });

      test('on explicit this', () {
        h.thisType = 'C';
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(this_.property('f').is_('Null'), [
            if_(
              this_.property('f').eq(nullLiteral),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]),
        ]);
      });

      test('on implicit this/super', () {
        h.thisType = 'C';
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(thisProperty('f').is_('Null'), [
            if_(
              thisProperty('f').eq(nullLiteral),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]),
        ]);
      });
    });

    test('finish checks proper nesting', () {
      var e = expr('Null');
      var s = if_(e, []);
      var flow = FlowAnalysis<Node, Statement, Expression, Var, SharedTypeView>(
        h.typeOperations,
        AssignedVariables<Node, Var>(),
        typeAnalyzerOptions: h.computeTypeAnalyzerOptions(),
      );
      flow.ifStatement_conditionBegin();
      flow.ifStatement_thenBegin(e, s);
      expect(() => flow.finish(), _asserts);
    });

    test('for_conditionBegin() un-promotes', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforeLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeLoop = nodes[x]!),
        for_(
          null,
          second(
            listLiteral(elementType: 'dynamic', [
              checkNotPromoted(x),
              getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeLoop))),
            ]),
            expr('bool'),
          ),
          null,
          [x.write(expr('int?'))],
        ),
      ]);
    });

    test('for_conditionBegin() handles write captures in the loop', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        for_(
          null,
          second(
            listLiteral(elementType: 'dynamic', [
              x.as_('int'),
              checkNotPromoted(x),
              localFunction([x.write(expr('int?'))]),
            ]),
            expr('bool'),
          ),
          null,
          [],
        ),
      ]);
    });

    test('for_bodyBegin() handles empty condition', () {
      h.run([
        for_(null, null, second(checkReachable(true), expr('Null')), []),
        checkReachable(false),
      ]);
    });

    test('for_bodyBegin() promotes', () {
      var x = Var('x');
      h.run([
        for_(
          declare(x, type: 'int?', initializer: expr('int?')),
          x.notEq(nullLiteral),
          null,
          [checkPromoted(x, 'int')],
        ),
      ]);
    });

    test('for_bodyBegin() can be used with a null statement', () {
      // This is needed for collection elements that are for-loops.

      var x = Var('x');
      h.run([
        for_(
          declare(x, type: 'int?', initializer: expr('int?')),
          x.notEq(nullLiteral),
          null,
          [],
          forCollection: true,
        ),
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
          second(
            listLiteral(elementType: 'dynamic', [
              checkPromoted(x, 'int'),
              checkNotPromoted(y),
              checkNotPromoted(z),
            ]),
            expr('Null'),
          ),
          [
            if_(expr('bool'), [x.as_('int'), y.as_('int'), continue_()]),
            x.as_('int'),
            z.as_('int'),
          ],
        ),
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
        for_(null, x.eq(nullLiteral).or(z.eq(nullLiteral)), null, [
          if_(expr('bool'), [x.as_('int'), y.as_('int'), break_()]),
        ]),
        checkPromoted(x, 'int'),
        checkNotPromoted(y),
        checkNotPromoted(z),
      ]);
    });

    test('for_end() with break updates Ssa of modified vars', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<SharedTypeView> xSsaInsideLoop;
      late SsaNode<SharedTypeView> ySsaInsideLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        for_(null, expr('bool'), null, [
          x.write(expr('int?')),
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

    test('for_end() with break updates Ssa of modified vars when types were '
        'tested', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<SharedTypeView> xSsaInsideLoop;
      late SsaNode<SharedTypeView> ySsaInsideLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        for_(null, expr('bool'), null, [
          x.write(expr('int?')),
          if_(expr('bool'), [break_()]),
          if_(x.is_('int'), []),
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
      late SsaNode<SharedTypeView> ssaBeforeLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeLoop = nodes[x]!),
        forEachWithNonVariable(expr('List<int?>'), [
          checkNotPromoted(x),
          getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeLoop))),
          x.write(expr('int?')),
        ]),
      ]);
    });

    test('forEach_bodyBegin() handles write captures in the loop', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        forEachWithNonVariable(expr('List<int?>'), [
          x.as_('int'),
          checkNotPromoted(x),
          localFunction([x.write(expr('int?'))]),
        ]),
      ]);
    });

    test('forEach_bodyBegin() writes to loop variable', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?'),
        checkAssigned(x, false),
        forEachWithVariableSet(x, expr('List<int?>'), [checkAssigned(x, true)]),
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
          if_(x.notEq(nullLiteral), [checkPromoted(x, 'int')]),
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
          break_(), x.write(expr('int')),
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
          x.as_('int'),
          checkPromoted(x, 'int'),
        ]),
        checkNotPromoted(x),
      ]);
    });

    test(
      'functionExpression_begin() cancels promotions of self-captured vars',
      () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?')),
          x.as_('int'),
          y.as_('int'),
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
            x.write(expr('int?')), x.as_('int'),
          ]),
          // x is unpromoted after the local function too
          checkNotPromoted(x), checkPromoted(y, 'int'),
          getSsaNodes((nodes) {
            expect(nodes[x], isNull);
            expect(nodes[y], isNotNull);
          }),
        ]);
      },
    );

    test(
      'functionExpression_begin() cancels promotions of other-captured vars',
      () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?')),
          x.as_('int'), y.as_('int'),
          checkPromoted(x, 'int'), checkPromoted(y, 'int'),
          localFunction([
            // x is unpromoted within the local function, because the write
            // might have been captured by the time the local function executes.
            checkNotPromoted(x), checkPromoted(y, 'int'),
            // And any effort to promote x fails, because there is no way of
            // knowing when the captured write might occur.
            x.as_('int'),
            checkNotPromoted(x), checkPromoted(y, 'int'),
          ]),
          // x is still promoted after the local function, though, because the
          // write hasn't been captured yet.
          checkPromoted(x, 'int'), checkPromoted(y, 'int'),
          localFunction([
            // x is unpromoted inside this local function too.
            checkNotPromoted(x), checkPromoted(y, 'int'),
            x.write(expr('int?')),
          ]),
          // And since the second local function captured x, it remains
          // unpromoted.
          checkNotPromoted(x), checkPromoted(y, 'int'),
        ]);
      },
    );

    test('functionExpression_begin() cancels promotions of written vars', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<SharedTypeView> ssaBeforeFunction;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        x.as_('int'), y.as_('int'),
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
          x.as_('int'),
          checkPromoted(x, 'int'), checkPromoted(y, 'int'),
        ]),
        // x is still promoted after the local function, though, because the
        // write hasn't occurred yet.
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforeFunction))),
        checkPromoted(y, 'int'),
        x.write(expr('int?')),
        // x is unpromoted now.
        checkNotPromoted(x), checkPromoted(y, 'int'),
      ]);
    });

    test('functionExpression_begin() cancels promotions of final vars'
        ' with inference-update-4 disabled', () {
      // See test for "functionExpression_begin() preserves promotions of final
      // variables" for enabled behavior.
      var x = Var('x', isFinal: true);
      h.disableInferenceUpdate4();
      h.run([
        declare(x, type: 'num'),
        if_(expr('bool'), [x.write(expr('int'))], [x.write(expr('double'))]),
        if_(
          x.is_('int'),
          [
            localFunction([checkNotPromoted(x)]),
          ],
          [
            localFunction([checkNotPromoted(x)]),
          ],
        ),
      ]);
    });

    test('functionExpression_begin() cancels promotions of non-final vars', () {
      // num x;
      // if (<bool>) {
      //   x = <int>;
      // } else {
      //   x = <double>;
      // }
      // if (x is int) {
      //   () => x is not promoted
      // } else {
      //   () => x is not promoted
      // }

      var x = Var('x');
      h.run([
        declare(x, type: 'num'),
        if_(expr('bool'), [x.write(expr('int'))], [x.write(expr('double'))]),
        if_(
          x.is_('int'),
          [
            localFunction([checkNotPromoted(x)]),
          ],
          [
            localFunction([checkNotPromoted(x)]),
          ],
        ),
      ]);
    });

    test(
      'functionExpression_begin() preserves promotions of final variables',
      () {
        // final num x;
        // if (<bool>) {
        //   x = <int>;
        // } else {
        //   x = <double>;
        // }
        // if (x is int) {
        //   () => x is promoted to int
        // } else {
        //   () => x is not promoted
        // }

        var x = Var('x', isFinal: true);
        h.run([
          declare(x, type: 'num'),
          if_(expr('bool'), [x.write(expr('int'))], [x.write(expr('double'))]),
          if_(
            x.is_('int'),
            [
              localFunction([checkPromoted(x, 'int')]),
            ],
            [
              localFunction([checkNotPromoted(x)]),
            ],
          ),
        ]);
      },
    );

    test(
      'functionExpression_begin() preserves promotions of initialized vars',
      () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?'), isLate: true),
          x.as_('int'),
          y.as_('int'),
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
          localFunction([
            // x and y remain promoted within the local function, because the
            // assignment that happens implicitly as part of the initialization
            // definitely happens before anything else, and hence the promotions
            // are still valid whenever the local function executes.
            checkPromoted(x, 'int'),
            checkPromoted(y, 'int'),
          ]),
          // x and y remain promoted after the local function too.
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
        ]);
      },
    );

    test('functionExpression_begin() handles not-yet-seen variables', () {
      var x = Var('x');
      h.run([
        localFunction([]),
        // x is declared after the local function, so the local function
        // cannot possibly write to x.
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'), x.write(expr('Null')),
      ]);
    });

    test(
      'functionExpression_begin() handles not-yet-seen write-captured vars',
      () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?')),
          y.as_('int'),
          getSsaNodes((nodes) => expect(nodes[x], isNotNull)),
          localFunction([
            getSsaNodes((nodes) => expect(nodes[x], isNot(nodes[y]))),
            x.as_('int'),
            // Promotion should not occur, because x might be write-captured by
            // the time this code is reached.
            checkNotPromoted(x),
          ]),
          localFunction([x.write(expr('Null'))]),
        ]);
      },
    );

    test('functionExpression_end does not propagate "definitely unassigned" '
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
        x.write(expr('int')),
        checkUnassigned(x, false),
      ]);
    });

    test('handleBreak handles deep nesting', () {
      h.run([
        while_(booleanLiteral(true), [
          if_(expr('bool'), [
            if_(expr('bool'), [break_()]),
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
            if_(expr('bool'), [break_()]),
            break_(),
          ]),
          break_(),
          checkReachable(false),
        ]),
        checkReachable(true),
      ]);
    });

    test('handleBreak handles null target', () {
      h.run([
        while_(booleanLiteral(true), [
          checkReachable(true),
          break_(Label.unbound()),
          checkReachable(false),
        ]),
        checkReachable(false),
      ]);
    });

    test('handleContinue handles deep nesting', () {
      h.run([
        do_([
          if_(expr('bool'), [
            if_(expr('bool'), [continue_()]),
          ]),
          return_(),
          checkReachable(false),
        ], second(checkReachable(true), expr('bool')).or(booleanLiteral(true))),
        checkReachable(false),
      ]);
    });

    test('handleContinue handles mixed nesting', () {
      h.run([
        do_([
          if_(expr('bool'), [
            if_(expr('bool'), [continue_()]),
            continue_(),
          ]),
          continue_(),
          checkReachable(false),
        ], second(checkReachable(true), expr('bool')).or(booleanLiteral(true))),
        checkReachable(false),
      ]);
    });

    test('handleContinue handles null target', () {
      h.run([
        for_(
          null,
          booleanLiteral(true),
          second(checkReachable(false), expr('Object?')),
          [
            checkReachable(true),
            continue_(Label.unbound()),
            checkReachable(false),
          ],
        ),
        checkReachable(false),
      ]);
    });

    test('ifNullExpression allows ensure guarding', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x
            .ifNull(
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  x.write(expr('int')),
                  checkPromoted(x, 'int'),
                ]),
                expr('int?'),
              ),
            )
            .thenStmt(block([checkReachable(true), checkPromoted(x, 'int')])),
      ]);
    });

    test('ifNullExpression allows promotion of tested var', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x
            .ifNull(
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  x.as_('int'),
                  checkPromoted(x, 'int'),
                ]),
                expr('int?'),
              ),
            )
            .thenStmt(block([checkReachable(true), checkPromoted(x, 'int')])),
      ]);
    });

    test('ifNullExpression discards promotions unrelated to tested expr', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        expr('int?')
            .ifNull(
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  x.as_('int'),
                  checkPromoted(x, 'int'),
                ]),
                expr('int?'),
              ),
            )
            .thenStmt(block([checkReachable(true), checkNotPromoted(x)])),
      ]);
    });

    test('ifNullExpression does not detect when RHS is unreachable', () {
      // Note: sound flow analysis changes this behavior.
      h.disableSoundFlowAnalysis();
      h.run([
        expr('int')
            .ifNull(second(checkReachable(true), expr('int')))
            .thenStmt(checkReachable(true)),
      ]);
    });

    test(
      'ifNullExpression determines reachability correctly for `Null` type',
      () {
        h.run([
          expr('Null')
              .ifNull(second(checkReachable(true), expr('Null')))
              .thenStmt(checkReachable(true)),
        ]);
      },
    );

    test(
      'ifNullExpression sets shortcut reachability correctly for `Null` type',
      () {
        h.run([
          expr('Null')
              .ifNull(second(checkReachable(true), throw_(expr('Object'))))
              .thenStmt(checkReachable(false)),
        ]);
      },
    );

    test('ifNullExpression sets shortcut reachability correctly for non-null '
        'type', () {
      // Note: sound flow analysis changes this behavior.
      h.disableSoundFlowAnalysis();
      h.run([
        expr('Object')
            .ifNull(second(checkReachable(true), throw_(expr('Object'))))
            .thenStmt(checkReachable(true)),
      ]);
    });

    test('ifStatement with early exit promotes in unreachable code', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        return_(),
        checkReachable(false),
        if_(x.eq(nullLiteral), [return_()]),
        checkReachable(false),
        checkPromoted(x, 'int'),
      ]);
    });

    test('ifStatement_end(false) keeps else branch if then branch exits', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.eq(nullLiteral), [return_()]),
        checkPromoted(x, 'int'),
      ]);
    });

    test('ifStatement_end() discards non-matching expression info from joined '
        'branches', () {
      var w = Var('w');
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      late SsaNode<SharedTypeView> xSsaNodeBeforeIf;
      h.run([
        declare(w, type: 'Object', initializer: expr('Object')),
        declare(x, type: 'bool', initializer: expr('bool')),
        declare(y, type: 'bool', initializer: expr('bool')),
        declare(z, type: 'bool', initializer: expr('bool')),
        x.write(w.is_('int')),
        getSsaNodes((nodes) {
          xSsaNodeBeforeIf = nodes[x]!;
          expect(xSsaNodeBeforeIf.conditionVariableState, isNotNull);
        }),
        if_(expr('bool'), [y.write(w.is_('String'))], [z.write(w.is_('bool'))]),
        getSsaNodes((nodes) {
          expect(nodes[x], same(xSsaNodeBeforeIf));
          expect(nodes[y]!.conditionVariableState, isNull);
          expect(nodes[z]!.conditionVariableState, isNull);
        }),
      ]);
    });

    test('ifStatement_end() ignores non-matching SSA info from "then" path if '
        'unreachable', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> xSsaNodeBeforeIf;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        getSsaNodes((nodes) {
          xSsaNodeBeforeIf = nodes[x]!;
        }),
        if_(expr('bool'), [x.write(expr('Object')), return_()]),
        getSsaNodes((nodes) {
          expect(nodes[x], same(xSsaNodeBeforeIf));
        }),
      ]);
    });

    test('ifStatement_end() ignores non-matching SSA info from "else" path if '
        'unreachable', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> xSsaNodeBeforeIf;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        getSsaNodes((nodes) {
          xSsaNodeBeforeIf = nodes[x]!;
        }),
        if_(expr('bool'), [], [x.write(expr('Object')), return_()]),
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

    group(
      'initialize() promotes implicitly typed vars to type parameter types',
      () {
        test('when not final', () {
          TypeRegistry.addTypeParameter('T');
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('T&int')),
            checkPromoted(x, 'T&int'),
          ]);
        });

        test('when final', () {
          TypeRegistry.addTypeParameter('T');
          var x = Var('x');
          h.run([
            declare(
              x,
              isFinal: true,
              initializer: expr('T&int'),
              expectInferredType: 'T',
            ),
            checkPromoted(x, 'T&int'),
          ]);
        });
      },
    );

    group("initialize() doesn't promote explicitly typed vars to type "
        'parameter types', () {
      test('when not final', () {
        var x = Var('x');
        TypeRegistry.addTypeParameter('T');
        h.run([
          declare(x, type: 'T', initializer: expr('T&int')),
          checkNotPromoted(x),
        ]);
      });

      test('when final', () {
        var x = Var('x');
        TypeRegistry.addTypeParameter('T');
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
            declare(
              x,
              initializer: expr('Null'),
              expectInferredType: 'dynamic',
            ),
            checkNotPromoted(x),
          ]);
        });

        test('when final', () {
          var x = Var('x');
          h.run([
            declare(
              x,
              isFinal: true,
              initializer: expr('Null'),
              expectInferredType: 'dynamic',
            ),
            checkNotPromoted(x),
          ]);
        });
      },
    );

    test('initialize() stores expressionInfo when not late', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x, type: 'Object', initializer: y.eq(nullLiteral)),
        getSsaNodes((nodes) {
          var info = nodes[x]!.conditionVariableState!;
          var key = h.promotionKeyStore.keyForVariable(y);
          expect(
            info.ifTrue.promotionInfo!.get(h, key)!.promotedTypes,
            isEmpty,
          );
          expect(
            info.ifFalse.promotionInfo!
                .get(h, key)!
                .promotedTypes
                .single
                .unwrapTypeView<Type>()
                .type,
            'int',
          );
        }),
      ]);
    });

    test('initialize() does not store expressionInfo when late', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(
          x,
          isLate: true,
          type: 'Object',
          initializer: y.eq(nullLiteral),
        ),
        getSsaNodes((nodes) {
          expect(nodes[x]!.conditionVariableState, isNull);
        }),
      ]);
    });

    test('initialize() does not store expressionInfo for implicitly typed '
        'vars, pre-bug fix', () {
      h.disableRespectImplicitlyTypedVarInitializers();
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x, initializer: y.eq(nullLiteral), expectInferredType: 'bool'),
        getSsaNodes((nodes) {
          expect(nodes[x]!.conditionVariableState, isNull);
        }),
      ]);
    });

    test('initialize() stores expressionInfo for implicitly typed '
        'vars, post-bug fix', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x, initializer: y.eq(nullLiteral), expectInferredType: 'bool'),
        getSsaNodes((nodes) {
          expect(nodes[x]!.conditionVariableState, isNotNull);
        }),
      ]);
    });

    test('initialize() stores expressionInfo for explicitly typed '
        'vars, pre-bug fix', () {
      h.disableRespectImplicitlyTypedVarInitializers();
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(x, type: 'Object', initializer: y.eq(nullLiteral)),
        getSsaNodes((nodes) {
          expect(nodes[x]!.conditionVariableState, isNotNull);
        }),
      ]);
    });

    test(
      'initialize() does not store expressionInfo for trivial expressions',
      () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(y, type: 'int?', initializer: expr('int?')),
          localFunction([y.write(expr('int?'))]),
          declare(
            x,
            type: 'Object',
            // `y == null` is a trivial expression because y has been write
            // captured.
            initializer: y
                .eq(nullLiteral)
                .getExpressionInfo((info) => expect(info, isNotNull)),
          ),
          getSsaNodes((nodes) {
            expect(nodes[x]!.conditionVariableState, isNull);
          }),
        ]);
      },
    );

    void _checkIs(
      String declaredType,
      String tryPromoteType,
      String? expectedPromotedTypeThen,
      String? expectedPromotedTypeElse, {
      bool inverted = false,
      bool expectedReachableThen = true,
      bool expectedReachableElse = true,
    }) {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforePromotion;
      h.run([
        declare(x, type: declaredType, initializer: expr(declaredType)),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        if_(
          x.is_(tryPromoteType, isInverted: inverted),
          [
            checkReachable(expectedReachableThen),
            checkPromoted(x, expectedPromotedTypeThen),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
          [
            checkReachable(expectedReachableElse),
            checkPromoted(x, expectedPromotedTypeElse),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ],
        ),
      ]);
    }

    test('isExpression_end promotes to a subtype', () {
      _checkIs('int?', 'int', 'int', 'Never?');
    });

    test('isExpression_end promotes to a subtype, inverted', () {
      _checkIs('int?', 'int', 'Never?', 'int', inverted: true);
    });

    test('isExpression_end does not promote to a supertype', () {
      _checkIs('int', 'int?', null, null, expectedReachableElse: false);
    });

    test('isExpression_end does not promote to a supertype, inverted', () {
      _checkIs(
        'int',
        'int?',
        null,
        null,
        inverted: true,
        expectedReachableThen: false,
      );
    });

    test('isExpression_end does not promote to an unrelated type', () {
      _checkIs('int', 'String', null, null);
    });

    test(
      'isExpression_end does not promote to an unrelated type, inverted',
      () {
        _checkIs('int', 'String', null, null, inverted: true);
      },
    );

    test('isExpression_end() does not promote write-captured vars', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.is_('int'), [checkPromoted(x, 'int')]),
        localFunction([x.write(expr('int?'))]),
        if_(x.is_('int'), [checkNotPromoted(x)]),
      ]);
    });

    test('isExpression_end() sets reachability for `this`', () {
      h.thisType = 'C';
      h.run([
        if_(
          this_.is_('Never'),
          [checkReachable(false)],
          [checkReachable(true)],
        ),
      ]);
    });

    group('isExpression_end() sets reachability for property gets', () {
      test('on a variable', () {
        h.addMember('C', 'f', 'Object?');
        var x = Var('x');
        h.run([
          declare(x, type: 'C', initializer: expr('C')),
          if_(
            x.property('f').is_('Never'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test(
        'isExpression_end() variables in assignment expressions are promoted',
        () {
          // num x;
          // if ((x = <int>) is int) {
          //   x is promoted to `int`.
          // }
          // x is not promoted

          var x = Var('x');
          h.run([
            declare(x, type: 'num'),
            if_(x.write(expr('int')).is_('int'), [checkPromoted(x, 'int')]),
            checkNotPromoted(x),
          ]);
        },
      );

      test('isExpression_end() variables in assignment expressions are not'
          ' promoted when inference-update-4 is disabled', () {
        var x = Var('x');
        h.disableInferenceUpdate4();
        h.run([
          declare(x, type: 'num'),
          if_(x.write(expr('int')).is_('int'), [checkNotPromoted(x)]),
          checkNotPromoted(x),
        ]);
      });

      test('on an arbitrary expression', () {
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(
            expr('C').property('f').is_('Never'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('on explicit this', () {
        h.thisType = 'C';
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(
            this_.property('f').is_('Never'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('on implicit this/super', () {
        h.thisType = 'C';
        h.addMember('C', 'f', 'Object?');
        h.run([
          if_(
            thisProperty('f').is_('Never'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    test('isExpression_end() sets reachability for arbitrary exprs', () {
      h.run([
        if_(
          expr('int').is_('Never'),
          [checkReachable(false)],
          [checkReachable(true)],
        ),
      ]);
    });

    test('labeledBlock without break', () {
      var x = Var('x');
      var l = Label('l');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.isNot('int'), [l.thenStmt(return_())]),
        checkPromoted(x, 'int'),
      ]);
    });

    test('labeledBlock with break joins', () {
      var x = Var('x');
      var l = Label('l');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.isNot('int'), [
          l.thenStmt(
            block([
              if_(expr('bool'), [break_(l)]),
              return_(),
            ]),
          ),
        ]),
        checkNotPromoted(x),
      ]);
    });

    test('logicalBinaryOp_rightBegin(isAnd: true) promotes in RHS', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.notEq(nullLiteral).and(second(checkPromoted(x, 'int'), expr('bool'))),
      ]);
    });

    test('logicalBinaryOp_rightEnd(isAnd: true) keeps promotions from RHS', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(expr('bool').and(x.notEq(nullLiteral)), [checkPromoted(x, 'int')]),
      ]);
    });

    test(
      'logicalBinaryOp_rightEnd(isAnd: false) keeps promotions from RHS',
      () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          if_(expr('bool').or(x.eq(nullLiteral)), [], [
            checkPromoted(x, 'int'),
          ]),
        ]);
      },
    );

    test('logicalBinaryOp_rightBegin(isAnd: false) promotes in RHS', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.eq(nullLiteral).or(second(checkPromoted(x, 'int'), expr('bool'))),
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
        if_(x.notEq(nullLiteral).and(y.notEq(nullLiteral)), [
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
        if_(x.eq(nullLiteral).or(y.eq(nullLiteral)), [], [
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
        ]),
      ]);
    });

    test('logicalNot_end() inverts a condition', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(
          x.eq(nullLiteral).not,
          [checkPromoted(x, 'int')],
          [checkNotPromoted(x)],
        ),
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
      late SsaNode<SharedTypeView> ssaBeforePromotion;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        x.nonNullAssert,
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
      ]);
    });

    test('nonNullAssert_end sets reachability if type is `Null`', () {
      // Note: this is handled by the general mechanism that marks control flow
      // as reachable after any expression with static type `Never`.  This is
      // implemented in the flow analysis client, but we test it here anyway as
      // a validation of the "mini AST" logic.
      h.run([expr('Null').nonNullAssert.thenStmt(checkReachable(false))]);
    });

    test('nullAwareAccess temporarily promotes', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforePromotion;
      h.addMember('int', 'f', 'Null Function(Object?)');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforePromotion = nodes[x]!),
        x.invokeMethod('f', [
          listLiteral(elementType: 'dynamic', [
            checkReachable(true),
            checkPromoted(x, 'int'),
            getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
          ]),
        ], isNullAware: true),
        checkNotPromoted(x),
        getSsaNodes((nodes) => expect(nodes[x], same(ssaBeforePromotion))),
      ]);
    });

    test('nullAwareAccess promotes the target of a cascade', () {
      var x = Var('x');
      h.addMember('int', 'f', 'Null Function(Object?)');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.cascade([
          (placeholder) => placeholder.invokeMethod('f', [
            listLiteral(elementType: 'dynamic', [
              checkReachable(true),
              checkPromoted(x, 'int'),
            ]),
          ]),
        ], isNullAware: true),
      ]);
    });

    test('nullAwareAccess preserves demotions', () {
      var x = Var('x');
      h.addMember('int', 'f', 'Null Function(Object?)');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        expr('int').invokeMethod('f', [
          listLiteral(elementType: 'dynamic', [
            checkReachable(true),
            checkPromoted(x, 'int'),
            x.write(expr('int?')),
          ]),
        ], isNullAware: true),
        checkNotPromoted(x),
      ]);
    });

    test('nullAwareAccess sets reachability correctly for `Null` type', () {
      h.addMember('Never', 'f', 'Null Function(Object?)');
      h.run([
        expr(
          'Null',
        ).invokeMethod('f', [checkReachable(false)], isNullAware: true),
        checkReachable(true),
      ]);
    });

    test('parenthesizedExpression preserves promotion behaviors', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.parenthesized.notEq(nullLiteral.parenthesized).parenthesized, [
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
        ifCase(
          expr('num'),
          w.pattern(type: 'int'),
          [x.write(expr('int')), y.write(expr('int'))],
          [y.write(expr('int')), z.write(expr('int'))],
        ),
        checkAssigned(x, false),
        checkAssigned(y, true),
        checkAssigned(z, false),
      ]);
    });

    test('ifCase does not promote when expression true', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        ifCase(x.notEq(nullLiteral), intLiteral(0).pattern, [
          checkNotPromoted(x),
        ]),
      ]);
    });

    test('promote promotes to a subtype and sets type of interest', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'num?', initializer: expr('num?')),
        checkNotPromoted(x),
        x.as_('num'),
        checkPromoted(x, 'num'),
        // Check that it's a type of interest by promoting and de-promoting.
        if_(x.is_('int'), [
          checkPromoted(x, 'int'),
          x.write(expr('num')),
          checkPromoted(x, 'num'),
        ]),
      ]);
    });

    test('promote does not promote to a non-subtype', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'num?', initializer: expr('num?')),
        checkNotPromoted(x),
        x.as_('String'),
        checkNotPromoted(x),
      ]);
    });

    test('promote does not promote if variable is write-captured', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'num?', initializer: expr('num?')),
        checkNotPromoted(x),
        localFunction([x.write(expr('num'))]),
        x.as_('num'),
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

    test('postIncDec() does not store expressionInfo in the write', () {
      // num x;
      // if (x++ is int) {
      //   x is not promoted.
      // }

      var x = Var('x');
      h.run([
        declare(x, type: 'num'),
        if_(
          x
              .postIncDec()
              .is_('int')
              .getExpressionInfo((info) => expect(info, isNull)),
          [checkNotPromoted(x)],
        ),
        checkNotPromoted(x),
      ]);
    });

    test('switchExpression throw in scrutinee makes all cases unreachable', () {
      h.run([
        switchExpr(throw_(expr('C')), [
          intLiteral(
            0,
          ).pattern.thenExpr(second(checkReachable(false), intLiteral(1))),
          default_.thenExpr(second(checkReachable(false), intLiteral(2))),
        ]),
        checkReachable(false),
      ]);
    });

    test('switchExpression throw in case body has isolated effect', () {
      h.run([
        switchExpr(expr('int'), [
          intLiteral(0).pattern.thenExpr(throw_(expr('C'))),
          default_.thenExpr(second(checkReachable(true), intLiteral(2))),
        ]),
        checkReachable(true),
      ]);
    });

    test('switchExpression throw in all case bodies affects flow after', () {
      h.run([
        switchExpr(expr('int'), [
          intLiteral(0).pattern.thenExpr(throw_(expr('C'))),
          default_.thenExpr(throw_(expr('C'))),
        ]),
        checkReachable(false),
      ]);
    });

    test('switchExpression var promotes', () {
      var x = Var('x');
      h.run([
        switchExpr(expr('int'), [
          x
              .pattern(type: 'int?')
              .thenExpr(second(checkPromoted(x, 'int'), nullLiteral)),
        ]),
      ]);
    });

    test('switchStatement throw in scrutinee makes all cases unreachable', () {
      h.run([
        switch_(throw_(expr('int')), [
          intLiteral(0).pattern.then([checkReachable(false)]),
          intLiteral(1).pattern.then([checkReachable(false)]),
        ]),
        checkReachable(false),
      ]);
    });

    test('switchStatement var promotes', () {
      var x = Var('x');
      h.run([
        switch_(expr('int'), [
          x.pattern(type: 'int?').then([checkPromoted(x, 'int')]),
        ]),
      ]);
    });

    test('switchStatement_afterWhen() promotes', () {
      var x = Var('x');
      h.run([
        switch_(expr('num'), [
          x.pattern().when(x.is_('int')).then([checkPromoted(x, 'int')]),
        ]),
      ]);
    });

    test('switchStatement_afterWhen() called for switch expressions', () {
      var x = Var('x');
      h.run([
        switchExpr(expr('num'), [
          x
              .pattern()
              .when(x.is_('int'))
              .thenExpr(second(checkPromoted(x, 'int'), expr('String'))),
        ]),
      ]);
    });

    test('switchStatement_beginCase(false) restores previous promotions', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        switch_(expr('int'), [
          intLiteral(0).pattern.then([
            checkPromoted(x, 'int'),
            x.write(expr('int?')),
            checkNotPromoted(x),
          ]),
          intLiteral(1).pattern.then([
            checkPromoted(x, 'int'),
            x.write(expr('int?')),
            checkNotPromoted(x),
          ]),
        ]),
      ]);
    });

    test('switchStatement_beginCase(false) does not un-promote', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        switch_(expr('int'), [
          intLiteral(0).pattern.then([
            checkPromoted(x, 'int'),
            x.write(expr('int?')),
            checkNotPromoted(x),
          ]),
        ]),
      ]);
    });

    test(
      'switchStatement_beginCase(false) handles write captures in cases',
      () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          x.as_('int'),
          switch_(expr('int'), [
            intLiteral(0).pattern.then([
              checkPromoted(x, 'int'),
              localFunction([x.write(expr('int?'))]),
              checkNotPromoted(x),
            ]),
          ]),
        ]);
      },
    );

    test('switchStatement_beginCase(true) un-promotes', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforeSwitch;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        switch_(
          expr('int').thenStmt(
            block([
              checkPromoted(x, 'int'),
              getSsaNodes((nodes) => ssaBeforeSwitch = nodes[x]!),
            ]),
          ),
          [
            switchStatementMember(
              [intLiteral(0).pattern],
              [
                checkNotPromoted(x),
                getSsaNodes(
                  (nodes) => expect(nodes[x], isNot(ssaBeforeSwitch)),
                ),
                x.write(expr('int?')),
                checkNotPromoted(x),
              ],
              hasLabels: true,
            ),
          ],
        ),
      ]);
    });

    test('switchStatement_beginCase(true) handles write captures in cases', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        switch_(expr('int'), [
          switchStatementMember(
            [intLiteral(0).pattern],
            [
              x.as_('int'),
              checkNotPromoted(x),
              localFunction([x.write(expr('int?'))]),
              checkNotPromoted(x),
            ],
            hasLabels: true,
          ),
        ]),
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
        y.as_('int'),
        z.as_('int'),
        switch_(expr('int'), [
          intLiteral(
            0,
          ).pattern.then([x.as_('int'), y.write(expr('int?')), break_()]),
        ]),
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
        x.as_('int'),
        y.as_('int'),
        z.as_('int'),
        switch_(expr('int'), [
          intLiteral(0).pattern.then([
            w.as_('int'),
            y.as_('int'),
            x.write(expr('int?')),
            break_(),
          ]),
          default_.then([
            w.as_('int'),
            x.as_('int'),
            y.write(expr('int?')),
            break_(),
          ]),
        ]),
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
        switch_(expr('int'), [
          intLiteral(0).pattern.then([x.as_('int'), break_()]),
          default_.then([]),
        ]),
        checkNotPromoted(x),
      ]);
    });

    test('switchStatement_endAlternative() joins branches', () {
      var x1 = Var('x', identity: 'x1');
      var x2 = Var('x', identity: 'x2');
      PatternVariableJoin('x', expectedComponents: [x1, x2]);
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(y, type: 'num'),
        declare(z, type: 'num'),
        switch_(expr('num'), [
          switchStatementMember(
            [
              x1.pattern().when(x1.is_('int').and(y.is_('int'))),
              x2.pattern().when(y.is_('int').and(z.is_('int'))),
            ],
            [
              checkNotPromoted(x2),
              checkPromoted(y, 'int'),
              checkNotPromoted(z),
            ],
          ),
        ]),
      ]);
    });

    test('tryCatchStatement_bodyEnd() restores pre-try state', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        y.as_('int'),
        try_([
          x.as_('int'),
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
        ]).catch_(
          type: 'dynamic',
          body: [checkNotPromoted(x), checkPromoted(y, 'int')],
        ),
      ]);
    });

    test(
      'tryCatchStatement_bodyEnd() un-promotes variables assigned in body',
      () {
        var x = Var('x');
        late SsaNode<SharedTypeView> ssaAfterTry;
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          x.as_('int'),
          checkPromoted(x, 'int'),
          try_([
            x.write(expr('int?')),
            x.as_('int'),
            checkPromoted(x, 'int'),
            getSsaNodes((nodes) => ssaAfterTry = nodes[x]!),
          ]).catch_(
            type: 'dynamic',
            body: [
              checkNotPromoted(x),
              getSsaNodes((nodes) => expect(nodes[x], isNot(ssaAfterTry))),
            ],
          ),
        ]);
      },
    );

    test('tryCatchStatement_bodyEnd() preserves write captures in body', () {
      // Note: it's not necessary for the write capture to survive to the end of
      // the try body, because an exception could occur at any time.  We check
      // this by putting an exit in the try body.

      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        try_([
          localFunction([x.write(expr('int?'))]),
          return_(),
        ]).catch_(type: 'dynamic', body: [x.as_('int'), checkNotPromoted(x)]),
      ]);
    });

    test(
      'tryCatchStatement_catchBegin() restores previous post-body state',
      () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          try_([])
              .catch_(
                type: 'dynamic',
                body: [x.as_('int'), checkPromoted(x, 'int')],
              )
              .catch_(type: 'dynamic', body: [checkNotPromoted(x)]),
        ]);
      },
    );

    test('tryCatchStatement_catchBegin() initializes vars', () {
      var e = Var('e');
      var st = Var('st');
      h.run([
        try_([]).catch_(
          exception: e,
          stackTrace: st,
          body: [checkAssigned(e, true), checkAssigned(st, true)],
        ),
      ]);
    });

    test('Exception variable is promotable', () {
      var e = Var('e');
      h.run([
        try_([]).catch_(
          exception: e,
          body: [checkNotPromoted(e), e.as_('int'), checkPromoted(e, 'int')],
        ),
      ]);
    });

    test('Exception variable is promotable', () {
      var e = Var('e');
      h.run([
        try_([]).catch_(
          type: 'Object',
          exception: e,
          body: [
            e.checkType('Object'),
            checkNotPromoted(e),
            e.as_('String'),
            checkPromoted(e, 'String'),
          ],
        ),
      ]);
    });

    test('StackTrace variable is promotable', () {
      TypeRegistry.addInterfaceTypeName('StackTraceSubtype');
      h.addSuperInterfaces(
        'StackTraceSubtype',
        (_) => [Type('StackTrace'), Type('Object')],
      );
      var e = Var('e');
      var st = Var('st');
      h.run([
        try_([]).catch_(
          exception: e,
          stackTrace: st,
          body: [
            st.checkType('StackTrace'),
            checkNotPromoted(st),
            st.as_('StackTraceSubtype'),
            checkPromoted(st, 'StackTraceSubtype'),
          ],
        ),
      ]);
    });

    test(
      'tryCatchStatement_catchEnd() joins catch state with after-try state',
      () {
        var x = Var('x');
        var y = Var('y');
        var z = Var('z');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?')),
          declare(z, type: 'int?', initializer: expr('int?')),
          try_([
            x.as_('int'),
            y.as_('int'),
          ]).catch_(type: 'dynamic', body: [x.as_('int'), z.as_('int')]),
          // Only x should be promoted, because it's the only variable
          // promoted in both the try body and the catch handler.
          checkPromoted(x, 'int'), checkNotPromoted(y), checkNotPromoted(z),
        ]);
      },
    );

    test('tryCatchStatement_catchEnd() joins catch states', () {
      var x = Var('x');
      var y = Var('y');
      var z = Var('z');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        declare(z, type: 'int?', initializer: expr('int?')),
        try_([return_()])
            .catch_(type: 'dynamic', body: [x.as_('int'), y.as_('int')])
            .catch_(type: 'dynamic', body: [x.as_('int'), z.as_('int')]),
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
        y.as_('int'),
        try_([
          x.as_('int'),
          checkPromoted(x, 'int'),
          checkPromoted(y, 'int'),
        ]).finally_([checkNotPromoted(x), checkPromoted(y, 'int')]),
      ]);
    });

    test('tryFinallyStatement_finallyBegin() un-promotes variables assigned in '
        'body', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaAtStartOfTry;
      late SsaNode<SharedTypeView> ssaAfterTry;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        try_([
          getSsaNodes((nodes) => ssaAtStartOfTry = nodes[x]!),
          x.write(expr('int?')),
          x.as_('int'),
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

    test(
      'tryFinallyStatement_finallyBegin() preserves write captures in body',
      () {
        // Note: it's not necessary for the write capture to survive to the end
        // of the try body, because an exception could occur at any time.  We
        // check this by putting an exit in the try body.

        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          try_([
            localFunction([x.write(expr('int?'))]),
            return_(),
          ]).finally_([x.as_('int'), checkNotPromoted(x)]),
        ]);
      },
    );

    test('tryFinallyStatement_end() restores promotions from try body', () {
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        try_([x.as_('int'), checkPromoted(x, 'int')]).finally_([
          checkNotPromoted(x),
          y.as_('int'),
          checkPromoted(y, 'int'),
        ]),
        // Both x and y should now be promoted.
        checkPromoted(x, 'int'), checkPromoted(y, 'int'),
      ]);
    });

    test('tryFinallyStatement_end() does not restore try body promotions for '
        'variables assigned in finally', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<SharedTypeView> xSsaAtEndOfFinally;
      late SsaNode<SharedTypeView> ySsaAtEndOfFinally;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        try_([x.as_('int'), checkPromoted(x, 'int')]).finally_([
          checkNotPromoted(x),
          x.write(expr('int?')),
          y.write(expr('int?')),
          y.as_('int'),
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
      test('tryFinallyStatement_end() restores SSA nodes from try block when it'
          'is sound to do so', () {
        var x = Var('x');
        var y = Var('y');
        late SsaNode<SharedTypeView> xSsaAtEndOfTry;
        late SsaNode<SharedTypeView> ySsaAtEndOfTry;
        late SsaNode<SharedTypeView> xSsaAtEndOfFinally;
        late SsaNode<SharedTypeView> ySsaAtEndOfFinally;
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?')),
          try_([
            x.write(expr('int?')),
            y.write(expr('int?')),
            getSsaNodes((nodes) {
              xSsaAtEndOfTry = nodes[x]!;
              ySsaAtEndOfTry = nodes[y]!;
            }),
          ]).finally_([
            if_(expr('bool'), [x.write(expr('int?'))]),
            if_(expr('bool'), [y.write(expr('int?')), return_()]),
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

      test('tryFinallyStatement_end() sets unreachable if end of try block '
          'unreachable', () {
        h.run([
          try_([
            return_(),
            checkReachable(false),
          ]).finally_([checkReachable(true)]),
          checkReachable(false),
        ]);
      });

      test('tryFinallyStatement_end() sets unreachable if end of finally block '
          'unreachable', () {
        h.run([
          try_([
            checkReachable(true),
          ]).finally_([return_(), checkReachable(false)]),
          checkReachable(false),
        ]);
      });

      test('tryFinallyStatement_end() handles a variable declared only in the '
          'try block', () {
        var x = Var('x');
        h.run([
          try_([
            declare(x, type: 'int?', initializer: expr('int?')),
          ]).finally_([]),
        ]);
      });

      test('tryFinallyStatement_end() handles a variable declared only in the '
          'finally block', () {
        var x = Var('x');
        h.run([
          try_(
            [],
          ).finally_([declare(x, type: 'int?', initializer: expr('int?'))]),
        ]);
      });

      test('tryFinallyStatement_end() handles a variable that was write '
          'captured in the try block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          try_([
            localFunction([x.write(expr('int?'))]),
          ]).finally_([]),
          if_(x.notEq(nullLiteral), [checkNotPromoted(x)]),
        ]);
      });

      test('tryFinallyStatement_end() handles a variable that was write '
          'captured in the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          try_([]).finally_([
            localFunction([x.write(expr('int?'))]),
          ]),
          if_(x.notEq(nullLiteral), [checkNotPromoted(x)]),
        ]);
      });

      test('tryFinallyStatement_end() handles a variable that was promoted in '
          'the try block and write captured in the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          try_([
            if_(x.eq(nullLiteral), [return_()]),
            checkPromoted(x, 'int'),
          ]).finally_([
            localFunction([x.write(expr('int?'))]),
          ]),
          // The capture in the `finally` cancels old promotions and prevents
          // future promotions.
          checkNotPromoted(x),
          if_(x.notEq(nullLiteral), [checkNotPromoted(x)]),
        ]);
      });

      test('tryFinallyStatement_end() keeps promotions from both try and '
          'finally blocks when there is no write in the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object', initializer: expr('Object')),
          try_([
            if_(x.is_('num', isInverted: true), [return_()]),
            checkPromoted(x, 'num'),
          ]).finally_([
            if_(x.is_('int', isInverted: true), [return_()]),
          ]),
          // The promotion chain now contains both `num` and `int`.
          checkPromoted(x, 'int'),
          x.write(expr('num')),
          checkPromoted(x, 'num'),
        ]);
      });

      test('tryFinallyStatement_end() keeps promotions from the finally block '
          'when there is a write in the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object', initializer: expr('Object')),
          try_([
            if_(x.is_('String', isInverted: true), [return_()]),
            checkPromoted(x, 'String'),
          ]).finally_([
            x.write(expr('Object')),
            if_(x.is_('int', isInverted: true), [return_()]),
          ]),
          checkPromoted(x, 'int'),
        ]);
      });

      test(
        'tryFinallyStatement_end() keeps tests from both the try and finally '
        'blocks',
        () {
          var x = Var('x');
          h.run([
            declare(x, type: 'Object', initializer: expr('Object')),
            try_([
              if_(x.is_('String', isInverted: true), []),
              checkNotPromoted(x),
            ]).finally_([
              if_(x.is_('int', isInverted: true), []),
              checkNotPromoted(x),
            ]),
            checkNotPromoted(x),
            if_(
              expr('bool'),
              [x.write(expr('String')), checkPromoted(x, 'String')],
              [x.write(expr('int')), checkPromoted(x, 'int')],
            ),
          ]);
        },
      );

      test(
        'tryFinallyStatement_end() handles variables not definitely assigned '
        'in either the try or finally block',
        () {
          var x = Var('x');
          h.run([
            declare(x, type: 'Object'),
            checkAssigned(x, false),
            try_([
              if_(expr('bool'), [x.write(expr('Object'))]),
              checkAssigned(x, false),
            ]).finally_([
              if_(expr('bool'), [x.write(expr('Object'))]),
              checkAssigned(x, false),
            ]),
            checkAssigned(x, false),
          ]);
        },
      );

      test('tryFinallyStatement_end() handles variables definitely assigned in '
          'the try block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkAssigned(x, false),
          try_([x.write(expr('Object')), checkAssigned(x, true)]).finally_([
            if_(expr('bool'), [x.write(expr('Object'))]),
            checkAssigned(x, false),
          ]),
          checkAssigned(x, true),
        ]);
      });

      test('tryFinallyStatement_end() handles variables definitely assigned in '
          'the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkAssigned(x, false),
          try_([
            if_(expr('bool'), [x.write(expr('Object'))]),
            checkAssigned(x, false),
          ]).finally_([x.write(expr('Object')), checkAssigned(x, true)]),
          checkAssigned(x, true),
        ]);
      });

      test('tryFinallyStatement_end() handles variables definitely unassigned '
          'in both the try and finally blocks', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkUnassigned(x, true),
          try_([checkUnassigned(x, true)]).finally_([checkUnassigned(x, true)]),
          checkUnassigned(x, true),
        ]);
      });

      test('tryFinallyStatement_end() handles variables definitely unassigned '
          'in the try but not the finally block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkUnassigned(x, true),
          try_([checkUnassigned(x, true)]).finally_([
            if_(expr('bool'), [x.write(expr('Object'))]),
            checkUnassigned(x, false),
          ]),
          checkUnassigned(x, false),
        ]);
      });

      test('tryFinallyStatement_end() handles variables definitely unassigned '
          'in the finally but not the try block', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          checkUnassigned(x, true),
          try_([
            if_(expr('bool'), [x.write(expr('Object'))]),
            checkUnassigned(x, false),
          ]).finally_([checkUnassigned(x, false)]),
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
        z.write(
          x
              .notEq(nullLiteral)
              .conditional(
                booleanLiteral(true),
                y
                    .notEq(nullLiteral)
                    .conditional(booleanLiteral(false), throw_(expr('Object'))),
              ),
        ),
        checkNotPromoted(x),
        checkNotPromoted(y),
        // Simply reading the variable shouldn't promote anything.
        z,
        checkNotPromoted(x),
        checkNotPromoted(y),
        // But reading it in an "if" condition should promote.
        if_(
          z,
          [checkPromoted(x, 'int'), checkNotPromoted(y)],
          [checkNotPromoted(x), checkPromoted(y, 'int')],
        ),
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
        declare(
          z,
          initializer: x
              .notEq(nullLiteral)
              .conditional(
                booleanLiteral(true),
                y
                    .notEq(nullLiteral)
                    .conditional(booleanLiteral(false), throw_(expr('Object'))),
              ),
        ),
        checkNotPromoted(x),
        checkNotPromoted(y),
        // Simply reading the variable shouldn't promote anything.
        z,
        checkNotPromoted(x),
        checkNotPromoted(y),
        // But reading it in an "if" condition should promote.
        if_(
          z,
          [checkPromoted(x, 'int'), checkNotPromoted(y)],
          [checkNotPromoted(x), checkPromoted(y, 'int')],
        ),
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
        z.write(
          x
              .notEq(nullLiteral)
              .conditional(
                booleanLiteral(true),
                y
                    .notEq(nullLiteral)
                    .conditional(booleanLiteral(false), throw_(expr('Object'))),
              ),
        ),
        checkNotPromoted(w),
        checkNotPromoted(x),
        checkNotPromoted(y),
        w.nonNullAssert,
        checkPromoted(w, 'int'),
        // Reading the value of z in an "if" condition should promote x or y,
        // and keep the promotion of w.
        if_(
          z,
          [
            checkPromoted(w, 'int'),
            checkPromoted(x, 'int'),
            checkNotPromoted(y),
          ],
          [
            checkPromoted(w, 'int'),
            checkNotPromoted(x),
            checkPromoted(y, 'int'),
          ],
        ),
      ]);
    });

    test(
      "variableRead() doesn't restore the notion of whether a value is null",
      () {
        // Note: we have the available infrastructure to do this if we want, but
        // we think it will give an inconsistent feel because comparisons like
        // `if (i == null)` *don't* promote.

        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          declare(y, type: 'int?', initializer: expr('int?')),
          y.write(nullLiteral),
          checkNotPromoted(x),
          checkNotPromoted(y),
          if_(
            x.eq(y),
            [checkNotPromoted(x), checkNotPromoted(y)],
            [
              // Even though x != y and y is known to contain the value `null`,
              // we don't promote x.
              checkNotPromoted(x),
              checkNotPromoted(y),
            ],
          ),
        ]);
      },
    );

    test('whileStatement_conditionBegin() un-promotes', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforeLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeLoop = nodes[x]!),
        while_(
          second(
            listLiteral(elementType: 'dynamic', [
              checkNotPromoted(x),
              getSsaNodes((nodes) => expect(nodes[x], isNot(ssaBeforeLoop))),
            ]),
            expr('bool'),
          ),
          [x.write(expr('Null'))],
        ),
      ]);
    });

    test(
      'whileStatement_conditionBegin() handles write captures in the loop',
      () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?', initializer: expr('int?')),
          x.as_('int'),
          checkPromoted(x, 'int'),
          while_(
            second(
              listLiteral(elementType: 'dynamic', [
                x.as_('int'),
                checkNotPromoted(x),
                localFunction([x.write(expr('int?'))]),
              ]),
              expr('bool'),
            ),
            [],
          ),
        ]);
      },
    );

    test('whileStatement_bodyBegin() promotes', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        while_(x.notEq(nullLiteral), [checkPromoted(x, 'int')]),
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
        while_(x.eq(nullLiteral).or(z.eq(nullLiteral)), [
          if_(expr('bool'), [x.as_('int'), y.as_('int'), break_()]),
        ]),
        checkPromoted(x, 'int'),
        checkNotPromoted(y),
        checkNotPromoted(z),
      ]);
    });

    test('whileStatement_end() with break updates Ssa of modified vars', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<SharedTypeView> xSsaInsideLoop;
      late SsaNode<SharedTypeView> ySsaInsideLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        while_(expr('bool'), [
          x.write(expr('int?')),
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

    test('whileStatement_end() with break updates Ssa of modified vars when '
        'types were tested', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<SharedTypeView> xSsaInsideLoop;
      late SsaNode<SharedTypeView> ySsaInsideLoop;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        while_(expr('bool'), [
          x.write(expr('int?')),
          if_(expr('bool'), [break_()]),
          if_(x.is_('int'), []),
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
      late SsaNode<SharedTypeView> ssaBeforeWrite;
      late ExpressionInfo<SharedTypeView> writtenValueInfo;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        declare(y, type: 'int?', initializer: expr('int?')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        getSsaNodes((nodes) => ssaBeforeWrite = nodes[x]!),
        x.write(
          y.eq(nullLiteral).getExpressionInfo((info) {
            expect(info, isNotNull);
            writtenValueInfo = info!;
          }),
        ),
        checkNotPromoted(x),
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(ssaBeforeWrite));
          expect(nodes[x]!.conditionVariableState, same(writtenValueInfo));
        }),
      ]);
    });

    test('write() updates Ssa', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<SharedTypeView> ssaBeforeWrite;
      late ExpressionInfo<SharedTypeView> writtenValueInfo;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        declare(y, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) => ssaBeforeWrite = nodes[x]!),
        x.write(
          y.eq(nullLiteral).getExpressionInfo((info) {
            expect(info, isNotNull);
            writtenValueInfo = info!;
          }),
        ),
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(ssaBeforeWrite));
          expect(nodes[x]!.conditionVariableState, same(writtenValueInfo));
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
      late SsaNode<SharedTypeView> xSsaBeforeWrite;
      late SsaNode<SharedTypeView> ySsa;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        declare(y, type: 'int?', initializer: expr('int?')),
        getSsaNodes((nodes) {
          xSsaBeforeWrite = nodes[x]!;
          ySsa = nodes[y]!;
        }),
        x.write(y),
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(xSsaBeforeWrite));
          expect(nodes[x], isNot(ySsa));
        }),
      ]);
    });

    test('write() does not store expressionInfo for trivial expressions', () {
      var x = Var('x');
      var y = Var('y');
      late SsaNode<SharedTypeView> ssaBeforeWrite;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        declare(y, type: 'int?', initializer: expr('int?')),
        localFunction([y.write(expr('int?'))]),
        getSsaNodes((nodes) => ssaBeforeWrite = nodes[x]!),
        // `y == null` is a trivial expression because y has been write
        // captured.
        x.write(
          y
              .eq(nullLiteral)
              .getExpressionInfo((info) => expect(info, isNotNull)),
        ),
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(ssaBeforeWrite));
          expect(nodes[x]!.conditionVariableState, isNull);
        }),
      ]);
    });

    test('write() permits expression to be null', () {
      var x = Var('x');
      late SsaNode<SharedTypeView> ssaBeforeWrite;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        getSsaNodes((nodes) => ssaBeforeWrite = nodes[x]!),
        x.write(null),
        getSsaNodes((nodes) {
          expect(nodes[x], isNot(ssaBeforeWrite));
          expect(nodes[x]!.conditionVariableState, isNull);
        }),
      ]);
    });

    test('Infinite loop does not implicitly assign variables', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int'),
        while_(booleanLiteral(true), [x.write(expr('Null'))]),
        checkAssigned(x, false),
      ]);
    });

    test('If(false) does not discard promotions', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        x.as_('int'),
        checkPromoted(x, 'int'),
        if_(booleanLiteral(false), [checkPromoted(x, 'int')]),
      ]);
    });

    test('Promotions do not occur when a variable is write-captured', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        localFunction([x.write(expr('Object'))]),
        getSsaNodes((nodes) => expect(nodes[x], isNull)),
        x.as_('int'),
        checkNotPromoted(x),
        getSsaNodes((nodes) => expect(nodes[x], isNull)),
      ]);
    });

    test('Promotion cancellation of write-captured vars survives join', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        if_(
          expr('bool'),
          [
            localFunction([x.write(expr('Object'))]),
          ],
          [
            // Promotion should work here because the write capture is in the
            // other branch.
            x.as_('int'), checkPromoted(x, 'int'),
          ],
        ),
        // But the promotion should be cancelled now, after the join.
        checkNotPromoted(x),
        // And further attempts to promote should fail due to the write capture.
        x.as_('int'), checkNotPromoted(x),
      ]);
    });

    test('issue 47991', () {
      var b = Var('b');
      var i = Var('i');
      h.run([
        localFunction([
          declare(b, type: 'bool', initializer: expr('bool').or(expr('bool'))),
          declare(i, isFinal: true, type: 'int'),
          if_(
            b,
            [checkUnassigned(i, true), i.write(expr('int'))],
            [checkUnassigned(i, true), i.write(expr('int'))],
          ),
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
      var reachableSplitUnreachableUnsplit = reachableSplitUnreachable
          .unsplit();
      expect(reachableSplitUnreachableUnsplit.parent, same(base.parent));
      expect(reachableSplitUnreachableUnsplit.overallReachable, false);
      expect(reachableSplitUnreachableUnsplit.locallyReachable, false);
      var unreachable = base.setUnreachable();
      var unreachableSplit = unreachable.split();
      var unreachableSplitUnsplit = unreachableSplit.unsplit();
      expect(unreachableSplitUnsplit, same(unreachable));
      var unreachableSplitUnreachable = unreachableSplit.setUnreachable();
      var unreachableSplitUnreachableUnsplit = unreachableSplitUnreachable
          .unsplit();
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
        provisionallyUnreachable.parent,
        same(provisionallyReachable.parent),
      );
      expect(provisionallyUnreachable.locallyReachable, false);
      expect(provisionallyUnreachable.overallReachable, false);
      expect(
        provisionallyUnreachable.setUnreachable(),
        same(provisionallyUnreachable),
      );
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
      expect(
        reachable.rebaseForward(unreachablePrevious),
        same(unreachablePrevious),
      );
      expect(
        unreachablePrevious.rebaseForward(reachable).parent,
        same(previous),
      );
      expect(
        unreachablePrevious.rebaseForward(reachable).locallyReachable,
        false,
      );
      expect(reachable.rebaseForward(reachable3), same(reachable3));
      expect(reachable3.rebaseForward(reachable).parent, same(previous));
      expect(reachable3.rebaseForward(reachable).locallyReachable, false);
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
    late Var intVar;
    late Var intQVar;
    late Var objectQVar;
    late Var nullVar;

    setUp(() {
      intVar = Var('x')..type = Type('int');
      intQVar = Var('x')..type = Type('int?');
      objectQVar = Var('x')..type = Type('Object?');
      nullVar = Var('x')..type = Type('Null');
    });

    group('setUnreachable', () {
      var unreachable = FlowModel<SharedTypeView>(
        Reachability.initial.setUnreachable(),
      );
      var reachable = FlowModel<SharedTypeView>(Reachability.initial);
      test('unchanged', () {
        expect(unreachable.setUnreachable(), same(unreachable));
      });

      test('changed', () {
        void _check(FlowModel<SharedTypeView> initial) {
          var s = initial.setUnreachable();
          expect(s, isNot(same(initial)));
          expect(s.reachable.overallReachable, false);
          expect(s.promotionInfo, same(initial.promotionInfo));
        }

        _check(reachable);
      });
    });

    test('split', () {
      var s1 = FlowModel<SharedTypeView>(Reachability.initial);
      var s2 = s1.split();
      expect(s2.reachable.parent, same(s1.reachable));
    });

    test('unsplit', () {
      var s1 = FlowModel<SharedTypeView>(Reachability.initial.split());
      var s2 = s1.unsplit();
      expect(s2.reachable, same(Reachability.initial));
    });

    group('unsplitTo', () {
      test('no change', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial.split());
        var result = s1.unsplitTo(s1.reachable.parent!);
        expect(result, same(s1));
      });

      test('unsplit once, reachable', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial.split());
        var s2 = s1.split();
        var result = s2.unsplitTo(s1.reachable.parent!);
        expect(result.reachable, same(s1.reachable));
      });

      test('unsplit once, unreachable', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial.split());
        var s2 = s1.split().setUnreachable();
        var result = s2.unsplitTo(s1.reachable.parent!);
        expect(result.reachable.locallyReachable, false);
        expect(result.reachable.parent, same(s1.reachable.parent));
      });

      test('unsplit twice, reachable', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial.split());
        var s2 = s1.split();
        var s3 = s2.split();
        var result = s3.unsplitTo(s1.reachable.parent!);
        expect(result.reachable, same(s1.reachable));
      });

      test('unsplit twice, top unreachable', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial.split());
        var s2 = s1.split();
        var s3 = s2.split().setUnreachable();
        var result = s3.unsplitTo(s1.reachable.parent!);
        expect(result.reachable.locallyReachable, false);
        expect(result.reachable.parent, same(s1.reachable.parent));
      });

      test('unsplit twice, previous unreachable', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial.split());
        var s2 = s1.split().setUnreachable();
        var s3 = s2.split();
        var result = s3.unsplitTo(s1.reachable.parent!);
        expect(result.reachable.locallyReachable, false);
        expect(result.reachable.parent, same(s1.reachable.parent));
      });
    });

    group('tryPromoteForTypeCheck', () {
      test('unpromoted -> unchanged (same)', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial);
        var s2 = s1._tryPromoteForTypeCheck(h, intVar, 'int').ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (supertype)', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial);
        var s2 = s1._tryPromoteForTypeCheck(h, intVar, 'Object').ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (unrelated)', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial);
        var s2 = s1._tryPromoteForTypeCheck(h, intVar, 'String').ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> subtype', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial);
        var s2 = s1._tryPromoteForTypeCheck(h, intQVar, 'int').ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(intQVar): _matchVariableModel(
            chain: ['int'],
            ofInterest: ['int'],
          ),
        });
      });

      test('promoted -> unchanged (same)', () {
        var s1 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._tryPromoteForTypeCheck(h, objectQVar, 'int').ifTrue;
        var s2 = s1._tryPromoteForTypeCheck(h, objectQVar, 'int').ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (supertype)', () {
        var s1 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._tryPromoteForTypeCheck(h, objectQVar, 'int').ifTrue;
        var s2 = s1._tryPromoteForTypeCheck(h, objectQVar, 'Object').ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (unrelated)', () {
        var s1 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._tryPromoteForTypeCheck(h, objectQVar, 'int').ifTrue;
        var s2 = s1._tryPromoteForTypeCheck(h, objectQVar, 'String').ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> subtype', () {
        var s1 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._tryPromoteForTypeCheck(h, objectQVar, 'int?').ifTrue;
        var s2 = s1._tryPromoteForTypeCheck(h, objectQVar, 'int').ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['int?', 'int'],
            ofInterest: ['int?', 'int'],
          ),
        });
      });
    });

    group('write', () {
      late Var objectQVar;

      setUp(() {
        objectQVar = Var('x')..type = Type('Object?');
      });

      test('without declaration', () {
        // This should not happen in valid code, but test that we don't crash.

        var s = FlowModel<SharedTypeView>(Reachability.initial)._write(
          h,
          null,
          objectQVar,
          SharedTypeView(Type('Object?')),
          new SsaNode<SharedTypeView>(),
        );
        expect(
          s.promotionInfo?.get(
            h,
            h.promotionKeyStore.keyForVariable(objectQVar),
          ),
          isNull,
        );
      });

      test('unchanged', () {
        var s1 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._declare(h, objectQVar, true);
        var s2 = s1._write(
          h,
          null,
          objectQVar,
          SharedTypeView(Type('Object?')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2, isNot(same(s1)));
        expect(s2.reachable, same(s1.reachable));
        expect(
          s2._infoFor(h, objectQVar),
          _matchVariableModel(
            chain: isEmpty,
            ofInterest: isEmpty,
            assigned: true,
            unassigned: false,
          ),
        );
      });

      test('marks as assigned', () {
        var s1 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._declare(h, objectQVar, false);
        var s2 = s1._write(
          h,
          null,
          objectQVar,
          SharedTypeView(Type('int?')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.reachable.overallReachable, true);
        expect(
          s2._infoFor(h, objectQVar),
          _matchVariableModel(
            chain: isEmpty,
            ofInterest: isEmpty,
            assigned: true,
            unassigned: false,
          ),
        );
      });

      test('un-promotes fully', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        expect(
          s1.promotionInfo.unwrap(h),
          contains(h.promotionKeyStore.keyForVariable(objectQVar)),
        );
        var s2 = s1._write(
          h,
          _MockNonPromotionReason(),
          objectQVar,
          SharedTypeView(Type('int?')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: isEmpty,
            ofInterest: [Type('int')],
            assigned: true,
            unassigned: false,
          ),
        });
      });

      test('un-promotes partially, when no exact match', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        expect(s1.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'int'],
            ofInterest: ['num?', 'int'],
            assigned: true,
            unassigned: false,
          ),
        });
        var s2 = s1._write(
          h,
          _MockNonPromotionReason(),
          objectQVar,
          SharedTypeView(Type('num')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'int'],
            assigned: true,
            unassigned: false,
          ),
        });
      });

      test('un-promotes partially, when exact match', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'num')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        expect(s1.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num', 'int'],
            ofInterest: ['num?', 'num', 'int'],
            assigned: true,
            unassigned: false,
          ),
        });
        var s2 = s1._write(
          h,
          _MockNonPromotionReason(),
          objectQVar,
          SharedTypeView(Type('num')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'num', 'int'],
            assigned: true,
            unassigned: false,
          ),
        });
      });

      test('leaves promoted, when exact match', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'num')
            .ifTrue;
        expect(s1.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'num'],
            assigned: true,
            unassigned: false,
          ),
        });
        var s2 = s1._write(
          h,
          null,
          objectQVar,
          SharedTypeView(Type('num')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo, isNot(same(s1.promotionInfo)));
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'num'],
            assigned: true,
            unassigned: false,
          ),
        });
      });

      test('leaves promoted, when writing a subtype', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'num')
            .ifTrue;
        expect(s1.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'num'],
            assigned: true,
            unassigned: false,
          ),
        });
        var s2 = s1._write(
          h,
          null,
          objectQVar,
          SharedTypeView(Type('int')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo, isNot(same(s1.promotionInfo)));
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'num'],
            assigned: true,
            unassigned: false,
          ),
        });
      });

      group('Promotes to NonNull of a type of interest', () {
        test('when declared type', () {
          var x = Var('x')..type = Type('int?');

          var s1 = FlowModel<SharedTypeView>(
            Reachability.initial,
          )._declare(h, x, true);
          expect(s1.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
              chain: isEmpty,
            ),
          });

          var s2 = s1._write(
            h,
            null,
            x,
            SharedTypeView(Type('int')),
            new SsaNode<SharedTypeView>(),
          );
          expect(s2.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
              chain: ['int'],
            ),
          });
        });

        test('when declared type, if write-captured', () {
          var x = Var('x')..type = Type('int?');

          var s1 = FlowModel<SharedTypeView>(
            Reachability.initial,
          )._declare(h, x, true);
          expect(s1.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
              chain: isEmpty,
            ),
          });

          var s2 = s1._conservativeJoin(h, [], [x]);
          expect(s2.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
              chain: isEmpty,
              writeCaptured: true,
            ),
          });

          // 'x' is write-captured, so not promoted
          var s3 = s2._write(
            h,
            null,
            x,
            SharedTypeView(Type('int')),
            new SsaNode<SharedTypeView>(),
          );
          expect(s3.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
              chain: isEmpty,
              writeCaptured: true,
            ),
          });
        });

        test('when promoted', () {
          var s1 = FlowModel<SharedTypeView>(Reachability.initial)
              ._declare(h, objectQVar, true)
              ._tryPromoteForTypeCheck(h, objectQVar, 'int?')
              .ifTrue;
          expect(s1.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['int?'],
              ofInterest: ['int?'],
            ),
          });
          var s2 = s1._write(
            h,
            null,
            objectQVar,
            SharedTypeView(Type('int')),
            new SsaNode<SharedTypeView>(),
          );
          expect(s2.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['int?', 'int'],
              ofInterest: ['int?'],
            ),
          });
        });

        test('when not promoted', () {
          var s1 = FlowModel<SharedTypeView>(Reachability.initial)
              ._declare(h, objectQVar, true)
              ._tryPromoteForTypeCheck(h, objectQVar, 'int?')
              .ifFalse;
          expect(s1.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['Object'],
              ofInterest: ['int?'],
            ),
          });
          var s2 = s1._write(
            h,
            null,
            objectQVar,
            SharedTypeView(Type('int')),
            new SsaNode<SharedTypeView>(),
          );
          expect(s2.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['Object', 'int'],
              ofInterest: ['int?'],
            ),
          });
        });
      });

      test('Promotes to type of interest when not previously promoted', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifFalse;
        expect(s1.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['Object'],
            ofInterest: ['num?'],
          ),
        });
        var s2 = s1._write(
          h,
          _MockNonPromotionReason(),
          objectQVar,
          SharedTypeView(Type('num?')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?'],
            ofInterest: ['num?'],
          ),
        });
      });

      test('Promotes to type of interest when previously promoted', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, objectQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, objectQVar, 'int?')
            .ifFalse;
        expect(s1.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'int?'],
          ),
        });
        var s2 = s1._write(
          h,
          _MockNonPromotionReason(),
          objectQVar,
          SharedTypeView(Type('int?')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.promotionInfo.unwrap(h), {
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
            h.addSuperInterfaces(
              'C',
              (_) => [Type('B'), Type('A'), Type('Object')],
            );
            h.addSuperInterfaces('B', (_) => [Type('A'), Type('Object')]);
            h.addSuperInterfaces('A', (_) => [Type('Object')]);
          });

          test('; first', () {
            var x = Var('x')..type = Type('Object?');

            var s1 = FlowModel<SharedTypeView>(Reachability.initial)
                ._declare(h, x, true)
                ._tryPromoteForTypeCheck(h, x, 'B?')
                .ifFalse
                ._tryPromoteForTypeCheck(h, x, 'A?')
                .ifFalse;
            expect(s1.promotionInfo.unwrap(h), {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A?', 'B?'],
              ),
            });

            var s2 = s1._write(
              h,
              null,
              x,
              SharedTypeView(Type('C')),
              new SsaNode<SharedTypeView>(),
            );
            expect(s2.promotionInfo.unwrap(h), {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object', 'B'],
                ofInterest: ['A?', 'B?'],
              ),
            });
          });

          test('; second', () {
            var x = Var('x')..type = Type('Object?');

            var s1 = FlowModel<SharedTypeView>(Reachability.initial)
                ._declare(h, x, true)
                ._tryPromoteForTypeCheck(h, x, 'A?')
                .ifFalse
                ._tryPromoteForTypeCheck(h, x, 'B?')
                .ifFalse;
            expect(s1.promotionInfo.unwrap(h), {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A?', 'B?'],
              ),
            });

            var s2 = s1._write(
              h,
              null,
              x,
              SharedTypeView(Type('C')),
              new SsaNode<SharedTypeView>(),
            );
            expect(s2.promotionInfo.unwrap(h), {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object', 'B'],
                ofInterest: ['A?', 'B?'],
              ),
            });
          });

          test('; nullable and non-nullable', () {
            var x = Var('x')..type = Type('Object?');

            var s1 = FlowModel<SharedTypeView>(Reachability.initial)
                ._declare(h, x, true)
                ._tryPromoteForTypeCheck(h, x, 'A')
                .ifFalse
                ._tryPromoteForTypeCheck(h, x, 'A?')
                .ifFalse;
            expect(s1.promotionInfo.unwrap(h), {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A', 'A?'],
              ),
            });

            var s2 = s1._write(
              h,
              null,
              x,
              SharedTypeView(Type('B')),
              new SsaNode<SharedTypeView>(),
            );
            expect(s2.promotionInfo.unwrap(h), {
              h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
                chain: ['Object', 'A'],
                ofInterest: ['A', 'A?'],
              ),
            });
          });
        });

        group('; ambiguous', () {
          test('; no promotion', () {
            var s1 = FlowModel<SharedTypeView>(Reachability.initial)
                ._declare(h, objectQVar, true)
                ._tryPromoteForTypeCheck(h, objectQVar, 'List<Object?>')
                .ifFalse
                ._tryPromoteForTypeCheck(h, objectQVar, 'List<dynamic>')
                .ifFalse;
            expect(s1.promotionInfo.unwrap(h), {
              h.promotionKeyStore.keyForVariable(
                objectQVar,
              ): _matchVariableModel(
                ofInterest: ['List<Object?>', 'List<dynamic>'],
              ),
            });
            var s2 = s1._write(
              h,
              null,
              objectQVar,
              SharedTypeView(Type('List<int>')),
              new SsaNode<SharedTypeView>(),
            );
            // It's ambiguous whether to promote to List<Object?> or
            // List<dynamic>, so we don't promote.
            expect(s2, isNot(same(s1)));
            expect(s2.promotionInfo.unwrap(h), {
              h.promotionKeyStore.keyForVariable(
                objectQVar,
              ): _matchVariableModel(
                ofInterest: ['List<Object?>', 'List<dynamic>'],
              ),
            });
          });
        });

        test('exact match', () {
          var s1 = FlowModel<SharedTypeView>(Reachability.initial)
              ._declare(h, objectQVar, true)
              ._tryPromoteForTypeCheck(h, objectQVar, 'List<Object?>')
              .ifFalse
              ._tryPromoteForTypeCheck(h, objectQVar, 'List<dynamic>')
              .ifFalse;
          expect(s1.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              ofInterest: ['List<Object?>', 'List<dynamic>'],
            ),
          });
          var s2 = s1._write(
            h,
            _MockNonPromotionReason(),
            objectQVar,
            SharedTypeView(Type('List<Object?>')),
            new SsaNode<SharedTypeView>(),
          );
          // It's ambiguous whether to promote to List<Object?> or
          // List<dynamic>, but since the written type is exactly List<Object?>,
          // we use that.
          expect(s2.promotionInfo.unwrap(h), {
            h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
              chain: ['List<Object?>'],
              ofInterest: ['List<Object?>', 'List<dynamic>'],
            ),
          });
        });
      });
    });

    group('demotion, to NonNull', () {
      test('when promoted via test', () {
        var x = Var('x')..type = Type('Object?');

        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, x, true)
            ._tryPromoteForTypeCheck(h, x, 'num?')
            .ifTrue
            ._tryPromoteForTypeCheck(h, x, 'int?')
            .ifTrue;
        expect(s1.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
            chain: ['num?', 'int?'],
            ofInterest: ['num?', 'int?'],
          ),
        });

        var s2 = s1._write(
          h,
          _MockNonPromotionReason(),
          x,
          SharedTypeView(Type('double')),
          new SsaNode<SharedTypeView>(),
        );
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(x): _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'int?'],
          ),
        });
      });
    });

    group('declare', () {
      late Var objectQVar;

      setUp(() {
        objectQVar = Var('x')..type = Type('Object?');
      });

      test('initialized', () {
        var s = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._declare(h, objectQVar, true);
        expect(s.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            assigned: true,
            unassigned: false,
          ),
        });
      });

      test('not initialized', () {
        var s = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._declare(h, objectQVar, false);
        expect(s.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            assigned: false,
            unassigned: true,
          ),
        });
      });
    });

    group('markNonNullable', () {
      test('unpromoted -> unchanged', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial);
        var s2 = s1._tryMarkNonNullable(h, intVar).ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> promoted', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial);
        var s2 = s1._tryMarkNonNullable(h, intQVar).ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(
          s2._infoFor(h, intQVar),
          _matchVariableModel(chain: ['int'], ofInterest: []),
        );
      });

      test('promoted -> unchanged', () {
        var s1 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._tryPromoteForTypeCheck(h, objectQVar, 'int').ifTrue;
        var s2 = s1._tryMarkNonNullable(h, objectQVar).ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> re-promoted', () {
        var s1 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._tryPromoteForTypeCheck(h, objectQVar, 'int?').ifTrue;
        var s2 = s1._tryMarkNonNullable(h, objectQVar).ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['int?', 'int'],
            ofInterest: ['int?'],
          ),
        });
      });

      test('promote to Never', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial);
        var s2 = s1._tryMarkNonNullable(h, nullVar).ifTrue;
        expect(s2.reachable.overallReachable, true);
        expect(
          s2._infoFor(h, nullVar),
          _matchVariableModel(chain: ['Never'], ofInterest: []),
        );
      });
    });

    group('conservativeJoin', () {
      test('unchanged', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, intQVar, true)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue;
        var s2 = s1._conservativeJoin(h, [intQVar], []);
        expect(s2, isNot(same(s1)));
        expect(s2.reachable, same(s1.reachable));
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['int'],
            ofInterest: ['int'],
          ),
          h.promotionKeyStore.keyForVariable(intQVar): _matchVariableModel(
            chain: isEmpty,
            ofInterest: [],
          ),
        });
      });

      test('written', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue
            ._tryPromoteForTypeCheck(h, intQVar, 'int')
            .ifTrue;
        var s2 = s1._conservativeJoin(h, [intQVar], []);
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['int'],
            ofInterest: ['int'],
          ),
          h.promotionKeyStore.keyForVariable(intQVar): _matchVariableModel(
            chain: isEmpty,
            ofInterest: ['int'],
          ),
        });
      });

      test('write captured', () {
        var s1 = FlowModel<SharedTypeView>(Reachability.initial)
            ._tryPromoteForTypeCheck(h, objectQVar, 'int')
            .ifTrue
            ._tryPromoteForTypeCheck(h, intQVar, 'int')
            .ifTrue;
        var s2 = s1._conservativeJoin(h, [], [intQVar]);
        expect(s2.reachable.overallReachable, true);
        expect(s2.promotionInfo.unwrap(h), {
          h.promotionKeyStore.keyForVariable(objectQVar): _matchVariableModel(
            chain: ['int'],
            ofInterest: ['int'],
          ),
          h.promotionKeyStore.keyForVariable(intQVar): _matchVariableModel(
            chain: isEmpty,
            ofInterest: isEmpty,
            unassigned: false,
          ),
        });
      });
    });

    group('rebaseForward', () {
      test('reachability', () {
        var reachable = FlowModel<SharedTypeView>(Reachability.initial);
        var unreachable = reachable.setUnreachable();
        expect(reachable.rebaseForward(h, reachable), same(reachable));
        expect(reachable.rebaseForward(h, unreachable), same(unreachable));
        expect(
          unreachable.rebaseForward(h, reachable).reachable.overallReachable,
          false,
        );
        expect(
          unreachable.rebaseForward(h, reachable).promotionInfo,
          same(unreachable.promotionInfo),
        );
        expect(unreachable.rebaseForward(h, unreachable), same(unreachable));
      });

      test('assignments', () {
        var a = Var('a')..type = Type('int');
        var b = Var('b')..type = Type('int');
        var c = Var('c')..type = Type('int');
        var d = Var('d')..type = Type('int');
        var s0 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, a, false)
            ._declare(h, b, false)
            ._declare(h, c, false)
            ._declare(h, d, false);
        var s1 = s0
            ._write(
              h,
              null,
              a,
              SharedTypeView(Type('int')),
              new SsaNode<SharedTypeView>(),
            )
            ._write(
              h,
              null,
              b,
              SharedTypeView(Type('int')),
              new SsaNode<SharedTypeView>(),
            );
        var s2 = s0
            ._write(
              h,
              null,
              a,
              SharedTypeView(Type('int')),
              new SsaNode<SharedTypeView>(),
            )
            ._write(
              h,
              null,
              c,
              SharedTypeView(Type('int')),
              new SsaNode<SharedTypeView>(),
            );
        var result = s1.rebaseForward(h, s2);
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
        var s0 = FlowModel<SharedTypeView>(Reachability.initial)
            ._declare(h, a, false)
            ._declare(h, b, false)
            ._declare(h, c, false)
            ._declare(h, d, false);
        // In s1, a and b are write captured.  In s2, a and c are.
        var s1 = s0._conservativeJoin(h, [a, b], [a, b]);
        var s2 = s1._conservativeJoin(h, [a, c], [a, c]);
        var result = s1.rebaseForward(h, s2);
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
        var s0 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._declare(h, a, false);
        // In s1, a is write captured.  In s2 it's promoted.
        var s1 = s0._conservativeJoin(h, [a], [a]);
        var s2 = s0._tryPromoteForTypeCheck(h, a, 'int').ifTrue;
        expect(
          s1.rebaseForward(h, s2)._infoFor(h, a),
          _matchVariableModel(writeCaptured: true, chain: isEmpty),
        );
        expect(
          s2.rebaseForward(h, s1)._infoFor(h, a),
          _matchVariableModel(writeCaptured: true, chain: isEmpty),
        );
      });

      test('promotion', () {
        void _check(
          String? thisType,
          String? otherType,
          bool unsafe,
          List<String>? expectedChain,
        ) {
          var x = Var('x')..type = Type('Object?');
          var s0 = FlowModel<SharedTypeView>(
            Reachability.initial,
          )._declare(h, x, true);
          var s1 = s0;
          if (unsafe) {
            s1 = s1._write(
              h,
              null,
              x,
              SharedTypeView(Type('Object?')),
              new SsaNode<SharedTypeView>(),
            );
          }
          if (thisType != null) {
            s1 = s1._tryPromoteForTypeCheck(h, x, thisType).ifTrue;
          }
          var s2 = otherType == null
              ? s0
              : s0._tryPromoteForTypeCheck(h, x, otherType).ifTrue;
          var result = s2.rebaseForward(h, s1);
          if (expectedChain == null) {
            expect(
              result.promotionInfo.unwrap(h),
              contains(h.promotionKeyStore.keyForVariable(x)),
            );
            expect(result._infoFor(h, x).promotedTypes, isEmpty);
          } else {
            expect(
              result
                  ._infoFor(h, x)
                  .promotedTypes
                  .map((t) => t.unwrapTypeView<Type>().type)
                  .toList(),
              expectedChain,
            );
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
        void _checkChain(List<SharedTypeView> chain, List<String> expected) {
          var strings = chain
              .map((t) => t.unwrapTypeView<Type>().type)
              .toList();
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
        void _check(
          List<String> before,
          List<String> inTry,
          List<String> inFinally,
          List<String> expectedResult,
        ) {
          var x = Var('x')..type = Type('Object?');
          var initialModel = FlowModel<SharedTypeView>(
            Reachability.initial,
          )._declare(h, x, true);
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
            finallyModel._infoFor(h, x).promotedTypes,
            expectedFinallyChain,
          );
          var result = tryModel.rebaseForward(h, finallyModel);
          _checkChain(result._infoFor(h, x).promotedTypes, expectedResult);
          // And verify that the inputs are unchanged.
          _checkChain(initialModel._infoFor(h, x).promotedTypes, before);
          _checkChain(tryModel._infoFor(h, x).promotedTypes, expectedTryChain);
          _checkChain(
            finallyModel._infoFor(h, x).promotedTypes,
            expectedFinallyChain,
          );
        }

        _check(
          ['Object'],
          ['num', 'int'],
          ['Iterable<dynamic>', 'List<dynamic>'],
          ['Object', 'Iterable<dynamic>', 'List<dynamic>'],
        );
        _check([], ['num', 'int'], ['Iterable<dynamic>', 'List<dynamic>'], [
          'Iterable<dynamic>',
          'List<dynamic>',
        ]);
        _check(['Object'], [], ['Iterable<dynamic>', 'List<dynamic>'], [
          'Object',
          'Iterable<dynamic>',
          'List<dynamic>',
        ]);
        _check(
          [],
          [],
          ['Iterable<dynamic>', 'List<dynamic>'],
          ['Iterable<dynamic>', 'List<dynamic>'],
        );
        _check(['Object'], ['num', 'int'], [], ['Object', 'num', 'int']);
        _check([], ['num', 'int'], [], ['num', 'int']);
        _check(['Object'], [], [], ['Object']);
        _check([], [], [], []);
        _check([], ['num', 'int'], ['Object', 'Iterable<dynamic>'], [
          'Object',
          'Iterable<dynamic>',
        ]);
        _check([], ['num', 'int'], ['Object'], ['Object', 'num', 'int']);
        _check([], ['Object', 'Iterable<dynamic>'], ['num', 'int'], [
          'num',
          'int',
        ]);
        _check([], ['Object'], ['num', 'int'], ['num', 'int']);
        _check([], ['num'], ['Object', 'int'], ['Object', 'int']);
        _check([], ['int'], ['Object', 'num'], ['Object', 'num', 'int']);
        _check([], ['Object', 'int'], ['num'], ['num', 'int']);
        _check([], ['Object', 'num'], ['int'], ['int']);
      });

      test('types of interest', () {
        var a = Var('a')..type = Type('Object');
        var s0 = FlowModel<SharedTypeView>(
          Reachability.initial,
        )._declare(h, a, false);
        var s1 = s0._tryPromoteForTypeCheck(h, a, 'int').ifFalse;
        var s2 = s0._tryPromoteForTypeCheck(h, a, 'String').ifFalse;
        expect(
          s1.rebaseForward(h, s2)._infoFor(h, a),
          _matchVariableModel(ofInterest: ['int', 'String']),
        );
        expect(
          s2.rebaseForward(h, s1)._infoFor(h, a),
          _matchVariableModel(ofInterest: ['int', 'String']),
        );
      });

      test('variable present in one state but not the other', () {
        var x = Var('x')..type = Type('Object?');
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._declare(h, x, true);
        expect(s1.rebaseForward(h, s0), same(s1));
        expect(s0.rebaseForward(h, s1), same(s1));
      });
    });
  });

  group('joinPromotionChains', () {
    late Type doubleType;
    late Type intType;
    late Type numType;
    late Type objectType;

    setUp(() {
      doubleType = Type('double');
      intType = Type('int');
      numType = Type('num');
      objectType = Type('Object');
    });

    test('should handle empty promotion chains', () {
      expect(
        PromotionModel.joinPromotedTypes(<Type>[], <Type>[], h.typeOperations),
        isEmpty,
      );
      expect(
        PromotionModel.joinPromotedTypes(<Type>[], [intType], h.typeOperations),
        isEmpty,
      );
      expect(
        PromotionModel.joinPromotedTypes([intType], <Type>[], h.typeOperations),
        isEmpty,
      );
    });

    test('should return empty list if there are no common types', () {
      expect(
        PromotionModel.joinPromotedTypes(
          [intType],
          [doubleType],
          h.typeOperations,
        ),
        isEmpty,
      );
    });

    test('should return common prefix if there are common types', () {
      expect(
        PromotionModel.joinPromotedTypes(
          [SharedTypeView(objectType), SharedTypeView(intType)],
          [SharedTypeView(objectType), SharedTypeView(doubleType)],
          h.typeOperations,
        ),
        _matchPromotionChain(['Object']),
      );
      expect(
        PromotionModel.joinPromotedTypes(
          [
            SharedTypeView(objectType),
            SharedTypeView(numType),
            SharedTypeView(intType),
          ],
          [
            SharedTypeView(objectType),
            SharedTypeView(numType),
            SharedTypeView(doubleType),
          ],
          h.typeOperations,
        ),
        _matchPromotionChain(['Object', 'num']),
      );
    });

    test('should return an input if it is a prefix of the other', () {
      var prefix = [objectType, numType];
      var largerChain = [objectType, numType, intType];
      expect(
        PromotionModel.joinPromotedTypes(prefix, largerChain, h.typeOperations),
        same(prefix),
      );
      expect(
        PromotionModel.joinPromotedTypes(largerChain, prefix, h.typeOperations),
        same(prefix),
      );
      expect(
        PromotionModel.joinPromotedTypes(prefix, prefix, h.typeOperations),
        same(prefix),
      );
    });

    test('should intersect', () {
      // F <: E <: D <: C <: B <: A
      var A = Type('A');
      var B = Type('B');
      var C = Type('C');
      var D = Type('D');
      var E = Type('E');
      var F = Type('F');
      h.addSuperInterfaces(
        'F',
        (_) => [
          Type('E'),
          Type('D'),
          Type('C'),
          Type('B'),
          Type('A'),
          Type('Object'),
        ],
      );
      h.addSuperInterfaces(
        'E',
        (_) => [Type('D'), Type('C'), Type('B'), Type('A'), Type('Object')],
      );
      h.addSuperInterfaces(
        'D',
        (_) => [Type('C'), Type('B'), Type('A'), Type('Object')],
      );
      h.addSuperInterfaces('C', (_) => [Type('B'), Type('A'), Type('Object')]);
      h.addSuperInterfaces('B', (_) => [Type('A'), Type('Object')]);
      h.addSuperInterfaces('A', (_) => [Type('Object')]);

      void check(
        List<SharedTypeView> chain1,
        List<SharedTypeView> chain2,
        Matcher matcher,
      ) {
        expect(
          PromotionModel.joinPromotedTypes(chain1, chain2, h.typeOperations),
          matcher,
        );

        expect(
          PromotionModel.joinPromotedTypes(chain2, chain1, h.typeOperations),
          matcher,
        );
      }

      {
        var chain1 = [SharedTypeView(A), SharedTypeView(B), SharedTypeView(C)];
        var chain2 = [SharedTypeView(A), SharedTypeView(C)];
        check(chain1, chain2, same(chain2));
      }

      check(
        [
          SharedTypeView(A),
          SharedTypeView(B),
          SharedTypeView(C),
          SharedTypeView(F),
        ],
        [
          SharedTypeView(A),
          SharedTypeView(D),
          SharedTypeView(E),
          SharedTypeView(F),
        ],
        _matchPromotionChain(['A', 'F']),
      );

      check(
        [
          SharedTypeView(A),
          SharedTypeView(B),
          SharedTypeView(E),
          SharedTypeView(F),
        ],
        [
          SharedTypeView(A),
          SharedTypeView(C),
          SharedTypeView(D),
          SharedTypeView(F),
        ],
        _matchPromotionChain(['A', 'F']),
      );

      check(
        [SharedTypeView(A), SharedTypeView(C), SharedTypeView(E)],
        [SharedTypeView(B), SharedTypeView(C), SharedTypeView(D)],
        _matchPromotionChain(['C']),
      );

      check(
        [
          SharedTypeView(A),
          SharedTypeView(C),
          SharedTypeView(E),
          SharedTypeView(F),
        ],
        [
          SharedTypeView(B),
          SharedTypeView(C),
          SharedTypeView(D),
          SharedTypeView(F),
        ],
        _matchPromotionChain(['C', 'F']),
      );

      check(
        [SharedTypeView(A), SharedTypeView(B), SharedTypeView(C)],
        [SharedTypeView(A), SharedTypeView(B), SharedTypeView(D)],
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
      expect(PromotionModel.joinTested(s1, s2), expected);
      expect(PromotionModel.joinTested(s2, s1), expected);
    });

    test('common prefix', () {
      var s1 = _makeTypes(['double', 'int', 'String']);
      var s2 = _makeTypes(['double', 'int', 'bool']);
      var expected = _matchOfInterestSet(['double', 'int', 'String', 'bool']);
      expect(PromotionModel.joinTested(s1, s2), expected);
      expect(PromotionModel.joinTested(s2, s1), expected);
    });

    test('order mismatch', () {
      var s1 = _makeTypes(['double', 'int']);
      var s2 = _makeTypes(['int', 'double']);
      var expected = _matchOfInterestSet(['double', 'int']);
      expect(PromotionModel.joinTested(s1, s2), expected);
      expect(PromotionModel.joinTested(s2, s1), expected);
    });

    test('small common prefix', () {
      var s1 = _makeTypes(['int', 'double', 'String', 'bool']);
      var s2 = _makeTypes(['int', 'List', 'bool', 'Future']);
      var expected = _matchOfInterestSet([
        'int',
        'double',
        'String',
        'bool',
        'List',
        'Future',
      ]);
      expect(PromotionModel.joinTested(s1, s2), expected);
      expect(PromotionModel.joinTested(s2, s1), expected);
    });
  });

  group('join', () {
    late int x;
    late int y;
    late int z;
    late int w;
    late Type intType;
    late Type intQType;
    late Type stringType;

    setUp(() {
      x = h.promotionKeyStore.keyForVariable(Var('x')..type = Type('Object?'));
      y = h.promotionKeyStore.keyForVariable(Var('y')..type = Type('Object?'));
      z = h.promotionKeyStore.keyForVariable(Var('z')..type = Type('Object?'));
      w = h.promotionKeyStore.keyForVariable(Var('w')..type = Type('Object?'));
      intType = Type('int');
      intQType = Type('int?');
      stringType = Type('String');
    });

    PromotionModel<SharedTypeView> model(
      List<SharedTypeView> promotionChain, {
      List<SharedTypeView>? typesOfInterest,
      bool assigned = false,
    }) => PromotionModel<SharedTypeView>(
      promotedTypes: promotionChain,
      tested: typesOfInterest ?? promotionChain,
      assigned: assigned,
      unassigned: !assigned,
      ssaNode: new SsaNode<SharedTypeView>(),
    );

    group('without input reuse', () {
      test('promoted with unpromoted', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._setInfo(h, {
          x: model([SharedTypeView(intType)]),
          y: model(const []),
        });
        var s2 = s0._setInfo(h, {
          x: model(const []),
          y: model([SharedTypeView(intType)]),
        });
        expect(FlowModel.joinPromotionInfo(h, s1, s2).promotionInfo.unwrap(h), {
          x: _matchVariableModel(chain: isEmpty, ofInterest: ['int']),
          y: _matchVariableModel(chain: isEmpty, ofInterest: ['int']),
        });
      });
    });
    group('should re-use an input if possible', () {
      test('identical inputs', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._setInfo(h, {
          x: model([SharedTypeView(intType)]),
          y: model([SharedTypeView(stringType)]),
        });
        expect(FlowModel.joinPromotionInfo(h, s1, s1), same(s1));
      });

      test('one input empty', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._setInfo(h, {
          x: model([SharedTypeView(intType)]),
          y: model([SharedTypeView(stringType)]),
        });
        var s2 = s0;
        const Null expected = null;
        expect(
          FlowModel.joinPromotionInfo(h, s1, s2).promotionInfo,
          same(expected),
        );
        expect(
          FlowModel.joinPromotionInfo(h, s2, s1).promotionInfo,
          same(expected),
        );
      });

      test('promoted with unpromoted', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._setInfo(h, {
          x: model([SharedTypeView(intType)]),
        });
        var s2 = s0._setInfo(h, {x: model(const [])});
        var expected = {
          x: _matchVariableModel(chain: isEmpty, ofInterest: ['int']),
        };
        expect(
          FlowModel.joinPromotionInfo(h, s1, s2).promotionInfo.unwrap(h),
          expected,
        );
        expect(
          FlowModel.joinPromotionInfo(h, s2, s1).promotionInfo.unwrap(h),
          expected,
        );
      });

      test('related type chains', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._setInfo(h, {
          x: model([SharedTypeView(intQType), SharedTypeView(intType)]),
        });
        var s2 = s0._setInfo(h, {
          x: model([SharedTypeView(intQType)]),
        });
        var expected = {
          x: _matchVariableModel(chain: ['int?'], ofInterest: ['int?', 'int']),
        };
        expect(
          FlowModel.joinPromotionInfo(h, s1, s2).promotionInfo.unwrap(h),
          expected,
        );
        expect(
          FlowModel.joinPromotionInfo(h, s2, s1).promotionInfo.unwrap(h),
          expected,
        );
      });

      test('unrelated type chains', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._setInfo(h, {
          x: model([SharedTypeView(intType)]),
        });
        var s2 = s0._setInfo(h, {
          x: model([SharedTypeView(stringType)]),
        });
        var expected = {
          x: _matchVariableModel(chain: isEmpty, ofInterest: ['String', 'int']),
        };
        expect(
          FlowModel.joinPromotionInfo(h, s1, s2).promotionInfo.unwrap(h),
          expected,
        );
        expect(
          FlowModel.joinPromotionInfo(h, s2, s1).promotionInfo.unwrap(h),
          expected,
        );
      });

      test('sub-map', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var xModel = model([SharedTypeView(intType)]);
        var s1 = s0._setInfo(h, {
          x: xModel,
          y: model([SharedTypeView(stringType)]),
        });
        var s2 = s0._setInfo(h, {x: xModel});
        var expected = {x: xModel};
        expect(
          FlowModel.joinPromotionInfo(h, s1, s2).promotionInfo.unwrap(h),
          expected,
        );
        expect(
          FlowModel.joinPromotionInfo(h, s2, s1).promotionInfo.unwrap(h),
          expected,
        );
      });

      test('sub-map with matched subtype', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._setInfo(h, {
          x: model([SharedTypeView(intQType), SharedTypeView(intType)]),
          y: model([SharedTypeView(stringType)]),
        });
        var s2 = s0._setInfo(h, {
          x: model([SharedTypeView(intQType)]),
        });
        var expected = {
          x: _matchVariableModel(chain: ['int?'], ofInterest: ['int?', 'int']),
        };
        expect(
          FlowModel.joinPromotionInfo(h, s1, s2).promotionInfo.unwrap(h),
          expected,
        );
        expect(
          FlowModel.joinPromotionInfo(h, s2, s1).promotionInfo.unwrap(h),
          expected,
        );
      });

      test('sub-map with mismatched subtype', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var s1 = s0._setInfo(h, {
          x: model([SharedTypeView(intQType)]),
          y: model([SharedTypeView(stringType)]),
        });
        var s2 = s0._setInfo(h, {
          x: model([SharedTypeView(intQType), SharedTypeView(intType)]),
        });
        var expected = {
          x: _matchVariableModel(chain: ['int?'], ofInterest: ['int?', 'int']),
        };
        expect(
          FlowModel.joinPromotionInfo(h, s1, s2).promotionInfo.unwrap(h),
          expected,
        );
        expect(
          FlowModel.joinPromotionInfo(h, s2, s1).promotionInfo.unwrap(h),
          expected,
        );
      });

      test('assigned', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var unassigned = model(const [], assigned: false);
        var assigned = model(const [], assigned: true);
        var s1 = s0._setInfo(h, {
          x: assigned,
          y: assigned,
          z: unassigned,
          w: unassigned,
        });
        var s2 = s0._setInfo(h, {
          x: assigned,
          y: unassigned,
          z: assigned,
          w: unassigned,
        });
        var joined = FlowModel.joinPromotionInfo(h, s1, s2);
        expect(joined.promotionInfo.unwrap(h), {
          x: same(assigned),
          y: _matchVariableModel(
            chain: isEmpty,
            assigned: false,
            unassigned: false,
          ),
          z: _matchVariableModel(
            chain: isEmpty,
            assigned: false,
            unassigned: false,
          ),
          w: same(unassigned),
        });
      });

      test('write captured', () {
        var s0 = FlowModel<SharedTypeView>(Reachability.initial);
        var intQModel = model([SharedTypeView(intQType)]);
        var writeCapturedModel = intQModel.writeCapture();
        var s1 = s0._setInfo(h, {
          x: writeCapturedModel,
          y: writeCapturedModel,
          z: intQModel,
          w: intQModel,
        });
        var s2 = s0._setInfo(h, {
          x: writeCapturedModel,
          y: intQModel,
          z: writeCapturedModel,
          w: intQModel,
        });
        var joined = FlowModel.joinPromotionInfo(h, s1, s2);
        expect(joined.promotionInfo.unwrap(h), {
          x: same(writeCapturedModel),
          y: same(writeCapturedModel),
          z: same(writeCapturedModel),
          w: same(intQModel),
        });
      });
    });
  });

  group('inheritTested', () {
    late int x;
    late Type intType;
    late Type stringType;

    setUp(() {
      x = h.promotionKeyStore.keyForVariable(Var('x')..type = Type('Object?'));
      intType = Type('int');
      stringType = Type('String');
    });

    PromotionModel<SharedTypeView> model(
      List<SharedTypeView> typesOfInterest,
    ) => PromotionModel<SharedTypeView>(
      promotedTypes: const [],
      tested: typesOfInterest,
      assigned: true,
      unassigned: false,
      ssaNode: new SsaNode<SharedTypeView>(),
    );

    test('inherits types of interest from other', () {
      var m0 = FlowModel<SharedTypeView>(Reachability.initial);
      var m1 = m0._setInfo(h, {
        x: model([SharedTypeView(intType)]),
      });
      var m2 = m0._setInfo(h, {
        x: model([SharedTypeView(stringType)]),
      });
      expect(
        m1.inheritTested(h, m2).promotionInfo!.get(h, x)!.tested,
        _matchOfInterestSet(['int', 'String']),
      );
    });

    test('handles variable missing from other', () {
      var m0 = FlowModel<SharedTypeView>(Reachability.initial);
      var m1 = m0._setInfo(h, {
        x: model([SharedTypeView(intType)]),
      });
      var m2 = m0;
      expect(m1.inheritTested(h, m2), same(m1));
    });

    test('returns identical model when no changes', () {
      var m0 = FlowModel<SharedTypeView>(Reachability.initial);
      var m1 = m0._setInfo(h, {
        x: model([SharedTypeView(intType)]),
      });
      var m2 = m0._setInfo(h, {
        x: model([SharedTypeView(intType)]),
      });
      expect(m1.inheritTested(h, m2), same(m1));
    });
  });

  group('why not promoted', () {
    test('due to assignment', () {
      var x = Var('x');
      late Expression writeExpression;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.eq(nullLiteral), [return_()]),
        checkPromoted(x, 'int'),
        (writeExpression = x.write(expr('int?'))),
        checkNotPromoted(x),
        x.whyNotPromoted((reasons) {
          expect(reasons.keys, unorderedEquals([Type('int')]));
          var nonPromotionReason =
              reasons.values.single as DemoteViaExplicitWrite<Var>;
          expect(nonPromotionReason.node, same(writeExpression));
          expect(
            nonPromotionReason.documentationLink,
            NonPromotionDocumentationLink.write,
          );
        }),
      ]);
    });

    test('due to assignment, multiple demotions', () {
      var x = Var('x');
      late Expression writeExpression;
      h.run([
        declare(x, type: 'Object?', initializer: expr('Object?')),
        if_(x.isNot('int?'), [return_()]),
        if_(x.eq(nullLiteral), [return_()]),
        checkPromoted(x, 'int'),
        (writeExpression = x.write(expr('Object?'))),
        checkNotPromoted(x),
        x.whyNotPromoted((reasons) {
          expect(reasons.keys, unorderedEquals([Type('int'), Type('int?')]));
          for (var type in [
            SharedTypeView(Type('int')),
            SharedTypeView(Type('int?')),
          ]) {
            var nonPromotionReason =
                reasons[type] as DemoteViaExplicitWrite<Var>;
            expect(nonPromotionReason.node, same(writeExpression));
            expect(
              nonPromotionReason.documentationLink,
              NonPromotionDocumentationLink.write,
            );
          }
        }),
      ]);
    });

    test('due to pattern assignment', () {
      var x = Var('x');
      late Pattern writePattern;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.eq(nullLiteral), [return_()]),
        checkPromoted(x, 'int'),
        (writePattern = x.pattern()).assign(expr('int?')),
        checkNotPromoted(x),
        x.whyNotPromoted((reasons) {
          expect(reasons.keys, unorderedEquals([Type('int')]));
          var nonPromotionReason =
              reasons.values.single as DemoteViaExplicitWrite<Var>;
          expect(nonPromotionReason.node, same(writePattern));
          expect(
            nonPromotionReason.documentationLink,
            NonPromotionDocumentationLink.write,
          );
        }),
      ]);
    });

    test('preserved in join when one branch unreachable', () {
      var x = Var('x');
      late Expression writeExpression;
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.eq(nullLiteral), [return_()]),
        checkPromoted(x, 'int'),
        (writeExpression = x.write(expr('int?'))),
        checkNotPromoted(x),
        if_(expr('bool'), [return_()]),
        x.whyNotPromoted((reasons) {
          expect(reasons.keys, unorderedEquals([Type('int')]));
          var nonPromotionReason =
              reasons.values.single as DemoteViaExplicitWrite<Var>;
          expect(nonPromotionReason.node, same(writeExpression));
          expect(
            nonPromotionReason.documentationLink,
            NonPromotionDocumentationLink.write,
          );
        }),
      ]);
    });

    test('preserved in later promotions', () {
      var x = Var('x');
      late Expression writeExpression;
      h.run([
        declare(x, type: 'Object', initializer: expr('Object')),
        if_(x.is_('int', isInverted: true), [return_()]),
        checkPromoted(x, 'int'),
        (writeExpression = x.write(expr('Object'))),
        checkNotPromoted(x),
        if_(x.is_('num', isInverted: true), [return_()]),
        checkPromoted(x, 'num'),
        x.whyNotPromoted((reasons) {
          var nonPromotionReason =
              reasons[SharedTypeView(Type('int'))]
                  as DemoteViaExplicitWrite<Var>;
          expect(nonPromotionReason.node, same(writeExpression));
          expect(
            nonPromotionReason.documentationLink,
            NonPromotionDocumentationLink.write,
          );
        }),
      ]);
    });

    test('re-promotion', () {
      var x = Var('x');
      h.run([
        declare(x, type: 'int?', initializer: expr('int?')),
        if_(x.eq(nullLiteral), [return_()]),
        checkPromoted(x, 'int'),
        x.write(expr('int?')),
        checkNotPromoted(x),
        if_(x.eq(nullLiteral), [return_()]),
        checkPromoted(x, 'int'),
        x.whyNotPromoted((reasons) {
          expect(reasons, isEmpty);
        }),
      ]);
    });

    group('field promotion disabled', () {
      test('via explicit this', () {
        h.disableFieldPromotion();
        h.thisType = 'C';
        h.addMember('C', '_field', 'Object?', promotable: true);
        h.run([
          if_(this_.property('_field').eq(nullLiteral), [return_()]),
          this_.property('_field').whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('Object')]));
            var nonPromotionReason =
                reasons.values.single
                    as PropertyNotPromotedForNonInherentReason;
            expect(nonPromotionReason.fieldPromotionEnabled, false);
          }),
        ]);
      });

      test('via implicit this/super', () {
        h.disableFieldPromotion();
        h.thisType = 'C';
        h.addMember('C', '_field', 'Object?', promotable: true);
        h.run([
          if_(thisProperty('_field').eq(nullLiteral), [return_()]),
          thisProperty('_field').whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('Object')]));
            var nonPromotionReason =
                reasons.values.single
                    as PropertyNotPromotedForNonInherentReason;
            expect(nonPromotionReason.fieldPromotionEnabled, false);
          }),
        ]);
      });

      test('via variable', () {
        h.disableFieldPromotion();
        h.addMember('C', '_field', 'Object?', promotable: true);
        var x = Var('x');
        h.run([
          declare(x, type: 'C', initializer: expr('C')),
          if_(x.property('_field').eq(nullLiteral), [return_()]),
          x.property('_field').whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('Object')]));
            var nonPromotionReason =
                reasons.values.single
                    as PropertyNotPromotedForNonInherentReason;
            expect(nonPromotionReason.fieldPromotionEnabled, false);
          }),
        ]);
      });
    });

    group('because this', () {
      test('explicit', () {
        h.thisType = 'C';
        h.addSuperInterfaces('D', (_) => [Type('C'), Type('Object')]);
        h.addSuperInterfaces('C', (_) => [Type('Object')]);
        h.run([
          if_(this_.isNot('D'), [return_()]),
          this_.whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('D')]));
            var nonPromotionReason = reasons.values.single as ThisNotPromoted;
            expect(
              nonPromotionReason.documentationLink,
              NonPromotionDocumentationLink.this_,
            );
          }),
        ]);
      });

      test('implicit', () {
        h.thisType = 'C';
        h.addSuperInterfaces('D', (_) => [Type('C'), Type('Object')]);
        h.addSuperInterfaces('C', (_) => [Type('Object')]);
        h.run([
          if_(this_.isNot('D'), [return_()]),
          implicitThis_whyNotPromoted('C', (reasons) {
            expect(reasons.keys, unorderedEquals([Type('D')]));
            var nonPromotionReason = reasons.values.single as ThisNotPromoted;
            expect(
              nonPromotionReason.documentationLink,
              NonPromotionDocumentationLink.this_,
            );
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
        if_(x.property('_field').eq(nullLiteral), [return_()]),
        checkPromoted(x.property('_field'), 'Object'),
        x.property('_field').checkType('Object'),
      ]);
    });

    test('promotable field, this', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      h.run([
        if_(thisProperty('_field').eq(nullLiteral), [return_()]),
        checkPromoted(thisProperty('_field'), 'Object'),
        thisProperty('_field').checkType('Object'),
      ]);
    });

    test('non-promotable field', () {
      h.addMember('C', '_field', 'Object?', promotable: false);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.property('_field').eq(nullLiteral), [return_()]),
        checkNotPromoted(x.property('_field')),
        x.property('_field').checkType('Object?'),
      ]);
    });

    test('non-promotable field, this', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: false);
      h.run([
        if_(thisProperty('_field').eq(nullLiteral), [return_()]),
        checkNotPromoted(thisProperty('_field')),
        thisProperty('_field').checkType('Object?'),
      ]);
    });

    test('multiply promoted', () {
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.property('_field').eq(nullLiteral), [return_()]),
        if_(x.property('_field').isNot('int'), [return_()]),
        checkPromoted(x.property('_field'), 'int'),
        x.property('_field').checkType('int'),
      ]);
    });

    test('multiply promoted, this', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      h.run([
        if_(thisProperty('_field').eq(nullLiteral), [return_()]),
        if_(thisProperty('_field').isNot('int'), [return_()]),
        checkPromoted(thisProperty('_field'), 'int'),
        thisProperty('_field').checkType('int'),
      ]);
    });

    test('promotion of target breaks field promotion', () {
      h.addMember('B', '_field', 'Object?', promotable: true);
      h.addMember('C', '_field', 'num?', promotable: true);
      h.addSuperInterfaces('C', (_) => [Type('B'), Type('Object')]);
      h.addSuperInterfaces('B', (_) => [Type('Object')]);
      var x = Var('x');
      h.run([
        declare(x, type: 'B', initializer: expr('B')),
        if_(x.property('_field').eq(nullLiteral), [return_()]),
        checkPromoted(x.property('_field'), 'Object'),
        x.property('_field').checkType('Object'),
        if_(x.isNot('C'), [return_()]),
        checkNotPromoted(x.property('_field')),
        x.property('_field').checkType('num?'),
      ]);
    });

    test('promotion of target does not break field promotion', () {
      h.addMember('B', '_field', 'Object?', promotable: true);
      h.addMember('C', '_field', 'num?', promotable: true);
      h.addSuperInterfaces('C', (_) => [Type('B'), Type('Object')]);
      h.addSuperInterfaces('B', (_) => [Type('Object')]);
      var x = Var('x');
      h.run([
        declare(x, type: 'B', initializer: expr('B')),
        if_(x.property('_field').isNot('int'), [return_()]),
        checkPromoted(x.property('_field'), 'int'),
        x.property('_field').checkType('int'),
        if_(x.isNot('C'), [return_()]),
        checkPromoted(x.property('_field'), 'int'),
        x.property('_field').checkType('int'),
      ]);
    });

    test('field not promotable after outer variable demoted', () {
      h.addMember('B', '_field', 'Object?', promotable: false);
      h.addMember('C', '_field', 'Object?', promotable: true);
      h.addSuperInterfaces('C', (_) => [Type('B'), Type('Object')]);
      h.addSuperInterfaces('B', (_) => [Type('Object')]);
      var x = Var('x');
      h.run([
        declare(x, type: 'B', initializer: expr('B')),
        if_(x.is_('C'), [
          if_(x.property('_field').notEq(nullLiteral), [
            checkPromoted(x.property('_field'), 'Object'),
            x.property('_field').checkType('Object'),
          ]),
        ]),
        if_(x.property('_field').notEq(nullLiteral), [
          checkNotPromoted(x.property('_field')),
          x.property('_field').checkType('Object?'),
        ]),
      ]);
    });

    test('field promotable after outer variable promoted', () {
      h.addMember('B', '_field', 'Object?', promotable: false);
      h.addMember('C', '_field', 'Object?', promotable: true);
      h.addSuperInterfaces('C', (_) => [Type('B'), Type('Object')]);
      h.addSuperInterfaces('B', (_) => [Type('Object')]);
      var x = Var('x');
      h.run([
        declare(x, type: 'B', initializer: expr('B')),
        if_(x.property('_field').notEq(nullLiteral), [
          checkNotPromoted(x.property('_field')),
          x.property('_field').checkType('Object?'),
        ]),
        if_(x.is_('C'), [
          if_(x.property('_field').notEq(nullLiteral), [
            checkPromoted(x.property('_field'), 'Object'),
            x.property('_field').checkType('Object'),
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
        if_(thisProperty('_field1').isNot('String'), [return_()]),
        if_(this_.property('_field2').isNot('String?'), [return_()]),
        if_(x.property('_field1').isNot('int'), [return_()]),
        if_(y.property('_field1').isNot('double'), [return_()]),
        checkPromoted(thisProperty('_field1'), 'String'),
        thisProperty('_field1').checkType('String'),
        checkPromoted(this_.property('_field1'), 'String'),
        this_.property('_field1').checkType('String'),
        checkPromoted(thisProperty('_field2'), 'String?'),
        thisProperty('_field2').checkType('String?'),
        checkPromoted(this_.property('_field2'), 'String?'),
        this_.property('_field2').checkType('String?'),
        checkPromoted(x.property('_field1'), 'int'),
        x.property('_field1').checkType('int'),
        checkNotPromoted(x.property('_field2')),
        x.property('_field2').checkType('Object?'),
        checkPromoted(y.property('_field1'), 'double'),
        y.property('_field1').checkType('double'),
        checkNotPromoted(y.property('_field2')),
        y.property('_field2').checkType('Object?'),
      ]);
    });

    test('cancelled by write to local var', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.property('_field').isNot('String'), [return_()]),
        checkPromoted(x.property('_field'), 'String'),
        x.property('_field').checkType('String'),
        x.write(expr('C')),
        checkNotPromoted(x.property('_field')),
        x.property('_field').checkType('Object?'),
      ]);
    });

    test('cancelled by write to local var, nested', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: true);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.property('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.property('_field1').property('_field2'), 'String'),
        x.property('_field1').property('_field2').checkType('String'),
        x.write(expr('C')),
        checkNotPromoted(x.property('_field1').property('_field2')),
        x.property('_field1').property('_field2').checkType('Object?'),
      ]);
    });

    test('cancelled by write to local var later in loop', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.property('_field').isNot('String'), [return_()]),
        checkPromoted(x.property('_field'), 'String'),
        x.property('_field').checkType('String'),
        while_(expr('bool'), [
          checkNotPromoted(x.property('_field')),
          x.property('_field').checkType('Object?'),
          x.write(expr('C')),
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
        if_(x.property('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.property('_field1').property('_field2'), 'String'),
        x.property('_field1').property('_field2').checkType('String'),
        while_(expr('bool'), [
          checkNotPromoted(x.property('_field1').property('_field2')),
          x.property('_field1').property('_field2').checkType('Object?'),
          x.write(expr('C')),
        ]),
      ]);
    });

    test('cancelled by capture of local var', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.property('_field').isNot('String'), [return_()]),
        checkPromoted(x.property('_field'), 'String'),
        x.property('_field').checkType('String'),
        localFunction([x.write(expr('C'))]),
        checkNotPromoted(x.property('_field')),
        x.property('_field').checkType('Object?'),
      ]);
    });

    test('cancelled by capture of local var, nested', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: true);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        if_(x.property('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkPromoted(x.property('_field1').property('_field2'), 'String'),
        x.property('_field1').property('_field2').checkType('String'),
        localFunction([x.write(expr('C'))]),
        checkNotPromoted(x.property('_field1').property('_field2')),
        x.property('_field1').property('_field2').checkType('Object?'),
      ]);
    });

    test('prevented by previous capture of local var', () {
      h.thisType = 'C';
      h.addMember('C', '_field', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        localFunction([x.write(expr('C'))]),
        if_(x.property('_field').isNot('String'), [return_()]),
        checkNotPromoted(x.property('_field')),
        x.property('_field').checkType('Object?'),
      ]);
    });

    test('prevented by previous capture of local var, nested', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: true);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      var x = Var('x');
      h.run([
        declare(x, type: 'C', initializer: expr('C')),
        localFunction([x.write(expr('C'))]),
        if_(x.property('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkNotPromoted(x.property('_field1').property('_field2')),
        x.property('_field1').property('_field2').checkType('Object?'),
      ]);
    });

    test('prevented by non-promotability of target', () {
      h.thisType = 'C';
      h.addMember('C', '_field1', 'D', promotable: false);
      h.addMember('D', '_field2', 'Object?', promotable: true);
      h.run([
        if_(thisProperty('_field1').property('_field2').isNot('String'), [
          return_(),
        ]),
        checkNotPromoted(thisProperty('_field1').property('_field2')),
        thisProperty('_field1').property('_field2').checkType('Object?'),
      ]);
    });

    test('super tracked separately', () {
      // This test verifies that promotion of `this._field` and promotion of
      // `super._field` are tracked separately. This is necessary in case
      // `this._field` overrides `super._field` (and hence the two accesses
      // refer to different underlying fields).
      h.thisType = 'C';
      h.addMember('C', '_field', 'int?', promotable: true);
      h.run([
        if_(thisProperty('_field').notEq(nullLiteral), [
          checkPromoted(thisProperty('_field'), 'int'),
          this_.property('_field').checkType('int'),
          checkNotPromoted(superProperty('_field')),
        ]),
        if_(superProperty('_field').notEq(nullLiteral), [
          checkPromoted(superProperty('_field'), 'int'),
          checkNotPromoted(thisProperty('_field')),
          this_.property('_field').checkType('int?'),
        ]),
      ]);
    });

    group('cascades:', () {
      group('not null-aware:', () {
        test('cascaded access receives the benefit of promotion', () {
          h.addMember('C', '_field', 'Object?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            x.property('_field').as_('int'),
            checkPromoted(x.property('_field'), 'int'),
            x.cascade([
              (v) => v.property('_field').checkType('int'),
              (v) => v.property('_field').checkType('int'),
            ]),
          ]);
        });

        test('field access on cascade expression retains promotion', () {
          h.addMember('C', '_field', 'Object?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            x.property('_field').as_('int'),
            checkPromoted(x.property('_field'), 'int'),
            x
                .cascade([(v) => v.property('_field').checkType('int')])
                .property('_field')
                .checkType('int'),
          ]);
        });

        test('a cascade expression is not promotable', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('int?')),
            x.cascade([(v) => v.invokeMethod('toString', [])]).nonNullAssert,
            checkNotPromoted(x),
          ]);
        });

        test('even a field of an ephemeral object can be promoted', () {
          h.addMember('C', '_field', 'int?', promotable: true);
          h.run([
            expr('C')
                .cascade([
                  (v) => v.property('_field').checkType('int?').nonNullAssert,
                  (v) => v.property('_field').checkType('int'),
                ])
                .property('_field')
                .checkType('int'),
          ]);
        });

        test('even a field of a write captured variable can be promoted', () {
          h.addMember('C', '_field', 'int?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            localFunction([x.write(expr('C'))]),
            x
                .cascade([
                  (v) => v.property('_field').checkType('int?').nonNullAssert,
                  (v) => v.property('_field').checkType('int'),
                ])
                .property('_field')
                .checkType('int'),
          ]);
        });
      });

      group('null-aware:', () {
        test('cascaded access receives the benefit of promotion', () {
          h.addMember('C', '_field', 'Object?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            x.property('_field').as_('int'),
            checkPromoted(x.property('_field'), 'int'),
            x.cascade(isNullAware: true, [
              (v) => v.property('_field').checkType('int'),
              (v) => v.property('_field').checkType('int'),
            ]),
          ]);
        });

        test('field access on cascade expression retains promotion', () {
          h.addMember('C', '_field', 'Object?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            x.property('_field').as_('int'),
            checkPromoted(x.property('_field'), 'int'),
            x
                .cascade(isNullAware: true, [
                  (v) => v.property('_field').checkType('int'),
                ])
                .property('_field')
                .checkType('int'),
          ]);
        });

        test('a cascade expression is not promotable', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('int?')),
            x.cascade(isNullAware: true, [
              (v) => v.invokeMethod('toString', []),
            ]).nonNullAssert,
            checkNotPromoted(x),
          ]);
        });

        test('even a field of an ephemeral object can be promoted', () {
          h.addMember('C', '_field', 'int?', promotable: true);
          h.addSuperInterfaces('C', (_) => [Type('Object')]);
          h.run([
            expr('C?')
                .cascade(isNullAware: true, [
                  (v) => v.property('_field').checkType('int?').nonNullAssert,
                  (v) => v.property('_field').checkType('int'),
                ])
                // But the promotion doesn't survive beyond the cascade
                // expression, because of the implicit control flow join implied
                // by the null-awareness of the cascade. (In principle it would
                // be sound to preserve the promotion, but it's extra work to do
                // so, and it's not clear that there would be enough user
                // benefit to justify the work).
                .nonNullAssert
                .property('_field')
                .checkType('int?'),
          ]);
        });

        test('even a field of a write captured variable can be promoted', () {
          h.addSuperInterfaces('C', (_) => [Type('Object')]);
          h.addMember('C', '_field', 'int?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C?')),
            localFunction([x.write(expr('C?'))]),
            x
                .cascade(isNullAware: true, [
                  (v) => v.property('_field').checkType('int?').nonNullAssert,
                  (v) => v.property('_field').checkType('int'),
                ])
                // But the promotion doesn't survive beyond the cascade
                // expression, because of the implicit control flow join implied
                // by the null-awareness of the cascade. (In principle it would
                // be sound to preserve the promotion, but it's extra work to do
                // so, and it's not clear that there would be enough user
                // benefit to justify the work).
                .nonNullAssert
                .property('_field')
                .checkType('int?'),
          ]);
        });
      });

      test('unstable target', () {
        h.addMember('C', 'd', 'D', promotable: false);
        h.addMember('D', '_i', 'int?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          // The value of `c.d` is cached in a temporary variable, call it `t0`.
          c.property('d').cascade([
            // `t0._i` could be null at this point.
            (t0) => t0.property('_i').checkType('int?'),
            // But now we promote it to non-null
            (t0) => t0.property('_i').nonNullAssert,
            // And the promotion sticks for the duration of the cascade.
            (t0) => t0.property('_i').checkType('int'),
          ]),
          // Now, a new value of `c.d` is computed, and cached in a new
          // temporary variable, call it `t1`.
          c.property('d').cascade([
            // even though `t0._i` was promoted above, `t1._i` could still be
            // null at this point.
            (t1) => t1.property('_i').checkType('int?'),
            // But now we promote it to non-null
            (t1) => t1.property('_i').nonNullAssert,
            // And the promotion sticks for the duration of the cascade.
            (t1) => t1.property('_i').checkType('int'),
          ]),
        ]);
      });
    });

    test('field becomes promotable after type test', () {
      // In this test, `C._property` is not promotable, but `D` extends `C`, and
      // `D._property` is promotable. (This could happen if, for example,
      // `C._property` is an abstract getter, and `D._property` is a final
      // field). If `_property` is type-tested while the type of the target is
      // `C`, but then `_property` is accessed while the type of the target is
      // `D`, no promotion occurs, because the thing that is type tested is
      // non-promotable.
      h.addMember('C', '_property', 'int?', promotable: false);
      h.addMember('D', '_property', 'int?', promotable: true);
      h.addSuperInterfaces('C', (_) => [Type('Object')]);
      h.addSuperInterfaces('D', (_) => [Type('C'), Type('Object')]);
      var x = Var('x');
      h.run([
        declare(x, initializer: expr('C')),
        x.property('_property').nonNullAssert,
        x.as_('D'),
        checkNotPromoted(x.property('_property')),
        x.property('_property').nonNullAssert,
        checkPromoted(x.property('_property'), 'int'),
      ]);
    });

    group('Preserved by join:', () {
      test('Property', () {
        h.addMember('C', '_field', 'int?', promotable: true);
        var x = Var('x');
        // Even though the two branches of the "if" assign different values to
        // `x` (and hence the SSA nodes associated with `x._field` in the two
        // branches are different), the promotion is still preserved by the
        // join.
        h.run([
          declare(x, type: 'C'),
          if_(
            expr('bool'),
            [x.write(expr('C')), x.property('_field').nonNullAssert],
            [x.write(expr('C')), x.property('_field').nonNullAssert],
          ),
          checkPromoted(x.property('_field'), 'int'),
        ]);
      });

      test('Property of property', () {
        h.addMember('C', '_i', 'int?', promotable: true);
        h.addMember('D', '_c', 'C', promotable: true);
        var x = Var('x');
        // Even though the two branches of the "if" assign different values to
        // `x` (and hence the SSA nodes associated with `x._c._i` in the two
        // branches are different), the promotion is still preserved by the
        // join.
        h.run([
          declare(x, type: 'D'),
          if_(
            expr('bool'),
            [x.write(expr('D')), x.property('_c').property('_i').nonNullAssert],
            [x.write(expr('D')), x.property('_c').property('_i').nonNullAssert],
          ),
          checkPromoted(x.property('_c').property('_i'), 'int'),
        ]);
      });

      test('Property promoted only in first joined control flow path', () {
        h.addMember('C', '_field', 'int?', promotable: true);
        var x = Var('x');
        // No promotion because the property is only promoted in one control
        // flow path.
        h.run([
          declare(x, type: 'C'),
          if_(
            expr('bool'),
            [x.write(expr('C')), x.property('_field').nonNullAssert],
            [x.write(expr('C')), x.property('_field')],
          ),
          checkNotPromoted(x.property('_field')),
        ]);
      });

      test('Property promoted only in second joined control flow path', () {
        h.addMember('C', '_field', 'int?', promotable: true);
        var x = Var('x');
        // No promotion because the property is only promoted in one control
        // flow path.
        h.run([
          declare(x, type: 'C'),
          if_(
            expr('bool'),
            [x.write(expr('C')), x.property('_field')],
            [x.write(expr('C')), x.property('_field').nonNullAssert],
          ),
          checkNotPromoted(x.property('_field')),
        ]);
      });

      test('Property accessed only in first joined control flow path', () {
        h.addMember('C', '_field', 'int?', promotable: true);
        var x = Var('x');
        // No promotion because the property is only promoted in one control
        // flow path.
        h.run([
          declare(x, type: 'C'),
          if_(
            expr('bool'),
            [x.write(expr('C')), x.property('_field').nonNullAssert],
            [x.write(expr('C'))],
          ),
          checkNotPromoted(x.property('_field')),
        ]);
      });

      test('Property accessed only in second joined control flow path', () {
        h.addMember('C', '_field', 'int?', promotable: true);
        var x = Var('x');
        // No promotion because the property is only promoted in one control
        // flow path.
        h.run([
          declare(x, type: 'C'),
          if_(
            expr('bool'),
            [x.write(expr('C'))],
            [x.write(expr('C')), x.property('_field').nonNullAssert],
          ),
          checkNotPromoted(x.property('_field')),
        ]);
      });
    });

    group('In try/finally:', () {
      // In a try/finally statement, the `finally` clause is analyzed as though
      // the `try` block hasn't executed yet (and any variables written inside
      // the `try` block have been de-promoted), to account for the fact that
      // an exception might occur at any time during the `try` block. However,
      // after the `finally` block is finished, any flow model changes that
      // occurred during the `finally` block are rewound and re-applied to the
      // flow model state after the `try` block, to account for the fact that
      // if the try/finally statement completes normally, it is known that the
      // `try` block executed fully.
      //
      // We need to verify that this rebasing logic handles all the possible
      // ways that field promotion can occur relative to a try/finally
      // statement.

      test('Promoted in try', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          try_([
            checkNotPromoted(c.property('_property')),
            c.property('_property').nonNullAssert,
            checkPromoted(c.property('_property'), 'int'),
          ]).finally_([checkNotPromoted(c.property('_property'))]),
          checkPromoted(c.property('_property'), 'int'),
        ]);
      });

      test('Promoted in try, nested', () {
        h.addMember('C', '_i', 'int?', promotable: true);
        h.addMember('D', '_c', 'C', promotable: true);
        var d = Var('d');
        h.run([
          declare(d, initializer: expr('D')),
          try_([
            checkNotPromoted(d.property('_c').property('_i')),
            d.property('_c').property('_i').nonNullAssert,
            checkPromoted(d.property('_c').property('_i'), 'int'),
          ]).finally_([checkNotPromoted(d.property('_c').property('_i'))]),
          checkPromoted(d.property('_c').property('_i'), 'int'),
        ]);
      });

      test('Promoted before try/finally', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          c.property('_property').nonNullAssert,
          checkPromoted(c.property('_property'), 'int'),
          try_([
            checkPromoted(c.property('_property'), 'int'),
          ]).finally_([checkPromoted(c.property('_property'), 'int')]),
          checkPromoted(c.property('_property'), 'int'),
        ]);
      });

      test('Promoted before try/finally and in try', () {
        h.addMember('C', '_property', 'num?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          c.property('_property').nonNullAssert,
          checkPromoted(c.property('_property'), 'num'),
          try_([
            checkPromoted(c.property('_property'), 'num'),
            c.property('_property').as_('int'),
            checkPromoted(c.property('_property'), 'int'),
          ]).finally_([checkPromoted(c.property('_property'), 'num')]),
          checkPromoted(c.property('_property'), 'int'),
        ]);
      });

      group('Promoted in both try and finally:', () {
        test('same type', () {
          h.addMember('C', '_property', 'int?', promotable: true);
          var c = Var('c');
          h.run([
            declare(c, initializer: expr('C')),
            try_([
              checkNotPromoted(c.property('_property')),
              c.property('_property').nonNullAssert,
              checkPromoted(c.property('_property'), 'int'),
            ]).finally_([
              checkNotPromoted(c.property('_property')),
              c.property('_property').nonNullAssert,
              checkPromoted(c.property('_property'), 'int'),
            ]),
            checkPromoted(c.property('_property'), 'int'),
          ]);
        });

        test('finally type is subtype of try type', () {
          h.addMember('C', '_property', 'num?', promotable: true);
          var c = Var('c');
          h.run([
            declare(c, initializer: expr('C')),
            try_([
              checkNotPromoted(c.property('_property')),
              c.property('_property').nonNullAssert,
              checkPromoted(c.property('_property'), 'num'),
            ]).finally_([
              checkNotPromoted(c.property('_property')),
              c.property('_property').as_('int'),
              checkPromoted(c.property('_property'), 'int'),
            ]),
            checkPromoted(c.property('_property'), 'int'),
          ]);
        });

        test('finally type is supertype of try type', () {
          h.addMember('C', '_property', 'num?', promotable: true);
          var c = Var('c');
          h.run([
            declare(c, initializer: expr('C')),
            try_([
              checkNotPromoted(c.property('_property')),
              c.property('_property').as_('int'),
              checkPromoted(c.property('_property'), 'int'),
            ]).finally_([
              checkNotPromoted(c.property('_property')),
              c.property('_property').nonNullAssert,
              checkPromoted(c.property('_property'), 'num'),
            ]),
            checkPromoted(c.property('_property'), 'int'),
          ]);
        });
      });

      test('Promoted in finally', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          try_([checkNotPromoted(c.property('_property'))]).finally_([
            checkNotPromoted(c.property('_property')),
            c.property('_property').nonNullAssert,
            checkPromoted(c.property('_property'), 'int'),
          ]),
          checkPromoted(c.property('_property'), 'int'),
        ]);
      });

      test('Promoted in finally, nested', () {
        h.addMember('C', '_i', 'int?', promotable: true);
        h.addMember('D', '_c', 'C', promotable: true);
        var d = Var('d');
        h.run([
          declare(d, initializer: expr('D')),
          try_([checkNotPromoted(d.property('_c').property('_i'))]).finally_([
            checkNotPromoted(d.property('_c').property('_i')),
            d.property('_c').property('_i').nonNullAssert,
            checkPromoted(d.property('_c').property('_i'), 'int'),
          ]),
          checkPromoted(d.property('_c').property('_i'), 'int'),
        ]);
      });

      test('Promoted before try/finally, assigned in try', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          c.property('_property').nonNullAssert,
          checkPromoted(c.property('_property'), 'int'),
          try_([
            checkPromoted(c.property('_property'), 'int'),
            c.write(expr('C')),
            checkNotPromoted(c.property('_property')),
          ]).finally_([checkNotPromoted(c.property('_property'))]),
          checkNotPromoted(c.property('_property')),
        ]);
      });

      test('Promoted before try/finally, assigned and re-promoted in try', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          c.property('_property').nonNullAssert,
          checkPromoted(c.property('_property'), 'int'),
          try_([
            checkPromoted(c.property('_property'), 'int'),
            c.write(expr('C')),
            c.property('_property').nonNullAssert,
            checkPromoted(c.property('_property'), 'int'),
          ]).finally_([checkNotPromoted(c.property('_property'))]),
          checkPromoted(c.property('_property'), 'int'),
        ]);
      });

      test('Assigned in try, promoted in finally', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          try_([
            // Note: no calls to `checkNotPromoted` here, because we want to
            // trigger the code path where flow analysis doesn't even know about
            // the property until the finally block
            c.write(expr('C')),
          ]).finally_([
            c.property('_property').nonNullAssert,
            checkPromoted(c.property('_property'), 'int'),
          ]),
          checkPromoted(c.property('_property'), 'int'),
        ]);
      });

      test('Assigned in try, promoted in finally, nested', () {
        h.addMember('C', '_i', 'int?', promotable: true);
        h.addMember('D', '_c', 'C', promotable: true);
        var d = Var('d');
        h.run([
          declare(d, initializer: expr('D')),
          try_([
            // Note: no calls to `checkNotPromoted` here, because we want to
            // trigger the code path where flow analysis doesn't even know about
            // the property until the finally block
            d.write(expr('D')),
          ]).finally_([
            d.property('_c').property('_i').nonNullAssert,
            checkPromoted(d.property('_c').property('_i'), 'int'),
          ]),
          checkPromoted(d.property('_c').property('_i'), 'int'),
        ]);
      });

      test('Assigned but not promotable in try, promoted in finally', () {
        h.addMember('C', '_property', 'int?', promotable: false);
        h.addMember('D', '_property', 'int?', promotable: true);
        h.addSuperInterfaces('C', (_) => [Type('Object')]);
        h.addSuperInterfaces('D', (_) => [Type('C'), Type('Object')]);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          try_([
            c.write(expr('C')),
            c.property('_property').nonNullAssert,
            checkNotPromoted(c.property('_property')),
          ]).finally_([
            c.as_('D'),
            c.property('_property').nonNullAssert,
            checkPromoted(c.property('_property'), 'int'),
          ]),
          checkPromoted(c.property('_property'), 'int'),
        ]);
      });

      test('Assigned and promoted in try, promoted to subtype in finally', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          try_([
            checkNotPromoted(c.property('_property')),
            c.write(expr('C')),
            checkNotPromoted(c.property('_property')),
            c.property('_property').as_('num'),
            checkPromoted(c.property('_property'), 'num'),
          ]).finally_([
            c.property('_property').as_('int'),
            checkPromoted(c.property('_property'), 'int'),
          ]),
          checkPromoted(c.property('_property'), 'int'),
        ]);
      });
    });

    group('Via local condition variable:', () {
      group('without intervening promotion:', () {
        // These tests exercise the code path in `FlowModel.rebaseForward` where
        // `this` model (which represents the state captured at the time the
        // condition variable is written) contains a promotion key for the
        // field, but the `base` model (which represents state just prior to
        // reading from the condition variable) doesn't contain any promotion
        // key for the field. Furthermore, since no other promotions occur
        // between writing and reading the condition variable, `rebaseForward`
        // will not create a fresh `FlowModel`; it will simply return `this`
        // model.
        test('using null check', () {
          h.addMember('C', '_field', 'int?', promotable: true);
          var c = Var('c');
          var b = Var('b');
          h.run([
            declare(c, initializer: expr('C')),
            declare(b, initializer: c.property('_field').notEq(nullLiteral)),
            if_(b, [checkPromoted(c.property('_field'), 'int')]),
          ]);
        });

        test('using `is` test', () {
          h.addMember('C', '_field', 'Object', promotable: true);
          h.addSuperInterfaces('C', (_) => [Type('Object')]);
          var c = Var('c');
          var b = Var('b');
          h.run([
            declare(c, initializer: expr('C')),
            declare(b, initializer: c.property('_field').is_('int')),
            if_(b, [checkPromoted(c.property('_field'), 'int')]),
          ]);
        });
      });

      group('with intervening related promotion:', () {
        // These tests exercise the code path in `FlowModel.rebaseForward` where
        // `this` model (which represents the state captured at the time the
        // condition variable is written) and the `base` model (which represents
        // state just prior to reading from the condition variable) both contain
        // a promotion key for the field.
        test('using null check', () {
          h.addMember('C', '_field', 'int?', promotable: true);
          var c = Var('c');
          var b = Var('b');
          h.run([
            declare(c, initializer: expr('C')),
            declare(b, initializer: c.property('_field').notEq(nullLiteral)),
            if_(c.property('_field').notEq(nullLiteral), [
              checkPromoted(c.property('_field'), 'int'),
            ]),
            if_(b, [checkPromoted(c.property('_field'), 'int')]),
          ]);
        });

        test('using `is` test', () {
          h.addMember('C', '_field', 'Object', promotable: true);
          h.addSuperInterfaces('C', (_) => [Type('Object')]);
          var c = Var('c');
          var b = Var('b');
          h.run([
            declare(c, initializer: expr('C')),
            declare(b, initializer: c.property('_field').is_('int')),
            if_(c.property('_field').is_('int'), [
              checkPromoted(c.property('_field'), 'int'),
            ]),
            if_(b, [checkPromoted(c.property('_field'), 'int')]),
          ]);
        });
      });

      group('with intervening unrelated promotion:', () {
        // These tests exercise the code path in `FlowModel.rebaseForward` where
        // `this` model (which represents the state captured at the time the
        // condition variable is written) contains a promotion key for the
        // field, but the `base` model (which represents state just prior to
        // reading from the condition variable) doesn't contain any promotion
        // key for the field. Since a different variable is promoted in between
        // writing and reading the condition variable, `rebaseForward` will be
        // forced to create a fresh `FlowModel`; it will not be able to simply
        // return `this` model.
        test('using null check', () {
          h.addMember('C', '_field', 'int?', promotable: true);
          var c = Var('c');
          var unrelated = Var('unrelated');
          var b = Var('b');
          h.run([
            declare(c, initializer: expr('C')),
            declare(unrelated, initializer: expr('int?')),
            declare(b, initializer: c.property('_field').notEq(nullLiteral)),
            unrelated.nonNullAssert,
            if_(b, [checkPromoted(c.property('_field'), 'int')]),
          ]);
        });

        test('using `is` test', () {
          h.addMember('C', '_field', 'Object', promotable: true);
          h.addSuperInterfaces('C', (_) => [Type('Object')]);
          var c = Var('c');
          var unrelated = Var('unrelated');
          var b = Var('b');
          h.run([
            declare(c, initializer: expr('C')),
            declare(unrelated, initializer: expr('int?')),
            declare(b, initializer: c.property('_field').is_('int')),
            unrelated.nonNullAssert,
            if_(b, [checkPromoted(c.property('_field'), 'int')]),
          ]);
        });
      });

      group('disabled by intervening assignment:', () {
        test('using null check', () {
          h.addMember('C', '_field', 'int?', promotable: true);
          var c = Var('c');
          var b = Var('b');
          h.run([
            declare(c, initializer: expr('C')),
            declare(b, initializer: c.property('_field').notEq(nullLiteral)),
            if_(c.property('_field').notEq(nullLiteral), [
              checkPromoted(c.property('_field'), 'int'),
            ]),
            c.write(expr('C')),
            if_(b, [checkNotPromoted(c.property('_field'))]),
          ]);
        });

        test('using `is` test', () {
          h.addMember('C', '_field', 'Object', promotable: true);
          h.addSuperInterfaces('C', (_) => [Type('Object')]);
          var c = Var('c');
          var b = Var('b');
          h.run([
            declare(c, initializer: expr('C')),
            declare(b, initializer: c.property('_field').is_('int')),
            if_(c.property('_field').is_('int'), [
              checkPromoted(c.property('_field'), 'int'),
            ]),
            c.write(expr('C')),
            if_(b, [checkNotPromoted(c.property('_field'))]),
          ]);
        });
      });
    });

    group('And object pattern:', () {
      test('Promotion via object promotion', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        h.addDownwardInfer(name: 'C', context: 'C', result: 'C');
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('C')),
          ifCase(
            x,
            objectPattern(
              requiredType: 'C',
              fields: [wildcard().nullCheck.recordField('_property')],
            ),
            [checkPromoted(x.property('_property'), 'int')],
            [checkNotPromoted(x.property('_property'))],
          ),
        ]);
      });

      test('Scrutinee restored after object pattern', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        h.addDownwardInfer(name: 'C', context: 'C?', result: 'C');
        h.addSuperInterfaces('C', (_) => [Type('Object')]);
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('C?')),
          ifCase(
            x,
            objectPattern(
              requiredType: 'C',
              fields: [wildcard().nullCheck.recordField('_property')],
            ).or(
              // After visiting the object pattern, the scrutinee should now
              // be restored to point to the `x`, so this null check should
              // promote `x` to `C`.
              wildcard().nullCheck,
            ),
            [checkPromoted(x, 'C')],
            [checkNotPromoted(x)],
          ),
        ]);
      });

      test('Subpattern matched value type accounts for previous promotion', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        h.addDownwardInfer(name: 'C', context: 'C', result: 'C');
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, initializer: expr('C')),
          x.property('_property').nonNullAssert,
          checkPromoted(x.property('_property'), 'int'),
          ifCase(
            x,
            objectPattern(
              requiredType: 'C',
              fields: [
                y.pattern(expectInferredType: 'int').recordField('_property'),
              ],
            ),
            [],
          ),
        ]);
      });
    });

    group('non promotion reasons:', () {
      test('inherent reason', () {
        // It's only necessary to test one of the inherent reasons, because flow
        // analysis just passes it through.
        h.thisType = 'C';
        h.addMember(
          'C',
          '_field',
          'Object?',
          whyNotPromotable: PropertyNonPromotabilityReason.isNotFinal,
        );
        h.run([
          if_(thisProperty('_field').eq(nullLiteral), [return_()]),
          thisProperty('_field').whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('Object')]));
            var nonPromotionReason =
                reasons.values.single as PropertyNotPromotedForInherentReason;
            expect(
              nonPromotionReason.whyNotPromotable,
              PropertyNonPromotabilityReason.isNotFinal,
            );
          }),
        ]);
      });

      test('due to conflict', () {
        h.thisType = 'C';
        h.addMember('C', '_field', 'Object?', whyNotPromotable: null);
        h.run([
          if_(thisProperty('_field').eq(nullLiteral), [return_()]),
          thisProperty('_field').whyNotPromoted((reasons) {
            expect(reasons.keys, unorderedEquals([Type('Object')]));
            var nonPromotionReason =
                reasons.values.single
                    as PropertyNotPromotedForNonInherentReason;
            expect(nonPromotionReason.fieldPromotionEnabled, true);
          }),
        ]);
      });
    });

    group('and equality:', () {
      test('promoted type accounted for on LHS', () {
        // Flow analysis understands when an `if` test is guaranteed to succeed
        // (or fail) based on the static types of the LHS and RHS. Make sure
        // this works when the LHS or RHS is a property reference.
        h.addMember('C', 'f', 'Object?', promotable: true);
        h.thisType = 'C';
        h.run([
          if_(thisProperty('f').isNot('Null'), [return_()]),
          checkPromoted(thisProperty('f'), 'Null'),
          if_(
            thisProperty('f').eq(nullLiteral),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('promoted type accounted for on RHS', () {
        // Flow analysis understands when an `if` test is guaranteed to succeed
        // (or fail) based on the static types of the LHS and RHS. Make sure
        // this works when the LHS or RHS is a property reference.
        h.addMember('C', 'f', 'Object?', promotable: true);
        h.thisType = 'C';
        h.run([
          if_(thisProperty('f').isNot('Null'), [return_()]),
          checkPromoted(thisProperty('f'), 'Null'),
          if_(
            nullLiteral.eq(thisProperty('f')),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });
  });

  group('Patterns:', () {
    group('Assignment:', () {
      group('Demotion', () {
        test('Demoting', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            x.nonNullAssert,
            checkPromoted(x, 'int'),
            x.pattern().assign(expr('int?')),
            checkNotPromoted(x),
          ]);
        });

        test('Non-demoting', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'num?'),
            x.nonNullAssert,
            checkPromoted(x, 'num'),
            x.pattern().assign(expr('int')),
            checkPromoted(x, 'num'),
          ]);
        });
      });

      group('Schema:', () {
        test('Not promoted', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            x.pattern().assign(expr('int').checkSchema('int?')),
          ]);
        });

        test('Promoted', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            x.nonNullAssert,
            checkPromoted(x, 'int'),
            x.pattern().assign(expr('int').checkSchema('int')),
          ]);
        });
      });

      group('Promotion:', () {
        test('Type of interest', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'num'),
            if_(x.is_('int'), []),
            checkNotPromoted(x),
            x.pattern().assign(expr('int')),
            checkPromoted(x, 'int'),
          ]);
        });

        test('Not a type of interest', () {
          var x = Var('x');
          h.run([
            declare(x, type: 'num'),
            x.pattern().assign(expr('int')),
            checkNotPromoted(x),
          ]);
        });

        test('Promotes matched value', () {
          // The code below is equivalent to:
          //     int x;
          //     (x && _!) = ... as dynamic;
          // There should be an "unnecessary !" warning, because the `x` pattern
          // implicitly promotes the matched value to type `int`.
          var x = Var('x');
          h.run(
            [
              declare(x, type: 'int'),
              x
                  .pattern()
                  .and(wildcard().nullAssert..errorId = 'NULLASSERT')
                  .assign(expr('dynamic')),
            ],
            expectedErrors: {
              'matchedTypeIsStrictlyNonNullable(pattern: NULLASSERT, '
                  'matchedType: int)',
            },
          );
        });

        test('Does not promote scrutinee', () {
          // The code below is equivalent to:
          //     int x;
          //     dynamic y = ...;
          //     (x && _) = y;
          //     // y is *not* promoted to `int`.
          // Although the assignment to `x` performs an implicit downcast, we
          // don't promote `y` because patterns in irrefutable contexts don't
          // trigger scrutinee promotion.
          var x = Var('x');
          var y = Var('y');
          h.run(
            [
              declare(x, type: 'int'),
              declare(y, initializer: expr('dynamic')),
              x.pattern().and(wildcard()..errorId = 'WILDCARD').assign(y),
              checkNotPromoted(y),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });
      });

      test('Definite assignment', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int'),
          checkAssigned(x, false),
          x.pattern().assign(expr('int')),
          checkAssigned(x, true),
        ]);
      });

      group('Boolean condition:', () {
        test('As main pattern', () {
          var b = Var('b');
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            declare(b, type: 'bool'),
            b.pattern().assign(x.notEq(nullLiteral)),
            if_(b, [
              // `x` is promoted because `b` is known to equal `x != null`.
              checkPromoted(x, 'int'),
            ]),
          ]);
        });

        test('As parenthesized pattern', () {
          var b = Var('b');
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            declare(b, type: 'bool'),
            b.pattern().parenthesized.assign(x.notEq(nullLiteral)),
            if_(b, [
              // `x` is promoted because `b` is known to equal `x != null`.
              checkPromoted(x, 'int'),
            ]),
          ]);
        });

        test('As subpattern', () {
          h.addMember('bool', 'foo', 'bool');
          var b = Var('b');
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            declare(b, type: 'bool'),
            objectPattern(
              requiredType: 'bool',
              fields: [b.pattern().recordField('foo')],
            ).assign(x.notEq(nullLiteral)),
            if_(b, [
              // Even though the RHS of the pattern is `x != null`, `x` is not
              // promoted because the pattern for `b` is in a subpattern
              // position.
              checkNotPromoted(x),
            ]),
          ]);
        });
      });

      group('Demonstrated type:', () {
        test('Subtype of matched value type', () {
          var x = Var('x');
          var y = Var('y');
          h.run(
            [
              declare(x, initializer: expr('(dynamic,)')),
              declare(y, type: 'int'),
              recordPattern([y.pattern().recordField()])
                  .and(
                    wildcard(expectInferredType: '(int,)')
                      ..errorId = 'WILDCARD',
                  )
                  .assign(x),
              checkNotPromoted(x),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('Supertype of matched value type', () {
          var x = Var('x');
          var y = Var('y');
          h.run(
            [
              declare(x, initializer: expr('(int,)')),
              declare(y, type: 'num'),
              recordPattern([y.pattern().recordField()])
                  .and(
                    wildcard(expectInferredType: '(int,)')
                      ..errorId = 'WILDCARD',
                  )
                  .assign(x),
              checkNotPromoted(x),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });
      });
    });

    group('Cast pattern:', () {
      test('Subtype', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object?'),
          ifCase(x, wildcard(expectInferredType: 'String').as_('String'), [
            checkPromoted(x, 'String'),
          ]),
        ]);
      });

      test('Supertype', () {
        var x = Var('x');
        h.run(
          [
            declare(x, type: 'num'),
            ifCase(
              x,
              wildcard(expectInferredType: 'Object').as_('Object')
                ..errorId = 'PATTERN',
              [checkNotPromoted(x)],
            ),
          ],
          expectedErrors: {
            'matchedTypeIsSubtypeOfRequired(pattern: PATTERN, '
                'matchedType: num, requiredType: Object)',
          },
        );
      });

      test('Unrelated type', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'num'),
          ifCase(x, wildcard(expectInferredType: 'String').as_('String'), [
            checkNotPromoted(x),
          ]),
        ]);
      });

      test('Inner promotions have no effect', () {
        var x = Var('x');
        h.run(
          [
            declare(x, type: 'Object?'),
            ifCase(
              x,
              objectPattern(requiredType: 'int', fields: [])
                  .as_('num')
                  .and(
                    wildcard(expectInferredType: 'num')..errorId = 'WILDCARD',
                  ),
              [checkPromoted(x, 'num')],
            ),
          ],
          expectedErrors: {
            'unnecessaryWildcardPattern(pattern: WILDCARD, '
                'kind: logicalAndPatternOperand)',
          },
        );
      });

      test('Match failure unreachable', () {
        // Cast patterns don't fail; they throw exceptions.  So the "match
        // failure" code path should be unreachable.
        h.run([
          ifCase(
            expr('Object?'),
            wildcard().as_('int'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        h.run(
          [
            declare(x, initializer: expr('Object?')),
            ifCase(
              x,
              wildcard()
                  .as_('int')
                  .and(wildcard().as_('num')..errorId = 'AS_NUM')
                  .and(y.pattern(expectInferredType: 'int')),
              [checkPromoted(x, 'int')],
            ),
          ],
          expectedErrors: {
            'matchedTypeIsSubtypeOfRequired(pattern: AS_NUM, matchedType: int, '
                'requiredType: num)',
          },
        );
      });

      group('Demonstrated type:', () {
        test('Subtype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(x, recordPattern([wildcard().as_('int').recordField()]), [
              checkPromoted(x, '(int,)'),
            ]),
          ]);
        });

        test('Supertype of matched value type', () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('(num,)')),
              ifCase(
                x,
                recordPattern([
                  (wildcard().as_('Object')..errorId = 'CAST').recordField(),
                ]),
                [checkNotPromoted(x)],
              ),
            ],
            expectedErrors: {
              'matchedTypeIsSubtypeOfRequired(pattern: CAST, matchedType: num, '
                  'requiredType: Object)',
            },
          );
        });

        test('Unrelated to matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(x, recordPattern([wildcard().as_('String').recordField()]), [
              checkNotPromoted(x),
            ]),
          ]);
        });
      });

      test('Error type does not trigger unnecessary cast warning', () {
        h.run([ifCase(expr('int'), wildcard().as_('error'), [])]);
      });

      test('Promotable property', () {
        h.addMember('C', '_property', 'int?', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), wildcard().as_('int'), [
            checkPromoted(c.property('_property'), 'int'),
          ]),
        ]);
      });

      test('Promotable property, target changed', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          switch_(c.property('_property'), [
            wildcard().as_('num').when(expr('bool')).then([
              checkPromoted(c.property('_property'), 'num'),
            ]),
            wildcard().when(second(c.write(expr('C')), expr('bool'))).then([]),
            wildcard().as_('int').then([
              checkNotPromoted(c.property('_property')),
            ]),
          ]),
        ]);
      });

      test('Non-promotable property', () {
        h.addMember('C', '_property', 'int?', promotable: false);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), wildcard().as_('int'), [
            checkNotPromoted(c.property('_property')),
          ]),
        ]);
      });
    });

    group('Constant pattern:', () {
      test('Guaranteed match due to Null type', () {
        h.run([
          ifCase(
            expr('Null'),
            nullLiteral.pattern,
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test(
        'Not guaranteed to match due to Null type with old language version',
        () {
          h.disablePatterns();
          h.run([
            switch_(expr('Null'), [
              nullLiteral.pattern.then([checkReachable(true), break_()]),
              default_.then([checkReachable(true), break_()]),
            ], isLegacyExhaustive: true),
          ]);
        },
      );

      test('In the general case, may or may not match', () {
        h.run([
          ifCase(
            expr('Object?'),
            intLiteral(0).pattern,
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('Null pattern promotes unchanged scrutinee', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('int?')),
          ifCase(
            x,
            nullLiteral.pattern,
            [checkReachable(true), checkNotPromoted(x)],
            [checkReachable(true), checkPromoted(x, 'int')],
          ),
        ]);
      });

      test(
        "Null pattern doesn't promote scrutinee with old language version",
        () {
          h.disablePatterns();
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('int?')),
            switch_(x, [
              nullLiteral.pattern.then([
                checkReachable(true),
                checkNotPromoted(x),
                break_(),
              ]),
              default_.then([
                checkReachable(true),
                checkNotPromoted(x),
                break_(),
              ]),
            ], isLegacyExhaustive: true),
          ]);
        },
      );

      test("Null pattern doesn't promote changed scrutinee", () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('int?')),
          switch_(x, [
            wildcard().when(second(x.write(expr('int?')), expr('bool'))).then([
              break_(),
            ]),
            nullLiteral.pattern.then([
              checkReachable(true),
              checkNotPromoted(x),
            ]),
            wildcard(
              expectInferredType: 'int',
            ).then([checkReachable(true), checkNotPromoted(x)]),
          ]),
        ]);
      });

      test('Null pattern promotes matched pattern var', () {
        h.run([
          ifCase(
            expr('int?'),
            nullLiteral.pattern.or(wildcard(expectInferredType: 'int')),
            [],
          ),
        ]);
      });

      test('Demonstrated type', () {
        // The demonstrated type of a constant pattern is the matched value
        // type.  We don't want to promote to the constant type because doing so
        // might be unsound if the user overrides `operator==`.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('(Object,)')),
          ifCase(x, recordPattern([intLiteral(1).pattern.recordField()]), [
            checkNotPromoted(x),
          ]),
        ]);
      });
    });

    group('For-in statement:', () {
      test('does not promote iterable', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('List<dynamic>')),
          patternForIn(wildcard(type: 'int'), x, []),
          checkNotPromoted(x),
        ]);
      });
    });

    group('For-in collection element:', () {
      test('does not promote iterable', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('List<dynamic>')),
          listLiteral(elementType: 'Object', [
            patternForInElement(wildcard(type: 'int'), x, expr('Object')),
          ]),
          checkNotPromoted(x),
        ]);
      });
    });

    group('If-case element:', () {
      test('guarded', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?'),
          listLiteral(elementType: 'String', [
            ifCaseElement(
              expr('Object'),
              wildcard().when(x.notEq(nullLiteral)),
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  checkPromoted(x, 'int'),
                ]),
                expr('String'),
              ),
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  checkNotPromoted(x),
                ]),
                expr('String'),
              ),
            ),
          ]),
        ]);
      });

      test('promotes', () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'num'),
          listLiteral(elementType: 'String', [
            ifCaseElement(
              x,
              y.pattern(type: 'int'),
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  checkPromoted(x, 'int'),
                ]),
                expr('String'),
              ),
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  checkNotPromoted(x),
                ]),
                expr('String'),
              ),
            ),
          ]),
        ]);
      });
    });

    group('If-case statement:', () {
      test('guarded', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?'),
          ifCase(
            expr('Object'),
            wildcard().when(x.notEq(nullLiteral)),
            [checkReachable(true), checkPromoted(x, 'int')],
            [checkReachable(true), checkNotPromoted(x)],
          ),
        ]);
      });

      test('promotes', () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'num'),
          ifCase(
            x,
            y.pattern(type: 'int'),
            [checkReachable(true), checkPromoted(x, 'int')],
            [checkReachable(true), checkNotPromoted(x)],
          ),
        ]);
      });

      test('promotion in both pattern and guard', () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'int?'),
          declare(y, type: 'String?'),
          ifCase(
            x,
            wildcard(type: 'int').when(y.notEq(nullLiteral)),
            [
              checkReachable(true),
              checkPromoted(x, 'int'),
              checkPromoted(y, 'String'),
            ],
            [checkReachable(true), checkNotPromoted(x), checkNotPromoted(y)],
          ),
        ]);
      });
    });

    group('Logical-and pattern:', () {
      group('promotion of matched value type:', () {
        test('when scrutinee is promotable', () {
          var x = Var('x');
          h.run(
            [
              declare(x, type: 'num'),
              ifCase(
                x,
                wildcard(type: 'int').and(
                  wildcard(expectInferredType: 'int')..errorId = 'WILDCARD',
                ),
                [checkPromoted(x, 'int')],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('when scrutinee is not promotable', () {
          h.run(
            [
              ifCase(
                expr('num'),
                wildcard(type: 'int').and(
                  wildcard(expectInferredType: 'int')..errorId = 'WILDCARD',
                ),
                [],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });
      });

      test('double promotion of matched value type', () {
        var x = Var('x');
        h.run(
          [
            declare(x, type: 'Object'),
            ifCase(
              x,
              wildcard(type: 'num').and(
                wildcard(type: 'int').and(
                  wildcard(expectInferredType: 'int')..errorId = 'WILDCARD',
                ),
              ),
              [checkPromoted(x, 'int')],
            ),
          ],
          expectedErrors: {
            'unnecessaryWildcardPattern(pattern: WILDCARD, '
                'kind: logicalAndPatternOperand)',
          },
        );
      });

      group('Demonstrated type:', () {
        test('LHS <: RHS, both could promote', () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('(Object,)')),
              ifCase(
                x,
                recordPattern([
                  wildcard(
                    type: 'int',
                  ).and(wildcard(type: 'num')..errorId = 'NUM').recordField(),
                ]),
                [checkPromoted(x, '(int,)')],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: NUM, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('RHS <: LHS, both could promote', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Object,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(type: 'num').and(wildcard(type: 'int')).recordField(),
              ]),
              [checkPromoted(x, '(int,)')],
            ),
          ]);
        });

        test('LHS <: RHS, RHS == declared type', () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('(num,)')),
              ifCase(
                x,
                recordPattern([
                  wildcard(
                    type: 'int',
                  ).and(wildcard(type: 'num')..errorId = 'NUM').recordField(),
                ]),
                [checkPromoted(x, '(int,)')],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: NUM, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('RHS <: LHS, LHS == declared type', () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('(num,)')),
              ifCase(
                x,
                recordPattern([
                  (wildcard(
                    type: 'num',
                  )..errorId = 'NUM').and(wildcard(type: 'int')).recordField(),
                ]),
                [checkPromoted(x, '(int,)')],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: NUM, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('LHS <: RHS, only LHS could promote', () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('(num,)')),
              ifCase(
                x,
                recordPattern([
                  wildcard(type: 'int')
                      .and(wildcard(type: 'Object')..errorId = 'OBJECT')
                      .recordField(),
                ]),
                [checkPromoted(x, '(int,)')],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: OBJECT, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('RHS <: LHS, only RHS could promote', () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('(num,)')),
              ifCase(
                x,
                recordPattern([
                  (wildcard(type: 'Object')..errorId = 'OBJECT')
                      .and(wildcard(type: 'int'))
                      .recordField(),
                ]),
                [checkPromoted(x, '(int,)')],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: OBJECT, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('LHS <: RHS, neither could promote', () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('(int,)')),
              ifCase(
                x,
                recordPattern([
                  (wildcard(type: 'num')..errorId = 'NUM')
                      .and(wildcard(type: 'Object')..errorId = 'OBJECT')
                      .recordField(),
                ]),
                [checkNotPromoted(x)],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: NUM, '
                  'kind: logicalAndPatternOperand)',
              'unnecessaryWildcardPattern(pattern: OBJECT, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('RHS <: LHS, neither could promote', () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('(int,)')),
              ifCase(
                x,
                recordPattern([
                  (wildcard(type: 'Object')..errorId = 'OBJECT')
                      .and(wildcard(type: 'num')..errorId = 'NUM')
                      .recordField(),
                ]),
                [checkNotPromoted(x)],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: OBJECT, '
                  'kind: logicalAndPatternOperand)',
              'unnecessaryWildcardPattern(pattern: NUM, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });
      });
    });

    group('Logical-or pattern:', () {
      group('Joins promotions of scrutinee:', () {
        test('LHS more promoted', () {
          var x = Var('x');
          // `(num() && int()) || num()` retains promotion to `num`
          h.run([
            declare(x, initializer: expr('Object')),
            ifCase(
              x,
              objectPattern(requiredType: 'num', fields: [])
                  .and(objectPattern(requiredType: 'int', fields: []))
                  .or(objectPattern(requiredType: 'num', fields: [])),
              [checkPromoted(x, 'num')],
            ),
          ]);
        });

        test('RHS more promoted', () {
          var x = Var('x');
          // `num() || (num() && int())` retains promotion to `num`
          h.run([
            declare(x, initializer: expr('Object')),
            ifCase(
              x,
              objectPattern(requiredType: 'num', fields: []).or(
                objectPattern(
                  requiredType: 'num',
                  fields: [],
                ).and(objectPattern(requiredType: 'int', fields: [])),
              ),
              [checkPromoted(x, 'num')],
            ),
          ]);
        });
      });

      group('Joins promotions of implicit temporary match variable:', () {
        test('LHS more promoted', () {
          // `(num() && int()) || num()` retains promotion to `num`
          h.run(
            [
              ifCase(
                expr('Object'),
                objectPattern(requiredType: 'num', fields: [])
                    .and(objectPattern(requiredType: 'int', fields: []))
                    .or(objectPattern(requiredType: 'num', fields: []))
                    .and(
                      wildcard(expectInferredType: 'num')..errorId = 'WILDCARD',
                    ),
                [],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('RHS more promoted', () {
          // `num() || (num() && int())` retains promotion to `num`
          h.run(
            [
              ifCase(
                expr('Object'),
                objectPattern(requiredType: 'num', fields: [])
                    .or(
                      objectPattern(
                        requiredType: 'num',
                        fields: [],
                      ).and(objectPattern(requiredType: 'int', fields: [])),
                    )
                    .and(
                      wildcard(expectInferredType: 'num')..errorId = 'WILDCARD',
                    ),
                [],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });
      });

      group('Joins explicitly declared variables:', () {
        test('LHS promoted', () {
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            ifCase(
              expr('int?'),
              x1.pattern(type: 'int?').nullCheck.or(x2.pattern(type: 'int?')),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('RHS promoted', () {
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            ifCase(
              expr('int?'),
              x1.pattern(type: 'int?').or(x2.pattern(type: 'int?').nullCheck),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('Both sides promoted', () {
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            ifCase(
              expr('int?'),
              x1
                  .pattern(type: 'int?')
                  .nullCheck
                  .or(x2.pattern(type: 'int?').nullCheck),
              [checkPromoted(x, 'int')],
            ),
          ]);
        });

        test('Join variable is promotable', () {
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            ifCase(
              expr('int?'),
              x1.pattern(type: 'int?').nullCheck.or(x2.pattern(type: 'int?')),
              [checkNotPromoted(x), x.nonNullAssert, checkPromoted(x, 'int')],
            ),
          ]);
        });
      });

      group('Sets join variable assigned even if variable appears on only one '
          'side:', () {
        test('Variable on LHS only', () {
          var x1 = Var('x', identity: 'x1')..errorId = 'X1';
          var x = PatternVariableJoin('x', expectedComponents: [x1]);
          // `x` is considered assigned inside the `true` branch (even though
          // it's not actually assigned on both sides of the or-pattern) because
          // this avoids redundant errors.
          h.run(
            [
              ifCase(
                expr('num?'),
                (x1.pattern().nullCheck.or(wildcard()))..errorId = 'OR',
                [
                  checkAssigned(x, true),
                  // Also verify that the join variable is promotable
                  checkNotPromoted(x),
                  x.as_('int'),
                  checkPromoted(x, 'int'),
                ],
              ),
            ],
            expectedErrors: {
              'logicalOrPatternBranchMissingVariable(node: OR, hasInLeft: '
                  'true, name: x, variable: X1)',
            },
          );
        });

        test('Variable on RHS only', () {
          var x1 = Var('x', identity: 'x1')..errorId = 'X1';
          var x = PatternVariableJoin('x', expectedComponents: [x1]);
          // `x` is considered assigned inside the `true` branch (even though
          // it's not actually assigned on both sides of the or-pattern) because
          // this avoids redundant errors.
          h.run(
            [
              ifCase(
                expr('int?'),
                (wildcard().nullCheck.or(x1.pattern()))..errorId = 'OR',
                [
                  checkAssigned(x, true),
                  // Also verify that the join variable is promotable
                  checkNotPromoted(x),
                  x.nonNullAssert,
                  checkPromoted(x, 'int'),
                ],
              ),
            ],
            expectedErrors: {
              'logicalOrPatternBranchMissingVariable(node: OR, hasInLeft: '
                  'false, name: x, variable: X1)',
            },
          );
        });
      });

      group('Demonstrated type:', () {
        test('LHS <: RHS, both could promote', () {
          // In the circumstance where the LHS and RHS of the logical-or pattern
          // promote the matched value to different types, we don't retain any
          // promotion.  This is similar to how we don't retain any promotion
          // for a test like `if (x is int || x is num)`.
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Object,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(type: 'int').or(wildcard(type: 'num')).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('RHS <: LHS, both could promote', () {
          // In the circumstance where the LHS and RHS of the logical-or pattern
          // promote the matched value to different types, we don't retain any
          // promotion.  This is similar to how we don't retain any promotion
          // for a test like `if (x is int || x is num)`.
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Object,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(type: 'num').or(wildcard(type: 'int')).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('LHS == RHS, could promote', () {
          // In the circumstance where the LHS and RHS of the logical-or pattern
          // promote the matched value to the same type, we do retain the
          // promotion.  This is similar to how we retain the promotion for a
          // test like `if (x is num || x is num)`.
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Object,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(type: 'num').or(wildcard(type: 'num')).recordField(),
              ]),
              [checkPromoted(x, '(num,)')],
            ),
          ]);
        });

        test('LHS <: RHS, only LHS could promote', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(
                  type: 'int',
                ).or(wildcard(type: 'Object')).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('RHS <: LHS, only RHS could promote', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(
                  type: 'Object',
                ).or(wildcard(type: 'int')).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('LHS <: RHS, neither could promote', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(int,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(
                  type: 'num',
                ).or(wildcard(type: 'Object')).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('RHS <: LHS, neither could promote', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(int,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(
                  type: 'Object',
                ).or(wildcard(type: 'num')).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('Does not promote to LUB', () {
          // `if (x case (int _ || double _,)` doesn't promote `x` to `(num,)`.
          // Rationale: we want to be consistent with the behavior of
          // `if (x case int _ || double _)`, which doesn't promote to `num`.
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Object?,)')),
            ifCase(
              x,
              recordPattern([
                wildcard(
                  type: 'int',
                ).or(wildcard(type: 'double')).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });
      });
    });

    group('List pattern:', () {
      group('Not guaranteed to match:', () {
        group('Empty list:', () {
          test('matched value type is non-nullable list', () {
            h.run([
              switch_(expr('List<Object>'), [
                listPattern([]).then([break_()]),
                default_.then([checkReachable(true)]),
              ]),
            ]);
          });

          test('matched value type is nullable list', () {
            var x = Var('x');
            h.run([
              declare(x, initializer: expr('List<Object?>?')),
              switch_(x, [
                listPattern([]).then([
                  checkReachable(true),
                  checkPromoted(x, 'List<Object?>'),
                ]),
                default_.then([checkReachable(true), checkNotPromoted(x)]),
              ]),
            ]);
          });
        });

        test('Single non-rest element', () {
          h.run([
            switch_(expr('List<Object>'), [
              listPattern([wildcard()]).then([break_()]),
              default_.then([checkReachable(true)]),
            ]),
          ]);
        });

        test('Rest pattern with subpattern that may fail to match', () {
          h.run([
            switch_(expr('List<Object>'), [
              listPattern([restPattern(listPattern([]))]).then([break_()]),
              default_.then([checkReachable(true)]),
            ]),
          ]);
        });
      });

      group('Guaranteed to match:', () {
        test('Rest pattern with no subpattern', () {
          h.run([
            switch_(expr('List<Object>'), [
              listPattern([restPattern()]).then([break_()]),
              default_.then([checkReachable(false)]),
            ]),
          ]);
        });

        test('Rest pattern with subpattern that always matches', () {
          h.run([
            switch_(expr('List<Object>'), [
              listPattern([restPattern(wildcard())]).then([break_()]),
              default_.then([checkReachable(false)]),
            ]),
          ]);
        });
      });

      test('Promotes', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(x, listPattern([wildcard()], elementType: 'int'), [
            checkPromoted(x, 'List<int>'),
          ]),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(
            x,
            wildcard()
                .as_('List<int>')
                .and(listPattern([], elementType: 'num'))
                .and(y.pattern(expectInferredType: 'List<int>')),
            [checkPromoted(x, 'List<int>')],
          ),
        ]);
      });

      test('Reachability', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('List<int>')),
          ifCase(
            x,
            listPattern([], elementType: 'int'),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });

      group('Demonstrated type:', () {
        test('Subtype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Iterable<Object>,)')),
            ifCase(
              x,
              recordPattern([
                listPattern([
                  wildcard(type: 'int'),
                ], elementType: 'num').recordField(),
              ]),
              [checkPromoted(x, '(List<num>,)')],
            ),
          ]);
        });

        test('Supertype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(List<num>,)')),
            ifCase(
              x,
              recordPattern([
                listPattern([
                  wildcard(type: 'int'),
                ], elementType: 'Object').recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('Unrelated to matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(List<int?>,)')),
            ifCase(
              x,
              recordPattern([
                listPattern([
                  wildcard(type: 'int'),
                ], elementType: 'num').recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });
      });

      test('Promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), listPattern([]), [
            checkPromoted(c.property('_property'), 'List<Object?>'),
          ]),
        ]);
      });

      test('Promotable property, target changed', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          switch_(c.property('_property'), [
            listPattern([]).when(expr('bool')).then([
              checkPromoted(c.property('_property'), 'List<Object?>'),
            ]),
            wildcard().when(second(c.write(expr('C')), expr('bool'))).then([]),
            listPattern([]).then([checkNotPromoted(c.property('_property'))]),
          ]),
        ]);
      });

      test('Non-promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: false);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), listPattern([]), [
            checkNotPromoted(c.property('_property')),
          ]),
        ]);
      });
    });

    group('Null-aware map entry:', () {
      test('Promotes key within value', () {
        var a = Var('a');

        h.run([
          declare(a, type: 'String?', initializer: expr('String?')),
          mapLiteral(keyType: 'String', valueType: 'dynamic', [
            mapEntry(a, checkPromoted(a, 'String'), isKeyNullAware: true),
          ]),
          checkNotPromoted(a),
        ]);
      });

      test('Non-null-aware key', () {
        var a = Var('a');

        h.run([
          declare(a, type: 'String?', initializer: expr('String?')),
          mapLiteral(keyType: 'String?', valueType: 'dynamic', [
            mapEntry(a, checkNotPromoted(a), isKeyNullAware: false),
          ]),
          checkNotPromoted(a),
        ]);
      });

      test('Promotes', () {
        var a = Var('a');
        var x = Var('x');

        h.run([
          declare(a, type: 'String', initializer: expr('String')),
          declare(x, type: 'num', initializer: expr('num')),
          mapLiteral(keyType: 'String', valueType: 'dynamic', [
            mapEntry(a, x.as_('int'), isKeyNullAware: true),
          ]),
          checkPromoted(x, 'int'),
        ]);
      });

      test('Affects promotion', () {
        var a = Var('a');
        var x = Var('x');

        h.run([
          declare(a, type: 'String?', initializer: expr('String?')),
          declare(x, type: 'num', initializer: expr('num')),
          mapLiteral(keyType: 'String', valueType: 'dynamic', [
            mapEntry(a, x.as_('int'), isKeyNullAware: true),
          ]),
          checkNotPromoted(x),
        ]);
      });

      test('Unreachable', () {
        var a = Var('a');
        h.run([
          declare(a, type: 'String', initializer: expr('String')),
          mapLiteral(keyType: 'String', valueType: 'dynamic', [
            mapEntry(a, throw_(expr('Object')), isKeyNullAware: true),
          ]),
          checkReachable(false),
        ]);
      });

      test('Reachable', () {
        var a = Var('a');
        h.run([
          declare(a, type: 'String?', initializer: expr('String?')),
          mapLiteral(keyType: 'String', valueType: 'dynamic', [
            mapEntry(a, throw_(expr('Object')), isKeyNullAware: true),
          ]),
          checkReachable(true),
        ]);
      });
    });

    group('Map pattern:', () {
      test('Promotes', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(
            x,
            mapPattern(
              [mapPatternEntry(intLiteral(0), wildcard())],
              keyType: 'int',
              valueType: 'String',
            ),
            [checkPromoted(x, 'Map<int, String>')],
          ),
        ]);
      });

      test('Match failure reachable', () {
        h.run([
          ifCase(
            expr('Object?'),
            mapPattern([mapPatternEntry(expr('Object'), wildcard())]),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(
            x,
            wildcard()
                .as_('Map<int, int>')
                .and(
                  mapPattern(
                    [mapPatternEntry(expr('Object'), wildcard())],
                    keyType: 'num',
                    valueType: 'num',
                  ),
                )
                .and(y.pattern(expectInferredType: 'Map<int, int>')),
            [checkPromoted(x, 'Map<int, int>')],
          ),
        ]);
      });

      test('Reachability', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Map<int, int>')),
          ifCase(
            x,
            mapPattern(
              [mapPatternEntry(expr('Object'), wildcard())],
              keyType: 'int',
              valueType: 'int',
            ),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });

      group('Demonstrated type:', () {
        test('Subtype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Map<num?, Object>?,)')),
            ifCase(
              x,
              recordPattern([
                mapPattern(
                  [mapPatternEntry(intLiteral(0), wildcard(type: 'int'))],
                  keyType: 'int?',
                  valueType: 'num',
                ).recordField(),
              ]),
              [checkPromoted(x, '(Map<int?, num>,)')],
            ),
          ]);
        });

        test('Supertype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Map<int, num>,)')),
            ifCase(
              x,
              recordPattern([
                mapPattern(
                  [mapPatternEntry(intLiteral(0), wildcard(type: 'int'))],
                  keyType: 'int',
                  valueType: 'Object',
                ).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('Unrelated to matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(Map<int, int?>,)')),
            ifCase(
              x,
              recordPattern([
                mapPattern(
                  [mapPatternEntry(intLiteral(0), wildcard(type: 'int'))],
                  keyType: 'int',
                  valueType: 'num',
                ).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });
      });

      test('Promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(
            c.property('_property'),
            mapPattern([mapPatternEntry(intLiteral(0), wildcard())]),
            [checkPromoted(c.property('_property'), 'Map<Object?, Object?>')],
          ),
        ]);
      });

      test('Promotable property, target changed', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          switch_(c.property('_property'), [
            mapPattern([
              mapPatternEntry(intLiteral(0), wildcard()),
            ]).when(expr('bool')).then([
              checkPromoted(c.property('_property'), 'Map<Object?, Object?>'),
            ]),
            wildcard().when(second(c.write(expr('C')), expr('bool'))).then([]),
            mapPattern([
              mapPatternEntry(intLiteral(0), wildcard()),
            ]).then([checkNotPromoted(c.property('_property'))]),
          ]),
        ]);
      });

      test('Non-promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: false);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(
            c.property('_property'),
            mapPattern([mapPatternEntry(intLiteral(0), wildcard())]),
            [checkNotPromoted(c.property('_property'))],
          ),
        ]);
      });
    });

    group('Null-assert:', () {
      test('Throws if not null', () {
        h.run([
          ifCase(expr('Object?'), wildcard().nullAssert, [], [
            checkReachable(false),
          ]),
        ]);
      });

      group('Scrutinee promotion:', () {
        test('If changed', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            switch_(x, [
              wildcard()
                  .when(second(x.write(expr('Object?')), expr('bool')))
                  .then([break_()]),
              wildcard().nullAssert.then([checkNotPromoted(x)]),
            ]),
          ]);
        });

        test('If unchanged', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            ifCase(
              x,
              wildcard().nullAssert,
              [checkPromoted(x, 'Object')],
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('If subpattern', () {
          // Equivalent Dart code:
          //     typedef T = int?;
          //     extension on T {
          //       dynamic get foo { ... }
          //     }
          //     f(Object? x) {
          //       if (x case T(foo: _!)) {
          //         // x still might be `null`
          //       }
          //     }
          TypeRegistry.addInterfaceTypeName('T');
          h.addDownwardInfer(name: 'T', context: 'Object?', result: 'int?');
          h.addMember('int?', 'foo', 'dynamic');
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            ifCase(
              x,
              objectPattern(
                requiredType: 'T',
                fields: [wildcard().nullAssert.recordField('foo')],
              ),
              [checkPromoted(x, 'int?')],
            ),
          ]);
        });

        test('If promotable property', () {
          h.addMember('C', '_property', 'int?', promotable: true);
          var c = Var('c');
          h.run([
            declare(c, initializer: expr('C')),
            ifCase(c.property('_property'), wildcard().nullAssert, [
              checkPromoted(c.property('_property'), 'int'),
            ]),
          ]);
        });

        test('If promotable property, target changed', () {
          h.addMember('C', '_property', 'int?', promotable: true);
          var c = Var('c');
          h.run(
            [
              declare(c, initializer: expr('C')),
              switch_(c.property('_property'), [
                wildcard().nullAssert.when(expr('bool')).then([
                  checkPromoted(c.property('_property'), 'int'),
                ]),
                wildcard()
                    .when(second(c.write(expr('C')), expr('bool')))
                    .then([]),
                (wildcard().nullAssert..errorId = 'SECOND_NULL_ASSERT').then([
                  checkNotPromoted(c.property('_property')),
                ]),
              ]),
            ],
            expectedErrors: {
              'matchedTypeIsStrictlyNonNullable('
                  'pattern: SECOND_NULL_ASSERT, matchedType: int)',
            },
          );
        });

        test('If non-promotable property', () {
          h.addMember('C', '_property', 'int?', promotable: false);
          var c = Var('c');
          h.run([
            declare(c, initializer: expr('C')),
            ifCase(c.property('_property'), wildcard().nullAssert, [
              checkNotPromoted(c.property('_property')),
            ]),
          ]);
        });
      });

      test('Promotes temporary variable', () {
        h.run(
          [
            ifCase(
              expr('Object?'),
              wildcard().nullAssert.and(
                wildcard(expectInferredType: 'Object')..errorId = 'WILDCARD',
              ),
              [],
            ),
          ],
          expectedErrors: {
            'unnecessaryWildcardPattern(pattern: WILDCARD, '
                'kind: logicalAndPatternOperand)',
          },
        );
      });

      test('Unreachable if null', () {
        h.run([
          ifCase(expr('Null'), wildcard().nullAssert, [checkReachable(false)]),
        ]);
      });

      test('Reachable otherwise', () {
        h.run([
          ifCase(expr('Object?'), wildcard().nullAssert, [
            checkReachable(true),
          ]),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(
            x,
            wildcard()
                .as_('int?')
                .and(wildcard().nullAssert)
                .and(y.pattern(expectInferredType: 'int')),
            [checkPromoted(x, 'int')],
          ),
        ]);
      });

      test('Demonstrated type', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('(int?,)')),
          ifCase(x, recordPattern([wildcard().nullAssert.recordField()]), [
            checkPromoted(x, '(int,)'),
          ]),
        ]);
      });
    });

    group('Null-check:', () {
      test('Might not match', () {
        h.run([
          ifCase(expr('Object?'), wildcard().nullCheck, [], [
            checkReachable(true),
          ]),
        ]);
      });

      group('Scrutinee promotion:', () {
        test('If changed', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            switch_(x, [
              wildcard()
                  .when(second(x.write(expr('Object?')), expr('bool')))
                  .then([break_()]),
              wildcard().nullCheck.then([checkNotPromoted(x)]),
            ]),
          ]);
        });

        test('If unchanged', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            ifCase(
              x,
              wildcard().nullCheck,
              [checkPromoted(x, 'Object')],
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('If subpattern', () {
          // Equivalent Dart code:
          //     typedef T = int?;
          //     extension on T {
          //       dynamic get foo { ... }
          //     }
          //     f(Object? x) {
          //       if (x case T(foo: _?)) {
          //         // x still might be `null`
          //       }
          //     }
          TypeRegistry.addInterfaceTypeName('T');
          h.addDownwardInfer(name: 'T', context: 'Object?', result: 'int?');
          h.addMember('int?', 'foo', 'dynamic');
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            ifCase(
              x,
              objectPattern(
                requiredType: 'T',
                fields: [wildcard().nullCheck.recordField('foo')],
              ),
              [checkPromoted(x, 'int?')],
            ),
          ]);
        });

        test('If promotable property', () {
          h.addMember('C', '_property', 'int?', promotable: true);
          var c = Var('c');
          h.run([
            declare(c, initializer: expr('C')),
            ifCase(c.property('_property'), wildcard().nullCheck, [
              checkPromoted(c.property('_property'), 'int'),
            ]),
          ]);
        });

        test('If promotable property, target changed', () {
          h.addMember('C', '_property', 'int?', promotable: true);
          var c = Var('c');
          h.run([
            declare(c, initializer: expr('C')),
            switch_(c.property('_property'), [
              wildcard().nullCheck.when(expr('bool')).then([
                checkPromoted(c.property('_property'), 'int'),
              ]),
              wildcard()
                  .when(second(c.write(expr('C')), expr('bool')))
                  .then([]),
              wildcard().nullCheck.then([
                checkNotPromoted(c.property('_property')),
              ]),
            ]),
          ]);
        });

        test('If non-promotable property', () {
          h.addMember('C', '_property', 'int?', promotable: false);
          var c = Var('c');
          h.run([
            declare(c, initializer: expr('C')),
            ifCase(c.property('_property'), wildcard().nullCheck, [
              checkNotPromoted(c.property('_property')),
            ]),
          ]);
        });
      });

      test('Promotes temporary variable', () {
        h.run(
          [
            ifCase(
              expr('Object?'),
              wildcard().nullCheck.and(
                wildcard(expectInferredType: 'Object')..errorId = 'WILDCARD',
              ),
              [],
            ),
          ],
          expectedErrors: {
            'unnecessaryWildcardPattern(pattern: WILDCARD, '
                'kind: logicalAndPatternOperand)',
          },
        );
      });

      test('Unreachable if null', () {
        h.run([
          ifCase(expr('Null'), wildcard().nullCheck, [checkReachable(false)]),
        ]);
      });

      test('Reachable otherwise', () {
        h.run([
          ifCase(expr('Object?'), wildcard().nullCheck, [checkReachable(true)]),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(
            x,
            wildcard()
                .as_('int?')
                .and(wildcard().nullCheck)
                .and(y.pattern(expectInferredType: 'int')),
            [checkPromoted(x, 'int')],
          ),
        ]);
      });

      test('Demonstrated type', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('(int?,)')),
          ifCase(x, recordPattern([wildcard().nullCheck.recordField()]), [
            checkPromoted(x, '(int,)'),
          ]),
        ]);
      });
    });

    group('Object pattern:', () {
      test('Promotes', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(x, objectPattern(requiredType: 'int', fields: []), [
            checkPromoted(x, 'int'),
          ]),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(
            x,
            wildcard()
                .as_('int')
                .and(objectPattern(requiredType: 'num', fields: []))
                .and(y.pattern(expectInferredType: 'int')),
            [checkPromoted(x, 'int')],
          ),
        ]);
      });

      group('Demonstrated type:', () {
        test('Subtype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(
              x,
              recordPattern([
                objectPattern(requiredType: 'int', fields: []).recordField(),
              ]),
              [checkPromoted(x, '(int,)')],
            ),
          ]);
        });

        test('Supertype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(
              x,
              recordPattern([
                objectPattern(requiredType: 'Object', fields: []).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('Unrelated to matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(
              x,
              recordPattern([
                objectPattern(requiredType: 'String', fields: []).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });
      });

      test('Read of Never typed getter makes unreachable', () {
        h.addDownwardInfer(name: 'A', context: 'Object', result: 'A');
        h.addMember('A', 'foo', 'Never');
        h.run([
          ifCase(
            expr('Object'),
            objectPattern(
              requiredType: 'A',
              fields: [Var('foo').pattern().recordField('foo')],
            ),
            [checkReachable(false)],
          ),
        ]);
      });

      test('Promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(
            c.property('_property'),
            objectPattern(requiredType: 'int', fields: []),
            [checkPromoted(c.property('_property'), 'int')],
          ),
        ]);
      });

      test('Promotable property, target changed', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          switch_(c.property('_property'), [
            objectPattern(requiredType: 'int', fields: [])
                .when(expr('bool'))
                .then([checkPromoted(c.property('_property'), 'int')]),
            wildcard().when(second(c.write(expr('C')), expr('bool'))).then([]),
            objectPattern(
              requiredType: 'int',
              fields: [],
            ).then([checkNotPromoted(c.property('_property'))]),
          ]),
        ]);
      });

      test('Non-promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: false);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(
            c.property('_property'),
            objectPattern(requiredType: 'int', fields: []),
            [checkNotPromoted(c.property('_property'))],
          ),
        ]);
      });
    });

    group('Pattern assignment:', () {
      test('Does not promote RHS', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('num')),
          wildcard().as_('int').assign(x),
          checkNotPromoted(x),
        ]);
      });
    });

    group('Pattern variable declaration:', () {
      test('Does not promote RHS', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('num')),
          patternVariableDeclaration(wildcard().as_('int'), x),
          checkNotPromoted(x),
        ]);
      });
    });

    group('Record pattern:', () {
      test('Simple promotion', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(x, recordPattern([wildcard().recordField()]), [
            checkPromoted(x, '(Object?,)'),
          ]),
        ]);
      });

      group('Promote to demonstrated type:', () {
        test('Unnamed fields', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            ifCase(
              x,
              recordPattern([
                wildcard(type: 'int').recordField(),
                wildcard(type: 'String').recordField(),
              ]),
              [checkPromoted(x, '(int, String)')],
            ),
          ]);
        });

        test('Named fields', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            ifCase(
              x,
              recordPattern([
                wildcard(type: 'int').recordField('i'),
                wildcard(type: 'String').recordField('s'),
              ]),
              [checkPromoted(x, '({int i, String s})')],
            ),
          ]);
        });
      });

      test('Required type is a type of interest', () {
        // The required type is `(Object?,)`.  Since that's the type used in the
        // desugared type test, it's considered a type of interest even though
        // the scrutinee is initially promoted to `(int,)`.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          ifCase(x, recordPattern([wildcard(type: 'int').recordField()]), [
            checkPromoted(x, '(int,)'),
            x.write(expr('(num,)')),
            checkPromoted(x, '(Object?,)'),
          ]),
        ]);
      });

      test('Promotion to demonstrated type cannot fail', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('(Object?,)')),
          ifCase(
            x,
            recordPattern([wildcard().as_('int').recordField()]),
            [checkPromoted(x, '(int,)')],
            [checkReachable(false)],
          ),
        ]);
      });

      test('Match failure reachable', () {
        h.run([
          ifCase(
            expr('Object?'),
            recordPattern([wildcard().recordField()]),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(
            x,
            wildcard()
                .as_('(int,)')
                .and(recordPattern([wildcard().recordField()]))
                .and(y.pattern(expectInferredType: '(int,)')),
            [checkPromoted(x, '(int,)')],
          ),
        ]);
      });

      group('Demonstrated type:', () {
        test('Subtype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('((num,),)')),
            ifCase(
              x,
              recordPattern([
                recordPattern([
                  wildcard(type: 'int').recordField(),
                ]).recordField(),
              ]),
              [checkPromoted(x, '((int,),)')],
            ),
          ]);
        });

        test('Supertype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Never')),
            ifCase(
              x,
              recordPattern([
                recordPattern([
                  wildcard(type: 'num').recordField(),
                ]).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('Unrelated to matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('String')),
            ifCase(
              x,
              recordPattern([
                recordPattern([
                  wildcard(type: 'num').recordField(),
                ]).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });
      });

      test('Error type does not alter previous reachability conclusions', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('(Null, Object?)')),
          ifCase(
            x,
            recordPattern([
              relationalPattern('!=', nullLiteral).recordField(),
              wildcard(type: 'error').recordField(),
            ]),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('Promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), recordPattern([]), [
            checkPromoted(c.property('_property'), '()'),
          ]),
        ]);
      });

      test('Promotable property, target changed', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          switch_(c.property('_property'), [
            recordPattern([]).when(expr('bool')).then([
              checkPromoted(c.property('_property'), '()'),
            ]),
            wildcard().when(second(c.write(expr('C')), expr('bool'))).then([]),
            recordPattern([]).then([checkNotPromoted(c.property('_property'))]),
          ]),
        ]);
      });

      test('Non-promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: false);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), recordPattern([]), [
            checkNotPromoted(c.property('_property')),
          ]),
        ]);
      });
    });

    group('Relational pattern:', () {
      group('==:', () {
        test('Guaranteed match due to Null type', () {
          h.run([
            ifCase(
              expr('Null'),
              relationalPattern('==', nullLiteral),
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ]);
        });

        test('Guaranteed match due to Null type in subpattern', () {
          h.run([
            ifCase(
              expr('(Null,)'),
              recordPattern([
                relationalPattern('==', nullLiteral).recordField(),
              ]),
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ]);
        });

        test('In the general case, may or may not match', () {
          h.run([
            ifCase(
              expr('Object?'),
              relationalPattern('==', intLiteral(0)),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]);
        });

        test('Using dot shorthands in relational pattern', () {
          h.addMember('C', 'field', 'C');
          h.run([
            ifCase(
              expr('C'),
              relationalPattern('==', dotShorthandHead('field').dotShorthand),
              [checkReachable(true)],
            ),
          ]);
        });

        test('Null pattern promotes unchanged scrutinee', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('int?')),
            ifCase(
              x,
              relationalPattern('==', nullLiteral),
              [checkReachable(true), checkNotPromoted(x)],
              [checkReachable(true), checkPromoted(x, 'int')],
            ),
          ]);
        });

        test("Null pattern doesn't promote changed scrutinee", () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('int?')),
            switch_(x, [
              wildcard().when(second(x.write(expr('int?')), expr('bool'))).then(
                [break_()],
              ),
              relationalPattern(
                '==',
                nullLiteral,
              ).then([checkReachable(true), checkNotPromoted(x)]),
              wildcard(
                expectInferredType: 'int',
              ).then([checkReachable(true), checkNotPromoted(x)]),
            ]),
          ]);
        });

        test('Null pattern promotes matched pattern var', () {
          h.run([
            ifCase(
              expr('int?'),
              relationalPattern(
                '==',
                nullLiteral,
              ).or(wildcard(expectInferredType: 'int')),
              [],
            ),
          ]);
        });

        group('Demonstrated type:', () {
          test('== value', () {
            // The demonstrated type of a relational pattern using `==` is the
            // matched value type.
            var x = Var('x');
            h.run([
              declare(x, initializer: expr('(Object?,)')),
              ifCase(
                x,
                recordPattern([
                  relationalPattern('==', expr('Object')).recordField(),
                ]),
                [checkNotPromoted(x)],
              ),
            ]);
          });

          test('== null', () {
            // The demonstrated type of a relational pattern using `==` is the
            // matched value type, even in the case of `== null`, because we
            // don't promote to the `Null` type.
            var x = Var('x');
            h.run([
              declare(x, initializer: expr('(Object?,)')),
              ifCase(
                x,
                recordPattern([
                  relationalPattern('==', nullLiteral).recordField(),
                ]),
                [checkNotPromoted(x)],
              ),
            ]);
          });
        });
      });

      group('!=:', () {
        test('Guaranteed mismatch due to Null type', () {
          h.run([
            ifCase(
              expr('Null'),
              relationalPattern('!=', nullLiteral),
              [checkReachable(false)],
              [checkReachable(true)],
            ),
          ]);
        });

        test('In the general case, may or may not match', () {
          h.run([
            ifCase(
              expr('Object?'),
              relationalPattern('!=', intLiteral(0)),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]);
        });

        test('Null pattern promotes unchanged scrutinee', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('int?')),
            ifCase(
              x,
              relationalPattern('!=', nullLiteral),
              [checkReachable(true), checkPromoted(x, 'int')],
              [checkReachable(true), checkNotPromoted(x)],
            ),
          ]);
        });

        test("Null pattern doesn't promote changed scrutinee", () {
          var x = Var('x');
          h.run(
            [
              declare(x, initializer: expr('int?')),
              switch_(x, [
                wildcard()
                    .when(second(x.write(expr('int?')), expr('bool')))
                    .then([break_()]),
                relationalPattern('!=', nullLiteral)
                    .and(
                      wildcard(expectInferredType: 'int')..errorId = 'WILDCARD',
                    )
                    .then([checkReachable(true), checkNotPromoted(x)]),
              ]),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        test('Null pattern promotes matched pattern var', () {
          h.run(
            [
              ifCase(
                expr('int?'),
                relationalPattern('!=', nullLiteral).and(
                  wildcard(expectInferredType: 'int')..errorId = 'WILDCARD',
                ),
                [],
              ),
            ],
            expectedErrors: {
              'unnecessaryWildcardPattern(pattern: WILDCARD, '
                  'kind: logicalAndPatternOperand)',
            },
          );
        });

        group('Demonstrated type:', () {
          test('!= value', () {
            // The demonstrated type of a relational pattern using `!=` is
            // usually the matched value type.
            var x = Var('x');
            h.run([
              declare(x, initializer: expr('(Object?,)')),
              ifCase(
                x,
                recordPattern([
                  relationalPattern('!=', expr('Object')).recordField(),
                ]),
                [checkNotPromoted(x)],
              ),
            ]);
          });

          test('!= null', () {
            // The demonstrated type of the relational pattern `!= null` is the
            // matched value type promoted to non-nullable.
            var x = Var('x');
            h.run([
              declare(x, initializer: expr('(Object?,)')),
              ifCase(
                x,
                recordPattern([
                  relationalPattern('!=', nullLiteral).recordField(),
                ]),
                [checkPromoted(x, '(Object,)')],
              ),
            ]);
          });
        });
      });

      group('other:', () {
        test('Does not assume anything, even though == or != would', () {
          // This is a bit of a contrived test case, since it exercises
          // `null < null`.  But such a thing is possible with extension
          // methods.
          h.addMember('Null', '<', 'bool Function(Object?)');
          h.run([
            ifCase(
              expr('Null'),
              relationalPattern('<', nullLiteral),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]);
        });

        test('Demonstrated type', () {
          // The demonstrated type of a relational pattern using a
          // non-equality operator is the matched value type.
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(int,)')),
            ifCase(
              x,
              recordPattern([
                relationalPattern('>', intLiteral(0)).recordField(),
              ]),
              [checkNotPromoted(x)],
            ),
          ]);
        });
      });
    });

    group('Switch expression:', () {
      test('guarded', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?'),
          switchExpr(expr('Object'), [
            wildcard()
                .when(x.notEq(nullLiteral))
                .thenExpr(
                  second(
                    listLiteral(elementType: 'dynamic', [
                      checkReachable(true),
                      checkPromoted(x, 'int'),
                    ]),
                    expr('String'),
                  ),
                ),
            wildcard().thenExpr(
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  checkNotPromoted(x),
                ]),
                expr('String'),
              ),
            ),
          ]),
        ]);
      });

      group('guard promotes later cases:', () {
        test('when pattern fully covers the scrutinee type', () {
          // `case _ when x == null:` promotes `x` to non-null in later cases,
          // because the implicit type of `_` fully covers the scrutinee type.
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            switchExpr(expr('Object?'), [
              wildcard().when(x.eq(nullLiteral)).thenExpr(intLiteral(0)),
              wildcard().thenExpr(
                second(checkPromoted(x, 'int'), intLiteral(1)),
              ),
            ]),
          ]);
        });

        test('when pattern does not fully cover the scrutinee type', () {
          // `case String _ when x == null:` does not promote `y` to non-null in
          // later cases, because the type `String` does not fully cover the
          // scrutinee type.
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            switchExpr(expr('Object?'), [
              wildcard(
                type: 'String',
              ).when(x.eq(nullLiteral)).thenExpr(intLiteral(0)),
              wildcard().thenExpr(
                second(
                  listLiteral(elementType: 'dynamic', [checkNotPromoted(x)]),
                  intLiteral(1),
                ),
              ),
            ]),
          ]);
        });
      });

      test('promotes scrutinee', () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'num'),
          switchExpr(x, [
            y
                .pattern(type: 'int')
                .thenExpr(
                  second(
                    listLiteral(elementType: 'dynamic', [
                      checkReachable(true),
                      checkPromoted(x, 'int'),
                    ]),
                    expr('String'),
                  ),
                ),
            wildcard().thenExpr(
              second(
                listLiteral(elementType: 'dynamic', [
                  checkReachable(true),
                  checkNotPromoted(x),
                ]),
                expr('String'),
              ),
            ),
          ]),
        ]);
      });

      test('reassigned scrutinee var no longer promotes', () {
        var x = Var('x');
        // Note that the second `wildcard(type: 'int')` doesn't promote `x`
        // because it's been reassigned.  But it does still promote the
        // scrutinee in the RHS of the `&&`.
        h.run(
          [
            declare(x, initializer: expr('Object')),
            switchExpr(x, [
              wildcard(type: 'int')
                  .and(
                    wildcard(expectInferredType: 'int')..errorId = 'WILDCARD1',
                  )
                  .thenExpr(second(checkPromoted(x, 'int'), intLiteral(0))),
              wildcard()
                  .when(second(x.write(expr('Object')), expr('bool')))
                  .thenExpr(intLiteral(1)),
              wildcard(type: 'int')
                  .and(
                    wildcard(expectInferredType: 'int')..errorId = 'WILDCARD2',
                  )
                  .thenExpr(second(checkNotPromoted(x), intLiteral(2))),
              wildcard().thenExpr(intLiteral(3)),
            ]),
          ],
          expectedErrors: {
            'unnecessaryWildcardPattern(pattern: WILDCARD1, '
                'kind: logicalAndPatternOperand)',
            'unnecessaryWildcardPattern(pattern: WILDCARD2, '
                'kind: logicalAndPatternOperand)',
          },
        );
      });

      test('cached scrutinee retains promoted type even if scrutinee var '
          'reassigned', () {
        var x = Var('x');
        var y = Var('y');
        // `x` is promoted at the time the scrutinee is cached.  Therefore, even
        // though `case _ where f(x = ...)` de-promotes `x`, the promoted type
        // is still used for type inference in the later `case var y`.
        h.run([
          declare(x, initializer: expr('Object')),
          x.as_('int'),
          checkPromoted(x, 'int'),
          switchExpr(x, [
            wildcard()
                .when(second(x.write(expr('Object')), expr('bool')))
                .thenExpr(intLiteral(0)),
            y
                .pattern(expectInferredType: 'int')
                .thenExpr(second(checkNotPromoted(x), intLiteral(1))),
          ]),
        ]);
      });

      test('no cases', () {
        h.run([switchExpr(expr('A'), []), checkReachable(false)]);
      });

      test('error type does not make following cases unreachable', () {
        // We don't know the correct type, so recover by expecting that the
        // following cases still will be useful once the error is fixed.
        h.run([
          switchExpr(expr('num'), [
            wildcard(
              type: 'error',
            ).thenExpr(second(checkReachable(true), intLiteral(0))),
            wildcard().thenExpr(second(checkReachable(true), intLiteral(1))),
          ]),
        ]);
      });
    });

    group('Switch statement:', () {
      test('guarded', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int?'),
          switch_(expr('Object'), [
            switchStatementMember(
              [wildcard().when(x.notEq(nullLiteral))],
              [checkReachable(true), checkPromoted(x, 'int')],
            ),
            switchStatementMember(
              [default_],
              [checkReachable(true), checkNotPromoted(x)],
            ),
          ]),
        ]);
      });

      group('guard promotes later cases:', () {
        test('when pattern fully covers the scrutinee type', () {
          // `case _ when x == null:` promotes `x` to non-null in later cases,
          // because the implicit type of `_` fully covers the scrutinee type.
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            switch_(expr('Object?'), [
              wildcard().when(x.eq(nullLiteral)).then([break_()]),
              wildcard().then([checkPromoted(x, 'int')]),
            ]),
          ]);
        });

        test('when pattern does not fully cover the scrutinee type', () {
          // `case String _ when x == null:` does not promote `x` to non-null in
          // later cases, because the type `String` does not fully cover the
          // scrutinee type.
          var x = Var('x');
          h.run([
            declare(x, type: 'int?'),
            switch_(expr('Object?'), [
              wildcard(type: 'String').when(x.eq(nullLiteral)).then([break_()]),
              wildcard().then([checkNotPromoted(x)]),
            ]),
          ]);
        });
      });

      test('promotes scrutinee', () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, type: 'num'),
          switch_(x, [
            switchStatementMember(
              [y.pattern(type: 'int')],
              [checkReachable(true), checkPromoted(x, 'int')],
            ),
            switchStatementMember(
              [default_],
              [checkReachable(true), checkNotPromoted(x)],
            ),
          ]),
        ]);
      });

      test('implicit break', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'Object'),
          switch_(expr('Object'), [
            switchStatementMember([wildcard(type: 'int')], [x.as_('int')]),
            switchStatementMember([default_], [return_()]),
          ]),
          checkReachable(true),
          checkPromoted(x, 'int'),
        ]);
      });

      group('exhaustiveness:', () {
        test('exhaustive', () {
          h.addExhaustiveness('E', true);
          h.run([
            switch_(expr('E'), [
              switchStatementMember([expr('E').pattern], [return_()]),
            ]),
            checkReachable(false),
          ]);
        });

        test('non-exhaustive', () {
          h.run([
            switch_(expr('int'), [
              switchStatementMember([intLiteral(0).pattern], [return_()]),
            ]),
            checkReachable(true),
          ]);
        });
      });

      group('pre-patterns exhaustiveness:', () {
        test('exhaustive', () {
          h.disablePatterns();
          h.run([
            switch_(expr('E'), [
              switchStatementMember([expr('E').pattern], [return_()]),
            ], isLegacyExhaustive: true),
            checkReachable(false),
          ]);
        });

        test('non-exhaustive', () {
          h.disablePatterns();
          h.run([
            switch_(expr('E'), [
              switchStatementMember([expr('E').pattern], [return_()]),
            ], isLegacyExhaustive: false),
            checkReachable(true),
          ]);
        });
      });

      test('empty exhaustive', () {
        // This can happen if a class is marked `sealed` but has no subclasses.
        // Note that exhaustiveness checking of "always exhaustive" types is
        // deferred until a later analysis stage (so that it can take constant
        // evaluation into account), so flow analysis simply assumes that the
        // switch is exhaustive without checking, and sets the
        // `requiresExhaustivenessValidation` flag to let the client know that
        // exhaustiveness checking must be performed later.  Had this been a
        // real compilation (and not just a unit test), exhaustiveness checking
        // would later confirm that the class `C` has no subclasses, or report
        // a compile-time error.
        h.addExhaustiveness('C', true);
        h.run([
          switch_(expr('C'), [], expectRequiresExhaustivenessValidation: true),
          checkReachable(false),
        ]);
      });

      group('Nested:', () {
        test('scrutinee type', () {
          // Verify that the inner switch's matched value type doesn't bleed out
          // to the next case in the outer switch.
          h.run([
            switch_(expr('int'), [
              wildcard(expectInferredType: 'int').when(expr('bool')).then([
                switch_(expr('String'), [
                  wildcard(expectInferredType: 'String').then([]),
                ]),
              ]),
              wildcard(expectInferredType: 'int').then([]),
            ]),
          ]);
        });

        test('scrutinee reference', () {
          // Verify that the inner switch's scrutinee reference is properly
          // distinguished from the outer switch's scrutinee reference.
          var x = Var('x');
          var y = Var('x');
          h.run([
            declare(x, initializer: expr('Object')),
            declare(y, initializer: expr('Object')),
            switch_(x, [
              wildcard(type: 'num').then([
                checkPromoted(x, 'num'),
                checkNotPromoted(y),
                switch_(y, [
                  wildcard(
                    type: 'int',
                  ).then([checkPromoted(x, 'num'), checkPromoted(y, 'int')]),
                  default_.then([return_()]),
                ]),
                checkPromoted(x, 'num'),
                checkPromoted(y, 'int'),
              ]),
              wildcard(
                type: 'String',
              ).then([checkPromoted(x, 'String'), checkNotPromoted(y)]),
            ]),
          ]);
        });
      });

      test('reassigned scrutinee var no longer promotes', () {
        var x = Var('x');
        // Note that the second `wildcard(type: 'int')` doesn't promote `x`
        // because it's been reassigned.  But it does still promote the
        // scrutinee in the RHS of the `&&`.
        h.run(
          [
            declare(x, initializer: expr('Object')),
            switch_(x, [
              wildcard(type: 'int')
                  .and(
                    wildcard(expectInferredType: 'int')..errorId = 'WILDCARD1',
                  )
                  .then([checkPromoted(x, 'int')]),
              wildcard()
                  .when(second(x.write(expr('Object')), expr('bool')))
                  .then([break_()]),
              wildcard(type: 'int')
                  .and(
                    wildcard(expectInferredType: 'int')..errorId = 'WILDCARD2',
                  )
                  .then([checkNotPromoted(x)]),
            ]),
          ],
          expectedErrors: {
            'unnecessaryWildcardPattern(pattern: WILDCARD1, '
                'kind: logicalAndPatternOperand)',
            'unnecessaryWildcardPattern(pattern: WILDCARD2, '
                'kind: logicalAndPatternOperand)',
          },
        );
      });

      test('cached scrutinee retains promoted type even if scrutinee var '
          'reassigned', () {
        var x = Var('x');
        var y = Var('y');
        // `x` is promoted at the time the scrutinee is cached.  Therefore, even
        // though `case _ where f(x = ...)` de-promotes `x`, the promoted type
        // is still used for type inference in the later `case var y`.
        h.run([
          declare(x, initializer: expr('Object')),
          x.as_('int'),
          checkPromoted(x, 'int'),
          switch_(x, [
            wildcard().when(second(x.write(expr('Object')), expr('bool'))).then(
              [break_()],
            ),
            y.pattern(expectInferredType: 'int').then([checkNotPromoted(x)]),
          ]),
        ]);
      });

      test('synthetic break inserted even in unreachable cases', () {
        // In this example, the second case is unreachable, so technically it
        // doesn't matter whether it ends in a synthetic break.  However, to
        // avoid confusion on the part of the CFE and back-end developers, we go
        // ahead and put in the synthetic break anyhow.
        h.run([
          switch_(expr('Object'), [
            wildcard().then([intLiteral(0)]),
            wildcard().then([intLiteral(1)]),
          ]).checkIR(
            'switch(expr(Object), '
            'case(heads(head(wildcardPattern(matchedType: Object), true, '
            'variables()), variables()), block(stmt(0), synthetic-break())), '
            'case(heads(head(wildcardPattern(matchedType: Object), true, '
            'variables()), variables()), '
            'block(stmt(1), synthetic-break())))',
          ),
        ]);
      });

      test('error type does not make following cases unreachable', () {
        // We don't know the correct type, so recover by expecting that the
        // following cases still will be useful once the error is fixed.
        h.run([
          switch_(expr('num'), [
            wildcard(type: 'error').then([checkReachable(true)]),
            wildcard().then([checkReachable(true)]),
          ]),
        ]);
      });

      group('Joins promotions of scrutinee:', () {
        test('First case more promoted', () {
          var x = Var('x');
          // ` case num() && int(): case num():` retains promotion to `num`
          h.run([
            declare(x, initializer: expr('Object')),
            switch_(x, [
              switchStatementMember(
                [
                  objectPattern(
                    requiredType: 'num',
                    fields: [],
                  ).and(objectPattern(requiredType: 'int', fields: [])),
                  objectPattern(requiredType: 'num', fields: []),
                ],
                [checkPromoted(x, 'num')],
              ),
            ]),
          ]);
        });

        test('Second case more promoted', () {
          var x = Var('x');
          // `case num(): case num() && int():` retains promotion to `num`
          h.run([
            declare(x, initializer: expr('Object')),
            switch_(x, [
              switchStatementMember(
                [
                  objectPattern(requiredType: 'num', fields: []),
                  objectPattern(
                    requiredType: 'num',
                    fields: [],
                  ).and(objectPattern(requiredType: 'int', fields: [])),
                ],
                [checkPromoted(x, 'num')],
              ),
            ]),
          ]);
        });
      });

      group('Joins explicitly declared variables:', () {
        test('First var promoted', () {
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            switch_(expr('(int, int?)'), [
              switchStatementMember(
                [
                  recordPattern([
                    intLiteral(0).pattern.recordField(),
                    x1.pattern(type: 'int?').nullCheck.recordField(),
                  ]),
                  recordPattern([
                    intLiteral(1).pattern.recordField(),
                    x2.pattern(type: 'int?').recordField(),
                  ]),
                ],
                [checkNotPromoted(x)],
              ),
            ]),
          ]);
        });

        test('Second var promoted', () {
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            switch_(expr('(int, int?)'), [
              switchStatementMember(
                [
                  recordPattern([
                    intLiteral(0).pattern.recordField(),
                    x1.pattern(type: 'int?').recordField(),
                  ]),
                  recordPattern([
                    intLiteral(1).pattern.recordField(),
                    x2.pattern(type: 'int?').nullCheck.recordField(),
                  ]),
                ],
                [checkNotPromoted(x)],
              ),
            ]),
          ]);
        });

        test('Both vars promoted', () {
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            switch_(expr('int?'), [
              switchStatementMember(
                [
                  x1.pattern(type: 'int?').nullCheck,
                  x2.pattern(type: 'int?').nullCheck,
                ],
                [checkPromoted(x, 'int')],
              ),
            ]),
          ]);
        });

        test('Promoted via when clause', () {
          // Equivalent Dart code:
          //     switch (... as (int, int?)) {
          //       case (0, int? x?):
          //       case (1, int? x) where x != null:
          //         x; // Should be promoted to non-null
          //     }
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            switch_(expr('(int, int?)'), [
              switchStatementMember(
                [
                  recordPattern([
                    intLiteral(0).pattern.recordField(),
                    x1.pattern(type: 'int?').nullCheck.recordField(),
                  ]),
                  recordPattern([
                    intLiteral(1).pattern.recordField(),
                    x2.pattern(type: 'int?').recordField(),
                  ]).when(x2.notEq(nullLiteral)),
                ],
                [checkPromoted(x, 'int')],
              ),
            ]),
          ]);
        });

        test('Complex example', () {
          // This is based on the code sample from
          // https://github.com/dart-lang/sdk/issues/51644, except that the type
          // of the scrutinee has been changed from `dynamic` to `Object?`.
          var a1 = Var('a', identity: 'a1');
          var a2 = Var('a', identity: 'a2');
          var a3 = Var('a', identity: 'a3');
          var a = PatternVariableJoin('a', expectedComponents: [a1, a2, a3]);
          h.run([
            switch_(expr('Object?'), [
              switchStatementMember(
                [
                  a1.pattern(type: 'String?').nullCheck.when(a1.is_('Never')),
                  a2.pattern(type: 'String?').when(a2.notEq(nullLiteral)),
                  a3
                      .pattern(type: 'String?')
                      .nullAssert
                      .when(a3.eq(intLiteral(1))),
                ],
                [checkPromoted(a, 'String')],
              ),
            ]),
          ]);
        });

        test('Join variable is promotable', () {
          var x1 = Var('x', identity: 'x1');
          var x2 = Var('x', identity: 'x2');
          var x = PatternVariableJoin('x', expectedComponents: [x1, x2]);
          h.run([
            switch_(expr('int?'), [
              switchStatementMember(
                [x1.pattern(type: 'int?').nullCheck, x2.pattern(type: 'int?')],
                [checkNotPromoted(x), x.nonNullAssert, checkPromoted(x, 'int')],
              ),
            ]),
          ]);
        });
      });

      group("Sets join variable assigned even if variable doesn't appear in "
          "every case", () {
        test('Variable in first case only', () {
          var x1 = Var('x', identity: 'x1');
          var x = PatternVariableJoin('x', expectedComponents: [x1]);
          // `x` is considered assigned inside the case body (even though it's
          // not actually assigned by both patterns) because this avoids
          // redundant errors.
          h.run([
            switch_(expr('num?'), [
              switchStatementMember(
                [x1.pattern().nullCheck, wildcard()],
                [
                  checkAssigned(x, true),
                  // Also verify that the join variable is promotable
                  checkNotPromoted(x),
                  x.as_('int'),
                  checkPromoted(x, 'int'),
                ],
              ),
            ]),
          ]);
        });

        test('Variable in second case only', () {
          var x1 = Var('x', identity: 'x1');
          var x = PatternVariableJoin('x', expectedComponents: [x1]);
          // `x` is considered assigned inside the case body (even though it's
          // not actually assigned by both patterns) because this avoids
          // redundant errors.
          h.run([
            switch_(expr('int?'), [
              switchStatementMember(
                [wildcard().nullCheck, x1.pattern()],
                [
                  checkAssigned(x, true),
                  // Also verify that the join variable is promotable
                  checkNotPromoted(x),
                  x.nonNullAssert,
                  checkPromoted(x, 'int'),
                ],
              ),
            ]),
          ]);
        });
      });

      group('Trivial exhaustiveness:', () {
        // Although flow analysis doesn't attempt to do full exhaustiveness
        // checking on switch statements, it understands that if any single case
        // fully covers the matched value type, the switch statement is
        // exhaustive.  (Such a switch is called "trivially exhaustive").
        //
        // Note that we don't test all possible patterns, because the flow
        // analysis logic for detecting trivial exhaustiveness builds on the
        // logic for tracking the "unmatched" state, which is tested elsewhere.
        test('exhaustive', () {
          h.run([
            switch_(expr('Object'), [
              wildcard().then([return_()]),
            ]),
            checkReachable(false),
          ]);
        });

        test('exhaustive but a reachable switch case completes', () {
          // In this case, even though the switch is trivially exhaustive, the
          // code after the switch is reachable because one of the reachable
          // switch cases completes normally.
          h.run([
            switch_(expr('Object'), [
              wildcard(type: 'int').then([checkReachable(true)]),
              wildcard().then([return_()]),
            ]),
            checkReachable(true),
          ]);
        });

        test('exhaustive but an unreachable switch case completes', () {
          // In this case, even though the `int` case completes normally, that
          // case is unreachable, so the code after the switch is unreachable.
          h.run([
            switch_(expr('Object'), [
              wildcard().then([return_()]),
              wildcard(type: 'int').then([checkReachable(false)]),
            ]),
            checkReachable(false),
          ]);
        });

        test('exhaustive but a reachable switch case breaks', () {
          // In this case, even though the switch is trivially exhaustive, the
          // code after the switch is reachable because one of the reachable
          // switch cases ends in a break.
          h.run([
            switch_(expr('Object'), [
              wildcard(type: 'int').then([checkReachable(true), break_()]),
              wildcard().then([return_()]),
            ]),
            checkReachable(true),
          ]);
        });

        test('exhaustive but an unreachable switch case breaks', () {
          // In this case, even though the `int` case breaks, that case is
          // unreachable, so the code after the switch is unreachable.
          h.run([
            switch_(expr('Object'), [
              wildcard().then([return_()]),
              wildcard(type: 'int').then([checkReachable(false), break_()]),
            ]),
            checkReachable(false),
          ]);
        });

        test('not exhaustive', () {
          h.run([
            switch_(expr('Object'), [
              wildcard(type: 'int').then([return_()]),
            ]),
            checkReachable(true),
          ]);
        });
      });
    });

    group('Variable pattern:', () {
      group('covers matched type:', () {
        test('without promotion candidate', () {
          // In `if(<some int> case num x) ...`, the `else` branch should be
          // unreachable because the type `num` fully covers the type `int`.
          var x = Var('x');
          h.run([
            ifCase(
              expr('int'),
              x.pattern(type: 'num'),
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ]);
        });

        test('with promotion candidate', () {
          // In `if(x case num y) ...`, the `else` branch should be unreachable
          // because the type `num` fully covers the type `int`.
          var x = Var('x');
          var y = Var('y');
          h.run([
            declare(x, type: 'int'),
            ifCase(
              x,
              y.pattern(type: 'num'),
              [checkReachable(true), checkNotPromoted(x)],
              [checkReachable(false), checkNotPromoted(x)],
            ),
          ]);
        });

        test('matched type is extension type', () {
          h.addSuperInterfaces('E', (_) => [Type('Object?')]);
          h.addExtensionTypeErasure('E', 'int');
          var x = Var('x');
          h.run([
            ifCase(
              expr('E'),
              x.pattern(type: 'int'),
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ]);
        });

        test('known type is extension type', () {
          h.addSuperInterfaces('E', (_) => [Type('Object?')]);
          h.addExtensionTypeErasure('E', 'int');
          var x = Var('x');
          h.run([
            ifCase(
              expr('int'),
              x.pattern(type: 'E'),
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ]);
        });
      });

      group("doesn't cover matched type:", () {
        test('without promotion candidate', () {
          // In `if(<some num> case int x) ...`, the `else` branch should be
          // reachable because the type `int` doesn't fully cover the type
          // `num`.
          var x = Var('x');
          h.run([
            ifCase(
              expr('num'),
              x.pattern(type: 'int'),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]);
        });

        group('with promotion candidate:', () {
          test('without factor', () {
            var x = Var('x');
            var y = Var('y');
            h.run([
              declare(x, type: 'num'),
              ifCase(
                x,
                y.pattern(type: 'int'),
                [checkReachable(true), checkPromoted(x, 'int')],
                [checkReachable(true), checkNotPromoted(x)],
              ),
            ]);
          });

          test('with factor', () {
            var x = Var('x');
            var y = Var('y');
            h.run([
              declare(x, type: 'int?'),
              ifCase(
                x,
                y.pattern(type: 'Null'),
                [checkReachable(true), checkPromoted(x, 'Null')],
                [checkReachable(true), checkPromoted(x, 'int')],
              ),
            ]);
          });
        });
      });

      test("Subpattern doesn't promote scrutinee", () {
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(x, initializer: expr('Object')),
          ifCase(
            x,
            objectPattern(
              requiredType: 'num',
              fields: [y.pattern(type: 'int').recordField('sign')],
            ),
            [
              checkPromoted(x, 'num'),
              // TODO(paulberry): should promote `x.sign` to `int`.
            ],
          ),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        var z = Var('z');
        h.run([
          declare(x, initializer: expr('Object?')),
          ifCase(
            x,
            wildcard()
                .as_('int')
                .and(y.pattern(type: 'num'))
                .and(z.pattern(expectInferredType: 'int')),
            [checkPromoted(x, 'int')],
          ),
        ]);
      });

      test('Promotes to non-nullable if matched type is non-nullable', () {
        // When the matched value type is non-nullable, and the variable's
        // declared type is nullable, a successful match promotes the variable.
        // This allows a case pattern of the form `T? x?` to promote `x` to
        // non-nullable `T`.
        var x = Var('x');
        h.run([
          ifCase(expr('Object'), x.pattern(type: 'int?'), [
            checkPromoted(x, 'int'),
          ]),
        ]);
      });

      test('Does not promote to non-nullable if matched type is `Null`', () {
        // Since `Null` is handled specially by `TypeOperations.classifyType`,
        // make sure that we don't accidentally promote the variable to
        // non-nullable when the matched value type is `Null`.
        var x = Var('x');
        h.run([
          ifCase(expr('Null'), x.pattern(type: 'int?'), [checkNotPromoted(x)]),
        ]);
      });

      group('Demonstrated type:', () {
        test('Subtype of matched value type', () {
          var x = Var('x');
          var y = Var('y');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(x, recordPattern([y.pattern(type: 'int').recordField()]), [
              checkPromoted(x, '(int,)'),
            ]),
          ]);
        });

        test('Supertype of matched value type', () {
          var x = Var('x');
          var y = Var('y');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(
              x,
              recordPattern([y.pattern(type: 'Object').recordField()]),
              [checkNotPromoted(x)],
            ),
          ]);
        });

        test('Unrelated to matched value type', () {
          var x = Var('x');
          var y = Var('y');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(
              x,
              recordPattern([y.pattern(type: 'String').recordField()]),
              [checkNotPromoted(x)],
            ),
          ]);
        });
      });

      test('Promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        var x = Var('x');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), x.pattern(type: 'int'), [
            checkPromoted(c.property('_property'), 'int'),
          ]),
        ]);
      });

      test('Promotable property, target changed', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        var x = Var('x');
        var y = Var('y');
        h.run([
          declare(c, initializer: expr('C')),
          switch_(c.property('_property'), [
            x.pattern(type: 'int').when(expr('bool')).then([
              checkPromoted(c.property('_property'), 'int'),
            ]),
            wildcard().when(second(c.write(expr('C')), expr('bool'))).then([]),
            y.pattern(type: 'int').then([
              checkNotPromoted(c.property('_property')),
            ]),
          ]),
        ]);
      });

      test('Non-promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: false);
        var c = Var('c');
        var x = Var('x');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), x.pattern(type: 'int'), [
            checkNotPromoted(c.property('_property')),
          ]),
        ]);
      });
    });

    group('Wildcard pattern:', () {
      group('covers matched type:', () {
        test('without promotion candidate', () {
          // In `if(<some int> case num _) ...`, the `else` branch should be
          // unreachable because the type `num` fully covers the type `int`.
          h.run([
            ifCase(
              expr('int'),
              wildcard(type: 'num'),
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ]);
        });

        test('with promotion candidate', () {
          // In `if(x case num _) ...`, the `else` branch should be unreachable
          // because the type `num` fully covers the type `int`.
          var x = Var('x');
          h.run([
            declare(x, type: 'int'),
            ifCase(
              x,
              wildcard(type: 'num'),
              [checkReachable(true), checkNotPromoted(x)],
              [checkReachable(false), checkNotPromoted(x)],
            ),
          ]);
        });
      });

      group("doesn't cover matched type:", () {
        test('without promotion candidate', () {
          // In `if(<some num> case int _) ...`, the `else` branch should be
          // reachable because the type `int` doesn't fully cover the type
          // `num`.
          h.run([
            ifCase(
              expr('num'),
              wildcard(type: 'int'),
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ]);
        });

        group('with promotion candidate:', () {
          test('without factor', () {
            var x = Var('x');
            h.run([
              declare(x, type: 'num'),
              ifCase(
                x,
                wildcard(type: 'int'),
                [checkReachable(true), checkPromoted(x, 'int')],
                [checkReachable(true), checkNotPromoted(x)],
              ),
            ]);
          });

          test('with factor', () {
            var x = Var('x');
            h.run([
              declare(x, type: 'int?'),
              ifCase(
                x,
                wildcard(type: 'Null'),
                [checkReachable(true), checkPromoted(x, 'Null')],
                [checkReachable(true), checkPromoted(x, 'int')],
              ),
            ]);
          });
        });
      });

      test("Subpattern doesn't promote scrutinee", () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          ifCase(
            x,
            objectPattern(
              requiredType: 'num',
              fields: [wildcard(type: 'int').recordField('sign')],
            ),
            [
              checkPromoted(x, 'num'),
              // TODO(paulberry): should promote `x.sign` to `int`.
            ],
          ),
        ]);
      });

      test("Doesn't demote", () {
        var x = Var('x');
        var y = Var('y');
        h.run(
          [
            declare(x, initializer: expr('Object?')),
            ifCase(
              x,
              wildcard()
                  .as_('int')
                  .and(wildcard(type: 'num')..errorId = 'WILDCARD')
                  .and(y.pattern(expectInferredType: 'int')),
              [checkPromoted(x, 'int')],
            ),
          ],
          expectedErrors: {
            'unnecessaryWildcardPattern(pattern: WILDCARD, '
                'kind: logicalAndPatternOperand)',
          },
        );
      });

      group('Demonstrated type:', () {
        test('Subtype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(x, recordPattern([wildcard(type: 'int').recordField()]), [
              checkPromoted(x, '(int,)'),
            ]),
          ]);
        });

        test('Supertype of matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(x, recordPattern([wildcard(type: 'Object').recordField()]), [
              checkNotPromoted(x),
            ]),
          ]);
        });

        test('Unrelated to matched value type', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('(num,)')),
            ifCase(x, recordPattern([wildcard(type: 'String').recordField()]), [
              checkNotPromoted(x),
            ]),
          ]);
        });
      });

      test('Promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), wildcard(type: 'int'), [
            checkPromoted(c.property('_property'), 'int'),
          ]),
        ]);
      });

      test('Promotable property, target changed', () {
        h.addMember('C', '_property', 'Object', promotable: true);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          switch_(c.property('_property'), [
            wildcard(type: 'int').when(expr('bool')).then([
              checkPromoted(c.property('_property'), 'int'),
            ]),
            wildcard().when(second(c.write(expr('C')), expr('bool'))).then([]),
            wildcard(
              type: 'int',
            ).then([checkNotPromoted(c.property('_property'))]),
          ]),
        ]);
      });

      test('Non-promotable property', () {
        h.addMember('C', '_property', 'Object', promotable: false);
        var c = Var('c');
        h.run([
          declare(c, initializer: expr('C')),
          ifCase(c.property('_property'), wildcard(type: 'int'), [
            checkNotPromoted(c.property('_property')),
          ]),
        ]);
      });
    });

    test('Pattern inside guard', () {
      // Roughly equivalent Dart code:
      //     FutureOr<int> x = ...;
      //     FutureOr<String> y = ...;
      //     if (x case int _ when f(() {
      //           if (y case String _) {
      //             /* x promoted to `int` */
      //             /* y promoted to `String` */
      //           } else {
      //             /* x promoted to `int` */
      //             /* y promoted to `Future<String>` */
      //           }
      //         }, throw ...)) {
      //       /* unreachable (due to `throw`) */
      //     } else {
      //       /* x promoted to `Future<int>` */
      //     }
      // For this to be analyzed correctly, flow analysis needs to avoid mixing
      // up the "unmatched" state from the outer and inner pattern matches.
      var x = Var('x');
      var y = Var('y');
      h.run([
        declare(x, initializer: expr('FutureOr<int>')),
        declare(y, initializer: expr('FutureOr<String>')),
        ifCase(
          x,
          wildcard(type: 'int').when(
            second(
              localFunction([
                ifCase(
                  y,
                  wildcard(type: 'String'),
                  [checkPromoted(x, 'int'), checkPromoted(y, 'String')],
                  [checkPromoted(x, 'int'), checkPromoted(y, 'Future<String>')],
                ),
              ]),
              throw_(expr('Object')),
            ),
          ),
          [checkReachable(false)],
          [checkReachable(true), checkPromoted(x, 'Future<int>')],
        ),
      ]);
    });

    test('Error type does not trigger unnecessary wildcard warning', () {
      h.run([
        ifCase(
          expr('num'),
          wildcard(type: 'int').and(wildcard(type: 'error')),
          [],
        ),
      ]);
    });

    group('Split points:', () {
      test('Guarded', () {
        // This test verifies that for a guarded pattern, the join of the two
        // "unmatched" control flow paths corresponds to a split point at the
        // beginning of the pattern.
        var i = Var('i');
        h.run([
          declare(i, initializer: expr('int?')),
          ifCase(
            second(throw_(expr('Object')), expr('int')).checkType('int'),
            objectPattern(
              requiredType: 'int',
              fields: [],
            ).when(i.eq(nullLiteral)),
            [],
            [
              // There is a join point here, joining the flow control paths
              // where (a) the pattern `int()` failed to match and (b) the
              // guard `i == null` was not satisfied. Since the scrutinee has
              // type `int`, and the pattern is `int()`, the pattern is
              // guaranteed to match, so path (a) is unreachable. Path (b) is
              // also unreachable due to the fact that the scrutinee throws,
              // but since the split point is the beginning of the pattern,
              // path (b) is reachable from the split point. So the promotion
              // implied by (b) is preserved after the join.
              checkPromoted(i, 'int'),
              // Note that due to the `throw` in the scrutinee, this code is
              // unreachable.
              checkReachable(false),
            ],
          ),
        ]);
      });

      test('Logical-or', () {
        // This test verifies that for a logical-or pattern, the join of the two
        // "matched" control flow paths corresponds to a split point at the
        // beginning of the top level pattern.
        var x = Var('x');
        h.run([
          ifCase(
            expr('(Null, Null, int?)'),
            recordPattern([
                  relationalPattern('!=', nullLiteral).recordField(),
                  wildcard().recordField(),
                  wildcard().recordField(),
                ])
                // At this point, control flow is unreachable due to the fact
                // that the `!= null` pattern in the first field of the
                // record pattern above can never match the type `Null`.
                .and(
                  recordPattern([
                    wildcard().recordField(),
                    relationalPattern('!=', nullLiteral).recordField(),
                    wildcard().recordField(),
                  ])
                  // At this point, control flow is unreachable for a
                  // second reason: because the `!= null` pattern in the
                  // second field of the record pattern above can never
                  // match the type `Null`.
                  .or(
                    recordPattern([
                      wildcard().recordField(),
                      wildcard().recordField(),
                      wildcard().nullCheck.recordField(),
                    ]),
                    // At this point, the third field of the scrutinee
                    // is promoted from `int?` to `int`, due to the
                    // null check pattern.
                  ),
                  // At this point, there is a control flow join between the
                  // two branches of the logical-or pattern. Since the split
                  // point corresponding to the control flow join is at the
                  // beginning of the top level pattern, both branches are
                  // considered unreachable, so neither is favored in the
                  // join, and therefore, the promotion from the second
                  // branch is lost.
                )
                .and(
                  // The record pattern below matches `x` to the unpromoted
                  // type of the third field of the scrutinee, so we just
                  // have to verify that it has the expected type of `int?`.
                  recordPattern([
                    wildcard().recordField(),
                    wildcard().recordField(),
                    x.pattern(expectInferredType: 'int?').recordField(),
                  ]),
                ),
            [
              // As a sanity check, confirm that the overall pattern
              // can't ever match.
              checkReachable(false),
            ],
          ),
        ]);
      });
    });
  });

  group('Sound flow analysis:', () {
    group('<nonNull> as Null:', () {
      test('When enabled, is guaranteed to throw', () {
        h.run([expr('int').as_('Null'), checkReachable(false)]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([expr('int').as_('Null'), checkReachable(true)]);
      });
    });

    group('<Null> as <nonNullable>:', () {
      test('When enabled, is guaranteed to throw', () {
        h.run([expr('Null').as_('int'), checkReachable(false)]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([expr('Null').as_('int'), checkReachable(true)]);
      });
    });

    group('<nonNull> is Null:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('int').is_('Null'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('int').is_('Null'),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<nonNull> is! Null:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('int').is_('Null', isInverted: true),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('int').is_('Null', isInverted: true),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<Null> is <nonNullable>:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('Null').is_('int'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('Null').is_('int'),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<Null> is! <nonNullable>:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('Null').is_('int', isInverted: true),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('Null').is_('int', isInverted: true),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<nonNullable> == <Null>:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('int').eq(expr('Null')),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('int').eq(expr('Null')),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<nonNullable> != <Null>:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('int').notEq(expr('Null')),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('int').notEq(expr('Null')),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<Null> == <nonNullable>:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('Null').eq(expr('int')),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('Null').eq(expr('int')),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<Null> != <nonNullable>:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('Null').notEq(expr('int')),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, no effect', () {
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('Null').notEq(expr('int')),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<Null> == <Null>:', () {
      test('When enabled, is guaranteed true', () {
        h.run([
          if_(
            expr('Null').eq(expr('Null')),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, is guaranteed true', () {
        // Flow analysis has considered `<Null> == <Null>` as "guaranteed to be
        // true" since its inception.
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('Null').eq(expr('Null')),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('<Null> != <Null>:', () {
      test('When enabled, is guaranteed false', () {
        h.run([
          if_(
            expr('Null').notEq(expr('Null')),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, is guaranteed false', () {
        // Flow analysis has considered `<Null> != <Null>` as "guaranteed to be
        // false" since its inception.
        h.disableSoundFlowAnalysis();
        h.run([
          if_(
            expr('Null').notEq(expr('Null')),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('== pattern:', () {
      test("When enabled, null pattern can't match non-nullable types", () {
        h.run([
          ifCase(
            expr('int'),
            relationalPattern('==', nullLiteral),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, null pattern can even match non-nullable types', () {
        // Due to mixed mode unsoundness, attempting to match `null` to a
        // non-nullable type can still succeed, so in order to avoid
        // unsoundness escalation, it's important that the matching case is
        // considered reachable.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('int'),
            relationalPattern('==', nullLiteral),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('!= pattern:', () {
      test("When enabled, null pattern can't match non-nullable types", () {
        h.run([
          ifCase(
            expr('int'),
            relationalPattern('!=', nullLiteral),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, null pattern can even match non-nullable types', () {
        // Due to mixed mode unsoundness, attempting to match `null` to a
        // non-nullable type can still succeed, so in order to avoid
        // unsoundness escalation, it's important that the matching case is
        // considered reachable.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('int'),
            relationalPattern('!=', nullLiteral),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('null pattern:', () {
      test("When enabled, null pattern can't match non-nullable types", () {
        h.run([
          ifCase(
            expr('int'),
            nullLiteral.pattern,
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, null pattern can even match non-nullable types', () {
        // Due to mixed mode unsoundness, attempting to match `null` to a
        // non-nullable type can still succeed, so in order to avoid unsoundness
        // escalation, it's important that the matching case is considered
        // reachable.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('int'),
            nullLiteral.pattern,
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('<nonNull>?.foo(<expr>)', () {
      test('When enabled, guaranteed to execute <expr>', () {
        h.addMember('C', 'foo', 'dynamic');
        var x = Var('x');
        h.run([
          declare(x, type: 'int'),
          expr(
            'C',
          ).invokeMethod(isNullAware: true, 'foo', [x.write(expr('int'))]),
          checkAssigned(x, true),
        ]);
      });

      test('When disabled, not guaranteed to execute <expr>', () {
        h.disableSoundFlowAnalysis();
        h.addMember('C', 'foo', 'dynamic');
        var x = Var('x');
        h.run([
          declare(x, type: 'int'),
          expr(
            'C',
          ).invokeMethod(isNullAware: true, 'foo', [x.write(expr('int'))]),
          checkAssigned(x, false),
        ]);
      });
    });

    group('<nonNull>?..foo(<expr>)', () {
      test('When enabled, guaranteed to execute <expr>', () {
        h.addMember('C', 'foo', 'dynamic');
        var x = Var('x');
        h.run([
          declare(x, type: 'int'),
          expr('C').cascade(isNullAware: true, [
            (e) => e.invokeMethod('foo', [x.write(expr('int'))]),
          ]),
          checkAssigned(x, true),
        ]);
      });

      test('When disabled, not guaranteed to execute <expr>', () {
        h.disableSoundFlowAnalysis();
        h.addMember('C', 'foo', 'dynamic');
        var x = Var('x');
        h.run([
          declare(x, type: 'int'),
          expr('C').cascade(isNullAware: true, [
            (e) => e.invokeMethod('foo', [x.write(expr('int'))]),
          ]),
          checkAssigned(x, false),
        ]);
      });
    });

    group('<nonNullable> ?? <expr>', () {
      test('When enabled, <expr> is dead', () {
        h.run([expr('int').ifNull(checkReachable(false))]);
      });

      test('When disabled, <expr> is live', () {
        h.disableSoundFlowAnalysis();
        h.run([expr('int').ifNull(checkReachable(true))]);
      });
    });

    group('{ ?<nonNullable>: <expr> }', () {
      test('When enabled, guaranteed to execute <expr>', () {
        var x = Var('x');
        h.run([
          declare(x, type: 'int'),
          mapLiteral(keyType: 'dynamic', valueType: 'dynamic', [
            mapEntry(expr('int'), x.write(expr('int')), isKeyNullAware: true),
          ]),
          checkAssigned(x, true),
        ]);
      });

      test('When disabled, guaranteed to execute <expr>', () {
        // Flow analysis has considered `{ ?<nonNullable>: <expr> }` as
        // guaranteed to execute <expr> since null-aware map entries were added
        // to the language.
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          declare(x, type: 'int'),
          mapLiteral(keyType: 'dynamic', valueType: 'dynamic', [
            mapEntry(expr('int'), x.write(expr('int')), isKeyNullAware: true),
          ]),
          checkAssigned(x, true),
        ]);
      });
    });

    group('{ ?<Null>: <expr> }', () {
      test('When enabled, guaranteed to skip execution of <expr>', () {
        h.run([
          mapLiteral(keyType: 'dynamic', valueType: 'dynamic', [
            mapEntry(expr('Null'), checkReachable(false), isKeyNullAware: true),
          ]),
        ]);
      });

      test('When disabled, not guaranteed to skip execution of <expr>', () {
        // Note: it would always have been sound for flow analysis to reason
        // that `{ ?<Null>: <expr> }` was guaranteed to skip execution of
        // `<expr>` (even when flow analysis had to assume that code might be
        // running in unsound null safety mode). But this functionality wasn't
        // implemented. It's been added as part of `sound-flow-analysis`; this
        // test verifies that the old behavior is preserved when
        // `sound-flow-analysis` is disabled.
        h.disableSoundFlowAnalysis();
        h.run([
          mapLiteral(keyType: 'dynamic', valueType: 'dynamic', [
            mapEntry(expr('Null'), checkReachable(true), isKeyNullAware: true),
          ]),
        ]);
      });
    });

    group('? pattern applied to non-nullable type', () {
      test('When enabled, guaranteed to match', () {
        h.run(
          [
            ifCase(
              expr('int'),
              wildcard().nullCheck..errorId = 'nullCheck',
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ],
          expectedErrors: {
            'matchedTypeIsStrictlyNonNullable(pattern: nullCheck, '
                'matchedType: int)',
          },
        );
      });

      test('When disabled, not guaranteed to match', () {
        h.disableSoundFlowAnalysis();
        h.run(
          [
            ifCase(
              expr('int'),
              wildcard().nullCheck..errorId = 'nullCheck',
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ],
          expectedErrors: {
            'matchedTypeIsStrictlyNonNullable(pattern: nullCheck, '
                'matchedType: int)',
          },
        );
      });
    });

    group('Map pattern', () {
      test('When enabled, guaranteed to match non-nullable map', () {
        h.run(
          [
            ifCase(
              expr('Map<int, int>'),
              mapPattern([])..errorId = 'mapPattern',
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ],
          expectedErrors: {'emptyMapPattern(pattern: mapPattern)'},
        );
      });

      test('When disabled, not guaranteed to match non-nullable map', () {
        h.disableSoundFlowAnalysis();
        h.run(
          [
            ifCase(
              expr('Map<int, int>'),
              mapPattern([])..errorId = 'mapPattern',
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ],
          expectedErrors: {'emptyMapPattern(pattern: mapPattern)'},
        );
      });
    });

    group('Null() pattern with non-nullable matched value type', () {
      test('When enabled, guaranteed not to match', () {
        h.run([
          ifCase(
            expr('int'),
            objectPattern(requiredType: 'Null', fields: []),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('int'),
            objectPattern(requiredType: 'Null', fields: []),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('Null _ pattern with non-nullable matched value type', () {
      test('When enabled, guaranteed not to match', () {
        h.run([
          ifCase(
            expr('int'),
            wildcard(type: 'Null'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('int'),
            wildcard(type: 'Null'),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('Null variable pattern with non-nullable matched value type', () {
      test('When enabled, guaranteed not to match', () {
        var x = Var('x');
        h.run([
          ifCase(
            expr('int'),
            x.pattern(type: 'Null'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          ifCase(
            expr('int'),
            x.pattern(type: 'Null'),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('Non-nullable cast pattern with Null matched value type', () {
      test('When enabled, guaranteed not to match', () {
        h.run([
          ifCase(
            expr('Null'),
            wildcard().as_('int'),
            [checkReachable(false)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        // Note: it would always have been sound for flow analysis to reason
        // that `_ as int` was guaranteed not to match `Null` (even when flow
        // analysis had to assume that code might be running in unsound null
        // safety mode). But this functionality wasn't implemented. It's been
        // added as part of `sound-flow-analysis`; this test verifies that the
        // old behavior is preserved when `sound-flow-analysis` is disabled.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            wildcard().as_('int'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Nullable cast pattern with Null matched value type', () {
      test('When enabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable cast
        // patterns is not over-broad.
        h.run(
          [
            ifCase(
              expr('Null'),
              wildcard().as_('int?')..errorId = 'castPattern',
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ],
          expectedErrors: {
            'matchedTypeIsSubtypeOfRequired(pattern: castPattern, '
                'matchedType: Null, requiredType: int?)',
          },
        );
      });

      test('When disabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable cast
        // patterns is not over-broad.
        h.disableSoundFlowAnalysis();
        h.run(
          [
            ifCase(
              expr('Null'),
              wildcard().as_('int?')..errorId = 'castPattern',
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ],
          expectedErrors: {
            'matchedTypeIsSubtypeOfRequired(pattern: castPattern, '
                'matchedType: Null, requiredType: int?)',
          },
        );
      });
    });

    group('Null cast pattern with Null matched value type', () {
      test('When enabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable cast
        // patterns is not over-broad.
        h.run(
          [
            ifCase(
              expr('Null'),
              wildcard().as_('Null')..errorId = 'castPattern',
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ],
          expectedErrors: {
            'matchedTypeIsSubtypeOfRequired(pattern: castPattern, '
                'matchedType: Null, requiredType: Null)',
          },
        );
      });

      test('When disabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable cast
        // patterns is not over-broad.
        h.disableSoundFlowAnalysis();
        h.run(
          [
            ifCase(
              expr('Null'),
              wildcard().as_('Null')..errorId = 'castPattern',
              [checkReachable(true)],
              [checkReachable(false)],
            ),
          ],
          expectedErrors: {
            'matchedTypeIsSubtypeOfRequired(pattern: castPattern, '
                'matchedType: Null, requiredType: Null)',
          },
        );
      });
    });

    group('Non-nullable variable pattern with Null matched value type', () {
      test('When enabled, guaranteed not to match', () {
        var x = Var('x');
        h.run([
          ifCase(
            expr('Null'),
            x.pattern(type: 'int'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        // Note: it would always have been sound for flow analysis to reason
        // that `int x` was guaranteed not to match `Null` (even when flow
        // analysis had to assume that code might be running in unsound null
        // safety mode). But this functionality wasn't implemented. It's been
        // added as part of `sound-flow-analysis`; this test verifies that the
        // old behavior is preserved when `sound-flow-analysis` is disabled.
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          ifCase(
            expr('Null'),
            x.pattern(type: 'int'),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('Nullable variable pattern with Null matched value type', () {
      test('When enabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable variable
        // patterns is not over-broad.
        var x = Var('x');
        h.run([
          ifCase(
            expr('Null'),
            x.pattern(type: 'int?'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable variable
        // patterns is not over-broad.
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          ifCase(
            expr('Null'),
            x.pattern(type: 'int?'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Null variable pattern with Null matched value type', () {
      test('When enabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable variable
        // patterns is not over-broad.
        var x = Var('x');
        h.run([
          ifCase(
            expr('Null'),
            x.pattern(type: 'Null'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable variable
        // patterns is not over-broad.
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          ifCase(
            expr('Null'),
            x.pattern(type: 'Null'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('List pattern with Null matched value type', () {
      test('When enabled, guaranteed not to match', () {
        h.run([
          ifCase(
            expr('Null'),
            listPattern([]),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        // Note: it would always have been sound for flow analysis to reason
        // that `[]` was guaranteed not to match `Null` (even when flow analysis
        // had to assume that code might be running in unsound null safety
        // mode). But this functionality wasn't implemented. It's been added as
        // part of `sound-flow-analysis`; this test verifies that the old
        // behavior is preserved when `sound-flow-analysis` is disabled.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            listPattern([]),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('Map pattern with Null matched value type', () {
      test('When enabled, guaranteed not to match', () {
        h.run(
          [
            ifCase(
              expr('Null'),
              mapPattern([])..errorId = 'mapPattern',
              [checkReachable(false)],
              [checkReachable(true)],
            ),
          ],
          expectedErrors: {'emptyMapPattern(pattern: mapPattern)'},
        );
      });

      test('When disabled, might match', () {
        // Note: it would always have been sound for flow analysis to reason
        // that `{}` was guaranteed not to match `Null` (even when flow analysis
        // had to assume that code might be running in unsound null safety
        // mode). But this functionality wasn't implemented. It's been added as
        // part of `sound-flow-analysis`; this test verifies that the old
        // behavior is preserved when `sound-flow-analysis` is disabled.
        h.disableSoundFlowAnalysis();
        h.run(
          [
            ifCase(
              expr('Null'),
              mapPattern([])..errorId = 'mapPattern',
              [checkReachable(true)],
              [checkReachable(true)],
            ),
          ],
          expectedErrors: {'emptyMapPattern(pattern: mapPattern)'},
        );
      });
    });

    group('Non-nullable object pattern with Null matched value type', () {
      test('When enabled, guaranteed not to match', () {
        h.run([
          ifCase(
            expr('Null'),
            objectPattern(requiredType: 'int', fields: []),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        // Note: it would always have been sound for flow analysis to reason
        // that `int()` was guaranteed not to match `Null` (even when flow
        // analysis had to assume that code might be running in unsound null
        // safety mode). But this functionality wasn't implemented. It's been
        // added as part of `sound-flow-analysis`; this test verifies that the
        // old behavior is preserved when `sound-flow-analysis` is disabled.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            objectPattern(requiredType: 'int', fields: []),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('Nullable object pattern with Null matched value type', () {
      test('When enabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable object
        // patterns is not over-broad.
        h.run([
          ifCase(
            expr('Null'),
            objectPattern(requiredType: 'dynamic', fields: []),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable object
        // patterns is not over-broad.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            objectPattern(requiredType: 'dynamic', fields: []),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Null object pattern with Null matched value type', () {
      test('When enabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable object
        // patterns is not over-broad.
        h.run([
          ifCase(
            expr('Null'),
            objectPattern(requiredType: 'Null', fields: []),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable object
        // patterns is not over-broad.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            objectPattern(requiredType: 'Null', fields: []),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Record pattern with Null matched value type', () {
      test('When enabled, guaranteed not to match', () {
        h.run([
          ifCase(
            expr('Null'),
            recordPattern([wildcard().recordField()]),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        // Note: it would always have been sound for flow analysis to reason
        // that `(_,)` was guaranteed not to match `Null` (even when flow
        // analysis had to assume that code might be running in unsound null
        // safety mode). But this functionality wasn't implemented. It's been
        // added as part of `sound-flow-analysis`; this test verifies that the
        // old behavior is preserved when `sound-flow-analysis` is disabled.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            recordPattern([wildcard().recordField()]),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('Non-nullable wildcard pattern with Null matched value type', () {
      test('When enabled, guaranteed not to match', () {
        h.run([
          ifCase(
            expr('Null'),
            wildcard(type: 'int'),
            [checkReachable(false)],
            [checkReachable(true)],
          ),
        ]);
      });

      test('When disabled, might match', () {
        // Note: it would always have been sound for flow analysis to reason
        // that `int _` was guaranteed not to match `Null` (even when flow
        // analysis had to assume that code might be running in unsound null
        // safety mode). But this functionality wasn't implemented. It's been
        // added as part of `sound-flow-analysis`; this test verifies that the
        // old behavior is preserved when `sound-flow-analysis` is disabled.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            wildcard(type: 'int'),
            [checkReachable(true)],
            [checkReachable(true)],
          ),
        ]);
      });
    });

    group('Nullable wildcard pattern with Null matched value type', () {
      test('When enabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable wildcard
        // patterns is not over-broad.
        h.run([
          ifCase(
            expr('Null'),
            wildcard(type: 'int?'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable wildcard
        // patterns is not over-broad.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            wildcard(type: 'int?'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Null wildcard pattern with Null matched value type', () {
      test('When enabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable wildcard
        // patterns is not over-broad.
        h.run([
          ifCase(
            expr('Null'),
            wildcard(type: 'Null'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // This is just to check that the logic to handle non-nullable wildcard
        // patterns is not over-broad.
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('Null'),
            wildcard(type: 'Null'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Declared variable pattern with matching non-nullable types', () {
      test('When enabled, guaranteed to match', () {
        var x = Var('x');
        h.run([
          ifCase(
            expr('int'),
            x.pattern(type: 'int'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // Flow analysis has considered `int x` as guaranteed to match a value
        // with static type `int` since patterns were added to the language
        // (even though that was not technically guaranteed to be the case when
        // running in unsound null safety mode).
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          ifCase(
            expr('int'),
            x.pattern(type: 'int'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('List pattern', () {
      test('When enabled, guaranteed to match non-nullable list', () {
        h.run([
          ifCase(
            expr('List<int>'),
            listPattern([restPattern()]),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match non-nullable list', () {
        // Flow analysis has considered a list pattern as guaranteed to match a
        // value with static type `List` since patterns were added to the
        // language (even though that was not technically guaranteed to be the
        // case when running in unsound null safety mode).
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('List<int>'),
            listPattern([restPattern()]),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Object pattern with matching non-nullable types', () {
      test('When enabled, guaranteed to match', () {
        h.run([
          ifCase(
            expr('int'),
            objectPattern(requiredType: 'int', fields: []),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // Flow analysis has considered an object pattern as guaranteed to match
        // a value with a matching static type since patterns were added to the
        // language (even though that was not technically guaranteed to be the
        // case when running in unsound null safety mode).
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('int'),
            objectPattern(requiredType: 'int', fields: []),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Record pattern with matching non-nullable type', () {
      test('When enabled, guaranteed to match', () {
        h.run([
          ifCase(
            expr('(int,)'),
            recordPattern([wildcard(type: 'int').recordField()]),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // Flow analysis has considered a record pattern as guaranteed to match
        // a value with a matching static type since patterns were added to the
        // language (even though that was not technically guaranteed to be the
        // case when running in unsound null safety mode).
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('(int,)'),
            recordPattern([wildcard(type: 'int').recordField()]),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Wildcard pattern with matching non-nullable types', () {
      test('When enabled, guaranteed to match', () {
        h.run([
          ifCase(
            expr('int'),
            wildcard(type: 'int'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });

      test('When disabled, guaranteed to match', () {
        // Flow analysis has considered `int _` as guaranteed to match a value
        // with static type `int` since patterns were added to the language
        // (even though that was not technically guaranteed to be the case when
        // running in unsound null safety mode).
        h.disableSoundFlowAnalysis();
        h.run([
          ifCase(
            expr('int'),
            wildcard(type: 'int'),
            [checkReachable(true)],
            [checkReachable(false)],
          ),
        ]);
      });
    });

    group('Null aware field access:', () {
      group('Non-cascaded:', () {
        test('When disabled, does not see previous promotions', () {
          h.disableSoundFlowAnalysis();
          h.addMember('A', '_i', 'int?', promotable: true);
          var a = Var('a');
          h.run([
            declare(a, initializer: expr('A')),
            a.property('_i').nonNullAssert,
            // `a._i` is promoted now.
            a.property('_i').checkType('int'),
            // But `a?._i` is not.
            a.property('_i', isNullAware: true).checkType('int?'),
          ]);
        });

        test('When enabled, sees previous promotions', () {
          h.addMember('A', '_i', 'int?', promotable: true);
          var a = Var('a');
          h.run([
            declare(a, initializer: expr('A')),
            a.property('_i').nonNullAssert,
            // `a._i` is promoted now.
            a.property('_i').checkType('int'),
            // And so is `a?._i`.
            a.property('_i', isNullAware: true).checkType('int'),
          ]);
        });

        test('When disabled, cannot promote', () {
          h.disableSoundFlowAnalysis();
          h.addMember('A', '_i', 'int?', promotable: true);
          var a = Var('a');
          h.run([
            declare(a, initializer: expr('A')),
            a.property('_i', isNullAware: true).nonNullAssert,
            // `a._i` is not promoted.
            a.property('_i').checkType('int?'),
            // But had the field access not been null aware, it would have been
            // promoted.
            a.property('_i').nonNullAssert,
            a.property('_i').checkType('int'),
          ]);
        });

        test('When enabled, can promote', () {
          h.addMember('A', '_i', 'int?', promotable: true);
          var a = Var('a');
          h.run([
            declare(a, initializer: expr('A')),
            a.property('_i').checkType('int?'),
            a.property('_i', isNullAware: true).nonNullAssert,
            // `a._i` is promoted.
            a.property('_i').checkType('int'),
          ]);
        });

        test('In conditional expression', () {
          h.addMember('A', '_i', 'int?', promotable: true);
          var a = Var('a');
          h.run([
            declare(a, initializer: expr('A')),
            expr(
              'bool',
            ).conditional(nullLiteral, a.property('_i', isNullAware: true)),
          ]);
        });
      });

      group('Cascaded:', () {
        test('When disabled, sees previous promotions', () {
          h.disableSoundFlowAnalysis();
          h.addMember('A', '_i', 'int?', promotable: true);
          var a = Var('a');
          h.run([
            declare(a, initializer: expr('A')),
            a.property('_i').nonNullAssert,
            // `a._i` is promoted now.
            a.property('_i').checkType('int'),
            // And `a?.._i` is promoted.
            a.cascade(isNullAware: true, [
              (placeholder) => placeholder.property('_i').checkType('int'),
            ]),
          ]);
        });

        test('When enabled, sees previous promotions', () {
          h.addMember('A', '_i', 'int?', promotable: true);
          var a = Var('a');
          h.run([
            declare(a, initializer: expr('A')),
            a.property('_i').nonNullAssert,
            // `a._i` is promoted now.
            a.property('_i').checkType('int'),
            // And `a?.._i` is promoted.
            a.cascade(isNullAware: true, [
              (placeholder) => placeholder.property('_i').checkType('int'),
            ]),
          ]);
        });
      });
    });

    group('When disabled, may promote to mutual subtypes:', () {
      test('Type cast', () {
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('List<Object?>')),
          x.as_('List<dynamic>'),
          checkPromoted(x, 'List<dynamic>'),
        ]);
      });

      test('Type check', () {
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('List<Object?>')),
          if_(x.is_(isInverted: true, 'List<dynamic>'), [return_()]),
          checkPromoted(x, 'List<dynamic>'),
        ]);
      });

      test('Type of interest promotion', () {
        // Note: to work around the fact that a full demotion clears types of
        // interest (see https://github.com/dart-lang/language/issues/4380),
        // this test starts with a variable of type `dynamic` and promotes it
        // first to `List<Object?>?` and then to `List<dynamic>`. This ensures
        // that the write that follows (which writes a value of type
        // `List<Object?>?`) does not fully demote the variable, so the types of
        // interest will be preserved.
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('dynamic')),
          x.as_('List<Object?>?'),
          // `x` is now promoted to `List<Object?>?` and `List<Object?>` is a
          // type of interest
          checkPromoted(x, 'List<Object?>?'),
          x.as_('List<dynamic>'),
          // `x` is now promoted to `List<dynamic>` and `List<dynamic>` is a
          // type of interest.
          checkPromoted(x, 'List<dynamic>'),
          x.write(expr('List<Object?>?')),
          // `x` is now demoted back to `List<Object?>?`.
          checkPromoted(x, 'List<Object?>?'),
          x.write(expr('List<Object?>')),
          // `x` is now promoted to `List<Object?>`.
          checkPromoted(x, 'List<Object?>'),
          x.write(expr('List<void>')),
          // Type of interest promotion rejected `List<Object?>` (because it was
          // the already-promoted type), but accepted `List<dynamic>`.
          checkPromoted(x, 'List<dynamic>'),
        ]);
      });

      group('Finally clause:', () {
        test('Variable', () {
          h.disableSoundFlowAnalysis();
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            try_([
              x.as_('List<Object?>'),
              checkPromoted(x, 'List<Object?>'),
            ]).finally_([
              checkNotPromoted(x),
              x.as_('List<dynamic>'),
              checkPromoted(x, 'List<dynamic>'),
            ]),
            // After the try/finally, the promotions in the try block are
            // layered over the promotions in the finally block (see
            // https://github.com/dart-lang/language/issues/4382), so the
            // promotion to `List<Object?>` layers over the promotion to
            // `List<dynamic>`.
            checkPromoted(x, 'List<Object?>'),
          ]);
        });

        test('Promotable property of unmodified variable', () {
          h.disableSoundFlowAnalysis();
          h.addMember('C', '_property', 'Object?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            try_([
              x.property('_property').as_('List<Object?>'),
              checkPromoted(x.property('_property'), 'List<Object?>'),
            ]).finally_([
              checkNotPromoted(x),
              x.property('_property').as_('List<dynamic>'),
              checkPromoted(x.property('_property'), 'List<dynamic>'),
            ]),
            // After the try/finally, the promotions in the try block are
            // layered over the promotions in the finally block (see
            // https://github.com/dart-lang/language/issues/4382), so the
            // promotion to `List<Object?>` layers over the promotion to
            // `List<dynamic>`.
            checkPromoted(x.property('_property'), 'List<Object?>'),
          ]);
        });

        test('Promotable property of modified variable', () {
          h.disableSoundFlowAnalysis();
          h.addMember('C', '_property', 'Object?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            try_([
              x.write(expr('C')),
              x.property('_property').as_('List<dynamic>'),
              checkPromoted(x.property('_property'), 'List<dynamic>'),
            ]).finally_([
              checkNotPromoted(x),
              x.property('_property').as_('List<Object?>'),
              checkPromoted(x.property('_property'), 'List<Object?>'),
            ]),
            // After the try/finally, the promotions in the finally block are
            // layered over the promotions in the try block (see
            // https://github.com/dart-lang/language/issues/4382), so the
            // promotion to `List<Object?>` layers over the promotion to
            // `List<dynamic>`.
            checkPromoted(x.property('_property'), 'List<Object?>'),
          ]);
        });
      });

      test('Boolean variable', () {
        h.disableSoundFlowAnalysis();
        var x = Var('x');
        var b = Var('b');
        h.run([
          declare(x, initializer: expr('Object?')),
          declare(b, initializer: x.is_('List<Object?>')),
          checkNotPromoted(x),
          x.as_('List<dynamic>'),
          checkPromoted(x, 'List<dynamic>'),
          if_(b, [
            // The promotion to `List<Object?>`, captured at the declaration
            // site of `b`, is layered over the promotion to `List<dynamic>`.
            checkPromoted(x, 'List<Object?>'),
          ]),
        ]);
      });
    });

    group('When enabled, do not promote to mutual subtypes:', () {
      test('Type cast', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('List<Object?>')),
          x.as_('List<dynamic>'),
          checkNotPromoted(x),
        ]);
      });

      test('Type check', () {
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('List<Object?>')),
          if_(x.is_(isInverted: true, 'List<dynamic>'), [return_()]),
          checkNotPromoted(x),
        ]);
      });

      test('Type of interest promotion', () {
        // Note: to work around the fact that a full demotion clears types of
        // interest (see https://github.com/dart-lang/language/issues/4380),
        // this test starts with a variable of type `dynamic` and promotes it
        // first to `List<Object?>?` and then to `List<dynamic>`. This ensures
        // that the write that follows (which writes a value of type
        // `List<Object?>?`) does not fully demote the variable, so the types of
        // interest will be preserved.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('dynamic')),
          x.as_('List<Object?>?'),
          // `x` is now promoted to `List<Object?>?` and `List<Object?>` is a
          // type of interest
          checkPromoted(x, 'List<Object?>?'),
          x.as_('List<dynamic>'),
          // `x` is now promoted to `List<dynamic>` and `List<dynamic>` is a
          // type of interest.
          checkPromoted(x, 'List<dynamic>'),
          x.write(expr('List<Object?>?')),
          // `x` is now demoted back to `List<Object?>?`.
          checkPromoted(x, 'List<Object?>?'),
          x.write(expr('List<Object?>')),
          // `x` is now promoted to `List<Object?>`.
          checkPromoted(x, 'List<Object?>'),
          x.write(expr('List<void>')),
          // Type of interest promotion rejected `List<Object?>` (because it was
          // the already-promoted type) and `List<dynamic>` (because it is a
          // mutual subtype with the already-promoted type).
          checkPromoted(x, 'List<Object?>'),
        ]);
      });

      group('Finally clause:', () {
        test('Variable', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('Object?')),
            try_([
              x.as_('List<Object?>'),
              checkPromoted(x, 'List<Object?>'),
            ]).finally_([
              checkNotPromoted(x),
              x.as_('List<dynamic>'),
              checkPromoted(x, 'List<dynamic>'),
            ]),
            // After the try/finally, the promotions in the finally block are
            // layered over the promotions in the try block, so the
            // promotion to `List<dynamic>` layers over the promotion to
            // `List<Object?>`. But since the two types are mutual subtypes, the
            // promotion to `List<dynamic>` is discarded, leaving only the
            // promotion to `List<Object?>`.
            checkPromoted(x, 'List<Object?>'),
          ]);
        });

        test('Promotable property of unmodified variable', () {
          h.addMember('C', '_property', 'Object?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            try_([
              x.property('_property').as_('List<Object?>'),
              checkPromoted(x.property('_property'), 'List<Object?>'),
            ]).finally_([
              checkNotPromoted(x),
              x.property('_property').as_('List<dynamic>'),
              checkPromoted(x.property('_property'), 'List<dynamic>'),
            ]),
            // After the try/finally, the promotions in the finally block are
            // layered over the promotions in the try block, so the
            // promotion to `List<dynamic>` layers over the promotion to
            // `List<Object?>`. But since the two types are mutual subtypes, the
            // promotion to `List<dynamic>` is discarded, leaving only the
            // promotion to `List<Object?>`.
            checkPromoted(x.property('_property'), 'List<Object?>'),
          ]);
        });

        test('Promotable property of modified variable', () {
          h.addMember('C', '_property', 'Object?', promotable: true);
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('C')),
            try_([
              x.write(expr('C')),
              x.property('_property').as_('List<dynamic>'),
              checkPromoted(x.property('_property'), 'List<dynamic>'),
            ]).finally_([
              checkNotPromoted(x),
              x.property('_property').as_('List<Object?>'),
              checkPromoted(x.property('_property'), 'List<Object?>'),
            ]),
            // After the try/finally, the promotions in the finally block are
            // layered over the promotions in the try block (see
            // https://github.com/dart-lang/language/issues/4382), so the
            // promotion to `List<Object?>` layers over the promotion to
            // `List<dynamic>`. But since the two types are mutual subtypes, the
            // promotion to `List<Object?>` is discarded, leaving only the
            // promotion to `List<dynamic>`.
            checkPromoted(x.property('_property'), 'List<dynamic>'),
          ]);
        });
      });

      test('Boolean variable', () {
        var x = Var('x');
        var b = Var('b');
        h.run([
          declare(x, initializer: expr('Object?')),
          declare(b, initializer: x.is_('List<Object?>')),
          checkNotPromoted(x),
          x.as_('List<dynamic>'),
          checkPromoted(x, 'List<dynamic>'),
          if_(b, [
            // The promotion to `List<Object?>`, captured at the declaration
            // site of `b`, is layered over the promotion to `List<dynamic>`.
            // But since the two types are mutual subtypes, the promotion to
            // `List<Object?>` is discarded, leaving only the promotion to
            // `List<dynamic>`.
            checkPromoted(x, 'List<dynamic>'),
          ]),
        ]);
      });
    });

    group('Try/finally layering order:', () {
      group('Local variables:', () {
        late Var x, y;

        setUp(() {
          x = Var('x');
          y = Var('y');
        });

        void checkPromotionsAfterTryFinally(List<ProtoStatement> expectations) {
          h.run([
            declare(x, initializer: expr('Object')),
            declare(y, initializer: expr('Object')),
            try_([
              x.as_('num'),
              y.as_('int'),
              checkPromoted(x, 'num'),
              checkPromoted(y, 'int'),
            ]).finally_([
              // Neither `x` nor `y` is promoted at this point, because in
              // principle an exception could have occurred at any point in the
              // `try` block.
              checkNotPromoted(x),
              checkNotPromoted(y),
              x.as_('int'),
              y.as_('num'),
              checkPromoted(x, 'int'),
              checkPromoted(y, 'num'),
            ]),
            ...expectations,
          ]);
        }

        test('When disabled, promotions in `finally` applied first', () {
          h.disableSoundFlowAnalysis();
          checkPromotionsAfterTryFinally([
            // After the try/finally, both `x` and `y` are fully promoted to
            // `int`. But since the promotions from the `try` block are layered
            // over the promotions from the `finally` block, `x` has promotion
            // chain `[int]`, whereas `y` has promotion chain `[num, int]`.
            checkPromotionChain(x, ['int']),
            checkPromotionChain(y, ['num', 'int']),
          ]);
        });

        test('When enabled, promotions in `try` applied first', () {
          checkPromotionsAfterTryFinally([
            // After the try/finally, both `x` and `y` are fully promoted to
            // `int`. But since the promotions from the `finally` block are
            // layered over the promotions from the `try` block, `x` has
            // promotion chain `[num, int]`, whereas `y` has promotion chain
            // `[int]`.
            checkPromotionChain(x, ['num', 'int']),
            checkPromotionChain(y, ['int']),
          ]);
        });
      });

      group('Fields of unmodified local variables:', () {
        late Var x, y;

        setUp(() {
          x = Var('x');
          y = Var('y');
        });

        void checkPromotionsAfterTryFinally(List<ProtoStatement> expectations) {
          h.addMember('C', '_f', 'Object', promotable: true);
          h.run([
            declare(x, initializer: expr('C')),
            declare(y, initializer: expr('C')),
            try_([
              x.property('_f').as_('num'),
              y.property('_f').as_('int'),
              checkPromoted(x.property('_f'), 'num'),
              checkPromoted(y.property('_f'), 'int'),
            ]).finally_([
              // Neither `x._f` nor `y._f` is promoted at this point, because in
              // principle an exception could have occurred at any point in the
              // `try` block.
              checkNotPromoted(x.property('_f')),
              checkNotPromoted(y.property('_f')),
              x.property('_f').as_('int'),
              y.property('_f').as_('num'),
              checkPromoted(x.property('_f'), 'int'),
              checkPromoted(y.property('_f'), 'num'),
            ]),
            ...expectations,
          ]);
        }

        test('When disabled, promotions in `finally` applied first', () {
          h.disableSoundFlowAnalysis();
          checkPromotionsAfterTryFinally([
            // After the try/finally, both `x._f` and `y._f` are fully promoted
            // to `int`. But since the promotions from the `try` block are
            // layered over the promotions from the `finally` block, `x._f` has
            // promotion chain `[int]`, whereas `y._f` has promotion chain
            // `[num, int]`.
            checkPromotionChain(x.property('_f'), ['int']),
            checkPromotionChain(y.property('_f'), ['num', 'int']),
          ]);
        });

        test('When enabled, promotions in `try` applied first', () {
          checkPromotionsAfterTryFinally([
            // After the try/finally, both `x._f` and `y._f` are fully promoted
            // to `int`. But since the promotions from the `finally` block are
            // layered over the promotions from the `try` block, `x._f` has
            // promotion chain `[num, int]`, whereas `y._f` has promotion chain
            // `[int]`.
            checkPromotionChain(x.property('_f'), ['num', 'int']),
            checkPromotionChain(y.property('_f'), ['int']),
          ]);
        });
      });

      group('Fields of local variables modified in try clause:', () {
        late Var x, y;

        setUp(() {
          x = Var('x');
          y = Var('y');
        });

        void checkPromotionsAfterTryFinally(List<ProtoStatement> expectations) {
          h.addMember('C', '_f', 'Object', promotable: true);
          h.run([
            declare(x, initializer: expr('C')),
            declare(y, initializer: expr('C')),
            try_([
              x.write(expr('C')),
              y.write(expr('C')),
              x.property('_f').as_('num'),
              y.property('_f').as_('int'),
              checkPromoted(x.property('_f'), 'num'),
              checkPromoted(y.property('_f'), 'int'),
            ]).finally_([
              // Neither `x._f` nor `y._f` is promoted at this point, because in
              // principle an exception could have occurred at any point in the
              // `try` block.
              checkNotPromoted(x.property('_f')),
              checkNotPromoted(y.property('_f')),
              x.property('_f').as_('int'),
              y.property('_f').as_('num'),
              checkPromoted(x.property('_f'), 'int'),
              checkPromoted(y.property('_f'), 'num'),
            ]),
            ...expectations,
          ]);
        }

        test('When disabled, promotions in `try` applied first', () {
          h.disableSoundFlowAnalysis();
          checkPromotionsAfterTryFinally([
            // After the try/finally, both `x._f` and `y._f` are fully promoted
            // to `int`. But since the promotions from the `finally` block are
            // layered over the promotions from the `try` block, `x._f` has
            // promotion chain `[num, int]`, whereas `y._f` has promotion chain
            // `[int]`.
            checkPromotionChain(x.property('_f'), ['num', 'int']),
            checkPromotionChain(y.property('_f'), ['int']),
          ]);
        });

        test('When enabled, promotions in `try` applied first', () {
          checkPromotionsAfterTryFinally([
            // After the try/finally, both `x._f` and `y._f` are fully promoted
            // to `int`. But since the promotions from the `finally` block are
            // layered over the promotions from the `try` block, `x._f` has
            // promotion chain `[num, int]`, whereas `y._f` has promotion chain
            // `[int]`.
            checkPromotionChain(x.property('_f'), ['num', 'int']),
            checkPromotionChain(y.property('_f'), ['int']),
          ]);
        });
      });
    });

    test('When disabled, full demotion clears types of interest', () {
      var x = Var('x');
      h.disableSoundFlowAnalysis();
      h.run([
        declare(x, initializer: expr('Object')),
        x.as_('num'),
        checkPromoted(x, 'num'),
        x.write(expr('String')),
        checkNotPromoted(x),
        x.write(expr('num')),
        checkNotPromoted(x),
      ]);
    });

    test('When enabled, full demotion preserves types of interest', () {
      var x = Var('x');
      h.run([
        declare(x, initializer: expr('Object')),
        x.as_('num'),
        checkPromoted(x, 'num'),
        x.write(expr('String')),
        checkNotPromoted(x),
        x.write(expr('num')),
        checkPromoted(x, 'num'),
      ]);
    });

    group('False branch for trivially satisfied "is" test:', () {
      group('When enabled, sets unreachable:', () {
        test('Promotable target', () {
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('int')),
            if_(x.is_('int', isInverted: true), [
              checkNotPromoted(x),
              checkReachable(false),
            ]),
          ]);
        });

        test('Non-promotable target', () {
          h.run([
            if_(expr('int').is_('int', isInverted: true), [
              checkReachable(false),
            ]),
          ]);
        });
      });

      group('When disabled, leaves reachable:', () {
        test('Promotable target', () {
          h.disableSoundFlowAnalysis();
          var x = Var('x');
          h.run([
            declare(x, initializer: expr('int')),
            if_(x.is_('int', isInverted: true), [
              checkNotPromoted(x),
              checkReachable(true),
            ]),
          ]);
        });

        test('Non-promotable target', () {
          h.disableSoundFlowAnalysis();
          h.run([
            if_(expr('int').is_('int', isInverted: true), [
              checkReachable(true),
            ]),
          ]);
        });
      });
    });
  });

  group('Demotion and type of interest promotion:', () {
    test('Partial demotion', () {
      // Promote `Object` to `num`, and then `int`, then assigning a `double`
      // demotes to `num`.
      var x = Var('x');
      h.run([
        declare(x, initializer: expr('Object')),
        x.as_('num'),
        x.as_('int'),
        checkPromoted(x, 'int'),
        x.write(expr('double')),
        checkPromoted(x, 'num'),
      ]);
    });

    test('Full demotion', () {
      // Promote `Object` to `num` and then `int`, then assigning a `String`
      // demotes to `Object`
      var x = Var('x');
      h.run([
        declare(x, initializer: expr('Object')),
        x.as_('num'),
        x.as_('int'),
        checkPromoted(x, 'int'),
        x.write(expr('String')),
        checkNotPromoted(x),
      ]);
    });

    group('Types of interest:', () {
      test('NonNull(declared) is a type of interest', () {
        // Declared type is `num?`; assigning a `num` promotes to `num`.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('num?')),
          checkNotPromoted(x),
          x.write(expr('num')),
          checkPromoted(x, 'num'),
        ]);
      });

      test('Invalid type does not promote on assignment', () {
        // Declared type is `num?`; assigning an invalid type does not promote
        // to `num`.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('num?')),
          checkNotPromoted(x),
          x.write(expr('error')),
          checkNotPromoted(x),
        ]);
      });

      test('Invalid type does not promote on declaration', () {
        // Declared type is `num?`; initializing an invalid type does not
        // promote to `num`.
        var x = Var('x');
        h.run([
          declare(x, type: 'num?', initializer: expr('error')),
          checkNotPromoted(x),
        ]);
      });

      test('Untested type is not a type of interest', () {
        // Declared type is `Object`; assigning an `int` does not promote.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          checkNotPromoted(x),
          x.write(expr('int')),
          checkNotPromoted(x),
        ]);
      });

      test('Tested type is a type of interest', () {
        // Declared type is `Object`; assigning an `int` after testing `int`
        // promotes.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          if_(x.is_('int'), [], []),
          checkNotPromoted(x),
          x.write(expr('int')),
          checkPromoted(x, 'int'),
        ]);
      });

      test('NonNull of tested type is a type of interest', () {
        // Declared type is `Object`; assigning an `int` after testing `int?`
        // promotes to `int`.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          if_(x.is_('int?'), [], []),
          checkNotPromoted(x),
          x.write(expr('int')),
          checkPromoted(x, 'int'),
        ]);
      });
    });

    group('Choosing among types of interest:', () {
      test('If one type is a subtype of all the others, it is chosen', () {
        // Types of interest are `List<num>` and `List<Object>`; writing
        // `List<int>` causes promotion to `List<num>`, because `List<num>` is a
        // subtype of `List<Object>`.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          if_(x.is_('List<num>'), [], []),
          if_(x.is_('List<Object>'), [], []),
          checkNotPromoted(x),
          x.write(expr('List<int>')),
          checkPromoted(x, 'List<num>'),
        ]);
      });

      test('If no type is a subtype of all the others, no promotion', () {
        // Types of interest are `List<Object?>` and `List<dynamic>`. Since
        // these are mutual subytpes, neither is preferred over the other. So
        // assignment of `List<int>` does not promote, even though both
        // `List<Object?>` and `List<dynamic>` are promotion candidates.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          if_(x.is_('List<Object?>'), [], []),
          if_(x.is_('List<dynamic>'), [], []),
          checkNotPromoted(x),
          x.write(expr('List<int>')),
          checkNotPromoted(x),
        ]);
      });

      test('If a type of interest matches exactly, it is chosen', () {
        // Types of interest are `List<Object?>` and `List<dynamic>`. Since
        // these are mutual subytpes, neither is preferred over the other. But
        // assignment of `List<Object?>` promotes, because it matches one of the
        // types of interest exactly.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          if_(x.is_('List<Object?>'), [], []),
          if_(x.is_('List<dynamic>'), [], []),
          checkNotPromoted(x),
          x.write(expr('List<Object?>')),
          checkPromoted(x, 'List<Object?>'),
        ]);
      });

      test('Only supertypes of written type are considered', () {
        // Types of interest are `num` and `String`; writing `int` causes
        // promotion to `num`, because `int` is not a subtype of `String`.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('Object')),
          if_(x.is_('num'), [], []),
          if_(x.is_('String'), [], []),
          checkNotPromoted(x),
          x.write(expr('int')),
          checkPromoted(x, 'num'),
        ]);
      });

      test('Only subtypes of declared type are considered', () {
        // Declared type is `List<Object>`. Types of interest are `List<num>`
        // and `List<int?>`, but `List<int?>` is not a subtype of
        // `List<Object>`. Writing `List<int>` (which is a subtype of both types
        // of interest) causes promotion to `List<num>`, because `List<int?>` is
        // not a subtype of the declared type.
        var x = Var('x');
        h.run([
          declare(x, initializer: expr('List<Object>')),
          if_(x.is_('List<num>'), [], []),
          if_(x.is_('List<int?>'), [], []),
          checkNotPromoted(x),
          x.write(expr('List<int>')),
          checkPromoted(x, 'List<num>'),
        ]);
      });
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
    (List<SharedTypeView> x) => unorderedEquals(
      expectedTypes,
    ).matches(x.map((t) => t.unwrapTypeView<Type>().type).toList(), {}),
    'interest set $expectedTypes',
  );
}

Matcher _matchPromotionChain(List<String> expectedTypes) {
  return predicate(
    (List<SharedTypeView> x) => equals(
      expectedTypes,
    ).matches(x.map((t) => t.unwrapTypeView<Type>().type).toList(), {}),
    'promotion chain $expectedTypes',
  );
}

Matcher _matchVariableModel({
  Object? chain,
  Object? ofInterest,
  Object? assigned,
  Object? unassigned,
  Object? writeCaptured,
}) {
  chain ??= anything;
  ofInterest ??= anything;
  assigned ??= anything;
  unassigned ??= anything;
  writeCaptured ??= anything;
  Matcher chainMatcher = chain is List<String>
      ? _matchPromotionChain(chain)
      : wrapMatcher(chain);
  Matcher ofInterestMatcher = ofInterest is List<String>
      ? _matchOfInterestSet(ofInterest)
      : wrapMatcher(ofInterest);
  Matcher assignedMatcher = wrapMatcher(assigned);
  Matcher unassignedMatcher = wrapMatcher(unassigned);
  Matcher writeCapturedMatcher = wrapMatcher(writeCaptured);
  return predicate(
    (PromotionModel<SharedTypeView> model) {
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
    'writeCaptured: ${_describeMatcher(writeCapturedMatcher)})',
  );
}

class _MockNonPromotionReason extends NonPromotionReason {
  @override
  NonPromotionDocumentationLink get documentationLink =>
      fail('Unexpected call to documentationLink');

  @override
  String get shortName => fail('Unexpected call to shortName');

  @override
  R accept<R, Node extends Object, Variable extends Object>(
    NonPromotionReasonVisitor<R, Node, Variable> visitor,
  ) => fail('Unexpected call to accept');
}

extension on FlowModel<SharedTypeView> {
  FlowModel<SharedTypeView> _conservativeJoin(
    FlowAnalysisTestHarness h,
    Iterable<Var> writtenVariables,
    Iterable<Var> capturedVariables,
  ) => conservativeJoin(
    h,
    [for (Var v in writtenVariables) h.promotionKeyStore.keyForVariable(v)],
    [for (Var v in capturedVariables) h.promotionKeyStore.keyForVariable(v)],
  );

  FlowModel<SharedTypeView> _declare(
    FlowAnalysisTestHarness h,
    Var variable,
    bool initialized,
  ) => this.declare(
    h,
    h.promotionKeyStore.keyForVariable(variable),
    initialized,
  );

  PromotionModel<SharedTypeView> _infoFor(
    FlowAnalysisTestHarness h,
    Var variable,
  ) => infoFor(
    h,
    h.promotionKeyStore.keyForVariable(variable),
    ssaNode: new SsaNode(),
  );

  FlowModel<SharedTypeView> _setInfo(
    FlowAnalysisTestHarness h,
    Map<int, PromotionModel<SharedTypeView>> newInfo,
  ) {
    var result = this;
    for (var core.MapEntry(:key, :value) in newInfo.entries) {
      if (result.promotionInfo?.get(h, key) != value) {
        result = result.updatePromotionInfo(h, key, value);
      }
    }
    return result;
  }

  ExpressionInfo<SharedTypeView> _tryMarkNonNullable(
    FlowAnalysisTestHarness h,
    Var variable,
  ) => tryMarkNonNullable(h, _varRefWithType(h, variable));

  ExpressionInfo<SharedTypeView> _tryPromoteForTypeCheck(
    FlowAnalysisTestHarness h,
    Var variable,
    String type,
  ) => tryPromoteForTypeCheck(
    h,
    _varRefWithType(h, variable),
    SharedTypeView(Type(type)),
  );

  int _varRef(FlowAnalysisTestHarness h, Var variable) =>
      h.promotionKeyStore.keyForVariable(variable);

  TrivialVariableReference<SharedTypeView> _varRefWithType(
    FlowAnalysisTestHarness h,
    Var variable,
  ) => new TrivialVariableReference<SharedTypeView>(
    promotionKey: _varRef(h, variable),
    model: this,
    type:
        promotionInfo
            ?.get(h, h.promotionKeyStore.keyForVariable(variable))
            ?.promotedTypes
            .lastOrNull ??
        SharedTypeView(variable.type),
    isThisOrSuper: false,
    ssaNode: SsaNode(),
  );

  FlowModel<SharedTypeView> _write(
    FlowAnalysisTestHarness h,
    NonPromotionReason? nonPromotionReason,
    Var variable,
    SharedTypeView writtenType,
    SsaNode<SharedTypeView> newSsaNode,
  ) => write(
    h,
    nonPromotionReason,
    h.promotionKeyStore.keyForVariable(variable),
    writtenType,
    newSsaNode,
    unpromotedType: SharedTypeView(variable.type),
  );
}

extension on PromotionInfo<SharedTypeView>? {
  Map<int, PromotionModel<SharedTypeView>> unwrap(FlowAnalysisTestHarness h) =>
      {
        for (var FlowLinkDiffEntry(:int key, right: second!)
            in h.reader.diff(null, this).entries)
          key: second.model,
      };
}
