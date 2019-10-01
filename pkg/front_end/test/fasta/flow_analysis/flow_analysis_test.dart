// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/flow_analysis/flow_analysis.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

main() {
  group('API', () {
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

    test('conditionEqNull(notEqual: true) promotes true branch', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var expr = _Expression();
        flow.conditionEqNull(expr, x, notEqual: true);
        flow.ifStatement_thenBegin(expr);
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_elseBegin();
        expect(flow.promotedType(x), isNull);
        flow.ifStatement_end(true);
      });
    });

    test('conditionEqNull(notEqual: false) promotes false branch', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var expr = _Expression();
        flow.conditionEqNull(expr, x, notEqual: false);
        flow.ifStatement_thenBegin(expr);
        expect(flow.promotedType(x), isNull);
        flow.ifStatement_elseBegin();
        expect(flow.promotedType(x).type, 'int');
        flow.ifStatement_end(true);
      });
    });

    test('doStatement_bodyBegin() un-promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.doStatement_bodyBegin(_Statement(), {x});
        expect(flow.promotedType(x), isNull);
        flow.doStatement_conditionBegin();
        flow.doStatement_end(_Expression());
      });
    });

    test('doStatement_conditionBegin() joins continue state', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var stmt = _Statement();
        flow.doStatement_bodyBegin(stmt, {});
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
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.doStatement_bodyBegin(_Statement(), {});
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.for_conditionBegin({x});
        expect(flow.promotedType(x), isNull);
        flow.for_bodyBegin(_Statement(), _Expression());
        flow.for_updaterBegin();
        flow.for_end();
      });
    });

    test('for_conditionBegin() handles not-yet-seen variables', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      h.run((flow) {
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.for_conditionBegin({x});
        flow.write(x);
        flow.for_bodyBegin(_Statement(), _Expression());
        flow.for_updaterBegin();
        flow.for_end();
      });
    });

    test('for_bodyBegin() handles empty condition', () {
      var h = _Harness();
      h.run((flow) {
        flow.for_conditionBegin({});
        flow.for_bodyBegin(_Statement(), null);
        flow.for_updaterBegin();
        expect(flow.isReachable, isTrue);
        flow.for_end();
        expect(flow.isReachable, isFalse);
      });
    });

    test('for_bodyBegin() promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.for_conditionBegin({});
        flow.for_bodyBegin(_Statement(), h.notNull(x)());
        expect(flow.promotedType(x).type, 'int');
        flow.for_updaterBegin();
        flow.for_end();
      });
    });

    test('for_bodyBegin() can be used with a null statement', () {
      // This is needed for collection elements that are for-loops.
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.for_conditionBegin({});
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        var stmt = _Statement();
        flow.for_conditionBegin({});
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        var stmt = _Statement();
        flow.for_conditionBegin({});
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.forEach_bodyBegin({x}, null);
        expect(flow.promotedType(x), isNull);
        flow.forEach_end();
      });
    });

    test('forEach_bodyBegin() writes to loop variable', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: false);
        expect(flow.isAssigned(x), false);
        flow.forEach_bodyBegin({x}, x);
        expect(flow.isAssigned(x), true);
        flow.forEach_end();
        expect(flow.isAssigned(x), false);
      });
    });

    test('forEach_end() restores state before loop', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.forEach_bodyBegin({}, null);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.forEach_end();
        expect(flow.promotedType(x), isNull);
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

    void _checkIs(String declaredType, String tryPromoteType,
        String expectedPromotedType) {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        var expr = _Expression();
        flow.isExpression_end(expr, x, false, _Type(tryPromoteType));
        flow.ifStatement_thenBegin(expr);
        if (expectedPromotedType == null) {
          expect(flow.promotedType(x), isNull);
        } else {
          expect(flow.promotedType(x).type, expectedPromotedType);
        }
        flow.ifStatement_elseBegin();
        expect(flow.promotedType(x), isNull);
        flow.ifStatement_end(true);
      });
    }

    test('isExpression_end promotes to a subtype', () {
      _checkIs('int?', 'int', 'int');
    });

    test('isExpression_end does not promote to a supertype', () {
      _checkIs('int', 'int?', null);
    });

    test('isExpression_end does not promote to an unrelated type', () {
      _checkIs('int', 'String', null);
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        flow.switchStatement_expressionEnd(_Statement());
        flow.switchStatement_beginCase(false, {x});
        expect(flow.promotedType(x).type, 'int');
        flow.write(x);
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_beginCase(false, {x});
        expect(flow.promotedType(x).type, 'int');
        flow.write(x);
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_end(false);
      });
    });

    test('switchStatement_beginCase(false) does not un-promote', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        flow.switchStatement_expressionEnd(_Statement());
        flow.switchStatement_beginCase(false, {x});
        expect(flow.promotedType(x).type, 'int');
        flow.write(x);
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_end(false);
      });
    });

    test('switchStatement_beginCase(true) un-promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        flow.switchStatement_expressionEnd(_Statement());
        flow.switchStatement_beginCase(true, {x});
        expect(flow.promotedType(x), isNull);
        flow.write(x);
        expect(flow.promotedType(x), isNull);
        flow.switchStatement_end(false);
      });
    });

    test('switchStatement_end(false) joins break and default', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      var z = h.addVar('z', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        h.promote(y, 'int');
        h.promote(z, 'int');
        var stmt = _Statement();
        flow.switchStatement_expressionEnd(stmt);
        flow.switchStatement_beginCase(false, {y});
        h.promote(x, 'int');
        flow.write(y);
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
        flow.switchStatement_beginCase(false, {x, y});
        h.promote(w, 'int');
        h.promote(y, 'int');
        flow.write(x);
        flow.handleBreak(stmt);
        flow.switchStatement_beginCase(false, {x, y});
        h.promote(w, 'int');
        h.promote(x, 'int');
        flow.write(y);
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
      h.run((flow) {
        h.declare(x, initialized: true);
        var stmt = _Statement();
        flow.switchStatement_expressionEnd(stmt);
        flow.switchStatement_beginCase(false, {});
        h.promote(x, 'int');
        flow.handleBreak(stmt);
        flow.switchStatement_beginCase(false, {});
        flow.switchStatement_end(true);
        expect(flow.promotedType(x), isNull);
      });
    });

    test('tryCatchStatement_bodyEnd() restores pre-try state', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.tryCatchStatement_bodyBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.tryCatchStatement_bodyEnd({});
        flow.tryCatchStatement_catchBegin();
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryCatchStatement_bodyBegin();
        flow.write(x);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryCatchStatement_bodyEnd({x});
        flow.tryCatchStatement_catchBegin();
        expect(flow.promotedType(x), isNull);
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_end();
      });
    });

    test('tryCatchStatement_catchBegin() restores previous post-body state',
        () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.tryCatchStatement_bodyBegin();
        flow.tryCatchStatement_bodyEnd({});
        flow.tryCatchStatement_catchBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_catchBegin();
        expect(flow.promotedType(x), isNull);
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        flow.tryCatchStatement_bodyBegin();
        h.promote(x, 'int');
        h.promote(y, 'int');
        flow.tryCatchStatement_bodyEnd({});
        flow.tryCatchStatement_catchBegin();
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        flow.tryCatchStatement_bodyBegin();
        flow.handleExit();
        flow.tryCatchStatement_bodyEnd({});
        flow.tryCatchStatement_catchBegin();
        h.promote(x, 'int');
        h.promote(y, 'int');
        flow.tryCatchStatement_catchEnd();
        flow.tryCatchStatement_catchBegin();
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.tryFinallyStatement_bodyBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.tryFinallyStatement_finallyBegin({});
        expect(flow.promotedType(x), isNull);
        expect(flow.promotedType(y).type, 'int');
        flow.tryFinallyStatement_end({});
      });
    });

    test(
        'tryFinallyStatement_finallyBegin() un-promotes variables assigned in '
        'body', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryFinallyStatement_bodyBegin();
        flow.write(x);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryFinallyStatement_finallyBegin({x});
        expect(flow.promotedType(x), isNull);
        flow.tryFinallyStatement_end({});
      });
    });

    test('tryFinallyStatement_end() restores promotions from try body', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        flow.tryFinallyStatement_bodyBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryFinallyStatement_finallyBegin({});
        expect(flow.promotedType(x), isNull);
        h.promote(y, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.tryFinallyStatement_end({});
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        flow.tryFinallyStatement_bodyBegin();
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.tryFinallyStatement_finallyBegin({});
        expect(flow.promotedType(x), isNull);
        flow.write(x);
        flow.write(y);
        h.promote(y, 'int');
        expect(flow.promotedType(y).type, 'int');
        flow.tryFinallyStatement_end({x, y});
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.promote(x, 'int');
        expect(flow.promotedType(x).type, 'int');
        flow.whileStatement_conditionBegin({x});
        expect(flow.promotedType(x), isNull);
        flow.whileStatement_bodyBegin(_Statement(), _Expression());
        flow.whileStatement_end();
      });
    });

    test('whileStatement_conditionBegin() handles not-yet-seen variables', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      var y = h.addVar('y', 'int?');
      h.run((flow) {
        h.declare(y, initialized: true);
        h.promote(y, 'int');
        flow.whileStatement_conditionBegin({x});
        flow.write(x);
        flow.whileStatement_bodyBegin(_Statement(), _Expression());
        flow.whileStatement_end();
      });
    });

    test('whileStatement_bodyBegin() promotes', () {
      var h = _Harness();
      var x = h.addVar('x', 'int?');
      h.run((flow) {
        h.declare(x, initialized: true);
        flow.whileStatement_conditionBegin({});
        flow.whileStatement_bodyBegin(_Statement(), h.notNull(x)());
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
      h.run((flow) {
        h.declare(x, initialized: true);
        h.declare(y, initialized: true);
        h.declare(z, initialized: true);
        var stmt = _Statement();
        flow.whileStatement_conditionBegin({});
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
      h.run((flow) {
        h.declare(x, initialized: false);
        var trueCondition = _Expression();
        flow.whileStatement_conditionBegin({x});
        flow.booleanLiteral(trueCondition, true);
        flow.whileStatement_bodyBegin(_Statement(), trueCondition);
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

    group('promote', () {
      test('unpromoted -> unchanged (same)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.promote(h, intVar, _Type('int'));
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (supertype)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.promote(h, intVar, _Type('Object'));
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (unrelated)', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.promote(h, intVar, _Type('String'));
        expect(s2, same(s1));
      });

      test('unpromoted -> subtype', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.promote(h, intQVar, _Type('int'));
        expect(s2.reachable, true);
        _Type.allowComparisons(() {
          expect(s2.variableInfo,
              {intQVar: VariableModel<_Type>(_Type('int'), false)});
        });
      });

      test('promoted -> unchanged (same)', () {
        var h = _Harness();
        var s1 =
            FlowModel<_Var, _Type>(true).promote(h, objectQVar, _Type('int'));
        var s2 = s1.promote(h, objectQVar, _Type('int'));
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (supertype)', () {
        var h = _Harness();
        var s1 =
            FlowModel<_Var, _Type>(true).promote(h, objectQVar, _Type('int'));
        var s2 = s1.promote(h, objectQVar, _Type('Object'));
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (unrelated)', () {
        var h = _Harness();
        var s1 =
            FlowModel<_Var, _Type>(true).promote(h, objectQVar, _Type('int'));
        var s2 = s1.promote(h, objectQVar, _Type('String'));
        expect(s2, same(s1));
      });

      test('promoted -> subtype', () {
        var h = _Harness();
        var s1 =
            FlowModel<_Var, _Type>(true).promote(h, objectQVar, _Type('int?'));
        var s2 = s1.promote(h, objectQVar, _Type('int'));
        expect(s2.reachable, true);
        _Type.allowComparisons(() {
          expect(s2.variableInfo,
              {objectQVar: VariableModel<_Type>(_Type('int'), false)});
        });
      });
    });

    group('write', () {
      var objectQVar = _Var('x', _Type('Object?'));
      test('unchanged', () {
        var s1 = FlowModel<_Var, _Type>(true).write(objectQVar);
        var s2 = s1.write(objectQVar);
        expect(s2, same(s1));
      });

      test('marks as assigned', () {
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.write(objectQVar);
        expect(s2.reachable, true);
        expect(s2.infoFor(objectQVar), VariableModel<_Type>(null, true));
      });

      test('un-promotes', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .write(objectQVar)
            .promote(h, objectQVar, _Type('int'));
        expect(s1.variableInfo, contains(objectQVar));
        var s2 = s1.write(objectQVar);
        expect(s2.reachable, true);
        expect(s2.variableInfo, {objectQVar: VariableModel<_Type>(null, true)});
      });
    });

    group('markNonNullable', () {
      test('unpromoted -> unchanged', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.markNonNullable(h, intVar);
        expect(s2, same(s1));
      });

      test('unpromoted -> promoted', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true);
        var s2 = s1.markNonNullable(h, intQVar);
        expect(s2.reachable, true);
        _Type.allowComparisons(() {
          expect(s2.infoFor(intQVar), VariableModel(_Type('int'), false));
        });
      });

      test('promoted -> unchanged', () {
        var h = _Harness();
        var s1 =
            FlowModel<_Var, _Type>(true).promote(h, objectQVar, _Type('int'));
        var s2 = s1.markNonNullable(h, objectQVar);
        expect(s2, same(s1));
      });

      test('promoted -> re-promoted', () {
        var h = _Harness();
        var s1 =
            FlowModel<_Var, _Type>(true).promote(h, objectQVar, _Type('int?'));
        var s2 = s1.markNonNullable(h, objectQVar);
        expect(s2.reachable, true);
        _Type.allowComparisons(() {
          expect(s2.variableInfo,
              {objectQVar: VariableModel<_Type>(_Type('int'), false)});
        });
      });
    });

    group('removePromotedAll', () {
      test('unchanged', () {
        var h = _Harness();
        var s1 =
            FlowModel<_Var, _Type>(true).promote(h, objectQVar, _Type('int'));
        var s2 = s1.removePromotedAll([intQVar]);
        expect(s2, same(s1));
      });

      test('changed', () {
        var h = _Harness();
        var s1 = FlowModel<_Var, _Type>(true)
            .promote(h, objectQVar, _Type('int'))
            .promote(h, intQVar, _Type('int'));
        var s2 = s1.removePromotedAll([intQVar]);
        expect(s2.reachable, true);
        _Type.allowComparisons(() {
          expect(s2.variableInfo, {
            objectQVar: VariableModel<_Type>(_Type('int'), false),
            intQVar: VariableModel<_Type>(null, false)
          });
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
        var s0 = FlowModel<_Var, _Type>(true);
        var s1 = s0.write(a).write(b);
        var s2 = s0.write(a).write(c);
        var result = s1.restrict(h, s2, Set());
        expect(result.infoFor(a).assigned, true);
        expect(result.infoFor(b).assigned, true);
        expect(result.infoFor(c).assigned, true);
        expect(result.infoFor(d).assigned, false);
      });

      test('promotion', () {
        void _check(String thisType, String otherType, bool unsafe,
            String expectedType) {
          var h = _Harness();
          var x = _Var('x', _Type('Object?'));
          var s0 = FlowModel<_Var, _Type>(true).write(x);
          var s1 = thisType == null ? s0 : s0.promote(h, x, _Type(thisType));
          var s2 = otherType == null ? s0 : s0.promote(h, x, _Type(otherType));
          var result = s1.restrict(h, s2, unsafe ? [x].toSet() : Set());
          if (expectedType == null) {
            expect(result.variableInfo, contains(x));
            expect(result.infoFor(x).promotedType, isNull);
          } else {
            expect(result.infoFor(x).promotedType.type, expectedType);
          }
        }

        _check(null, null, false, null);
        _check(null, null, true, null);
        _check('int', null, false, 'int');
        _check('int', null, true, 'int');
        _check(null, 'int', false, 'int');
        _check(null, 'int', true, null);
        _check('int?', 'int', false, 'int');
        _check('int', 'int?', false, 'int');
        _check('int', 'String', false, 'int');
        _check('int?', 'int', true, 'int?');
        _check('int', 'int?', true, 'int');
        _check('int', 'String', true, 'int');
      });

      test('variable present in one state but not the other', () {
        var h = _Harness();
        var x = _Var('x', _Type('Object?'));
        var s0 = FlowModel<_Var, _Type>(true);
        var s1 = s0.write(x);
        expect(s0.restrict(h, s1, {}), same(s1));
        expect(s0.restrict(h, s1, {x}), same(s1));
        expect(s1.restrict(h, s0, {}), same(s1));
        expect(s1.restrict(h, s0, {x}), same(s1));
      });
    });
  });

  group('join', () {
    var x = _Var('x', null);
    var y = _Var('y', null);
    var intType = _Type('int');
    var intQType = _Type('int?');
    var stringType = _Type('String');
    const emptyMap = <Null, VariableModel<Null>>{};

    VariableModel<_Type> model(_Type type) => VariableModel<_Type>(type, true);

    group('without input reuse', () {
      test('promoted with unpromoted', () {
        var h = _Harness();
        var p1 = {x: model(intType), y: model(null)};
        var p2 = {x: model(null), y: model(intType)};
        expect(FlowModel.joinVariableInfo(h, p1, p2),
            {x: model(null), y: model(null)});
      });
    });
    group('should re-use an input if possible', () {
      test('identical inputs', () {
        var h = _Harness();
        var p = {x: model(intType), y: model(stringType)};
        expect(FlowModel.joinVariableInfo(h, p, p), same(p));
      });

      test('one input empty', () {
        var h = _Harness();
        var p1 = {x: model(intType), y: model(stringType)};
        var p2 = <_Var, VariableModel<_Type>>{};
        expect(FlowModel.joinVariableInfo(h, p1, p2), same(emptyMap));
        expect(FlowModel.joinVariableInfo(h, p2, p1), same(emptyMap));
      });

      test('promoted with unpromoted', () {
        var h = _Harness();
        var p1 = {x: model(intType)};
        var p2 = {x: model(null)};
        expect(FlowModel.joinVariableInfo(h, p1, p2), same(p2));
        expect(FlowModel.joinVariableInfo(h, p2, p1), same(p2));
      });

      test('related types', () {
        var h = _Harness();
        var p1 = {x: model(intType)};
        var p2 = {x: model(intQType)};
        expect(FlowModel.joinVariableInfo(h, p1, p2), same(p2));
        expect(FlowModel.joinVariableInfo(h, p2, p1), same(p2));
      });

      test('unrelated types', () {
        var h = _Harness();
        var p1 = {x: model(intType)};
        var p2 = {x: model(stringType)};
        expect(FlowModel.joinVariableInfo(h, p1, p2), {x: model(null)});
        expect(FlowModel.joinVariableInfo(h, p2, p1), {x: model(null)});
      });

      test('sub-map', () {
        var h = _Harness();
        var xModel = model(intType);
        var p1 = {x: xModel, y: model(stringType)};
        var p2 = {x: xModel};
        expect(FlowModel.joinVariableInfo(h, p1, p2), same(p2));
        expect(FlowModel.joinVariableInfo(h, p2, p1), same(p2));
      });

      test('sub-map with matched subtype', () {
        var h = _Harness();
        var p1 = {x: model(intType), y: model(stringType)};
        var p2 = {x: model(intQType)};
        expect(FlowModel.joinVariableInfo(h, p1, p2), same(p2));
        expect(FlowModel.joinVariableInfo(h, p2, p1), same(p2));
      });

      test('sub-map with mismatched subtype', () {
        var h = _Harness();
        var p1 = {x: model(intQType), y: model(stringType)};
        var p2 = {x: model(intType)};
        var join12 = FlowModel.joinVariableInfo(h, p1, p2);
        _Type.allowComparisons(() => expect(join12, {x: model(intQType)}));
        var join21 = FlowModel.joinVariableInfo(h, p2, p1);
        _Type.allowComparisons(() => expect(join21, {x: model(intQType)}));
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

/// Representation of an expression to be visited by the test harness.  Calling
/// the function causes the expression to be "visited" (in other words, the
/// appropriate methods in [FlowAnalysis] are called in the appropriate order),
/// and the [_Expression] object representing the whole expression is returned.
///
/// This is used by methods in [_Harness] as a lightweight way of building up
/// complex sequences of calls to [FlowAnalysis] that represent large
/// expressions.
typedef _Expression LazyExpression();

class _Expression {}

class _Harness
    implements
        NodeOperations<_Expression>,
        TypeOperations<_Var, _Type>,
        FunctionBodyAccess<_Var> {
  FlowAnalysis<_Statement, _Expression, _Var, _Type> _flow;

  /// Returns a [LazyExpression] representing an expression with now special
  /// flow analysis semantics.
  LazyExpression get expr => () => _Expression();

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

  FlowAnalysis<_Statement, _Expression, _Var, _Type> createFlow() =>
      FlowAnalysis<_Statement, _Expression, _Var, _Type>(this, this, this);

  void declare(_Var v, {@required bool initialized}) {
    if (initialized) {
      _flow.write(v);
    }
  }

  /// Creates a [LazyExpression] representing an `== null` check performed on
  /// [variable].
  LazyExpression eqNull(_Var variable) {
    return () {
      var expr = _Expression();
      _flow.conditionEqNull(expr, variable, notEqual: false);
      return expr;
    };
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
    _flow.ifStatement_end(false);
  }

  /// Creates a [LazyExpression] representing an `is!` check, checking whether
  /// [variable] has the given [type].
  LazyExpression isNotType(_Var variable, String type) {
    return () {
      var expr = _Expression();
      _flow.isExpression_end(expr, variable, true, _Type(type));
      return expr;
    };
  }

  @override
  bool isPotentiallyMutatedInClosure(_Var variable) {
    // TODO(paulberry): make tests where this returns true
    return false;
  }

  @override
  bool isPotentiallyMutatedInScope(_Var variable) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  bool isSameType(_Type type1, _Type type2) {
    return type1.type == type2.type;
  }

  @override
  bool isSubtypeOf(_Type leftType, _Type rightType) {
    const Map<String, bool> _subtypes = const {
      'int <: int?': true,
      'int <: Object': true,
      'int <: Object?': true,
      'int <: String': false,
      'int? <: int': false,
      'int? <: Object?': true,
      'Object <: int': false,
      'String <: int': false,
      'String <: int?': false,
      'String <: Object?': true,
    };

    if (leftType.type == rightType.type) return true;
    var query = '$leftType <: $rightType';
    return _subtypes[query] ?? fail('Unknown subtype query: $query');
  }

  /// Creates a [LazyExpression] representing a `!= null` check performed on
  /// [variable].
  LazyExpression notNull(_Var variable) {
    return () {
      var expr = _Expression();
      _flow.conditionEqNull(expr, variable, notEqual: true);
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

  /// Causes [variable] to be promoted to [type].
  void promote(_Var variable, String type) {
    if_(isNotType(variable, type), _flow.handleExit);
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
      void callback(FlowAnalysis<_Statement, _Expression, _Var, _Type> flow)) {
    assert(_flow == null);
    _flow = createFlow();
    callback(_flow);
    _flow.finish();
  }

  @override
  _Expression unwrapParenthesized(_Expression node) {
    // TODO(paulberry): test cases where this matters
    return node;
  }

  @override
  _Type variableType(_Var variable) {
    return variable.type;
  }
}

class _Statement {}

class _Type {
  static bool _allowingTypeComparisons = false;

  final String type;

  _Type(this.type);

  @override
  bool operator ==(Object other) {
    if (_allowingTypeComparisons) {
      return other is _Type && other.type == this.type;
    } else {
      // The flow analysis engine should not compare types using operator==.  It
      // should compare them using TypeOperations.
      fail('Unexpected use of operator== on types');
    }
  }

  @override
  String toString() => type;

  static T allowComparisons<T>(T callback()) {
    var oldAllowingTypeComparisons = _allowingTypeComparisons;
    _allowingTypeComparisons = true;
    try {
      return callback();
    } finally {
      _allowingTypeComparisons = oldAllowingTypeComparisons;
    }
  }
}

class _Var {
  final String name;

  final _Type type;

  _Var(this.name, this.type);

  @override
  String toString() => '$type $name';
}
