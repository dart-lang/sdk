// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/world.dart';
import 'type_mask_test_helper.dart';
import '../helpers/memory_compiler.dart';

TypeMask nullType;
TypeMask objectType;
TypeMask jsBoolean;
TypeMask jsNumber;
TypeMask jsInteger;
TypeMask jsDouble;
TypeMask jsBooleanOrNull;
TypeMask jsNumberOrNull;
TypeMask jsIntegerOrNull;
TypeMask jsDoubleOrNull;
TypeMask emptyType;
TypeMask dynamicType;

var patternClass;
TypeMask nonPrimitive1;
TypeMask nonPrimitive2;
TypeMask potentialArray;
TypeMask potentialString;
TypeMask jsInterceptor;
TypeMask jsInterceptorOrComparable;

TypeMask jsIndexable;
TypeMask jsReadableArray;
TypeMask jsMutableArray;
TypeMask jsFixedArray;
TypeMask jsExtendableArray;
TypeMask jsUnmodifiableArray;
TypeMask jsString;
TypeMask jsStringOrNull;
TypeMask jsArrayOrNull;
TypeMask jsMutableArrayOrNull;
TypeMask jsFixedArrayOrNull;
TypeMask jsExtendableArrayOrNull;
TypeMask jsUnmodifiableArrayOrNull;
TypeMask jsIndexableOrNull;
TypeMask jsInterceptorOrNull;
TypeMask jsInterceptorOrComparableOrNull;

class Pair {
  final first;
  final second;
  Pair(this.first, this.second);
  @override
  int get hashCode => first.hashCode * 47 + second.hashCode;
  @override
  bool operator ==(other) =>
      other is Pair &&
      identical(first, other.first) &&
      identical(second, other.second);
}

class RuleSet {
  final name;
  final operate;
  final Set typesSeen = new Set();
  final Set pairsSeen = new Set();

  RuleSet(this.name, this.operate);

  void rule(type1, type2, result) {
    typesSeen..add(type1)..add(type2);
    var pair1 = new Pair(type1, type2);
    var pair2 = new Pair(type2, type1);
    if (pairsSeen.contains(pair1)) {
      Expect.isFalse(true, 'Redundant rule ($type1, $type2, ...)');
    }
    pairsSeen..add(pair1)..add(pair2);

    var r1 = operate(type1, type2);
    var r2 = operate(type2, type1);
    Expect.equals(result, r1, "Unexpected result of $name($type1,$type2)");
    Expect.equals(r1, r2, 'Symmetry violation of $name($type1,$type2)');
  }

  void check(type1, type2, predicate) {
    typesSeen..add(type1)..add(type2);
    var pair = new Pair(type1, type2);
    pairsSeen..add(pair);
    var result = operate(type1, type2);
    Expect.isTrue(predicate(result));
  }

  void validateCoverage() {
    for (var type1 in typesSeen) {
      for (var type2 in typesSeen) {
        var pair = new Pair(type1, type2);
        if (!pairsSeen.contains(pair)) {
          Expect.isTrue(false, 'Missing rule: $name($type1, $type2)');
        }
      }
    }
  }
}

void testUnion(JClosedWorld closedWorld) {
  RuleSet ruleSet = new RuleSet(
      'union', (t1, t2) => simplify(t1.union(t2, closedWorld), closedWorld));
  rule(type1, type2, result) => ruleSet.rule(type1, type2, result);
  check(type1, type2, predicate) => ruleSet.check(type1, type2, predicate);

  rule(emptyType, emptyType, emptyType);
  rule(emptyType, dynamicType, dynamicType);
  rule(emptyType, jsBoolean, jsBoolean);
  rule(emptyType, jsNumber, jsNumber);
  rule(emptyType, jsInteger, jsInteger);
  rule(emptyType, jsDouble, jsDouble);
  rule(emptyType, jsIndexable, jsIndexable);
  rule(emptyType, jsString, jsString);
  rule(emptyType, jsReadableArray, jsReadableArray);
  rule(emptyType, jsMutableArray, jsMutableArray);
  rule(emptyType, jsExtendableArray, jsExtendableArray);
  rule(emptyType, jsUnmodifiableArray, jsUnmodifiableArray);
  rule(emptyType, nonPrimitive1, nonPrimitive1);
  rule(emptyType, nonPrimitive2, nonPrimitive2);
  rule(emptyType, potentialArray, potentialArray);
  rule(emptyType, potentialString, potentialString);
  rule(emptyType, jsBooleanOrNull, jsBooleanOrNull);
  rule(emptyType, jsNumberOrNull, jsNumberOrNull);
  rule(emptyType, jsIntegerOrNull, jsIntegerOrNull);
  rule(emptyType, jsDoubleOrNull, jsDoubleOrNull);
  rule(emptyType, jsStringOrNull, jsStringOrNull);
  rule(emptyType, nullType, nullType);
  rule(emptyType, jsFixedArray, jsFixedArray);

  rule(dynamicType, dynamicType, dynamicType);
  rule(dynamicType, jsBoolean, dynamicType);
  rule(dynamicType, jsNumber, dynamicType);
  rule(dynamicType, jsInteger, dynamicType);
  rule(dynamicType, jsDouble, dynamicType);
  rule(dynamicType, jsIndexable, dynamicType);
  rule(dynamicType, jsString, dynamicType);
  rule(dynamicType, jsReadableArray, dynamicType);
  rule(dynamicType, jsMutableArray, dynamicType);
  rule(dynamicType, jsExtendableArray, dynamicType);
  rule(dynamicType, jsUnmodifiableArray, dynamicType);
  rule(dynamicType, nonPrimitive1, dynamicType);
  rule(dynamicType, nonPrimitive2, dynamicType);
  rule(dynamicType, potentialArray, dynamicType);
  rule(dynamicType, potentialString, dynamicType);
  rule(dynamicType, jsBooleanOrNull, dynamicType);
  rule(dynamicType, jsNumberOrNull, dynamicType);
  rule(dynamicType, jsIntegerOrNull, dynamicType);
  rule(dynamicType, jsDoubleOrNull, dynamicType);
  rule(dynamicType, jsStringOrNull, dynamicType);
  rule(dynamicType, nullType, dynamicType);
  rule(dynamicType, jsFixedArray, dynamicType);

  rule(jsBoolean, jsBoolean, jsBoolean);
  rule(jsBoolean, jsNumber, jsInterceptor);
  rule(jsBoolean, jsInteger, jsInterceptor);
  rule(jsBoolean, jsDouble, jsInterceptor);
  rule(jsBoolean, jsIndexable, objectType);
  rule(jsBoolean, jsString, jsInterceptor);
  rule(jsBoolean, jsReadableArray, jsInterceptor);
  rule(jsBoolean, jsMutableArray, jsInterceptor);
  rule(jsBoolean, jsExtendableArray, jsInterceptor);
  rule(jsBoolean, jsUnmodifiableArray, jsInterceptor);
  rule(jsBoolean, nonPrimitive1, objectType);
  rule(jsBoolean, nonPrimitive2, objectType);
  rule(jsBoolean, potentialArray, dynamicType);
  rule(jsBoolean, potentialString, dynamicType);
  rule(jsBoolean, jsBooleanOrNull, jsBooleanOrNull);
  rule(jsBoolean, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsBoolean, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsBoolean, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsBoolean, jsStringOrNull, jsInterceptorOrNull);
  rule(jsBoolean, nullType, jsBooleanOrNull);
  rule(jsBoolean, jsFixedArray, jsInterceptor);

  rule(jsNumber, jsNumber, jsNumber);
  rule(jsNumber, jsInteger, jsNumber);
  rule(jsNumber, jsDouble, jsNumber);
  rule(jsNumber, jsIndexable, objectType);
  rule(jsNumber, jsString, jsInterceptorOrComparable);
  rule(jsNumber, jsReadableArray, jsInterceptor);
  rule(jsNumber, jsMutableArray, jsInterceptor);
  rule(jsNumber, jsExtendableArray, jsInterceptor);
  rule(jsNumber, jsUnmodifiableArray, jsInterceptor);
  rule(jsNumber, nonPrimitive1, objectType);
  rule(jsNumber, nonPrimitive2, objectType);
  rule(jsNumber, potentialArray, dynamicType);
  rule(jsNumber, potentialString, dynamicType);
  rule(jsNumber, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsNumber, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumber, jsIntegerOrNull, jsNumberOrNull);
  rule(jsNumber, jsDoubleOrNull, jsNumberOrNull);
  rule(jsNumber, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsNumber, nullType, jsNumberOrNull);
  rule(jsNumber, jsFixedArray, jsInterceptor);

  rule(jsInteger, jsInteger, jsInteger);
  rule(jsInteger, jsDouble, jsNumber);
  rule(jsInteger, jsIndexable, objectType);
  rule(jsInteger, jsString, jsInterceptorOrComparable);
  rule(jsInteger, jsReadableArray, jsInterceptor);
  rule(jsInteger, jsMutableArray, jsInterceptor);
  rule(jsInteger, jsExtendableArray, jsInterceptor);
  rule(jsInteger, jsUnmodifiableArray, jsInterceptor);
  rule(jsInteger, nonPrimitive1, objectType);
  rule(jsInteger, nonPrimitive2, objectType);
  rule(jsInteger, potentialArray, dynamicType);
  rule(jsInteger, potentialString, dynamicType);
  rule(jsInteger, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsInteger, jsNumberOrNull, jsNumberOrNull);
  rule(jsInteger, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsInteger, jsDoubleOrNull, jsNumberOrNull);
  rule(jsInteger, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsInteger, nullType, jsIntegerOrNull);
  rule(jsInteger, jsFixedArray, jsInterceptor);

  rule(jsDouble, jsDouble, jsDouble);
  rule(jsDouble, jsIndexable, objectType);
  rule(jsDouble, jsString, jsInterceptorOrComparable);
  rule(jsDouble, jsReadableArray, jsInterceptor);
  rule(jsDouble, jsMutableArray, jsInterceptor);
  rule(jsDouble, jsExtendableArray, jsInterceptor);
  rule(jsDouble, jsUnmodifiableArray, jsInterceptor);
  rule(jsDouble, nonPrimitive1, objectType);
  rule(jsDouble, nonPrimitive2, objectType);
  rule(jsDouble, potentialArray, dynamicType);
  rule(jsDouble, potentialString, dynamicType);
  rule(jsDouble, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsDouble, jsNumberOrNull, jsNumberOrNull);
  rule(jsDouble, jsIntegerOrNull, jsNumberOrNull);
  rule(jsDouble, jsDoubleOrNull, jsDoubleOrNull);
  rule(jsDouble, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsDouble, nullType, jsDoubleOrNull);
  rule(jsDouble, jsFixedArray, jsInterceptor);

  rule(jsIndexable, jsIndexable, jsIndexable);
  rule(jsIndexable, jsString, jsIndexable);
  rule(jsIndexable, jsReadableArray, jsIndexable);
  rule(jsIndexable, jsMutableArray, jsIndexable);
  rule(jsIndexable, jsExtendableArray, jsIndexable);
  rule(jsIndexable, jsUnmodifiableArray, jsIndexable);
  rule(jsIndexable, nonPrimitive1, objectType);
  rule(jsIndexable, nonPrimitive2, objectType);
  rule(jsIndexable, potentialArray, dynamicType);
  rule(jsIndexable, potentialString, dynamicType);
  rule(jsIndexable, jsBooleanOrNull, dynamicType);
  rule(jsIndexable, jsNumberOrNull, dynamicType);
  rule(jsIndexable, jsIntegerOrNull, dynamicType);
  rule(jsIndexable, jsDoubleOrNull, dynamicType);
  rule(jsIndexable, jsStringOrNull, jsIndexableOrNull);
  rule(jsIndexable, nullType, jsIndexableOrNull);
  rule(jsIndexable, jsFixedArray, jsIndexable);

  rule(jsString, jsString, jsString);
  rule(jsString, jsReadableArray, jsIndexable);
  rule(jsString, jsMutableArray, jsIndexable);
  rule(jsString, jsExtendableArray, jsIndexable);
  rule(jsString, jsUnmodifiableArray, jsIndexable);
  rule(jsString, nonPrimitive1, objectType);
  rule(jsString, nonPrimitive2, objectType);
  rule(jsString, potentialArray, dynamicType);
  rule(jsString, potentialString, potentialString);
  rule(jsString, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsString, jsNumberOrNull, jsInterceptorOrComparableOrNull);
  rule(jsString, jsIntegerOrNull, jsInterceptorOrComparableOrNull);
  rule(jsString, jsDoubleOrNull, jsInterceptorOrComparableOrNull);
  rule(jsString, jsStringOrNull, jsStringOrNull);
  rule(jsString, nullType, jsStringOrNull);
  rule(jsString, jsFixedArray, jsIndexable);

  rule(jsReadableArray, jsReadableArray, jsReadableArray);
  rule(jsReadableArray, jsMutableArray, jsReadableArray);
  rule(jsReadableArray, jsExtendableArray, jsReadableArray);
  rule(jsReadableArray, jsUnmodifiableArray, jsReadableArray);
  rule(jsReadableArray, nonPrimitive1, objectType);
  rule(jsReadableArray, nonPrimitive2, objectType);
  rule(jsReadableArray, potentialArray, potentialArray);
  rule(jsReadableArray, potentialString, dynamicType);
  rule(jsReadableArray, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsReadableArray, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsReadableArray, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsReadableArray, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsReadableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsReadableArray, nullType, jsArrayOrNull);
  rule(jsReadableArray, jsFixedArray, jsReadableArray);

  rule(jsMutableArray, jsMutableArray, jsMutableArray);
  rule(jsMutableArray, jsExtendableArray, jsMutableArray);
  rule(jsMutableArray, jsUnmodifiableArray, jsReadableArray);
  rule(jsMutableArray, nonPrimitive1, objectType);
  rule(jsMutableArray, nonPrimitive2, objectType);
  rule(jsMutableArray, potentialArray, potentialArray);
  rule(jsMutableArray, potentialString, dynamicType);
  rule(jsMutableArray, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsMutableArray, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsMutableArray, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsMutableArray, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsMutableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsMutableArray, nullType, jsMutableArrayOrNull);
  rule(jsMutableArray, jsFixedArray, jsMutableArray);

  rule(jsExtendableArray, jsExtendableArray, jsExtendableArray);
  rule(jsExtendableArray, jsUnmodifiableArray, jsReadableArray);
  rule(jsExtendableArray, nonPrimitive1, objectType);
  rule(jsExtendableArray, nonPrimitive2, objectType);
  rule(jsExtendableArray, potentialArray, potentialArray);
  rule(jsExtendableArray, potentialString, dynamicType);
  rule(jsExtendableArray, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsExtendableArray, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsExtendableArray, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsExtendableArray, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsExtendableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsExtendableArray, nullType, jsExtendableArrayOrNull);
  rule(jsExtendableArray, jsFixedArray, jsMutableArray);

  rule(jsUnmodifiableArray, jsUnmodifiableArray, jsUnmodifiableArray);
  rule(jsUnmodifiableArray, nonPrimitive1, objectType);
  rule(jsUnmodifiableArray, nonPrimitive2, objectType);
  rule(jsUnmodifiableArray, potentialArray, potentialArray);
  rule(jsUnmodifiableArray, potentialString, dynamicType);
  rule(jsUnmodifiableArray, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsUnmodifiableArray, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsUnmodifiableArray, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsUnmodifiableArray, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsUnmodifiableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsUnmodifiableArray, nullType, jsUnmodifiableArrayOrNull);
  rule(jsUnmodifiableArray, jsFixedArray, jsReadableArray);

  rule(nonPrimitive1, nonPrimitive1, nonPrimitive1);
  rule(nonPrimitive1, nonPrimitive2, objectType);
  rule(nonPrimitive1, potentialArray, dynamicType);
  rule(nonPrimitive1, potentialString, dynamicType);
  rule(nonPrimitive1, jsBooleanOrNull, dynamicType);
  rule(nonPrimitive1, jsNumberOrNull, dynamicType);
  rule(nonPrimitive1, jsIntegerOrNull, dynamicType);
  rule(nonPrimitive1, jsDoubleOrNull, dynamicType);
  rule(nonPrimitive1, jsStringOrNull, dynamicType);
  rule(nonPrimitive1, jsFixedArray, objectType);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, dynamicType);
  rule(nonPrimitive2, potentialString, dynamicType);
  rule(nonPrimitive2, jsBooleanOrNull, dynamicType);
  rule(nonPrimitive2, jsNumberOrNull, dynamicType);
  rule(nonPrimitive2, jsIntegerOrNull, dynamicType);
  rule(nonPrimitive2, jsDoubleOrNull, dynamicType);
  rule(nonPrimitive2, jsStringOrNull, dynamicType);
  rule(nonPrimitive2, jsFixedArray, objectType);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, dynamicType);
  rule(potentialArray, jsBooleanOrNull, dynamicType);
  rule(potentialArray, jsNumberOrNull, dynamicType);
  rule(potentialArray, jsIntegerOrNull, dynamicType);
  rule(potentialArray, jsDoubleOrNull, dynamicType);
  rule(potentialArray, jsStringOrNull, dynamicType);
  rule(potentialArray, nullType, potentialArray);
  rule(potentialArray, jsFixedArray, potentialArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, jsBooleanOrNull, dynamicType);
  rule(potentialString, jsNumberOrNull, dynamicType);
  rule(potentialString, jsIntegerOrNull, dynamicType);
  rule(potentialString, jsDoubleOrNull, dynamicType);
  rule(potentialString, jsStringOrNull, potentialString);
  rule(potentialString, nullType, potentialString);
  rule(potentialString, jsFixedArray, dynamicType);

  rule(jsBooleanOrNull, jsBooleanOrNull, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, jsStringOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, nullType, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsNumberOrNull, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsIntegerOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsDoubleOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsNumberOrNull, nullType, jsNumberOrNull);
  rule(jsNumberOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsIntegerOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsDoubleOrNull, jsNumberOrNull);
  rule(jsIntegerOrNull, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsIntegerOrNull, nullType, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsDoubleOrNull, jsDoubleOrNull, jsDoubleOrNull);
  rule(jsDoubleOrNull, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsDoubleOrNull, nullType, jsDoubleOrNull);
  rule(jsDoubleOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsStringOrNull, jsStringOrNull, jsStringOrNull);
  rule(jsStringOrNull, nullType, jsStringOrNull);
  rule(jsStringOrNull, jsFixedArray, jsIndexableOrNull);

  rule(nullType, nullType, nullType);
  rule(nullType, jsFixedArray, jsFixedArrayOrNull);

  rule(jsFixedArray, jsFixedArray, jsFixedArray);

  check(nonPrimitive1, nullType, (type) => type == nonPrimitive1.nullable());
  check(nonPrimitive2, nullType, (type) => type == nonPrimitive2.nullable());
  check(nullType, nonPrimitive1, (type) => type == nonPrimitive1.nullable());
  check(nullType, nonPrimitive2, (type) => type == nonPrimitive2.nullable());

  ruleSet.validateCoverage();
}

void testIntersection(JClosedWorld closedWorld) {
  RuleSet ruleSet =
      new RuleSet('intersection', (t1, t2) => t1.intersection(t2, closedWorld));
  rule(type1, type2, result) => ruleSet.rule(type1, type2, result);

  rule(emptyType, emptyType, emptyType);
  rule(emptyType, dynamicType, emptyType);
  rule(emptyType, jsBoolean, emptyType);
  rule(emptyType, jsNumber, emptyType);
  rule(emptyType, jsInteger, emptyType);
  rule(emptyType, jsDouble, emptyType);
  rule(emptyType, jsIndexable, emptyType);
  rule(emptyType, jsString, emptyType);
  rule(emptyType, jsReadableArray, emptyType);
  rule(emptyType, jsMutableArray, emptyType);
  rule(emptyType, jsExtendableArray, emptyType);
  rule(emptyType, jsUnmodifiableArray, emptyType);
  rule(emptyType, nonPrimitive1, emptyType);
  rule(emptyType, nonPrimitive2, emptyType);
  rule(emptyType, potentialArray, emptyType);
  rule(emptyType, potentialString, emptyType);
  rule(emptyType, jsBooleanOrNull, emptyType);
  rule(emptyType, jsNumberOrNull, emptyType);
  rule(emptyType, jsIntegerOrNull, emptyType);
  rule(emptyType, jsDoubleOrNull, emptyType);
  rule(emptyType, jsStringOrNull, emptyType);
  rule(emptyType, nullType, emptyType);
  rule(emptyType, jsFixedArray, emptyType);

  rule(dynamicType, dynamicType, dynamicType);
  rule(dynamicType, jsBoolean, jsBoolean);
  rule(dynamicType, jsNumber, jsNumber);
  rule(dynamicType, jsInteger, jsInteger);
  rule(dynamicType, jsDouble, jsDouble);
  rule(dynamicType, jsIndexable, jsIndexable);
  rule(dynamicType, jsString, jsString);
  rule(dynamicType, jsReadableArray, jsReadableArray);
  rule(dynamicType, jsMutableArray, jsMutableArray);
  rule(dynamicType, jsExtendableArray, jsExtendableArray);
  rule(dynamicType, jsUnmodifiableArray, jsUnmodifiableArray);
  rule(dynamicType, nonPrimitive1, nonPrimitive1);
  rule(dynamicType, nonPrimitive2, nonPrimitive2);
  rule(dynamicType, potentialArray, potentialArray);
  rule(dynamicType, potentialString, potentialString);
  rule(dynamicType, jsBooleanOrNull, jsBooleanOrNull);
  rule(dynamicType, jsNumberOrNull, jsNumberOrNull);
  rule(dynamicType, jsIntegerOrNull, jsIntegerOrNull);
  rule(dynamicType, jsDoubleOrNull, jsDoubleOrNull);
  rule(dynamicType, jsStringOrNull, jsStringOrNull);
  rule(dynamicType, nullType, nullType);
  rule(dynamicType, jsFixedArray, jsFixedArray);

  rule(jsBoolean, jsBoolean, jsBoolean);
  rule(jsBoolean, jsNumber, emptyType);
  rule(jsBoolean, jsInteger, emptyType);
  rule(jsBoolean, jsDouble, emptyType);
  rule(jsBoolean, jsIndexable, emptyType);
  rule(jsBoolean, jsString, emptyType);
  rule(jsBoolean, jsReadableArray, emptyType);
  rule(jsBoolean, jsMutableArray, emptyType);
  rule(jsBoolean, jsExtendableArray, emptyType);
  rule(jsBoolean, jsUnmodifiableArray, emptyType);
  rule(jsBoolean, nonPrimitive1, emptyType);
  rule(jsBoolean, nonPrimitive2, emptyType);
  rule(jsBoolean, potentialArray, emptyType);
  rule(jsBoolean, potentialString, emptyType);
  rule(jsBoolean, jsBooleanOrNull, jsBoolean);
  rule(jsBoolean, jsNumberOrNull, emptyType);
  rule(jsBoolean, jsIntegerOrNull, emptyType);
  rule(jsBoolean, jsDoubleOrNull, emptyType);
  rule(jsBoolean, jsStringOrNull, emptyType);
  rule(jsBoolean, nullType, emptyType);
  rule(jsBoolean, jsFixedArray, emptyType);

  rule(jsNumber, jsNumber, jsNumber);
  rule(jsNumber, jsInteger, jsInteger);
  rule(jsNumber, jsDouble, jsDouble);
  rule(jsNumber, jsIndexable, emptyType);
  rule(jsNumber, jsString, emptyType);
  rule(jsNumber, jsReadableArray, emptyType);
  rule(jsNumber, jsMutableArray, emptyType);
  rule(jsNumber, jsExtendableArray, emptyType);
  rule(jsNumber, jsUnmodifiableArray, emptyType);
  rule(jsNumber, nonPrimitive1, emptyType);
  rule(jsNumber, nonPrimitive2, emptyType);
  rule(jsNumber, potentialArray, emptyType);
  rule(jsNumber, potentialString, emptyType);
  rule(jsNumber, jsBooleanOrNull, emptyType);
  rule(jsNumber, jsNumberOrNull, jsNumber);
  rule(jsNumber, jsIntegerOrNull, jsInteger);
  rule(jsNumber, jsDoubleOrNull, jsDouble);
  rule(jsNumber, jsStringOrNull, emptyType);
  rule(jsNumber, nullType, emptyType);
  rule(jsNumber, jsFixedArray, emptyType);

  rule(jsInteger, jsInteger, jsInteger);
  rule(jsInteger, jsDouble, emptyType);
  rule(jsInteger, jsIndexable, emptyType);
  rule(jsInteger, jsString, emptyType);
  rule(jsInteger, jsReadableArray, emptyType);
  rule(jsInteger, jsMutableArray, emptyType);
  rule(jsInteger, jsExtendableArray, emptyType);
  rule(jsInteger, jsUnmodifiableArray, emptyType);
  rule(jsInteger, nonPrimitive1, emptyType);
  rule(jsInteger, nonPrimitive2, emptyType);
  rule(jsInteger, potentialArray, emptyType);
  rule(jsInteger, potentialString, emptyType);
  rule(jsInteger, jsBooleanOrNull, emptyType);
  rule(jsInteger, jsNumberOrNull, jsInteger);
  rule(jsInteger, jsIntegerOrNull, jsInteger);
  rule(jsInteger, jsDoubleOrNull, emptyType);
  rule(jsInteger, jsStringOrNull, emptyType);
  rule(jsInteger, nullType, emptyType);
  rule(jsInteger, jsFixedArray, emptyType);

  rule(jsDouble, jsDouble, jsDouble);
  rule(jsDouble, jsIndexable, emptyType);
  rule(jsDouble, jsString, emptyType);
  rule(jsDouble, jsReadableArray, emptyType);
  rule(jsDouble, jsMutableArray, emptyType);
  rule(jsDouble, jsExtendableArray, emptyType);
  rule(jsDouble, jsUnmodifiableArray, emptyType);
  rule(jsDouble, nonPrimitive1, emptyType);
  rule(jsDouble, nonPrimitive2, emptyType);
  rule(jsDouble, potentialArray, emptyType);
  rule(jsDouble, potentialString, emptyType);
  rule(jsDouble, jsBooleanOrNull, emptyType);
  rule(jsDouble, jsNumberOrNull, jsDouble);
  rule(jsDouble, jsIntegerOrNull, emptyType);
  rule(jsDouble, jsDoubleOrNull, jsDouble);
  rule(jsDouble, jsStringOrNull, emptyType);
  rule(jsDouble, nullType, emptyType);
  rule(jsDouble, jsFixedArray, emptyType);

  rule(jsIndexable, jsIndexable, jsIndexable);
  rule(jsIndexable, jsString, jsString);
  rule(jsIndexable, jsReadableArray, jsReadableArray);
  rule(jsIndexable, jsMutableArray, jsMutableArray);
  rule(jsIndexable, jsExtendableArray, jsExtendableArray);
  rule(jsIndexable, jsUnmodifiableArray, jsUnmodifiableArray);
  rule(jsIndexable, nonPrimitive1, emptyType);
  rule(jsIndexable, nonPrimitive2, emptyType);
  rule(
      jsIndexable,
      potentialArray,
      new TypeMask.nonNullSubtype(
          closedWorld.commonElements.jsArrayClass, closedWorld));
  rule(
      jsIndexable,
      potentialString,
      new TypeMask.nonNullSubtype(
          closedWorld.commonElements.jsStringClass, closedWorld));
  rule(jsIndexable, jsBooleanOrNull, emptyType);
  rule(jsIndexable, jsNumberOrNull, emptyType);
  rule(jsIndexable, jsIntegerOrNull, emptyType);
  rule(jsIndexable, jsDoubleOrNull, emptyType);
  rule(jsIndexable, jsStringOrNull, jsString);
  rule(jsIndexable, nullType, emptyType);
  rule(jsIndexable, jsFixedArray, jsFixedArray);

  rule(jsString, jsString, jsString);
  rule(jsString, jsReadableArray, emptyType);
  rule(jsString, jsMutableArray, emptyType);
  rule(jsString, jsExtendableArray, emptyType);
  rule(jsString, jsUnmodifiableArray, emptyType);
  rule(jsString, nonPrimitive1, emptyType);
  rule(jsString, nonPrimitive2, emptyType);
  rule(jsString, potentialArray, emptyType);
  rule(jsString, potentialString, jsString);
  rule(jsString, jsBooleanOrNull, emptyType);
  rule(jsString, jsNumberOrNull, emptyType);
  rule(jsString, jsIntegerOrNull, emptyType);
  rule(jsString, jsDoubleOrNull, emptyType);
  rule(jsString, jsStringOrNull, jsString);
  rule(jsString, nullType, emptyType);
  rule(jsString, jsFixedArray, emptyType);

  rule(jsReadableArray, jsReadableArray, jsReadableArray);
  rule(jsReadableArray, jsMutableArray, jsMutableArray);
  rule(jsReadableArray, jsExtendableArray, jsExtendableArray);
  rule(jsReadableArray, jsUnmodifiableArray, jsUnmodifiableArray);
  rule(jsReadableArray, nonPrimitive1, emptyType);
  rule(jsReadableArray, nonPrimitive2, emptyType);
  rule(jsReadableArray, potentialArray, jsReadableArray);
  rule(jsReadableArray, potentialString, emptyType);
  rule(jsReadableArray, jsBooleanOrNull, emptyType);
  rule(jsReadableArray, jsNumberOrNull, emptyType);
  rule(jsReadableArray, jsIntegerOrNull, emptyType);
  rule(jsReadableArray, jsDoubleOrNull, emptyType);
  rule(jsReadableArray, jsStringOrNull, emptyType);
  rule(jsReadableArray, nullType, emptyType);
  rule(jsReadableArray, jsFixedArray, jsFixedArray);

  rule(jsMutableArray, jsMutableArray, jsMutableArray);
  rule(jsMutableArray, jsExtendableArray, jsExtendableArray);
  rule(jsMutableArray, jsUnmodifiableArray, emptyType);
  rule(jsMutableArray, nonPrimitive1, emptyType);
  rule(jsMutableArray, nonPrimitive2, emptyType);
  rule(jsMutableArray, potentialArray, jsMutableArray);
  rule(jsMutableArray, potentialString, emptyType);
  rule(jsMutableArray, jsBooleanOrNull, emptyType);
  rule(jsMutableArray, jsNumberOrNull, emptyType);
  rule(jsMutableArray, jsIntegerOrNull, emptyType);
  rule(jsMutableArray, jsDoubleOrNull, emptyType);
  rule(jsMutableArray, jsStringOrNull, emptyType);
  rule(jsMutableArray, nullType, emptyType);
  rule(jsMutableArray, jsFixedArray, jsFixedArray);

  rule(jsExtendableArray, jsExtendableArray, jsExtendableArray);
  rule(jsExtendableArray, jsUnmodifiableArray, emptyType);
  rule(jsExtendableArray, nonPrimitive1, emptyType);
  rule(jsExtendableArray, nonPrimitive2, emptyType);
  rule(jsExtendableArray, potentialArray, jsExtendableArray);
  rule(jsExtendableArray, potentialString, emptyType);
  rule(jsExtendableArray, jsBooleanOrNull, emptyType);
  rule(jsExtendableArray, jsNumberOrNull, emptyType);
  rule(jsExtendableArray, jsIntegerOrNull, emptyType);
  rule(jsExtendableArray, jsDoubleOrNull, emptyType);
  rule(jsExtendableArray, jsStringOrNull, emptyType);
  rule(jsExtendableArray, nullType, emptyType);
  rule(jsExtendableArray, jsFixedArray, emptyType);

  rule(jsUnmodifiableArray, jsUnmodifiableArray, jsUnmodifiableArray);
  rule(jsUnmodifiableArray, nonPrimitive1, emptyType);
  rule(jsUnmodifiableArray, nonPrimitive2, emptyType);
  rule(jsUnmodifiableArray, potentialArray, jsUnmodifiableArray);
  rule(jsUnmodifiableArray, potentialString, emptyType);
  rule(jsUnmodifiableArray, jsBooleanOrNull, emptyType);
  rule(jsUnmodifiableArray, jsNumberOrNull, emptyType);
  rule(jsUnmodifiableArray, jsIntegerOrNull, emptyType);
  rule(jsUnmodifiableArray, jsDoubleOrNull, emptyType);
  rule(jsUnmodifiableArray, jsStringOrNull, emptyType);
  rule(jsUnmodifiableArray, nullType, emptyType);
  rule(jsUnmodifiableArray, jsFixedArray, emptyType);

  rule(nonPrimitive1, nonPrimitive1, nonPrimitive1);
  rule(nonPrimitive1, nonPrimitive2, emptyType);
  rule(nonPrimitive1, potentialArray, emptyType);
  rule(nonPrimitive1, potentialString, emptyType);
  rule(nonPrimitive1, jsBooleanOrNull, emptyType);
  rule(nonPrimitive1, jsNumberOrNull, emptyType);
  rule(nonPrimitive1, jsIntegerOrNull, emptyType);
  rule(nonPrimitive1, jsDoubleOrNull, emptyType);
  rule(nonPrimitive1, jsStringOrNull, emptyType);
  rule(nonPrimitive1, nullType, emptyType);
  rule(nonPrimitive1, jsFixedArray, emptyType);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, emptyType);
  rule(nonPrimitive2, potentialString, emptyType);
  rule(nonPrimitive2, jsBooleanOrNull, emptyType);
  rule(nonPrimitive2, jsNumberOrNull, emptyType);
  rule(nonPrimitive2, jsIntegerOrNull, emptyType);
  rule(nonPrimitive2, jsDoubleOrNull, emptyType);
  rule(nonPrimitive2, jsStringOrNull, emptyType);
  rule(nonPrimitive2, nullType, emptyType);
  rule(nonPrimitive2, jsFixedArray, emptyType);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, nullType);
  rule(potentialArray, jsBooleanOrNull, nullType);
  rule(potentialArray, jsNumberOrNull, nullType);
  rule(potentialArray, jsIntegerOrNull, nullType);
  rule(potentialArray, jsDoubleOrNull, nullType);
  rule(potentialArray, jsStringOrNull, nullType);
  rule(potentialArray, nullType, nullType);
  rule(potentialArray, jsFixedArray, jsFixedArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, jsBooleanOrNull, nullType);
  rule(potentialString, jsNumberOrNull, nullType);
  rule(potentialString, jsIntegerOrNull, nullType);
  rule(potentialString, jsDoubleOrNull, nullType);
  rule(potentialString, jsStringOrNull, jsStringOrNull);
  rule(potentialString, nullType, nullType);
  rule(potentialString, jsFixedArray, emptyType);

  rule(jsBooleanOrNull, jsBooleanOrNull, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsNumberOrNull, nullType);
  rule(jsBooleanOrNull, jsIntegerOrNull, nullType);
  rule(jsBooleanOrNull, jsDoubleOrNull, nullType);
  rule(jsBooleanOrNull, jsStringOrNull, nullType);
  rule(jsBooleanOrNull, nullType, nullType);
  rule(jsBooleanOrNull, jsFixedArray, emptyType);

  rule(jsNumberOrNull, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsNumberOrNull, jsDoubleOrNull, jsDoubleOrNull);
  rule(jsNumberOrNull, jsStringOrNull, nullType);
  rule(jsNumberOrNull, nullType, nullType);
  rule(jsNumberOrNull, jsFixedArray, emptyType);

  rule(jsIntegerOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsDoubleOrNull, nullType);
  rule(jsIntegerOrNull, jsStringOrNull, nullType);
  rule(jsIntegerOrNull, nullType, nullType);
  rule(jsIntegerOrNull, jsFixedArray, emptyType);

  rule(jsDoubleOrNull, jsDoubleOrNull, jsDoubleOrNull);
  rule(jsDoubleOrNull, jsStringOrNull, nullType);
  rule(jsDoubleOrNull, nullType, nullType);
  rule(jsDoubleOrNull, jsFixedArray, emptyType);

  rule(jsStringOrNull, jsStringOrNull, jsStringOrNull);
  rule(jsStringOrNull, nullType, nullType);
  rule(jsStringOrNull, jsFixedArray, emptyType);

  rule(nullType, nullType, nullType);
  rule(nullType, jsFixedArray, emptyType);

  rule(jsFixedArray, jsFixedArray, jsFixedArray);

  ruleSet.validateCoverage();
}

void testRegressions(JClosedWorld closedWorld) {
  TypeMask nonNullPotentialString =
      new TypeMask.nonNullSubtype(patternClass, closedWorld);
  Expect.equals(potentialString,
      jsStringOrNull.union(nonNullPotentialString, closedWorld));
}

void main() {
  asyncTest(() async {
    await runTests();
  });
}

runTests() async {
  CompilationResult result = await runCompiler(memorySourceFiles: {
    'main.dart': r'''
    import 'dart:collection';
    class AList<E> extends ListBase<E> {
      noSuchMethod(_) {}
    }
    main() {
      print('${0}${true}${null}${0.5}${[]}${{}}');
      print('${"".split("")}${new RegExp('')}');
      print('${const []}${const {}}${(){}}${new AList()}');
    }
    '''
  }, beforeRun: (compiler) => compiler.stopAfterTypeInference = true);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  CommonElements commonElements = closedWorld.commonElements;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  // Grab hold of a supertype for String so we can produce potential
  // string types.
  LibraryEntity coreLibrary = commonElements.coreLibrary;
  patternClass = elementEnvironment.lookupClass(coreLibrary, 'Pattern');

  nonPrimitive1 = new TypeMask.nonNullSubtype(
      closedWorld.commonElements.mapClass, closedWorld);
  nonPrimitive2 = new TypeMask.nonNullSubtype(
      closedWorld.commonElements.functionClass, closedWorld);
  potentialArray =
      new TypeMask.subtype(closedWorld.commonElements.listClass, closedWorld);
  potentialString = new TypeMask.subtype(patternClass, closedWorld);
  jsInterceptor = new TypeMask.nonNullSubclass(
      closedWorld.commonElements.jsInterceptorClass, closedWorld);
  jsArrayOrNull = new TypeMask.subclass(
      closedWorld.commonElements.jsArrayClass, closedWorld);
  jsReadableArray = new TypeMask.nonNullSubclass(
      closedWorld.commonElements.jsArrayClass, closedWorld);
  jsMutableArrayOrNull = new TypeMask.subclass(
      closedWorld.commonElements.jsMutableArrayClass, closedWorld);
  jsMutableArray = new TypeMask.nonNullSubclass(
      closedWorld.commonElements.jsMutableArrayClass, closedWorld);
  jsFixedArrayOrNull = new TypeMask.exact(
      closedWorld.commonElements.jsFixedArrayClass, closedWorld);
  jsFixedArray = new TypeMask.nonNullExact(
      closedWorld.commonElements.jsFixedArrayClass, closedWorld);
  jsExtendableArrayOrNull = new TypeMask.exact(
      closedWorld.commonElements.jsExtendableArrayClass, closedWorld);
  jsExtendableArray = new TypeMask.nonNullExact(
      closedWorld.commonElements.jsExtendableArrayClass, closedWorld);
  jsUnmodifiableArrayOrNull = new TypeMask.exact(
      closedWorld.commonElements.jsUnmodifiableArrayClass, closedWorld);
  jsUnmodifiableArray = new TypeMask.nonNullExact(
      closedWorld.commonElements.jsUnmodifiableArrayClass, closedWorld);
  jsIndexableOrNull = new TypeMask.subtype(
      closedWorld.commonElements.jsIndexableClass, closedWorld);
  jsIndexable = new TypeMask.nonNullSubtype(
      closedWorld.commonElements.jsIndexableClass, closedWorld);
  jsInterceptorOrNull = new TypeMask.subclass(
      closedWorld.commonElements.jsInterceptorClass, closedWorld);
  jsStringOrNull =
      new TypeMask.exact(closedWorld.commonElements.jsStringClass, closedWorld);
  jsString = new TypeMask.nonNullExact(
      closedWorld.commonElements.jsStringClass, closedWorld);
  jsBoolean = new TypeMask.nonNullExact(
      closedWorld.commonElements.jsBoolClass, closedWorld);
  jsNumber = new TypeMask.nonNullSubclass(
      closedWorld.commonElements.jsNumberClass, closedWorld);
  jsInteger = new TypeMask.nonNullExact(
      closedWorld.commonElements.jsIntClass, closedWorld);
  jsDouble = new TypeMask.nonNullExact(
      closedWorld.commonElements.jsDoubleClass, closedWorld);
  jsBooleanOrNull =
      new TypeMask.exact(closedWorld.commonElements.jsBoolClass, closedWorld);
  jsNumberOrNull = new TypeMask.subclass(
      closedWorld.commonElements.jsNumberClass, closedWorld);
  jsIntegerOrNull =
      new TypeMask.exact(closedWorld.commonElements.jsIntClass, closedWorld);
  jsDoubleOrNull =
      new TypeMask.exact(closedWorld.commonElements.jsDoubleClass, closedWorld);
  nullType = const TypeMask.empty();
  objectType = new TypeMask.nonNullSubclass(
      closedWorld.commonElements.objectClass, closedWorld);
  emptyType = const TypeMask.nonNullEmpty();
  dynamicType = new TypeMask.subclass(
      closedWorld.commonElements.objectClass, closedWorld);

  jsInterceptorOrComparable =
      interceptorOrComparable(closedWorld, nullable: false);
  jsInterceptorOrComparableOrNull =
      interceptorOrComparable(closedWorld, nullable: true);

  Expect.notEquals(
      emptyType, nonPrimitive1, "nonPrimitive1 expected to be non-empty.");
  Expect.notEquals(jsStringOrNull, potentialString,
      "potentialString expected not to be exact JSString");
  Expect.notEquals(jsArrayOrNull, potentialArray,
      "potentialArray expected not to be JSArray subclass");

  testUnion(closedWorld);
  testIntersection(closedWorld);
  testRegressions(closedWorld);
}
