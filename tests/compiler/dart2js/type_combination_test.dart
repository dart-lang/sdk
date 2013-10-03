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
const BOOLEAN = HType.BOOLEAN;
const NUMBER = HType.NUMBER;
const INTEGER = HType.INTEGER;
const DOUBLE = HType.DOUBLE;
const BOOLEAN_OR_NULL = HType.BOOLEAN_OR_NULL;
const NUMBER_OR_NULL = HType.NUMBER_OR_NULL;
const INTEGER_OR_NULL = HType.INTEGER_OR_NULL;
const DOUBLE_OR_NULL = HType.DOUBLE_OR_NULL;
const NULL = HType.NULL;
const NON_NULL = HType.NON_NULL;

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
  rule(CONFLICTING, BOOLEAN, BOOLEAN);
  rule(CONFLICTING, NUMBER, NUMBER);
  rule(CONFLICTING, INTEGER, INTEGER);
  rule(CONFLICTING, DOUBLE, DOUBLE);
  rule(CONFLICTING, jsIndexable, jsIndexable);
  rule(CONFLICTING, jsString, jsString);
  rule(CONFLICTING, jsReadableArray, jsReadableArray);
  rule(CONFLICTING, jsMutableArray, jsMutableArray);
  rule(CONFLICTING, jsExtendableArray, jsExtendableArray);
  rule(CONFLICTING, nonPrimitive1, nonPrimitive1);
  rule(CONFLICTING, nonPrimitive2, nonPrimitive2);
  rule(CONFLICTING, potentialArray, potentialArray);
  rule(CONFLICTING, potentialString, potentialString);
  rule(CONFLICTING, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(CONFLICTING, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(CONFLICTING, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(CONFLICTING, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(CONFLICTING, jsStringOrNull, jsStringOrNull);
  rule(CONFLICTING, NULL, NULL);
  rule(CONFLICTING, jsFixedArray, jsFixedArray);

  rule(UNKNOWN, UNKNOWN, UNKNOWN);
  rule(UNKNOWN, BOOLEAN, UNKNOWN);
  rule(UNKNOWN, NUMBER, UNKNOWN);
  rule(UNKNOWN, INTEGER, UNKNOWN);
  rule(UNKNOWN, DOUBLE, UNKNOWN);
  rule(UNKNOWN, jsIndexable, UNKNOWN);
  rule(UNKNOWN, jsString, UNKNOWN);
  rule(UNKNOWN, jsReadableArray, UNKNOWN);
  rule(UNKNOWN, jsMutableArray, UNKNOWN);
  rule(UNKNOWN, jsExtendableArray, UNKNOWN);
  rule(UNKNOWN, nonPrimitive1, UNKNOWN);
  rule(UNKNOWN, nonPrimitive2, UNKNOWN);
  rule(UNKNOWN, potentialArray, UNKNOWN);
  rule(UNKNOWN, potentialString, UNKNOWN);
  rule(UNKNOWN, BOOLEAN_OR_NULL, UNKNOWN);
  rule(UNKNOWN, NUMBER_OR_NULL, UNKNOWN);
  rule(UNKNOWN, INTEGER_OR_NULL, UNKNOWN);
  rule(UNKNOWN, DOUBLE_OR_NULL, UNKNOWN);
  rule(UNKNOWN, jsStringOrNull, UNKNOWN);
  rule(UNKNOWN, NULL, UNKNOWN);
  rule(UNKNOWN, jsFixedArray, UNKNOWN);

  rule(BOOLEAN, BOOLEAN, BOOLEAN);
  rule(BOOLEAN, NUMBER, jsInterceptor);
  rule(BOOLEAN, INTEGER, jsInterceptor);
  rule(BOOLEAN, DOUBLE, jsInterceptor);
  rule(BOOLEAN, jsIndexable, NON_NULL);
  rule(BOOLEAN, jsString, jsInterceptor);
  rule(BOOLEAN, jsReadableArray, jsInterceptor);
  rule(BOOLEAN, jsMutableArray, jsInterceptor);
  rule(BOOLEAN, jsExtendableArray, jsInterceptor);
  rule(BOOLEAN, nonPrimitive1, NON_NULL);
  rule(BOOLEAN, nonPrimitive2, NON_NULL);
  rule(BOOLEAN, potentialArray, UNKNOWN);
  rule(BOOLEAN, potentialString, UNKNOWN);
  rule(BOOLEAN, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN, jsStringOrNull, jsInterceptorOrNull);
  rule(BOOLEAN, NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN, jsFixedArray, jsInterceptor);

  rule(NUMBER, NUMBER, NUMBER);
  rule(NUMBER, INTEGER, NUMBER);
  rule(NUMBER, DOUBLE, NUMBER);
  rule(NUMBER, jsIndexable, NON_NULL);
  rule(NUMBER, jsString, jsInterceptor);
  rule(NUMBER, jsReadableArray, jsInterceptor);
  rule(NUMBER, jsMutableArray, jsInterceptor);
  rule(NUMBER, jsExtendableArray, jsInterceptor);
  rule(NUMBER, nonPrimitive1, NON_NULL);
  rule(NUMBER, nonPrimitive2, NON_NULL);
  rule(NUMBER, potentialArray, UNKNOWN);
  rule(NUMBER, potentialString, UNKNOWN);
  rule(NUMBER, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(NUMBER, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER, INTEGER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER, DOUBLE_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER, jsStringOrNull, jsInterceptorOrNull);
  rule(NUMBER, NULL, NUMBER_OR_NULL);
  rule(NUMBER, jsFixedArray, jsInterceptor);

  rule(INTEGER, INTEGER, INTEGER);
  rule(INTEGER, DOUBLE, NUMBER);
  rule(INTEGER, jsIndexable, NON_NULL);
  rule(INTEGER, jsString, jsInterceptor);
  rule(INTEGER, jsReadableArray, jsInterceptor);
  rule(INTEGER, jsMutableArray, jsInterceptor);
  rule(INTEGER, jsExtendableArray, jsInterceptor);
  rule(INTEGER, nonPrimitive1, NON_NULL);
  rule(INTEGER, nonPrimitive2, NON_NULL);
  rule(INTEGER, potentialArray, UNKNOWN);
  rule(INTEGER, potentialString, UNKNOWN);
  rule(INTEGER, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(INTEGER, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(INTEGER, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(INTEGER, DOUBLE_OR_NULL, NUMBER_OR_NULL);
  rule(INTEGER, jsStringOrNull, jsInterceptorOrNull);
  rule(INTEGER, NULL, INTEGER_OR_NULL);
  rule(INTEGER, jsFixedArray, jsInterceptor);

  rule(DOUBLE, DOUBLE, DOUBLE);
  rule(DOUBLE, jsIndexable, NON_NULL);
  rule(DOUBLE, jsString, jsInterceptor);
  rule(DOUBLE, jsReadableArray, jsInterceptor);
  rule(DOUBLE, jsMutableArray, jsInterceptor);
  rule(DOUBLE, jsExtendableArray, jsInterceptor);
  rule(DOUBLE, nonPrimitive1, NON_NULL);
  rule(DOUBLE, nonPrimitive2, NON_NULL);
  rule(DOUBLE, potentialArray, UNKNOWN);
  rule(DOUBLE, potentialString, UNKNOWN);
  rule(DOUBLE, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(DOUBLE, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(DOUBLE, INTEGER_OR_NULL, NUMBER_OR_NULL);
  rule(DOUBLE, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(DOUBLE, jsStringOrNull, jsInterceptorOrNull);
  rule(DOUBLE, NULL, DOUBLE_OR_NULL);
  rule(DOUBLE, jsFixedArray, jsInterceptor);

  rule(jsIndexable, jsIndexable, jsIndexable);
  rule(jsIndexable, jsString, jsIndexable);
  rule(jsIndexable, jsReadableArray, jsIndexable);
  rule(jsIndexable, jsMutableArray, jsIndexable);
  rule(jsIndexable, jsExtendableArray, jsIndexable);
  rule(jsIndexable, nonPrimitive1, NON_NULL);
  rule(jsIndexable, nonPrimitive2, NON_NULL);
  rule(jsIndexable, potentialArray, UNKNOWN);
  rule(jsIndexable, potentialString, UNKNOWN);
  rule(jsIndexable, BOOLEAN_OR_NULL, UNKNOWN);
  rule(jsIndexable, NUMBER_OR_NULL, UNKNOWN);
  rule(jsIndexable, INTEGER_OR_NULL, UNKNOWN);
  rule(jsIndexable, DOUBLE_OR_NULL, UNKNOWN);
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
  rule(jsString, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(jsString, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(jsString, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(jsString, DOUBLE_OR_NULL, jsInterceptorOrNull);
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
  rule(jsReadableArray, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(jsReadableArray, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(jsReadableArray, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(jsReadableArray, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(jsReadableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsReadableArray, NULL, jsArrayOrNull);
  rule(jsReadableArray, jsFixedArray, jsReadableArray);

  rule(jsMutableArray, jsMutableArray, jsMutableArray);
  rule(jsMutableArray, jsExtendableArray, jsMutableArray);
  rule(jsMutableArray, nonPrimitive1, NON_NULL);
  rule(jsMutableArray, nonPrimitive2, NON_NULL);
  rule(jsMutableArray, potentialArray, potentialArray);
  rule(jsMutableArray, potentialString, UNKNOWN);
  rule(jsMutableArray, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(jsMutableArray, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(jsMutableArray, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(jsMutableArray, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(jsMutableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsMutableArray, NULL, jsMutableArrayOrNull);
  rule(jsMutableArray, jsFixedArray, jsMutableArray);

  rule(jsExtendableArray, jsExtendableArray, jsExtendableArray);
  rule(jsExtendableArray, nonPrimitive1, NON_NULL);
  rule(jsExtendableArray, nonPrimitive2, NON_NULL);
  rule(jsExtendableArray, potentialArray, potentialArray);
  rule(jsExtendableArray, potentialString, UNKNOWN);
  rule(jsExtendableArray, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(jsExtendableArray, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(jsExtendableArray, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(jsExtendableArray, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(jsExtendableArray, jsStringOrNull, jsIndexableOrNull);
  rule(jsExtendableArray, NULL, jsExtendableArrayOrNull);
  rule(jsExtendableArray, jsFixedArray, jsMutableArray);

  rule(nonPrimitive1, nonPrimitive1, nonPrimitive1);
  rule(nonPrimitive1, nonPrimitive2, NON_NULL);
  rule(nonPrimitive1, potentialArray, UNKNOWN);
  rule(nonPrimitive1, potentialString, UNKNOWN);
  rule(nonPrimitive1, BOOLEAN_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, NUMBER_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, INTEGER_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, DOUBLE_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, jsStringOrNull, UNKNOWN);
  rule(nonPrimitive1, jsFixedArray, NON_NULL);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, UNKNOWN);
  rule(nonPrimitive2, potentialString, UNKNOWN);
  rule(nonPrimitive2, BOOLEAN_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, NUMBER_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, INTEGER_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, DOUBLE_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, jsStringOrNull, UNKNOWN);
  rule(nonPrimitive2, jsFixedArray, NON_NULL);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, UNKNOWN);
  rule(potentialArray, BOOLEAN_OR_NULL, UNKNOWN);
  rule(potentialArray, NUMBER_OR_NULL, UNKNOWN);
  rule(potentialArray, INTEGER_OR_NULL, UNKNOWN);
  rule(potentialArray, DOUBLE_OR_NULL, UNKNOWN);
  rule(potentialArray, jsStringOrNull, UNKNOWN);
  rule(potentialArray, NULL, potentialArray);
  rule(potentialArray, jsFixedArray, potentialArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, BOOLEAN_OR_NULL, UNKNOWN);
  rule(potentialString, NUMBER_OR_NULL, UNKNOWN);
  rule(potentialString, INTEGER_OR_NULL, UNKNOWN);
  rule(potentialString, DOUBLE_OR_NULL, UNKNOWN);
  rule(potentialString, jsStringOrNull, potentialString);
  rule(potentialString, NULL, potentialString);
  rule(potentialString, jsFixedArray, UNKNOWN);

  rule(BOOLEAN_OR_NULL, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN_OR_NULL, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN_OR_NULL, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN_OR_NULL, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN_OR_NULL, jsStringOrNull, jsInterceptorOrNull);
  rule(BOOLEAN_OR_NULL, NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN_OR_NULL, jsFixedArray, jsInterceptorOrNull);

  rule(NUMBER_OR_NULL, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, INTEGER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, DOUBLE_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, jsStringOrNull, jsInterceptorOrNull);
  rule(NUMBER_OR_NULL, NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, jsFixedArray, jsInterceptorOrNull);

  rule(INTEGER_OR_NULL, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(INTEGER_OR_NULL, DOUBLE_OR_NULL, NUMBER_OR_NULL);
  rule(INTEGER_OR_NULL, jsStringOrNull, jsInterceptorOrNull);
  rule(INTEGER_OR_NULL, NULL, INTEGER_OR_NULL);
  rule(INTEGER_OR_NULL, jsFixedArray, jsInterceptorOrNull);

  rule(DOUBLE_OR_NULL, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(DOUBLE_OR_NULL, jsStringOrNull, jsInterceptorOrNull);
  rule(DOUBLE_OR_NULL, NULL, DOUBLE_OR_NULL);
  rule(DOUBLE_OR_NULL, jsFixedArray, jsInterceptorOrNull);

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
  rule(CONFLICTING, BOOLEAN, CONFLICTING);
  rule(CONFLICTING, NUMBER, CONFLICTING);
  rule(CONFLICTING, INTEGER, CONFLICTING);
  rule(CONFLICTING, DOUBLE, CONFLICTING);
  rule(CONFLICTING, jsIndexable, CONFLICTING);
  rule(CONFLICTING, jsString, CONFLICTING);
  rule(CONFLICTING, jsReadableArray, CONFLICTING);
  rule(CONFLICTING, jsMutableArray, CONFLICTING);
  rule(CONFLICTING, jsExtendableArray, CONFLICTING);
  rule(CONFLICTING, nonPrimitive1, CONFLICTING);
  rule(CONFLICTING, nonPrimitive2, CONFLICTING);
  rule(CONFLICTING, potentialArray, CONFLICTING);
  rule(CONFLICTING, potentialString, CONFLICTING);
  rule(CONFLICTING, BOOLEAN_OR_NULL, CONFLICTING);
  rule(CONFLICTING, NUMBER_OR_NULL, CONFLICTING);
  rule(CONFLICTING, INTEGER_OR_NULL, CONFLICTING);
  rule(CONFLICTING, DOUBLE_OR_NULL, CONFLICTING);
  rule(CONFLICTING, jsStringOrNull, CONFLICTING);
  rule(CONFLICTING, NULL, CONFLICTING);
  rule(CONFLICTING, jsFixedArray, CONFLICTING);

  rule(UNKNOWN, UNKNOWN, UNKNOWN);
  rule(UNKNOWN, BOOLEAN, BOOLEAN);
  rule(UNKNOWN, NUMBER, NUMBER);
  rule(UNKNOWN, INTEGER, INTEGER);
  rule(UNKNOWN, DOUBLE, DOUBLE);
  rule(UNKNOWN, jsIndexable, jsIndexable);
  rule(UNKNOWN, jsString, jsString);
  rule(UNKNOWN, jsReadableArray, jsReadableArray);
  rule(UNKNOWN, jsMutableArray, jsMutableArray);
  rule(UNKNOWN, jsExtendableArray, jsExtendableArray);
  rule(UNKNOWN, nonPrimitive1, nonPrimitive1);
  rule(UNKNOWN, nonPrimitive2, nonPrimitive2);
  rule(UNKNOWN, potentialArray, potentialArray);
  rule(UNKNOWN, potentialString, potentialString);
  rule(UNKNOWN, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(UNKNOWN, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(UNKNOWN, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(UNKNOWN, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(UNKNOWN, jsStringOrNull, jsStringOrNull);
  rule(UNKNOWN, NULL, NULL);
  rule(UNKNOWN, jsFixedArray, jsFixedArray);

  rule(BOOLEAN, BOOLEAN, BOOLEAN);
  rule(BOOLEAN, NUMBER, CONFLICTING);
  rule(BOOLEAN, INTEGER, CONFLICTING);
  rule(BOOLEAN, DOUBLE, CONFLICTING);
  rule(BOOLEAN, jsIndexable, CONFLICTING);
  rule(BOOLEAN, jsString, CONFLICTING);
  rule(BOOLEAN, jsReadableArray, CONFLICTING);
  rule(BOOLEAN, jsMutableArray, CONFLICTING);
  rule(BOOLEAN, jsExtendableArray, CONFLICTING);
  rule(BOOLEAN, nonPrimitive1, CONFLICTING);
  rule(BOOLEAN, nonPrimitive2, CONFLICTING);
  rule(BOOLEAN, potentialArray, CONFLICTING);
  rule(BOOLEAN, potentialString, CONFLICTING);
  rule(BOOLEAN, BOOLEAN_OR_NULL, BOOLEAN);
  rule(BOOLEAN, NUMBER_OR_NULL, CONFLICTING);
  rule(BOOLEAN, INTEGER_OR_NULL, CONFLICTING);
  rule(BOOLEAN, DOUBLE_OR_NULL, CONFLICTING);
  rule(BOOLEAN, jsStringOrNull, CONFLICTING);
  rule(BOOLEAN, NULL, CONFLICTING);
  rule(BOOLEAN, jsFixedArray, CONFLICTING);

  rule(NUMBER, NUMBER, NUMBER);
  rule(NUMBER, INTEGER, INTEGER);
  rule(NUMBER, DOUBLE, DOUBLE);
  rule(NUMBER, jsIndexable, CONFLICTING);
  rule(NUMBER, jsString, CONFLICTING);
  rule(NUMBER, jsReadableArray, CONFLICTING);
  rule(NUMBER, jsMutableArray, CONFLICTING);
  rule(NUMBER, jsExtendableArray, CONFLICTING);
  rule(NUMBER, nonPrimitive1, CONFLICTING);
  rule(NUMBER, nonPrimitive2, CONFLICTING);
  rule(NUMBER, potentialArray, CONFLICTING);
  rule(NUMBER, potentialString, CONFLICTING);
  rule(NUMBER, BOOLEAN_OR_NULL, CONFLICTING);
  rule(NUMBER, NUMBER_OR_NULL, NUMBER);
  rule(NUMBER, INTEGER_OR_NULL, INTEGER);
  rule(NUMBER, DOUBLE_OR_NULL, DOUBLE);
  rule(NUMBER, jsStringOrNull, CONFLICTING);
  rule(NUMBER, NULL, CONFLICTING);
  rule(NUMBER, jsFixedArray, CONFLICTING);

  rule(INTEGER, INTEGER, INTEGER);
  rule(INTEGER, DOUBLE, CONFLICTING);
  rule(INTEGER, jsIndexable, CONFLICTING);
  rule(INTEGER, jsString, CONFLICTING);
  rule(INTEGER, jsReadableArray, CONFLICTING);
  rule(INTEGER, jsMutableArray, CONFLICTING);
  rule(INTEGER, jsExtendableArray, CONFLICTING);
  rule(INTEGER, nonPrimitive1, CONFLICTING);
  rule(INTEGER, nonPrimitive2, CONFLICTING);
  rule(INTEGER, potentialArray, CONFLICTING);
  rule(INTEGER, potentialString, CONFLICTING);
  rule(INTEGER, BOOLEAN_OR_NULL, CONFLICTING);
  rule(INTEGER, NUMBER_OR_NULL, INTEGER);
  rule(INTEGER, INTEGER_OR_NULL, INTEGER);
  rule(INTEGER, DOUBLE_OR_NULL, CONFLICTING);
  rule(INTEGER, jsStringOrNull, CONFLICTING);
  rule(INTEGER, NULL, CONFLICTING);
  rule(INTEGER, jsFixedArray, CONFLICTING);

  rule(DOUBLE, DOUBLE, DOUBLE);
  rule(DOUBLE, jsIndexable, CONFLICTING);
  rule(DOUBLE, jsString, CONFLICTING);
  rule(DOUBLE, jsReadableArray, CONFLICTING);
  rule(DOUBLE, jsMutableArray, CONFLICTING);
  rule(DOUBLE, jsExtendableArray, CONFLICTING);
  rule(DOUBLE, nonPrimitive1, CONFLICTING);
  rule(DOUBLE, nonPrimitive2, CONFLICTING);
  rule(DOUBLE, potentialArray, CONFLICTING);
  rule(DOUBLE, potentialString, CONFLICTING);
  rule(DOUBLE, BOOLEAN_OR_NULL, CONFLICTING);
  rule(DOUBLE, NUMBER_OR_NULL, DOUBLE);
  rule(DOUBLE, INTEGER_OR_NULL, CONFLICTING);
  rule(DOUBLE, DOUBLE_OR_NULL, DOUBLE);
  rule(DOUBLE, jsStringOrNull, CONFLICTING);
  rule(DOUBLE, NULL, CONFLICTING);
  rule(DOUBLE, jsFixedArray, CONFLICTING);

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
  rule(jsIndexable, BOOLEAN_OR_NULL, CONFLICTING);
  rule(jsIndexable, NUMBER_OR_NULL, CONFLICTING);
  rule(jsIndexable, INTEGER_OR_NULL, CONFLICTING);
  rule(jsIndexable, DOUBLE_OR_NULL, CONFLICTING);
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
  rule(jsString, BOOLEAN_OR_NULL, CONFLICTING);
  rule(jsString, NUMBER_OR_NULL, CONFLICTING);
  rule(jsString, INTEGER_OR_NULL, CONFLICTING);
  rule(jsString, DOUBLE_OR_NULL, CONFLICTING);
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
  rule(jsReadableArray, BOOLEAN_OR_NULL, CONFLICTING);
  rule(jsReadableArray, NUMBER_OR_NULL, CONFLICTING);
  rule(jsReadableArray, INTEGER_OR_NULL, CONFLICTING);
  rule(jsReadableArray, DOUBLE_OR_NULL, CONFLICTING);
  rule(jsReadableArray, jsStringOrNull, CONFLICTING);
  rule(jsReadableArray, NULL, CONFLICTING);
  rule(jsReadableArray, jsFixedArray, jsFixedArray);

  rule(jsMutableArray, jsMutableArray, jsMutableArray);
  rule(jsMutableArray, jsExtendableArray, jsExtendableArray);
  rule(jsMutableArray, nonPrimitive1, CONFLICTING);
  rule(jsMutableArray, nonPrimitive2, CONFLICTING);
  rule(jsMutableArray, potentialArray, jsMutableArray);
  rule(jsMutableArray, potentialString, CONFLICTING);
  rule(jsMutableArray, BOOLEAN_OR_NULL, CONFLICTING);
  rule(jsMutableArray, NUMBER_OR_NULL, CONFLICTING);
  rule(jsMutableArray, INTEGER_OR_NULL, CONFLICTING);
  rule(jsMutableArray, DOUBLE_OR_NULL, CONFLICTING);
  rule(jsMutableArray, jsStringOrNull, CONFLICTING);
  rule(jsMutableArray, NULL, CONFLICTING);
  rule(jsMutableArray, jsFixedArray, jsFixedArray);

  rule(jsExtendableArray, jsExtendableArray, jsExtendableArray);
  rule(jsExtendableArray, nonPrimitive1, CONFLICTING);
  rule(jsExtendableArray, nonPrimitive2, CONFLICTING);
  rule(jsExtendableArray, potentialArray, jsExtendableArray);
  rule(jsExtendableArray, potentialString, CONFLICTING);
  rule(jsExtendableArray, BOOLEAN_OR_NULL, CONFLICTING);
  rule(jsExtendableArray, NUMBER_OR_NULL, CONFLICTING);
  rule(jsExtendableArray, INTEGER_OR_NULL, CONFLICTING);
  rule(jsExtendableArray, DOUBLE_OR_NULL, CONFLICTING);
  rule(jsExtendableArray, jsStringOrNull, CONFLICTING);
  rule(jsExtendableArray, NULL, CONFLICTING);
  rule(jsExtendableArray, jsFixedArray, CONFLICTING);

  rule(nonPrimitive1, nonPrimitive1, nonPrimitive1);
  rule(nonPrimitive1, nonPrimitive2, CONFLICTING);
  rule(nonPrimitive1, potentialArray, CONFLICTING);
  rule(nonPrimitive1, potentialString, CONFLICTING);
  rule(nonPrimitive1, BOOLEAN_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, NUMBER_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, INTEGER_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, DOUBLE_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, jsStringOrNull, CONFLICTING);
  rule(nonPrimitive1, NULL, CONFLICTING);
  rule(nonPrimitive1, jsFixedArray, CONFLICTING);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, CONFLICTING);
  rule(nonPrimitive2, potentialString, CONFLICTING);
  rule(nonPrimitive2, BOOLEAN_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, NUMBER_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, INTEGER_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, DOUBLE_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, jsStringOrNull, CONFLICTING);
  rule(nonPrimitive2, NULL, CONFLICTING);
  rule(nonPrimitive2, jsFixedArray, CONFLICTING);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, NULL);
  rule(potentialArray, BOOLEAN_OR_NULL, NULL);
  rule(potentialArray, NUMBER_OR_NULL, NULL);
  rule(potentialArray, INTEGER_OR_NULL, NULL);
  rule(potentialArray, DOUBLE_OR_NULL, NULL);
  rule(potentialArray, jsStringOrNull, NULL);
  rule(potentialArray, NULL, NULL);
  rule(potentialArray, jsFixedArray, jsFixedArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, BOOLEAN_OR_NULL, NULL);
  rule(potentialString, NUMBER_OR_NULL, NULL);
  rule(potentialString, INTEGER_OR_NULL, NULL);
  rule(potentialString, DOUBLE_OR_NULL, NULL);
  rule(potentialString, jsStringOrNull, jsStringOrNull);
  rule(potentialString, NULL, NULL);
  rule(potentialString, jsFixedArray, CONFLICTING);

  rule(BOOLEAN_OR_NULL, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN_OR_NULL, NUMBER_OR_NULL, NULL);
  rule(BOOLEAN_OR_NULL, INTEGER_OR_NULL, NULL);
  rule(BOOLEAN_OR_NULL, DOUBLE_OR_NULL, NULL);
  rule(BOOLEAN_OR_NULL, jsStringOrNull, NULL);
  rule(BOOLEAN_OR_NULL, NULL, NULL);
  rule(BOOLEAN_OR_NULL, jsFixedArray, CONFLICTING);

  rule(NUMBER_OR_NULL, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(NUMBER_OR_NULL, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(NUMBER_OR_NULL, jsStringOrNull, NULL);
  rule(NUMBER_OR_NULL, NULL, NULL);
  rule(NUMBER_OR_NULL, jsFixedArray, CONFLICTING);

  rule(INTEGER_OR_NULL, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(INTEGER_OR_NULL, DOUBLE_OR_NULL, NULL);
  rule(INTEGER_OR_NULL, jsStringOrNull, NULL);
  rule(INTEGER_OR_NULL, NULL, NULL);
  rule(INTEGER_OR_NULL, jsFixedArray, CONFLICTING);

  rule(DOUBLE_OR_NULL, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(DOUBLE_OR_NULL, jsStringOrNull, NULL);
  rule(DOUBLE_OR_NULL, NULL, NULL);
  rule(DOUBLE_OR_NULL, jsFixedArray, CONFLICTING);

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
  patternClass = compiler.coreLibrary.find(buildSourceString('Pattern'));

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

  testUnion(compiler);
  testIntersection(compiler);
  testRegressions(compiler);
}
