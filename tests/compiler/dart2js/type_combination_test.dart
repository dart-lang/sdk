// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "compiler_helper.dart";
import "parser_helper.dart";
import "../../../sdk/lib/_internal/compiler/implementation/ssa/ssa.dart";
import "../../../sdk/lib/_internal/compiler/implementation/types/types.dart";

const CONFLICTING = HType.CONFLICTING;
const UNKNOWN = HType.UNKNOWN;
const NULL = HType.NULL;
const NON_NULL = HType.NON_NULL;

HType jsBoolean;
HType jsNumber;
HType jsInteger;
HType jsDouble;
HType jsBooleanOrNull;
HType jsNumberOrNull;
HType jsIntegerOrNull;
HType jsDoubleOrNull;

var patternClass;
HType nonPrimitive1;
HType nonPrimitive2;
HType potentialArray;
HType potentialString;
HType jsInterceptor;

HType jsIndexable;
HType jsReadableArray;
HType jsMutableArray;
HType jsFixedArray;
HType jsExtendableArray;
HType jsString;
HType jsStringOrNull;
HType jsArrayOrNull;
HType jsMutableArrayOrNull;
HType jsFixedArrayOrNull;
HType jsExtendableArrayOrNull;
HType jsIndexableOrNull;
HType jsInterceptorOrNull;


class Pair {
  final first;
  final second;
  Pair(this.first, this.second);
  int get hashCode => first.hashCode * 47 + second.hashCode;
  bool operator==(Pair other) =>
      identical(first, other.first) && identical(second, other.second);
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
    Expect.equals(result, r1);
    Expect.equals(r1, r2, 'symmetry violation');
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

void testUnion(MockCompiler compiler) {
  RuleSet ruleSet = new RuleSet('union',
      (t1, t2) => t1.union(t2, compiler).simplify(compiler));
  rule(type1, type2, result) => ruleSet.rule(type1, type2, result);
  check(type1, type2, predicate) => ruleSet.check(type1, type2, predicate);

  rule(CONFLICTING, CONFLICTING, CONFLICTING);
  rule(CONFLICTING, UNKNOWN, UNKNOWN);
  rule(CONFLICTING, jsBoolean, jsBoolean);
  rule(CONFLICTING, jsNumber, jsNumber);
  rule(CONFLICTING, jsInteger, jsInteger);
  rule(CONFLICTING, jsDouble, jsDouble);
  rule(CONFLICTING, jsIndexable, jsIndexable);
  rule(CONFLICTING, jsString, jsString);
  rule(CONFLICTING, jsReadableArray, jsReadableArray);
  rule(CONFLICTING, jsMutableArray, jsMutableArray);
  rule(CONFLICTING, jsExtendableArray, jsExtendableArray);
  rule(CONFLICTING, nonPrimitive1, nonPrimitive1);
  rule(CONFLICTING, nonPrimitive2, nonPrimitive2);
  rule(CONFLICTING, potentialArray, potentialArray);
  rule(CONFLICTING, potentialString, potentialString);
  rule(CONFLICTING, jsBooleanOrNull, jsBooleanOrNull);
  rule(CONFLICTING, jsNumberOrNull, jsNumberOrNull);
  rule(CONFLICTING, jsIntegerOrNull, jsIntegerOrNull);
  rule(CONFLICTING, jsDoubleOrNull, jsDoubleOrNull);
  rule(CONFLICTING, jsStringOrNull, jsStringOrNull);
  rule(CONFLICTING, NULL, NULL);
  rule(CONFLICTING, jsFixedArray, jsFixedArray);

  rule(UNKNOWN, UNKNOWN, UNKNOWN);
  rule(UNKNOWN, jsBoolean, UNKNOWN);
  rule(UNKNOWN, jsNumber, UNKNOWN);
  rule(UNKNOWN, jsInteger, UNKNOWN);
  rule(UNKNOWN, jsDouble, UNKNOWN);
  rule(UNKNOWN, jsIndexable, UNKNOWN);
  rule(UNKNOWN, jsString, UNKNOWN);
  rule(UNKNOWN, jsReadableArray, UNKNOWN);
  rule(UNKNOWN, jsMutableArray, UNKNOWN);
  rule(UNKNOWN, jsExtendableArray, UNKNOWN);
  rule(UNKNOWN, nonPrimitive1, UNKNOWN);
  rule(UNKNOWN, nonPrimitive2, UNKNOWN);
  rule(UNKNOWN, potentialArray, UNKNOWN);
  rule(UNKNOWN, potentialString, UNKNOWN);
  rule(UNKNOWN, jsBooleanOrNull, UNKNOWN);
  rule(UNKNOWN, jsNumberOrNull, UNKNOWN);
  rule(UNKNOWN, jsIntegerOrNull, UNKNOWN);
  rule(UNKNOWN, jsDoubleOrNull, UNKNOWN);
  rule(UNKNOWN, jsStringOrNull, UNKNOWN);
  rule(UNKNOWN, NULL, UNKNOWN);
  rule(UNKNOWN, jsFixedArray, UNKNOWN);

  rule(jsBoolean, jsBoolean, jsBoolean);
  rule(jsBoolean, jsNumber, jsInterceptor);
  rule(jsBoolean, jsInteger, jsInterceptor);
  rule(jsBoolean, jsDouble, jsInterceptor);
  rule(jsBoolean, jsIndexable, NON_NULL);
  rule(jsBoolean, jsString, jsInterceptor);
  rule(jsBoolean, jsReadableArray, jsInterceptor);
  rule(jsBoolean, jsMutableArray, jsInterceptor);
  rule(jsBoolean, jsExtendableArray, jsInterceptor);
  rule(jsBoolean, nonPrimitive1, NON_NULL);
  rule(jsBoolean, nonPrimitive2, NON_NULL);
  rule(jsBoolean, potentialArray, UNKNOWN);
  rule(jsBoolean, potentialString, UNKNOWN);
  rule(jsBoolean, jsBooleanOrNull, jsBooleanOrNull);
  rule(jsBoolean, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsBoolean, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsBoolean, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsBoolean, jsStringOrNull, jsInterceptorOrNull);
  rule(jsBoolean, NULL, jsBooleanOrNull);
  rule(jsBoolean, jsFixedArray, jsInterceptor);

  rule(jsNumber, jsNumber, jsNumber);
  rule(jsNumber, jsInteger, jsNumber);
  rule(jsNumber, jsDouble, jsNumber);
  rule(jsNumber, jsIndexable, NON_NULL);
  rule(jsNumber, jsString, jsInterceptor);
  rule(jsNumber, jsReadableArray, jsInterceptor);
  rule(jsNumber, jsMutableArray, jsInterceptor);
  rule(jsNumber, jsExtendableArray, jsInterceptor);
  rule(jsNumber, nonPrimitive1, NON_NULL);
  rule(jsNumber, nonPrimitive2, NON_NULL);
  rule(jsNumber, potentialArray, UNKNOWN);
  rule(jsNumber, potentialString, UNKNOWN);
  rule(jsNumber, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsNumber, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumber, jsIntegerOrNull, jsNumberOrNull);
  rule(jsNumber, jsDoubleOrNull, jsNumberOrNull);
  rule(jsNumber, jsStringOrNull, jsInterceptorOrNull);
  rule(jsNumber, NULL, jsNumberOrNull);
  rule(jsNumber, jsFixedArray, jsInterceptor);

  rule(jsInteger, jsInteger, jsInteger);
  rule(jsInteger, jsDouble, jsNumber);
  rule(jsInteger, jsIndexable, NON_NULL);
  rule(jsInteger, jsString, jsInterceptor);
  rule(jsInteger, jsReadableArray, jsInterceptor);
  rule(jsInteger, jsMutableArray, jsInterceptor);
  rule(jsInteger, jsExtendableArray, jsInterceptor);
  rule(jsInteger, nonPrimitive1, NON_NULL);
  rule(jsInteger, nonPrimitive2, NON_NULL);
  rule(jsInteger, potentialArray, UNKNOWN);
  rule(jsInteger, potentialString, UNKNOWN);
  rule(jsInteger, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsInteger, jsNumberOrNull, jsNumberOrNull);
  rule(jsInteger, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsInteger, jsDoubleOrNull, jsNumberOrNull);
  rule(jsInteger, jsStringOrNull, jsInterceptorOrNull);
  rule(jsInteger, NULL, jsIntegerOrNull);
  rule(jsInteger, jsFixedArray, jsInterceptor);

  rule(jsDouble, jsDouble, jsDouble);
  rule(jsDouble, jsIndexable, NON_NULL);
  rule(jsDouble, jsString, jsInterceptor);
  rule(jsDouble, jsReadableArray, jsInterceptor);
  rule(jsDouble, jsMutableArray, jsInterceptor);
  rule(jsDouble, jsExtendableArray, jsInterceptor);
  rule(jsDouble, nonPrimitive1, NON_NULL);
  rule(jsDouble, nonPrimitive2, NON_NULL);
  rule(jsDouble, potentialArray, UNKNOWN);
  rule(jsDouble, potentialString, UNKNOWN);
  rule(jsDouble, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsDouble, jsNumberOrNull, jsNumberOrNull);
  rule(jsDouble, jsIntegerOrNull, jsNumberOrNull);
  rule(jsDouble, jsDoubleOrNull, jsDoubleOrNull);
  rule(jsDouble, jsStringOrNull, jsInterceptorOrNull);
  rule(jsDouble, NULL, jsDoubleOrNull);
  rule(jsDouble, jsFixedArray, jsInterceptor);

  rule(jsIndexable, jsIndexable, jsIndexable);
  rule(jsIndexable, jsString, jsIndexable);
  rule(jsIndexable, jsReadableArray, jsIndexable);
  rule(jsIndexable, jsMutableArray, jsIndexable);
  rule(jsIndexable, jsExtendableArray, jsIndexable);
  rule(jsIndexable, nonPrimitive1, NON_NULL);
  rule(jsIndexable, nonPrimitive2, NON_NULL);
  rule(jsIndexable, potentialArray, UNKNOWN);
  rule(jsIndexable, potentialString, UNKNOWN);
  rule(jsIndexable, jsBooleanOrNull, UNKNOWN);
  rule(jsIndexable, jsNumberOrNull, UNKNOWN);
  rule(jsIndexable, jsIntegerOrNull, UNKNOWN);
  rule(jsIndexable, jsDoubleOrNull, UNKNOWN);
  rule(jsIndexable, jsStringOrNull, jsIndexableOrNull);
  rule(jsIndexable, NULL, jsIndexableOrNull);
  rule(jsIndexable, jsFixedArray, jsIndexable);

  rule(jsString, jsString, jsString);
  rule(jsString, jsReadableArray, jsIndexable);
  rule(jsString, jsMutableArray, jsIndexable);
  rule(jsString, jsExtendableArray, jsIndexable);
  rule(jsString, nonPrimitive1, NON_NULL);
  rule(jsString, nonPrimitive2, NON_NULL);
  rule(jsString, potentialArray, UNKNOWN);
  rule(jsString, potentialString, potentialString);
  rule(jsString, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsString, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsString, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsString, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsString, jsStringOrNull, jsStringOrNull);
  rule(jsString, NULL, jsStringOrNull);
  rule(jsString, jsFixedArray, jsIndexable);

  rule(jsReadableArray, jsReadableArray, jsReadableArray);
  rule(jsReadableArray, jsMutableArray, jsReadableArray);
  rule(jsReadableArray, jsExtendableArray, jsReadableArray);
  rule(jsReadableArray, nonPrimitive1, NON_NULL);
  rule(jsReadableArray, nonPrimitive2, NON_NULL);
  rule(jsReadableArray, potentialArray, potentialArray);
  rule(jsReadableArray, potentialString, UNKNOWN);
  rule(jsReadableArray, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsReadableArray, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsReadableArray, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsReadableArray, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsReadableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsReadableArray, NULL, jsArrayOrNull);
  rule(jsReadableArray, jsFixedArray, jsReadableArray);

  rule(jsMutableArray, jsMutableArray, jsMutableArray);
  rule(jsMutableArray, jsExtendableArray, jsMutableArray);
  rule(jsMutableArray, nonPrimitive1, NON_NULL);
  rule(jsMutableArray, nonPrimitive2, NON_NULL);
  rule(jsMutableArray, potentialArray, potentialArray);
  rule(jsMutableArray, potentialString, UNKNOWN);
  rule(jsMutableArray, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsMutableArray, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsMutableArray, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsMutableArray, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsMutableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsMutableArray, NULL, jsMutableArrayOrNull);
  rule(jsMutableArray, jsFixedArray, jsMutableArray);

  rule(jsExtendableArray, jsExtendableArray, jsExtendableArray);
  rule(jsExtendableArray, nonPrimitive1, NON_NULL);
  rule(jsExtendableArray, nonPrimitive2, NON_NULL);
  rule(jsExtendableArray, potentialArray, potentialArray);
  rule(jsExtendableArray, potentialString, UNKNOWN);
  rule(jsExtendableArray, jsBooleanOrNull, jsInterceptorOrNull);
  rule(jsExtendableArray, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsExtendableArray, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsExtendableArray, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsExtendableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsExtendableArray, NULL, jsExtendableArrayOrNull);
  rule(jsExtendableArray, jsFixedArray, jsMutableArray);

  rule(nonPrimitive1, nonPrimitive1, nonPrimitive1);
  rule(nonPrimitive1, nonPrimitive2, NON_NULL);
  rule(nonPrimitive1, potentialArray, UNKNOWN);
  rule(nonPrimitive1, potentialString, UNKNOWN);
  rule(nonPrimitive1, jsBooleanOrNull, UNKNOWN);
  rule(nonPrimitive1, jsNumberOrNull, UNKNOWN);
  rule(nonPrimitive1, jsIntegerOrNull, UNKNOWN);
  rule(nonPrimitive1, jsDoubleOrNull, UNKNOWN);
  rule(nonPrimitive1, jsStringOrNull, UNKNOWN);
  rule(nonPrimitive1, jsFixedArray, NON_NULL);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, UNKNOWN);
  rule(nonPrimitive2, potentialString, UNKNOWN);
  rule(nonPrimitive2, jsBooleanOrNull, UNKNOWN);
  rule(nonPrimitive2, jsNumberOrNull, UNKNOWN);
  rule(nonPrimitive2, jsIntegerOrNull, UNKNOWN);
  rule(nonPrimitive2, jsDoubleOrNull, UNKNOWN);
  rule(nonPrimitive2, jsStringOrNull, UNKNOWN);
  rule(nonPrimitive2, jsFixedArray, NON_NULL);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, UNKNOWN);
  rule(potentialArray, jsBooleanOrNull, UNKNOWN);
  rule(potentialArray, jsNumberOrNull, UNKNOWN);
  rule(potentialArray, jsIntegerOrNull, UNKNOWN);
  rule(potentialArray, jsDoubleOrNull, UNKNOWN);
  rule(potentialArray, jsStringOrNull, UNKNOWN);
  rule(potentialArray, NULL, potentialArray);
  rule(potentialArray, jsFixedArray, potentialArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, jsBooleanOrNull, UNKNOWN);
  rule(potentialString, jsNumberOrNull, UNKNOWN);
  rule(potentialString, jsIntegerOrNull, UNKNOWN);
  rule(potentialString, jsDoubleOrNull, UNKNOWN);
  rule(potentialString, jsStringOrNull, potentialString);
  rule(potentialString, NULL, potentialString);
  rule(potentialString, jsFixedArray, UNKNOWN);

  rule(jsBooleanOrNull, jsBooleanOrNull, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsNumberOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, jsIntegerOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, jsDoubleOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, jsStringOrNull, jsInterceptorOrNull);
  rule(jsBooleanOrNull, NULL, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsNumberOrNull, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsIntegerOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsDoubleOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsStringOrNull, jsInterceptorOrNull);
  rule(jsNumberOrNull, NULL, jsNumberOrNull);
  rule(jsNumberOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsIntegerOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsDoubleOrNull, jsNumberOrNull);
  rule(jsIntegerOrNull, jsStringOrNull, jsInterceptorOrNull);
  rule(jsIntegerOrNull, NULL, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsDoubleOrNull, jsDoubleOrNull, jsDoubleOrNull);
  rule(jsDoubleOrNull, jsStringOrNull, jsInterceptorOrNull);
  rule(jsDoubleOrNull, NULL, jsDoubleOrNull);
  rule(jsDoubleOrNull, jsFixedArray, jsInterceptorOrNull);

  rule(jsStringOrNull, jsStringOrNull, jsStringOrNull);
  rule(jsStringOrNull, NULL, jsStringOrNull);
  rule(jsStringOrNull, jsFixedArray, jsIndexableOrNull);

  rule(NULL, NULL, NULL);
  rule(NULL, jsFixedArray, jsFixedArrayOrNull);

  rule(jsFixedArray, jsFixedArray, jsFixedArray);

  check(nonPrimitive1, NULL, (type) => type is HBoundedType);
  check(nonPrimitive2, NULL, (type) => type is HBoundedType);
  check(NULL, nonPrimitive1, (type) => type.canBeNull());
  check(NULL, nonPrimitive2, (type) => type.canBeNull());

  ruleSet.validateCoverage();
}

void testIntersection(MockCompiler compiler) {
  RuleSet ruleSet = new RuleSet('intersection',
                                (t1, t2) => t1.intersection(t2, compiler));
  rule(type1, type2, result) => ruleSet.rule(type1, type2, result);

  rule(CONFLICTING, CONFLICTING, CONFLICTING);
  rule(CONFLICTING, UNKNOWN, CONFLICTING);
  rule(CONFLICTING, jsBoolean, CONFLICTING);
  rule(CONFLICTING, jsNumber, CONFLICTING);
  rule(CONFLICTING, jsInteger, CONFLICTING);
  rule(CONFLICTING, jsDouble, CONFLICTING);
  rule(CONFLICTING, jsIndexable, CONFLICTING);
  rule(CONFLICTING, jsString, CONFLICTING);
  rule(CONFLICTING, jsReadableArray, CONFLICTING);
  rule(CONFLICTING, jsMutableArray, CONFLICTING);
  rule(CONFLICTING, jsExtendableArray, CONFLICTING);
  rule(CONFLICTING, nonPrimitive1, CONFLICTING);
  rule(CONFLICTING, nonPrimitive2, CONFLICTING);
  rule(CONFLICTING, potentialArray, CONFLICTING);
  rule(CONFLICTING, potentialString, CONFLICTING);
  rule(CONFLICTING, jsBooleanOrNull, CONFLICTING);
  rule(CONFLICTING, jsNumberOrNull, CONFLICTING);
  rule(CONFLICTING, jsIntegerOrNull, CONFLICTING);
  rule(CONFLICTING, jsDoubleOrNull, CONFLICTING);
  rule(CONFLICTING, jsStringOrNull, CONFLICTING);
  rule(CONFLICTING, NULL, CONFLICTING);
  rule(CONFLICTING, jsFixedArray, CONFLICTING);

  rule(UNKNOWN, UNKNOWN, UNKNOWN);
  rule(UNKNOWN, jsBoolean, jsBoolean);
  rule(UNKNOWN, jsNumber, jsNumber);
  rule(UNKNOWN, jsInteger, jsInteger);
  rule(UNKNOWN, jsDouble, jsDouble);
  rule(UNKNOWN, jsIndexable, jsIndexable);
  rule(UNKNOWN, jsString, jsString);
  rule(UNKNOWN, jsReadableArray, jsReadableArray);
  rule(UNKNOWN, jsMutableArray, jsMutableArray);
  rule(UNKNOWN, jsExtendableArray, jsExtendableArray);
  rule(UNKNOWN, nonPrimitive1, nonPrimitive1);
  rule(UNKNOWN, nonPrimitive2, nonPrimitive2);
  rule(UNKNOWN, potentialArray, potentialArray);
  rule(UNKNOWN, potentialString, potentialString);
  rule(UNKNOWN, jsBooleanOrNull, jsBooleanOrNull);
  rule(UNKNOWN, jsNumberOrNull, jsNumberOrNull);
  rule(UNKNOWN, jsIntegerOrNull, jsIntegerOrNull);
  rule(UNKNOWN, jsDoubleOrNull, jsDoubleOrNull);
  rule(UNKNOWN, jsStringOrNull, jsStringOrNull);
  rule(UNKNOWN, NULL, NULL);
  rule(UNKNOWN, jsFixedArray, jsFixedArray);

  rule(jsBoolean, jsBoolean, jsBoolean);
  rule(jsBoolean, jsNumber, CONFLICTING);
  rule(jsBoolean, jsInteger, CONFLICTING);
  rule(jsBoolean, jsDouble, CONFLICTING);
  rule(jsBoolean, jsIndexable, CONFLICTING);
  rule(jsBoolean, jsString, CONFLICTING);
  rule(jsBoolean, jsReadableArray, CONFLICTING);
  rule(jsBoolean, jsMutableArray, CONFLICTING);
  rule(jsBoolean, jsExtendableArray, CONFLICTING);
  rule(jsBoolean, nonPrimitive1, CONFLICTING);
  rule(jsBoolean, nonPrimitive2, CONFLICTING);
  rule(jsBoolean, potentialArray, CONFLICTING);
  rule(jsBoolean, potentialString, CONFLICTING);
  rule(jsBoolean, jsBooleanOrNull, jsBoolean);
  rule(jsBoolean, jsNumberOrNull, CONFLICTING);
  rule(jsBoolean, jsIntegerOrNull, CONFLICTING);
  rule(jsBoolean, jsDoubleOrNull, CONFLICTING);
  rule(jsBoolean, jsStringOrNull, CONFLICTING);
  rule(jsBoolean, NULL, CONFLICTING);
  rule(jsBoolean, jsFixedArray, CONFLICTING);

  rule(jsNumber, jsNumber, jsNumber);
  rule(jsNumber, jsInteger, jsInteger);
  rule(jsNumber, jsDouble, jsDouble);
  rule(jsNumber, jsIndexable, CONFLICTING);
  rule(jsNumber, jsString, CONFLICTING);
  rule(jsNumber, jsReadableArray, CONFLICTING);
  rule(jsNumber, jsMutableArray, CONFLICTING);
  rule(jsNumber, jsExtendableArray, CONFLICTING);
  rule(jsNumber, nonPrimitive1, CONFLICTING);
  rule(jsNumber, nonPrimitive2, CONFLICTING);
  rule(jsNumber, potentialArray, CONFLICTING);
  rule(jsNumber, potentialString, CONFLICTING);
  rule(jsNumber, jsBooleanOrNull, CONFLICTING);
  rule(jsNumber, jsNumberOrNull, jsNumber);
  rule(jsNumber, jsIntegerOrNull, jsInteger);
  rule(jsNumber, jsDoubleOrNull, jsDouble);
  rule(jsNumber, jsStringOrNull, CONFLICTING);
  rule(jsNumber, NULL, CONFLICTING);
  rule(jsNumber, jsFixedArray, CONFLICTING);

  rule(jsInteger, jsInteger, jsInteger);
  rule(jsInteger, jsDouble, CONFLICTING);
  rule(jsInteger, jsIndexable, CONFLICTING);
  rule(jsInteger, jsString, CONFLICTING);
  rule(jsInteger, jsReadableArray, CONFLICTING);
  rule(jsInteger, jsMutableArray, CONFLICTING);
  rule(jsInteger, jsExtendableArray, CONFLICTING);
  rule(jsInteger, nonPrimitive1, CONFLICTING);
  rule(jsInteger, nonPrimitive2, CONFLICTING);
  rule(jsInteger, potentialArray, CONFLICTING);
  rule(jsInteger, potentialString, CONFLICTING);
  rule(jsInteger, jsBooleanOrNull, CONFLICTING);
  rule(jsInteger, jsNumberOrNull, jsInteger);
  rule(jsInteger, jsIntegerOrNull, jsInteger);
  rule(jsInteger, jsDoubleOrNull, CONFLICTING);
  rule(jsInteger, jsStringOrNull, CONFLICTING);
  rule(jsInteger, NULL, CONFLICTING);
  rule(jsInteger, jsFixedArray, CONFLICTING);

  rule(jsDouble, jsDouble, jsDouble);
  rule(jsDouble, jsIndexable, CONFLICTING);
  rule(jsDouble, jsString, CONFLICTING);
  rule(jsDouble, jsReadableArray, CONFLICTING);
  rule(jsDouble, jsMutableArray, CONFLICTING);
  rule(jsDouble, jsExtendableArray, CONFLICTING);
  rule(jsDouble, nonPrimitive1, CONFLICTING);
  rule(jsDouble, nonPrimitive2, CONFLICTING);
  rule(jsDouble, potentialArray, CONFLICTING);
  rule(jsDouble, potentialString, CONFLICTING);
  rule(jsDouble, jsBooleanOrNull, CONFLICTING);
  rule(jsDouble, jsNumberOrNull, jsDouble);
  rule(jsDouble, jsIntegerOrNull, CONFLICTING);
  rule(jsDouble, jsDoubleOrNull, jsDouble);
  rule(jsDouble, jsStringOrNull, CONFLICTING);
  rule(jsDouble, NULL, CONFLICTING);
  rule(jsDouble, jsFixedArray, CONFLICTING);

  rule(jsIndexable, jsIndexable, jsIndexable);
  rule(jsIndexable, jsString, jsString);
  rule(jsIndexable, jsReadableArray, jsReadableArray);
  rule(jsIndexable, jsMutableArray, jsMutableArray);
  rule(jsIndexable, jsExtendableArray, jsExtendableArray);
  rule(jsIndexable, nonPrimitive1, CONFLICTING);
  rule(jsIndexable, nonPrimitive2, CONFLICTING);
  rule(jsIndexable, potentialArray, new HType.nonNullSubtype(
      compiler.backend.jsArrayClass, compiler));
  rule(jsIndexable, potentialString, jsString);
  rule(jsIndexable, jsBooleanOrNull, CONFLICTING);
  rule(jsIndexable, jsNumberOrNull, CONFLICTING);
  rule(jsIndexable, jsIntegerOrNull, CONFLICTING);
  rule(jsIndexable, jsDoubleOrNull, CONFLICTING);
  rule(jsIndexable, jsStringOrNull, jsString);
  rule(jsIndexable, NULL, CONFLICTING);
  rule(jsIndexable, jsFixedArray, jsFixedArray);

  rule(jsString, jsString, jsString);
  rule(jsString, jsReadableArray, CONFLICTING);
  rule(jsString, jsMutableArray, CONFLICTING);
  rule(jsString, jsExtendableArray, CONFLICTING);
  rule(jsString, nonPrimitive1, CONFLICTING);
  rule(jsString, nonPrimitive2, CONFLICTING);
  rule(jsString, potentialArray, CONFLICTING);
  rule(jsString, potentialString, jsString);
  rule(jsString, jsBooleanOrNull, CONFLICTING);
  rule(jsString, jsNumberOrNull, CONFLICTING);
  rule(jsString, jsIntegerOrNull, CONFLICTING);
  rule(jsString, jsDoubleOrNull, CONFLICTING);
  rule(jsString, jsStringOrNull, jsString);
  rule(jsString, NULL, CONFLICTING);
  rule(jsString, jsFixedArray, CONFLICTING);

  rule(jsReadableArray, jsReadableArray, jsReadableArray);
  rule(jsReadableArray, jsMutableArray, jsMutableArray);
  rule(jsReadableArray, jsExtendableArray, jsExtendableArray);
  rule(jsReadableArray, nonPrimitive1, CONFLICTING);
  rule(jsReadableArray, nonPrimitive2, CONFLICTING);
  rule(jsReadableArray, potentialArray, jsReadableArray);
  rule(jsReadableArray, potentialString, CONFLICTING);
  rule(jsReadableArray, jsBooleanOrNull, CONFLICTING);
  rule(jsReadableArray, jsNumberOrNull, CONFLICTING);
  rule(jsReadableArray, jsIntegerOrNull, CONFLICTING);
  rule(jsReadableArray, jsDoubleOrNull, CONFLICTING);
  rule(jsReadableArray, jsStringOrNull, CONFLICTING);
  rule(jsReadableArray, NULL, CONFLICTING);
  rule(jsReadableArray, jsFixedArray, jsFixedArray);

  rule(jsMutableArray, jsMutableArray, jsMutableArray);
  rule(jsMutableArray, jsExtendableArray, jsExtendableArray);
  rule(jsMutableArray, nonPrimitive1, CONFLICTING);
  rule(jsMutableArray, nonPrimitive2, CONFLICTING);
  rule(jsMutableArray, potentialArray, jsMutableArray);
  rule(jsMutableArray, potentialString, CONFLICTING);
  rule(jsMutableArray, jsBooleanOrNull, CONFLICTING);
  rule(jsMutableArray, jsNumberOrNull, CONFLICTING);
  rule(jsMutableArray, jsIntegerOrNull, CONFLICTING);
  rule(jsMutableArray, jsDoubleOrNull, CONFLICTING);
  rule(jsMutableArray, jsStringOrNull, CONFLICTING);
  rule(jsMutableArray, NULL, CONFLICTING);
  rule(jsMutableArray, jsFixedArray, jsFixedArray);

  rule(jsExtendableArray, jsExtendableArray, jsExtendableArray);
  rule(jsExtendableArray, nonPrimitive1, CONFLICTING);
  rule(jsExtendableArray, nonPrimitive2, CONFLICTING);
  rule(jsExtendableArray, potentialArray, jsExtendableArray);
  rule(jsExtendableArray, potentialString, CONFLICTING);
  rule(jsExtendableArray, jsBooleanOrNull, CONFLICTING);
  rule(jsExtendableArray, jsNumberOrNull, CONFLICTING);
  rule(jsExtendableArray, jsIntegerOrNull, CONFLICTING);
  rule(jsExtendableArray, jsDoubleOrNull, CONFLICTING);
  rule(jsExtendableArray, jsStringOrNull, CONFLICTING);
  rule(jsExtendableArray, NULL, CONFLICTING);
  rule(jsExtendableArray, jsFixedArray, CONFLICTING);

  rule(nonPrimitive1, nonPrimitive1, nonPrimitive1);
  rule(nonPrimitive1, nonPrimitive2, CONFLICTING);
  rule(nonPrimitive1, potentialArray, CONFLICTING);
  rule(nonPrimitive1, potentialString, CONFLICTING);
  rule(nonPrimitive1, jsBooleanOrNull, CONFLICTING);
  rule(nonPrimitive1, jsNumberOrNull, CONFLICTING);
  rule(nonPrimitive1, jsIntegerOrNull, CONFLICTING);
  rule(nonPrimitive1, jsDoubleOrNull, CONFLICTING);
  rule(nonPrimitive1, jsStringOrNull, CONFLICTING);
  rule(nonPrimitive1, NULL, CONFLICTING);
  rule(nonPrimitive1, jsFixedArray, CONFLICTING);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, CONFLICTING);
  rule(nonPrimitive2, potentialString, CONFLICTING);
  rule(nonPrimitive2, jsBooleanOrNull, CONFLICTING);
  rule(nonPrimitive2, jsNumberOrNull, CONFLICTING);
  rule(nonPrimitive2, jsIntegerOrNull, CONFLICTING);
  rule(nonPrimitive2, jsDoubleOrNull, CONFLICTING);
  rule(nonPrimitive2, jsStringOrNull, CONFLICTING);
  rule(nonPrimitive2, NULL, CONFLICTING);
  rule(nonPrimitive2, jsFixedArray, CONFLICTING);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, NULL);
  rule(potentialArray, jsBooleanOrNull, NULL);
  rule(potentialArray, jsNumberOrNull, NULL);
  rule(potentialArray, jsIntegerOrNull, NULL);
  rule(potentialArray, jsDoubleOrNull, NULL);
  rule(potentialArray, jsStringOrNull, NULL);
  rule(potentialArray, NULL, NULL);
  rule(potentialArray, jsFixedArray, jsFixedArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, jsBooleanOrNull, NULL);
  rule(potentialString, jsNumberOrNull, NULL);
  rule(potentialString, jsIntegerOrNull, NULL);
  rule(potentialString, jsDoubleOrNull, NULL);
  rule(potentialString, jsStringOrNull, jsStringOrNull);
  rule(potentialString, NULL, NULL);
  rule(potentialString, jsFixedArray, CONFLICTING);

  rule(jsBooleanOrNull, jsBooleanOrNull, jsBooleanOrNull);
  rule(jsBooleanOrNull, jsNumberOrNull, NULL);
  rule(jsBooleanOrNull, jsIntegerOrNull, NULL);
  rule(jsBooleanOrNull, jsDoubleOrNull, NULL);
  rule(jsBooleanOrNull, jsStringOrNull, NULL);
  rule(jsBooleanOrNull, NULL, NULL);
  rule(jsBooleanOrNull, jsFixedArray, CONFLICTING);

  rule(jsNumberOrNull, jsNumberOrNull, jsNumberOrNull);
  rule(jsNumberOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsNumberOrNull, jsDoubleOrNull, jsDoubleOrNull);
  rule(jsNumberOrNull, jsStringOrNull, NULL);
  rule(jsNumberOrNull, NULL, NULL);
  rule(jsNumberOrNull, jsFixedArray, CONFLICTING);

  rule(jsIntegerOrNull, jsIntegerOrNull, jsIntegerOrNull);
  rule(jsIntegerOrNull, jsDoubleOrNull, NULL);
  rule(jsIntegerOrNull, jsStringOrNull, NULL);
  rule(jsIntegerOrNull, NULL, NULL);
  rule(jsIntegerOrNull, jsFixedArray, CONFLICTING);

  rule(jsDoubleOrNull, jsDoubleOrNull, jsDoubleOrNull);
  rule(jsDoubleOrNull, jsStringOrNull, NULL);
  rule(jsDoubleOrNull, NULL, NULL);
  rule(jsDoubleOrNull, jsFixedArray, CONFLICTING);

  rule(jsStringOrNull, jsStringOrNull, jsStringOrNull);
  rule(jsStringOrNull, NULL, NULL);
  rule(jsStringOrNull, jsFixedArray, CONFLICTING);

  rule(NULL, NULL, NULL);
  rule(NULL, jsFixedArray, CONFLICTING);

  rule(jsFixedArray, jsFixedArray, jsFixedArray);

  ruleSet.validateCoverage();
}

void testRegressions(MockCompiler compiler) {
  HType nonNullPotentialString = new HType.nonNullSubtype(
      patternClass, compiler);
  Expect.equals(
      potentialString, jsStringOrNull.union(nonNullPotentialString, compiler));
}

void main() {
  MockCompiler compiler = new MockCompiler();
  compiler.interceptorsLibrary.forEachLocalMember((element) {
    if (element.isClass()) {
      compiler.enqueuer.resolution.registerInstantiatedClass(
          element, compiler.globalDependencies);
    }
  });
  compiler.enqueuer.resolution.registerInstantiatedClass(
      compiler.mapClass, compiler.globalDependencies);
  compiler.world.populate();

  // Grab hold of a supertype for String so we can produce potential
  // string types.
  patternClass = compiler.coreLibrary.find('Pattern');

  nonPrimitive1 = new HType.nonNullSubtype(
      compiler.mapClass, compiler);
  nonPrimitive2 = new HType.nonNullSubtype(
      compiler.functionClass, compiler);
  potentialArray = new HType.subtype(
      compiler.listClass, compiler);
  potentialString = new HType.subtype(
      patternClass, compiler);
  jsInterceptor = new HType.nonNullSubclass(
      compiler.backend.jsInterceptorClass, compiler);
  jsArrayOrNull = new HType.subclass(
      compiler.backend.jsArrayClass, compiler);
  jsReadableArray = new HType.nonNullSubclass(
      compiler.backend.jsArrayClass, compiler);
  jsMutableArrayOrNull = new HType.subclass(
      compiler.backend.jsMutableArrayClass, compiler);
  jsMutableArray = new HType.nonNullSubclass(
      compiler.backend.jsMutableArrayClass, compiler);
  jsFixedArrayOrNull = new HType.exact(
      compiler.backend.jsFixedArrayClass, compiler);
  jsFixedArray = new HType.nonNullExact(
      compiler.backend.jsFixedArrayClass, compiler);
  jsExtendableArrayOrNull = new HType.exact(
      compiler.backend.jsExtendableArrayClass, compiler);
  jsExtendableArray = new HType.nonNullExact(
      compiler.backend.jsExtendableArrayClass, compiler);
  jsIndexableOrNull = new HType.subtype(
      compiler.backend.jsIndexableClass, compiler);
  jsIndexable = new HType.nonNullSubtype(
      compiler.backend.jsIndexableClass, compiler);
  jsInterceptorOrNull = new HType.subclass(
      compiler.backend.jsInterceptorClass, compiler);
  jsStringOrNull = new HType.exact(
      compiler.backend.jsStringClass, compiler);
  jsString = new HType.nonNullExact(
      compiler.backend.jsStringClass, compiler);
  jsBoolean = new HType.nonNullExact(
      compiler.backend.jsBoolClass, compiler);
  jsNumber = new HType.nonNullSubclass(
      compiler.backend.jsNumberClass, compiler);
  jsInteger = new HType.nonNullExact(
      compiler.backend.jsIntClass, compiler);
  jsDouble = new HType.nonNullExact(
      compiler.backend.jsDoubleClass, compiler);
  jsBooleanOrNull = new HType.exact(
      compiler.backend.jsBoolClass, compiler);
  jsNumberOrNull = new HType.subclass(
      compiler.backend.jsNumberClass, compiler);
  jsIntegerOrNull = new HType.exact(
      compiler.backend.jsIntClass, compiler);
  jsDoubleOrNull = new HType.exact(
      compiler.backend.jsDoubleClass, compiler);

  testUnion(compiler);
  testIntersection(compiler);
  testRegressions(compiler);
}
