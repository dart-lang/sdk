// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/task/strong/ast_properties.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:front_end/src/base/errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';
import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrongModeCastsTest);
    defineReflectiveTests(StrongModeLocalInferenceTest);
    defineReflectiveTests(StrongModeLocalInferenceTest_NNBD);
    defineReflectiveTests(StrongModeStaticTypeAnalyzer2Test);
    defineReflectiveTests(StrongModeTypePropagationTest);
  });
}

@reflectiveTest
class StrongModeCastsTest extends ResolverTestCase {
  test_implicitCastMetadata_ifElement_condition() async {
    var source = addSource(r'''
class C {
  dynamic dyn;
  Object object;
  bool boolean;

  void casts() {
    [if (dyn) null];
    [if (object) null];
    <int>{if (dyn) null};
    <int>{if (object) null};
    <int, int>{if (dyn) null: null};
    <int, int>{if (object) null: null};
  }

  void noCasts() {
    [if (boolean) null];
    [if (null) null];
    <int>{if (dyn) null};
    <int>{if (object) null};
    <int, int>{if (boolean) null : null};
    <int, int>{if (null) null : null};
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    Expression getCondition(ExpressionStatement s) {
      Expression expression = s.expression;
      IfElement ifElement;
      if (expression is ListLiteral) {
        ifElement = expression.elements[0];
      } else if (expression is SetOrMapLiteral) {
        ifElement = expression.elements[0];
      }
      return ifElement.condition;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      var expression = getCondition(s);
      var castType = getImplicitCast(expression);
      expect(castType, isNotNull,
          reason: 'Expression $expression does not have implicit cast');
      expect(castType.toString(), equals('bool'));
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      var expression = getCondition(s);
      var spreadCastType = getImplicitSpreadCast(expression);
      expect(spreadCastType, isNull,
          reason: 'Expression $expression should not have implicit cast');
    }
  }

  test_implicitCastMetadata_ifElement_list_branches() async {
    var source = addSource(r'''
class C {
  bool c;
  dynamic dyn;
  Object object;
  num someNum;
  int someInt;

  void casts() {
    <num>[if (c) dyn];
    <num>[if (c) object];
    <int>[if (c) dyn];
    <int>[if (c) object];
    <int>[if (c) someNum];
    <Null>[if (c) dyn];
    <Null>[if (c) object];
    <Null>[if (c) someNum];
    <Null>[if (c) someInt];
    <num>[if (c) dyn else dyn];
    <num>[if (c) object else object];
    <int>[if (c) dyn else dyn];
    <int>[if (c) object else object];
    <int>[if (c) someNum else someNum];
    <Null>[if (c) dyn else dyn];
    <Null>[if (c) object else object];
    <Null>[if (c) someNum else someNum];
    <Null>[if (c) someInt else someInt];
  }

  void noCasts() {
    <dynamic>[if (c) dyn];
    <dynamic>[if (c) object];
    <dynamic>[if (c) someNum];
    <dynamic>[if (c) someInt];
    <dynamic>[if (c) null];
    <Object>[if (c) dyn];
    <Object>[if (c) object];
    <Object>[if (c) someNum];
    <Object>[if (c) someInt];
    <Object>[if (c) null];
    <num>[if (c) someNum];
    <num>[if (c) someInt];
    <num>[if (c) null];
    <int>[if (c) someInt];
    <int>[if (c) null];
    <Null>[if (c) null];
    <dynamic>[if (c) dyn else dyn];
    <dynamic>[if (c) object else object];
    <dynamic>[if (c) someNum else someNum];
    <dynamic>[if (c) someInt else someInt];
    <dynamic>[if (c) null else null];
    <Object>[if (c) dyn else dyn];
    <Object>[if (c) object else object];
    <Object>[if (c) someNum else someNum];
    <Object>[if (c) someInt else someInt];
    <Object>[if (c) null else null];
    <num>[if (c) someNum else someNum];
    <num>[if (c) someInt else someInt];
    <num>[if (c) null else null];
    <int>[if (c) someInt else someInt];
    <int>[if (c) null else null];
    <Null>[if (c) null else null];
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    List<Expression> getBranches(ExpressionStatement s) {
      ListLiteral literal = s.expression;
      IfElement ifElement = literal.elements[0];
      return ifElement.elseElement == null
          ? [ifElement.thenElement]
          : [ifElement.thenElement, ifElement.elseElement];
    }

    DartType getListElementType(ExpressionStatement s) {
      ListLiteral literal = s.expression;
      return literal.typeArguments.arguments[0].type;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      for (var expression in getBranches(s)) {
        var castType = getImplicitCast(expression);
        expect(castType, isNotNull,
            reason: 'Expression $expression does not have implicit cast');
        expect(castType, equals(getListElementType(s)));
      }
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      for (var expression in getBranches(s)) {
        var castType = getImplicitCast(expression);
        expect(castType, isNull,
            reason: 'Expression $expression should not have implicit cast');
      }
    }
  }

  test_implicitCastMetadata_ifElement_map_keys() async {
    var source = addSource(r'''
class C {
  bool c;
  dynamic dyn;
  Object object;
  num someNum;
  int someInt;

  void casts() {
    <num, dynamic>{if (c) dyn: null};
    <num, dynamic>{if (c) object: null};
    <int, dynamic>{if (c) dyn: null};
    <int, dynamic>{if (c) object: null};
    <int, dynamic>{if (c) someNum: null};
    <Null, dynamic>{if (c) dyn: null};
    <Null, dynamic>{if (c) object: null};
    <Null, dynamic>{if (c) someNum: null};
    <Null, dynamic>{if (c) someInt: null};
    <num, dynamic>{if (c) dyn: null else dyn: null};
    <num, dynamic>{if (c) object: null else object: null};
    <int, dynamic>{if (c) dyn: null else dyn: null};
    <int, dynamic>{if (c) object: null else object: null};
    <int, dynamic>{if (c) someNum: null else someNum: null};
    <Null, dynamic>{if (c) dyn: null else dyn: null};
    <Null, dynamic>{if (c) object: null else object: null};
    <Null, dynamic>{if (c) someNum: null else someNum: null};
    <Null, dynamic>{if (c) someInt: null else someInt: null};
  }

  void noCasts() {
    <dynamic, dynamic>{if (c) dyn: null};
    <dynamic, dynamic>{if (c) object: null};
    <dynamic, dynamic>{if (c) someNum: null};
    <dynamic, dynamic>{if (c) someInt: null};
    <dynamic, dynamic>{if (c) null: null};
    <Object, dynamic>{if (c) dyn: null};
    <Object, dynamic>{if (c) object: null};
    <Object, dynamic>{if (c) someNum: null};
    <Object, dynamic>{if (c) someInt: null};
    <Object, dynamic>{if (c) null: null};
    <num, dynamic>{if (c) someNum: null};
    <num, dynamic>{if (c) someInt: null};
    <num, dynamic>{if (c) null: null};
    <int, dynamic>{if (c) someInt: null};
    <int, dynamic>{if (c) null: null};
    <Null, dynamic>{if (c) null: null};
    <dynamic, dynamic>{if (c) dyn: null else dyn: null};
    <dynamic, dynamic>{if (c) object: null else object: null};
    <dynamic, dynamic>{if (c) someNum: null else someNum: null};
    <dynamic, dynamic>{if (c) someInt: null else someInt: null};
    <dynamic, dynamic>{if (c) null: null else null: null};
    <Object, dynamic>{if (c) dyn: null else dyn: null};
    <Object, dynamic>{if (c) object: null else object: null};
    <Object, dynamic>{if (c) someNum: null else someNum: null};
    <Object, dynamic>{if (c) someInt: null else someInt: null};
    <Object, dynamic>{if (c) null: null else null: null};
    <num, dynamic>{if (c) someNum: null else someNum: null};
    <num, dynamic>{if (c) someInt: null else someInt: null};
    <num, dynamic>{if (c) null: null else null: null};
    <int, dynamic>{if (c) someInt: null else someInt: null};
    <int, dynamic>{if (c) null: null else null: null};
    <Null, dynamic>{if (c) null: null else null: null};
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    List<Expression> getKeys(ExpressionStatement s) {
      SetOrMapLiteral literal = s.expression;
      IfElement ifElement = literal.elements[0];
      return (ifElement.elseElement == null
              ? [ifElement.thenElement]
              : [ifElement.thenElement, ifElement.elseElement])
          .cast<MapLiteralEntry>()
          .map((elem) => elem.key)
          .toList();
    }

    DartType getMapKeyType(ExpressionStatement s) {
      SetOrMapLiteral literal = s.expression;
      return literal.typeArguments.arguments[0].type;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      for (var expression in getKeys(s)) {
        var castType = getImplicitCast(expression);
        expect(castType, isNotNull,
            reason: 'Expression $expression does not have implicit cast');
        expect(castType, equals(getMapKeyType(s)));
      }
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      for (var expression in getKeys(s)) {
        var castType = getImplicitCast(expression);
        expect(castType, isNull,
            reason: 'Expression $expression should not have implicit cast');
      }
    }
  }

  test_implicitCastMetadata_ifElement_map_values() async {
    var source = addSource(r'''
class C {
  bool c;
  dynamic dyn;
  Object object;
  num someNum;
  int someInt;

  void casts() {
    <dynamic, num>{if (c) null: dyn};
    <dynamic, num>{if (c) null: object};
    <dynamic, int>{if (c) null: dyn};
    <dynamic, int>{if (c) null: object};
    <dynamic, int>{if (c) null: someNum};
    <dynamic, Null>{if (c) null: dyn};
    <dynamic, Null>{if (c) null: object};
    <dynamic, Null>{if (c) null: someNum};
    <dynamic, Null>{if (c) null: someInt};
    <dynamic, num>{if (c) null: dyn else null: dyn};
    <dynamic, num>{if (c) null: object else null: object};
    <dynamic, int>{if (c) null: dyn else null: dyn};
    <dynamic, int>{if (c) null: object else null: object};
    <dynamic, int>{if (c) null: someNum else null: someNum};
    <dynamic, Null>{if (c) null: dyn else null: dyn};
    <dynamic, Null>{if (c) null: object else null: object};
    <dynamic, Null>{if (c) null: someNum else null: someNum};
    <dynamic, Null>{if (c) null: someInt else null: someInt};
  }

  void noCasts() {
    <dynamic, dynamic>{if (c) null: dyn};
    <dynamic, dynamic>{if (c) null: object};
    <dynamic, dynamic>{if (c) null: someNum};
    <dynamic, dynamic>{if (c) null: someInt};
    <dynamic, dynamic>{if (c) null: null};
    <dynamic, Object>{if (c) null: dyn};
    <dynamic, Object>{if (c) null: object};
    <dynamic, Object>{if (c) null: someNum};
    <dynamic, Object>{if (c) null: someInt};
    <dynamic, Object>{if (c) null: null};
    <dynamic, num>{if (c) null: someNum};
    <dynamic, num>{if (c) null: someInt};
    <dynamic, num>{if (c) null: null};
    <dynamic, int>{if (c) null: someInt};
    <dynamic, int>{if (c) null: null};
    <dynamic, Null>{if (c) null: null};
    <dynamic, dynamic>{if (c) null: dyn else null: dyn};
    <dynamic, dynamic>{if (c) null: object else null: object};
    <dynamic, dynamic>{if (c) null: someNum else null: someNum};
    <dynamic, dynamic>{if (c) null: someInt else null: someInt};
    <dynamic, dynamic>{if (c) null: null else null: null};
    <dynamic, Object>{if (c) null: dyn else null: dyn};
    <dynamic, Object>{if (c) null: object else null: object};
    <dynamic, Object>{if (c) null: someNum else null: someNum};
    <dynamic, Object>{if (c) null: someInt else null: someInt};
    <dynamic, Object>{if (c) null: null else null: null};
    <dynamic, num>{if (c) null: someNum else null: someNum};
    <dynamic, num>{if (c) null: someInt else null: someInt};
    <dynamic, num>{if (c) null: null else null: null};
    <dynamic, int>{if (c) null: someInt else null: someInt};
    <dynamic, int>{if (c) null: null else null: null};
    <dynamic, Null>{if (c) null: null else null: null};
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    List<Expression> getValues(ExpressionStatement s) {
      SetOrMapLiteral literal = s.expression;
      IfElement ifElement = literal.elements[0];
      return (ifElement.elseElement == null
              ? [ifElement.thenElement]
              : [ifElement.thenElement, ifElement.elseElement])
          .cast<MapLiteralEntry>()
          .map((elem) => elem.value)
          .toList();
    }

    DartType getMapValueType(ExpressionStatement s) {
      SetOrMapLiteral literal = s.expression;
      return literal.typeArguments.arguments[1].type;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      for (var expression in getValues(s)) {
        var castType = getImplicitCast(expression);
        expect(castType, isNotNull,
            reason: 'Expression $expression does not have implicit cast');
        expect(castType, equals(getMapValueType(s)));
      }
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      for (var expression in getValues(s)) {
        var castType = getImplicitCast(expression);
        expect(castType, isNull,
            reason: 'Expression $expression should not have implicit cast');
      }
    }
  }

  test_implicitCastMetadata_ifElement_set_trueBranch() async {
    var source = addSource(r'''
class C {
  bool c;
  dynamic dyn;
  Object object;
  num someNum;
  int someInt;

  void casts() {
    <num>{if (c) dyn};
    <num>{if (c) object};
    <int>{if (c) dyn};
    <int>{if (c) object};
    <int>{if (c) someNum};
    <Null>{if (c) dyn};
    <Null>{if (c) object};
    <Null>{if (c) someNum};
    <Null>{if (c) someInt};
    <num>{if (c) dyn else dyn};
    <num>{if (c) object else object};
    <int>{if (c) dyn else dyn};
    <int>{if (c) object else object};
    <int>{if (c) someNum else someNum};
    <Null>{if (c) dyn else dyn};
    <Null>{if (c) object else object};
    <Null>{if (c) someNum else someNum};
    <Null>{if (c) someInt else someInt};
  }

  void noCasts() {
    <dynamic>{if (c) dyn};
    <dynamic>{if (c) object};
    <dynamic>{if (c) someNum};
    <dynamic>{if (c) someInt};
    <dynamic>{if (c) null};
    <Object>{if (c) dyn};
    <Object>{if (c) object};
    <Object>{if (c) someNum};
    <Object>{if (c) someInt};
    <Object>{if (c) null};
    <num>{if (c) someNum};
    <num>{if (c) someInt};
    <num>{if (c) null};
    <int>{if (c) someInt};
    <int>{if (c) null};
    <Null>{if (c) null};
    <dynamic>{if (c) dyn else dyn};
    <dynamic>{if (c) object else object};
    <dynamic>{if (c) someNum else someNum};
    <dynamic>{if (c) someInt else someInt};
    <dynamic>{if (c) null else null};
    <Object>{if (c) dyn else dyn};
    <Object>{if (c) object else object};
    <Object>{if (c) someNum else someNum};
    <Object>{if (c) someInt else someInt};
    <Object>{if (c) null else null};
    <num>{if (c) someNum else someNum};
    <num>{if (c) someInt else someInt};
    <num>{if (c) null else null};
    <int>{if (c) someInt else someInt};
    <int>{if (c) null else null};
    <Null>{if (c) null else null};
 }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    List<Expression> getBranches(ExpressionStatement s) {
      SetOrMapLiteral literal = s.expression;
      IfElement ifElement = literal.elements[0];
      return ifElement.elseElement == null
          ? [ifElement.thenElement]
          : [ifElement.thenElement, ifElement.elseElement];
    }

    DartType getSetElementType(ExpressionStatement s) {
      SetOrMapLiteral literal = s.expression;
      return literal.typeArguments.arguments[0].type;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      for (var expression in getBranches(s)) {
        var castType = getImplicitCast(expression);
        expect(castType, isNotNull,
            reason: 'Expression $expression does not have implicit cast');
        expect(castType, equals(getSetElementType(s)));
      }
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      for (var expression in getBranches(s)) {
        var castType = getImplicitCast(expression);
        expect(castType, isNull,
            reason: 'Expression $expression should not have implicit cast');
      }
    }
  }

  test_implicitCastMetadata_spread_list_elements() async {
    var source = addSource(r'''
class C {
  dynamic dyn;
  Iterable<int> iInt;
  Iterable<Object> iObject;
  Iterable<dynamic> iDynamic;
  Iterable<Null> iNull;
  List<int> lInt;
  List<Object> lObject;
  List<dynamic> lDynamic;
  List<Null> lNull;

  void casts() {
    <int>[...dyn];
    <num>[...dyn];
    <int>[...iObject];
    <int>[...iDynamic];
    <int>[...lObject];
    <int>[...lDynamic];
    <Null>[...dyn];
    <Null>[...iObject];
    <Null>[...iDynamic];
    <Null>[...iInt];
    <Null>[...lObject];
    <Null>[...lDynamic];
    <Null>[...lInt];
  }

  void noCasts() {
    [...dyn];
    <dynamic>[...dyn];
    <Object>[...dyn];
    <dynamic>[...iInt];
    <Object>[...iInt];
    <Object>[...iNull];
    <dynamic>[...lInt];
    <Object>[...lInt];
    <Object>[...lNull];
    <dynamic>[...iObject];
    <Object>[...iObject];
    <Object>[...iNull];
    <dynamic>[...lObject];
    <Object>[...lObject];
    <Object>[...lNull];
    <dynamic>[...iDynamic];
    <Object>[...iDynamic];
    <Object>[...iNull];
    <dynamic>[...lDynamic];
    <Object>[...lDynamic];
    <Object>[...lNull];
    <num>[...iInt];
    <num>[...lInt];
    <num>[...iNull];
    <num>[...lNull];
    <int>[...iInt];
    <int>[...lInt];
    <int>[...iNull];
    <int>[...lNull];
    <Null>[...iNull];
    <Null>[...lNull];
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    Expression getSpreadExpression(ExpressionStatement s) {
      ListLiteral literal = s.expression;
      SpreadElement spread = literal.elements[0];
      return spread.expression;
    }

    DartType getListElementType(ExpressionStatement s) {
      ListLiteral literal = s.expression;
      return literal.typeArguments.arguments[0].type;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitSpreadCast(expression);
      expect(spreadCastType, isNotNull,
          reason: 'Expression $expression does not have implicit cast');
      expect(spreadCastType, equals(getListElementType(s)));
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitSpreadCast(expression);
      expect(spreadCastType, isNull,
          reason: 'Expression $expression should not have implicit cast');
    }
  }

  test_implicitCastMetadata_spread_list_iterable() async {
    var source = addSource(r'''
class C {
  dynamic dyn;
  Iterable<int> iInt;
  Iterable<Object> iObject;
  Iterable<dynamic> iDynamic;
  Iterable<Null> iNull;
  List<int> lInt;
  List<Object> lObject;
  List<dynamic> lDynamic;
  List<Null> lNull;

  void casts() {
    [...dyn];
    <int>[...dyn];
    <num>[...dyn];
  }

  void noCasts() {
    [...iInt];
    [...iObject];
    [...iDynamic];
    [...iNull];
    <Null>[...iInt];
    <Null>[...iObject];
    <Null>[...iDynamic];
    <Null>[...iNull];
    <int>[...iInt];
    <int>[...iObject];
    <int>[...iDynamic];
    <int>[...iNull];
    [...lInt];
    [...lObject];
    [...lDynamic];
    [...lNull];
    <Null>[...lInt];
    <Null>[...lObject];
    <Null>[...lDynamic];
    <Null>[...lNull];
    <int>[...lInt];
    <int>[...lObject];
    <int>[...lDynamic];
    <int>[...lNull];
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    Expression getSpreadExpression(ExpressionStatement e) {
      ListLiteral expression = e.expression;
      SpreadElement spread = expression.elements[0];
      return spread.expression;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitCast(expression);
      expect(spreadCastType, isNotNull,
          reason: 'Expression $expression does not have implicit cast');
      expect(spreadCastType.toString(), equals('Iterable<dynamic>'));
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitCast(expression);
      expect(spreadCastType, isNull,
          reason: 'Expression $expression should not have implicit cast');
    }
  }

  test_implicitCastMetadata_spread_map_keys() async {
    var source = addSource(r'''
abstract class HashMap<K, V> implements Map<K, V> {}
class C {
  dynamic dyn;
  Map<int, dynamic> mIntDynamic;
  Map<Object, dynamic> mObjectDynamic;
  Map<dynamic, dynamic> mDynamicDynamic;
  Map<Null, dynamic> mNullDynamic;
  HashMap<int, dynamic> hIntDynamic;
  HashMap<Object, dynamic> hObjectDynamic;
  HashMap<dynamic, dynamic> hDynamicDynamic;
  HashMap<Null, dynamic> hNullDynamic;

  void casts() {
    Map m0 = <int, dynamic>{...dyn};
    Map m1 = <num, dynamic>{...dyn};
    Map m2 = <int, dynamic>{...mObjectDynamic};
    Map m3 = <int, dynamic>{...mDynamicDynamic};
    Map m4 = <int, dynamic>{...hObjectDynamic};
    Map m5 = <int, dynamic>{...hDynamicDynamic};
    Map m6 = <Null, dynamic>{...dyn};
    Map m7 = <Null, dynamic>{...mObjectDynamic};
    Map m8 = <Null, dynamic>{...mDynamicDynamic};
    Map m9 = <Null, dynamic>{...mIntDynamic};
    Map m10 = <Null, dynamic>{...hObjectDynamic};
    Map m11 = <Null, dynamic>{...hDynamicDynamic};
    Map m12 = <Null, dynamic>{...hIntDynamic};
  }

  void noCasts() {
    Map m0 = {...dyn};
    Map m1 = <dynamic, dynamic>{...dyn};
    Map m2 = <Object, dynamic>{...dyn};
    Map m3 = <dynamic, dynamic>{...mIntDynamic};
    Map m4 = <Object, dynamic>{...mIntDynamic};
    Map m5 = <Object, dynamic>{...mNullDynamic};
    Map m6 = <dynamic, dynamic>{...hIntDynamic};
    Map m7 = <Object, dynamic>{...hIntDynamic};
    Map m8 = <Object, dynamic>{...hNullDynamic};
    Map m9 = <dynamic, dynamic>{...mObjectDynamic};
    Map m10 = <Object, dynamic>{...mObjectDynamic};
    Map m11 = <Object, dynamic>{...mNullDynamic};
    Map m12 = <dynamic, dynamic>{...hObjectDynamic};
    Map m13 = <Object, dynamic>{...hObjectDynamic};
    Map m14 = <Object, dynamic>{...hNullDynamic};
    Map m15 = <dynamic, dynamic>{...mDynamicDynamic};
    Map m16 = <Object, dynamic>{...mDynamicDynamic};
    Map m17 = <Object, dynamic>{...mNullDynamic};
    Map m18 = <dynamic, dynamic>{...hDynamicDynamic};
    Map m19 = <Object, dynamic>{...hDynamicDynamic};
    Map m20 = <Object, dynamic>{...hNullDynamic};
    Map m21 = <num, dynamic>{...mIntDynamic};
    Map m22 = <num, dynamic>{...hIntDynamic};
    Map m23 = <num, dynamic>{...mNullDynamic};
    Map m24 = <num, dynamic>{...hNullDynamic};
    Map m25 = <int, dynamic>{...hIntDynamic};
    Map m26 = <int, dynamic>{...mIntDynamic};
    Map m27 = <int, dynamic>{...mNullDynamic};
    Map m28 = <int, dynamic>{...hNullDynamic};
    Map m29 = <Null, dynamic>{...mNullDynamic};
    Map m30 = <Null, dynamic>{...hNullDynamic};
 }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    Expression getSpreadExpression(VariableDeclarationStatement s) {
      VariableDeclaration declaration = s.variables.variables[0];
      SetOrMapLiteral literal = declaration.initializer;
      SpreadElement spread = literal.elements[0];
      return spread.expression;
    }

    DartType getSetElementType(VariableDeclarationStatement s) {
      VariableDeclaration declaration = s.variables.variables[0];
      SetOrMapLiteral literal = declaration.initializer;
      return literal.typeArguments.arguments[0].type;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitSpreadKeyCast(expression);
      expect(spreadCastType, isNotNull,
          reason: 'Expression $expression does not have implicit cast');
      expect(spreadCastType, equals(getSetElementType(s)));
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitSpreadKeyCast(expression);
      expect(spreadCastType, isNull,
          reason: 'Expression $expression should not have implicit cast');
    }
  }

  test_implicitCastMetadata_spread_map_map() async {
    var source = addSource(r'''
abstract class HashMap<K, V> implements Map<K, V> {}
class C {
  dynamic dyn;
  Map<int, int> mIntInt;
  Map<int, Object> mIntObject;
  Map<Object, int> mObjectInt;
  Map<Object, Object> mObjectObject;
  Map<dynamic, dynamic> mDynamicDynamic;
  Map<Null, Null> mNullNull;
  Map<Object, Null> mObjectNull;
  Map<Null, Object> mNullObject;
  HashMap<int, int> hIntInt;
  HashMap<int, Object> hIntObject;
  HashMap<Object, int> hObjectInt;
  HashMap<Object, Object> hObjectObject;
  HashMap<dynamic, dynamic> hDynamicDynamic;
  HashMap<Null, Null> hNullNull;

  void casts() {
    Map m0 = {...dyn};
    Map m1 = <int, int>{...dyn};
    Map m2 = <num, int>{...dyn};
    Map m3 = <int, num>{...dyn};
    Map m4 = <num, num>{...dyn};
  }

  void noCasts() {
    Map m0 = {...mIntInt};
    Map m1 = {...mIntObject};
    Map m2 = {...mObjectInt};
    Map m3 = {...mObjectObject};
    Map m4 = {...mDynamicDynamic};
    Map m5 = {...mNullObject};
    Map m6 = {...mObjectNull};
    Map m7 = {...mNullNull};
    Map m8 = <Null, Null>{...mIntInt};
    Map m9 = <Null, Null>{...mObjectObject};
    Map m10 = <Null, Null>{...mDynamicDynamic};
    Map m11 = <Null, Null>{...mNullNull};
    Map m12 = <int, int>{...mIntInt};
    Map m13 = <int, int>{...mObjectObject};
    Map m14 = <int, int>{...mDynamicDynamic};
    Map m15 = <int, int>{...mNullNull};
    Map m16 = {...hIntInt};
    Map m17 = {...hObjectObject};
    Map m18 = {...hDynamicDynamic};
    Map m19 = {...hNullNull};
    Map m20 = <Null, Null>{...hIntInt};
    Map m21 = <Null, Null>{...hObjectObject};
    Map m22 = <Null, Null>{...hDynamicDynamic};
    Map m23 = <Null, Null>{...hNullNull};
    Map m24 = <int, int>{...hIntInt};
    Map m25 = <int, int>{...hObjectObject};
    Map m26 = <int, int>{...hDynamicDynamic};
    Map m27 = <int, int>{...hNullNull};
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    Expression getSpreadExpression(VariableDeclarationStatement s) {
      VariableDeclaration declaration = s.variables.variables[0];
      SetOrMapLiteral literal = declaration.initializer;
      SpreadElement spread = literal.elements[0];
      return spread.expression;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitCast(expression);
      expect(spreadCastType, isNotNull,
          reason: 'Expression $expression does not have implicit cast');
      expect(spreadCastType.toString(), equals('Map<dynamic, dynamic>'));
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitCast(expression);
      expect(spreadCastType, isNull,
          reason: 'Expression $expression should not have implicit cast');
    }
  }

  test_implicitCastMetadata_spread_map_values() async {
    var source = addSource(r'''
abstract class HashMap<K, V> implements Map<K, V> {}
class C {
  dynamic dyn;
  Map<dynamic, int> mDynamicInt;
  Map<dynamic, Object> mDynamicObject;
  Map<dynamic, dynamic> mDynamicDynamic;
  Map<dynamic, Null> mDynamicNull;
  HashMap<dynamic, int> hDynamicInt;
  HashMap<dynamic, Object> hDynamicObject;
  HashMap<dynamic, dynamic> hDynamicDynamic;
  HashMap<dynamic, Null> hDynamicNull;

  void casts() {
    Map m0 = <dynamic, int>{...dyn};
    Map m1 = <dynamic, num>{...dyn};
    Map m2 = <dynamic, int>{...mDynamicObject};
    Map m3 = <dynamic, int>{...mDynamicDynamic};
    Map m4 = <dynamic, int>{...hDynamicObject};
    Map m5 = <dynamic, int>{...hDynamicDynamic};
    Map m6 = <dynamic, Null>{...dyn};
    Map m7 = <dynamic, Null>{...mDynamicObject};
    Map m8 = <dynamic, Null>{...mDynamicDynamic};
    Map m9 = <dynamic, Null>{...mDynamicInt};
    Map m10 = <dynamic, Null>{...hDynamicObject};
    Map m11 = <dynamic, Null>{...hDynamicDynamic};
    Map m12 = <dynamic, Null>{...hDynamicInt};
  }

  void noCasts() {
    Map m0 = {...dyn};
    Map m1 = <dynamic, dynamic>{...dyn};
    Map m2 = <dynamic, Object>{...dyn};
    Map m3 = <dynamic, dynamic>{...mDynamicInt};
    Map m4 = <dynamic, Object>{...mDynamicInt};
    Map m5 = <dynamic, Object>{...mDynamicNull};
    Map m6 = <dynamic, dynamic>{...hDynamicInt};
    Map m7 = <dynamic, Object>{...hDynamicInt};
    Map m8 = <dynamic, Object>{...hDynamicNull};
    Map m9 = <dynamic, dynamic>{...mDynamicObject};
    Map m10 = <dynamic, Object>{...mDynamicObject};
    Map m11 = <dynamic, Object>{...mDynamicNull};
    Map m12 = <dynamic, dynamic>{...hDynamicObject};
    Map m13 = <dynamic, Object>{...hDynamicObject};
    Map m14 = <dynamic, Object>{...hDynamicNull};
    Map m15 = <dynamic, dynamic>{...mDynamicDynamic};
    Map m16 = <dynamic, Object>{...mDynamicDynamic};
    Map m17 = <dynamic, Object>{...mDynamicNull};
    Map m18 = <dynamic, dynamic>{...hDynamicDynamic};
    Map m19 = <dynamic, Object>{...hDynamicDynamic};
    Map m20 = <dynamic, Object>{...hDynamicNull};
    Map m21 = <dynamic, num>{...mDynamicInt};
    Map m22 = <dynamic, num>{...hDynamicInt};
    Map m23 = <dynamic, num>{...mDynamicNull};
    Map m24 = <dynamic, num>{...hDynamicNull};
    Map m25 = <dynamic, int>{...hDynamicInt};
    Map m26 = <dynamic, int>{...mDynamicInt};
    Map m27 = <dynamic, int>{...mDynamicNull};
    Map m28 = <dynamic, int>{...hDynamicNull};
    Map m29 = <dynamic, Null>{...mDynamicNull};
    Map m30 = <dynamic, Null>{...hDynamicNull};
 }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    Expression getSpreadExpression(VariableDeclarationStatement s) {
      VariableDeclaration declaration = s.variables.variables[0];
      SetOrMapLiteral literal = declaration.initializer;
      SpreadElement spread = literal.elements[0];
      return spread.expression;
    }

    DartType getValueType(VariableDeclarationStatement s) {
      VariableDeclaration declaration = s.variables.variables[0];
      SetOrMapLiteral literal = declaration.initializer;
      return literal.typeArguments.arguments[1].type;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitSpreadValueCast(expression);
      expect(spreadCastType, isNotNull,
          reason: 'Expression $expression does not have implicit cast');
      expect(spreadCastType, equals(getValueType(s)));
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitSpreadValueCast(expression);
      expect(spreadCastType, isNull,
          reason: 'Expression $expression should not have implicit cast');
    }
  }

  test_implicitCastMetadata_spread_set_elements() async {
    var source = addSource(r'''
class C {
  dynamic dyn;
  Iterable<int> iInt;
  Iterable<Object> iObject;
  Iterable<dynamic> iDynamic;
  Iterable<Null> iNull;
  List<int> lInt;
  List<Object> lObject;
  List<dynamic> lDynamic;
  List<Null> lNull;

  void casts() {
    Set s0 = <int>{...dyn};
    Set s1 = <num>{...dyn};
    Set s2 = <int>{...iObject};
    Set s3 = <int>{...iDynamic};
    Set s4 = <int>{...lObject};
    Set s5 = <int>{...lDynamic};
    Set s6 = <Null>{...dyn};
    Set s7 = <Null>{...iObject};
    Set s8 = <Null>{...iDynamic};
    Set s9 = <Null>{...iInt};
    Set s10 = <Null>{...lObject};
    Set s11 = <Null>{...lDynamic};
    Set s12 = <Null>{...lInt};
  }

  void noCasts() {
    Set s0 = {...dyn};
    Set s1 = <dynamic>{...dyn};
    Set s2 = <Object>{...dyn};
    Set s3 = <dynamic>{...iInt};
    Set s4 = <Object>{...iInt};
    Set s5 = <Object>{...iNull};
    Set s6 = <dynamic>{...lInt};
    Set s7 = <Object>{...lInt};
    Set s8 = <Object>{...lNull};
    Set s9 = <dynamic>{...iObject};
    Set s10 = <Object>{...iObject};
    Set s11 = <Object>{...iNull};
    Set s12 = <dynamic>{...lObject};
    Set s13 = <Object>{...lObject};
    Set s14 = <Object>{...lNull};
    Set s15 = <dynamic>{...iDynamic};
    Set s16 = <Object>{...iDynamic};
    Set s17 = <Object>{...iNull};
    Set s18 = <dynamic>{...lDynamic};
    Set s19 = <Object>{...lDynamic};
    Set s20 = <Object>{...lNull};
    Set s21 = <num>{...iInt};
    Set s22 = <num>{...lInt};
    Set s23 = <num>{...iNull};
    Set s24 = <num>{...lNull};
    Set s25 = <int>{...iInt};
    Set s26 = <int>{...lInt};
    Set s27 = <int>{...iNull};
    Set s28 = <int>{...lNull};
    Set s29 = <Null>{...iNull};
    Set s30 = <Null>{...lNull};
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    Expression getSpreadExpression(VariableDeclarationStatement s) {
      VariableDeclaration declaration = s.variables.variables[0];
      SetOrMapLiteral literal = declaration.initializer;
      SpreadElement spread = literal.elements[0];
      return spread.expression;
    }

    DartType getKeyType(VariableDeclarationStatement s) {
      VariableDeclaration declaration = s.variables.variables[0];
      SetOrMapLiteral literal = declaration.initializer;
      return literal.typeArguments.arguments[0].type;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitSpreadCast(expression);
      expect(spreadCastType, isNotNull,
          reason: 'Expression $expression does not have implicit cast');
      expect(spreadCastType, equals(getKeyType(s)));
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitSpreadCast(expression);
      expect(spreadCastType, isNull,
          reason: 'Expression $expression should not have implicit cast');
    }
  }

  test_implicitCastMetadata_spread_set_iterable() async {
    var source = addSource(r'''
class C {
  dynamic dyn;
  Iterable<int> iInt;
  Iterable<Object> iObject;
  Iterable<dynamic> iDynamic;
  Iterable<Null> iNull;
  List<int> lInt;
  List<Object> lObject;
  List<dynamic> lDynamic;
  List<Null> lNull;

  void casts() {
    Set s0 = {...dyn};
    Set s1 = <int>{...dyn};
    Set s2 = <num>{...dyn};
  }

  void noCasts() {
    Set s0 = {...iInt};
    Set s1 = {...iObject};
    Set s2 = {...iDynamic};
    Set s3 = {...iNull};
    Set s4 = <Null>{...iInt};
    Set s5 = <Null>{...iObject};
    Set s6 = <Null>{...iDynamic};
    Set s7 = <Null>{...iNull};
    Set s8 = <int>{...iInt};
    Set s9 = <int>{...iObject};
    Set s10 = <int>{...iDynamic};
    Set s11 = <int>{...iNull};
    Set s12 = {...lInt};
    Set s13 = {...lObject};
    Set s14 = {...lDynamic};
    Set s15 = {...lNull};
    Set s16 = <Null>{...lInt};
    Set s17 = <Null>{...lObject};
    Set s18 = <Null>{...lDynamic};
    Set s19 = <Null>{...lNull};
    Set s20 = <int>{...lInt};
    Set s21 = <int>{...lObject};
    Set s22 = <int>{...lDynamic};
  }
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    Expression getSpreadExpression(VariableDeclarationStatement s) {
      VariableDeclaration declaration = s.variables.variables[0];
      SetOrMapLiteral literal = declaration.initializer;
      SpreadElement spread = literal.elements[0];
      return spread.expression;
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitCast(expression);
      expect(spreadCastType, isNotNull,
          reason: 'Expression $expression does not have implicit cast');
      expect(spreadCastType.toString(), equals('Iterable<dynamic>'));
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      var expression = getSpreadExpression(s);
      var spreadCastType = getImplicitCast(expression);
      expect(spreadCastType, isNull,
          reason: 'Expression $expression should not have implicit cast');
    }
  }
}

/// Strong mode static analyzer local type inference tests
@reflectiveTest
class StrongModeLocalInferenceTest extends ResolverTestCase {
  TypeAssertions _assertions;

  Asserter<DartType> _isDynamic;
  Asserter<InterfaceType> _isFutureOfDynamic;
  Asserter<InterfaceType> _isFutureOfInt;
  Asserter<InterfaceType> _isFutureOfNull;
  Asserter<InterfaceType> _isFutureOrOfInt;
  Asserter<DartType> _isInt;
  Asserter<DartType> _isNull;
  Asserter<DartType> _isNum;
  Asserter<DartType> _isObject;
  Asserter<DartType> _isString;

  AsserterBuilder2<Asserter<DartType>, Asserter<DartType>, DartType>
      _isFunction2Of;
  AsserterBuilder<List<Asserter<DartType>>, InterfaceType> _isFutureOf;
  AsserterBuilder<List<Asserter<DartType>>, InterfaceType> _isFutureOrOf;
  AsserterBuilderBuilder<Asserter<DartType>, List<Asserter<DartType>>, DartType>
      _isInstantiationOf;
  AsserterBuilder<Asserter<DartType>, InterfaceType> _isListOf;
  AsserterBuilder2<Asserter<DartType>, Asserter<DartType>, InterfaceType>
      _isMapOf;
  AsserterBuilder<List<Asserter<DartType>>, InterfaceType> _isStreamOf;
  AsserterBuilder<DartType, DartType> _isType;

  AsserterBuilder<Element, DartType> _hasElement;

  @override
  Future<TestAnalysisResult> computeAnalysisResult(Source source) async {
    TestAnalysisResult result = await super.computeAnalysisResult(source);
    if (_assertions == null) {
      _assertions = new TypeAssertions(typeProvider);
      _isType = _assertions.isType;
      _hasElement = _assertions.hasElement;
      _isInstantiationOf = _assertions.isInstantiationOf;
      _isInt = _assertions.isInt;
      _isNull = _assertions.isNull;
      _isNum = _assertions.isNum;
      _isObject = _assertions.isObject;
      _isString = _assertions.isString;
      _isDynamic = _assertions.isDynamic;
      _isListOf = _assertions.isListOf;
      _isMapOf = _assertions.isMapOf;
      _isFunction2Of = _assertions.isFunction2Of;
      _isFutureOf = _isInstantiationOf(_hasElement(typeProvider.futureElement));
      _isFutureOrOf =
          _isInstantiationOf(_hasElement(typeProvider.futureOrElement));
      _isFutureOfDynamic = _isFutureOf([_isDynamic]);
      _isFutureOfInt = _isFutureOf([_isInt]);
      _isFutureOfNull = _isFutureOf([_isNull]);
      _isFutureOrOfInt = _isFutureOrOf([_isInt]);
      _isStreamOf = _isInstantiationOf(_hasElement(typeProvider.streamElement));
    }
    return result;
  }

  @override
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    resetWith(options: options);
  }

  test_async_method_propagation() async {
    String code = r'''
      import "dart:async";
      class A {
        Future f0() => new Future.value(3);
        Future f1() async => new Future.value(3);
        Future f2() async => await new Future.value(3);

        Future<int> f3() => new Future.value(3);
        Future<int> f4() async => new Future.value(3);
        Future<int> f5() async => await new Future.value(3);

        Future g0() { return new Future.value(3); }
        Future g1() async { return new Future.value(3); }
        Future g2() async { return await new Future.value(3); }

        Future<int> g3() { return new Future.value(3); }
        Future<int> g4() async { return new Future.value(3); }
        Future<int> g5() async { return await new Future.value(3); }
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      FunctionBody body = test.body;
      Expression returnExp;
      if (body is ExpressionFunctionBody) {
        returnExp = body.expression;
      } else {
        ReturnStatement stmt = (body as BlockFunctionBody).block.statements[0];
        returnExp = stmt.expression;
      }
      DartType type = returnExp.staticType;
      if (returnExp is AwaitExpression) {
        type = returnExp.expression.staticType;
      }
      typeTest(type);
    }

    check("f0", _isFutureOfDynamic);
    check("f1", _isFutureOfDynamic);
    check("f2", _isFutureOfDynamic);

    check("f3", _isFutureOfInt);
    check("f4", _isFutureOfInt);
    check("f5", _isFutureOfInt);

    check("g0", _isFutureOfDynamic);
    check("g1", _isFutureOfDynamic);
    check("g2", _isFutureOfDynamic);

    check("g3", _isFutureOfInt);
    check("g4", _isFutureOfInt);
    check("g5", _isFutureOfInt);
  }

  test_async_propagation() async {
    String code = r'''
      import "dart:async";

      Future f0() => new Future.value(3);
      Future f1() async => new Future.value(3);
      Future f2() async => await new Future.value(3);

      Future<int> f3() => new Future.value(3);
      Future<int> f4() async => new Future.value(3);
      Future<int> f5() async => await new Future.value(3);

      Future g0() { return new Future.value(3); }
      Future g1() async { return new Future.value(3); }
      Future g2() async { return await new Future.value(3); }

      Future<int> g3() { return new Future.value(3); }
      Future<int> g4() async { return new Future.value(3); }
      Future<int> g5() async { return await new Future.value(3); }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      FunctionBody body = test.functionExpression.body;
      Expression returnExp;
      if (body is ExpressionFunctionBody) {
        returnExp = body.expression;
      } else {
        ReturnStatement stmt = (body as BlockFunctionBody).block.statements[0];
        returnExp = stmt.expression;
      }
      DartType type = returnExp.staticType;
      if (returnExp is AwaitExpression) {
        type = returnExp.expression.staticType;
      }
      typeTest(type);
    }

    check("f0", _isFutureOfDynamic);
    check("f1", _isFutureOfDynamic);
    check("f2", _isFutureOfDynamic);

    check("f3", _isFutureOfInt);
    check("f4", _isFutureOfInt);
    check("f5", _isFutureOfInt);

    check("g0", _isFutureOfDynamic);
    check("g1", _isFutureOfDynamic);
    check("g2", _isFutureOfDynamic);

    check("g3", _isFutureOfInt);
    check("g4", _isFutureOfInt);
    check("g5", _isFutureOfInt);
  }

  test_async_star_method_propagation() async {
    String code = r'''
      import "dart:async";
      class A {
        Stream g0() async* { yield []; }
        Stream g1() async* { yield* new Stream(); }

        Stream<List<int>> g2() async* { yield []; }
        Stream<List<int>> g3() async* { yield* new Stream(); }
      }
    ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      BlockFunctionBody body = test.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("g0", _isListOf(_isDynamic));
    check("g1", _isStreamOf([_isDynamic]));

    check("g2", _isListOf(_isInt));
    check("g3", _isStreamOf([(DartType type) => _isListOf(_isInt)(type)]));
  }

  test_async_star_propagation() async {
    String code = r'''
      import "dart:async";

      Stream g0() async* { yield []; }
      Stream g1() async* { yield* new Stream(); }

      Stream<List<int>> g2() async* { yield []; }
      Stream<List<int>> g3() async* { yield* new Stream(); }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      BlockFunctionBody body = test.functionExpression.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("g0", _isListOf(_isDynamic));
    check("g1", _isStreamOf([_isDynamic]));

    check("g2", _isListOf(_isInt));
    check("g3", _isStreamOf([(DartType type) => _isListOf(_isInt)(type)]));
  }

  test_cascadeExpression() async {
    String code = r'''
      class A<T> {
        List<T> map(T a, List<T> mapper(T x)) => mapper(a);
      }

      void main () {
        A<int> a = new A()..map(0, (x) => [x]);
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    CascadeExpression fetch(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      CascadeExpression exp = decl.initializer;
      return exp;
    }

    Element elementA = AstFinder.getClass(unit, "A").declaredElement;

    CascadeExpression cascade = fetch(0);
    _isInstantiationOf(_hasElement(elementA))([_isInt])(cascade.staticType);
    MethodInvocation invoke = cascade.cascadeSections[0];
    FunctionExpression function = invoke.argumentList.arguments[1];
    ExecutableElement f0 = function.declaredElement;
    _isListOf(_isInt)(f0.type.returnType);
    expect(f0.type.normalParameterTypes[0], typeProvider.intType);
  }

  test_constrainedByBounds1() async {
    // Test that upwards inference with two type variables correctly
    // propogates from the constrained variable to the unconstrained
    // variable if they are ordered left to right.
    String code = r'''
    T f<S, T extends S>(S x) => null;
    void test() { var x = f(3); }
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isInt(call.staticType);
  }

  test_constrainedByBounds2() async {
    // Test that upwards inference with two type variables does
    // propogate from the constrained variable to the unconstrained
    // variable if they are ordered right to left.
    String code = r'''
    T f<T extends S, S>(S x) => null;
    void test() { var x = f(3); }
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isInt(call.staticType);
  }

  test_constrainedByBounds3() async {
    Source source = addSource(r'''
      T f<T extends S, S extends int>(S x) => null;
      void test() { var x = f(3); }
   ''');
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isInt(call.staticType);
  }

  test_constrainedByBounds4() async {
    // Test that upwards inference with two type variables correctly
    // propogates from the constrained variable to the unconstrained
    // variable if they are ordered left to right, when the variable
    // appears co and contra variantly
    String code = r'''
    typedef To Func1<From, To>(From x);
    T f<S, T extends Func1<S, S>>(S x) => null;
    void test() { var x = f(3)(4); }
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isInt(call.staticType);
  }

  test_constrainedByBounds5() async {
    // Test that upwards inference with two type variables does not
    // propogate from the constrained variable to the unconstrained
    // variable if they are ordered right to left, when the variable
    // appears co and contra variantly, and that an error is issued
    // for the non-matching bound.
    String code = r'''
    typedef To Func1<From, To>(From x);
    T f<T extends Func1<S, S>, S>(S x) => null;
    void test() { var x = f(3)(null); }
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.COULD_NOT_INFER]);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    VariableDeclarationStatement stmt = statements[0];
    VariableDeclaration decl = stmt.variables.variables[0];
    Expression call = decl.initializer;
    _isDynamic(call.staticType);
  }

  test_constructorInitializer_propagation() async {
    String code = r'''
      class A {
        List<String> x;
        A() : this.x = [];
      }
   ''';
    CompilationUnit unit = await resolveSource(code);
    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    ConstructorFieldInitializer assignment = constructor.initializers[0];
    Expression exp = assignment.expression;
    _isListOf(_isString)(exp.staticType);
  }

  test_covarianceChecks() async {
    var source = addSource(r'''
class C<T> {
  add(T t) {}
  forEach(void f(T t)) {}
}
class D extends C<int> {
  add(int t) {}
  forEach(void f(int t)) {}
}
class E extends C<int> {
  add(Object t) {}
  forEach(void f(Null t)) {}
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);
    var cAdd = AstFinder.getMethodInClass(unit, "C", "add");
    var covariantC = getClassCovariantParameters(AstFinder.getClass(unit, "C"));
    expect(covariantC.toList(), [cAdd.declaredElement.parameters[0]]);

    var dAdd = AstFinder.getMethodInClass(unit, "D", "add");
    var covariantD = getClassCovariantParameters(AstFinder.getClass(unit, "D"));
    expect(covariantD.toList(), [dAdd.declaredElement.parameters[0]]);

    var covariantE = getClassCovariantParameters(AstFinder.getClass(unit, "E"));
    expect(covariantE.toList(), []);
  }

  test_covarianceChecks2() async {
    var content = r'''
class View<T1> {
  View<T1> create() => this;
}

class Bar<T2> extends View<Bar<T2>> {}

main() {
  var b = new Bar<int>();
  b.create();
}
''';
    var source = addSource(content);
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    var findNode = FindNode(content, unit);
    expect(getImplicitCast(findNode.methodInvocation('b.create')), isNull);
  }

  test_covarianceChecks_genericMethods() async {
    var source = addSource(r'''
class C<T> {
  add<S>(T t) {}
  forEach<S>(S f(T t)) {}
}
class D extends C<int> {
  add<S>(int t) {}
  forEach<S>(S f(int t)) {}
}
class E extends C<int> {
  add<S>(Object t) {}
  forEach<S>(S f(Null t)) {}
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    var cAdd = AstFinder.getMethodInClass(unit, "C", "add");
    var covariantC = getClassCovariantParameters(AstFinder.getClass(unit, "C"));
    expect(covariantC.toList(), [cAdd.declaredElement.parameters[0]]);

    var dAdd = AstFinder.getMethodInClass(unit, "D", "add");
    var covariantD = getClassCovariantParameters(AstFinder.getClass(unit, "D"));
    expect(covariantD.toList(), [dAdd.declaredElement.parameters[0]]);

    var covariantE = getClassCovariantParameters(AstFinder.getClass(unit, "E"));
    expect(covariantE.toList(), []);
  }

  test_covarianceChecks_returnFunction() async {
    var source = addSource(r'''
typedef F<T>(T t);
typedef T R<T>();
class C<T> {
  F<T> f;

  C();
  factory C.fact() => new C<Null>();

  F<T> get g => null;
  F<T> m1() => null;
  R<F<T>> m2() => null;

  casts(C<T> other, T t) {
    other.f;
    other.g(t);
    other.m1();
    other.m2;

    new C<T>.fact().f(t);
    new C<int>.fact().g;
    new C<int>.fact().m1;
    new C<T>.fact().m2();

    new C<Object>.fact().f(42);
    new C<Object>.fact().g;
    new C<Object>.fact().m1;
    new C<Object>.fact().m2();

    new C.fact().f(42);
    new C.fact().g;
    new C.fact().m1;
    new C.fact().m2();
  }

  noCasts(T t) {
    f;
    g;
    m1();
    m2();

    f(t);
    g(t);
    (f)(t);
    (g)(t);
    m1;
    m2;

    this.f;
    this.g;
    this.m1();
    this.m2();
    this.m1;
    this.m2;
    (this.m1)();
    (this.m2)();
    this.f(t);
    this.g(t);
    (this.f)(t);
    (this.g)(t);

    new C<int>().f;
    new C<T>().g;
    new C<int>().m1();
    new C().m2();

    new D().f;
    new D().g;
    new D().m1();
    new D().m2();
  }
}
class D extends C<num> {
  noCasts(t) {
    f;
    this.g;
    this.m1();
    m2;

    super.f;
    super.g;
    super.m1;
    super.m2();
  }
}

D d;
C<Object> c;
C cD;
C<Null> cN;
F<Object> f;
F<Null> fN;
R<F<Object>> rf;
R<F<Null>> rfN;
R<R<F<Object>>> rrf;
R<R<F<Null>>> rrfN;
Object obj;
F<int> fi;
R<F<int>> rfi;
R<R<F<int>>> rrfi;

casts() {
  c.f;
  c.g;
  c.m1;
  c.m1();
  c.m2();

  fN = c.f;
  fN = c.g;
  rfN = c.m1;
  rrfN = c.m2;
  fN = c.m1();
  rfN = c.m2();

  f = c.f;
  f = c.g;
  rf = c.m1;
  rrf = c.m2;
  f = c.m1();
  rf = c.m2();
  c.m2()();

  c.f(obj);
  c.g(obj);
  (c.f)(obj);
  (c.g)(obj);
  (c.m1)();
  c.m1()(obj);
  (c.m2)();

  cD.f;
  cD.g;
  cD.m1;
  cD.m1();
  cD.m2();

  cN.f;
  cN.g;
  cN.m1;
  cN.m1();
  cN.m2();
}

noCasts() {
  fi = d.f;
  fi = d.g;
  rfi = d.m1;
  fi = d.m1();
  rrfi = d.m2;
  rfi = d.m2();
  d.f(42);
  d.g(42);
  (d.f)(42);
  (d.g)(42);
  d.m1()(42);
  d.m2()()(42);
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    void expectCast(Statement statement, bool hasCast) {
      var value = (statement as ExpressionStatement).expression;
      if (value is AssignmentExpression) {
        value = (value as AssignmentExpression).rightHandSide;
      }
      while (value is FunctionExpressionInvocation) {
        value = (value as FunctionExpressionInvocation).function;
      }
      while (value is ParenthesizedExpression) {
        value = (value as ParenthesizedExpression).expression;
      }
      var isCallingGetter =
          value is MethodInvocation && !value.methodName.name.startsWith('m');
      var cast = isCallingGetter
          ? getImplicitOperationCast(value)
          : getImplicitCast(value);
      var castKind = isCallingGetter ? 'special cast' : 'cast';
      expect(cast, hasCast ? isNotNull : isNull,
          reason: '`$statement` should ' +
              (hasCast ? '' : 'not ') +
              'have a $castKind on `$value`.');
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      expectCast(s, false);
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      expectCast(s, true);
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'D', 'noCasts')) {
      expectCast(s, false);
    }
    for (var s in AstFinder.getStatementsInTopLevelFunction(unit, 'noCasts')) {
      expectCast(s, false);
    }
    for (var s in AstFinder.getStatementsInTopLevelFunction(unit, 'casts')) {
      expectCast(s, true);
    }
  }

  test_covarianceChecks_superclass() async {
    var source = addSource(r'''
class C<T> {
  add(T t) {}
  forEach(void f(T t)) {}
}
class D {
  add(int t) {}
  forEach(void f(int t)) {}
}
class E extends D implements C<int> {}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);
    var cAdd = AstFinder.getMethodInClass(unit, "C", "add");
    var covariantC = getClassCovariantParameters(AstFinder.getClass(unit, "C"));
    expect(covariantC.toList(), [cAdd.declaredElement.parameters[0]]);

    var dAdd = AstFinder.getMethodInClass(unit, "D", "add");
    var covariantD = getClassCovariantParameters(AstFinder.getClass(unit, "D"));
    expect(covariantD, null);

    var classE = AstFinder.getClass(unit, "E");
    var covariantE = getClassCovariantParameters(classE);
    var superCovariantE = getSuperclassCovariantParameters(classE);
    expect(covariantE.toList(), []);
    expect(superCovariantE.toList(), [dAdd.declaredElement.parameters[0]]);
  }

  test_factoryConstructor_propagation() async {
    String code = r'''
      class A<T> {
        factory A() { return new B(); }
      }
      class B<S> extends A<S> {}
   ''';
    CompilationUnit unit = await resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    BlockFunctionBody body = constructor.body;
    ReturnStatement stmt = body.block.statements[0];
    InstanceCreationExpression exp = stmt.expression;
    ClassElement elementB = AstFinder.getClass(unit, "B").declaredElement;
    ClassElement elementA = AstFinder.getClass(unit, "A").declaredElement;
    expect(exp.constructorName.type.type.element, elementB);
    _isInstantiationOf(_hasElement(elementB))([
      _isType(elementA.typeParameters[0]
          .instantiate(nullabilitySuffix: NullabilitySuffix.star))
    ])(exp.staticType);
  }

  test_fieldDeclaration_propagation() async {
    String code = r'''
      class A {
        List<String> f0 = ["hello"];
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    VariableDeclaration field = AstFinder.getFieldInClass(unit, "A", "f0");

    _isListOf(_isString)(field.initializer.staticType);
  }

  test_functionDeclaration_body_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      List<int> test1() => [];

      Function2<int, int> test2 (int x) {
        Function2<String, int> inner() {
          return (x) => x.length;
        }
        return (x) => x;
     }
   ''';
    CompilationUnit unit = await resolveSource(code);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    FunctionDeclaration test1 = AstFinder.getTopLevelFunction(unit, "test1");
    ExpressionFunctionBody body = test1.functionExpression.body;
    assertListOfInt(body.expression.staticType);

    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test2");

    FunctionDeclaration inner =
        (statements[0] as FunctionDeclarationStatement).functionDeclaration;
    BlockFunctionBody body0 = inner.functionExpression.body;
    ReturnStatement return0 = body0.block.statements[0];
    Expression anon0 = return0.expression;
    FunctionType type0 = anon0.staticType;
    expect(type0.returnType, typeProvider.intType);
    expect(type0.normalParameterTypes[0], typeProvider.stringType);

    FunctionExpression anon1 = (statements[1] as ReturnStatement).expression;
    FunctionType type1 = anon1.declaredElement.type;
    expect(type1.returnType, typeProvider.intType);
    expect(type1.normalParameterTypes[0], typeProvider.intType);
  }

  test_functionLiteral_assignment_typedArguments() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, String> l0 = (int x) => null;
        Function2<int, String> l1 = (int x) => "hello";
        Function2<int, String> l2 = (String x) => "hello";
        Function2<int, String> l3 = (int x) => 3;
        Function2<int, String> l4 = (int x) {return 3;};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      return exp.declaredElement.type;
    }

    _isFunction2Of(_isInt, _isNull)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_assignment_unTypedArguments() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, String> l0 = (x) => null;
        Function2<int, String> l1 = (x) => "hello";
        Function2<int, String> l2 = (x) => "hello";
        Function2<int, String> l3 = (x) => 3;
        Function2<int, String> l4 = (x) {return 3;};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      return exp.declaredElement.type;
    }

    _isFunction2Of(_isInt, _isNull)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_body_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, List<String>> l0 = (int x) => ["hello"];
        Function2<int, List<String>> l1 = (String x) => ["hello"];
        Function2<int, List<String>> l2 = (int x) => [3];
        Function2<int, List<String>> l3 = (int x) {return [3];};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    Expression functionReturnValue(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      FunctionBody body = exp.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    assertListOfString(functionReturnValue(0).staticType);
    assertListOfString(functionReturnValue(1).staticType);
    assertListOfString(functionReturnValue(2).staticType);
    assertListOfString(functionReturnValue(3).staticType);
  }

  test_functionLiteral_functionExpressionInvocation_typedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        (new Mapper<int, String>().map)((int x) => null);
        (new Mapper<int, String>().map)((int x) => "hello");
        (new Mapper<int, String>().map)((String x) => "hello");
        (new Mapper<int, String>().map)((int x) => 3);
        (new Mapper<int, String>().map)((int x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      FunctionExpressionInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.declaredElement.type;
    }

    _isFunction2Of(_isInt, _isNull)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionExpressionInvocation_unTypedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        (new Mapper<int, String>().map)((x) => null);
        (new Mapper<int, String>().map)((x) => "hello");
        (new Mapper<int, String>().map)((x) => "hello");
        (new Mapper<int, String>().map)((x) => 3);
        (new Mapper<int, String>().map)((x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      FunctionExpressionInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.declaredElement.type;
    }

    _isFunction2Of(_isInt, _isNull)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionInvocation_typedArguments() async {
    String code = r'''
      String map(String mapper(int x)) => mapper(null);

      void main () {
        map((int x) => null);
        map((int x) => "hello");
        map((String x) => "hello");
        map((int x) => 3);
        map((int x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.declaredElement.type;
    }

    _isFunction2Of(_isInt, _isNull)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_functionInvocation_unTypedArguments() async {
    String code = r'''
      String map(String mapper(int x)) => mapper(null);

      void main () {
        map((x) => null);
        map((x) => "hello");
        map((x) => "hello");
        map((x) => 3);
        map((x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.declaredElement.type;
    }

    _isFunction2Of(_isInt, _isNull)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_methodInvocation_typedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        new Mapper<int, String>().map((int x) => null);
        new Mapper<int, String>().map((int x) => "hello");
        new Mapper<int, String>().map((String x) => "hello");
        new Mapper<int, String>().map((int x) => 3);
        new Mapper<int, String>().map((int x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.declaredElement.type;
    }

    _isFunction2Of(_isInt, _isNull)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isString, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_methodInvocation_unTypedArguments() async {
    String code = r'''
      class Mapper<F, T> {
        T map(T mapper(F x)) => mapper(null);
      }

      void main () {
        new Mapper<int, String>().map((x) => null);
        new Mapper<int, String>().map((x) => "hello");
        new Mapper<int, String>().map((x) => "hello");
        new Mapper<int, String>().map((x) => 3);
        new Mapper<int, String>().map((x) {return 3;});
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      ExpressionStatement stmt = statements[i];
      MethodInvocation invk = stmt.expression;
      FunctionExpression exp = invk.argumentList.arguments[0];
      return exp.declaredElement.type;
    }

    _isFunction2Of(_isInt, _isNull)(literal(0));
    _isFunction2Of(_isInt, _isString)(literal(1));
    _isFunction2Of(_isInt, _isString)(literal(2));
    _isFunction2Of(_isInt, _isString)(literal(3));
    _isFunction2Of(_isInt, _isString)(literal(4));
  }

  test_functionLiteral_unTypedArgument_propagation() async {
    String code = r'''
      typedef T Function2<S, T>(S x);

      void main () {
        Function2<int, int> l0 = (x) => x;
        Function2<int, int> l1 = (x) => x+1;
        Function2<int, String> l2 = (x) => x;
        Function2<int, String> l3 = (x) => x.toLowerCase();
        Function2<String, String> l4 = (x) => x.toLowerCase();
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    Expression functionReturnValue(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      FunctionExpression exp = decl.initializer;
      FunctionBody body = exp.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }

    expect(functionReturnValue(0).staticType, typeProvider.intType);
    expect(functionReturnValue(1).staticType, typeProvider.intType);
    expect(functionReturnValue(2).staticType, typeProvider.intType);
    expect(functionReturnValue(3).staticType, typeProvider.dynamicType);
    expect(functionReturnValue(4).staticType, typeProvider.stringType);
  }

  test_futureOr_assignFromFuture() async {
    // Test a Future<T> can be assigned to FutureOr<T>.
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOrOfInt(invoke.staticType);
  }

  test_futureOr_assignFromValue() async {
    // Test a T can be assigned to FutureOr<T>.
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(T x) => x;
    test() => mk(42);
    ''');
    _isFutureOrOfInt(invoke.staticType);
  }

  test_futureOr_asyncExpressionBody() async {
    // A FutureOr<T> can be used as the expression body for an async function
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async => x;
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_asyncReturn() async {
    // A FutureOr<T> can be used as the return value for an async function
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async { return x; }
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_await() async {
    // Test a FutureOr<T> can be awaited.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) async => await x;
    test() => mk(42);
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_downwards1() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    Future<int> test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_downwards2() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters when the downwards context is FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<int> test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_downwards3() async {
    // Test that downwards inference correctly propogates into
    // arguments.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    Future<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards4() async {
    // Test that downwards inference interacts correctly with FutureOr
    // parameters when the downwards context is FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards5() async {
    // Test that downwards inference correctly pins the type when it
    // comes from a FutureOr
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    FutureOr<num> test() => mk(new Future.value(42));
    ''');
    _isFutureOf([_isNum])(invoke.staticType);
    _isFutureOf([_isNum])(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards6() async {
    // Test that downwards inference doesn't decompose FutureOr
    // when instantiating type variables.
    MethodInvocation invoke = await _testFutureOr(r'''
    T mk<T>(T x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOrOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards7() async {
    // Test that downwards inference incorporates bounds correctly
    // when instantiating type variables.
    MethodInvocation invoke = await _testFutureOr(r'''
      T mk<T extends Future<int>>(T x) => null;
      FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards8() async {
    // Test that downwards inference incorporates bounds correctly
    // when instantiating type variables.
    // TODO(leafp): I think this should pass once the inference changes
    // that jmesserly is adding are landed.
    MethodInvocation invoke = await _testFutureOr(r'''
    T mk<T extends Future<Object>>(T x) => null;
    FutureOr<int> test() => mk(new Future.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
    _isFutureOfInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_downwards9() async {
    // Test that downwards inference decomposes correctly with
    // other composite types
    MethodInvocation invoke = await _testFutureOr(r'''
    List<T> mk<T>(T x) => null;
    FutureOr<List<int>> test() => mk(3);
    ''');
    _isListOf(_isInt)(invoke.staticType);
    _isInt(invoke.argumentList.arguments[0].staticType);
  }

  test_futureOr_methods1() async {
    // Test that FutureOr has the Object methods
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<int> x) => x.toString();
    ''');
    _isString(invoke.staticType);
  }

  test_futureOr_methods2() async {
    // Test that FutureOr does not have the constituent type methods
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<int> x) => x.abs();
    ''', errors: [StaticTypeWarningCode.UNDEFINED_METHOD]);
    _isDynamic(invoke.staticType);
  }

  test_futureOr_methods3() async {
    // Test that FutureOr does not have the Future type methods
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<int> x) => x.then((x) => x);
    ''', errors: [StaticTypeWarningCode.UNDEFINED_METHOD]);
    _isDynamic(invoke.staticType);
  }

  test_futureOr_methods4() async {
    // Test that FutureOr<dynamic> does not have all methods
    MethodInvocation invoke = await _testFutureOr(r'''
    dynamic test(FutureOr<dynamic> x) => x.abs();
    ''', errors: [StaticTypeWarningCode.UNDEFINED_METHOD]);
    _isDynamic(invoke.staticType);
  }

  test_futureOr_no_return() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOr_no_return_value() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {return;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOr_return_null() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then((int x) {return null;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOr_upwards1() async {
    // Test that upwards inference correctly prefers to instantiate type
    // variables with the "smaller" solution when both are possible.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T>(FutureOr<T> x) => null;
    dynamic test() => mk(new Future<int>.value(42));
    ''');
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOr_upwards2() async {
    // Test that upwards inference fails when the solution doesn't
    // match the bound.
    MethodInvocation invoke = await _testFutureOr(r'''
    Future<T> mk<T extends Future<Object>>(FutureOr<T> x) => null;
    dynamic test() => mk(new Future<int>.value(42));
    ''', errors: [StrongModeCode.COULD_NOT_INFER]);
    _isFutureOfInt(invoke.staticType);
  }

  test_futureOrNull_no_return() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) {});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOrNull_no_return_value() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) {return;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_futureOrNull_return_null() async {
    MethodInvocation invoke = await _testFutureOr(r'''
    FutureOr<T> mk<T>(Future<T> x) => x;
    Future<int> f;
    test() => f.then<Null>((int x) { return null;});
    ''');
    _isFunction2Of(_isInt, _isNull)(
        invoke.argumentList.arguments[0].staticType);
    _isFutureOfNull(invoke.staticType);
  }

  test_generic_partial() async {
    // Test that upward and downward type inference handles partial
    // type schemas correctly.  Downwards inference in a partial context
    // (e.g. Map<String, ?>) should still allow upwards inference to fill
    // in the missing information.
    String code = r'''
class A<T> {
  A(T x);
  A.fromA(A<T> a) {}
  A.fromMap(Map<String, T> m) {}
  A.fromList(List<T> m) {}
  A.fromT(T t) {}
  A.fromB(B<T, String> a) {}
}

class B<S, T> {
  B(S s);
}

void test() {
    var a0 = new A.fromA(new A(3));
    var a1 = new A.fromMap({'hello' : 3});
    var a2 = new A.fromList([3]);
    var a3 = new A.fromT(3);
    var a4 = new A.fromB(new B(3));
}
   ''';
    CompilationUnit unit = await resolveSource(code);
    Element elementA = AstFinder.getClass(unit, "A").declaredElement;
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "test");
    void check(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      Expression init = decl.initializer;
      _isInstantiationOf(_hasElement(elementA))([_isInt])(init.staticType);
    }

    for (var i = 0; i < 5; i++) check(i);
  }

  test_inferConstructor_unknownTypeLowerBound() async {
    Source source = addSource(r'''
        class C<T> {
          C(void callback(List<T> a));
        }
        test() {
          // downwards inference pushes List<?> and in parameter position this
          // becomes inferred as List<Null>.
          var c = new C((items) {});
        }
        ''');
    CompilationUnit unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);
    verify([source]);
    DartType cType = findLocalVariable(unit, 'c').type;
    Element elementC = AstFinder.getClass(unit, "C").declaredElement;

    _isInstantiationOf(_hasElement(elementC))([_isDynamic])(cType);
  }

  test_inference_error_arguments() async {
    Source source = addSource(r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(F<T, T> f) => (x) => f(f(x));

test() {
  var h = g((int x) => 42.0);
}
 ''');
    await computeAnalysisResult(source);
    _expectInferenceError(source, [
      StrongModeCode.COULD_NOT_INFER,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ], r'''
Couldn't infer type parameter 'T'.

Tried to infer 'double' for 'T' which doesn't work:
  Parameter 'f' declared as     'T Function(T)'
                but argument is 'double Function(int)'.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_error_arguments2() async {
    Source source = addSource(r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(F<T, T> a, F<T, T> b) => (x) => a(b(x));

test() {
  var h = g((int x) => 42.0, (double x) => 42);
}
 ''');
    await computeAnalysisResult(source);
    _expectInferenceError(source, [
      StrongModeCode.COULD_NOT_INFER,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ], r'''
Couldn't infer type parameter 'T'.

Tried to infer 'num' for 'T' which doesn't work:
  Parameter 'a' declared as     'T Function(T)'
                but argument is 'double Function(int)'.
  Parameter 'b' declared as     'T Function(T)'
                but argument is 'int Function(double)'.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_error_extendsFromReturn() async {
    // This is not an inference error because we successfully infer Null.
    Source source = addSource(r'''
T max<T extends num>(T x, T y) => x;

test() {
  String hello = max(1, 2);
}
 ''');
    var analysisResult = await computeAnalysisResult(source);
    assertErrors(source, [
      StrongModeCode.INVALID_CAST_LITERAL,
      StrongModeCode.INVALID_CAST_LITERAL
    ]);
    var unit = analysisResult.unit;
    var h = (AstFinder.getStatementsInTopLevelFunction(unit, "test")[0]
            as VariableDeclarationStatement)
        .variables
        .variables[0];
    var call = h.initializer as MethodInvocation;
    expect(call.staticInvokeType.toString(), 'Null Function(Null, Null)');
  }

  test_inference_error_extendsFromReturn2() async {
    Source source = addSource(r'''
typedef R F<T, R>(T t);
F<T, T> g<T extends num>() => (y) => y;

test() {
  F<String, String> hello = g();
}
 ''');
    await computeAnalysisResult(source);
    _expectInferenceError(source, [
      StrongModeCode.COULD_NOT_INFER,
    ], r'''
Couldn't infer type parameter 'T'.

Tried to infer 'String' for 'T' which doesn't work:
  Type parameter 'T' declared to extend 'num'.
The type 'String' was inferred from:
  Return type declared as 'T Function(T)'
              used where  'String Function(String)' is required.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_error_genericFunction() async {
    Source source = addSource(r'''
T max<T extends num>(T x, T y) => x < y ? y : x;
abstract class Iterable<T> {
  T get first;
  S fold<S>(S s, S f(S s, T t));
}
test(Iterable values) {
  num n = values.fold(values.first as num, max);
}
 ''');
    await computeAnalysisResult(source);
    _expectInferenceError(source, [
      StrongModeCode.COULD_NOT_INFER,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ], r'''
Couldn't infer type parameter 'T'.

Tried to infer 'dynamic' for 'T' which doesn't work:
  Function type declared as 'T Function<T extends num>(T, T)'
                used where  'num Function(num, dynamic)' is required.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_error_returnContext() async {
    Source source = addSource(r'''
typedef R F<T, R>(T t);

F<T, T> g<T>(T t) => (x) => t;

test() {
  F<num, int> h = g(42);
}
 ''');
    await computeAnalysisResult(source);
    _expectInferenceError(source, [StrongModeCode.COULD_NOT_INFER], r'''
Couldn't infer type parameter 'T'.

Tried to infer 'num' for 'T' which doesn't work:
  Return type declared as 'T Function(T)'
              used where  'int Function(num)' is required.

Consider passing explicit type argument(s) to the generic.

''');
  }

  test_inference_hints() async {
    Source source = addSource(r'''
      void main () {
        var x = 3;
        List<int> l0 = [];
     }
   ''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inference_simplePolymorphicRecursion_function() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/30980
    // Check that inference works properly when inferring the type argument
    // for a self-recursive call with a function type
    var source = addSource(r'''
void _mergeSort<T>(T Function(T) list, int compare(T a, T b), T Function(T) target) {
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    var unit = analysisResult.unit;
    var body = (AstFinder.getTopLevelFunction(unit, '_mergeSort')
        .functionExpression
        .body as BlockFunctionBody);
    var stmts = body.block.statements;
    for (ExpressionStatement stmt in stmts) {
      MethodInvocation invoke = stmt.expression;
      FunctionType fType = invoke.staticInvokeType;
      expect('$fType',
          'void Function(T Function(T), int Function(T, T), T Function(T))');
    }
  }

  test_inference_simplePolymorphicRecursion_interface() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/30980
    // Check that inference works properly when inferring the type argument
    // for a self-recursive call with an interface type
    var source = addSource(r'''
void _mergeSort<T>(List<T> list, int compare(T a, T b), List<T> target) {
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    var unit = analysisResult.unit;
    var body = (AstFinder.getTopLevelFunction(unit, '_mergeSort')
        .functionExpression
        .body as BlockFunctionBody);
    var stmts = body.block.statements;
    for (ExpressionStatement stmt in stmts) {
      MethodInvocation invoke = stmt.expression;
      FunctionType fType = invoke.staticInvokeType;
      expect('$fType', 'void Function(List<T>, int Function(T, T), List<T>)');
    }
  }

  test_inference_simplePolymorphicRecursion_simple() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/30980
    // Check that inference works properly when inferring the type argument
    // for a self-recursive call with a simple type parameter
    var source = addSource(r'''
void _mergeSort<T>(T list, int compare(T a, T b), T target) {
  _mergeSort(list, compare, target);
  _mergeSort(list, compare, list);
  _mergeSort(target, compare, target);
  _mergeSort(target, compare, list);
}
    ''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    var unit = analysisResult.unit;
    var body = (AstFinder.getTopLevelFunction(unit, '_mergeSort')
        .functionExpression
        .body as BlockFunctionBody);
    var stmts = body.block.statements;
    for (ExpressionStatement stmt in stmts) {
      MethodInvocation invoke = stmt.expression;
      FunctionType fType = invoke.staticInvokeType;
      expect('$fType', 'void Function(T, int Function(T, T), T)');
    }
  }

  test_inferGenericInstantiation() async {
    // Verify that we don't infer '?` when we instantiate a generic function.
    var source = addSource(r'''
T f<T>(T x(T t)) => x(null);
S g<S>(S s) => s;
test() {
 var h = f(g);
}
    ''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    var unit = analysisResult.unit;
    var h = (AstFinder.getStatementsInTopLevelFunction(unit, "test")[0]
            as VariableDeclarationStatement)
        .variables
        .variables[0];
    _isDynamic(h.declaredElement.type);
    var fCall = h.initializer as MethodInvocation;
    expect(fCall.staticInvokeType.toString(),
        'dynamic Function(dynamic Function(dynamic))');
    var g = fCall.argumentList.arguments[0];
    expect(g.staticType.toString(), 'dynamic Function(dynamic)');
  }

  test_inferGenericInstantiation2() async {
    // Verify the behavior when we cannot infer an instantiation due to invalid
    // constraints from an outer generic method.
    var source = addSource(r'''
T max<T extends num>(T x, T y) => x < y ? y : x;
abstract class Iterable<T> {
  T get first;
  S fold<S>(S s, S f(S s, T t));
}
num test(Iterable values) => values.fold(values.first as num, max);
    ''');
    var analysisResult = await computeAnalysisResult(source);
    assertErrors(source, [
      StrongModeCode.COULD_NOT_INFER,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
    var unit = analysisResult.unit;
    var fold = (AstFinder.getTopLevelFunction(unit, 'test')
            .functionExpression
            .body as ExpressionFunctionBody)
        .expression as MethodInvocation;
    expect(fold.staticInvokeType.toString(),
        'num Function(num, num Function(num, dynamic))');
    var max = fold.argumentList.arguments[1];
    // TODO(jmesserly): arguably num Function(num, num) is better here.
    expect(max.staticType.toString(), 'dynamic Function(dynamic, dynamic)');
  }

  test_inferredFieldDeclaration_propagation() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25546
    String code = r'''
      abstract class A {
        Map<int, List<int>> get map;
      }
      class B extends A {
        var map = { 42: [] };
      }
      class C extends A {
        get map => { 43: [] };
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertMapOfIntToListOfInt =
        _isMapOf(_isInt, (DartType type) => assertListOfInt(type));

    VariableDeclaration mapB = AstFinder.getFieldInClass(unit, "B", "map");
    MethodDeclaration mapC = AstFinder.getMethodInClass(unit, "C", "map");
    assertMapOfIntToListOfInt(mapB.declaredElement.type);
    assertMapOfIntToListOfInt(mapC.declaredElement.returnType);

    SetOrMapLiteral mapLiteralB = mapB.initializer;
    SetOrMapLiteral mapLiteralC =
        (mapC.body as ExpressionFunctionBody).expression;
    assertMapOfIntToListOfInt(mapLiteralB.staticType);
    assertMapOfIntToListOfInt(mapLiteralC.staticType);

    ListLiteral listLiteralB =
        (mapLiteralB.elements[0] as MapLiteralEntry).value;
    ListLiteral listLiteralC =
        (mapLiteralC.elements[0] as MapLiteralEntry).value;
    assertListOfInt(listLiteralB.staticType);
    assertListOfInt(listLiteralC.staticType);
  }

  test_instanceCreation() async {
    String code = r'''
      class A<S, T> {
        S x;
        T y;
        A(this.x, this.y);
        A.named(this.x, this.y);
      }

      class B<S, T> extends A<T, S> {
        B(S y, T x) : super(x, y);
        B.named(S y, T x) : super.named(x, y);
      }

      class C<S> extends B<S, S> {
        C(S a) : super(a, a);
        C.named(S a) : super.named(a, a);
      }

      class D<S, T> extends B<T, int> {
        D(T a) : super(a, 3);
        D.named(T a) : super.named(a, 3);
      }

      class E<S, T> extends A<C<S>, T> {
        E(T a) : super(null, a);
      }

      class F<S, T> extends A<S, T> {
        F(S x, T y, {List<S> a, List<T> b}) : super(x, y);
        F.named(S x, T y, [S a, T b]) : super(a, b);
      }

      void test0() {
        A<int, String> a0 = new A(3, "hello");
        A<int, String> a1 = new A.named(3, "hello");
        A<int, String> a2 = new A<int, String>(3, "hello");
        A<int, String> a3 = new A<int, String>.named(3, "hello");
        A<int, String> a4 = new A<int, dynamic>(3, "hello");
        A<int, String> a5 = new A<dynamic, dynamic>.named(3, "hello");
      }
      void test1()  {
        A<int, String> a0 = new A("hello", 3);
        A<int, String> a1 = new A.named("hello", 3);
      }
      void test2() {
        A<int, String> a0 = new B("hello", 3);
        A<int, String> a1 = new B.named("hello", 3);
        A<int, String> a2 = new B<String, int>("hello", 3);
        A<int, String> a3 = new B<String, int>.named("hello", 3);
        A<int, String> a4 = new B<String, dynamic>("hello", 3);
        A<int, String> a5 = new B<dynamic, dynamic>.named("hello", 3);
      }
      void test3() {
        A<int, String> a0 = new B(3, "hello");
        A<int, String> a1 = new B.named(3, "hello");
      }
      void test4() {
        A<int, int> a0 = new C(3);
        A<int, int> a1 = new C.named(3);
        A<int, int> a2 = new C<int>(3);
        A<int, int> a3 = new C<int>.named(3);
        A<int, int> a4 = new C<dynamic>(3);
        A<int, int> a5 = new C<dynamic>.named(3);
      }
      void test5() {
        A<int, int> a0 = new C("hello");
        A<int, int> a1 = new C.named("hello");
      }
      void test6()  {
        A<int, String> a0 = new D("hello");
        A<int, String> a1 = new D.named("hello");
        A<int, String> a2 = new D<int, String>("hello");
        A<int, String> a3 = new D<String, String>.named("hello");
        A<int, String> a4 = new D<num, dynamic>("hello");
        A<int, String> a5 = new D<dynamic, dynamic>.named("hello");
      }
      void test7() {
        A<int, String> a0 = new D(3);
        A<int, String> a1 = new D.named(3);
      }
      void test8() {
        A<C<int>, String> a0 = new E("hello");
      }
      void test9() { // Check named and optional arguments
        A<int, String> a0 = new F(3, "hello", a: [3], b: ["hello"]);
        A<int, String> a1 = new F(3, "hello", a: ["hello"], b:[3]);
        A<int, String> a2 = new F.named(3, "hello", 3, "hello");
        A<int, String> a3 = new F.named(3, "hello");
        A<int, String> a4 = new F.named(3, "hello", "hello", 3);
        A<int, String> a5 = new F.named(3, "hello", "hello");
      }''';
    CompilationUnit unit = await resolveSource(code);

    Expression rhs(VariableDeclarationStatement stmt) {
      VariableDeclaration decl = stmt.variables.variables[0];
      Expression exp = decl.initializer;
      return exp;
    }

    void hasType(Asserter<DartType> assertion, Expression exp) =>
        assertion(exp.staticType);

    Element elementA = AstFinder.getClass(unit, "A").declaredElement;
    Element elementB = AstFinder.getClass(unit, "B").declaredElement;
    Element elementC = AstFinder.getClass(unit, "C").declaredElement;
    Element elementD = AstFinder.getClass(unit, "D").declaredElement;
    Element elementE = AstFinder.getClass(unit, "E").declaredElement;
    Element elementF = AstFinder.getClass(unit, "F").declaredElement;

    AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf =
        _isInstantiationOf(_hasElement(elementA));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf =
        _isInstantiationOf(_hasElement(elementB));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertCOf =
        _isInstantiationOf(_hasElement(elementC));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertDOf =
        _isInstantiationOf(_hasElement(elementD));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf =
        _isInstantiationOf(_hasElement(elementE));
    AsserterBuilder<List<Asserter<DartType>>, DartType> assertFOf =
        _isInstantiationOf(_hasElement(elementF));

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test0");

      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[3]));
      hasType(assertAOf([_isInt, _isDynamic]), rhs(statements[4]));
      hasType(assertAOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test1");
      hasType(assertAOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertAOf([_isInt, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test2");
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[2]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[3]));
      hasType(assertBOf([_isString, _isDynamic]), rhs(statements[4]));
      hasType(assertBOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test3");
      hasType(assertBOf([_isString, _isInt]), rhs(statements[0]));
      hasType(assertBOf([_isString, _isInt]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test4");
      hasType(assertCOf([_isInt]), rhs(statements[0]));
      hasType(assertCOf([_isInt]), rhs(statements[1]));
      hasType(assertCOf([_isInt]), rhs(statements[2]));
      hasType(assertCOf([_isInt]), rhs(statements[3]));
      hasType(assertCOf([_isDynamic]), rhs(statements[4]));
      hasType(assertCOf([_isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test5");
      hasType(assertCOf([_isInt]), rhs(statements[0]));
      hasType(assertCOf([_isInt]), rhs(statements[1]));
    }

    {
      // The first type parameter is not constrained by the
      // context.  We could choose a tighter type, but currently
      // we just use dynamic.
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test6");
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
      hasType(assertDOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertDOf([_isString, _isString]), rhs(statements[3]));
      hasType(assertDOf([_isNum, _isDynamic]), rhs(statements[4]));
      hasType(assertDOf([_isDynamic, _isDynamic]), rhs(statements[5]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test7");
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[0]));
      hasType(assertDOf([_isDynamic, _isString]), rhs(statements[1]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test8");
      hasType(assertEOf([_isInt, _isString]), rhs(statements[0]));
    }

    {
      List<Statement> statements =
          AstFinder.getStatementsInTopLevelFunction(unit, "test9");
      hasType(assertFOf([_isInt, _isString]), rhs(statements[0]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[1]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[2]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[3]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[4]));
      hasType(assertFOf([_isInt, _isString]), rhs(statements[5]));
    }
  }

  test_listLiteral_nested() async {
    String code = r'''
      void main () {
        List<List<int>> l0 = [[]];
        Iterable<List<int>> l1 = [[3]];
        Iterable<List<int>> l2 = [[3], [4]];
        List<List<int>> l3 = [["hello", 3], []];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    ListLiteral literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);
    Asserter<InterfaceType> assertListOfListOfInt =
        _isListOf((DartType type) => assertListOfInt(type));

    assertListOfListOfInt(literal(0).staticType);
    assertListOfListOfInt(literal(1).staticType);
    assertListOfListOfInt(literal(2).staticType);
    assertListOfListOfInt(literal(3).staticType);

    assertListOfInt((literal(1).elements[0] as Expression).staticType);
    assertListOfInt((literal(2).elements[0] as Expression).staticType);
    assertListOfInt((literal(3).elements[0] as Expression).staticType);
  }

  test_listLiteral_simple() async {
    String code = r'''
      void main () {
        List<int> l0 = [];
        List<int> l1 = [3];
        List<int> l2 = ["hello"];
        List<int> l3 = ["hello", 3];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  test_listLiteral_simple_const() async {
    String code = r'''
      void main () {
        const List<int> c0 = const [];
        const List<int> c1 = const [3];
        const List<int> c2 = const ["hello"];
        const List<int> c3 = const ["hello", 3];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  test_listLiteral_simple_disabled() async {
    String code = r'''
      void main () {
        List<int> l0 = <num>[];
        List<int> l1 = <num>[3];
        List<int> l2 = <String>["hello"];
        List<int> l3 = <dynamic>["hello", 3];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    _isListOf(_isNum)(literal(0));
    _isListOf(_isNum)(literal(1));
    _isListOf(_isString)(literal(2));
    _isListOf(_isDynamic)(literal(3));
  }

  test_listLiteral_simple_subtype() async {
    String code = r'''
      void main () {
        Iterable<int> l0 = [];
        Iterable<int> l1 = [3];
        Iterable<int> l2 = ["hello"];
        Iterable<int> l3 = ["hello", 3];
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      ListLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertListOfInt = _isListOf(_isInt);

    assertListOfInt(literal(0));
    assertListOfInt(literal(1));
    assertListOfInt(literal(2));
    assertListOfInt(literal(3));
  }

  test_mapLiteral_nested() async {
    String code = r'''
      void main () {
        Map<int, List<String>> l0 = {};
        Map<int, List<String>> l1 = {3: ["hello"]};
        Map<int, List<String>> l2 = {"hello": ["hello"]};
        Map<int, List<String>> l3 = {3: [3]};
        Map<int, List<String>> l4 = {3:["hello"], "hello": [3]};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    SetOrMapLiteral literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      SetOrMapLiteral exp = decl.initializer;
      return exp;
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    Asserter<InterfaceType> assertMapOfIntToListOfString =
        _isMapOf(_isInt, (DartType type) => assertListOfString(type));

    assertMapOfIntToListOfString(literal(0).staticType);
    assertMapOfIntToListOfString(literal(1).staticType);
    assertMapOfIntToListOfString(literal(2).staticType);
    assertMapOfIntToListOfString(literal(3).staticType);
    assertMapOfIntToListOfString(literal(4).staticType);

    assertListOfString(
        (literal(1).elements[0] as MapLiteralEntry).value.staticType);
    assertListOfString(
        (literal(2).elements[0] as MapLiteralEntry).value.staticType);
    assertListOfString(
        (literal(3).elements[0] as MapLiteralEntry).value.staticType);
    assertListOfString(
        (literal(4).elements[0] as MapLiteralEntry).value.staticType);
  }

  test_mapLiteral_simple() async {
    String code = r'''
      void main () {
        Map<int, String> l0 = {};
        Map<int, String> l1 = {3: "hello"};
        Map<int, String> l2 = {"hello": "hello"};
        Map<int, String> l3 = {3: 3};
        Map<int, String> l4 = {3:"hello", "hello": 3};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      SetOrMapLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertMapOfIntToString =
        _isMapOf(_isInt, _isString);

    assertMapOfIntToString(literal(0));
    assertMapOfIntToString(literal(1));
    assertMapOfIntToString(literal(2));
    assertMapOfIntToString(literal(3));
  }

  test_mapLiteral_simple_disabled() async {
    String code = r'''
      void main () {
        Map<int, String> l0 = <int, dynamic>{};
        Map<int, String> l1 = <int, dynamic>{3: "hello"};
        Map<int, String> l2 = <int, dynamic>{"hello": "hello"};
        Map<int, String> l3 = <int, dynamic>{3: 3};
     }
   ''';
    CompilationUnit unit = await resolveSource(code);
    List<Statement> statements =
        AstFinder.getStatementsInTopLevelFunction(unit, "main");
    DartType literal(int i) {
      VariableDeclarationStatement stmt = statements[i];
      VariableDeclaration decl = stmt.variables.variables[0];
      SetOrMapLiteral exp = decl.initializer;
      return exp.staticType;
    }

    Asserter<InterfaceType> assertMapOfIntToDynamic =
        _isMapOf(_isInt, _isDynamic);

    assertMapOfIntToDynamic(literal(0));
    assertMapOfIntToDynamic(literal(1));
    assertMapOfIntToDynamic(literal(2));
    assertMapOfIntToDynamic(literal(3));
  }

  test_methodDeclaration_body_propagation() async {
    String code = r'''
      class A {
        List<String> m0(int x) => ["hello"];
        List<String> m1(int x) {return [3];}
      }
   ''';
    CompilationUnit unit = await resolveSource(code);
    Expression methodReturnValue(String methodName) {
      MethodDeclaration method =
          AstFinder.getMethodInClass(unit, "A", methodName);
      FunctionBody body = method.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else {
        Statement stmt = (body as BlockFunctionBody).block.statements[0];
        return (stmt as ReturnStatement).expression;
      }
    }

    Asserter<InterfaceType> assertListOfString = _isListOf(_isString);
    assertListOfString(methodReturnValue("m0").staticType);
    assertListOfString(methodReturnValue("m1").staticType);
  }

  test_partialTypes1() async {
    // Test that downwards inference with a partial type
    // correctly uses the partial information to fill in subterm
    // types
    String code = r'''
    typedef To Func1<From, To>(From x);
    S f<S, T>(Func1<S, T> g) => null;
    String test() => f((l) => l.length);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    _isString(body.expression.staticType);
    MethodInvocation invoke = body.expression;
    FunctionExpression function = invoke.argumentList.arguments[0];
    ExecutableElement f0 = function.declaredElement;
    FunctionType type = f0.type;
    _isFunction2Of(_isString, _isInt)(type);
  }

  test_pinning_multipleConstraints1() async {
    // Test that downwards inference with two different downwards covariant
    // constraints on the same parameter correctly fails to infer when
    // the types do not share a common subtype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<int, String> test() => new B(3);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.INVALID_CAST_LITERAL]);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    DartType type = body.expression.staticType;

    Element elementB = AstFinder.getClass(unit, "B").declaredElement;

    _isInstantiationOf(_hasElement(elementB))([_isNull])(type);
  }

  test_pinning_multipleConstraints2() async {
    // Test that downwards inference with two identical downwards covariant
    // constraints on the same parameter correctly infers and pins the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<num, num> test() => new B(3);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    DartType type = body.expression.staticType;

    Element elementB = AstFinder.getClass(unit, "B").declaredElement;

    _isInstantiationOf(_hasElement(elementB))([_isNum])(type);
  }

  test_pinning_multipleConstraints3() async {
    // Test that downwards inference with two different downwards covariant
    // constraints on the same parameter correctly fails to infer when
    // the types do not share a common subtype, but do share a common supertype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> { B(S s); }
    A<int, double> test() => new B(3);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertErrors(source, [
      StrongModeCode.INVALID_CAST_LITERAL,
    ]);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    DartType type = body.expression.staticType;

    Element elementB = AstFinder.getClass(unit, "B").declaredElement;

    _isInstantiationOf(_hasElement(elementB))([_isNull])(type);
  }

  test_pinning_multipleConstraints4() async {
    // Test that downwards inference with two subtype related downwards
    // covariant constraints on the same parameter correctly infers and pins
    // the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    A<int, num> test() => new B();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    DartType type = body.expression.staticType;

    Element elementB = AstFinder.getClass(unit, "B").declaredElement;

    _isInstantiationOf(_hasElement(elementB))([_isInt])(type);
  }

  test_pinning_multipleConstraints_contravariant1() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter chooses the upper bound
    // when the only supertype is Object
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, String>> test() => mkA();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").declaredElement;

    _isInstantiationOf(_hasElement(elementA))([_isObject, _isObject])(type);
  }

  test_pinning_multipleConstraints_contravariant2() async {
    // Test that downwards inference with two identical downwards contravariant
    // constraints on the same parameter correctly pins the type
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<num, num>> test() => mkA();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").declaredElement;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_pinning_multipleConstraints_contravariant3() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter correctly choose the least upper bound
    // when they share a common supertype
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, double>> test() => mkA();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").declaredElement;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_pinning_multipleConstraints_contravariant4() async {
    // Test that downwards inference with two different downwards contravariant
    // constraints on the same parameter correctly choose the least upper bound
    // when one is a subtype of the other
    String code = r'''
    class A<S, T> {
      S s;
      T t;
    }
    class B<S> extends A<S, S> {}
    typedef void Contra1<T>(T x);
    Contra1<A<S, S>> mkA<S>() => (A<S, S> x) {};
    Contra1<A<int, num>> test() => mkA();
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];

    Element elementA = AstFinder.getClass(unit, "A").declaredElement;

    _isInstantiationOf(_hasElement(elementA))([_isNum, _isNum])(type);
  }

  test_redirectedConstructor_named() async {
    Source source = addSource(r'''
class A<T, U> implements B<T, U> {
  A.named();
}

class B<T2, U2> {
  factory B() = A.named;
}
   ''');
    TestAnalysisResult result = await computeAnalysisResult(source);
    assertNoErrors(source);

    ClassDeclaration b = result.unit.declarations[1];
    ConstructorDeclaration bConstructor = b.members[0];
    ConstructorName redirected = bConstructor.redirectedConstructor;

    TypeName typeName = redirected.type;
    expect(typeName.type.toString(), 'A<T2, U2>');
    expect(typeName.type.toString(), 'A<T2, U2>');

    var constructorMember = redirected.staticElement;
    expect(constructorMember.toString(), 'A<T2, U2> A.named()');
    expect(redirected.name.staticElement, constructorMember);
  }

  test_redirectedConstructor_self() async {
    Source source = addSource(r'''
class A<T> {
  A();
  factory A.redirected() = A;
}
   ''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_redirectedConstructor_unnamed() async {
    Source source = addSource(r'''
class A<T, U> implements B<T, U> {
  A();
}

class B<T2, U2> {
  factory B() = A;
}
   ''');
    TestAnalysisResult result = await computeAnalysisResult(source);
    assertNoErrors(source);

    ClassDeclaration b = result.unit.declarations[1];
    ConstructorDeclaration bConstructor = b.members[0];
    ConstructorName redirected = bConstructor.redirectedConstructor;

    TypeName typeName = redirected.type;
    expect(typeName.type.toString(), 'A<T2, U2>');
    expect(typeName.type.toString(), 'A<T2, U2>');

    expect(redirected.name, isNull);
    expect(redirected.staticElement.toString(), 'A<T2, U2> A()');
  }

  test_redirectingConstructor_propagation() async {
    String code = r'''
      class A {
        A() : this.named([]);
        A.named(List<String> x);
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    RedirectingConstructorInvocation invocation = constructor.initializers[0];
    Expression exp = invocation.argumentList.arguments[0];
    _isListOf(_isString)(exp.staticType);
  }

  test_returnType_variance1() async {
    // Check that downwards inference correctly pins a type parameter
    // when the parameter is constrained in a contravariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x) => null;
    Func1<num, String> test() => f(42);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    MethodInvocation invoke = body.expression;
    _isFunction2Of(_isNum, _isFunction2Of(_isNum, _isString))(
        invoke.staticInvokeType);
  }

  test_returnType_variance2() async {
    // Check that downwards inference correctly pins a type parameter
    // when the parameter is constrained in a covariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x) => null;
    Func1<String, num> test() => f(42);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    MethodInvocation invoke = body.expression;
    _isFunction2Of(_isNum, _isFunction2Of(_isString, _isNum))(
        invoke.staticInvokeType);
  }

  test_returnType_variance3() async {
    // Check that the variance heuristic chooses the most precise type
    // when the return type uses the variable in a contravariant position
    // and there is no downwards constraint.
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x, g(T x)) => null;
    dynamic test() => f(42, (num x) => x);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.normalParameterTypes[0];
    _isInt(type);
  }

  test_returnType_variance4() async {
    // Check that the variance heuristic chooses the more precise type
    // when the return type uses the variable in a covariant position
    // and there is no downwards constraint
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x, g(T x)) => null;
    dynamic test() => f(42, (num x) => x);
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    FunctionType functionType = body.expression.staticType;
    DartType type = functionType.returnType;
    _isInt(type);
  }

  test_returnType_variance5() async {
    // Check that pinning works correctly with a partial type
    // when the return type uses the variable in a contravariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<T, String> f<T>(T x) => null;
    T g<T, S>(Func1<T, S> f) => null;
    num test() => g(f(3));
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    MethodInvocation call = body.expression;
    _isNum(call.staticType);
    _isFunction2Of(_isFunction2Of(_isNum, _isString), _isNum)(
        call.staticInvokeType);
  }

  test_returnType_variance6() async {
    // Check that pinning works correctly with a partial type
    // when the return type uses the variable in a covariant position
    String code = r'''
    typedef To Func1<From, To>(From x);
    Func1<String, T> f<T>(T x) => null;
    T g<T, S>(Func1<S, T> f) => null;
    num test() => g(f(3));
   ''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    MethodInvocation call = body.expression;
    _isNum(call.staticType);
    _isFunction2Of(_isFunction2Of(_isString, _isNum), _isNum)(
        call.staticInvokeType);
  }

  test_superConstructorInvocation_propagation() async {
    String code = r'''
      class B {
        B(List<String> p);
      }
      class A extends B {
        A() : super([]);
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    ConstructorDeclaration constructor =
        AstFinder.getConstructorInClass(unit, "A", null);
    SuperConstructorInvocation invocation = constructor.initializers[0];
    Expression exp = invocation.argumentList.arguments[0];
    _isListOf(_isString)(exp.staticType);
  }

  test_sync_star_method_propagation() async {
    String code = r'''
      import "dart:async";
      class A {
        Iterable f0() sync* { yield []; }
        Iterable f1() sync* { yield* new List(); }

        Iterable<List<int>> f2() sync* { yield []; }
        Iterable<List<int>> f3() sync* { yield* new List(); }
      }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      MethodDeclaration test = AstFinder.getMethodInClass(unit, "A", name);
      BlockFunctionBody body = test.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("f0", _isListOf(_isDynamic));
    check("f1", _isListOf(_isDynamic));

    check("f2", _isListOf(_isInt));
    check("f3", _isListOf((DartType type) => _isListOf(_isInt)(type)));
  }

  test_sync_star_propagation() async {
    String code = r'''
      import "dart:async";

      Iterable f0() sync* { yield []; }
      Iterable f1() sync* { yield* new List(); }

      Iterable<List<int>> f2() sync* { yield []; }
      Iterable<List<int>> f3() sync* { yield* new List(); }
   ''';
    CompilationUnit unit = await resolveSource(code);

    void check(String name, Asserter<InterfaceType> typeTest) {
      FunctionDeclaration test = AstFinder.getTopLevelFunction(unit, name);
      BlockFunctionBody body = test.functionExpression.body;
      YieldStatement stmt = body.block.statements[0];
      Expression exp = stmt.expression;
      typeTest(exp.staticType);
    }

    check("f0", _isListOf(_isDynamic));
    check("f1", _isListOf(_isDynamic));

    check("f2", _isListOf(_isInt));
    check("f3", _isListOf((DartType type) => _isListOf(_isInt)(type)));
  }

  /// Verifies the source has the expected [errorCodes] as well as the
  /// expected [errorMessage].
  void _expectInferenceError(
      Source source, List<ErrorCode> errorCodes, String errorMessage) {
    assertErrors(source, errorCodes);
    var errors = analysisResults[source]
        .errors
        .where((e) => e.errorCode == StrongModeCode.COULD_NOT_INFER)
        .map((e) => e.message)
        .toList();
    expect(errors.length, 1);
    var actual = errors[0];
    expect(actual,
        errorMessage, // Print the literal error message for easy copy+paste:
        reason: 'Actual error did not match expected error:\n$actual');
  }

  /// Helper method for testing `FutureOr<T>`.
  ///
  /// Validates that [code] produces [errors]. It should define a function
  /// "test", whose body is an expression that invokes a method. Returns that
  /// invocation.
  Future<MethodInvocation> _testFutureOr(String code,
      {List<ErrorCode> errors}) async {
    Source source = addSource("""
    import "dart:async";
    $code""");
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);

    if (errors == null) {
      assertNoErrors(source);
    } else {
      assertErrors(source, errors);
    }
    verify([source]);
    FunctionDeclaration test =
        AstFinder.getTopLevelFunction(analysisResult.unit, "test");
    ExpressionFunctionBody body = test.functionExpression.body;
    return body.expression;
  }
}

@reflectiveTest
class StrongModeLocalInferenceTest_NNBD extends ResolverTestCase {
  @override
  AnalysisOptions get analysisOptions => new AnalysisOptionsImpl()
    ..contextFeatures =
        new FeatureSet.forTesting(additionalFeatures: [Feature.non_nullable]);

  @override
  void setUp() {
    //TODO(mfairhurst): why is this override required?
    super.setUp();
    AnalysisOptionsImpl options = analysisOptions;
    resetWith(options: options);
  }

  test_covarianceChecks_returnFunction() async {
    // test Never cases.
    var source = addSource(r'''
typedef F<T>(T t);
typedef T R<T>();
class C<T> {
  F<T> f = throw '';

  C();
  factory C.fact() => new C<Never>();

  F<T> get g => throw '';
  F<T> m1() => throw '';
  R<F<T>> m2() => throw '';

  casts(C<T> other, T t) {
    other.f;
    other.g(t);
    other.m1();
    other.m2;

    new C<T>.fact().f(t);
    new C<int>.fact().g;
    new C<int>.fact().m1;
    new C<T>.fact().m2();

    new C<Object>.fact().f(42);
    new C<Object>.fact().g;
    new C<Object>.fact().m1;
    new C<Object>.fact().m2();

    new C.fact().f(42);
    new C.fact().g;
    new C.fact().m1;
    new C.fact().m2();
  }

  noCasts(T t) {
    f;
    g;
    m1();
    m2();

    f(t);
    g(t);
    (f)(t);
    (g)(t);
    m1;
    m2;

    this.f;
    this.g;
    this.m1();
    this.m2();
    this.m1;
    this.m2;
    (this.m1)();
    (this.m2)();
    this.f(t);
    this.g(t);
    (this.f)(t);
    (this.g)(t);

    new C<int>().f;
    new C<T>().g;
    new C<int>().m1();
    new C().m2();

    new D().f;
    new D().g;
    new D().m1();
    new D().m2();
  }
}
class D extends C<num> {
  noCasts(t) {
    f;
    this.g;
    this.m1();
    m2;

    super.f;
    super.g;
    super.m1;
    super.m2();
  }
}

D d = throw '';
C<Object> c = throw '';
C cD = throw '';
C<Null> cNu = throw '';
C<Never> cN = throw '';
F<Object> f = throw '';
F<Never> fN = throw '';
R<F<Object>> rf = throw '';
R<F<Never>> rfN = throw '';
R<R<F<Object>>> rrf = throw '';
R<R<F<Never>>> rrfN = throw '';
Object obj = throw '';
F<int> fi = throw '';
R<F<int>> rfi = throw '';
R<R<F<int>>> rrfi = throw '';

casts() {
  c.f;
  c.g;
  c.m1;
  c.m1();
  c.m2();

  fN = c.f;
  fN = c.g;
  rfN = c.m1;
  rrfN = c.m2;
  fN = c.m1();
  rfN = c.m2();

  f = c.f;
  f = c.g;
  rf = c.m1;
  rrf = c.m2;
  f = c.m1();
  rf = c.m2();
  c.m2()();

  c.f(obj);
  c.g(obj);
  (c.f)(obj);
  (c.g)(obj);
  (c.m1)();
  c.m1()(obj);
  (c.m2)();

  cD.f;
  cD.g;
  cD.m1;
  cD.m1();
  cD.m2();

  cNu.f;
  cNu.g;
  cNu.m1;
  cNu.m1();
  cNu.m2();
}

noCasts() {
  fi = d.f;
  fi = d.g;
  rfi = d.m1;
  fi = d.m1();
  rrfi = d.m2;
  rfi = d.m2();
  d.f(42);
  d.g(42);
  (d.f)(42);
  (d.g)(42);
  d.m1()(42);
  d.m2()()(42);

  cN.f;
  cN.g;
  cN.m1;
  cN.m1();
  cN.m2();
}
''');
    var unit = (await computeAnalysisResult(source)).unit;
    assertNoErrors(source);

    void expectCast(Statement statement, bool hasCast) {
      var value = (statement as ExpressionStatement).expression;
      if (value is AssignmentExpression) {
        value = (value as AssignmentExpression).rightHandSide;
      }
      while (value is FunctionExpressionInvocation) {
        value = (value as FunctionExpressionInvocation).function;
      }
      while (value is ParenthesizedExpression) {
        value = (value as ParenthesizedExpression).expression;
      }
      var isCallingGetter =
          value is MethodInvocation && !value.methodName.name.startsWith('m');
      var cast = isCallingGetter
          ? getImplicitOperationCast(value)
          : getImplicitCast(value);
      var castKind = isCallingGetter ? 'special cast' : 'cast';
      expect(cast, hasCast ? isNotNull : isNull,
          reason: '`$statement` should ' +
              (hasCast ? '' : 'not ') +
              'have a $castKind on `$value`.');
    }

    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'noCasts')) {
      expectCast(s, false);
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'C', 'casts')) {
      expectCast(s, true);
    }
    for (var s in AstFinder.getStatementsInMethod(unit, 'D', 'noCasts')) {
      expectCast(s, false);
    }
    for (var s in AstFinder.getStatementsInTopLevelFunction(unit, 'noCasts')) {
      expectCast(s, false);
    }
    for (var s in AstFinder.getStatementsInTopLevelFunction(unit, 'casts')) {
      expectCast(s, true);
    }
  }
}

@reflectiveTest
class StrongModeStaticTypeAnalyzer2Test extends StaticTypeAnalyzer2TestShared {
  void expectStaticInvokeType(String search, String type) {
    var invocation = findNode.simple(search).parent as MethodInvocation;
    expect(invocation.staticInvokeType.toString(), type);
  }

  test_dynamicObjectGetter_hashCode() async {
    String code = r'''
main() {
  dynamic a = null;
  var foo = a.hashCode;
}
''';
    await assertNoErrorsInCode(code);
    expectInitializerType('foo', 'int');
  }

  test_futureOr_promotion1() async {
    // Test that promotion from FutureOr<T> to T works for concrete types
    String code = r'''
    import "dart:async";
    dynamic test(FutureOr<int> x) => (x is int) && (x.abs() == 0);
   ''';
    await assertNoErrorsInCode(code);
  }

  test_futureOr_promotion2() async {
    // Test that promotion from FutureOr<T> to Future<T> works for concrete
    // types
    String code = r'''
    import "dart:async";
    dynamic test(FutureOr<int> x) => (x is Future<int>) &&
                                     (x.then((x) => x) == null);
   ''';
    await assertNoErrorsInCode(code);
  }

  test_futureOr_promotion3() async {
    // Test that promotion from FutureOr<T> to T works for type
    // parameters T
    String code = r'''
    import "dart:async";
    dynamic test<T extends num>(FutureOr<T> x) => (x is T) &&
                                                  (x.abs() == 0);
   ''';
    await assertNoErrorsInCode(code);
  }

  test_futureOr_promotion4() async {
    // Test that promotion from FutureOr<T> to Future<T> works for type
    // parameters T
    String code = r'''
    import "dart:async";
    dynamic test<T extends num>(FutureOr<T> x) => (x is Future<T>) &&
                                                  (x.then((x) => x) == null);
   ''';
    await assertNoErrorsInCode(code);
  }

  test_generalizedVoid_assignToVoidOk() async {
    await assertNoErrorsInCode(r'''
void main() {
  void x;
  x = 42;
}
''');
  }

  test_genericFunction() async {
    await assertNoErrorsInCode(r'T f<T>(T x) => null;');
    expectFunctionType('f', 'T Function<T>(T)',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findNode.simple('f');
    FunctionElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), 'String Function(String)');
  }

  test_genericFunction_bounds() async {
    await assertNoErrorsInCode(r'T f<T extends num>(T x) => null;');
    expectFunctionType('f', 'T Function<T extends num>(T)',
        elementTypeParams: '[T extends num]', typeFormals: '[T extends num]');
  }

  test_genericFunction_parameter() async {
    await assertNoErrorsInCode(r'''
void g(T f<T>(T x)) {}
''');
    var type = expectFunctionType2('f', 'T Function<T>(T)');
    FunctionType ft = type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), 'String Function(String)');
  }

  test_genericFunction_static() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  static T f<T>(T x) => null;
}
''');
    expectFunctionType('f', 'T Function<T>(T)',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findNode.simple('f');
    MethodElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), 'String Function(String)');
  }

  test_genericFunction_typedef() async {
    String code = r'''
typedef T F<T>(T x);
F f0;

class C {
  static F f1;
  F f2;
  void g(F f3) { // C
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
  }
}

class D<S> {
  static F f1;
  F f2;
  void g(F f3) { // D
    F f4;
    f0(3);
    f1(3);
    f2(3);
    f3(3);
    f4(3);
  }
}
''';
    await assertNoErrorsInCode(code);

    checkBody(String className) {
      var statements = findNode.block('{ // $className').statements;

      for (int i = 1; i <= 5; i++) {
        Expression exp = (statements[i] as ExpressionStatement).expression;
        expect(exp.staticType, typeProvider.dynamicType);
      }
    }

    checkBody("C");
    checkBody("D");
  }

  test_genericFunction_upwardsAndDownwards() async {
    // Regression tests for https://github.com/dart-lang/sdk/issues/27586.
    await assertNoErrorsInCode(r'List<num> x = [1, 2];');
    expectInitializerType('x', 'List<num>');
  }

  test_genericFunction_upwardsAndDownwards_Object() async {
    // Regression tests for https://github.com/dart-lang/sdk/issues/27625.
    await assertNoErrorsInCode(r'''
List<Object> aaa = [];
List<Object> bbb = [1, 2, 3];
List<Object> ccc = [null];
List<Object> ddd = [1 as dynamic];
List<Object> eee = [new Object()];
    ''');
    expectInitializerType('aaa', 'List<Object>');
    expectInitializerType('bbb', 'List<Object>');
    expectInitializerType('ccc', 'List<Object>');
    expectInitializerType('ddd', 'List<Object>');
    expectInitializerType('eee', 'List<Object>');
  }

  test_genericMethod() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  List<T> f<T>(E e) => null;
}
main() {
  C<String> cOfString;
}
''');
    expectFunctionType('f<T>', 'List<T> Function<T>(E)',
        elementTypeParams: '[T]',
        typeParams: '[E]',
        typeArgs: '[E]',
        typeFormals: '[T]');
    SimpleIdentifier c = findNode.simple('cOfString');
    FunctionType ft = (c.staticType as InterfaceType).getMethod('f').type;
    expect(ft.toString(), 'List<T> Function<T>(String)');
    ft = ft.instantiate([typeProvider.intType]);
    expect(ft.toString(), 'List<int> Function(String)');
  }

  test_genericMethod_explicitTypeParams() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  List<T> f<T>(E e) => null;
}
main() {
  C<String> cOfString;
  var x = cOfString.f<int>('hi');
}
''');
    MethodInvocation f = findNode.simple('f<int>').parent;
    FunctionType ft = f.staticInvokeType;
    expect(ft.toString(), 'List<int> Function(String)');

    SimpleIdentifier x = findNode.simple('x');
    expect(x.staticType, typeProvider.listType2(typeProvider.intType));
  }

  test_genericMethod_functionExpressionInvocation_explicit() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  T f<T>(T e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;

  var lambdaCall = (<E>(E e) => e)<int>(3);
  var methodCall = (c.f)<int>(3);
  var staticCall = (C.g)<int>(3);
  var staticFieldCall = (C.h)<int>(3);
  var topFunCall = (topF)<int>(3);
  var topFieldCall = (topG)<int>(3);
  var localCall = (lf)<int>(3);
  var paramCall = (pf)<int>(3);
}
''');
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
    expectIdentifierType('lambdaCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_functionTypedParameter_explicit() async {
    await assertNoErrorsInCode(r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = (pf)<int>(3);
}
''');
    expectIdentifierType('paramCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_functionTypedParameter_inferred() async {
    await assertNoErrorsInCode(r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = (pf)(3);
}
''');
    expectIdentifierType('paramCall', "int");
  }

  test_genericMethod_functionExpressionInvocation_inferred() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  T f<T>(T e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;

  var lambdaCall = (<E>(E e) => e)(3);
  var methodCall = (c.f)(3);
  var staticCall = (C.g)(3);
  var staticFieldCall = (C.h)(3);
  var topFunCall = (topF)(3);
  var topFieldCall = (topG)(3);
  var localCall = (lf)(3);
  var paramCall = (pf)(3);
}
''');
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
    expectIdentifierType('lambdaCall', "int");
  }

  test_genericMethod_functionInvocation_explicit() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  T f<T>(T e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
  var methodCall = c.f<int>(3);
  var staticCall = C.g<int>(3);
  var staticFieldCall = C.h<int>(3);
  var topFunCall = topF<int>(3);
  var topFieldCall = topG<int>(3);
  var localCall = lf<int>(3);
  var paramCall = pf<int>(3);
}
''');
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
  }

  test_genericMethod_functionInvocation_functionTypedParameter_explicit() async {
    await assertNoErrorsInCode(r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = pf<int>(3);
}
''');
    expectIdentifierType('paramCall', "int");
  }

  test_genericMethod_functionInvocation_functionTypedParameter_inferred() async {
    await assertNoErrorsInCode(r'''
void test<S>(T pf<T>(T e)) {
  var paramCall = pf(3);
}
''');
    expectIdentifierType('paramCall', "int");
  }

  test_genericMethod_functionInvocation_inferred() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  T f<T>(T e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
  var methodCall = c.f(3);
  var staticCall = C.g(3);
  var staticFieldCall = C.h(3);
  var topFunCall = topF(3);
  var topFieldCall = topG(3);
  var localCall = lf(3);
  var paramCall = pf(3);
}
''');
    expectIdentifierType('methodCall', "int");
    expectIdentifierType('staticCall', "int");
    expectIdentifierType('staticFieldCall', "int");
    expectIdentifierType('topFunCall', "int");
    expectIdentifierType('topFieldCall', "int");
    expectIdentifierType('localCall', "int");
    expectIdentifierType('paramCall', "int");
  }

  test_genericMethod_functionTypedParameter() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  List<T> f<T>(T f(E e)) => null;
}
main() {
  C<String> cOfString;
}
''');
    expectFunctionType('f<T>', 'List<T> Function<T>(T Function(E))',
        elementTypeParams: '[T]',
        typeParams: '[E]',
        typeArgs: '[E]',
        typeFormals: '[T]');

    SimpleIdentifier c = findNode.simple('cOfString');
    FunctionType ft = (c.staticType as InterfaceType).getMethod('f').type;
    expect(ft.toString(), 'List<T> Function<T>(T Function(String))');
    ft = ft.instantiate([typeProvider.intType]);
    expect(ft.toString(), 'List<int> Function(int Function(String))');
  }

  test_genericMethod_functionTypedParameter_tearoff() async {
    await assertNoErrorsInCode(r'''
void test<S>(T pf<T>(T e)) {
  var paramTearOff = pf;
}
''');
    expectIdentifierType('paramTearOff', "T Function<T>(T)");
  }

  test_genericMethod_implicitDynamic() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25100#issuecomment-162047588
    // These should not cause any hints or warnings.
    await assertNoErrorsInCode(r'''
class List<E> {
  T map<T>(T f(E e)) => null;
}
void foo() {
  List list = null;
  list.map((e) => e);
  list.map((e) => 3);
}''');
    expectIdentifierType(
        'map((e) => e);', 'T Function<T>(T Function(dynamic))');
    expectIdentifierType(
        'map((e) => 3);', 'T Function<T>(T Function(dynamic))');

    MethodInvocation m1 = findNode.methodInvocation('map((e) => e);');
    expect(m1.staticInvokeType.toString(),
        'dynamic Function(dynamic Function(dynamic))');
    MethodInvocation m2 = findNode.methodInvocation('map((e) => 3);');
    expect(
        m2.staticInvokeType.toString(), 'int Function(int Function(dynamic))');
  }

  test_genericMethod_max_doubleDouble() async {
    await assertNoErrorsInCode(r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2.0);
}
''');
    expectInitializerType('foo', 'double');
  }

  test_genericMethod_max_doubleDouble_prefixed() async {
    await assertNoErrorsInCode(r'''
import 'dart:math' as math;
main() {
  var foo = math.max(1.0, 2.0);
}
''');
    expectInitializerType('foo', 'double');
  }

  test_genericMethod_max_doubleInt() async {
    await assertNoErrorsInCode(r'''
import 'dart:math';
main() {
  var foo = max(1.0, 2);
}
''');
    expectInitializerType('foo', 'num');
  }

  test_genericMethod_max_intDouble() async {
    await assertNoErrorsInCode(r'''
import 'dart:math';
main() {
  var foo = max(1, 2.0);
}
''');
    expectInitializerType('foo', 'num');
  }

  test_genericMethod_max_intInt() async {
    await assertNoErrorsInCode(r'''
import 'dart:math';
main() {
  var foo = max(1, 2);
}
''');
    expectInitializerType('foo', 'int');
  }

  test_genericMethod_nestedBound() async {
    // Just validate that there is no warning on the call to `.abs()`.
    await assertNoErrorsInCode(r'''
class Foo<T extends num> {
  void method<U extends T>(U u) {
    u.abs();
  }
}
''');
  }

  test_genericMethod_nestedCapture() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  T f<S>(S x) {
    new C<S>().f<int>(3);
    new C<S>().f; // tear-off
    return null;
  }
}
''');
    MethodInvocation f = findNode.methodInvocation('f<int>(3);');
    expect(f.staticInvokeType.toString(), 'S Function(int)');

    expectIdentifierType('f;', 'S Function<S₀>(S₀)');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/30236')
  test_genericMethod_nestedCaptureBounds() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  T f<S extends T>(S x) {
    new C<S>().f<int>(3);
    new C<S>().f; // tear-off
    return null;
  }
}
''');
    MethodInvocation f = findNode.methodInvocation('f<int>(3);');
    expect(f.staticInvokeType.toString(), 'S Function(int)');
    FunctionType ft = f.staticInvokeType;
    expect('${ft.typeArguments}/${ft.typeParameters}',
        '[S, int]/[T, S extends T]');

    expectIdentifierType('f;', 'S Function<S₀ extends S>(S₀)');
  }

  test_genericMethod_nestedFunctions() async {
    await assertNoErrorsInCode(r'''
S f<S>(S x) {
  g<S>(S x) => f;
  return null;
}
''');
    expectIdentifierType('f<S>', 'S Function<S>(S)');
    expectIdentifierType('g<S>', 'S Function<S>(S) Function<S>(S)');
  }

  test_genericMethod_override() async {
    await assertNoErrorsInCode(r'''
class C {
  T f<T>(T x) => null;
}
class D extends C {
  T f<T>(T x) => null; // from D
}
''');
    expectFunctionType('f<T>(T x) => null; // from D', 'T Function<T>(T)',
        elementTypeParams: '[T]', typeFormals: '[T]');
    SimpleIdentifier f = findNode.simple('f<T>(T x) => null; // from D');
    MethodElementImpl e = f.staticElement;
    FunctionType ft = e.type.instantiate([typeProvider.stringType]);
    expect(ft.toString(), 'String Function(String)');
  }

  test_genericMethod_override_bounds() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {
  T f<T extends A>(T x) => null;
}
// override with the same bound is OK
class C extends B {
  T f<T extends A>(T x) => null;
}
// override with new name and the same bound is OK
class D extends B {
  Q f<Q extends A>(Q x) => null;
}
''');
  }

  test_genericMethod_override_covariant_field() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  num get x;
  set x(covariant num _);
}

class B extends A {
  int x;
}
''');
  }

  test_genericMethod_override_differentContextsSameBounds() async {
    await assertNoErrorsInCode(r'''
        class GenericMethodBounds<T> {
  Type get t => T;
  GenericMethodBounds<E> foo<E extends T>() => new GenericMethodBounds<E>();
  GenericMethodBounds<E> bar<E extends void Function(T)>() =>
      new GenericMethodBounds<E>();
}

class GenericMethodBoundsDerived extends GenericMethodBounds<num> {
  GenericMethodBounds<E> foo<E extends num>() => new GenericMethodBounds<E>();
  GenericMethodBounds<E> bar<E extends void Function(num)>() =>
      new GenericMethodBounds<E>();
}
''');
  }

  test_genericMethod_override_invalidContravariantTypeParamBounds() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C {
  T f<T extends A>(T x) => null;
}
class D extends C {
  T f<T extends B>(T x) => null;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 101, 1),
    ]);
  }

  test_genericMethod_override_invalidCovariantTypeParamBounds() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C {
  T f<T extends B>(T x) => null;
}
class D extends C {
  T f<T extends A>(T x) => null;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 101, 1),
    ]);
  }

  test_genericMethod_override_invalidReturnType() async {
    await assertErrorsInCode(r'''
class C {
  Iterable<T> f<T>(T x) => null;
}
class D extends C {
  String f<S>(S x) => null;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 74, 1),
    ]);
  }

  test_genericMethod_override_invalidTypeParamCount() async {
    await assertErrorsInCode(r'''
class C {
  T f<T>(T x) => null;
}
class D extends C {
  S f<T, S>(T x) => null;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 59, 1),
    ]);
  }

  test_genericMethod_propagatedType_promotion() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25340

    // Note, after https://github.com/dart-lang/sdk/issues/25486 the original
    // example won't work, as we now compute a static type and therefore discard
    // the propagated type. So a new test was created that doesn't run under
    // strong mode.
    await assertNoErrorsInCode(r'''
abstract class Iter {
  List<S> map<S>(S f(x));
}
class C {}
C toSpan(dynamic element) {
  if (element is Iter) {
    var y = element.map(toSpan);
  }
  return null;
}''');
    expectIdentifierType('y = ', 'List<C>');
  }

  test_genericMethod_tearoff() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  T f<T>(E e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T Function<T>(T) pf) {
  var c = new C<int>();
  T lf<T>(T e) => null;
  var methodTearOff = c.f;
  var staticTearOff = C.g;
  var staticFieldTearOff = C.h;
  var topFunTearOff = topF;
  var topFieldTearOff = topG;
  var localTearOff = lf;
  var paramTearOff = pf;
}
''');
    expectIdentifierType('methodTearOff', "T Function<T>(int)");
    expectIdentifierType('staticTearOff', "T Function<T>(T)");
    expectIdentifierType('staticFieldTearOff', "T Function<T>(T)");
    expectIdentifierType('topFunTearOff', "T Function<T>(T)");
    expectIdentifierType('topFieldTearOff', "T Function<T>(T)");
    expectIdentifierType('localTearOff', "T Function<T>(T)");
    expectIdentifierType('paramTearOff', "T Function<T>(T)");
  }

  @failingTest
  test_genericMethod_tearoff_instantiated() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  T f<T>(E e) => null;
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

T topF<T>(T e) => null;
var topG = topF;
void test<S>(T pf<T>(T e)) {
  var c = new C<int>();
  T lf<T>(T e) => null;
  var methodTearOffInst = c.f<int>;
  var staticTearOffInst = C.g<int>;
  var staticFieldTearOffInst = C.h<int>;
  var topFunTearOffInst = topF<int>;
  var topFieldTearOffInst = topG<int>;
  var localTearOffInst = lf<int>;
  var paramTearOffInst = pf<int>;
}
''');
    expectIdentifierType('methodTearOffInst', "int Function(int)");
    expectIdentifierType('staticTearOffInst', "int Function(int)");
    expectIdentifierType('staticFieldTearOffInst', "int Function(int)");
    expectIdentifierType('topFunTearOffInst', "int Function(int)");
    expectIdentifierType('topFieldTearOffInst', "int Function(int)");
    expectIdentifierType('localTearOffInst', "int Function(int)");
    expectIdentifierType('paramTearOffInst', "int Function(int)");
  }

  test_genericMethod_then() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
String toString(int x) => x.toString();
main() {
  Future<int> bar = null;
  var foo = bar.then(toString);
}
''');

    expectInitializerType('foo', 'Future<String>');
  }

  test_genericMethod_then_prefixed() async {
    await assertNoErrorsInCode(r'''
import 'dart:async' as async;
String toString(int x) => x.toString();
main() {
  async.Future<int> bar = null;
  var foo = bar.then(toString);
}
''');
    expectInitializerType('foo', 'Future<String>');
  }

  test_genericMethod_then_propagatedType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25482.
    await assertErrorsInCode(r'''
import 'dart:async';
void main() {
  Future<String> p;
  var foo = p.then((r) => new Future<String>.value(3));
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 61, 3),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 106, 1),
    ]);
    // Note: this correctly reports the error
    // StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE when run with the driver;
    // when run without the driver, it reports no errors.  So we don't bother
    // checking whether the correct errors were reported.
    expectInitializerType('foo', 'Future<String>');
  }

  test_genericMethod_toplevel_field_staticTearoff() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  static T g<T>(T e) => null;
  static T Function<T>(T) h = null;
}

void test() {
  var fieldRead = C.h;
}
''');
    expectIdentifierType('fieldRead', "T Function<T>(T)");
  }

  test_implicitBounds() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

class B<T extends num> {}

class C<S extends int, T extends B<S>, U extends A> {}

void test() {
//
  A ai;
  B bi;
  C ci;
  var aa = new A();
  var bb = new B();
  var cc = new C();
}
''');
    expectIdentifierType('ai', "A<dynamic>");
    expectIdentifierType('bi', "B<num>");
    expectIdentifierType('ci', "C<int, B<int>, A<dynamic>>");
    expectIdentifierType('aa', "A<dynamic>");
    expectIdentifierType('bb', "B<num>");
    expectIdentifierType('cc', "C<int, B<int>, A<dynamic>>");
  }

  test_instantiateToBounds_class_error_extension_malbounded() async {
    // Test that superclasses are strictly checked for malbounded default
    // types
    await assertErrorsInCode(r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
class D extends C {}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 69, 1),
    ]);
  }

  test_instantiateToBounds_class_error_instantiation_malbounded() async {
    // Test that instance creations are strictly checked for malbounded default
    // types
    await assertErrorsInCode(r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
void test() {
  var c = new C();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 73, 1),
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 81, 1),
      error(StrongModeCode.COULD_NOT_INFER, 81, 1),
    ]);
    expectIdentifierType('c =', 'C<List<dynamic>, List<List<dynamic>>>');
  }

  test_instantiateToBounds_class_error_recursion() async {
    await assertErrorsInCode(r'''
class C<T0 extends List<T1>, T1 extends List<T0>> {}
C c;
''', []);

    expectIdentifierType('c;', 'C<List<dynamic>, List<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion_self() async {
    await assertErrorsInCode(r'''
class C<T extends C<T>> {}
C c;
''', []);

    expectIdentifierType('c;', 'C<C<dynamic>>');
  }

  test_instantiateToBounds_class_error_recursion_self2() async {
    await assertErrorsInCode(r'''
class A<E> {}
class C<T extends A<T>> {}
C c;
''', []);

    expectIdentifierType('c;', 'C<A<dynamic>>');
  }

  test_instantiateToBounds_class_error_typedef() async {
    await assertErrorsInCode(r'''
typedef T F<T>(T x);
class C<T extends F<T>> {}
C c;
''', []);

    expectIdentifierType('c;', 'C<dynamic Function(dynamic)>');
  }

  test_instantiateToBounds_class_ok_implicitDynamic_multi() async {
    await assertNoErrorsInCode(r'''
class C<T0 extends Map<T1, T2>, T1 extends List, T2 extends int> {}
C c;
''');

    expectIdentifierType(
        'c;', 'C<Map<List<dynamic>, int>, List<dynamic>, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_after() async {
    await assertNoErrorsInCode(r'''
class C<T0 extends T1, T1 extends int> {}
C c;
''');

    expectIdentifierType('c;', 'C<int, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_after2() async {
    await assertNoErrorsInCode(r'''
class C<T0 extends Map<T1, T1>, T1 extends int> {}
C c;
''');

    expectIdentifierType('c;', 'C<Map<int, int>, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_before() async {
    await assertNoErrorsInCode(r'''
class C<T0 extends int, T1 extends T0> {}
C c;
''');

    expectIdentifierType('c;', 'C<int, int>');
  }

  test_instantiateToBounds_class_ok_referenceOther_multi() async {
    await assertNoErrorsInCode(r'''
class C<T0 extends Map<T1, T2>, T1 extends List<T2>, T2 extends int> {}
C c;
''');

    expectIdentifierType('c;', 'C<Map<List<int>, int>, List<int>, int>');
  }

  test_instantiateToBounds_class_ok_simpleBounds() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class B<T extends num> {}
class C<T extends List<int>> {}
class D<T extends A> {}
void main() {
  A a;
  B b;
  C c;
  D d;
}
''');

    expectIdentifierType('a;', 'A<dynamic>');
    expectIdentifierType('b;', 'B<num>');
    expectIdentifierType('c;', 'C<List<int>>');
    expectIdentifierType('d;', 'D<A<dynamic>>');
  }

  test_instantiateToBounds_generic_function_error_malbounded() async {
    // Test that generic methods are strictly checked for malbounded default
    // types
    await assertErrorsInCode(r'''
T0 f<T0 extends List<T1>, T1 extends List<T0>>() {}
void g() {
  var c = f();
  return;
}
''', [
      error(HintCode.MISSING_RETURN, 0, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 69, 1),
      error(StrongModeCode.COULD_NOT_INFER, 73, 1),
    ]);
    expectIdentifierType('c =', 'List<dynamic>');
  }

  test_instantiateToBounds_method_ok_referenceOther_before() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  void m<S0 extends T, S1 extends List<S0>>(S0 p0, S1 p1) {}

  void main() {
    m(null, null);
  }
}
''');

    expectStaticInvokeType('m(null', 'void Function(Null, Null)');
  }

  test_instantiateToBounds_method_ok_referenceOther_before2() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  Map<S0, S1> m<S0 extends T, S1 extends List<S0>>() => null;

  void main() {
    m();
  }
}
''');

    expectStaticInvokeType('m();', 'Map<T, List<T>> Function()');
  }

  test_instantiateToBounds_method_ok_simpleBounds() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  void m<S extends T>(S p0) {}

  void main() {
    m(null);
  }
}
''');

    expectStaticInvokeType('m(null)', 'void Function(Null)');
  }

  test_instantiateToBounds_method_ok_simpleBounds2() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  S m<S extends T>() => null;

  void main() {
    m();
  }
}
''');

    expectStaticInvokeType('m();', 'T Function()');
  }

  test_issue32396() async {
    await assertNoErrorsInCode(r'''
class C<E> {
  static T g<T>(T e) => null;
  static final h = g;
}
''');
  }

  test_notInstantiatedBound_class_error_recursion() async {
    await assertErrorsInCode(r'''
class A<T extends B> {} // points to a
class B<T extends A> {} // points to b
class C<T extends A> {} // points to a cyclical type
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 18, 1),
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 57, 1),
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 96, 1),
    ]);
  }

  test_notInstantiatedBound_class_error_recursion_less_direct() async {
    await assertErrorsInCode(r'''
class A<T extends B<A>> {}
class B<T extends A<B>> {}
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 20, 1),
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 47, 1),
    ]);
  }

  test_notInstantiatedBound_class_error_recursion_typedef() async {
    await assertErrorsInCode(r'''
typedef F(C value);
class C<T extends F> {}
class D<T extends C> {}
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 19),
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 38, 1),
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 62, 1),
    ]);
  }

  test_notInstantiatedBound_error_class_argument() async {
    await assertErrorsInCode(r'''
class A<K, V extends List<K>> {}
class C<T extends A> {}
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 51, 1),
    ]);
  }

  test_notInstantiatedBound_error_class_argument2() async {
    await assertErrorsInCode(r'''
class A<K, V extends List<List<K>>> {}
class C<T extends A> {}
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 57, 1),
    ]);
  }

  test_notInstantiatedBound_error_class_direct() async {
    await assertErrorsInCode(r'''
class A<K, V extends K> {}
class C<T extends A> {}
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 45, 1),
    ]);
  }

  test_notInstantiatedBound_error_class_indirect() async {
    await assertErrorsInCode(r'''
class A<K, V extends K> {}
class C<T extends List<A>> {}
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 50, 1),
    ]);
  }

  test_notInstantiatedBound_error_functionType() async {
    await assertErrorsInCode(r'''
class A<T extends Function(T)> {}
class B<T extends T Function()> {}
class C<T extends A> {}
class D<T extends B> {}
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 87, 1),
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 111, 1),
    ]);
  }

  test_notInstantiatedBound_error_typedef_argument() async {
    await assertErrorsInCode(r'''
class A<K, V extends List<K>> {}
typedef void F<T extends A>();
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 58, 1),
    ]);
  }

  test_notInstantiatedBound_error_typedef_argument2() async {
    await assertErrorsInCode(r'''
class A<K, V extends List<List<K>>> {}
typedef void F<T extends A>();
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 64, 1),
    ]);
  }

  test_notInstantiatedBound_error_typedef_direct() async {
    await assertErrorsInCode(r'''
class A<K, V extends K> {}
typedef void F<T extends A>();
''', [
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 52, 1),
    ]);
  }

  test_notInstantiatedBound_ok_class() async {
    await assertNoErrorsInCode(r'''
class A<T extends int> {}
class C1<T extends A> {}
class C2<T extends List<A>> {}
''');
  }

  test_notInstantiatedBound_ok_class_class2() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class C<T extends A<int>> {}
class D<T extends C> {}
''');
  }

  test_notInstantiatedBound_ok_class_class3() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class B<T extends int> {}
class C<T extends A<B>> {}
''');
  }

  test_notInstantiatedBound_ok_class_class4() async {
    await assertNoErrorsInCode(r'''
class A<K, V> {}
class B<T extends int> {}
class C<T extends A<B, B>> {}
''');
  }

  test_notInstantiatedBound_ok_class_function() async {
    await assertNoErrorsInCode(r'''
class A<T extends void Function()> {}
class B<T extends A> {}
''');
  }

  test_notInstantiatedBound_ok_class_typedef() async {
    await assertNoErrorsInCode(r'''
typedef void F<T extends int>();
class C<T extends F> {}
''');
  }

  test_notInstantiatedBound_ok_typedef_class() async {
    await assertNoErrorsInCode(r'''
class C<T extends int> {}
typedef void F<T extends C>();
''');
  }

  test_objectMethodOnFunctions_Anonymous() async {
    await _objectMethodOnFunctions_helper2(r'''
void main() {
  var f = (x) => 3;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}''');
  }

  test_objectMethodOnFunctions_Function() async {
    await _objectMethodOnFunctions_helper2(r'''
void main() {
  Function f;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}''');
  }

  test_objectMethodOnFunctions_Static() async {
    await _objectMethodOnFunctions_helper2(r'''
int f(int x) => null;
void main() {
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}''');
  }

  test_objectMethodOnFunctions_Typedef() async {
    await _objectMethodOnFunctions_helper2(r'''
typedef bool Predicate<T>(T object);

void main() {
  Predicate<int> f;
  // No errors, correct type
  var t0 = f.toString();
  var t1 = f.toString;
  var t2 = f.hashCode;

  // Expressions, no errors, correct type
  var t3 = (f).toString();
  var t4 = (f).toString;
  var t5 = (f).hashCode;

  // Cascades, no errors
  f..toString();
  f..toString;
  f..hashCode;

  // Expression cascades, no errors
  (f)..toString();
  (f)..toString;
  (f)..hashCode;
}''');
  }

  test_returnOfInvalidType_object_void() async {
    await assertErrorsInCode(
        "Object f() { void voidFn() => null; return voidFn(); }", [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 43, 8),
    ]);
  }

  test_setterWithDynamicTypeIsError() async {
    await assertErrorsInCode(r'''
class A {
  dynamic set f(String s) => null;
}
dynamic set g(int x) => null;
''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 12, 7),
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 47, 7),
    ]);
  }

  test_setterWithExplicitVoidType_returningVoid() async {
    await assertNoErrorsInCode(r'''
void returnsVoid() {}
class A {
  void set f(String s) => returnsVoid();
}
void set g(int x) => returnsVoid();
''');
  }

  test_setterWithNoVoidType() async {
    await assertErrorsInCode(r'''
class A {
  set f(String s) {
    return '42';
  }
}
set g(int x) => 42;
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 41, 4),
    ]);
  }

  test_setterWithNoVoidType_returningVoid() async {
    await assertNoErrorsInCode(r'''
void returnsVoid() {}
class A {
  set f(String s) => returnsVoid();
}
set g(int x) => returnsVoid();
''');
  }

  test_setterWithOtherTypeIsError() async {
    await assertErrorsInCode(r'''
class A {
  String set f(String s) => null;
}
Object set g(x) => null;
''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 12, 6),
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 46, 6),
    ]);
  }

  test_ternaryOperator_null_left() async {
    await assertNoErrorsInCode(r'''
main() {
  var foo = (true) ? null : 3;
}
''');
    expectInitializerType('foo', 'int');
  }

  test_ternaryOperator_null_right() async {
    await assertNoErrorsInCode(r'''
main() {
  var foo = (true) ? 3 : null;
}
''');
    expectInitializerType('foo', 'int');
  }

  Future<void> _objectMethodOnFunctions_helper2(String code) async {
    await assertNoErrorsInCode(code);
    expectIdentifierType('t0', "String");
    expectIdentifierType('t1', "String Function()");
    expectIdentifierType('t2', "int");
    expectIdentifierType('t3', "String");
    expectIdentifierType('t4', "String Function()");
    expectIdentifierType('t5', "int");
  }
}

@reflectiveTest
class StrongModeTypePropagationTest extends DriverResolutionTest {
  test_foreachInference_dynamic_disabled() async {
    await resolveTestCode(r'''
main() {
  var list = <int>[];
  for (dynamic v in list) {
    v; // marker
  }
}''');
    assertTypeDynamic(findNode.simple('v in'));
    assertTypeDynamic(findNode.simple('v; // marker'));
  }

  test_foreachInference_reusedVar_disabled() async {
    await resolveTestCode(r'''
main() {
  var list = <int>[];
  var v;
  for (v in list) {
    v; // marker
  }
}''');
    assertTypeDynamic(findNode.simple('v in'));
    assertTypeDynamic(findNode.simple('v; // marker'));
  }

  test_foreachInference_var() async {
    await resolveTestCode(r'''
main() {
  var list = <int>[];
  for (var v in list) {
    v; // marker
  }
}''');
    assertType(findNode.simple('v in'), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_foreachInference_var_iterable() async {
    await resolveTestCode(r'''
main() {
  Iterable<int> list = <int>[];
  for (var v in list) {
    v; // marker
  }
}''');
    assertType(findNode.simple('v in'), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_foreachInference_var_stream() async {
    await resolveTestCode(r'''
import 'dart:async';
main() async {
  Stream<int> stream = null;
  await for (var v in stream) {
    v; // marker
  }
}''');
    assertType(findNode.simple('v in'), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_inconsistentMethodInheritance_inferFunctionTypeFromTypedef() async {
    await assertNoErrorsInCode(r'''
typedef bool F<E>(E argument);

abstract class Base {
  f<E extends int>(F<int> x);
}

abstract class BaseCopy extends Base {
}

abstract class Override implements Base, BaseCopy {
  f<E extends int>(x) => null;
}

class C extends Override implements Base {}
''');
  }

  test_localVariableInference_bottom_disabled() async {
    await resolveTestCode(r'''
main() {
  var v = null;
  v; // marker
}''');
    assertTypeDynamic(findNode.simple('v ='));
    assertTypeDynamic(findNode.simple('v; // marker'));
  }

  test_localVariableInference_constant() async {
    await resolveTestCode(r'''
main() {
  var v = 3;
  v; // marker
}''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_declaredType_disabled() async {
    await resolveTestCode(r'''
main() {
  dynamic v = 3;
  v; // marker
}''');
    assertTypeDynamic(findNode.simple('v ='));
    assertTypeDynamic(findNode.simple('v; // marker'));
  }

  test_localVariableInference_noInitializer_disabled() async {
    await resolveTestCode(r'''
main() {
  var v;
  v = 3;
  v; // marker
}''');
    assertTypeDynamic(findNode.simple('v ='));
    assertTypeDynamic(findNode.simple('v; // marker'));
  }

  test_localVariableInference_transitive_field_inferred_lexical() async {
    await resolveTestCode(r'''
class A {
  final x = 3;
  f() {
    var v = x;
    return v; // marker
  }
}
main() {
}
''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_inferred_reversed() async {
    await resolveTestCode(r'''
class A {
  f() {
    var v = x;
    return v; // marker
  }
  final x = 3;
}
main() {
}
''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_lexical() async {
    await resolveTestCode(r'''
class A {
  int x = 3;
  f() {
    var v = x;
    return v; // marker
  }
}
main() {
}
''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_field_reversed() async {
    await resolveTestCode(r'''
class A {
  f() {
    var v = x;
    return v; // marker
  }
  int x = 3;
}
main() {
}
''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_list_local() async {
    await resolveTestCode(r'''
main() {
  var x = <int>[3];
  var v = x[0];
  v; // marker
}''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_local() async {
    await resolveTestCode(r'''
main() {
  var x = 3;
  var v = x;
  v; // marker
}''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_inferred_lexical() async {
    await resolveTestCode(r'''
final x = 3;
main() {
  var v = x;
  v; // marker
}
''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_toplevel_inferred_reversed() async {
    await resolveTestCode(r'''
main() {
  var v = x;
  v; // marker
}
final x = 3;
''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_lexical() async {
    await resolveTestCode(r'''
int x = 3;
main() {
  var v = x;
  v; // marker
}
''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }

  test_localVariableInference_transitive_topLevel_reversed() async {
    await resolveTestCode(r'''
main() {
  var v = x;
  v; // marker
}
int x = 3;
''');
    assertType(findNode.simple('v ='), 'int');
    assertType(findNode.simple('v; // marker'), 'int');
  }
}
