// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/resolver/flow_analysis.dart';
import 'package:test/test.dart';

main() {
  group('API', () {
    test('conditionNotEqNull promotes true branch', () {
      var h = _Harness();
      var x = h.addAssignedVar('x', 'int?');
      var expr = _Expression();
      h.flow.conditionNotEqNull(expr, x);
      h.flow.ifStatement_thenBegin(expr);
      expect(h.flow.promotedType(x).type, 'int');
      h.flow.ifStatement_elseBegin();
      expect(h.flow.promotedType(x), isNull);
      h.flow.ifStatement_end(true);
      h.flow.verifyStackEmpty();
    });

    test('conditionEqNull promotes false branch', () {
      var h = _Harness();
      var x = h.addAssignedVar('x', 'int?');
      var expr = _Expression();
      h.flow.conditionEqNull(expr, x);
      h.flow.ifStatement_thenBegin(expr);
      expect(h.flow.promotedType(x), isNull);
      h.flow.ifStatement_elseBegin();
      expect(h.flow.promotedType(x).type, 'int');
      h.flow.ifStatement_end(true);
      h.flow.verifyStackEmpty();
    });

    test('ifStatement_end(false) keeps else branch if then branch exits', () {
      var h = _Harness();
      var x = h.addAssignedVar('x', 'int?');
      var expr = _Expression();
      h.flow.conditionEqNull(expr, x);
      h.flow.ifStatement_thenBegin(expr);
      h.flow.handleExit();
      h.flow.ifStatement_end(false);
      expect(h.flow.promotedType(x).type, 'int');
      h.flow.verifyStackEmpty();
    });

    void _checkIs(String declaredType, String tryPromoteType,
        String expectedPromotedType) {
      var h = _Harness();
      var x = h.addAssignedVar('x', 'int?');
      var expr = _Expression();
      h.flow.isExpression_end(expr, x, false, _Type(tryPromoteType));
      h.flow.ifStatement_thenBegin(expr);
      if (expectedPromotedType == null) {
        expect(h.flow.promotedType(x), isNull);
      } else {
        expect(h.flow.promotedType(x).type, 'int');
      }
      h.flow.ifStatement_elseBegin();
      expect(h.flow.promotedType(x), isNull);
      h.flow.ifStatement_end(true);
      h.flow.verifyStackEmpty();
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
  });

  group('join', () {
    group('should re-use an input if possible', () {
      var x = _Var('x', null);
      var y = _Var('y', null);
      var intType = _Type('int');
      var intQType = _Type('int?');
      var stringType = _Type('String');
      const emptyMap = <Null, Null>{};

      test('identical inputs', () {
        var flow = _Harness().flow;
        var p = {x: intType, y: stringType};
        expect(flow.joinPromoted(p, p), same(p));
      });

      test('one input empty', () {
        var flow = _Harness().flow;
        var p1 = {x: intType, y: stringType};
        var p2 = <_Var, _Type>{};
        expect(flow.joinPromoted(p1, p2), same(emptyMap));
        expect(flow.joinPromoted(p2, p1), same(emptyMap));
      });

      test('related types', () {
        var flow = _Harness().flow;
        var p1 = {x: intType};
        var p2 = {x: intQType};
        expect(flow.joinPromoted(p1, p2), same(p2));
        expect(flow.joinPromoted(p2, p1), same(p2));
      });

      test('unrelated types', () {
        var flow = _Harness().flow;
        var p1 = {x: intType};
        var p2 = {x: stringType};
        expect(flow.joinPromoted(p1, p2), same(emptyMap));
        expect(flow.joinPromoted(p2, p1), same(emptyMap));
      });

      test('sub-map', () {
        var flow = _Harness().flow;
        var p1 = {x: intType, y: stringType};
        var p2 = {x: intType};
        expect(flow.joinPromoted(p1, p2), same(p2));
        expect(flow.joinPromoted(p2, p1), same(p2));
      });

      test('sub-map with matched subtype', () {
        var flow = _Harness().flow;
        var p1 = {x: intType, y: stringType};
        var p2 = {x: intQType};
        expect(flow.joinPromoted(p1, p2), same(p2));
        expect(flow.joinPromoted(p2, p1), same(p2));
      });

      test('sub-map with mismatched subtype', () {
        var flow = _Harness().flow;
        var p1 = {x: intQType, y: stringType};
        var p2 = {x: intType};
        var join12 = flow.joinPromoted(p1, p2);
        _Type.allowComparisons(() => expect(join12, {x: intQType}));
        var join21 = flow.joinPromoted(p2, p1);
        _Type.allowComparisons(() => expect(join21, {x: intQType}));
      });
    });
  });
}

class _Expression {}

class _Harness
    implements
        NodeOperations<_Expression>,
        TypeOperations<_Var, _Type>,
        FunctionBodyAccess<_Var> {
  FlowAnalysis<_Statement, _Expression, _Var, _Type> flow;

  _Harness() {
    flow = FlowAnalysis<_Statement, _Expression, _Var, _Type>(this, this, this);
  }

  _Var addAssignedVar(String name, String type) {
    var v = _Var(name, _Type(type));
    flow.add(v, assigned: true);
    return v;
  }

  @override
  bool isLocalVariable(_Var variable) {
    throw UnimplementedError('TODO(paulberry)');
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
      'int <: String': false,
      'int? <: int': false,
      'String <: int': false,
      'String <: int?': false,
    };

    if (leftType.type == rightType.type) return true;
    var query = '$leftType <: $rightType';
    return _subtypes[query] ?? fail('Unknown subtype query: $query');
  }

  @override
  _Type tryPromoteToNonNull(_Type type) {
    if (type.type.endsWith('?')) {
      return _Type(type.type.substring(0, type.type.length - 1));
    }
    return null;
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
