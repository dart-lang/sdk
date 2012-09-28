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
  V(_IntegerImplementation, addFromInteger, Integer_addFromInteger)            \
  V(_IntegerImplementation, +, Integer_add)                                    \
  V(_IntegerImplementation, subFromInteger, Integer_subFromInteger)            \
  V(_IntegerImplementation, -, Integer_sub)                                    \
  V(_IntegerImplementation, mulFromInteger, Integer_mulFromInteger)            \
  V(_IntegerImplementation, *, Integer_mul)                                    \
  V(_IntegerImplementation, %, Integer_modulo)                                 \
  V(_IntegerImplementation, ~/, Integer_truncDivide)                           \
  V(_IntegerImplementation, negate, Integer_negate)                            \
  V(_IntegerImplementation, bitAndFromInteger, Integer_bitAndFromInteger)      \
  V(_IntegerImplementation, &, Integer_bitAnd)                                 \
  V(_IntegerImplementation, bitOrFromInteger, Integer_bitOrFromInteger)        \
  V(_IntegerImplementation, |, Integer_bitOr)                                  \
  V(_IntegerImplementation, bitXorFromInteger, Integer_bitXorFromInteger)      \
  V(_IntegerImplementation, ^, Integer_bitXor)                                 \
  V(_IntegerImplementation, greaterThanFromInteger, Integer_greaterThanFromInt)\
  V(_IntegerImplementation, >, Integer_greaterThan)                            \
  V(_IntegerImplementation, ==, Integer_equal)                                 \
  V(_IntegerImplementation, equalToInteger, Integer_equalToInteger)            \
  V(_IntegerImplementation, <, Integer_lessThan)                               \
  V(_IntegerImplementation, <=, Integer_lessEqualThan)                         \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan)                      \
  V(_IntegerImplementation, <<, Integer_shl)                                   \
  V(_IntegerImplementation, >>, Integer_sar)                                   \
  V(_Smi, ~, Smi_bitNegate)                                                    \
  V(_Double, >, Double_greaterThan)                                            \
  V(_Double, >=, Double_greaterEqualThan)                                      \
  V(_Double, <, Double_lessThan)                                               \
  V(_Double, <=, Double_lessEqualThan)                                         \
  V(_Double, ==, Double_equal)                                                 \
  V(_Double, +, Double_add)                                                    \
  V(_Double, -, Double_sub)                                                    \
  V(_Double, *, Double_mul)                                                    \
  V(_Double, /, Double_div)                                                    \
  V(_Double, toDouble, Double_toDouble)                                        \
  V(_Double, mulFromInteger, Double_mulFromInteger)                            \
  V(_Double, .fromInteger, Double_fromInteger)                                 \
  V(_Double, isNaN, Double_isNaN)                                              \
  V(_Double, isNegative, Double_isNegative)                                    \
  V(_Double, toInt, Double_toInt)                                              \
  V(_ObjectArray, ., ObjectArray_Allocate)                                     \
  V(_ObjectArray, get:length, Array_getLength)                                 \
  V(_ObjectArray, [], Array_getIndexed)                                        \
  V(_ObjectArray, []=, Array_setIndexed)                                       \
  V(_GrowableObjectArray,                                                      \
    .fromObjectArray,                                                          \
    GArray_Allocate)                                                           \
  V(_GrowableObjectArray, get:length, GrowableArray_getLength)                 \
  V(_GrowableObjectArray, get:capacity, GrowableArray_getCapacity)             \
  V(_GrowableObjectArray, [], GrowableArray_getIndexed)                        \
  V(_GrowableObjectArray, []=, GrowableArray_setIndexed)                       \
  V(_GrowableObjectArray, _setLength, GrowableArray_setLength)                 \
  V(_GrowableObjectArray, _setData, GrowableArray_setData)                     \
  V(_GrowableObjectArray, add, GrowableArray_add)                              \
  V(_ImmutableArray, [], ImmutableArray_getIndexed)                            \
  V(_ImmutableArray, get:length, ImmutableArray_getLength)                     \
  V(::, sqrt, Math_sqrt)                                                       \
  V(::, sin, Math_sin)                                                         \
  V(::, cos, Math_cos)                                                         \
  V(Object, ==, Object_equal)                                                  \
  V(_FixedSizeArrayIterator, next, FixedSizeArrayIterator_next)                \
  V(_FixedSizeArrayIterator, hasNext, FixedSizeArrayIterator_hasNext)          \
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
  static bool CanIntrinsify(const Function& function);

 private:
#define DECLARE_FUNCTION(test_class_name, test_function_name, destination)    \
  static bool destination(Assembler* assembler);

INTRINSIC_LIST(DECLARE_FUNCTION)
#undef DECLARE_FUNCTION
};

}  // namespace dart

#endif  // VM_INTRINSIFIER_H_
