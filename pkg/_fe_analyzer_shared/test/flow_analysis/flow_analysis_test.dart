// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

main() {
  group('API', () {
    test('asExpression_end promotes variables', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var expr = _Expression();
        flow.variableRead(expr, x);
        flow.asExpression_end(expr, _Type('int'));
        expect(flow.promotedType(x).type, 'int');
      });
    });

    test('asExpression_end handles other expressions', () {
      var h = _Harness();
      h.run((flow) {
        var expr = _Expression();
        flow.asExpression_end(expr, _Type('int'));
      });
    });

    test('assert_afterCondition promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        flow.assert_begin();
        var expr = h.eqNull(x)();
        flow.assert_afterCondition(expr);
        expect(flow.promotedType(x).type, 'int');
        flow.assert_end();
      });
    });

    test('assert_end joins previous and ifTrue states', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('x', 'int?');
      var z = h.addVar('x', 'int?');
      h.assignedVariables((vars) {
        vars.write(x);
        vars.write(z);
      });
      h.run((flow) {
        h.promote(x, 'int');
        h.promote(z, 'int');
        flow.assert_begin();
        flow.write(x, _Type('int?'));
        flow.write(z, _Type('int?'));
        var expr = h.and(h.notNull(x), h.notNull(y))();
        flow.assert_afterCondition(expr);
        flow.assert_end();
        // x should be promoted because it was promoted before the assert, and
        // it is re-promoted within the assert (if it passes)
        expect(flow.promotedType(x).type, 'int');
        // y should not be promoted because it was not promoted before the
        // assert.
        expect(flow.promotedType(y), null);
        // z should not be promoted because it is demoted in the assert
        // condition.
        expect(flow.promotedType(z), null);
      });
    });

    test('conditional_thenBegin promotes true branch', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.conditional_thenBegin(h.notNull(x)());
        expect(flow.promotedType(x).type, 'int');
        flow.conditional_elseBegin(_Expression());
        expect(flow.promotedType(x), isNull);
        flow.conditional_end(_Expression(), _Expression());
        expect(flow.promotedType(x), isNull);
      });
    });

    test('conditional_elseBegin promotes false branch', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.conditional_thenBegin(h.eqNull(x)());
        expect(flow.promotedType(x), isNull);
        flow.conditional_elseBegin(_Expression());
        expect(flow.promotedType(x).type, 'int');
        flow.conditional_end(_Expression(), _Expression());
        expect(flow.promotedType(x), isNull);
      });
    });

    test('conditional_end keeps promotions common to true and false branches',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        flow.conditional_thenBegin(_Expression());
        h.promote(x, 'int');
        h.promote(y, 'int');
        flow.conditional_elseBegin(_Expression());
        h.promote(x, 'int');
        h.promote(z, 'int');
        flow.conditional_end(_Expression(), _Expression());
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y), isNull);
        expect(flow.promotedType(z), isNull);
      });
    });

    test('conditional joins true states', () {
      // if (... ? (x != null && y != null) : (x != null && z != null)) {
      //   promotes x, but not y or z
      // }
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        h.if_(
            h.conditional(h.expr, h.and(h.notNull(x), h.notNull(y)),
                h.and(h.notNull(x), h.notNull(z))), () {
          expect(flow.promotedType(x).type, 'int');
          expect(flow.promotedType(y), isNull);
          expect(flow.promotedType(z), isNull);
        });
      });
    });

    test('conditional joins false states', () {
      // if (... ? (x == null || y == null) : (x == null || z == null)) {
      // } else {
      //   promotes x, but not y or z
      // }
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        h.ifElse(
            h.conditional(h.expr, h.or(h.eqNull(x), h.eqNull(y)),
                h.or(h.eqNull(x), h.eqNull(z))),
            () {}, () {
          expect(flow.promotedType(x).type, 'int');
          expect(flow.promotedType(y), isNull);
          expect(flow.promotedType(z), isNull);
        });
      });
    });

    test('equalityOp(x != null) promotes true branch', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var varExpr = _Expression();
        flow.variableRead(varExpr, x);
        flow.equalityOp_rightBegin(varExpr);
        var nullExpr = _Expression();
        flow.nullLiteral(nullExpr);
        var expr = _Expression();
        flow.equalityOp_end(expr, nullExpr, notEqual: true);
        flow.ifStatement_thenBegin(expr);
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_elseBegin();
        expect(flow.promotedType(x), isNull);
        flow.ifStatement_end(true);
      });
    });

    test('equalityOp(x == null) promotes false branch', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var varExpr = _Expression();
        flow.variableRead(varExpr, x);
        flow.equalityOp_rightBegin(varExpr);
        var nullExpr = _Expression();
        flow.nullLiteral(nullExpr);
        var expr = _Expression();
        flow.equalityOp_end(expr, nullExpr, notEqual: false);
        flow.ifStatement_thenBegin(expr);
        expect(flow.promotedType(x), isNull);
        flow.ifStatement_elseBegin();
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_end(true);
      });
    });

    test('equalityOp(null != x) promotes true branch', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var nullExpr = _Expression();
        flow.nullLiteral(nullExpr);
        flow.equalityOp_rightBegin(nullExpr);
        var varExpr = _Expression();
        flow.variableRead(varExpr, x);
        var expr = _Expression();
        flow.equalityOp_end(expr, varExpr, notEqual: true);
        flow.ifStatement_thenBegin(expr);
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_elseBegin();
        expect(flow.promotedType(x), isNull);
        flow.ifStatement_end(true);
      });
    });

    test('equalityOp(null == x) promotes false branch', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var nullExpr = _Expression();
        flow.nullLiteral(nullExpr);
        flow.equalityOp_rightBegin(nullExpr);
        var varExpr = _Expression();
        flow.variableRead(varExpr, x);
        var expr = _Expression();
        flow.equalityOp_end(expr, varExpr, notEqual: false);
        flow.ifStatement_thenBegin(expr);
        expect(flow.promotedType(x), isNull);
        flow.ifStatement_elseBegin();
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_end(true);
      });
    });

    test('conditionEqNull() does not promote write-captured vars', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var functionNode = _Node();
      h.assignedVariables(
          (vars) => vars.function(functionNode, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.if_(h.notNull(x), () {
          expect(flow.promotedType(x).type, 'int');
        });
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        h.if_(h.notNull(x), () {
          expect(flow.promotedType(x), isNull);
        });
      });
    });

    test('doStatement_bodyBegin() un-promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var doStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(doStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.doStatement_bodyBegin(doStatement);
        expect(flow.promotedType(x), isNull);
        flow.doStatement_conditionBegin();
        flow.doStatement_end(_Expression());
      });
    });

    test('doStatement_bodyBegin() handles write captures in the loop', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var doStatement = _Statement();
      var functionNode = _Node();
      h.assignedVariables((vars) => vars.nest(
          doStatement, () => vars.function(functionNode, () => vars.write(x))));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.doStatement_bodyBegin(doStatement);
        h.promote(x, 'int');
        // The promotion should have no effect, because the second time through
        // the loop, x has been write-captured.
        expect(flow.promotedType(x), isNull);
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        flow.doStatement_conditionBegin();
        flow.doStatement_end(_Expression());
      });
    });

    test('doStatement_conditionBegin() joins continue state', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.doStatement_bodyBegin(stmt);
        h.if_(h.notNull(x), () {
          flow.handleContinue(stmt);
        });
        flow.handleExit();
        expect(flow.isReachable, false);
        expect(flow.promotedType(x), isNull);
        flow.doStatement_conditionBegin();
        expect(flow.isReachable, true);
        expect(flow.promotedType(x).type, 'int');
        flow.doStatement_end(_Expression());
      });
    });

    test('doStatement_end() promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.doStatement_bodyBegin(stmt);
        flow.doStatement_conditionBegin();
        expect(flow.promotedType(x), isNull);
        flow.doStatement_end(h.eqNull(x)());
        expect(flow.promotedType(x).type, 'int');
      });
    });

    test('finish checks proper nesting', () {
      var h = _Harness();
      var expr = _Expression();
      var flow = h.createFlow();
      flow.ifStatement_thenBegin(expr);
      expect(() => flow.finish(), _asserts);
    });

    test('for_conditionBegin() un-promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var forStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(forStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.for_conditionBegin(forStatement);
        expect(flow.promotedType(x), isNull);
        flow.for_bodyBegin(_Statement(), _Expression());
        flow.write(x, _Type('int?'));
        flow.for_updaterBegin();
        flow.for_end();
      });
    });

    test('for_conditionBegin() handles write captures in the loop', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var forStatement = _Statement();
      var functionNode = _Node();
      h.assignedVariables((vars) => vars.nest(forStatement,
          () => vars.function(functionNode, () => vars.write(x))));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.for_conditionBegin(forStatement);
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        flow.for_bodyBegin(_Statement(), _Expression());
        flow.for_updaterBegin();
        flow.for_end();
      });
    });

    test('for_conditionBegin() handles not-yet-seen variables', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var forStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(forStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.for_conditionBegin(forStatement);
        flow.declare(x, true);
        flow.for_bodyBegin(_Statement(), _Expression());
        flow.for_updaterBegin();
        flow.for_end();
      });
    });

    test('for_bodyBegin() handles empty condition', () {
      var h = _Harness();
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        flow.for_conditionBegin(stmt);
        flow.for_bodyBegin(stmt, null);
        flow.for_updaterBegin();
        expect(flow.isReachable, isTrue);
        flow.for_end();
        expect(flow.isReachable, isFalse);
      });
    });

    test('for_bodyBegin() promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.for_conditionBegin(stmt);
        flow.for_bodyBegin(stmt, h.notNull(x)());
        expect(flow.promotedType(x).type, 'int');
        flow.for_updaterBegin();
        flow.for_end();
      });
    });

    test('for_bodyBegin() can be used with a null statement', () {
      // This is needed for collection elements that are for-loops.
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var node = _Node();
      h.assignedVariables((vars) => vars.nest(node, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.for_conditionBegin(node);
        flow.for_bodyBegin(null, h.notNull(x)());
        flow.for_updaterBegin();
        flow.for_end();
      });
    });

    test('for_updaterBegin() joins current and continue states', () {
      // To test that the states are properly joined, we have three variables:
      // x, y, and z.  We promote x and y in the continue path, and x and z in
      // the current path.  Inside the updater, only x should be promoted.
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        flow.for_conditionBegin(stmt);
        flow.for_bodyBegin(stmt, h.expr());
        h.if_(h.expr, () {
          h.promote(x, 'int');
          h.promote(y, 'int');
          flow.handleContinue(stmt);
        });
        h.promote(x, 'int');
        h.promote(z, 'int');
        flow.for_updaterBegin();
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y), isNull);
        expect(flow.promotedType(z), isNull);
        flow.for_end();
      });
    });

    test('for_end() joins break and condition-false states', () {
      // To test that the states are properly joined, we have three variables:
      // x, y, and z.  We promote x and y in the break path, and x and z in the
      // condition-false path.  After the loop, only x should be promoted.
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        flow.for_conditionBegin(stmt);
        flow.for_bodyBegin(stmt, h.or(h.eqNull(x), h.eqNull(z))());
        h.if_(h.expr, () {
          h.promote(x, 'int');
          h.promote(y, 'int');
          flow.handleBreak(stmt);
        });
        flow.for_updaterBegin();
        flow.for_end();
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y), isNull);
        expect(flow.promotedType(z), isNull);
      });
    });

    test('forEach_bodyBegin() un-promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var forStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(forStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.forEach_bodyBegin(forStatement, null, _Type('int?'));
        expect(flow.promotedType(x), isNull);
        flow.write(x, _Type('int?'));
        flow.forEach_end();
      });
    });

    test('forEach_bodyBegin() handles write captures in the loop', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var forStatement = _Statement();
      var functionNode = _Node();
      h.assignedVariables((vars) => vars.nest(forStatement,
          () => vars.function(functionNode, () => vars.write(x))));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.forEach_bodyBegin(forStatement, null, _Type('int?'));
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        flow.forEach_end();
      });
    });

    test('forEach_bodyBegin() writes to loop variable', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var forStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(forStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: false);
        expect(flow.isAssigned(x), false);
        flow.forEach_bodyBegin(forStatement, x, _Type('int?'));
        expect(flow.isAssigned(x), true);
        flow.forEach_end();
        expect(flow.isAssigned(x), false);
      });
    });

    test('forEach_end() restores state before loop', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.forEach_bodyBegin(stmt, null, _Type('int?'));
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.forEach_end();
        expect(flow.promotedType(x), isNull);
      });
    });

    test('functionExpression_begin() cancels promotions of self-captured vars',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var functionNode = _Node();
      h.assignedVariables(
          (vars) => vars.function(functionNode, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.promote(x, 'int');
        h.promote(y, 'int');
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.functionExpression_begin(functionNode);
        // x is unpromoted within the local function
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
        flow.write(x, _Type('int?'));
        h.promote(x, 'int');
        flow.functionExpression_end();
        // x is unpromoted after the local function too
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
      });
    });

    test('functionExpression_begin() cancels promotions of other-captured vars',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var functionNode1 = _Node();
      var functionNode2 = _Node();
      h.assignedVariables((vars) {
        vars.function(functionNode1, () {});
        vars.function(functionNode2, () => vars.write(x));
      });
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.promote(x, 'int');
        h.promote(y, 'int');
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.functionExpression_begin(functionNode1);
        // x is unpromoted within the local function, because the write
        // might have been captured by the time the local function executes.
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
        // And any effort to promote x fails, because there is no way of knowing
        // when the captured write might occur.
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
        flow.functionExpression_end();
        // x is still promoted after the local function, though, because the
        // write hasn't been captured yet.
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.functionExpression_begin(functionNode2);
        // x is unpromoted inside this local function too.
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
        flow.write(x, _Type('int?'));
        flow.functionExpression_end();
        // And since the second local function captured x, it remains
        // unpromoted.
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
      });
    });

    test('functionExpression_begin() cancels promotions of written vars', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var node = _Node();
      h.assignedVariables((vars) {
        vars.function(node, () {});
        vars.write(x);
      });
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.promote(x, 'int');
        h.promote(y, 'int');
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.functionExpression_begin(node);
        // x is unpromoted within the local function, because the write
        // might have happened by the time the local function executes.
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
        // But it can be re-promoted because the write isn't captured.
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.functionExpression_end();
        // x is still promoted after the local function, though, because the
        // write hasn't occurred yet.
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.write(x, _Type('int?'));
        // x is unpromoted now.
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
      });
    });

    test('functionExpression_begin() handles not-yet-seen variables', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var functionNode = _Node();
      h.assignedVariables(
          (vars) => vars.function(functionNode, () => vars.write(x)));
      h.run((flow) {
        flow.functionExpression_begin(functionNode);
        flow.functionExpression_end();
        // x is declared after the local function, so the local function
        // cannot possibly write to x.
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
      });
    });

    test('functionExpression_begin() handles not-yet-seen write-captured vars',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var functionNode1 = _Node();
      var functionNode2 = _Node();
      h.assignedVariables((vars) {
        vars.function(functionNode1, () {});
        vars.function(functionNode2, () => vars.write(x));
      });
      h.run((flow) {
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.functionExpression_begin(functionNode1);
        h.promote(x, 'int');
        // Promotion should not occur, because x might be write-captured by the
        // time this code is reached.
        expect(flow.promotedType(x), isNull);
        flow.functionExpression_end();
        flow.functionExpression_begin(functionNode2);
        h.declare(x, initialized: true);
        flow.functionExpression_end();
      });
    });

    test('ifNullExpression allows ensure guarding', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.assignedVariables((vars) => vars.write(x));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.ifNullExpression_rightBegin(h.variableRead(x)());
        flow.write(x, _Type('int'));
        expect(flow.promotedType(x).type, 'int');
        flow.ifNullExpression_end();
        expect(flow.promotedType(x).type, 'int');
      });
    });

    test('ifNullExpression allows promotion of tested var', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.ifNullExpression_rightBegin(h.variableRead(x)());
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.ifNullExpression_end();
        expect(flow.promotedType(x).type, 'int');
      });
    });

    test('ifNullExpression discards promotions unrelated to tested expr', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.ifNullExpression_rightBegin(h.expr());
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.ifNullExpression_end();
        expect(flow.promotedType(x), null);
      });
    });

    test('ifStatement_end(false) keeps else branch if then branch exits', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.ifStatement_thenBegin(h.eqNull(x)());
        flow.handleExit();
        flow.ifStatement_end(false);
        expect(flow.promotedType(x).type, 'int');
      });
    });

    void _checkIs(
      String declaredType,
      String tryPromoteType,
      String expectedPromotedTypeThen,
      String expectedPromotedTypeElse,
    ) {
      var h = _Harness();
      var x = h.addVar('x', declaredType);
      h.run((flow) {
        h.declare(x, initialized: true);
        var read = _Expression();
        flow.variableRead(read, x);
        var expr = _Expression();
        flow.isExpression_end(expr, read, false, _Type(tryPromoteType));
        flow.ifStatement_thenBegin(expr);
        if (expectedPromotedTypeThen == null) {
          expect(flow.promotedType(x), isNull);
        } else {
          expect(flow.promotedType(x).type, expectedPromotedTypeThen);
        }
        flow.ifStatement_elseBegin();
        if (expectedPromotedTypeElse == null) {
          expect(flow.promotedType(x), isNull);
        } else {
          expect(flow.promotedType(x).type, expectedPromotedTypeElse);
        }
        flow.ifStatement_end(true);
      });
    }

    test('isExpression_end promotes to a subtype', () {
      _checkIs('int?', 'int', 'int', 'Never?');
    });

    test('isExpression_end does not promote to a supertype', () {
      _checkIs('int', 'int?', null, 'Never');
    });

    test('isExpression_end does not promote to an unrelated type', () {
      _checkIs('int', 'String', null, null);
    });

    test('isExpression_end() does not promote write-captured vars', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var functionNode = _Node();
      h.assignedVariables(
          (vars) => vars.function(functionNode, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.if_(h.isType(h.variableRead(x), 'int'), () {
          expect(flow.promotedType(x).type, 'int');
        });
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        h.if_(h.isType(h.variableRead(x), 'int'), () {
          expect(flow.promotedType(x), isNull);
        });
      });
    });

    test('isExpression_end() handles not-yet-seen variables', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.assignedVariables(
          (vars) => vars.function(_Node(), () => vars.write(x)));
      h.run((flow) {
        h.if_(h.isType(h.variableRead(x), 'int'), () {
          expect(flow.promotedType(x).type, 'int');
        });
        h.declare(x, initialized: true);
      });
    });

    test('labeledBlock without break', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var block = _Statement();
      h.run((flow) {
        h.declare(x, initialized: true);

        h.ifIsNotType(x, 'int', () {
          h.labeledBlock(block, () {
            flow.handleExit();
          });
        });
        expect(flow.promotedType(x).type, 'int');
      });
    });

    test('labeledBlock with break joins', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var block = _Statement();
      h.run((flow) {
        h.declare(x, initialized: true);

        h.ifIsNotType(x, 'int', () {
          h.labeledBlock(block, () {
            h.if_(h.expr, () {
              flow.handleBreak(block);
            });
            flow.handleExit();
          });
        });
        expect(flow.promotedType(x), isNull);
      });
    });

    test('logicalBinaryOp_rightBegin(isAnd: true) promotes in RHS', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.logicalBinaryOp_rightBegin(h.notNull(x)(), isAnd: true);
        expect(flow.promotedType(x).type, 'int');
        flow.logicalBinaryOp_end(_Expression(), _Expression(), isAnd: true);
      });
    });

    test('logicalBinaryOp_rightEnd(isAnd: true) keeps promotions from RHS', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.logicalBinaryOp_rightBegin(_Expression(), isAnd: true);
        var wholeExpr = _Expression();
        flow.logicalBinaryOp_end(wholeExpr, h.notNull(x)(), isAnd: true);
        flow.ifStatement_thenBegin(wholeExpr);
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_end(false);
      });
    });

    test('logicalBinaryOp_rightEnd(isAnd: false) keeps promotions from RHS',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.logicalBinaryOp_rightBegin(_Expression(), isAnd: false);
        var wholeExpr = _Expression();
        flow.logicalBinaryOp_end(wholeExpr, h.eqNull(x)(), isAnd: false);
        flow.ifStatement_thenBegin(wholeExpr);
        flow.ifStatement_elseBegin();
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_end(true);
      });
    });

    test('logicalBinaryOp_rightBegin(isAnd: false) promotes in RHS', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.logicalBinaryOp_rightBegin(h.eqNull(x)(), isAnd: false);
        expect(flow.promotedType(x).type, 'int');
        flow.logicalBinaryOp_end(_Expression(), _Expression(), isAnd: false);
      });
    });

    test('logicalBinaryOp(isAnd: true) joins promotions', () {
      // if (x != null && y != null) {
      //   promotes x and y
      // }
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.if_(h.and(h.notNull(x), h.notNull(y)), () {
          expect(flow.promotedType(x).type, 'int');
          expect(flow.promotedType(y).type, 'int');
        });
      });
    });

    test('logicalBinaryOp(isAnd: false) joins promotions', () {
      // if (x == null || y == null) {} else {
      //   promotes x and y
      // }
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.ifElse(h.or(h.eqNull(x), h.eqNull(y)), () {}, () {
          expect(flow.promotedType(x).type, 'int');
          expect(flow.promotedType(y).type, 'int');
        });
      });
    });

    test('nonNullAssert_end(x) promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var varExpr = _Expression();
        flow.variableRead(varExpr, x);
        flow.nonNullAssert_end(varExpr);
        expect(flow.promotedType(x).type, 'int');
      });
    });

    test('nullAwareAccess temporarily promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var varExpr = _Expression();
        flow.variableRead(varExpr, x);
        flow.nullAwareAccess_rightBegin(varExpr);
        expect(flow.promotedType(x).type, 'int');
        flow.nullAwareAccess_end();
        expect(flow.promotedType(x), isNull);
      });
    });

    test('nullAwareAccess does not promote the target of a cascade', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var varExpr = _Expression();
        flow.variableRead(varExpr, x);
        flow.nullAwareAccess_rightBegin(null);
        expect(flow.promotedType(x), isNull);
        flow.nullAwareAccess_end();
      });
    });

    test('nullAwareAccess preserves demotions', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.assignedVariables((vars) => vars.write(x));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        var lhs = _Expression();
        flow.nullAwareAccess_rightBegin(lhs);
        expect(flow.promotedType(x).type, 'int');
        flow.write(x, _Type('int?'));
        expect(flow.promotedType(x), isNull);
        flow.nullAwareAccess_end();
        expect(flow.promotedType(x), isNull);
      });
    });

    test('parenthesizedExpression preserves promotion behaviors', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.if_(
            h.parenthesized(h.notEqual(h.parenthesized(h.variableRead(x)),
                h.parenthesized(h.nullLiteral))), () {
          expect(flow.promotedType(x).type, 'int');
        });
      });
    });

    test('promotedType handles not-yet-seen variables', () {
      // Note: this is needed for error recovery in the analyzer.
      var h = _Harness();
      var x = h.addVar('x', 'int');
      h.run((flow) {
        expect(flow.promotedType(x), isNull);
        h.declare(x, initialized: true);
      });
    });

    test('switchStatement_beginCase(false) restores previous promotions', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var switchStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(switchStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        flow.switchStatement_expressionEnd(_Statement());
        flow.switchStatement_beginCase(false, switchStatement);
        expect(flow.promotedType(x).type, 'int');
        flow.write(x, _Type('int?'));
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_beginCase(false, switchStatement);
        expect(flow.promotedType(x).type, 'int');
        flow.write(x, _Type('int?'));
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_end(false);
      });
    });

    test('switchStatement_beginCase(false) does not un-promote', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var switchStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(switchStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        flow.switchStatement_expressionEnd(_Statement());
        flow.switchStatement_beginCase(false, switchStatement);
        expect(flow.promotedType(x).type, 'int');
        flow.write(x, _Type('int?'));
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_end(false);
      });
    });

    test('switchStatement_beginCase(false) handles write captures in cases',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var switchStatement = _Statement();
      var functionNode = _Node();
      h.assignedVariables((vars) => vars.nest(switchStatement,
          () => vars.function(functionNode, () => vars.write(x))));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        flow.switchStatement_expressionEnd(_Statement());
        flow.switchStatement_beginCase(false, switchStatement);
        expect(flow.promotedType(x).type, 'int');
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_end(false);
      });
    });

    test('switchStatement_beginCase(true) un-promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var switchStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(switchStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        flow.switchStatement_expressionEnd(_Statement());
        flow.switchStatement_beginCase(true, switchStatement);
        expect(flow.promotedType(x), isNull);
        flow.write(x, _Type('int?'));
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_end(false);
      });
    });

    test('switchStatement_beginCase(true) handles write captures in cases', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var switchStatement = _Statement();
      var functionNode = _Node();
      h.assignedVariables((vars) => vars.nest(switchStatement,
          () => vars.function(functionNode, () => vars.write(x))));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        flow.switchStatement_expressionEnd(_Statement());
        flow.switchStatement_beginCase(true, switchStatement);
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_end(false);
      });
    });

    test('switchStatement_end(false) joins break and default', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      var switchStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(switchStatement, () => vars.write(y)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        h.promote(y, 'int');
        h.promote(z, 'int');
        var stmt = _Statement();
        flow.switchStatement_expressionEnd(stmt);
        flow.switchStatement_beginCase(false, switchStatement);
        h.promote(x, 'int');
        flow.write(y, _Type('int?'));
        flow.handleBreak(stmt);
        flow.switchStatement_end(false);
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y), isNull);
        expect(flow.promotedType(z).type, 'int');
      });
    });

    test('switchStatement_end(true) joins breaks', () {
      var h = _Harness();
      var w = h.addVar('w', 'int?');
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      var switchStatement = _Statement();
      h.assignedVariables((vars) => vars.nest(switchStatement, () {
            vars.write(x);
            vars.write(y);
          }));
      h.run((flow) {
        h.declare(w, initialized: true);
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        h.promote(x, 'int');
        h.promote(y, 'int');
        h.promote(z, 'int');
        var stmt = _Statement();
        flow.switchStatement_expressionEnd(stmt);
        flow.switchStatement_beginCase(false, switchStatement);
        h.promote(w, 'int');
        h.promote(y, 'int');
        flow.write(x, _Type('int?'));
        flow.handleBreak(stmt);
        flow.switchStatement_beginCase(false, switchStatement);
        h.promote(w, 'int');
        h.promote(x, 'int');
        flow.write(y, _Type('int?'));
        flow.handleBreak(stmt);
        flow.switchStatement_end(true);
        expect(flow.promotedType(w).type, 'int');
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y), isNull);
        expect(flow.promotedType(z).type, 'int');
      });
    });

    test('switchStatement_end(true) allows fall-through of last case', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.switchStatement_expressionEnd(stmt);
        flow.switchStatement_beginCase(false, stmt);
        h.promote(x, 'int');
        flow.handleBreak(stmt);
        flow.switchStatement_beginCase(false, stmt);
        flow.switchStatement_end(true);
        expect(flow.promotedType(x), isNull);
      });
    });

    test('tryCatchStatement_bodyEnd() restores pre-try state', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.tryCatchStatement_bodyBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.tryCatchStatement_bodyEnd(stmt);
        flow.tryCatchStatement_catchBegin(null, null);
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_end();
      });
    });

    test('tryCatchStatement_bodyEnd() un-promotes variables assigned in body',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var body = _Statement();
      h.assignedVariables((vars) => vars.nest(body, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryCatchStatement_bodyBegin();
        flow.write(x, _Type('int?'));
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryCatchStatement_bodyEnd(body);
        flow.tryCatchStatement_catchBegin(null, null);
        expect(flow.promotedType(x), isNull);
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_end();
      });
    });

    test('tryCatchStatement_bodyEnd() preserves write captures in body', () {
      // Note: it's not necessary for the write capture to survive to the end of
      // the try body, because an exception could occur at any time.  We check
      // this by putting an exit in the try body.
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var body = _Statement();
      var functionNode = _Node();
      h.assignedVariables((vars) => vars.nest(
          body, () => vars.function(functionNode, () => vars.write(x))));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryCatchStatement_bodyBegin();
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        flow.handleExit();
        flow.tryCatchStatement_bodyEnd(body);
        flow.tryCatchStatement_catchBegin(null, null);
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_end();
      });
    });

    test('tryCatchStatement_catchBegin() restores previous post-body state',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.tryCatchStatement_bodyBegin();
        flow.tryCatchStatement_bodyEnd(stmt);
        flow.tryCatchStatement_catchBegin(null, null);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_catchBegin(null, null);
        expect(flow.promotedType(x), isNull);
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_end();
      });
    });

    test('tryCatchStatement_catchBegin() initializes vars', () {
      var h = _Harness();
      var e = h.addVar('e', 'int');
      var st = h.addVar('st', 'StackTrace');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        flow.tryCatchStatement_bodyBegin();
        flow.tryCatchStatement_bodyEnd(stmt);
        flow.tryCatchStatement_catchBegin(e, st);
        expect(flow.isAssigned(e), true);
        expect(flow.isAssigned(st), true);
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_end();
      });
    });

    test('tryCatchStatement_catchEnd() joins catch state with after-try state',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        flow.tryCatchStatement_bodyBegin();
        h.promote(x, 'int');
        h.promote(y, 'int');
        flow.tryCatchStatement_bodyEnd(stmt);
        flow.tryCatchStatement_catchBegin(null, null);
        h.promote(x, 'int');
        h.promote(z, 'int');
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_end();
        // Only x should be promoted, because it's the only variable
        // promoted in both the try body and the catch handler.
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y), isNull);
        expect(flow.promotedType(z), isNull);
      });
    });

    test('tryCatchStatement_catchEnd() joins catch states', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        flow.tryCatchStatement_bodyBegin();
        flow.handleExit();
        flow.tryCatchStatement_bodyEnd(stmt);
        flow.tryCatchStatement_catchBegin(null, null);
        h.promote(x, 'int');
        h.promote(y, 'int');
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_catchBegin(null, null);
        h.promote(x, 'int');
        h.promote(z, 'int');
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_end();
        // Only x should be promoted, because it's the only variable promoted
        // in both catch handlers.
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y), isNull);
        expect(flow.promotedType(z), isNull);
      });
    });

    test('tryFinallyStatement_finallyBegin() restores pre-try state', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var body = _Node();
      var finallyBlock = _Node();
      h.assignedVariables((vars) {
        vars.nest(body, () {});
        vars.nest(finallyBlock, () {});
      });
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.tryFinallyStatement_bodyBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.tryFinallyStatement_finallyBegin(body);
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
        flow.tryFinallyStatement_end(finallyBlock);
      });
    });

    test(
        'tryFinallyStatement_finallyBegin() un-promotes variables assigned in '
        'body', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var body = _Node();
      var finallyBlock = _Node();
      h.assignedVariables((vars) {
        vars.nest(body, () => vars.write(x));
        vars.nest(finallyBlock, () {});
      });
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryFinallyStatement_bodyBegin();
        flow.write(x, _Type('int?'));
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryFinallyStatement_finallyBegin(body);
        expect(flow.promotedType(x), isNull);
        flow.tryFinallyStatement_end(finallyBlock);
      });
    });

    test('tryFinallyStatement_finallyBegin() preserves write captures in body',
        () {
      // Note: it's not necessary for the write capture to survive to the end of
      // the try body, because an exception could occur at any time.  We check
      // this by putting an exit in the try body.
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var body = _Statement();
      var functionNode = _Node();
      var finallyBlock = _Node();
      h.assignedVariables((vars) => vars.nest(body, () {
            vars.function(functionNode, () => vars.write(x));
            vars.nest(finallyBlock, () {});
          }));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.tryFinallyStatement_bodyBegin();
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        flow.handleExit();
        flow.tryFinallyStatement_finallyBegin(body);
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
        flow.tryFinallyStatement_end(finallyBlock);
      });
    });

    test('tryFinallyStatement_end() restores promotions from try body', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var body = _Statement();
      var finallyBlock = _Node();
      h.assignedVariables((vars) => vars.nest(body, () {
            vars.nest(body, () {});
            vars.nest(finallyBlock, () {});
          }));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        flow.tryFinallyStatement_bodyBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryFinallyStatement_finallyBegin(body);
        expect(flow.promotedType(x), isNull);
        h.promote(y, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.tryFinallyStatement_end(finallyBlock);
        // Both x and y should now be promoted.
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
      });
    });

    test(
        'tryFinallyStatement_end() does not restore try body promotions for '
        'variables assigned in finally', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var body = _Node();
      var finallyBlock = _Node();
      h.assignedVariables((vars) {
        vars.nest(body, () {});
        vars.nest(finallyBlock, () {
          vars.write(x);
          vars.write(y);
        });
      });
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        flow.tryFinallyStatement_bodyBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryFinallyStatement_finallyBegin(body);
        expect(flow.promotedType(x), isNull);
        flow.write(x, _Type('int?'));
        flow.write(y, _Type('int?'));
        h.promote(y, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.tryFinallyStatement_end(finallyBlock);
        // x should not be re-promoted, because it might have been assigned a
        // non-promoted value in the "finally" block.  But y's promotion still
        // stands, because y was promoted in the finally block.
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
      });
    });

    test('whileStatement_conditionBegin() un-promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var whileStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(whileStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.whileStatement_conditionBegin(whileStatement);
        expect(flow.promotedType(x), isNull);
        flow.whileStatement_bodyBegin(_Statement(), _Expression());
        flow.whileStatement_end();
      });
    });

    test('whileStatement_conditionBegin() handles write captures in the loop',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var whileStatement = _Statement();
      var functionNode = _Node();
      h.assignedVariables((vars) => vars.nest(whileStatement,
          () => vars.function(functionNode, () => vars.write(x))));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.whileStatement_conditionBegin(whileStatement);
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
        h.function(functionNode, () {
          flow.write(x, _Type('int?'));
        });
        flow.whileStatement_bodyBegin(_Statement(), _Expression());
        flow.whileStatement_end();
      });
    });

    test('whileStatement_conditionBegin() handles not-yet-seen variables', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var whileStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(whileStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.whileStatement_conditionBegin(whileStatement);
        flow.declare(x, true);
        flow.whileStatement_bodyBegin(_Statement(), _Expression());
        flow.whileStatement_end();
      });
    });

    test('whileStatement_bodyBegin() promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.whileStatement_conditionBegin(stmt);
        flow.whileStatement_bodyBegin(stmt, h.notNull(x)());
        expect(flow.promotedType(x).type, 'int');
        flow.whileStatement_end();
      });
    });

    test('whileStatement_end() joins break and condition-false states', () {
      // To test that the states are properly joined, we have three variables:
      // x, y, and z.  We promote x and y in the break path, and x and z in the
      // condition-false path.  After the loop, only x should be promoted.
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      var stmt = _Statement();
      h.assignedVariables((vars) => vars.nest(stmt, () {}));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        flow.whileStatement_conditionBegin(stmt);
        flow.whileStatement_bodyBegin(stmt, h.or(h.eqNull(x), h.eqNull(z))());
        h.if_(h.expr, () {
          h.promote(x, 'int');
          h.promote(y, 'int');
          flow.handleBreak(stmt);
        });
        flow.whileStatement_end();
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y), isNull);
        expect(flow.promotedType(z), isNull);
      });
    });

    test('Infinite loop does not implicitly assign variables', () {
      var h = _Harness();
      var x = h.addVar('x', 'int');
      var whileStatement = _Statement();
      h.assignedVariables(
          (vars) => vars.nest(whileStatement, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: false);
        var trueCondition = _Expression();
        flow.whileStatement_conditionBegin(whileStatement);
        flow.booleanLiteral(trueCondition, true);
        flow.whileStatement_bodyBegin(whileStatement, trueCondition);
        flow.whileStatement_end();
        expect(flow.isAssigned(x), false);
      });
    });

    test('If(false) does not discard promotions', () {
      var h = _Harness();
      var x = h.addVar('x', 'Object');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        // if (false) {
        var falseExpression = _Expression();
        flow.booleanLiteral(falseExpression, false);
        flow.ifStatement_thenBegin(falseExpression);
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_end(false);
      });
    });

    test('Promotions do not occur when a variable is write-captured', () {
      var h = _Harness();
      var x = h.addVar('x', 'Object');
      var functionNode = _Node();
      h.assignedVariables(
          (vars) => vars.function(functionNode, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.function(functionNode, () {});
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
      });
    });

    test('Promotion cancellation of write-captured vars survives join', () {
      var h = _Harness();
      var x = h.addVar('x', 'Object');
      var functionNode = _Node();
      h.assignedVariables(
          (vars) => vars.function(functionNode, () => vars.write(x)));
      h.run((flow) {
        h.declare(x, initialized: true);
        h.ifElse(h.expr, () {
          h.function(functionNode, () {});
        }, () {
          // Promotion should work here because the write capture is in the
          // other branch.
          h.promote(x, 'int');
          expect(flow.promotedType(x).type, 'int');
        });
        // But the promotion should be cancelled now, after the join.
        expect(flow.promotedType(x), isNull);
        // And further attempts to promote should fail due to the write capture.
        h.promote(x, 'int');
        expect(flow.promotedType(x), isNull);
      });
    });
  });

  group('State', () {
    var intVar = _Var('x', _Type('int'));
    var intQVar = _Var('x', _Type('int?'));
    var objectQVar = _Var('x', _Type('Object?'));
    group('setReachable', () {
      var unreachable = FlowModel<_Var, _Type>(false);
      var reachable = FlowModel<_Var, _Type>(true);
      test('unchanged', () {
        expect(unreachable.setReachable(false), same(unreachable));
        expect(reachable.setReachable(true), same(reachable));
      });

      test('changed', () {
        void _check(FlowModel<_Var, _Type> initial, bool newReachability) {
          var s = initial.setReachable(newReachability);
          expect(s, isNot(same(initial)));
          expect(s.reachable, newReachability);
          expect(s.variableInfo, same(initial.variableInfo));
        }

        _check(unreachable, true);
        _check(reachable, false);
      });
    });

    group('tryPromoteForTypeCheck', () {
      test('unpromoted -> unchanged (same)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.tryPromoteForTypeCheck(h, intVar, _Type('int')).ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (supertype)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.tryPromoteForTypeCheck(h, intVar, _Type('Object')).ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (unrelated)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.tryPromoteForTypeCheck(h, intVar, _Type('String')).ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> subtype', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.tryPromoteForTypeCheck(h, intQVar, _Type('int')).ifTrue;
        expect(s2.reachable, true);
        expect(s2.variableInfo, {
          intQVar: _matchVariableModel(chain: ['int'], ofInterest: ['int'])
        });
      });

      test('promoted -> unchanged (same)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue;
        var s2 = s1.tryPromoteForTypeCheck(h, objectQVar, _Type('int')).ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (supertype)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue;
        var s2 =
            s1.tryPromoteForTypeCheck(h, objectQVar, _Type('Object')).ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (unrelated)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue;
        var s2 =
            s1.tryPromoteForTypeCheck(h, objectQVar, _Type('String')).ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> subtype', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int?'))
            .ifTrue;
        var s2 = s1.tryPromoteForTypeCheck(h, objectQVar, _Type('int')).ifTrue;
        expect(s2.reachable, true);
        expect(s2.variableInfo, {
          objectQVar: _matchVariableModel(
              chain: ['int?', 'int'], ofInterest: ['int?', 'int'])
        });
      });
    });

    group('write', () {
      var objectQVar = _Var('x', _Type('Object?'));

      test('without declaration', () {
        // This should not happen in valid code, but test that we don't crash.
        var h = _Harness();
        var s =
            FlowModel<_Var, _Type>(true).write(objectQVar, _Type('Object?'), h);
        expect(s.variableInfo[objectQVar], isNull);
      });

      test('unchanged', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true).declare(objectQVar, true);
        var s2 = s1.write(objectQVar, _Type('Object?'), h);
        expect(s2, same(s1));
      });

      test('marks as assigned', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true).declare(objectQVar, false);
        var s2 = s1.write(objectQVar, _Type('int?'), h);
        expect(s2.reachable, true);
        expect(
            s2.infoFor(objectQVar),
            _matchVariableModel(
                chain: null,
                ofInterest: isEmpty,
                assigned: true,
                unassigned: false));
      });

      test('un-promotes fully', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .declare(objectQVar, true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue;
        expect(s1.variableInfo, contains(objectQVar));
        var s2 = s1.write(objectQVar, _Type('int?'), h);
        expect(s2.reachable, true);
        expect(s2.variableInfo, {
          objectQVar: _matchVariableModel(
              chain: null,
              ofInterest: isEmpty,
              assigned: true,
              unassigned: false)
        });
      });

      test('un-promotes partially, when no exact match', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .declare(objectQVar, true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num?'))
            .ifTrue
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue;
        expect(s1.variableInfo, {
          objectQVar: _matchVariableModel(
              chain: ['num?', 'int'],
              ofInterest: ['num?', 'int'],
              assigned: true,
              unassigned: false)
        });
        var s2 = s1.write(objectQVar, _Type('num'), h);
        expect(s2.reachable, true);
        expect(s2.variableInfo, {
          objectQVar: _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'int'],
              assigned: true,
              unassigned: false)
        });
      });

      test('un-promotes partially, when exact match', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .declare(objectQVar, true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num?'))
            .ifTrue
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num'))
            .ifTrue
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue;
        expect(s1.variableInfo, {
          objectQVar: _matchVariableModel(
              chain: ['num?', 'num', 'int'],
              ofInterest: ['num?', 'num', 'int'],
              assigned: true,
              unassigned: false)
        });
        var s2 = s1.write(objectQVar, _Type('num'), h);
        expect(s2.reachable, true);
        expect(s2.variableInfo, {
          objectQVar: _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'num', 'int'],
              assigned: true,
              unassigned: false)
        });
      });

      test('leaves promoted, when exact match', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .declare(objectQVar, true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num?'))
            .ifTrue
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num'))
            .ifTrue;
        expect(s1.variableInfo, {
          objectQVar: _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'num'],
              assigned: true,
              unassigned: false)
        });
        var s2 = s1.write(objectQVar, _Type('num'), h);
        expect(s2.reachable, true);
        expect(s2.variableInfo, same(s1.variableInfo));
      });

      test('leaves promoted, when writing a subtype', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .declare(objectQVar, true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num?'))
            .ifTrue
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num'))
            .ifTrue;
        expect(s1.variableInfo, {
          objectQVar: _matchVariableModel(
              chain: ['num?', 'num'],
              ofInterest: ['num?', 'num'],
              assigned: true,
              unassigned: false)
        });
        var s2 = s1.write(objectQVar, _Type('int'), h);
        expect(s2.reachable, true);
        expect(s2.variableInfo, same(s1.variableInfo));
      });

      group('Promotes to NonNull of a type of interest', () {
        test('when declared type', () {
          var h = _Harness();
          var x = _Var('x', _Type('int?'));

          var s1 = FlowModel<_Var, _Type>(true).declare(x, true);
          expect(s1.variableInfo, {
            x: _matchVariableModel(chain: null),
          });

          var s2 = s1.write(x, _Type('int'), h);
          expect(s2.variableInfo, {
            x: _matchVariableModel(chain: ['int']),
          });
        });

        test('when declared type, if write-captured', () {
          var h = _Harness();
          var x = h.addVar('x', 'int?');

          var s1 = FlowModel<_Var, _Type>(true).declare(x, true);
          expect(s1.variableInfo, {
            x: _matchVariableModel(chain: null),
          });

          var s2 = s1.conservativeJoin([], [x]);
          expect(s2.variableInfo, {
            x: _matchVariableModel(chain: null, writeCaptured: true),
          });

          // 'x' is write-captured, so not promoted
          var s3 = s2.write(x, _Type('int'), h);
          expect(s3.variableInfo, {
            x: _matchVariableModel(chain: null, writeCaptured: true),
          });
        });

        test('when promoted', () {
          var h = _Harness();
          var s1 = FlowModel<_Var, _Type>(true)
              .declare(objectQVar, true)
              .tryPromoteForTypeCheck(h, objectQVar, _Type('int?'))
              .ifTrue;
          expect(s1.variableInfo, {
            objectQVar: _matchVariableModel(
              chain: ['int?'],
              ofInterest: ['int?'],
            ),
          });
          var s2 = s1.write(objectQVar, _Type('int'), h);
          expect(s2.variableInfo, {
            objectQVar: _matchVariableModel(
              chain: ['int?', 'int'],
              ofInterest: ['int?'],
            ),
          });
        });

        test('when not promoted', () {
          var h = _Harness();
          var s1 = FlowModel<_Var, _Type>(true)
              .declare(objectQVar, true)
              .tryPromoteForTypeCheck(h, objectQVar, _Type('int?'))
              .ifFalse;
          expect(s1.variableInfo, {
            objectQVar: _matchVariableModel(
              chain: ['Object'],
              ofInterest: ['int?'],
            ),
          });
          var s2 = s1.write(objectQVar, _Type('int'), h);
          expect(s2.variableInfo, {
            objectQVar: _matchVariableModel(
              chain: ['Object', 'int'],
              ofInterest: ['int?'],
            ),
          });
        });
      });

      test('Promotes to type of interest when not previously promoted', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .declare(objectQVar, true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num?'))
            .ifFalse;
        expect(s1.variableInfo, {
          objectQVar: _matchVariableModel(
            chain: ['Object'],
            ofInterest: ['num?'],
          ),
        });
        var s2 = s1.write(objectQVar, _Type('num?'), h);
        expect(s2.variableInfo, {
          objectQVar: _matchVariableModel(
            chain: ['num?'],
            ofInterest: ['num?'],
          ),
        });
      });

      test('Promotes to type of interest when previously promoted', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .declare(objectQVar, true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('num?'))
            .ifTrue
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int?'))
            .ifFalse;
        expect(s1.variableInfo, {
          objectQVar: _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'int?'],
          ),
        });
        var s2 = s1.write(objectQVar, _Type('int?'), h);
        expect(s2.variableInfo, {
          objectQVar: _matchVariableModel(
            chain: ['num?', 'int?'],
            ofInterest: ['num?', 'int?'],
          ),
        });
      });

      group('Multiple candidate types of interest', () {
        group('; choose most specific', () {
          _Harness h;

          setUp(() {
            h = _Harness();

            // class A {}
            // class B extends A {}
            // class C extends B {}
            h.addSubtype(_Type('Object'), _Type('A'), false);
            h.addSubtype(_Type('Object'), _Type('A?'), false);
            h.addSubtype(_Type('Object'), _Type('B?'), false);
            h.addSubtype(_Type('A'), _Type('Object'), true);
            h.addSubtype(_Type('A'), _Type('Object?'), true);
            h.addSubtype(_Type('A'), _Type('A?'), true);
            h.addSubtype(_Type('A'), _Type('B'), false);
            h.addSubtype(_Type('A'), _Type('B?'), false);
            h.addSubtype(_Type('A?'), _Type('Object'), false);
            h.addSubtype(_Type('A?'), _Type('Object?'), true);
            h.addSubtype(_Type('A?'), _Type('A'), false);
            h.addSubtype(_Type('A?'), _Type('B?'), false);
            h.addSubtype(_Type('B'), _Type('Object'), true);
            h.addSubtype(_Type('B'), _Type('A'), true);
            h.addSubtype(_Type('B'), _Type('A?'), true);
            h.addSubtype(_Type('B'), _Type('B?'), true);
            h.addSubtype(_Type('B?'), _Type('Object'), false);
            h.addSubtype(_Type('B?'), _Type('Object?'), true);
            h.addSubtype(_Type('B?'), _Type('A'), false);
            h.addSubtype(_Type('B?'), _Type('A?'), true);
            h.addSubtype(_Type('B?'), _Type('B'), false);
            h.addSubtype(_Type('C'), _Type('Object'), true);
            h.addSubtype(_Type('C'), _Type('A'), true);
            h.addSubtype(_Type('C'), _Type('A?'), true);
            h.addSubtype(_Type('C'), _Type('B'), true);
            h.addSubtype(_Type('C'), _Type('B?'), true);

            h.addFactor(_Type('Object'), _Type('A?'), _Type('Object'));
            h.addFactor(_Type('Object'), _Type('B?'), _Type('Object'));
            h.addFactor(_Type('Object?'), _Type('A'), _Type('Object?'));
            h.addFactor(_Type('Object?'), _Type('A?'), _Type('Object'));
            h.addFactor(_Type('Object?'), _Type('B?'), _Type('Object'));
          });

          test('; first', () {
            var x = _Var('x', _Type('Object?'));

            var s1 = FlowModel<_Var, _Type>(true)
                .declare(x, true)
                .tryPromoteForTypeCheck(h, x, _Type('B?'))
                .ifFalse
                .tryPromoteForTypeCheck(h, x, _Type('A?'))
                .ifFalse;
            expect(s1.variableInfo, {
              x: _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A?', 'B?'],
              ),
            });

            var s2 = s1.write(x, _Type('C'), h);
            expect(s2.variableInfo, {
              x: _matchVariableModel(
                chain: ['Object', 'B'],
                ofInterest: ['A?', 'B?'],
              ),
            });
          });

          test('; second', () {
            var x = _Var('x', _Type('Object?'));

            var s1 = FlowModel<_Var, _Type>(true)
                .declare(x, true)
                .tryPromoteForTypeCheck(h, x, _Type('A?'))
                .ifFalse
                .tryPromoteForTypeCheck(h, x, _Type('B?'))
                .ifFalse;
            expect(s1.variableInfo, {
              x: _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A?', 'B?'],
              ),
            });

            var s2 = s1.write(x, _Type('C'), h);
            expect(s2.variableInfo, {
              x: _matchVariableModel(
                chain: ['Object', 'B'],
                ofInterest: ['A?', 'B?'],
              ),
            });
          });

          test('; nullable and non-nullable', () {
            var x = _Var('x', _Type('Object?'));

            var s1 = FlowModel<_Var, _Type>(true)
                .declare(x, true)
                .tryPromoteForTypeCheck(h, x, _Type('A'))
                .ifFalse
                .tryPromoteForTypeCheck(h, x, _Type('A?'))
                .ifFalse;
            expect(s1.variableInfo, {
              x: _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['A', 'A?'],
              ),
            });

            var s2 = s1.write(x, _Type('B'), h);
            expect(s2.variableInfo, {
              x: _matchVariableModel(
                chain: ['Object', 'A'],
                ofInterest: ['A', 'A?'],
              ),
            });
          });
        });

        group('; ambiguous', () {
          test('; no promotion', () {
            var h = _Harness();
            var s1 = FlowModel<_Var, _Type>(true)
                .declare(objectQVar, true)
                .tryPromoteForTypeCheck(h, objectQVar, _Type('num?'))
                .ifFalse
                .tryPromoteForTypeCheck(h, objectQVar, _Type('num*'))
                .ifFalse;
            expect(s1.variableInfo, {
              objectQVar: _matchVariableModel(
                chain: ['Object'],
                ofInterest: ['num?', 'num*'],
              ),
            });
            var s2 = s1.write(objectQVar, _Type('int'), h);
            // It's ambiguous whether to promote to num? or num*, so we don't
            // promote.
            expect(s2, same(s1));
          });
        });

        test('exact match', () {
          var h = _Harness();
          var s1 = FlowModel<_Var, _Type>(true)
              .declare(objectQVar, true)
              .tryPromoteForTypeCheck(h, objectQVar, _Type('num?'))
              .ifFalse
              .tryPromoteForTypeCheck(h, objectQVar, _Type('num*'))
              .ifFalse;
          expect(s1.variableInfo, {
            objectQVar: _matchVariableModel(
              chain: ['Object'],
              ofInterest: ['num?', 'num*'],
            ),
          });
          var s2 = s1.write(objectQVar, _Type('num?'), h);
          // It's ambiguous whether to promote to num? or num*, but since the
          // written type is exactly num?, we use that.
          expect(s2.variableInfo, {
            objectQVar: _matchVariableModel(
              chain: ['num?'],
              ofInterest: ['num?', 'num*'],
            ),
          });
        });
      });

      test('promote via initialization', () {
        var h = _Harness();
        var x = _Var('x', null, isLocalVariableWithoutDeclaredType: true);

        var s1 = FlowModel<_Var, _Type>(true).declare(x, false);
        expect(s1.variableInfo, {
          x: _matchVariableModel(chain: null),
        });

        var s2 = s1.write(x, _Type('int'), h);
        expect(s2.variableInfo, {
          x: _matchVariableModel(chain: ['int']),
        });
      });
    });

    group('demotion, to NonNull', () {
      test('when promoted via test', () {
        var x = _Var('x', _Type('Object?'));

        var h = _Harness();

        var s1 = FlowModel<_Var, _Type>(true)
            .declare(x, true)
            .tryPromoteForTypeCheck(h, x, _Type('num?'))
            .ifTrue
            .tryPromoteForTypeCheck(h, x, _Type('int?'))
            .ifTrue;
        expect(s1.variableInfo, {
          x: _matchVariableModel(
            chain: ['num?', 'int?'],
            ofInterest: ['num?', 'int?'],
          ),
        });

        var s2 = s1.write(x, _Type('double'), h);
        expect(s2.variableInfo, {
          x: _matchVariableModel(
            chain: ['num?', 'num'],
            ofInterest: ['num?', 'int?'],
          ),
        });
      });
    });

    group('declare', () {
      var objectQVar = _Var('x', _Type('Object?'));

      test('initialized', () {
        var s = FlowModel<_Var, _Type>(true).declare(objectQVar, true);
        expect(s.variableInfo, {
          objectQVar: _matchVariableModel(assigned: true, unassigned: false),
        });
      });

      test('not initialized', () {
        var s = FlowModel<_Var, _Type>(true).declare(objectQVar, false);
        expect(s.variableInfo, {
          objectQVar: _matchVariableModel(assigned: false, unassigned: true),
        });
      });
    });

    group('markNonNullable', () {
      test('unpromoted -> unchanged', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.tryMarkNonNullable(h, intVar).ifTrue;
        expect(s2, same(s1));
      });

      test('unpromoted -> promoted', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.tryMarkNonNullable(h, intQVar).ifTrue;
        expect(s2.reachable, true);
        expect(s2.infoFor(intQVar),
            _matchVariableModel(chain: ['int'], ofInterest: []));
      });

      test('promoted -> unchanged', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue;
        var s2 = s1.tryMarkNonNullable(h, objectQVar).ifTrue;
        expect(s2, same(s1));
      });

      test('promoted -> re-promoted', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int?'))
            .ifTrue;
        var s2 = s1.tryMarkNonNullable(h, objectQVar).ifTrue;
        expect(s2.reachable, true);
        expect(s2.variableInfo, {
          objectQVar:
              _matchVariableModel(chain: ['int?', 'int'], ofInterest: ['int?'])
        });
      });
    });

    group('joinUnassigned', () {
      group('other', () {
        test('unchanged', () {
          var h = _Harness();

          var a = _Var('a', _Type('int'));
          var b = _Var('b', _Type('int'));

          var s1 = FlowModel<_Var, _Type>(true)
              .declare(a, false)
              .declare(b, false)
              .write(a, _Type('int'), h);
          expect(s1.variableInfo, {
            a: _matchVariableModel(assigned: true, unassigned: false),
            b: _matchVariableModel(assigned: false, unassigned: true),
          });

          var s2 = s1.write(a, _Type('int'), h);
          expect(s2.variableInfo, {
            a: _matchVariableModel(assigned: true, unassigned: false),
            b: _matchVariableModel(assigned: false, unassigned: true),
          });

          var s3 = s1.joinUnassigned(s2);
          expect(s3, same(s1));
        });

        test('changed', () {
          var h = _Harness();

          var a = _Var('a', _Type('int'));
          var b = _Var('b', _Type('int'));
          var c = _Var('c', _Type('int'));

          var s1 = FlowModel<_Var, _Type>(true)
              .declare(a, false)
              .declare(b, false)
              .declare(c, false)
              .write(a, _Type('int'), h);
          expect(s1.variableInfo, {
            a: _matchVariableModel(assigned: true, unassigned: false),
            b: _matchVariableModel(assigned: false, unassigned: true),
            c: _matchVariableModel(assigned: false, unassigned: true),
          });

          var s2 = s1.write(b, _Type('int'), h);
          expect(s2.variableInfo, {
            a: _matchVariableModel(assigned: true, unassigned: false),
            b: _matchVariableModel(assigned: true, unassigned: false),
            c: _matchVariableModel(assigned: false, unassigned: true),
          });

          var s3 = s1.joinUnassigned(s2);
          expect(s3.variableInfo, {
            a: _matchVariableModel(assigned: true, unassigned: false),
            b: _matchVariableModel(assigned: false, unassigned: false),
            c: _matchVariableModel(assigned: false, unassigned: true),
          });
        });
      });
    });

    group('conservativeJoin', () {
      test('unchanged', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .declare(intQVar, true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue;
        var s2 = s1.conservativeJoin([intQVar], []);
        expect(s2, same(s1));
      });

      test('written', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue
            .tryPromoteForTypeCheck(h, intQVar, _Type('int'))
            .ifTrue;
        var s2 = s1.conservativeJoin([intQVar], []);
        expect(s2.reachable, true);
        expect(s2.variableInfo, {
          objectQVar: _matchVariableModel(chain: ['int'], ofInterest: ['int']),
          intQVar: _matchVariableModel(chain: null, ofInterest: ['int'])
        });
      });

      test('write captured', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .tryPromoteForTypeCheck(h, objectQVar, _Type('int'))
            .ifTrue
            .tryPromoteForTypeCheck(h, intQVar, _Type('int'))
            .ifTrue;
        var s2 = s1.conservativeJoin([], [intQVar]);
        expect(s2.reachable, true);
        expect(s2.variableInfo, {
          objectQVar: _matchVariableModel(chain: ['int'], ofInterest: ['int']),
          intQVar: _matchVariableModel(
              chain: null, ofInterest: isEmpty, unassigned: false)
        });
      });
    });

    group('restrict', () {
      test('reachability', () {
        var h = _Harness();
        var reachable = FlowModel<_Var, _Type>(true);
        var unreachable = reachable.setReachable(false);
        expect(reachable.restrict(h, reachable, Set()), same(reachable));
        expect(reachable.restrict(h, unreachable, Set()), same(unreachable));
        expect(unreachable.restrict(h, unreachable, Set()), same(unreachable));
        expect(unreachable.restrict(h, unreachable, Set()), same(unreachable));
      });

      test('assignments', () {
        var h = _Harness();
        var a = _Var('a', _Type('int'));
        var b = _Var('b', _Type('int'));
        var c = _Var('c', _Type('int'));
        var d = _Var('d', _Type('int'));
        var s0 = FlowModel<_Var, _Type>(true)
            .declare(a, false)
            .declare(b, false)
            .declare(c, false)
            .declare(d, false);
        var s1 = s0.write(a, _Type('int'), h).write(b, _Type('int'), h);
        var s2 = s1.write(a, _Type('int'), h).write(c, _Type('int'), h);
        var result = s2.restrict(h, s1, Set());
        expect(result.infoFor(a).assigned, true);
        expect(result.infoFor(b).assigned, true);
        expect(result.infoFor(c).assigned, true);
        expect(result.infoFor(d).assigned, false);
      });

      test('write captured', () {
        var h = _Harness();
        var a = _Var('a', _Type('int'));
        var b = _Var('b', _Type('int'));
        var c = _Var('c', _Type('int'));
        var d = _Var('d', _Type('int'));
        var s0 = FlowModel<_Var, _Type>(true)
            .declare(a, false)
            .declare(b, false)
            .declare(c, false)
            .declare(d, false);
        // In s1, a and b are write captured.  In s2, a and c are.
        var s1 = s0.conservativeJoin([a, b], [a, b]);
        var s2 = s1.conservativeJoin([a, c], [a, c]);
        var result = s2.restrict(h, s1, Set());
        expect(
          result.infoFor(a),
          _matchVariableModel(writeCaptured: true, unassigned: false),
        );
        expect(
          result.infoFor(b),
          _matchVariableModel(writeCaptured: true, unassigned: false),
        );
        expect(
          result.infoFor(c),
          _matchVariableModel(writeCaptured: true, unassigned: false),
        );
        expect(
          result.infoFor(d),
          _matchVariableModel(writeCaptured: false, unassigned: true),
        );
      });

      test('promotion', () {
        void _check(String thisType, String otherType, bool unsafe,
            List<String> expectedChain) {
          var h = _Harness();
          var x = _Var('x', _Type('Object?'));
          var s0 = FlowModel<_Var, _Type>(true).declare(x, true);
          var s1 = thisType == null
              ? s0
              : s0.tryPromoteForTypeCheck(h, x, _Type(thisType)).ifTrue;
          var s2 = otherType == null
              ? s0
              : s0.tryPromoteForTypeCheck(h, x, _Type(otherType)).ifTrue;
          var result = s1.restrict(h, s2, unsafe ? [x].toSet() : Set());
          if (expectedChain == null) {
            expect(result.variableInfo, contains(x));
            expect(result.infoFor(x).promotedTypes, isNull);
          } else {
            expect(result.infoFor(x).promotedTypes.map((t) => t.type).toList(),
                expectedChain);
          }
        }

        _check(null, null, false, null);
        _check(null, null, true, null);
        _check('int', null, false, ['int']);
        _check('int', null, true, ['int']);
        _check(null, 'int', false, ['int']);
        _check(null, 'int', true, null);
        _check('int?', 'int', false, ['int']);
        _check('int', 'int?', false, ['int?', 'int']);
        _check('int', 'String', false, ['String']);
        _check('int?', 'int', true, ['int?']);
        _check('int', 'int?', true, ['int']);
        _check('int', 'String', true, ['int']);
      });

      test('promotion chains', () {
        // Verify that the given promotion chain matches the expected list of
        // strings.
        void _checkChain(List<_Type> chain, List<String> expected) {
          var strings = (chain ?? <_Type>[]).map((t) => t.type).toList();
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
          var h = _Harness();
          var x = _Var('x', _Type('Object?'));
          var initialModel = FlowModel<_Var, _Type>(true).declare(x, true);
          for (var t in before) {
            initialModel =
                initialModel.tryPromoteForTypeCheck(h, x, _Type(t)).ifTrue;
          }
          _checkChain(initialModel.infoFor(x).promotedTypes, before);
          var tryModel = initialModel;
          for (var t in inTry) {
            tryModel = tryModel.tryPromoteForTypeCheck(h, x, _Type(t)).ifTrue;
          }
          var expectedTryChain = before.toList()..addAll(inTry);
          _checkChain(tryModel.infoFor(x).promotedTypes, expectedTryChain);
          var finallyModel = initialModel;
          for (var t in inFinally) {
            finallyModel =
                finallyModel.tryPromoteForTypeCheck(h, x, _Type(t)).ifTrue;
          }
          var expectedFinallyChain = before.toList()..addAll(inFinally);
          _checkChain(
              finallyModel.infoFor(x).promotedTypes, expectedFinallyChain);
          var result = finallyModel.restrict(h, tryModel, {});
          _checkChain(result.infoFor(x).promotedTypes, expectedResult);
          // And verify that the inputs are unchanged.
          _checkChain(initialModel.infoFor(x).promotedTypes, before);
          _checkChain(tryModel.infoFor(x).promotedTypes, expectedTryChain);
          _checkChain(
              finallyModel.infoFor(x).promotedTypes, expectedFinallyChain);
        }

        _check(['Object'], ['Iterable', 'List'], ['num', 'int'],
            ['Object', 'Iterable', 'List']);
        _check([], ['Iterable', 'List'], ['num', 'int'], ['Iterable', 'List']);
        _check(['Object'], ['Iterable', 'List'], [],
            ['Object', 'Iterable', 'List']);
        _check([], ['Iterable', 'List'], [], ['Iterable', 'List']);
        _check(['Object'], [], ['num', 'int'], ['Object', 'num', 'int']);
        _check([], [], ['num', 'int'], ['num', 'int']);
        _check(['Object'], [], [], ['Object']);
        _check([], [], [], []);
        _check(
            [], ['Object', 'Iterable'], ['num', 'int'], ['Object', 'Iterable']);
        _check([], ['Object'], ['num', 'int'], ['Object', 'num', 'int']);
        _check([], ['num', 'int'], ['Object', 'Iterable'], ['num', 'int']);
        _check([], ['num', 'int'], ['Object'], ['num', 'int']);
        _check([], ['Object', 'int'], ['num'], ['Object', 'int']);
        _check([], ['Object', 'num'], ['int'], ['Object', 'num', 'int']);
        _check([], ['num'], ['Object', 'int'], ['num', 'int']);
        _check([], ['int'], ['Object', 'num'], ['int']);
      });

      test('variable present in one state but not the other', () {
        var h = _Harness();
        var x = _Var('x', _Type('Object?'));
        var s0 = FlowModel<_Var, _Type>(true);
        var s1 = s0.declare(x, true);
        expect(s0.restrict(h, s1, {}), same(s0));
        expect(s0.restrict(h, s1, {x}), same(s0));
        expect(s1.restrict(h, s0, {}), same(s0));
        expect(s1.restrict(h, s0, {x}), same(s0));
      });
    });
  });

  group('joinPromotionChains', () {
    var doubleType = _Type('double');
    var intType = _Type('int');
    var numType = _Type('num');
    var objectType = _Type('Object');

    test('should handle nulls', () {
      var h = _Harness();
      expect(VariableModel.joinPromotedTypes(null, null, h), null);
      expect(VariableModel.joinPromotedTypes(null, [intType], h), null);
      expect(VariableModel.joinPromotedTypes([intType], null, h), null);
    });

    test('should return null if there are no common types', () {
      var h = _Harness();
      expect(VariableModel.joinPromotedTypes([intType], [doubleType], h), null);
    });

    test('should return common prefix if there are common types', () {
      var h = _Harness();
      expect(
          VariableModel.joinPromotedTypes(
              [objectType, intType], [objectType, doubleType], h),
          _matchPromotionChain(['Object']));
      expect(
          VariableModel.joinPromotedTypes([objectType, numType, intType],
              [objectType, numType, doubleType], h),
          _matchPromotionChain(['Object', 'num']));
    });

    test('should return an input if it is a prefix of the other', () {
      var h = _Harness();
      var prefix = [objectType, numType];
      var largerChain = [objectType, numType, intType];
      expect(VariableModel.joinPromotedTypes(prefix, largerChain, h),
          same(prefix));
      expect(VariableModel.joinPromotedTypes(largerChain, prefix, h),
          same(prefix));
      expect(VariableModel.joinPromotedTypes(prefix, prefix, h), same(prefix));
    });

    test('should intersect', () {
      var h = _Harness();

      // F <: E <: D <: C <: B <: A
      var A = _Type('A');
      var B = _Type('B');
      var C = _Type('C');
      var D = _Type('D');
      var E = _Type('E');
      var F = _Type('F');
      h.addSubtype(A, B, false);
      h.addSubtype(B, A, true);
      h.addSubtype(B, C, false);
      h.addSubtype(B, D, false);
      h.addSubtype(C, B, true);
      h.addSubtype(C, D, false);
      h.addSubtype(C, E, false);
      h.addSubtype(D, B, true);
      h.addSubtype(D, C, true);
      h.addSubtype(D, E, false);
      h.addSubtype(D, F, false);
      h.addSubtype(E, C, true);
      h.addSubtype(E, D, true);
      h.addSubtype(E, F, false);
      h.addSubtype(F, D, true);
      h.addSubtype(F, E, true);

      void check(List<_Type> chain1, List<_Type> chain2, Matcher matcher) {
        expect(
          VariableModel.joinPromotedTypes(chain1, chain2, h),
          matcher,
        );

        expect(
          VariableModel.joinPromotedTypes(chain2, chain1, h),
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
    List<_Type> _makeTypes(List<String> typeNames) =>
        typeNames.map((t) => _Type(t)).toList();

    test('simple prefix', () {
      var h = _Harness();
      var s1 = _makeTypes(['double', 'int']);
      var s2 = _makeTypes(['double', 'int', 'bool']);
      var expected = _matchOfInterestSet(['double', 'int', 'bool']);
      expect(VariableModel.joinTested(s1, s2, h), expected);
      expect(VariableModel.joinTested(s2, s1, h), expected);
    });

    test('common prefix', () {
      var h = _Harness();
      var s1 = _makeTypes(['double', 'int', 'String']);
      var s2 = _makeTypes(['double', 'int', 'bool']);
      var expected = _matchOfInterestSet(['double', 'int', 'String', 'bool']);
      expect(VariableModel.joinTested(s1, s2, h), expected);
      expect(VariableModel.joinTested(s2, s1, h), expected);
    });

    test('order mismatch', () {
      var h = _Harness();
      var s1 = _makeTypes(['double', 'int']);
      var s2 = _makeTypes(['int', 'double']);
      var expected = _matchOfInterestSet(['double', 'int']);
      expect(VariableModel.joinTested(s1, s2, h), expected);
      expect(VariableModel.joinTested(s2, s1, h), expected);
    });

    test('small common prefix', () {
      var h = _Harness();
      var s1 = _makeTypes(['int', 'double', 'String', 'bool']);
      var s2 = _makeTypes(['int', 'List', 'bool', 'Future']);
      var expected = _matchOfInterestSet(
          ['int', 'double', 'String', 'bool', 'List', 'Future']);
      expect(VariableModel.joinTested(s1, s2, h), expected);
      expect(VariableModel.joinTested(s2, s1, h), expected);
    });
  });

  group('join', () {
    var x = _Var('x', _Type('Object?'));
    var y = _Var('y', _Type('Object?'));
    var z = _Var('z', _Type('Object?'));
    var w = _Var('w', _Type('Object?'));
    var intType = _Type('int');
    var intQType = _Type('int?');
    var stringType = _Type('String');
    const emptyMap = const <_Var, VariableModel<_Var, _Type>>{};

    VariableModel<_Var, _Type> model(List<_Type> promotionChain,
            {List<_Type> typesOfInterest, bool assigned = false}) =>
        VariableModel<_Var, _Type>(
          promotionChain,
          typesOfInterest ?? promotionChain ?? [],
          assigned,
          !assigned,
          false,
        );

    group('without input reuse', () {
      test('promoted with unpromoted', () {
        var h = _Harness();
        var p1 = {
          x: model([intType]),
          y: model(null)
        };
        var p2 = {
          x: model(null),
          y: model([intType])
        };
        expect(FlowModel.joinVariableInfo(h, p1, p2, emptyMap), {
          x: _matchVariableModel(chain: null, ofInterest: ['int']),
          y: _matchVariableModel(chain: null, ofInterest: ['int'])
        });
      });
    });
    group('should re-use an input if possible', () {
      test('identical inputs', () {
        var h = _Harness();
        var p = {
          x: model([intType]),
          y: model([stringType])
        };
        expect(FlowModel.joinVariableInfo(h, p, p, emptyMap), same(p));
      });

      test('one input empty', () {
        var h = _Harness();
        var p1 = {
          x: model([intType]),
          y: model([stringType])
        };
        var p2 = <_Var, VariableModel<_Var, _Type>>{};
        expect(FlowModel.joinVariableInfo(h, p1, p2, emptyMap), same(emptyMap));
        expect(FlowModel.joinVariableInfo(h, p2, p1, emptyMap), same(emptyMap));
      });

      test('promoted with unpromoted', () {
        var h = _Harness();
        var p1 = {
          x: model([intType])
        };
        var p2 = {x: model(null)};
        var expected = {
          x: _matchVariableModel(chain: null, ofInterest: ['int'])
        };
        expect(FlowModel.joinVariableInfo(h, p1, p2, emptyMap), expected);
        expect(FlowModel.joinVariableInfo(h, p2, p1, emptyMap), expected);
      });

      test('related type chains', () {
        var h = _Harness();
        var p1 = {
          x: model([intQType, intType])
        };
        var p2 = {
          x: model([intQType])
        };
        var expected = {
          x: _matchVariableModel(chain: ['int?'], ofInterest: ['int?', 'int'])
        };
        expect(FlowModel.joinVariableInfo(h, p1, p2, emptyMap), expected);
        expect(FlowModel.joinVariableInfo(h, p2, p1, emptyMap), expected);
      });

      test('unrelated type chains', () {
        var h = _Harness();
        var p1 = {
          x: model([intType])
        };
        var p2 = {
          x: model([stringType])
        };
        var expected = {
          x: _matchVariableModel(chain: null, ofInterest: ['String', 'int'])
        };
        expect(FlowModel.joinVariableInfo(h, p1, p2, emptyMap), expected);
        expect(FlowModel.joinVariableInfo(h, p2, p1, emptyMap), expected);
      });

      test('sub-map', () {
        var h = _Harness();
        var xModel = model([intType]);
        var p1 = {
          x: xModel,
          y: model([stringType])
        };
        var p2 = {x: xModel};
        expect(FlowModel.joinVariableInfo(h, p1, p2, emptyMap), same(p2));
        expect(FlowModel.joinVariableInfo(h, p2, p1, emptyMap), same(p2));
      });

      test('sub-map with matched subtype', () {
        var h = _Harness();
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
        expect(FlowModel.joinVariableInfo(h, p1, p2, emptyMap), expected);
        expect(FlowModel.joinVariableInfo(h, p2, p1, emptyMap), expected);
      });

      test('sub-map with mismatched subtype', () {
        var h = _Harness();
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
        expect(FlowModel.joinVariableInfo(h, p1, p2, emptyMap), expected);
        expect(FlowModel.joinVariableInfo(h, p2, p1, emptyMap), expected);
      });

      test('assigned', () {
        var h = _Harness();
        var unassigned = model(null, assigned: false);
        var assigned = model(null, assigned: true);
        var p1 = {x: assigned, y: assigned, z: unassigned, w: unassigned};
        var p2 = {x: assigned, y: unassigned, z: assigned, w: unassigned};
        var joined = FlowModel.joinVariableInfo(h, p1, p2, emptyMap);
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
        var h = _Harness();
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
        var joined = FlowModel.joinVariableInfo(h, p1, p2, emptyMap);
        expect(joined, {
          x: same(writeCapturedModel),
          y: same(writeCapturedModel),
          z: same(writeCapturedModel),
          w: same(intQModel)
        });
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
      (List<_Type> x) => unorderedEquals(expectedTypes)
          .matches(x.map((t) => t.type).toList(), {}),
      'interest set $expectedTypes');
}

Matcher _matchPromotionChain(List<String> expectedTypes) {
  if (expectedTypes == null) return isNull;
  return predicate(
      (List<_Type> x) =>
          equals(expectedTypes).matches(x.map((t) => t.type).toList(), {}),
      'promotion chain $expectedTypes');
}

Matcher _matchVariableModel(
    {Object chain = anything,
    Object ofInterest = anything,
    Object assigned = anything,
    Object unassigned = anything,
    Object writeCaptured = anything}) {
  Matcher chainMatcher =
      chain is List<String> ? _matchPromotionChain(chain) : wrapMatcher(chain);
  Matcher ofInterestMatcher = ofInterest is List<String>
      ? _matchOfInterestSet(ofInterest)
      : wrapMatcher(ofInterest);
  Matcher assignedMatcher = wrapMatcher(assigned);
  Matcher unassignedMatcher = wrapMatcher(unassigned);
  Matcher writeCapturedMatcher = wrapMatcher(writeCaptured);
  return predicate((VariableModel<_Var, _Type> model) {
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

/// Representation of an expression to be visited by the test harness.  Calling
/// the function causes the expression to be "visited" (in other words, the
/// appropriate methods in [FlowAnalysis] are called in the appropriate order),
/// and the [_Expression] object representing the whole expression is returned.
///
/// This is used by methods in [_Harness] as a lightweight way of building up
/// complex sequences of calls to [FlowAnalysis] that represent large
/// expressions.
typedef _Expression LazyExpression();

class _AssignedVariablesHarness {
  final AssignedVariables<_Node, _Var> _assignedVariables;

  _AssignedVariablesHarness(this._assignedVariables);

  void function(_Node node, void Function() callback) {
    _assignedVariables.beginNode();
    callback();
    _assignedVariables.endNode(node, isClosure: true);
  }

  void nest(_Node node, void Function() callback) {
    _assignedVariables.beginNode();
    callback();
    _assignedVariables.endNode(node);
  }

  void write(_Var v) {
    _assignedVariables.write(v);
  }
}

class _Expression {
  static int _idCounter = 0;

  final int _id = _idCounter++;

  @override
  String toString() => 'E$_id';
}

class _Harness extends TypeOperations<_Var, _Type> {
  static const Map<String, bool> _coreSubtypes = const {
    'double <: Object': true,
    'double <: num': true,
    'double <: num?': true,
    'double <: int': false,
    'double <: int?': false,
    'int <: double': false,
    'int <: int?': true,
    'int <: Iterable': false,
    'int <: List': false,
    'int <: num': true,
    'int <: num?': true,
    'int <: num*': true,
    'int <: Never?': false,
    'int <: Object': true,
    'int <: Object?': true,
    'int <: String': false,
    'int? <: int': false,
    'int? <: num': false,
    'int? <: num?': true,
    'int? <: Object': false,
    'int? <: Object?': true,
    'num <: int': false,
    'num <: Iterable': false,
    'num <: List': false,
    'num <: num?': true,
    'num <: num*': true,
    'num <: Object': true,
    'num <: Object?': true,
    'num? <: int?': false,
    'num? <: num': false,
    'num? <: num*': true,
    'num? <: Object': false,
    'num? <: Object?': true,
    'num* <: num': true,
    'num* <: num?': true,
    'num* <: Object': true,
    'num* <: Object?': true,
    'Iterable <: int': false,
    'Iterable <: num': false,
    'Iterable <: Object': true,
    'Iterable <: Object?': true,
    'List <: int': false,
    'List <: Iterable': true,
    'List <: Object': true,
    'Never <: int': true,
    'Never <: int?': true,
    'Never? <: int': false,
    'Never? <: int?': true,
    'Never? <: num?': true,
    'Never? <: Object?': true,
    'Object <: int': false,
    'Object <: int?': false,
    'Object <: List': false,
    'Object <: num': false,
    'Object <: num?': false,
    'Object <: Object?': true,
    'Object? <: Object': false,
    'Object? <: int': false,
    'Object? <: int?': false,
    'String <: int': false,
    'String <: int?': false,
    'String <: num?': false,
    'String <: Object?': true,
  };

  static final Map<String, _Type> _coreFactors = {
    'Object? - int': _Type('Object?'),
    'Object? - int?': _Type('Object'),
    'Object? - num?': _Type('Object'),
    'Object? - Object?': _Type('Never?'),
    'Object? - String': _Type('Object?'),
    'Object - int': _Type('Object'),
    'int - Object': _Type('Never'),
    'int - String': _Type('int'),
    'int - int': _Type('Never'),
    'int - int?': _Type('Never'),
    'int? - int': _Type('Never?'),
    'int? - int?': _Type('Never'),
    'int? - String': _Type('int?'),
    'num - int': _Type('num'),
    'num? - num': _Type('Never?'),
    'num? - int': _Type('num?'),
    'num? - int?': _Type('num'),
    'num? - Object': _Type('Never?'),
    'num? - String': _Type('num?'),
    'Object - int?': _Type('Object'),
    'Object - num': _Type('Object'),
    'Object - num?': _Type('Object'),
    'Object - num*': _Type('Object'),
    'Object - Iterable': _Type('Object'),
    'Object? - Object': _Type('Never?'),
    'Object? - Iterable': _Type('Object?'),
    'Object? - num': _Type('Object?'),
    'Iterable - List': _Type('Iterable'),
    'num* - Object': _Type('Never'),
  };

  final Map<String, bool> _subtypes = Map.of(_coreSubtypes);

  final Map<String, _Type> _factorResults = Map.of(_coreFactors);

  FlowAnalysis<_Node, _Statement, _Expression, _Var, _Type> _flow;

  final _assignedVariables = AssignedVariables<_Node, _Var>();

  /// Returns a [LazyExpression] representing an expression with now special
  /// flow analysis semantics.
  LazyExpression get expr => () => _Expression();

  LazyExpression get nullLiteral => () {
        var expr = _Expression();
        _flow.nullLiteral(expr);
        return expr;
      };

  void addFactor(_Type from, _Type what, _Type result) {
    var query = '$from - $what';
    _factorResults[query] = result;
  }

  void addSubtype(_Type leftType, _Type rightType, bool isSubtype) {
    var query = '$leftType <: $rightType';
    _subtypes[query] = isSubtype;
  }

  _Var addVar(String name, String type) {
    assert(_flow == null);
    return _Var(name, _Type(type));
  }

  /// Given two [LazyExpression]s, produces a new [LazyExpression] representing
  /// the result of combining them with `&&`.
  LazyExpression and(LazyExpression lhs, LazyExpression rhs) {
    return () {
      var expr = _Expression();
      _flow.logicalBinaryOp_rightBegin(lhs(), isAnd: true);
      _flow.logicalBinaryOp_end(expr, rhs(), isAnd: true);
      return expr;
    };
  }

  void assignedVariables(void Function(_AssignedVariablesHarness) callback) {
    callback(_AssignedVariablesHarness(_assignedVariables));
  }

  /// Given three [LazyExpression]s, produces a new [LazyExpression]
  /// representing the result of combining them with `?` and `:`.
  LazyExpression conditional(
      LazyExpression cond, LazyExpression ifTrue, LazyExpression ifFalse) {
    return () {
      var expr = _Expression();
      _flow.conditional_thenBegin(cond());
      _flow.conditional_elseBegin(ifTrue());
      _flow.conditional_end(expr, ifFalse());
      return expr;
    };
  }

  FlowAnalysis<_Node, _Statement, _Expression, _Var, _Type> createFlow() =>
      FlowAnalysis<_Node, _Statement, _Expression, _Var, _Type>(
          this, _assignedVariables);

  void declare(_Var v, {@required bool initialized}) {
    _flow.declare(v, initialized);
  }

  /// Creates a [LazyExpression] representing an `== null` check performed on
  /// [variable].
  LazyExpression eqNull(_Var variable) {
    return () {
      var varExpr = _Expression();
      _flow.variableRead(varExpr, variable);
      _flow.equalityOp_rightBegin(varExpr);
      var nullExpr = _Expression();
      _flow.nullLiteral(nullExpr);
      var expr = _Expression();
      _flow.equalityOp_end(expr, nullExpr, notEqual: false);
      return expr;
    };
  }

  @override
  _Type factor(_Type from, _Type what) {
    var query = '$from - $what';
    return _factorResults[query] ?? fail('Unknown factor query: $query');
  }

  /// Invokes flow analysis of a nested function.
  void function(_Node node, void body()) {
    _flow.functionExpression_begin(node);
    body();
    _flow.functionExpression_end();
  }

  /// Invokes flow analysis of an `if` statement with no `else` part.
  void if_(LazyExpression cond, void ifTrue()) {
    _flow.ifStatement_thenBegin(cond());
    ifTrue();
    _flow.ifStatement_end(false);
  }

  /// Invokes flow analysis of an `if` statement with an `else` part.
  void ifElse(LazyExpression cond, void ifTrue(), void ifFalse()) {
    _flow.ifStatement_thenBegin(cond());
    ifTrue();
    _flow.ifStatement_elseBegin();
    ifFalse();
    _flow.ifStatement_end(true);
  }

  /// Equivalent for `if (variable is! type) { ifTrue; }`
  void ifIsNotType(_Var variable, String type, void ifTrue()) {
    if_(isNotType(variableRead(variable), type), ifTrue);
  }

  @override
  bool isLocalVariableWithoutDeclaredType(_Var variable) {
    return variable.isLocalVariableWithoutDeclaredType;
  }

  /// Creates a [LazyExpression] representing an `is!` check, checking whether
  /// [subExpression] has the given [type].
  LazyExpression isNotType(LazyExpression subExpression, String type) {
    return () {
      var expr = _Expression();
      _flow.isExpression_end(expr, subExpression(), true, _Type(type));
      return expr;
    };
  }

  @override
  bool isSameType(_Type type1, _Type type2) {
    return type1.type == type2.type;
  }

  @override
  bool isSubtypeOf(_Type leftType, _Type rightType) {
    if (leftType.type == rightType.type) return true;
    var query = '$leftType <: $rightType';
    return _subtypes[query] ?? fail('Unknown subtype query: $query');
  }

  /// Creates a [LazyExpression] representing an `is` check, checking whether
  /// [subExpression] has the given [type].
  LazyExpression isType(LazyExpression subExpression, String type) {
    return () {
      var expr = _Expression();
      _flow.isExpression_end(expr, subExpression(), false, _Type(type));
      return expr;
    };
  }

  /// Invokes flow analysis of a labeled block.
  void labeledBlock(_Statement node, void body()) {
    _flow.labeledStatement_begin(node);
    body();
    _flow.labeledStatement_end();
  }

  /// Creates a [LazyExpression] representing an equality check between two
  /// other expressions.
  LazyExpression notEqual(LazyExpression lhs, LazyExpression rhs) {
    return () {
      var expr = _Expression();
      _flow.equalityOp_rightBegin(lhs());
      _flow.equalityOp_end(expr, rhs(), notEqual: true);
      return expr;
    };
  }

  /// Creates a [LazyExpression] representing a `!= null` check performed on
  /// [variable].
  LazyExpression notNull(_Var variable) {
    return () {
      var varExpr = _Expression();
      _flow.variableRead(varExpr, variable);
      _flow.equalityOp_rightBegin(varExpr);
      var nullExpr = _Expression();
      _flow.nullLiteral(nullExpr);
      var expr = _Expression();
      _flow.equalityOp_end(expr, nullExpr, notEqual: true);
      return expr;
    };
  }

  /// Given two [LazyExpression]s, produces a new [LazyExpression] representing
  /// the result of combining them with `||`.
  LazyExpression or(LazyExpression lhs, LazyExpression rhs) {
    return () {
      var expr = _Expression();
      _flow.logicalBinaryOp_rightBegin(lhs(), isAnd: false);
      _flow.logicalBinaryOp_end(expr, rhs(), isAnd: false);
      return expr;
    };
  }

  /// Creates a [LazyExpression] representing a parenthesized subexpression.
  LazyExpression parenthesized(LazyExpression inner) {
    return () {
      var expr = _Expression();
      _flow.parenthesizedExpression(expr, inner());
      return expr;
    };
  }

  /// Causes [variable] to be promoted to [type].
  void promote(_Var variable, String type) {
    ifIsNotType(variable, type, _flow.handleExit);
  }

  @override
  _Type promoteToNonNull(_Type type) {
    if (type.type.endsWith('?')) {
      return _Type(type.type.substring(0, type.type.length - 1));
    } else {
      return type;
    }
  }

  void run(
      void callback(
          FlowAnalysis<_Node, _Statement, _Expression, _Var, _Type> flow)) {
    assert(_flow == null);
    _flow = createFlow();
    callback(_flow);
    _flow.finish();
  }

  @override
  _Type tryPromoteToType(_Type to, _Type from) {
    if (isSubtypeOf(to, from)) {
      return to;
    } else {
      return null;
    }
  }

  LazyExpression variableRead(_Var variable) {
    return () {
      var expr = _Expression();
      _flow.variableRead(expr, variable);
      return expr;
    };
  }

  @override
  _Type variableType(_Var variable) {
    return variable.type;
  }
}

class _Node {}

class _Statement extends _Node {}

class _Type {
  final String type;

  _Type(this.type);

  @override
  bool operator ==(Object other) {
    // The flow analysis engine should not compare types using operator==.  It
    // should compare them using TypeOperations.
    fail('Unexpected use of operator== on types');
  }

  @override
  String toString() => type;
}

class _Var {
  final String name;
  final _Type type;
  final bool isLocalVariableWithoutDeclaredType;

  _Var(
    this.name,
    this.type, {
    this.isLocalVariableWithoutDeclaredType = false,
  });

  @override
  String toString() => '$type $name';
}
