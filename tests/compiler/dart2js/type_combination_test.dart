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
const INDEXABLE_PRIMITIVE = HType.INDEXABLE_PRIMITIVE;
const STRING = HType.STRING;
const READABLE_ARRAY = HType.READABLE_ARRAY;
const MUTABLE_ARRAY = HType.MUTABLE_ARRAY;
const FIXED_ARRAY = HType.FIXED_ARRAY;
const EXTENDABLE_ARRAY = HType.EXTENDABLE_ARRAY;
const BOOLEAN_OR_NULL = HType.BOOLEAN_OR_NULL;
const NUMBER_OR_NULL = HType.NUMBER_OR_NULL;
const INTEGER_OR_NULL = HType.INTEGER_OR_NULL;
const DOUBLE_OR_NULL = HType.DOUBLE_OR_NULL;
const STRING_OR_NULL = HType.STRING_OR_NULL;
const NULL = HType.NULL;
const NON_NULL = HType.NON_NULL;

var patternClass;
HType nonPrimitive1;
HType nonPrimitive2;
HType potentialArray;
HType potentialString;
HType jsInterceptor;

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
  RuleSet ruleSet = new RuleSet('union', (t1, t2) => t1.union(t2, compiler));
  rule(type1, type2, result) => ruleSet.rule(type1, type2, result);
  check(type1, type2, predicate) => ruleSet.check(type1, type2, predicate);

  rule(CONFLICTING, CONFLICTING, CONFLICTING);
  rule(CONFLICTING, UNKNOWN, UNKNOWN);
  rule(CONFLICTING, BOOLEAN, BOOLEAN);
  rule(CONFLICTING, NUMBER, NUMBER);
  rule(CONFLICTING, INTEGER, INTEGER);
  rule(CONFLICTING, DOUBLE, DOUBLE);
  rule(CONFLICTING, INDEXABLE_PRIMITIVE, INDEXABLE_PRIMITIVE);
  rule(CONFLICTING, STRING, STRING);
  rule(CONFLICTING, READABLE_ARRAY, READABLE_ARRAY);
  rule(CONFLICTING, MUTABLE_ARRAY, MUTABLE_ARRAY);
  rule(CONFLICTING, EXTENDABLE_ARRAY, EXTENDABLE_ARRAY);
  rule(CONFLICTING, nonPrimitive1, nonPrimitive1);
  rule(CONFLICTING, nonPrimitive2, nonPrimitive2);
  rule(CONFLICTING, potentialArray, potentialArray);
  rule(CONFLICTING, potentialString, potentialString);
  rule(CONFLICTING, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(CONFLICTING, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(CONFLICTING, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(CONFLICTING, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(CONFLICTING, STRING_OR_NULL, STRING_OR_NULL);
  rule(CONFLICTING, NULL, NULL);
  rule(CONFLICTING, FIXED_ARRAY, FIXED_ARRAY);

  rule(UNKNOWN, UNKNOWN, UNKNOWN);
  rule(UNKNOWN, BOOLEAN, UNKNOWN);
  rule(UNKNOWN, NUMBER, UNKNOWN);
  rule(UNKNOWN, INTEGER, UNKNOWN);
  rule(UNKNOWN, DOUBLE, UNKNOWN);
  rule(UNKNOWN, INDEXABLE_PRIMITIVE, UNKNOWN);
  rule(UNKNOWN, STRING, UNKNOWN);
  rule(UNKNOWN, READABLE_ARRAY, UNKNOWN);
  rule(UNKNOWN, MUTABLE_ARRAY, UNKNOWN);
  rule(UNKNOWN, EXTENDABLE_ARRAY, UNKNOWN);
  rule(UNKNOWN, nonPrimitive1, UNKNOWN);
  rule(UNKNOWN, nonPrimitive2, UNKNOWN);
  rule(UNKNOWN, potentialArray, UNKNOWN);
  rule(UNKNOWN, potentialString, UNKNOWN);
  rule(UNKNOWN, BOOLEAN_OR_NULL, UNKNOWN);
  rule(UNKNOWN, NUMBER_OR_NULL, UNKNOWN);
  rule(UNKNOWN, INTEGER_OR_NULL, UNKNOWN);
  rule(UNKNOWN, DOUBLE_OR_NULL, UNKNOWN);
  rule(UNKNOWN, STRING_OR_NULL, UNKNOWN);
  rule(UNKNOWN, NULL, UNKNOWN);
  rule(UNKNOWN, FIXED_ARRAY, UNKNOWN);

  rule(BOOLEAN, BOOLEAN, BOOLEAN);
  rule(BOOLEAN, NUMBER, jsInterceptor);
  rule(BOOLEAN, INTEGER, jsInterceptor);
  rule(BOOLEAN, DOUBLE, jsInterceptor);
  rule(BOOLEAN, INDEXABLE_PRIMITIVE, NON_NULL);
  rule(BOOLEAN, STRING, jsInterceptor);
  rule(BOOLEAN, READABLE_ARRAY, jsInterceptor);
  rule(BOOLEAN, MUTABLE_ARRAY, jsInterceptor);
  rule(BOOLEAN, EXTENDABLE_ARRAY, jsInterceptor);
  rule(BOOLEAN, nonPrimitive1, NON_NULL);
  rule(BOOLEAN, nonPrimitive2, NON_NULL);
  rule(BOOLEAN, potentialArray, UNKNOWN);
  rule(BOOLEAN, potentialString, UNKNOWN);
  rule(BOOLEAN, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN, STRING_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN, NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN, FIXED_ARRAY, jsInterceptor);

  rule(NUMBER, NUMBER, NUMBER);
  rule(NUMBER, INTEGER, NUMBER);
  rule(NUMBER, DOUBLE, NUMBER);
  rule(NUMBER, INDEXABLE_PRIMITIVE, NON_NULL);
  rule(NUMBER, STRING, jsInterceptor);
  rule(NUMBER, READABLE_ARRAY, jsInterceptor);
  rule(NUMBER, MUTABLE_ARRAY, jsInterceptor);
  rule(NUMBER, EXTENDABLE_ARRAY, jsInterceptor);
  rule(NUMBER, nonPrimitive1, NON_NULL);
  rule(NUMBER, nonPrimitive2, NON_NULL);
  rule(NUMBER, potentialArray, UNKNOWN);
  rule(NUMBER, potentialString, UNKNOWN);
  rule(NUMBER, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(NUMBER, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER, INTEGER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER, DOUBLE_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER, STRING_OR_NULL, jsInterceptorOrNull);
  rule(NUMBER, NULL, NUMBER_OR_NULL);
  rule(NUMBER, FIXED_ARRAY, jsInterceptor);

  rule(INTEGER, INTEGER, INTEGER);
  rule(INTEGER, DOUBLE, NUMBER);
  rule(INTEGER, INDEXABLE_PRIMITIVE, NON_NULL);
  rule(INTEGER, STRING, jsInterceptor);
  rule(INTEGER, READABLE_ARRAY, jsInterceptor);
  rule(INTEGER, MUTABLE_ARRAY, jsInterceptor);
  rule(INTEGER, EXTENDABLE_ARRAY, jsInterceptor);
  rule(INTEGER, nonPrimitive1, NON_NULL);
  rule(INTEGER, nonPrimitive2, NON_NULL);
  rule(INTEGER, potentialArray, UNKNOWN);
  rule(INTEGER, potentialString, UNKNOWN);
  rule(INTEGER, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(INTEGER, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(INTEGER, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(INTEGER, DOUBLE_OR_NULL, NUMBER_OR_NULL);
  rule(INTEGER, STRING_OR_NULL, jsInterceptorOrNull);
  rule(INTEGER, NULL, INTEGER_OR_NULL);
  rule(INTEGER, FIXED_ARRAY, jsInterceptor);

  rule(DOUBLE, DOUBLE, DOUBLE);
  rule(DOUBLE, INDEXABLE_PRIMITIVE, NON_NULL);
  rule(DOUBLE, STRING, jsInterceptor);
  rule(DOUBLE, READABLE_ARRAY, jsInterceptor);
  rule(DOUBLE, MUTABLE_ARRAY, jsInterceptor);
  rule(DOUBLE, EXTENDABLE_ARRAY, jsInterceptor);
  rule(DOUBLE, nonPrimitive1, NON_NULL);
  rule(DOUBLE, nonPrimitive2, NON_NULL);
  rule(DOUBLE, potentialArray, UNKNOWN);
  rule(DOUBLE, potentialString, UNKNOWN);
  rule(DOUBLE, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(DOUBLE, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(DOUBLE, INTEGER_OR_NULL, NUMBER_OR_NULL);
  rule(DOUBLE, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(DOUBLE, STRING_OR_NULL, jsInterceptorOrNull);
  rule(DOUBLE, NULL, DOUBLE_OR_NULL);
  rule(DOUBLE, FIXED_ARRAY, jsInterceptor);

  rule(INDEXABLE_PRIMITIVE, INDEXABLE_PRIMITIVE, INDEXABLE_PRIMITIVE);
  rule(INDEXABLE_PRIMITIVE, STRING, INDEXABLE_PRIMITIVE);
  rule(INDEXABLE_PRIMITIVE, READABLE_ARRAY, INDEXABLE_PRIMITIVE);
  rule(INDEXABLE_PRIMITIVE, MUTABLE_ARRAY, INDEXABLE_PRIMITIVE);
  rule(INDEXABLE_PRIMITIVE, EXTENDABLE_ARRAY, INDEXABLE_PRIMITIVE);
  rule(INDEXABLE_PRIMITIVE, nonPrimitive1, NON_NULL);
  rule(INDEXABLE_PRIMITIVE, nonPrimitive2, NON_NULL);
  rule(INDEXABLE_PRIMITIVE, potentialArray, UNKNOWN);
  rule(INDEXABLE_PRIMITIVE, potentialString, UNKNOWN);
  rule(INDEXABLE_PRIMITIVE, BOOLEAN_OR_NULL, UNKNOWN);
  rule(INDEXABLE_PRIMITIVE, NUMBER_OR_NULL, UNKNOWN);
  rule(INDEXABLE_PRIMITIVE, INTEGER_OR_NULL, UNKNOWN);
  rule(INDEXABLE_PRIMITIVE, DOUBLE_OR_NULL, UNKNOWN);
  rule(INDEXABLE_PRIMITIVE, STRING_OR_NULL, jsIndexableOrNull);
  rule(INDEXABLE_PRIMITIVE, NULL, jsIndexableOrNull);
  rule(INDEXABLE_PRIMITIVE, FIXED_ARRAY, INDEXABLE_PRIMITIVE);

  rule(STRING, STRING, STRING);
  rule(STRING, READABLE_ARRAY, INDEXABLE_PRIMITIVE);
  rule(STRING, MUTABLE_ARRAY, INDEXABLE_PRIMITIVE);
  rule(STRING, EXTENDABLE_ARRAY, INDEXABLE_PRIMITIVE);
  rule(STRING, nonPrimitive1, NON_NULL);
  rule(STRING, nonPrimitive2, NON_NULL);
  rule(STRING, potentialArray, UNKNOWN);
  rule(STRING, potentialString, potentialString);
  rule(STRING, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(STRING, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(STRING, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(STRING, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(STRING, STRING_OR_NULL, STRING_OR_NULL);
  rule(STRING, NULL, STRING_OR_NULL);
  rule(STRING, FIXED_ARRAY, INDEXABLE_PRIMITIVE);

  rule(READABLE_ARRAY, READABLE_ARRAY, READABLE_ARRAY);
  rule(READABLE_ARRAY, MUTABLE_ARRAY, READABLE_ARRAY);
  rule(READABLE_ARRAY, EXTENDABLE_ARRAY, READABLE_ARRAY);
  rule(READABLE_ARRAY, nonPrimitive1, NON_NULL);
  rule(READABLE_ARRAY, nonPrimitive2, NON_NULL);
  rule(READABLE_ARRAY, potentialArray, potentialArray);
  rule(READABLE_ARRAY, potentialString, UNKNOWN);
  rule(READABLE_ARRAY, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(READABLE_ARRAY, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(READABLE_ARRAY, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(READABLE_ARRAY, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(READABLE_ARRAY, STRING_OR_NULL, jsIndexableOrNull);
  rule(READABLE_ARRAY, NULL, jsArrayOrNull);
  rule(READABLE_ARRAY, FIXED_ARRAY, READABLE_ARRAY);

  rule(MUTABLE_ARRAY, MUTABLE_ARRAY, MUTABLE_ARRAY);
  rule(MUTABLE_ARRAY, EXTENDABLE_ARRAY, MUTABLE_ARRAY);
  rule(MUTABLE_ARRAY, nonPrimitive1, NON_NULL);
  rule(MUTABLE_ARRAY, nonPrimitive2, NON_NULL);
  rule(MUTABLE_ARRAY, potentialArray, potentialArray);
  rule(MUTABLE_ARRAY, potentialString, UNKNOWN);
  rule(MUTABLE_ARRAY, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(MUTABLE_ARRAY, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(MUTABLE_ARRAY, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(MUTABLE_ARRAY, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(MUTABLE_ARRAY, STRING_OR_NULL, jsIndexableOrNull);
  rule(MUTABLE_ARRAY, NULL, jsMutableArrayOrNull);
  rule(MUTABLE_ARRAY, FIXED_ARRAY, MUTABLE_ARRAY);

  rule(EXTENDABLE_ARRAY, EXTENDABLE_ARRAY, EXTENDABLE_ARRAY);
  rule(EXTENDABLE_ARRAY, nonPrimitive1, NON_NULL);
  rule(EXTENDABLE_ARRAY, nonPrimitive2, NON_NULL);
  rule(EXTENDABLE_ARRAY, potentialArray, potentialArray);
  rule(EXTENDABLE_ARRAY, potentialString, UNKNOWN);
  rule(EXTENDABLE_ARRAY, BOOLEAN_OR_NULL, jsInterceptorOrNull);
  rule(EXTENDABLE_ARRAY, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(EXTENDABLE_ARRAY, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(EXTENDABLE_ARRAY, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(EXTENDABLE_ARRAY, STRING_OR_NULL, jsIndexableOrNull);
  rule(EXTENDABLE_ARRAY, NULL, jsExtendableArrayOrNull);
  rule(EXTENDABLE_ARRAY, FIXED_ARRAY, MUTABLE_ARRAY);

  rule(nonPrimitive1, nonPrimitive1, nonPrimitive1);
  rule(nonPrimitive1, nonPrimitive2, NON_NULL);
  rule(nonPrimitive1, potentialArray, UNKNOWN);
  rule(nonPrimitive1, potentialString, UNKNOWN);
  rule(nonPrimitive1, BOOLEAN_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, NUMBER_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, INTEGER_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, DOUBLE_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, STRING_OR_NULL, UNKNOWN);
  rule(nonPrimitive1, FIXED_ARRAY, NON_NULL);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, UNKNOWN);
  rule(nonPrimitive2, potentialString, UNKNOWN);
  rule(nonPrimitive2, BOOLEAN_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, NUMBER_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, INTEGER_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, DOUBLE_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, STRING_OR_NULL, UNKNOWN);
  rule(nonPrimitive2, FIXED_ARRAY, NON_NULL);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, UNKNOWN);
  rule(potentialArray, BOOLEAN_OR_NULL, UNKNOWN);
  rule(potentialArray, NUMBER_OR_NULL, UNKNOWN);
  rule(potentialArray, INTEGER_OR_NULL, UNKNOWN);
  rule(potentialArray, DOUBLE_OR_NULL, UNKNOWN);
  rule(potentialArray, STRING_OR_NULL, UNKNOWN);
  rule(potentialArray, NULL, potentialArray);
  rule(potentialArray, FIXED_ARRAY, potentialArray);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, BOOLEAN_OR_NULL, UNKNOWN);
  rule(potentialString, NUMBER_OR_NULL, UNKNOWN);
  rule(potentialString, INTEGER_OR_NULL, UNKNOWN);
  rule(potentialString, DOUBLE_OR_NULL, UNKNOWN);
  rule(potentialString, STRING_OR_NULL, potentialString);
  rule(potentialString, NULL, potentialString);
  rule(potentialString, FIXED_ARRAY, UNKNOWN);

  rule(BOOLEAN_OR_NULL, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN_OR_NULL, NUMBER_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN_OR_NULL, INTEGER_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN_OR_NULL, DOUBLE_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN_OR_NULL, STRING_OR_NULL, jsInterceptorOrNull);
  rule(BOOLEAN_OR_NULL, NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN_OR_NULL, FIXED_ARRAY, jsInterceptorOrNull);

  rule(NUMBER_OR_NULL, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, INTEGER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, DOUBLE_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, STRING_OR_NULL, jsInterceptorOrNull);
  rule(NUMBER_OR_NULL, NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, FIXED_ARRAY, jsInterceptorOrNull);

  rule(INTEGER_OR_NULL, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(INTEGER_OR_NULL, DOUBLE_OR_NULL, NUMBER_OR_NULL);
  rule(INTEGER_OR_NULL, STRING_OR_NULL, jsInterceptorOrNull);
  rule(INTEGER_OR_NULL, NULL, INTEGER_OR_NULL);
  rule(INTEGER_OR_NULL, FIXED_ARRAY, jsInterceptorOrNull);

  rule(DOUBLE_OR_NULL, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(DOUBLE_OR_NULL, STRING_OR_NULL, jsInterceptorOrNull);
  rule(DOUBLE_OR_NULL, NULL, DOUBLE_OR_NULL);
  rule(DOUBLE_OR_NULL, FIXED_ARRAY, jsInterceptorOrNull);

  rule(STRING_OR_NULL, STRING_OR_NULL, STRING_OR_NULL);
  rule(STRING_OR_NULL, NULL, STRING_OR_NULL);
  rule(STRING_OR_NULL, FIXED_ARRAY, jsIndexableOrNull);

  rule(NULL, NULL, NULL);
  rule(NULL, FIXED_ARRAY, jsFixedArrayOrNull);

  rule(FIXED_ARRAY, FIXED_ARRAY, FIXED_ARRAY);

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
  rule(CONFLICTING, INDEXABLE_PRIMITIVE, CONFLICTING);
  rule(CONFLICTING, STRING, CONFLICTING);
  rule(CONFLICTING, READABLE_ARRAY, CONFLICTING);
  rule(CONFLICTING, MUTABLE_ARRAY, CONFLICTING);
  rule(CONFLICTING, EXTENDABLE_ARRAY, CONFLICTING);
  rule(CONFLICTING, nonPrimitive1, CONFLICTING);
  rule(CONFLICTING, nonPrimitive2, CONFLICTING);
  rule(CONFLICTING, potentialArray, CONFLICTING);
  rule(CONFLICTING, potentialString, CONFLICTING);
  rule(CONFLICTING, BOOLEAN_OR_NULL, CONFLICTING);
  rule(CONFLICTING, NUMBER_OR_NULL, CONFLICTING);
  rule(CONFLICTING, INTEGER_OR_NULL, CONFLICTING);
  rule(CONFLICTING, DOUBLE_OR_NULL, CONFLICTING);
  rule(CONFLICTING, STRING_OR_NULL, CONFLICTING);
  rule(CONFLICTING, NULL, CONFLICTING);
  rule(CONFLICTING, FIXED_ARRAY, CONFLICTING);

  rule(UNKNOWN, UNKNOWN, UNKNOWN);
  rule(UNKNOWN, BOOLEAN, BOOLEAN);
  rule(UNKNOWN, NUMBER, NUMBER);
  rule(UNKNOWN, INTEGER, INTEGER);
  rule(UNKNOWN, DOUBLE, DOUBLE);
  rule(UNKNOWN, INDEXABLE_PRIMITIVE, INDEXABLE_PRIMITIVE);
  rule(UNKNOWN, STRING, STRING);
  rule(UNKNOWN, READABLE_ARRAY, READABLE_ARRAY);
  rule(UNKNOWN, MUTABLE_ARRAY, MUTABLE_ARRAY);
  rule(UNKNOWN, EXTENDABLE_ARRAY, EXTENDABLE_ARRAY);
  rule(UNKNOWN, nonPrimitive1, nonPrimitive1);
  rule(UNKNOWN, nonPrimitive2, nonPrimitive2);
  rule(UNKNOWN, potentialArray, potentialArray);
  rule(UNKNOWN, potentialString, potentialString);
  rule(UNKNOWN, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(UNKNOWN, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(UNKNOWN, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(UNKNOWN, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(UNKNOWN, STRING_OR_NULL, STRING_OR_NULL);
  rule(UNKNOWN, NULL, NULL);
  rule(UNKNOWN, FIXED_ARRAY, FIXED_ARRAY);

  rule(BOOLEAN, BOOLEAN, BOOLEAN);
  rule(BOOLEAN, NUMBER, CONFLICTING);
  rule(BOOLEAN, INTEGER, CONFLICTING);
  rule(BOOLEAN, DOUBLE, CONFLICTING);
  rule(BOOLEAN, INDEXABLE_PRIMITIVE, CONFLICTING);
  rule(BOOLEAN, STRING, CONFLICTING);
  rule(BOOLEAN, READABLE_ARRAY, CONFLICTING);
  rule(BOOLEAN, MUTABLE_ARRAY, CONFLICTING);
  rule(BOOLEAN, EXTENDABLE_ARRAY, CONFLICTING);
  rule(BOOLEAN, nonPrimitive1, CONFLICTING);
  rule(BOOLEAN, nonPrimitive2, CONFLICTING);
  rule(BOOLEAN, potentialArray, CONFLICTING);
  rule(BOOLEAN, potentialString, CONFLICTING);
  rule(BOOLEAN, BOOLEAN_OR_NULL, BOOLEAN);
  rule(BOOLEAN, NUMBER_OR_NULL, CONFLICTING);
  rule(BOOLEAN, INTEGER_OR_NULL, CONFLICTING);
  rule(BOOLEAN, DOUBLE_OR_NULL, CONFLICTING);
  rule(BOOLEAN, STRING_OR_NULL, CONFLICTING);
  rule(BOOLEAN, NULL, CONFLICTING);
  rule(BOOLEAN, FIXED_ARRAY, CONFLICTING);

  rule(NUMBER, NUMBER, NUMBER);
  rule(NUMBER, INTEGER, INTEGER);
  rule(NUMBER, DOUBLE, DOUBLE);
  rule(NUMBER, INDEXABLE_PRIMITIVE, CONFLICTING);
  rule(NUMBER, STRING, CONFLICTING);
  rule(NUMBER, READABLE_ARRAY, CONFLICTING);
  rule(NUMBER, MUTABLE_ARRAY, CONFLICTING);
  rule(NUMBER, EXTENDABLE_ARRAY, CONFLICTING);
  rule(NUMBER, nonPrimitive1, CONFLICTING);
  rule(NUMBER, nonPrimitive2, CONFLICTING);
  rule(NUMBER, potentialArray, CONFLICTING);
  rule(NUMBER, potentialString, CONFLICTING);
  rule(NUMBER, BOOLEAN_OR_NULL, CONFLICTING);
  rule(NUMBER, NUMBER_OR_NULL, NUMBER);
  rule(NUMBER, INTEGER_OR_NULL, INTEGER);
  rule(NUMBER, DOUBLE_OR_NULL, DOUBLE);
  rule(NUMBER, STRING_OR_NULL, CONFLICTING);
  rule(NUMBER, NULL, CONFLICTING);
  rule(NUMBER, FIXED_ARRAY, CONFLICTING);

  rule(INTEGER, INTEGER, INTEGER);
  rule(INTEGER, DOUBLE, CONFLICTING);
  rule(INTEGER, INDEXABLE_PRIMITIVE, CONFLICTING);
  rule(INTEGER, STRING, CONFLICTING);
  rule(INTEGER, READABLE_ARRAY, CONFLICTING);
  rule(INTEGER, MUTABLE_ARRAY, CONFLICTING);
  rule(INTEGER, EXTENDABLE_ARRAY, CONFLICTING);
  rule(INTEGER, nonPrimitive1, CONFLICTING);
  rule(INTEGER, nonPrimitive2, CONFLICTING);
  rule(INTEGER, potentialArray, CONFLICTING);
  rule(INTEGER, potentialString, CONFLICTING);
  rule(INTEGER, BOOLEAN_OR_NULL, CONFLICTING);
  rule(INTEGER, NUMBER_OR_NULL, INTEGER);
  rule(INTEGER, INTEGER_OR_NULL, INTEGER);
  rule(INTEGER, DOUBLE_OR_NULL, CONFLICTING);
  rule(INTEGER, STRING_OR_NULL, CONFLICTING);
  rule(INTEGER, NULL, CONFLICTING);
  rule(INTEGER, FIXED_ARRAY, CONFLICTING);

  rule(DOUBLE, DOUBLE, DOUBLE);
  rule(DOUBLE, INDEXABLE_PRIMITIVE, CONFLICTING);
  rule(DOUBLE, STRING, CONFLICTING);
  rule(DOUBLE, READABLE_ARRAY, CONFLICTING);
  rule(DOUBLE, MUTABLE_ARRAY, CONFLICTING);
  rule(DOUBLE, EXTENDABLE_ARRAY, CONFLICTING);
  rule(DOUBLE, nonPrimitive1, CONFLICTING);
  rule(DOUBLE, nonPrimitive2, CONFLICTING);
  rule(DOUBLE, potentialArray, CONFLICTING);
  rule(DOUBLE, potentialString, CONFLICTING);
  rule(DOUBLE, BOOLEAN_OR_NULL, CONFLICTING);
  rule(DOUBLE, NUMBER_OR_NULL, DOUBLE);
  rule(DOUBLE, INTEGER_OR_NULL, CONFLICTING);
  rule(DOUBLE, DOUBLE_OR_NULL, DOUBLE);
  rule(DOUBLE, STRING_OR_NULL, CONFLICTING);
  rule(DOUBLE, NULL, CONFLICTING);
  rule(DOUBLE, FIXED_ARRAY, CONFLICTING);

  rule(INDEXABLE_PRIMITIVE, INDEXABLE_PRIMITIVE, INDEXABLE_PRIMITIVE);
  rule(INDEXABLE_PRIMITIVE, STRING, STRING);
  rule(INDEXABLE_PRIMITIVE, READABLE_ARRAY, READABLE_ARRAY);
  rule(INDEXABLE_PRIMITIVE, MUTABLE_ARRAY, MUTABLE_ARRAY);
  rule(INDEXABLE_PRIMITIVE, EXTENDABLE_ARRAY, EXTENDABLE_ARRAY);
  rule(INDEXABLE_PRIMITIVE, nonPrimitive1, CONFLICTING);
  rule(INDEXABLE_PRIMITIVE, nonPrimitive2, CONFLICTING);
  rule(INDEXABLE_PRIMITIVE, potentialArray, READABLE_ARRAY);
  rule(INDEXABLE_PRIMITIVE, potentialString, STRING);
  rule(INDEXABLE_PRIMITIVE, BOOLEAN_OR_NULL, CONFLICTING);
  rule(INDEXABLE_PRIMITIVE, NUMBER_OR_NULL, CONFLICTING);
  rule(INDEXABLE_PRIMITIVE, INTEGER_OR_NULL, CONFLICTING);
  rule(INDEXABLE_PRIMITIVE, DOUBLE_OR_NULL, CONFLICTING);
  rule(INDEXABLE_PRIMITIVE, STRING_OR_NULL, STRING);
  rule(INDEXABLE_PRIMITIVE, NULL, CONFLICTING);
  rule(INDEXABLE_PRIMITIVE, FIXED_ARRAY, FIXED_ARRAY);

  rule(STRING, STRING, STRING);
  rule(STRING, READABLE_ARRAY, CONFLICTING);
  rule(STRING, MUTABLE_ARRAY, CONFLICTING);
  rule(STRING, EXTENDABLE_ARRAY, CONFLICTING);
  rule(STRING, nonPrimitive1, CONFLICTING);
  rule(STRING, nonPrimitive2, CONFLICTING);
  rule(STRING, potentialArray, CONFLICTING);
  rule(STRING, potentialString, STRING);
  rule(STRING, BOOLEAN_OR_NULL, CONFLICTING);
  rule(STRING, NUMBER_OR_NULL, CONFLICTING);
  rule(STRING, INTEGER_OR_NULL, CONFLICTING);
  rule(STRING, DOUBLE_OR_NULL, CONFLICTING);
  rule(STRING, STRING_OR_NULL, STRING);
  rule(STRING, NULL, CONFLICTING);
  rule(STRING, FIXED_ARRAY, CONFLICTING);

  rule(READABLE_ARRAY, READABLE_ARRAY, READABLE_ARRAY);
  rule(READABLE_ARRAY, MUTABLE_ARRAY, MUTABLE_ARRAY);
  rule(READABLE_ARRAY, EXTENDABLE_ARRAY, EXTENDABLE_ARRAY);
  rule(READABLE_ARRAY, nonPrimitive1, CONFLICTING);
  rule(READABLE_ARRAY, nonPrimitive2, CONFLICTING);
  rule(READABLE_ARRAY, potentialArray, READABLE_ARRAY);
  rule(READABLE_ARRAY, potentialString, CONFLICTING);
  rule(READABLE_ARRAY, BOOLEAN_OR_NULL, CONFLICTING);
  rule(READABLE_ARRAY, NUMBER_OR_NULL, CONFLICTING);
  rule(READABLE_ARRAY, INTEGER_OR_NULL, CONFLICTING);
  rule(READABLE_ARRAY, DOUBLE_OR_NULL, CONFLICTING);
  rule(READABLE_ARRAY, STRING_OR_NULL, CONFLICTING);
  rule(READABLE_ARRAY, NULL, CONFLICTING);
  rule(READABLE_ARRAY, FIXED_ARRAY, FIXED_ARRAY);

  rule(MUTABLE_ARRAY, MUTABLE_ARRAY, MUTABLE_ARRAY);
  rule(MUTABLE_ARRAY, EXTENDABLE_ARRAY, EXTENDABLE_ARRAY);
  rule(MUTABLE_ARRAY, nonPrimitive1, CONFLICTING);
  rule(MUTABLE_ARRAY, nonPrimitive2, CONFLICTING);
  rule(MUTABLE_ARRAY, potentialArray, MUTABLE_ARRAY);
  rule(MUTABLE_ARRAY, potentialString, CONFLICTING);
  rule(MUTABLE_ARRAY, BOOLEAN_OR_NULL, CONFLICTING);
  rule(MUTABLE_ARRAY, NUMBER_OR_NULL, CONFLICTING);
  rule(MUTABLE_ARRAY, INTEGER_OR_NULL, CONFLICTING);
  rule(MUTABLE_ARRAY, DOUBLE_OR_NULL, CONFLICTING);
  rule(MUTABLE_ARRAY, STRING_OR_NULL, CONFLICTING);
  rule(MUTABLE_ARRAY, NULL, CONFLICTING);
  rule(MUTABLE_ARRAY, FIXED_ARRAY, FIXED_ARRAY);

  rule(EXTENDABLE_ARRAY, EXTENDABLE_ARRAY, EXTENDABLE_ARRAY);
  rule(EXTENDABLE_ARRAY, nonPrimitive1, CONFLICTING);
  rule(EXTENDABLE_ARRAY, nonPrimitive2, CONFLICTING);
  rule(EXTENDABLE_ARRAY, potentialArray, EXTENDABLE_ARRAY);
  rule(EXTENDABLE_ARRAY, potentialString, CONFLICTING);
  rule(EXTENDABLE_ARRAY, BOOLEAN_OR_NULL, CONFLICTING);
  rule(EXTENDABLE_ARRAY, NUMBER_OR_NULL, CONFLICTING);
  rule(EXTENDABLE_ARRAY, INTEGER_OR_NULL, CONFLICTING);
  rule(EXTENDABLE_ARRAY, DOUBLE_OR_NULL, CONFLICTING);
  rule(EXTENDABLE_ARRAY, STRING_OR_NULL, CONFLICTING);
  rule(EXTENDABLE_ARRAY, NULL, CONFLICTING);
  rule(EXTENDABLE_ARRAY, FIXED_ARRAY, CONFLICTING);

  rule(nonPrimitive1, nonPrimitive1, nonPrimitive1);
  rule(nonPrimitive1, nonPrimitive2, CONFLICTING);
  rule(nonPrimitive1, potentialArray, CONFLICTING);
  rule(nonPrimitive1, potentialString, CONFLICTING);
  rule(nonPrimitive1, BOOLEAN_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, NUMBER_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, INTEGER_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, DOUBLE_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, STRING_OR_NULL, CONFLICTING);
  rule(nonPrimitive1, NULL, CONFLICTING);
  rule(nonPrimitive1, FIXED_ARRAY, CONFLICTING);

  rule(nonPrimitive2, nonPrimitive2, nonPrimitive2);
  rule(nonPrimitive2, potentialArray, CONFLICTING);
  rule(nonPrimitive2, potentialString, CONFLICTING);
  rule(nonPrimitive2, BOOLEAN_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, NUMBER_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, INTEGER_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, DOUBLE_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, STRING_OR_NULL, CONFLICTING);
  rule(nonPrimitive2, NULL, CONFLICTING);
  rule(nonPrimitive2, FIXED_ARRAY, CONFLICTING);

  rule(potentialArray, potentialArray, potentialArray);
  rule(potentialArray, potentialString, NULL);
  rule(potentialArray, BOOLEAN_OR_NULL, NULL);
  rule(potentialArray, NUMBER_OR_NULL, NULL);
  rule(potentialArray, INTEGER_OR_NULL, NULL);
  rule(potentialArray, DOUBLE_OR_NULL, NULL);
  rule(potentialArray, STRING_OR_NULL, NULL);
  rule(potentialArray, NULL, NULL);
  rule(potentialArray, FIXED_ARRAY, FIXED_ARRAY);

  rule(potentialString, potentialString, potentialString);
  rule(potentialString, BOOLEAN_OR_NULL, NULL);
  rule(potentialString, NUMBER_OR_NULL, NULL);
  rule(potentialString, INTEGER_OR_NULL, NULL);
  rule(potentialString, DOUBLE_OR_NULL, NULL);
  rule(potentialString, STRING_OR_NULL, STRING_OR_NULL);
  rule(potentialString, NULL, NULL);
  rule(potentialString, FIXED_ARRAY, CONFLICTING);

  rule(BOOLEAN_OR_NULL, BOOLEAN_OR_NULL, BOOLEAN_OR_NULL);
  rule(BOOLEAN_OR_NULL, NUMBER_OR_NULL, NULL);
  rule(BOOLEAN_OR_NULL, INTEGER_OR_NULL, NULL);
  rule(BOOLEAN_OR_NULL, DOUBLE_OR_NULL, NULL);
  rule(BOOLEAN_OR_NULL, STRING_OR_NULL, NULL);
  rule(BOOLEAN_OR_NULL, NULL, NULL);
  rule(BOOLEAN_OR_NULL, FIXED_ARRAY, CONFLICTING);

  rule(NUMBER_OR_NULL, NUMBER_OR_NULL, NUMBER_OR_NULL);
  rule(NUMBER_OR_NULL, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(NUMBER_OR_NULL, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(NUMBER_OR_NULL, STRING_OR_NULL, NULL);
  rule(NUMBER_OR_NULL, NULL, NULL);
  rule(NUMBER_OR_NULL, FIXED_ARRAY, CONFLICTING);

  rule(INTEGER_OR_NULL, INTEGER_OR_NULL, INTEGER_OR_NULL);
  rule(INTEGER_OR_NULL, DOUBLE_OR_NULL, NULL);
  rule(INTEGER_OR_NULL, STRING_OR_NULL, NULL);
  rule(INTEGER_OR_NULL, NULL, NULL);
  rule(INTEGER_OR_NULL, FIXED_ARRAY, CONFLICTING);

  rule(DOUBLE_OR_NULL, DOUBLE_OR_NULL, DOUBLE_OR_NULL);
  rule(DOUBLE_OR_NULL, STRING_OR_NULL, NULL);
  rule(DOUBLE_OR_NULL, NULL, NULL);
  rule(DOUBLE_OR_NULL, FIXED_ARRAY, CONFLICTING);

  rule(STRING_OR_NULL, STRING_OR_NULL, STRING_OR_NULL);
  rule(STRING_OR_NULL, NULL, NULL);
  rule(STRING_OR_NULL, FIXED_ARRAY, CONFLICTING);

  rule(NULL, NULL, NULL);
  rule(NULL, FIXED_ARRAY, CONFLICTING);

  rule(FIXED_ARRAY, FIXED_ARRAY, FIXED_ARRAY);

  ruleSet.validateCoverage();
}

void testRegressions(MockCompiler compiler) {
  HType nonNullPotentialString = new HType.nonNullSubtype(
      patternClass.computeType(compiler), compiler);
  Expect.equals(
      potentialString, STRING_OR_NULL.union(nonNullPotentialString, compiler));
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
      compiler.mapClass.computeType(compiler), compiler);
  nonPrimitive2 = new HType.nonNullSubtype(
      compiler.functionClass.computeType(compiler), compiler);
  potentialArray = new HType.subtype(
      compiler.listClass.computeType(compiler), compiler);
  potentialString = new HType.subtype(
      patternClass.computeType(compiler), compiler);
  jsInterceptor = new HType.nonNullSubclass(
      compiler.backend.jsInterceptorClass.computeType(compiler), compiler);
  jsArrayOrNull = new HType.subclass(
      compiler.backend.jsArrayClass.computeType(compiler), compiler);
  jsMutableArrayOrNull = new HType.subclass(
      compiler.backend.jsMutableArrayClass.computeType(compiler), compiler);
  jsFixedArrayOrNull = new HType.exact(
      compiler.backend.jsFixedArrayClass.computeType(compiler), compiler);
  jsExtendableArrayOrNull = new HType.exact(
      compiler.backend.jsExtendableArrayClass.computeType(compiler), compiler);
  jsIndexableOrNull = new HType.subtype(
      compiler.backend.jsIndexableClass.computeType(compiler), compiler);
  jsInterceptorOrNull = new HType.subclass(
      compiler.backend.jsInterceptorClass.computeType(compiler), compiler);

  testUnion(compiler);
  testIntersection(compiler);
  testRegressions(compiler);
}
