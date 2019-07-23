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
      h.flow.finish();
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
      h.flow.finish();
    });

    test('finish checks proper nesting', () {
      var h = _Harness();
      var expr = _Expression();
      h.flow.ifStatement_thenBegin(expr);
      expect(() => h.flow.finish(), _asserts);
    });

    test('finish checks for un-added variables', () {
      var h = _Harness();
      var x = _Var('x', _Type('int'));
      h.flow.isAssigned(x);
      expect(() => h.flow.finish(), _asserts);
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
      h.flow.finish();
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
        expect(h.flow.promotedType(x).type, expectedPromotedType);
      }
      h.flow.ifStatement_elseBegin();
      expect(h.flow.promotedType(x), isNull);
      h.flow.ifStatement_end(true);
      h.flow.finish();
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

  group('State', () {
    var emptySet = State<_Var, _Type>(true).notAssigned;
    var intVar = _Var('x', _Type('int'));
    var intQVar = _Var('x', _Type('int?'));
    var objectQVar = _Var('x', _Type('Object?'));
    group('setReachable', () {
      var unreachable = State<_Var, _Type>(false);
      var reachable = State<_Var, _Type>(true);
      test('unchanged', () {
        expect(unreachable.setReachable(false), same(unreachable));
        expect(reachable.setReachable(true), same(reachable));
      });

      test('changed', () {
        void _check(State<_Var, _Type> initial, bool newReachability) {
          var s = initial.setReachable(newReachability);
          expect(s, isNot(same(initial)));
          expect(s.reachable, newReachability);
          expect(s.notAssigned, same(initial.notAssigned));
          expect(s.promoted, same(initial.promoted));
        }

        _check(unreachable, true);
        _check(reachable, false);
      });
    });

    group('add', () {
      test('default', () {
        // By default, added variables are considered unassigned.
        var s1 = State<_Var, _Type>(true);
        var s2 = s1.add(intVar);
        expect(s2.notAssigned.contains(intVar), true);
        expect(s2.reachable, true);
        expect(s2.promoted, same(s1.promoted));
      });

      test('unassigned', () {
        var s1 = State<_Var, _Type>(true);
        var s2 = s1.add(intVar, assigned: false);
        expect(s2.notAssigned.contains(intVar), true);
        expect(s2.reachable, true);
        expect(s2.promoted, same(s1.promoted));
      });

      test('assigned', () {
        var s1 = State<_Var, _Type>(true);
        var s2 = s1.add(intVar, assigned: true);
        expect(s2.notAssigned.contains(intVar), false);
        expect(s2, same(s1));
      });
    });

    group('promote', () {
      test('unpromoted -> unchanged (same)', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true).add(intVar);
        var s2 = s1.promote(h, intVar, _Type('int'));
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (supertype)', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true).add(intVar);
        var s2 = s1.promote(h, intVar, _Type('Object'));
        expect(s2, same(s1));
      });

      test('unpromoted -> unchanged (unrelated)', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true).add(intVar);
        var s2 = s1.promote(h, intVar, _Type('String'));
        expect(s2, same(s1));
      });

      test('unpromoted -> subtype', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true).add(intQVar);
        var s2 = s1.promote(h, intQVar, _Type('int'));
        expect(s2.reachable, true);
        expect(s2.notAssigned, same(s1.notAssigned));
        _Type.allowComparisons(() {
          expect(s2.promoted, {intQVar: _Type('int')});
        });
      });

      test('promoted -> unchanged (same)', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar)
            .promote(h, objectQVar, _Type('int'));
        var s2 = s1.promote(h, objectQVar, _Type('int'));
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (supertype)', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar)
            .promote(h, objectQVar, _Type('int'));
        var s2 = s1.promote(h, objectQVar, _Type('Object'));
        expect(s2, same(s1));
      });

      test('promoted -> unchanged (unrelated)', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar)
            .promote(h, objectQVar, _Type('int'));
        var s2 = s1.promote(h, objectQVar, _Type('String'));
        expect(s2, same(s1));
      });

      test('promoted -> subtype', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar)
            .promote(h, objectQVar, _Type('int?'));
        var s2 = s1.promote(h, objectQVar, _Type('int'));
        expect(s2.reachable, true);
        expect(s2.notAssigned, same(s1.notAssigned));
        _Type.allowComparisons(() {
          expect(s2.promoted, {objectQVar: _Type('int')});
        });
      });
    });

    group('write', () {
      var objectQVar = _Var('x', _Type('Object?'));
      test('unchanged', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true).add(objectQVar, assigned: true);
        var s2 = s1.write(h, emptySet, objectQVar);
        expect(s2, same(s1));
      });

      test('marks as assigned', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true).add(objectQVar, assigned: false);
        var s2 = s1.write(h, emptySet, objectQVar);
        expect(s2.reachable, true);
        expect(s2.notAssigned.contains(objectQVar), false);
        expect(s2.promoted, same(s1.promoted));
      });

      test('un-promotes', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar, assigned: true)
            .promote(h, objectQVar, _Type('int'));
        expect(s1.promoted, contains(objectQVar));
        var s2 = s1.write(h, emptySet, objectQVar);
        expect(s2.reachable, true);
        expect(s2.notAssigned, same(s1.notAssigned));
        expect(s2.promoted, isEmpty);
      });
    });

    group('markNonNullable', () {
      test('unpromoted -> unchanged', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true).add(intVar);
        var s2 = s1.markNonNullable(h, intVar);
        expect(s2, same(s1));
      });

      test('unpromoted -> promoted', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true).add(intQVar);
        var s2 = s1.markNonNullable(h, intQVar);
        expect(s2.reachable, true);
        expect(s2.notAssigned, same(s1.notAssigned));
        expect(s2.promoted[intQVar].type, 'int');
      });

      test('promoted -> unchanged', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar)
            .promote(h, objectQVar, _Type('int'));
        var s2 = s1.markNonNullable(h, objectQVar);
        expect(s2, same(s1));
      });

      test('promoted -> re-promoted', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar)
            .promote(h, objectQVar, _Type('int?'));
        var s2 = s1.markNonNullable(h, objectQVar);
        expect(s2.reachable, true);
        expect(s2.notAssigned, same(s1.notAssigned));
        _Type.allowComparisons(() {
          expect(s2.promoted, {objectQVar: _Type('int')});
        });
      });
    });

    group('removePromotedAll', () {
      test('unchanged', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar)
            .add(intQVar)
            .promote(h, objectQVar, _Type('int'));
        var s2 = s1.removePromotedAll({intQVar});
        expect(s2, same(s1));
      });

      test('changed', () {
        var h = _Harness();
        var s1 = State<_Var, _Type>(true)
            .add(objectQVar)
            .add(intQVar)
            .promote(h, objectQVar, _Type('int'))
            .promote(h, intQVar, _Type('int'));
        var s2 = s1.removePromotedAll({intQVar});
        expect(s2.reachable, true);
        expect(s2.notAssigned, same(s1.notAssigned));
        _Type.allowComparisons(() {
          expect(s2.promoted, {objectQVar: _Type('int')});
        });
      });
    });

    group('restrict', () {
      test('reachability', () {
        var h = _Harness();
        var reachable = State<_Var, _Type>(true);
        var unreachable = reachable.setReachable(false);
        expect(reachable.restrict(h, emptySet, reachable, {}), same(reachable));
        expect(reachable.restrict(h, emptySet, unreachable, {}),
            same(unreachable));
        expect(unreachable.restrict(h, emptySet, unreachable, {}),
            same(unreachable));
        expect(unreachable.restrict(h, emptySet, unreachable, {}),
            same(unreachable));
      });

      test('assignments', () {
        var h = _Harness();
        var a = _Var('a', _Type('int'));
        var b = _Var('b', _Type('int'));
        var c = _Var('c', _Type('int'));
        var d = _Var('d', _Type('int'));
        var s0 = State<_Var, _Type>(true).add(a).add(b).add(c).add(d);
        var s1 = s0.write(h, emptySet, a).write(h, emptySet, b);
        var s2 = s0.write(h, emptySet, a).write(h, emptySet, c);
        var result = s1.restrict(h, emptySet, s2, {});
        expect(result.notAssigned.contains(a), false);
        expect(result.notAssigned.contains(b), false);
        expect(result.notAssigned.contains(c), false);
        expect(result.notAssigned.contains(d), true);
      });

      test('promotion', () {
        void _check(String thisType, String otherType, bool unsafe,
            String expectedType) {
          var h = _Harness();
          var x = _Var('x', _Type('Object?'));
          var s0 = State<_Var, _Type>(true).add(x, assigned: true);
          var s1 = thisType == null ? s0 : s0.promote(h, x, _Type(thisType));
          var s2 = otherType == null ? s0 : s0.promote(h, x, _Type(otherType));
          var result = s1.restrict(h, emptySet, s2, unsafe ? {x} : {});
          if (expectedType == null) {
            expect(result.promoted, isNot(contains(x)));
          } else {
            expect(result.promoted[x].type, expectedType);
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
    // TODO(paulberry): make tests where this returns false
    return true;
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

  @override
  _Type promoteToNonNull(_Type type) {
    if (type.type.endsWith('?')) {
      return _Type(type.type.substring(0, type.type.length - 1));
    } else {
      return type;
    }
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
