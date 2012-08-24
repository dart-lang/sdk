// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#ifndef VM_INTRINSIFIER_H_
#define VM_INTRINSIFIER_H_

#include "vm/allocation.h"

namespace dart {

// List of intrinsics: (class-name, function-name, intrinsification method).
#define INTRINSIC_LIST(V)                                                      \
  V(IntegerImplementation, addFromInteger, Integer_addFromInteger)             \
  V(IntegerImplementation, +, Integer_add)                                     \
  V(IntegerImplementation, subFromInteger, Integer_subFromInteger)             \
  V(IntegerImplementation, -, Integer_sub)                                     \
  V(IntegerImplementation, mulFromInteger, Integer_mulFromInteger)             \
  V(IntegerImplementation, *, Integer_mul)                                     \
  V(IntegerImplementation, %, Integer_modulo)                                  \
  V(IntegerImplementation, ~/, Integer_truncDivide)                            \
  V(IntegerImplementation, negate, Integer_negate)                             \
  V(IntegerImplementation, bitAndFromInteger, Integer_bitAndFromInteger)       \
  V(IntegerImplementation, &, Integer_bitAnd)                                  \
  V(IntegerImplementation, bitOrFromInteger, Integer_bitOrFromInteger)         \
  V(IntegerImplementation, |, Integer_bitOr)                                   \
  V(IntegerImplementation, bitXorFromInteger, Integer_bitXorFromInteger)       \
  V(IntegerImplementation, ^, Integer_bitXor)                                  \
  V(IntegerImplementation, greaterThanFromInteger, Integer_greaterThanFromInt) \
  V(IntegerImplementation, >, Integer_greaterThan)                             \
  V(IntegerImplementation, ==, Integer_equal)                                  \
  V(IntegerImplementation, equalToInteger, Integer_equalToInteger)             \
  V(IntegerImplementation, <, Integer_lessThan)                                \
  V(IntegerImplementation, <=, Integer_lessEqualThan)                          \
  V(IntegerImplementation, >=, Integer_greaterEqualThan)                       \
  V(IntegerImplementation, <<, Integer_shl)                                    \
  V(IntegerImplementation, >>, Integer_sar)                                    \
  V(Smi, ~, Smi_bitNegate)                                                     \
  V(Double, >, Double_greaterThan)                                             \
  V(Double, >=, Double_greaterEqualThan)                                       \
  V(Double, <, Double_lessThan)                                                \
  V(Double, <=, Double_lessEqualThan)                                          \
  V(Double, ==, Double_equal)                                                  \
  V(Double, +, Double_add)                                                     \
  V(Double, -, Double_sub)                                                     \
  V(Double, *, Double_mul)                                                     \
  V(Double, /, Double_div)                                                     \
  V(Double, toDouble, Double_toDouble)                                         \
  V(Double, mulFromInteger, Double_mulFromInteger)                             \
  V(Double, Double.fromInteger, Double_fromInteger)                            \
  V(Double, isNaN, Double_isNaN)                                               \
  V(Double, isNegative, Double_isNegative)                                     \
  V(ObjectArray, ObjectArray., ObjectArray_Allocate)                           \
  V(ObjectArray, get:length, Array_getLength)                                  \
  V(ObjectArray, [], Array_getIndexed)                                         \
  V(ObjectArray, []=, Array_setIndexed)                                        \
  V(GrowableObjectArray, GrowableObjectArray.fromObjectArray, GArray_Allocate) \
  V(GrowableObjectArray, get:length, GrowableArray_getLength)                  \
  V(GrowableObjectArray, get:capacity, GrowableArray_getCapacity)              \
  V(GrowableObjectArray, [], GrowableArray_getIndexed)                         \
  V(GrowableObjectArray, []=, GrowableArray_setIndexed)                        \
  V(GrowableObjectArray, _setLength, GrowableArray_setLength)                  \
  V(GrowableObjectArray, set:data, GrowableArray_setData)                      \
  V(GrowableObjectArray, add, GrowableArray_add)                               \
  V(ImmutableArray, [], ImmutableArray_getIndexed)                             \
  V(ImmutableArray, get:length, ImmutableArray_getLength)                      \
  V(::, sqrt, Math_sqrt)                                                       \
  V(::, sin, Math_sin)                                                         \
  V(::, cos, Math_cos)                                                         \
  V(Object, ==, Object_equal)                                                  \
  V(FixedSizeArrayIterator, next, FixedSizeArrayIterator_next)                 \
  V(FixedSizeArrayIterator, hasNext, FixedSizeArrayIterator_hasNext)           \
  V(StringBase, get:length, String_getLength)                                  \
  V(StringBase, charCodeAt, String_charCodeAt)                                 \
  V(StringBase, hashCode, String_hashCode)                                     \
  V(StringBase, isEmpty, String_isEmpty)                                       \
  V(_ByteArrayBase, get:length, ByteArrayBase_getLength)                       \
  V(_Int8Array, [], Int8Array_getIndexed)                                      \
  V(_Uint8Array, [], Uint8Array_getIndexed)                                    \
  V(_Int16Array, [], Int16Array_getIndexed)                                    \
  V(_Uint16Array, [], Uint16Array_getIndexed)                                  \
  V(_Int32Array, [], Int32Array_getIndexed)                                    \
  V(_Uint32Array, [], Uint32Array_getIndexed)                                  \

// Forward declarations.
class Assembler;
class Function;

class Intrinsifier : public AllStatic {
 public:
  // Try to intrinsify 'function'. Returns true if the function intrinsified
  // completely and the code does not need to be generated (i.e., no slow
  // path possible).
  static bool Intrinsify(const Function& function, Assembler* assembler);

 private:
#define DECLARE_FUNCTION(test_class_name, test_function_name, destination)    \
  static bool destination(Assembler* assembler);

INTRINSIC_LIST(DECLARE_FUNCTION)
#undef DECLARE_FUNCTION
};

}  // namespace dart

#endif  // VM_INTRINSIFIER_H_
