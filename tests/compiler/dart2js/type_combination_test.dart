// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "mock_compiler.dart";
import "../../../sdk/lib/_internal/compiler/implementation/ssa/ssa.dart";

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
HType nonPrimitive1;
HType nonPrimitive2;
HType potentialArray;
HType potentialString;

void testUnion(MockCompiler compiler) {
  Expect.equals(CONFLICTING, 
                CONFLICTING.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                CONFLICTING.union(UNKNOWN, compiler));
  Expect.equals(BOOLEAN, 
                CONFLICTING.union(BOOLEAN, compiler));
  Expect.equals(NUMBER, 
                CONFLICTING.union(NUMBER, compiler));
  Expect.equals(INTEGER, 
                CONFLICTING.union(INTEGER, compiler));
  Expect.equals(DOUBLE, 
                CONFLICTING.union(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                CONFLICTING.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(STRING, 
                CONFLICTING.union(STRING, compiler));
  Expect.equals(READABLE_ARRAY, 
                CONFLICTING.union(READABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                CONFLICTING.union(MUTABLE_ARRAY, compiler));
  Expect.equals(EXTENDABLE_ARRAY, 
                CONFLICTING.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(nonPrimitive1, 
                CONFLICTING.union(nonPrimitive1, compiler));
  Expect.equals(nonPrimitive2, 
                CONFLICTING.union(nonPrimitive2, compiler));
  Expect.equals(potentialArray, 
                CONFLICTING.union(potentialArray, compiler));
  Expect.equals(potentialString, 
                CONFLICTING.union(potentialString, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                CONFLICTING.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                CONFLICTING.union(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                CONFLICTING.union(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                CONFLICTING.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                CONFLICTING.union(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                CONFLICTING.union(NULL, compiler));
  Expect.equals(FIXED_ARRAY, 
                CONFLICTING.union(FIXED_ARRAY, compiler));

  Expect.equals(UNKNOWN, 
                UNKNOWN.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(STRING_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.union(FIXED_ARRAY, compiler));

  Expect.equals(BOOLEAN, 
                BOOLEAN.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(UNKNOWN, compiler));
  Expect.equals(BOOLEAN, 
                BOOLEAN.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(potentialString, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                BOOLEAN.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(STRING_OR_NULL, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                BOOLEAN.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN.union(FIXED_ARRAY, compiler));

  Expect.equals(NUMBER, 
                NUMBER.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(BOOLEAN, compiler));
  Expect.equals(NUMBER, 
                NUMBER.union(NUMBER, compiler));
  Expect.equals(NUMBER, 
                NUMBER.union(INTEGER, compiler));
  Expect.equals(NUMBER, 
                NUMBER.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER.union(NUMBER_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER.union(INTEGER_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(STRING_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER.union(FIXED_ARRAY, compiler));

  Expect.equals(INTEGER, 
                INTEGER.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(BOOLEAN, compiler));
  Expect.equals(NUMBER, 
                INTEGER.union(NUMBER, compiler));
  Expect.equals(INTEGER, 
                INTEGER.union(INTEGER, compiler));
  Expect.equals(NUMBER, 
                INTEGER.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                INTEGER.union(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                INTEGER.union(INTEGER_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                INTEGER.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(STRING_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                INTEGER.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER.union(FIXED_ARRAY, compiler));

  Expect.equals(DOUBLE, 
                DOUBLE.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(BOOLEAN, compiler));
  Expect.equals(NUMBER, 
                DOUBLE.union(NUMBER, compiler));
  Expect.equals(NUMBER, 
                DOUBLE.union(INTEGER, compiler));
  Expect.equals(DOUBLE, 
                DOUBLE.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                DOUBLE.union(NUMBER_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                DOUBLE.union(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(STRING_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE.union(FIXED_ARRAY, compiler));

  Expect.equals(INDEXABLE_PRIMITIVE, 
                INDEXABLE_PRIMITIVE.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE,
                INDEXABLE_PRIMITIVE.union(INDEXABLE_PRIMITIVE, 
                compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                INDEXABLE_PRIMITIVE.union(STRING, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                INDEXABLE_PRIMITIVE.union(READABLE_ARRAY, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                INDEXABLE_PRIMITIVE.union(MUTABLE_ARRAY, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE,
                INDEXABLE_PRIMITIVE.union(EXTENDABLE_ARRAY, 
                compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(STRING_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                INDEXABLE_PRIMITIVE.union(NULL, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                INDEXABLE_PRIMITIVE.union(FIXED_ARRAY, compiler));

  Expect.equals(STRING, 
                STRING.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                STRING.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(STRING, 
                STRING.union(STRING, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                STRING.union(READABLE_ARRAY, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                STRING.union(MUTABLE_ARRAY, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                STRING.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(potentialArray, compiler));
  Expect.equals(potentialString, 
                STRING.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                STRING.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                STRING.union(STRING_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                STRING.union(NULL, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                STRING.union(FIXED_ARRAY, compiler));

  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                READABLE_ARRAY.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                READABLE_ARRAY.union(STRING, compiler));
  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.union(READABLE_ARRAY, compiler));
  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.union(MUTABLE_ARRAY, compiler));
  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(nonPrimitive2, compiler));
  Expect.equals(potentialArray, 
                READABLE_ARRAY.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(STRING_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                READABLE_ARRAY.union(NULL, compiler));
  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.union(FIXED_ARRAY, compiler));

  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                MUTABLE_ARRAY.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                MUTABLE_ARRAY.union(STRING, compiler));
  Expect.equals(READABLE_ARRAY, 
                MUTABLE_ARRAY.union(READABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.union(MUTABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(nonPrimitive2, compiler));
  Expect.equals(potentialArray,MUTABLE_ARRAY.union(potentialArray, 
                compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(STRING_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                MUTABLE_ARRAY.union(NULL, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.union(FIXED_ARRAY, compiler));

  Expect.equals(EXTENDABLE_ARRAY, 
                EXTENDABLE_ARRAY.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                EXTENDABLE_ARRAY.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                EXTENDABLE_ARRAY.union(STRING, compiler));
  Expect.equals(READABLE_ARRAY, 
                EXTENDABLE_ARRAY.union(READABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                EXTENDABLE_ARRAY.union(MUTABLE_ARRAY, compiler));
  Expect.equals(EXTENDABLE_ARRAY, 
                EXTENDABLE_ARRAY.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(nonPrimitive2, compiler));
  Expect.equals(potentialArray, 
                EXTENDABLE_ARRAY.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(STRING_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                EXTENDABLE_ARRAY.union(NULL, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                EXTENDABLE_ARRAY.union(FIXED_ARRAY, compiler));

  Expect.equals(nonPrimitive1, 
                nonPrimitive1.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(nonPrimitive1, 
                nonPrimitive1.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(STRING_OR_NULL, compiler));
  Expect.isTrue(nonPrimitive1.union(NULL, compiler) is HBoundedType);
  Expect.equals(UNKNOWN, 
                nonPrimitive1.union(FIXED_ARRAY, compiler));

  Expect.equals(nonPrimitive2, 
                nonPrimitive2.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(nonPrimitive1, compiler));
  Expect.equals(nonPrimitive2, 
                nonPrimitive2.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(STRING_OR_NULL, compiler));
  Expect.isTrue(nonPrimitive2.union(NULL, compiler) is HBoundedType);
  Expect.equals(UNKNOWN, 
                nonPrimitive2.union(FIXED_ARRAY, compiler));

  Expect.equals(potentialArray, 
                potentialArray.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(STRING, compiler));
  Expect.equals(potentialArray, 
                potentialArray.union(READABLE_ARRAY, compiler));
  Expect.equals(potentialArray, 
                potentialArray.union(MUTABLE_ARRAY, compiler));
  Expect.equals(potentialArray, 
                potentialArray.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(nonPrimitive2, compiler));
  Expect.equals(potentialArray, 
                potentialArray.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                potentialArray.union(STRING_OR_NULL, compiler));
  Expect.equals(potentialArray, 
                potentialArray.union(NULL, compiler));
  Expect.equals(potentialArray, 
                potentialArray.union(FIXED_ARRAY, compiler));

  Expect.equals(potentialString, 
                potentialString.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(potentialString, 
                potentialString.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(potentialArray, compiler));
  Expect.equals(potentialString, 
                potentialString.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(potentialString, 
                potentialString.union(STRING_OR_NULL, compiler));
  Expect.equals(potentialString, 
                potentialString.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                potentialString.union(FIXED_ARRAY, compiler));

  Expect.equals(BOOLEAN_OR_NULL, 
                BOOLEAN_OR_NULL.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(UNKNOWN, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                BOOLEAN_OR_NULL.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(potentialString, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                BOOLEAN_OR_NULL.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(STRING_OR_NULL, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                BOOLEAN_OR_NULL.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                BOOLEAN_OR_NULL.union(FIXED_ARRAY, compiler));

  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(BOOLEAN, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.union(NUMBER, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.union(INTEGER, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.union(NUMBER_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.union(INTEGER_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(STRING_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                NUMBER_OR_NULL.union(FIXED_ARRAY, compiler));

  Expect.equals(INTEGER_OR_NULL, 
                INTEGER_OR_NULL.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(BOOLEAN, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                INTEGER_OR_NULL.union(NUMBER, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                INTEGER_OR_NULL.union(INTEGER, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                INTEGER_OR_NULL.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                INTEGER_OR_NULL.union(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                INTEGER_OR_NULL.union(INTEGER_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                INTEGER_OR_NULL.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(STRING_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                INTEGER_OR_NULL.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                INTEGER_OR_NULL.union(FIXED_ARRAY, compiler));

  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE_OR_NULL.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(BOOLEAN, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                DOUBLE_OR_NULL.union(NUMBER, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                DOUBLE_OR_NULL.union(INTEGER, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE_OR_NULL.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                DOUBLE_OR_NULL.union(NUMBER_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                DOUBLE_OR_NULL.union(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE_OR_NULL.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(STRING_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE_OR_NULL.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                DOUBLE_OR_NULL.union(FIXED_ARRAY, compiler));

  Expect.equals(STRING_OR_NULL, 
                STRING_OR_NULL.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(STRING_OR_NULL, 
                STRING_OR_NULL.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(nonPrimitive2, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(potentialArray, compiler));
  Expect.equals(potentialString, 
                STRING_OR_NULL.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                STRING_OR_NULL.union(STRING_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                STRING_OR_NULL.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                STRING_OR_NULL.union(FIXED_ARRAY, compiler));

  Expect.equals(NULL, 
                NULL.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                NULL.union(UNKNOWN, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                NULL.union(BOOLEAN, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NULL.union(NUMBER, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                NULL.union(INTEGER, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                NULL.union(DOUBLE, compiler));
  Expect.equals(UNKNOWN, 
                NULL.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(STRING_OR_NULL, 
                NULL.union(STRING, compiler));
  Expect.equals(UNKNOWN, 
                NULL.union(READABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NULL.union(MUTABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NULL.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                NULL.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                NULL.union(nonPrimitive2, compiler));
  Expect.equals(potentialArray, 
                NULL.union(potentialArray, compiler));
  Expect.equals(potentialString, 
                NULL.union(potentialString, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                NULL.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NULL.union(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                NULL.union(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                NULL.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                NULL.union(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                NULL.union(NULL, compiler));
  Expect.equals(UNKNOWN, 
                NULL.union(FIXED_ARRAY, compiler));

  Expect.equals(FIXED_ARRAY, 
                FIXED_ARRAY.union(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(UNKNOWN, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(BOOLEAN, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(NUMBER, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(INTEGER, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                FIXED_ARRAY.union(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                FIXED_ARRAY.union(STRING, compiler));
  Expect.equals(READABLE_ARRAY, 
                FIXED_ARRAY.union(READABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                FIXED_ARRAY.union(MUTABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                FIXED_ARRAY.union(EXTENDABLE_ARRAY, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(nonPrimitive1, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(nonPrimitive2, compiler));
  Expect.equals(potentialArray, 
                FIXED_ARRAY.union(potentialArray, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(potentialString, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(BOOLEAN_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(NUMBER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(INTEGER_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(DOUBLE_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(STRING_OR_NULL, compiler));
  Expect.equals(UNKNOWN, 
                FIXED_ARRAY.union(NULL, compiler));
  Expect.equals(FIXED_ARRAY, 
                FIXED_ARRAY.union(FIXED_ARRAY, compiler));
}

void testIntersection(MockCompiler compiler) {
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(CONFLICTING, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(nonPrimitive2, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                CONFLICTING.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                UNKNOWN.intersection(CONFLICTING, compiler));
  Expect.equals(UNKNOWN, 
                UNKNOWN.intersection(UNKNOWN, compiler));
  Expect.equals(BOOLEAN, 
                UNKNOWN.intersection(BOOLEAN, compiler));
  Expect.equals(NUMBER, 
                UNKNOWN.intersection(NUMBER, compiler));
  Expect.equals(INTEGER, 
                UNKNOWN.intersection(INTEGER, compiler));
  Expect.equals(DOUBLE, 
                UNKNOWN.intersection(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                UNKNOWN.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(STRING, 
                UNKNOWN.intersection(STRING, compiler));
  Expect.equals(READABLE_ARRAY, 
                UNKNOWN.intersection(READABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                UNKNOWN.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(EXTENDABLE_ARRAY, 
                UNKNOWN.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(nonPrimitive1, 
                UNKNOWN.intersection(nonPrimitive1, compiler));
  Expect.equals(nonPrimitive2, 
                UNKNOWN.intersection(nonPrimitive2, compiler));
  Expect.equals(potentialArray, 
                UNKNOWN.intersection(potentialArray, compiler));
  Expect.equals(potentialString, 
                UNKNOWN.intersection(potentialString, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                UNKNOWN.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                UNKNOWN.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                UNKNOWN.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                UNKNOWN.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                UNKNOWN.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                UNKNOWN.intersection(NULL, compiler));
  Expect.equals(FIXED_ARRAY, 
                UNKNOWN.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(CONFLICTING, compiler));
  Expect.equals(BOOLEAN, 
                BOOLEAN.intersection(UNKNOWN, compiler));
  Expect.equals(BOOLEAN, 
                BOOLEAN.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(nonPrimitive2, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(potentialString, compiler));
  Expect.equals(BOOLEAN, 
                BOOLEAN.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                NUMBER.intersection(CONFLICTING, compiler));
  Expect.equals(NUMBER, 
                NUMBER.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(BOOLEAN, compiler));
  Expect.equals(NUMBER, 
                NUMBER.intersection(NUMBER, compiler));
  Expect.equals(INTEGER, 
                NUMBER.intersection(INTEGER, compiler));
  Expect.equals(DOUBLE, 
                NUMBER.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(nonPrimitive2, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER, 
                NUMBER.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER, 
                NUMBER.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE, 
                NUMBER.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                INTEGER.intersection(CONFLICTING, compiler));
  Expect.equals(INTEGER, 
                INTEGER.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(BOOLEAN, compiler));
  Expect.equals(INTEGER, 
                INTEGER.intersection(NUMBER, compiler));
  Expect.equals(INTEGER, 
                INTEGER.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(nonPrimitive2, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(INTEGER, 
                INTEGER.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER, 
                INTEGER.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(CONFLICTING, compiler));
  Expect.equals(DOUBLE, 
                DOUBLE.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(BOOLEAN, compiler));
  Expect.equals(DOUBLE, 
                DOUBLE.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(INTEGER, compiler));
  Expect.equals(DOUBLE, 
                DOUBLE.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(nonPrimitive2, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(DOUBLE, 
                DOUBLE.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE, 
                DOUBLE.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE.intersection(FIXED_ARRAY, compiler));
  
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(CONFLICTING, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE, 
                INDEXABLE_PRIMITIVE.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(DOUBLE, compiler));
  Expect.equals(INDEXABLE_PRIMITIVE,
                INDEXABLE_PRIMITIVE.intersection(INDEXABLE_PRIMITIVE, 
                compiler));
  Expect.equals(STRING, 
                INDEXABLE_PRIMITIVE.intersection(STRING, compiler));
  Expect.equals(READABLE_ARRAY,
                INDEXABLE_PRIMITIVE.intersection(READABLE_ARRAY, 
                compiler));
  Expect.equals(MUTABLE_ARRAY,
                INDEXABLE_PRIMITIVE.intersection(MUTABLE_ARRAY, 
                compiler));
  Expect.equals(EXTENDABLE_ARRAY,
                INDEXABLE_PRIMITIVE.intersection(EXTENDABLE_ARRAY, 
                compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(nonPrimitive2, compiler));
  Expect.equals(READABLE_ARRAY,
                INDEXABLE_PRIMITIVE.intersection(potentialArray, 
                compiler));
  Expect.equals(STRING,
                INDEXABLE_PRIMITIVE.intersection(potentialString, 
                compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                INDEXABLE_PRIMITIVE.intersection(NULL, compiler));
  Expect.equals(FIXED_ARRAY, 
                INDEXABLE_PRIMITIVE.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                STRING.intersection(CONFLICTING, compiler));
  Expect.equals(STRING, 
                STRING.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(DOUBLE, compiler));
  Expect.equals(STRING, 
                STRING.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(STRING, 
                STRING.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(nonPrimitive2, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(potentialArray, compiler));
  Expect.equals(STRING, 
                STRING.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(STRING, 
                STRING.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                STRING.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(CONFLICTING, compiler));
  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(DOUBLE, compiler));
  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(STRING, compiler));
  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.intersection(READABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                READABLE_ARRAY.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(EXTENDABLE_ARRAY, 
                READABLE_ARRAY.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(nonPrimitive2, compiler));
  Expect.equals(READABLE_ARRAY, 
                READABLE_ARRAY.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                READABLE_ARRAY.intersection(NULL, compiler));
  Expect.equals(FIXED_ARRAY, 
                READABLE_ARRAY.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(CONFLICTING, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(DOUBLE, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(STRING, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.intersection(READABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(EXTENDABLE_ARRAY, 
                MUTABLE_ARRAY.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(nonPrimitive2, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                MUTABLE_ARRAY.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                MUTABLE_ARRAY.intersection(NULL, compiler));
  Expect.equals(FIXED_ARRAY, 
                MUTABLE_ARRAY.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(CONFLICTING, compiler));
  Expect.equals(EXTENDABLE_ARRAY, 
                EXTENDABLE_ARRAY.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(DOUBLE, compiler));
  Expect.equals(EXTENDABLE_ARRAY,
                EXTENDABLE_ARRAY.intersection(INDEXABLE_PRIMITIVE, 
                compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(STRING, compiler));
  Expect.equals(EXTENDABLE_ARRAY,
                EXTENDABLE_ARRAY.intersection(READABLE_ARRAY, 
                compiler));
  Expect.equals(EXTENDABLE_ARRAY, 
                EXTENDABLE_ARRAY.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(EXTENDABLE_ARRAY,
                EXTENDABLE_ARRAY.intersection(EXTENDABLE_ARRAY, 
                compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(nonPrimitive2, compiler));
  Expect.equals(EXTENDABLE_ARRAY,
                EXTENDABLE_ARRAY.intersection(potentialArray, 
                compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                EXTENDABLE_ARRAY.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(CONFLICTING, compiler));
  Expect.equals(nonPrimitive1, 
                nonPrimitive1.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(nonPrimitive1, 
                nonPrimitive1.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(nonPrimitive2, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive1.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(CONFLICTING, compiler));
  Expect.equals(nonPrimitive2, 
                nonPrimitive2.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(nonPrimitive1, compiler));
  Expect.equals(nonPrimitive2, 
                nonPrimitive2.intersection(nonPrimitive2, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                nonPrimitive2.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                potentialArray.intersection(CONFLICTING, compiler));
  Expect.equals(potentialArray, 
                potentialArray.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                potentialArray.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                potentialArray.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                potentialArray.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                potentialArray.intersection(DOUBLE, compiler));
  Expect.equals(READABLE_ARRAY, 
                potentialArray.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                potentialArray.intersection(STRING, compiler));
  Expect.equals(READABLE_ARRAY, 
                potentialArray.intersection(READABLE_ARRAY, compiler));
  Expect.equals(MUTABLE_ARRAY, 
                potentialArray.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(EXTENDABLE_ARRAY, 
                potentialArray.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                potentialArray.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                potentialArray.intersection(nonPrimitive2, compiler));
  Expect.equals(potentialArray, 
                potentialArray.intersection(potentialArray, compiler));
  Expect.equals(NULL, 
                potentialArray.intersection(potentialString, compiler));
  Expect.equals(NULL, 
                potentialArray.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialArray.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialArray.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialArray.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialArray.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialArray.intersection(NULL, compiler));
  Expect.equals(FIXED_ARRAY, 
                potentialArray.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                potentialString.intersection(CONFLICTING, compiler));
  Expect.equals(potentialString, 
                potentialString.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(DOUBLE, compiler));
  Expect.equals(STRING, 
                potentialString.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(STRING, 
                potentialString.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(nonPrimitive2, compiler));
  Expect.equals(NULL, 
                potentialString.intersection(potentialArray, compiler));
  Expect.equals(potentialString, 
                potentialString.intersection(potentialString, compiler));
  Expect.equals(NULL, 
                potentialString.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialString.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialString.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialString.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                potentialString.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                potentialString.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                potentialString.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(CONFLICTING, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                BOOLEAN_OR_NULL.intersection(UNKNOWN, compiler));
  Expect.equals(BOOLEAN, 
                BOOLEAN_OR_NULL.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(nonPrimitive2, compiler));
  Expect.equals(NULL, 
                BOOLEAN_OR_NULL.intersection(potentialArray, compiler));
  Expect.equals(NULL, 
                BOOLEAN_OR_NULL.intersection(potentialString, compiler));
  Expect.equals(BOOLEAN_OR_NULL, 
                BOOLEAN_OR_NULL.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NULL, 
                BOOLEAN_OR_NULL.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(NULL, 
                BOOLEAN_OR_NULL.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(NULL, 
                BOOLEAN_OR_NULL.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(NULL, 
                BOOLEAN_OR_NULL.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                BOOLEAN_OR_NULL.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                BOOLEAN_OR_NULL.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(CONFLICTING, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(BOOLEAN, compiler));
  Expect.equals(NUMBER, 
                NUMBER_OR_NULL.intersection(NUMBER, compiler));
  Expect.equals(INTEGER, 
                NUMBER_OR_NULL.intersection(INTEGER, compiler));
  Expect.equals(DOUBLE, 
                NUMBER_OR_NULL.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(nonPrimitive2, compiler));
  Expect.equals(NULL, 
                NUMBER_OR_NULL.intersection(potentialArray, compiler));
  Expect.equals(NULL, 
                NUMBER_OR_NULL.intersection(potentialString, compiler));
  Expect.equals(NULL, 
                NUMBER_OR_NULL.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NUMBER_OR_NULL, 
                NUMBER_OR_NULL.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                NUMBER_OR_NULL.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                NUMBER_OR_NULL.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(NULL, 
                NUMBER_OR_NULL.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                NUMBER_OR_NULL.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                NUMBER_OR_NULL.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(CONFLICTING, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                INTEGER_OR_NULL.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(BOOLEAN, compiler));
  Expect.equals(INTEGER, 
                INTEGER_OR_NULL.intersection(NUMBER, compiler));
  Expect.equals(INTEGER, 
                INTEGER_OR_NULL.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(nonPrimitive2, compiler));
  Expect.equals(NULL, 
                INTEGER_OR_NULL.intersection(potentialArray, compiler));
  Expect.equals(NULL, 
                INTEGER_OR_NULL.intersection(potentialString, compiler));
  Expect.equals(NULL, 
                INTEGER_OR_NULL.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                INTEGER_OR_NULL.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(INTEGER_OR_NULL, 
                INTEGER_OR_NULL.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(NULL, 
                INTEGER_OR_NULL.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(NULL, 
                INTEGER_OR_NULL.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                INTEGER_OR_NULL.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                INTEGER_OR_NULL.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(CONFLICTING, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE_OR_NULL.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(BOOLEAN, compiler));
  Expect.equals(DOUBLE, 
                DOUBLE_OR_NULL.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(INTEGER, compiler));
  Expect.equals(DOUBLE, 
                DOUBLE_OR_NULL.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(nonPrimitive2, compiler));
  Expect.equals(NULL, 
                DOUBLE_OR_NULL.intersection(potentialArray, compiler));
  Expect.equals(NULL, 
                DOUBLE_OR_NULL.intersection(potentialString, compiler));
  Expect.equals(NULL, 
                DOUBLE_OR_NULL.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE_OR_NULL.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(NULL, 
                DOUBLE_OR_NULL.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(DOUBLE_OR_NULL, 
                DOUBLE_OR_NULL.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(NULL, 
                DOUBLE_OR_NULL.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                DOUBLE_OR_NULL.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                DOUBLE_OR_NULL.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(CONFLICTING, compiler));
  Expect.equals(STRING_OR_NULL, 
                STRING_OR_NULL.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(DOUBLE, compiler));
  Expect.equals(STRING, 
                STRING_OR_NULL.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(STRING, 
                STRING_OR_NULL.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(nonPrimitive2, compiler));
  Expect.equals(NULL, 
                STRING_OR_NULL.intersection(potentialArray, compiler));
  Expect.equals(STRING_OR_NULL, 
                STRING_OR_NULL.intersection(potentialString, compiler));
  Expect.equals(NULL, 
                STRING_OR_NULL.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NULL, 
                STRING_OR_NULL.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(NULL, 
                STRING_OR_NULL.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(NULL, 
                STRING_OR_NULL.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(STRING_OR_NULL, 
                STRING_OR_NULL.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                STRING_OR_NULL.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                STRING_OR_NULL.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                NULL.intersection(CONFLICTING, compiler));
  Expect.equals(NULL, 
                NULL.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(DOUBLE, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(STRING, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(READABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(nonPrimitive2, compiler));
  Expect.equals(NULL, 
                NULL.intersection(potentialArray, compiler));
  Expect.equals(NULL, 
                NULL.intersection(potentialString, compiler));
  Expect.equals(NULL, 
                NULL.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(NULL, 
                NULL.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(NULL, 
                NULL.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(NULL, 
                NULL.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(NULL, 
                NULL.intersection(STRING_OR_NULL, compiler));
  Expect.equals(NULL, 
                NULL.intersection(NULL, compiler));
  Expect.equals(CONFLICTING, 
                NULL.intersection(FIXED_ARRAY, compiler));

  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(CONFLICTING, compiler));
  Expect.equals(FIXED_ARRAY, 
                FIXED_ARRAY.intersection(UNKNOWN, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(BOOLEAN, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(NUMBER, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(INTEGER, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(DOUBLE, compiler));
  Expect.equals(FIXED_ARRAY, 
                FIXED_ARRAY.intersection(INDEXABLE_PRIMITIVE, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(STRING, compiler));
  Expect.equals(FIXED_ARRAY, 
                FIXED_ARRAY.intersection(READABLE_ARRAY, compiler));
  Expect.equals(FIXED_ARRAY, 
                FIXED_ARRAY.intersection(MUTABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(EXTENDABLE_ARRAY, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(nonPrimitive1, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(nonPrimitive2, compiler));
  Expect.equals(FIXED_ARRAY, 
                FIXED_ARRAY.intersection(potentialArray, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(potentialString, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(BOOLEAN_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(NUMBER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(INTEGER_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(DOUBLE_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(STRING_OR_NULL, compiler));
  Expect.equals(CONFLICTING, 
                FIXED_ARRAY.intersection(NULL, compiler));
  Expect.equals(FIXED_ARRAY, 
                FIXED_ARRAY.intersection(FIXED_ARRAY, compiler));
}

void main() {
  MockCompiler compiler = new MockCompiler();
  nonPrimitive1 = new HBoundedType.nonNull(
      compiler.mapClass.computeType(compiler));
  nonPrimitive2 = new HBoundedType.nonNull(
      compiler.functionClass.computeType(compiler));
  potentialArray = new HBoundedPotentialPrimitiveArray(
      compiler.listClass.computeType(compiler), true);
  potentialString = new HBoundedPotentialPrimitiveString(
      compiler.stringClass.computeType(compiler), true);
  testUnion(compiler);
  testIntersection(compiler);
}
