// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import 'type_mask_test_helper.dart';
import 'package:compiler/src/util/memory_compiler.dart';

late TypeMask nullType;
late TypeMask objectType;
late TypeMask jsBoolean;
late TypeMask jsNumber;
late TypeMask jsInteger;
late TypeMask jsNumNotInt;
late TypeMask jsBooleanOrNull;
late TypeMask jsNumberOrNull;
late TypeMask jsIntegerOrNull;
late TypeMask jsNumNotIntOrNull;
late TypeMask emptyType;
late TypeMask dynamicType;

var patternClass;
late TypeMask nonPrimitive1;
late TypeMask nonPrimitive2;
late TypeMask potentialArray;
late TypeMask potentialString;
late TypeMask jsInterceptor;
late TypeMask jsInterceptorOrComparable;
late TypeMask jsTrustedGetRuntimeType;

late TypeMask jsIndexable;
late TypeMask jsReadableArray;
late TypeMask jsMutableArray;
late TypeMask jsFixedArray;
late TypeMask jsExtendableArray;
late TypeMask jsUnmodifiableArray;
late TypeMask jsString;
late TypeMask jsStringOrNull;
late TypeMask jsArrayOrNull;
late TypeMask jsMutableArrayOrNull;
late TypeMask jsFixedArrayOrNull;
late TypeMask jsExtendableArrayOrNull;
late TypeMask jsUnmodifiableArrayOrNull;
late TypeMask jsIndexableOrNull;
late TypeMask jsInterceptorOrNull;
late TypeMask jsInterceptorOrComparableOrNull;
late TypeMask jsTrustedGetRuntimeTypeOrNull;

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
  final Set typesSeen = {};
  final Set pairsSeen = {};

  RuleSet(this.name, this.operate);

  void rule(type1, type2, result) {
    typesSeen
      ..add(type1)
      ..add(type2);
    var pair1 = Pair(type1, type2);
    var pair2 = Pair(type2, type1);
    if (pairsSeen.contains(pair1)) {
      Expect.isFalse(true, 'Redundant rule ($type1, $type2, ...)');
    }
    pairsSeen
      ..add(pair1)
      ..add(pair2);

    var r1 = operate(type1, type2);
    var r2 = operate(type2, type1);
    Expect.equals(result, r1, "Unexpected result of $name($type1,$type2)");
    Expect.equals(r1, r2, 'Symmetry violation of $name($type1,$type2)');
  }

  void check(type1, type2, predicate) {
    typesSeen
      ..add(type1)
      ..add(type2);
    var pair = Pair(type1, type2);
    pairsSeen..add(pair);
    var result = operate(type1, type2);
    Expect.isTrue(predicate(result));
  }

  void validateCoverage() {
    for (var type1 in typesSeen) {
      for (var type2 in typesSeen) {
        var pair = Pair(type1, type2);
        if (!pairsSeen.contains(pair)) {
          Expect.isTrue(false, 'Missing rule: $name($type1, $type2)');
        }
      }
    }
  }
}

void testUnion(JClosedWorld closedWorld) {
  final commonMasks = closedWorld.abstractValueDomain as CommonMasks;
  RuleSet ruleSet = RuleSet(
      'union', (t1, t2) => simplify(t1.union(t2, commonMasks), commonMasks));
  rule(type1, type2, result) => ruleSet.rule(type1, type2, result);
  check(type1, type2, predicate) => ruleSet.check(type1, type2, predicate);

  rule(emptyType, emptyType, emptyType);
  rule(emptyType, dynamicType, dynamicType);
  rule(emptyType, jsBoolean, jsBoolean);
  rule(emptyType, jsNumber, jsNumber);
  rule(emptyType, jsInteger, jsInteger);
  rule(emptyType, jsNumNotInt, jsNumNotInt);
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
  rule(emptyType, jsNumNotIntOrNull, jsNumNotIntOrNull);
  rule(emptyType, jsStringOrNull, jsStringOrNull);
  rule(emptyType, nullType, nullType);
  rule(emptyType, jsFixedArray, jsFixedArray);

  rule(dynamicType, dynamicType, dynamicType);
  rule(dynamicType, jsBoolean, dynamicType);
  rule(dynamicType, jsNumber, dynamicType);
  rule(dynamicType, jsInteger, dynamicType);
  rule(dynamicType, jsNumNotInt, dynamicType);
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
  rule(dynamicType, jsNumNotIntOrNull, dynamicType);
  rule(dynamicType, jsStringOrNull, dynamicType);
  rule(dynamicType, nullType, dynamicType);
  rule(dynamicType, jsFixedArray, dynamicType);

  rule(jsBoolean, jsBoolean, jsBoolean);
  rule(jsBoolean, jsNumber, jsInterceptor);
  rule(jsBoolean, jsInteger, jsTrustedGetRuntimeType);
  rule(jsBoolean, jsNumNotInt, jsTrustedGetRuntimeType);
  rule(jsBoolean, jsIndexable, objectType);
  rule(jsBoolean, jsString, jsTrustedGetRuntimeType);
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
  rule(jsBoolean, jsIntegerOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsBoolean, jsNumNotIntOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsBoolean, jsStringOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsBoolean, nullType, jsBooleanOrNull);
  rule(jsBoolean, jsFixedArray, jsInterceptor);

  rule(jsNumber, jsNumber, jsNumber);
  rule(jsNumber, jsInteger, jsNumber);
  rule(jsNumber, jsNumNotInt, jsNumber);
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
  rule(jsNumber, jsNumNotIntOrNull, jsNumberOrNull);
  rule(jsNumber, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsNumber, nullType, jsNumberOrNull);
  rule(jsNumber, jsFixedArray, jsInterceptor);

  rule(jsInteger, jsInteger, jsInteger);
  rule(jsInteger, jsNumNotInt, jsNumber);
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
  rule(jsInteger, jsBooleanOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsInteger, jsNumberOrNull, jsNumberOrNull);
  rule(jsInteger, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsInteger, jsNumNotIntOrNull, jsNumberOrNull);
  rule(jsInteger, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsInteger, nullType, jsIntegerOrNull);
  rule(jsInteger, jsFixedArray, jsInterceptor);

  rule(jsNumNotInt, jsNumNotInt, jsNumNotInt);
  rule(jsNumNotInt, jsIndexable, objectType);
  rule(jsNumNotInt, jsString, jsInterceptorOrComparable);
  rule(jsNumNotInt, jsReadableArray, jsInterceptor);
  rule(jsNumNotInt, jsMutableArray, jsInterceptor);
  rule(jsNumNotInt, jsExtendableArray, jsInterceptor);
  rule(jsNumNotInt, jsUnmodifiableArray, jsInterceptor);
  rule(jsNumNotInt, nonPrimitive1, objectType);
  rule(jsNumNotInt, nonPrimitive2, objectType);
  rule(jsNumNotInt, potentialArray, dynamicType);
  rule(jsNumNotInt, potentialString, dynamicType);
  rule(jsNumNotInt, jsBooleanOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsNumNotInt, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumNotInt, jsIntegerOrNull, jsNumberOrNull);
  rule(jsNumNotInt, jsNumNotIntOrNull, jsNumNotIntOrNull);
  rule(jsNumNotInt, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsNumNotInt, nullType, jsNumNotIntOrNull);
  rule(jsNumNotInt, jsFixedArray, jsInterceptor);

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
  rule(jsIndexable, jsNumNotIntOrNull, dynamicType);
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
  rule(jsString, jsBooleanOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsString, jsNumberOrNull, jsInterceptorOrComparableOrNull);
  rule(jsString, jsIntegerOrNull, jsInterceptorOrComparableOrNull);
  rule(jsString, jsNumNotIntOrNull, jsInterceptorOrComparableOrNull);
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
  rule(jsReadableArray, jsNumNotIntOrNull, jsInterceptorOrNull);
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
  rule(jsMutableArray, jsNumNotIntOrNull, jsInterceptorOrNull);
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
  rule(jsExtendableArray, jsNumNotIntOrNull, jsInterceptorOrNull);
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
  rule(jsUnmodifiableArray, jsNumNotIntOrNull, jsInterceptorOrNull);
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
  rule(nonPrimitive1, jsNumNotIntOrNull, dynamicType);
  rule(nonPrimitive1, jsStringOrNull, dynamicType);
  rule(nonPrimitive1, jsFixedArray, objectType);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, dynamicType);
  rule(nonPrimitive2, potentialString, dynamicType);
  rule(nonPrimitive2, jsBooleanOrNull, dynamicType);
  rule(nonPrimitive2, jsNumberOrNull, dynamicType);
  rule(nonPrimitive2, jsIntegerOrNull, dynamicType);
  rule(nonPrimitive2, jsNumNotIntOrNull, dynamicType);
  rule(nonPrimitive2, jsStringOrNull, dynamicType);
  rule(nonPrimitive2, jsFixedArray, objectType);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, dynamicType);
  rule(potentialArray, jsBooleanOrNull, dynamicType);
  rule(potentialArray, jsNumberOrNull, dynamicType);
  rule(potentialArray, jsIntegerOrNull, dynamicType);
  rule(potentialArray, jsNumNotIntOrNull, dynamicType);
  rule(potentialArray, jsStringOrNull, dynamicType);
  rule(potentialArray, nullType, potentialArray);
  rule(potentialArray, jsFixedArray, potentialArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, jsBooleanOrNull, dynamicType);
  rule(potentialString, jsNumberOrNull, dynamicType);
  rule(potentialString, jsIntegerOrNull, dynamicType);
  rule(potentialString, jsNumNotIntOrNull, dynamicType);
  rule(potentialString, jsStringOrNull, potentialString);
  rule(potentialString, nullType, potentialString);
  rule(potentialString, jsFixedArray, dynamicType);

  rule(jsBooleanOrNull, jsBooleanOrNull, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, jsIntegerOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsBooleanOrNull, jsNumNotIntOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsBooleanOrNull, jsStringOrNull, jsTrustedGetRuntimeTypeOrNull);
  rule(jsBooleanOrNull, nullType, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsNumberOrNull, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsIntegerOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsNumNotIntOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsNumberOrNull, nullType, jsNumberOrNull);
  rule(jsNumberOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsIntegerOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsNumNotIntOrNull, jsNumberOrNull);
  rule(jsIntegerOrNull, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsIntegerOrNull, nullType, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsNumNotIntOrNull, jsNumNotIntOrNull, jsNumNotIntOrNull);
  rule(jsNumNotIntOrNull, jsStringOrNull, jsInterceptorOrComparableOrNull);
  rule(jsNumNotIntOrNull, nullType, jsNumNotIntOrNull);
  rule(jsNumNotIntOrNull, jsFixedArray, jsInterceptorOrNull);

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
  RuleSet ruleSet = RuleSet('intersection',
      (t1, t2) => t1.intersection(t2, closedWorld.abstractValueDomain));
  rule(type1, type2, result) => ruleSet.rule(type1, type2, result);

  rule(emptyType, emptyType, emptyType);
  rule(emptyType, dynamicType, emptyType);
  rule(emptyType, jsBoolean, emptyType);
  rule(emptyType, jsNumber, emptyType);
  rule(emptyType, jsInteger, emptyType);
  rule(emptyType, jsNumNotInt, emptyType);
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
  rule(emptyType, jsNumNotIntOrNull, emptyType);
  rule(emptyType, jsStringOrNull, emptyType);
  rule(emptyType, nullType, emptyType);
  rule(emptyType, jsFixedArray, emptyType);

  rule(dynamicType, dynamicType, dynamicType);
  rule(dynamicType, jsBoolean, jsBoolean);
  rule(dynamicType, jsNumber, jsNumber);
  rule(dynamicType, jsInteger, jsInteger);
  rule(dynamicType, jsNumNotInt, jsNumNotInt);
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
  rule(dynamicType, jsNumNotIntOrNull, jsNumNotIntOrNull);
  rule(dynamicType, jsStringOrNull, jsStringOrNull);
  rule(dynamicType, nullType, nullType);
  rule(dynamicType, jsFixedArray, jsFixedArray);

  rule(jsBoolean, jsBoolean, jsBoolean);
  rule(jsBoolean, jsNumber, emptyType);
  rule(jsBoolean, jsInteger, emptyType);
  rule(jsBoolean, jsNumNotInt, emptyType);
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
  rule(jsBoolean, jsNumNotIntOrNull, emptyType);
  rule(jsBoolean, jsStringOrNull, emptyType);
  rule(jsBoolean, nullType, emptyType);
  rule(jsBoolean, jsFixedArray, emptyType);

  rule(jsNumber, jsNumber, jsNumber);
  rule(jsNumber, jsInteger, jsInteger);
  rule(jsNumber, jsNumNotInt, jsNumNotInt);
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
  rule(jsNumber, jsNumNotIntOrNull, jsNumNotInt);
  rule(jsNumber, jsStringOrNull, emptyType);
  rule(jsNumber, nullType, emptyType);
  rule(jsNumber, jsFixedArray, emptyType);

  rule(jsInteger, jsInteger, jsInteger);
  rule(jsInteger, jsNumNotInt, emptyType);
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
  rule(jsInteger, jsNumNotIntOrNull, emptyType);
  rule(jsInteger, jsStringOrNull, emptyType);
  rule(jsInteger, nullType, emptyType);
  rule(jsInteger, jsFixedArray, emptyType);

  rule(jsNumNotInt, jsNumNotInt, jsNumNotInt);
  rule(jsNumNotInt, jsIndexable, emptyType);
  rule(jsNumNotInt, jsString, emptyType);
  rule(jsNumNotInt, jsReadableArray, emptyType);
  rule(jsNumNotInt, jsMutableArray, emptyType);
  rule(jsNumNotInt, jsExtendableArray, emptyType);
  rule(jsNumNotInt, jsUnmodifiableArray, emptyType);
  rule(jsNumNotInt, nonPrimitive1, emptyType);
  rule(jsNumNotInt, nonPrimitive2, emptyType);
  rule(jsNumNotInt, potentialArray, emptyType);
  rule(jsNumNotInt, potentialString, emptyType);
  rule(jsNumNotInt, jsBooleanOrNull, emptyType);
  rule(jsNumNotInt, jsNumberOrNull, jsNumNotInt);
  rule(jsNumNotInt, jsIntegerOrNull, emptyType);
  rule(jsNumNotInt, jsNumNotIntOrNull, jsNumNotInt);
  rule(jsNumNotInt, jsStringOrNull, emptyType);
  rule(jsNumNotInt, nullType, emptyType);
  rule(jsNumNotInt, jsFixedArray, emptyType);

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
      TypeMask.nonNullSubtype(
          closedWorld.commonElements.jsArrayClass, closedWorld));
  rule(
      jsIndexable,
      potentialString,
      TypeMask.nonNullSubtype(
          closedWorld.commonElements.jsStringClass, closedWorld));
  rule(jsIndexable, jsBooleanOrNull, emptyType);
  rule(jsIndexable, jsNumberOrNull, emptyType);
  rule(jsIndexable, jsIntegerOrNull, emptyType);
  rule(jsIndexable, jsNumNotIntOrNull, emptyType);
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
  rule(jsString, jsNumNotIntOrNull, emptyType);
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
  rule(jsReadableArray, jsNumNotIntOrNull, emptyType);
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
  rule(jsMutableArray, jsNumNotIntOrNull, emptyType);
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
  rule(jsExtendableArray, jsNumNotIntOrNull, emptyType);
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
  rule(jsUnmodifiableArray, jsNumNotIntOrNull, emptyType);
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
  rule(nonPrimitive1, jsNumNotIntOrNull, emptyType);
  rule(nonPrimitive1, jsStringOrNull, emptyType);
  rule(nonPrimitive1, nullType, emptyType);
  rule(nonPrimitive1, jsFixedArray, emptyType);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, emptyType);
  rule(nonPrimitive2, potentialString, emptyType);
  rule(nonPrimitive2, jsBooleanOrNull, emptyType);
  rule(nonPrimitive2, jsNumberOrNull, emptyType);
  rule(nonPrimitive2, jsIntegerOrNull, emptyType);
  rule(nonPrimitive2, jsNumNotIntOrNull, emptyType);
  rule(nonPrimitive2, jsStringOrNull, emptyType);
  rule(nonPrimitive2, nullType, emptyType);
  rule(nonPrimitive2, jsFixedArray, emptyType);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, nullType);
  rule(potentialArray, jsBooleanOrNull, nullType);
  rule(potentialArray, jsNumberOrNull, nullType);
  rule(potentialArray, jsIntegerOrNull, nullType);
  rule(potentialArray, jsNumNotIntOrNull, nullType);
  rule(potentialArray, jsStringOrNull, nullType);
  rule(potentialArray, nullType, nullType);
  rule(potentialArray, jsFixedArray, jsFixedArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, jsBooleanOrNull, nullType);
  rule(potentialString, jsNumberOrNull, nullType);
  rule(potentialString, jsIntegerOrNull, nullType);
  rule(potentialString, jsNumNotIntOrNull, nullType);
  rule(potentialString, jsStringOrNull, jsStringOrNull);
  rule(potentialString, nullType, nullType);
  rule(potentialString, jsFixedArray, emptyType);

  rule(jsBooleanOrNull, jsBooleanOrNull, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsNumberOrNull, nullType);
  rule(jsBooleanOrNull, jsIntegerOrNull, nullType);
  rule(jsBooleanOrNull, jsNumNotIntOrNull, nullType);
  rule(jsBooleanOrNull, jsStringOrNull, nullType);
  rule(jsBooleanOrNull, nullType, nullType);
  rule(jsBooleanOrNull, jsFixedArray, emptyType);

  rule(jsNumberOrNull, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsNumberOrNull, jsNumNotIntOrNull, jsNumNotIntOrNull);
  rule(jsNumberOrNull, jsStringOrNull, nullType);
  rule(jsNumberOrNull, nullType, nullType);
  rule(jsNumberOrNull, jsFixedArray, emptyType);

  rule(jsIntegerOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsNumNotIntOrNull, nullType);
  rule(jsIntegerOrNull, jsStringOrNull, nullType);
  rule(jsIntegerOrNull, nullType, nullType);
  rule(jsIntegerOrNull, jsFixedArray, emptyType);

  rule(jsNumNotIntOrNull, jsNumNotIntOrNull, jsNumNotIntOrNull);
  rule(jsNumNotIntOrNull, jsStringOrNull, nullType);
  rule(jsNumNotIntOrNull, nullType, nullType);
  rule(jsNumNotIntOrNull, jsFixedArray, emptyType);

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
      TypeMask.nonNullSubtype(patternClass, closedWorld);
  Expect.equals(
      potentialString,
      jsStringOrNull.union(nonNullPotentialString,
          closedWorld.abstractValueDomain as CommonMasks));
}

void main() {
  asyncTest(() async {
    await runTests();
  });
}

runTests() async {
  CompilationResult result = await runCompiler(
      memorySourceFiles: {
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
      },
      beforeRun: (compiler) =>
          compiler.stopAfterGlobalTypeInferenceForTesting = true);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
  CommonElements commonElements = closedWorld.commonElements;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  // Grab hold of a supertype for String so we can produce potential
  // string types.
  LibraryEntity coreLibrary = commonElements.coreLibrary;
  patternClass = elementEnvironment.lookupClass(coreLibrary, 'Pattern');

  final trustedGetRuntimeTypeInterface = elementEnvironment.lookupClass(
      commonElements.rtiLibrary, 'TrustedGetRuntimeType')!;

  nonPrimitive1 =
      TypeMask.nonNullSubtype(closedWorld.commonElements.mapClass, closedWorld);
  nonPrimitive2 = TypeMask.nonNullSubtype(
      closedWorld.commonElements.functionClass, closedWorld);
  potentialArray =
      TypeMask.subtype(closedWorld.commonElements.listClass, closedWorld);
  potentialString = TypeMask.subtype(patternClass, closedWorld);
  jsInterceptor = TypeMask.nonNullSubclass(
      closedWorld.commonElements.jsInterceptorClass, closedWorld);
  jsTrustedGetRuntimeType =
      TypeMask.nonNullSubtype(trustedGetRuntimeTypeInterface, closedWorld);
  jsArrayOrNull =
      TypeMask.subclass(closedWorld.commonElements.jsArrayClass, closedWorld);
  jsReadableArray = TypeMask.nonNullSubclass(
      closedWorld.commonElements.jsArrayClass, closedWorld);
  jsMutableArrayOrNull = TypeMask.subclass(
      closedWorld.commonElements.jsMutableArrayClass, closedWorld);
  jsMutableArray = TypeMask.nonNullSubclass(
      closedWorld.commonElements.jsMutableArrayClass, closedWorld);
  jsFixedArrayOrNull =
      TypeMask.exact(closedWorld.commonElements.jsFixedArrayClass, closedWorld);
  jsFixedArray = TypeMask.nonNullExact(
      closedWorld.commonElements.jsFixedArrayClass, closedWorld);
  jsExtendableArrayOrNull = TypeMask.exact(
      closedWorld.commonElements.jsExtendableArrayClass, closedWorld);
  jsExtendableArray = TypeMask.nonNullExact(
      closedWorld.commonElements.jsExtendableArrayClass, closedWorld);
  jsUnmodifiableArrayOrNull = TypeMask.exact(
      closedWorld.commonElements.jsUnmodifiableArrayClass, closedWorld);
  jsUnmodifiableArray = TypeMask.nonNullExact(
      closedWorld.commonElements.jsUnmodifiableArrayClass, closedWorld);
  jsIndexableOrNull = TypeMask.subtype(
      closedWorld.commonElements.jsIndexableClass, closedWorld);
  jsIndexable = TypeMask.nonNullSubtype(
      closedWorld.commonElements.jsIndexableClass, closedWorld);
  jsInterceptorOrNull = TypeMask.subclass(
      closedWorld.commonElements.jsInterceptorClass, closedWorld);
  jsTrustedGetRuntimeTypeOrNull =
      TypeMask.subtype(trustedGetRuntimeTypeInterface, closedWorld);
  jsStringOrNull =
      TypeMask.exact(closedWorld.commonElements.jsStringClass, closedWorld);
  jsString = TypeMask.nonNullExact(
      closedWorld.commonElements.jsStringClass, closedWorld);
  jsBoolean = TypeMask.nonNullExact(
      closedWorld.commonElements.jsBoolClass, closedWorld);
  jsNumber = TypeMask.nonNullSubclass(
      closedWorld.commonElements.jsNumberClass, closedWorld);
  jsInteger =
      TypeMask.nonNullExact(closedWorld.commonElements.jsIntClass, closedWorld);
  jsNumNotInt = TypeMask.nonNullExact(
      closedWorld.commonElements.jsNumNotIntClass, closedWorld);
  jsBooleanOrNull =
      TypeMask.exact(closedWorld.commonElements.jsBoolClass, closedWorld);
  jsNumberOrNull =
      TypeMask.subclass(closedWorld.commonElements.jsNumberClass, closedWorld);
  jsIntegerOrNull =
      TypeMask.exact(closedWorld.commonElements.jsIntClass, closedWorld);
  jsNumNotIntOrNull =
      TypeMask.exact(closedWorld.commonElements.jsNumNotIntClass, closedWorld);
  nullType = TypeMask.empty();
  objectType = TypeMask.nonNullSubclass(
      closedWorld.commonElements.objectClass, closedWorld);
  emptyType = TypeMask.nonNullEmpty();
  dynamicType =
      TypeMask.subclass(closedWorld.commonElements.objectClass, closedWorld);

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
