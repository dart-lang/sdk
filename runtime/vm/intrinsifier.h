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
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger)           \
  V(_IntegerImplementation, +, Integer_add)                                    \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger)           \
  V(_IntegerImplementation, -, Integer_sub)                                    \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger)           \
  V(_IntegerImplementation, *, Integer_mul)                                    \
  V(_IntegerImplementation, %, Integer_modulo)                                 \
  V(_IntegerImplementation, ~/, Integer_truncDivide)                           \
  V(_IntegerImplementation, unary-, Integer_negate)                            \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger)     \
  V(_IntegerImplementation, &, Integer_bitAnd)                                 \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger)       \
  V(_IntegerImplementation, |, Integer_bitOr)                                  \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger)     \
  V(_IntegerImplementation, ^, Integer_bitXor)                                 \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt)                                                \
  V(_IntegerImplementation, >, Integer_greaterThan)                            \
  V(_IntegerImplementation, ==, Integer_equal)                                 \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger)           \
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
  V(_Double, get:isNaN, Double_getIsNaN)                                       \
  V(_Double, get:isNegative, Double_getIsNegative)                             \
  V(_Double, _mulFromInteger, Double_mulFromInteger)                           \
  V(_Double, .fromInteger, Double_fromInteger)                                 \
  V(_Double, toInt, Double_toInt)                                              \
  V(_ObjectArray, ., ObjectArray_Allocate)                                     \
  V(_ObjectArray, get:length, Array_getLength)                                 \
  V(_ObjectArray, [], Array_getIndexed)                                        \
  V(_ObjectArray, []=, Array_setIndexed)                                       \
  V(_GrowableObjectArray, .fromObjectArray, GArray_Allocate)                   \
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
  V(_FixedSizeArrayIterator, get:hasNext, FixedSizeArrayIterator_getHasNext)   \
  V(_FixedSizeArrayIterator, next, FixedSizeArrayIterator_next)                \
  V(_StringBase, get:hashCode, String_getHashCode)                             \
  V(_StringBase, get:isEmpty, String_getIsEmpty)                               \
  V(_StringBase, get:length, String_getLength)                                 \
  V(_StringBase, charCodeAt, String_charCodeAt)                                \
  V(_ByteArrayBase, get:length, ByteArrayBase_getLength)                       \
  V(_Int8Array, [], Int8Array_getIndexed)                                      \
  V(_Int8Array, []=, Int8Array_setIndexed)                                     \
  V(_Uint8Array, [], Uint8Array_getIndexed)                                    \
  V(_Uint8Array, []=, Uint8Array_setIndexed)                                   \
  V(_Int16Array, [], Int16Array_getIndexed)                                    \
  V(_Uint16Array, [], Uint16Array_getIndexed)                                  \
  V(_Int32Array, [], Int32Array_getIndexed)                                    \
  V(_Uint32Array, [], Uint32Array_getIndexed)                                  \
  V(_Int64Array, [], Int64Array_getIndexed)                                    \
  V(_Uint64Array, [], Uint64Array_getIndexed)                                  \
  V(_Float32Array, [], Float32Array_getIndexed)                                \
  V(_Float32Array, []=, Float32Array_setIndexed)                               \
  V(_Float64Array, [], Float64Array_getIndexed)                                \
  V(_Float64Array, []=, Float64Array_setIndexed)                               \
  V(_ExternalUint8Array, [], ExternalUint8Array_getIndexed)                    \

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
