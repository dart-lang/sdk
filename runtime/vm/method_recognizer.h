// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_METHOD_RECOGNIZER_H_
#define RUNTIME_VM_METHOD_RECOGNIZER_H_

#include "vm/allocation.h"

namespace dart {

// clang-format off
// (class-name, function-name, recognized enum, result type, fingerprint).
// When adding a new function add a 0 as fingerprint, build and run to get the
// correct fingerprint from the mismatch error.
#define OTHER_RECOGNIZED_LIST(V)                                               \
  V(::, identical, ObjectIdentical, Bool, 0x49c6e96a)                          \
  V(ClassID, getID, ClassIDgetID, Smi, 0x528fd455)                             \
  V(Object, Object., ObjectConstructor, Dynamic, 0x681617fe)                   \
  V(_List, ., ObjectArrayAllocate, Array, 0x375519ad)                          \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, Smi, 0x7041895a)               \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, Smi, 0x336fa3ea)             \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, Smi, 0x231bbe2e)             \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, Smi, 0x0371785f)           \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, Dynamic, 0x65ab3a20)         \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, Dynamic, 0x0cb0fcf6)       \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, Dynamic, 0x7db75d78)         \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, Double, 0x6674ea6f)      \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, Double, 0x236c6e7a)      \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, Float32x4,           \
    0x5c367ffb)                                                                \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, Int32x4, 0x772d1c0f)     \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, Dynamic, 0x68f17de8)           \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, Dynamic, 0x6bb8b747)         \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, Dynamic, 0x75b8d278)         \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, Dynamic, 0x6e54f794)       \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, Dynamic, 0x54123a05)         \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, Dynamic, 0x4a3fea0b)       \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, Dynamic, 0x1d77d3ec)         \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, Dynamic, 0x5a11a2f9)     \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, Dynamic, 0x0edea58b)     \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, Dynamic, 0x163bc6cc) \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, Dynamic, 0x5def39d2)     \
  V(_StringBase, _interpolate, StringBaseInterpolate, Dynamic, 0x084d9f1a)     \
  V(_IntegerImplementation, toDouble, IntegerToDouble, Double, 0x0d8f57ab)     \
  V(_Double, _add, DoubleAdd, Double, 0x2a38277b)                              \
  V(_Double, _sub, DoubleSub, Double, 0x4f466391)                              \
  V(_Double, _mul, DoubleMul, Double, 0x175e4f66)                              \
  V(_Double, _div, DoubleDiv, Double, 0x0854181b)                              \
  V(::, min, MathMin, Dynamic, 0x0bee5d52)                                     \
  V(::, max, MathMax, Dynamic, 0x4f51acb6)                                     \
  V(::, _doublePow, MathDoublePow, Double, 0x01d7b09e)                         \
  V(Float32x4, Float32x4., Float32x4Constructor, Float32x4, 0x05968999)        \
  V(Float32x4, Float32x4.zero, Float32x4Zero, Float32x4, 0x472a4c46)           \
  V(Float32x4, Float32x4.splat, Float32x4Splat, Float32x4, 0x00bba1a5)         \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits, Float32x4, \
    0x46d00995)                                                                \
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, Float32x4,     \
    0x685a86d2)                                                                \
  V(_Float32x4, shuffle, Float32x4Shuffle, Float32x4, 0x7829101f)              \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, Float32x4, 0x4182c06b)        \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, Dynamic, 0x1d07ca93)       \
  V(_Float32x4, equal, Float32x4Equal, Int32x4, 0x11adb239)                    \
  V(_Float32x4, greaterThan, Float32x4GreaterThan, Int32x4, 0x48adaf58)        \
  V(_Float32x4, greaterThanOrEqual, Float32x4GreaterThanOrEqual, Int32x4,      \
    0x32db94ca)                                                                \
  V(_Float32x4, lessThan, Float32x4LessThan, Int32x4, 0x425b000c)              \
  V(_Float32x4, lessThanOrEqual, Float32x4LessThanOrEqual, Int32x4,            \
    0x0278c2f8)                                                                \
  V(_Float32x4, notEqual, Float32x4NotEqual, Int32x4, 0x2987cd26)              \
  V(_Float32x4, min, Float32x4Min, Float32x4, 0x5ed74b6f)                      \
  V(_Float32x4, max, Float32x4Max, Float32x4, 0x68696442)                      \
  V(_Float32x4, scale, Float32x4Scale, Float32x4, 0x704e4122)                  \
  V(_Float32x4, sqrt, Float32x4Sqrt, Float32x4, 0x2c967a6f)                    \
  V(_Float32x4, reciprocalSqrt, Float32x4ReciprocalSqrt, Float32x4,            \
    0x6264bfe8)                                                                \
  V(_Float32x4, reciprocal, Float32x4Reciprocal, Float32x4, 0x3cd7e819)        \
  V(_Float32x4, unary-, Float32x4Negate, Float32x4, 0x34431a14)                \
  V(_Float32x4, abs, Float32x4Absolute, Float32x4, 0x471cdd87)                 \
  V(_Float32x4, clamp, Float32x4Clamp, Float32x4, 0x2cb30492)                  \
  V(_Float32x4, withX, Float32x4WithX, Float32x4, 0x4e336aff)                  \
  V(_Float32x4, withY, Float32x4WithY, Float32x4, 0x0a72b910)                  \
  V(_Float32x4, withZ, Float32x4WithZ, Float32x4, 0x31e93658)                  \
  V(_Float32x4, withW, Float32x4WithW, Float32x4, 0x60ddc105)                  \
  V(Float64x2, Float64x2., Float64x2Constructor, Float64x2, 0x193be61d)        \
  V(Float64x2, Float64x2.zero, Float64x2Zero, Float64x2, 0x7b2ed5df)           \
  V(Float64x2, Float64x2.splat, Float64x2Splat, Float64x2, 0x2abbfcb2)         \
  V(Float64x2, Float64x2.fromFloat32x4, Float64x2FromFloat32x4, Float64x2,     \
    0x2f43d3a6)                                                                \
  V(_Float64x2, get:x, Float64x2GetX, Double, 0x58bfb39a)                      \
  V(_Float64x2, get:y, Float64x2GetY, Double, 0x3cf4fcfa)                      \
  V(_Float64x2, unary-, Float64x2Negate, Float64x2, 0x3df2eecb)                \
  V(_Float64x2, abs, Float64x2Abs, Float64x2, 0x031f9e47)                      \
  V(_Float64x2, sqrt, Float64x2Sqrt, Float64x2, 0x77f711dd)                    \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, Dynamic, 0x27ddf18d)       \
  V(_Float64x2, scale, Float64x2Scale, Float64x2, 0x26830a61)                  \
  V(_Float64x2, withX, Float64x2WithX, Float64x2, 0x1d2bcaf5)                  \
  V(_Float64x2, withY, Float64x2WithY, Float64x2, 0x383ed6ac)                  \
  V(_Float64x2, min, Float64x2Min, Float64x2, 0x28d7ddf6)                      \
  V(_Float64x2, max, Float64x2Max, Float64x2, 0x0bd74e5b)                      \
  V(Int32x4, Int32x4., Int32x4Constructor, Int32x4, 0x26b199a7)                \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, Int32x4, 0x1b55a5e1)        \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Int32x4FromFloat32x4Bits, Int32x4,     \
    0x7e82564c)                                                                \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, Bool, 0x563883c4)                    \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, Bool, 0x446f5e7a)                    \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, Bool, 0x20d61679)                    \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, Bool, 0x504478ac)                    \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, Dynamic, 0x2c1ec9e5)           \
  V(_Int32x4, shuffle, Int32x4Shuffle, Int32x4, 0x20bc0b16)                    \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, Int32x4, 0x5c7056e1)              \
  V(_Int32x4, select, Int32x4Select, Float32x4, 0x6b49654f)                    \
  V(_Int32x4, withFlagX, Int32x4WithFlagX, Int32x4, 0x0ef58fcf)                \
  V(_Int32x4, withFlagY, Int32x4WithFlagY, Int32x4, 0x6485a9c4)                \
  V(_Int32x4, withFlagZ, Int32x4WithFlagZ, Int32x4, 0x267acdfa)                \
  V(_Int32x4, withFlagW, Int32x4WithFlagW, Int32x4, 0x345ac675)                \
  V(_Int64List, [], Int64ArrayGetIndexed, Dynamic, 0x680ec59b)                 \
  V(_Int64List, []=, Int64ArraySetIndexed, Dynamic, 0x0872fc15)                \
  V(_Bigint, get:_neg, Bigint_getNeg, Bool, 0x355fa565)                        \
  V(_Bigint, get:_used, Bigint_getUsed, Smi, 0x33b9dcd2)                       \
  V(_Bigint, get:_digits, Bigint_getDigits, TypedDataUint32Array, 0x68de883a)  \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, Dynamic, 0x02468899)      \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, Dynamic, 0x577d9e20)      \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, Array, 0x2d7987ee)          \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, Dynamic, 0x1674fb28)        \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, Smi, 0x0884b12f)    \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, Dynamic, 0x66f792c6)\
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, Smi, 0x32f2c87d)    \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, Dynamic, 0x79ce8c9b)\
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, Smi,          \
    0x55839904)                                                                \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, Dynamic,      \
    0x625e50cd)                                                                \
  V(::, _classRangeCheck, ClassRangeCheck, Bool, 0x025e8d82)                   \
  V(::, _classRangeCheckNegative, ClassRangeCheckNegated, Bool, 0x32451d73)    \


// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, Smi, 0x63bfee11)                                   \
  V(_Smi, get:bitLength, Smi_bitLength, Smi, 0x25b2e24c)                       \
  V(_Smi, _bitAndFromSmi, Smi_bitAndFromSmi, Smi, 0x490a4da1)                  \
  V(_Bigint, _lsh, Bigint_lsh, Dynamic, 0x0619eb8a)                            \
  V(_Bigint, _rsh, Bigint_rsh, Dynamic, 0x0e1b80df)                            \
  V(_Bigint, _absAdd, Bigint_absAdd, Dynamic, 0x1a2b6326)                      \
  V(_Bigint, _absSub, Bigint_absSub, Dynamic, 0x3bebab4e)                      \
  V(_Bigint, _mulAdd, Bigint_mulAdd, Dynamic, 0x7d48a0b3)                      \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, Dynamic, 0x638b5f5d)                      \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, Dynamic, 0x467dee78)  \
  V(_Montgomery, _mulMod, Montgomery_mulMod, Dynamic, 0x36065c30)              \
  V(_Double, >, Double_greaterThan, Bool, 0x452cd763)                          \
  V(_Double, >=, Double_greaterEqualThan, Bool, 0x6c317340)                    \
  V(_Double, <, Double_lessThan, Bool, 0x26dda4bc)                             \
  V(_Double, <=, Double_lessEqualThan, Bool, 0x1e869d20)                       \
  V(_Double, ==, Double_equal, Bool, 0x5244dca3)                               \
  V(_Double, +, Double_add, Double, 0x49b2a530)                                \
  V(_Double, -, Double_sub, Double, 0x31833626)                                \
  V(_Double, *, Double_mul, Double, 0x21d31f1d)                                \
  V(_Double, /, Double_div, Double, 0x3e584fe8)                                \
  V(_Double, get:isNaN, Double_getIsNaN, Bool, 0x0af8ebeb)                     \
  V(_Double, get:isInfinite, Double_getIsInfinite, Bool, 0x0f79e289)           \
  V(_Double, get:isNegative, Double_getIsNegative, Bool, 0x3a58ff36)           \
  V(_Double, _mulFromInteger, Double_mulFromInteger, Double, 0x7f565534)       \
  V(_Double, .fromInteger, DoubleFromInteger, Double, 0x04906d0d)              \
  V(_List, []=, ObjectArraySetIndexed, Dynamic, 0x34d2c72c)                    \
  V(_GrowableList, .withData, GrowableArray_Allocate, GrowableObjectArray,     \
    0x401f3150)                                                                \
  V(_GrowableList, add, GrowableArray_add, Dynamic, 0x71f49ac8)                \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, Dynamic, 0x380184b1)          \
  V(_RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky, Dynamic,          \
    0x79b8f955)                                                                \
  V(Object, ==, ObjectEquals, Bool, 0x11662ed8)                                \
  V(Object, get:runtimeType, ObjectRuntimeType, Type, 0x00e7c26b)              \
  V(Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType, Bool, 0x6532255b) \
  V(_StringBase, get:hashCode, String_getHashCode, Smi, 0x78c2eb88)            \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, Bool, 0x74c21fca)             \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, Bool,          \
    0x025b2ece)                                                                \
  V(_StringBase, [], StringBaseCharAt, Dynamic, 0x2cf92c45)                    \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, Smi, 0x78c2eb88)  \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked, OneByteString, 0x3538ad86)               \
  V(_OneByteString, _setAt, OneByteStringSetAt, Dynamic, 0x6836784f)           \
  V(_OneByteString, _allocate, OneByteString_allocate, OneByteString,          \
    0x4c0a5574)                                                                \
  V(_OneByteString, ==, OneByteString_equality, Bool, 0x3f59b700)              \
  V(_TwoByteString, ==, TwoByteString_equality, Bool, 0x3f59b700)              \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    Dynamic, 0x6a10c54a)                                                       \
  V(_IntegerImplementation, +, Integer_add, Dynamic, 0x20192008)               \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, Dynamic,  \
    0x3fa4b1ed)                                                                \
  V(_IntegerImplementation, -, Integer_sub, Dynamic, 0x5b877969)               \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    Dynamic, 0x3216e299)                                                       \
  V(_IntegerImplementation, *, Integer_mul, Dynamic, 0x142887aa)               \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    Dynamic, 0x6348b974)                                                       \
  V(_IntegerImplementation, ~/, Integer_truncDivide, Dynamic, 0x5b740346)      \
  V(_IntegerImplementation, unary-, Integer_negate, Dynamic, 0x59dce57c)       \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    Dynamic, 0x395b1678)                                                       \
  V(_IntegerImplementation, &, Integer_bitAnd, Dynamic, 0x50aab6e4)            \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    Dynamic, 0x6a36b395)                                                       \
  V(_IntegerImplementation, |, Integer_bitOr, Dynamic, 0x40b9d4c2)             \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    Dynamic, 0x72da93f0)                                                       \
  V(_IntegerImplementation, ^, Integer_bitXor, Dynamic, 0x16edce03)            \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, Bool, 0x4a50ed58)                              \
  V(_IntegerImplementation, >, Integer_greaterThan, Bool, 0x6220711f)          \
  V(_IntegerImplementation, ==, Integer_equal, Bool, 0x0d4d7f2c)               \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, Bool,     \
    0x063be842)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, Bool, 0x26dda4bc)             \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, Bool, 0x1e869d20)       \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, Bool, 0x6c317340)    \
  V(_IntegerImplementation, <<, Integer_shl, Dynamic, 0x5f43ef06)              \
  V(_IntegerImplementation, >>, Integer_sar, Dynamic, 0x08a241c7)              \
  V(_Double, toInt, DoubleToInteger, Dynamic, 0x26ef344b)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, Double, 0x0a683033)                                    \
  V(_Random, _nextState, Random_nextState, Dynamic, 0x24d91397)                \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, Double, 0x595a044c)                                      \
  V(::, cos, MathCos, Double, 0x337a20be)                                      \
  V(::, tan, MathTan, Double, 0x29aba1ea)                                      \
  V(::, asin, MathAsin, Double, 0x48ec330d)                                    \
  V(::, acos, MathAcos, Double, 0x22ef2552)                                    \
  V(::, atan, MathAtan, Double, 0x38473515)                                    \
  V(::, atan2, MathAtan2, Double, 0x39f1fa41)                                  \

#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(Int8List, ., TypedData_Int8Array_factory, TypedDataInt8Array, 0x2e7749e3)  \
  V(Uint8List, ., TypedData_Uint8Array_factory, TypedDataUint8Array,           \
    0x6ab75439)                                                                \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory,                  \
    TypedDataUint8ClampedArray, 0x183129d7)                                    \
  V(Int16List, ., TypedData_Int16Array_factory, TypedDataInt16Array,           \
    0x14b563ea)                                                                \
  V(Uint16List, ., TypedData_Uint16Array_factory, TypedDataUint16Array,        \
    0x07456be4)                                                                \
  V(Int32List, ., TypedData_Int32Array_factory, TypedDataInt32Array,           \
    0x5bd49250)                                                                \
  V(Uint32List, ., TypedData_Uint32Array_factory,                              \
    TypedDataUint32Array, 0x3c59b3a4)                                          \
  V(Int64List, ., TypedData_Int64Array_factory,                                \
    TypedDataInt64Array, 0x57d85ac7)                                           \
  V(Uint64List, ., TypedData_Uint64Array_factory,                              \
    TypedDataUint64Array, 0x2c093004)                                          \
  V(Float32List, ., TypedData_Float32Array_factory,                            \
    TypedDataFloat32Array, 0x738e124b)                                         \
  V(Float64List, ., TypedData_Float64Array_factory,                            \
    TypedDataFloat64Array, 0x501be4f1)                                         \
  V(Float32x4List, ., TypedData_Float32x4Array_factory,                        \
    TypedDataFloat32x4Array, 0x7a7dd718)                                       \
  V(Int32x4List, ., TypedData_Int32x4Array_factory,                            \
    TypedDataInt32x4Array, 0x1e0dca48)                                         \
  V(Float64x2List, ., TypedData_Float64x2Array_factory,                        \
    TypedDataFloat64x2Array, 0x18cbf4d9)                                       \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(_Int8List, [], Int8ArrayGetIndexed, Smi, 0x5f9a4430)                       \
  V(_Int8List, []=, Int8ArraySetIndexed, Dynamic, 0x5f880110)                  \
  V(_Uint8List, [], Uint8ArrayGetIndexed, Smi, 0x1eb150d8)                     \
  V(_Uint8List, []=, Uint8ArraySetIndexed, Dynamic, 0x4cf76981)                \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, Smi, 0x1eb150d8)    \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, Dynamic,           \
    0x4cf76981)                                                                \
  V(_Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, Smi, 0x1eb150d8)       \
  V(_Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, Dynamic, 0x2224afe1)  \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    Smi, 0x1eb150d8)                                                           \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    Dynamic, 0x2224afe1)                                                       \
  V(_Int16List, [], Int16ArrayGetIndexed, Smi, 0x74ea134c)                     \
  V(_Int16List, []=, Int16ArraySetIndexed, Dynamic, 0x48e25661)                \
  V(_Uint16List, [], Uint16ArrayGetIndexed, Smi, 0x756d9a97)                   \
  V(_Uint16List, []=, Uint16ArraySetIndexed, Dynamic, 0x698f9d4f)              \
  V(_Int32List, [], Int32ArrayGetIndexed, Dynamic, 0x61e49de1)                 \
  V(_Int32List, []=, Int32ArraySetIndexed, Dynamic, 0x55736c63)                \
  V(_Uint32List, [], Uint32ArrayGetIndexed, Dynamic, 0x2eaa22d2)               \
  V(_Uint32List, []=, Uint32ArraySetIndexed, Dynamic, 0x3c88eeb9)              \
  V(_Float64List, [], Float64ArrayGetIndexed, Double, 0x20950e8a)              \
  V(_Float64List, []=, Float64ArraySetIndexed, Dynamic, 0x556a0727)            \
  V(_Float32List, [], Float32ArrayGetIndexed, Double, 0x7101fa23)              \
  V(_Float32List, []=, Float32ArraySetIndexed, Dynamic, 0x5e32c1eb)            \
  V(_Float32x4List, [], Float32x4ArrayGetIndexed, Float32x4, 0x28b0a7ef)       \
  V(_Float32x4List, []=, Float32x4ArraySetIndexed, Dynamic, 0x4babf032)        \
  V(_Int32x4List, [], Int32x4ArrayGetIndexed, Int32x4, 0x619c79a0)             \
  V(_Int32x4List, []=, Int32x4ArraySetIndexed, Dynamic, 0x021bd16b)            \
  V(_Float64x2List, [], Float64x2ArrayGetIndexed, Float64x2, 0x7a6dd5e5)       \
  V(_Float64x2List, []=, Float64x2ArraySetIndexed, Dynamic, 0x3c59fecb)        \
  V(_TypedList, get:length, TypedDataLength, Smi, 0x2090dc1a)                  \
  V(_Float32x4, get:x, Float32x4ShuffleX, Double, 0x63d0c13f)                  \
  V(_Float32x4, get:y, Float32x4ShuffleY, Double, 0x20343b1b)                  \
  V(_Float32x4, get:z, Float32x4ShuffleZ, Double, 0x13181dba)                  \
  V(_Float32x4, get:w, Float32x4ShuffleW, Double, 0x69895020)                  \
  V(_Float32x4, *, Float32x4Mul, Float32x4, 0x0e2a0ef4)                        \
  V(_Float32x4, -, Float32x4Sub, Float32x4, 0x6edeeaa3)                        \
  V(_Float32x4, +, Float32x4Add, Float32x4, 0x303a9943)                        \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, Smi, 0x25943ad2)                     \
  V(_List, [], ObjectArrayGetIndexed, Dynamic, 0x157b4670)                     \
  V(_ImmutableList, get:length, ImmutableArrayLength, Smi, 0x25943ad2)         \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, Dynamic, 0x157b4670)         \
  V(_GrowableList, get:length, GrowableArrayLength, Smi, 0x18dc9df6)           \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, Smi, 0x2e03d5a2)      \
  V(_GrowableList, _setData, GrowableArraySetData, Dynamic, 0x6dfc498a)        \
  V(_GrowableList, _setLength, GrowableArraySetLength, Dynamic, 0x257bfc1c)    \
  V(_GrowableList, [], GrowableArrayGetIndexed, Dynamic, 0x74ad8832)           \
  V(_GrowableList, []=, GrowableArraySetIndexed, Dynamic, 0x0d6cfe96)          \
  V(_StringBase, get:length, StringBaseLength, Smi, 0x2a2c1b13)                \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, Smi, 0x55a0a1f3)      \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, Smi, 0x55a0a1f3)      \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    Smi, 0x55a0a1f3)                                                           \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    Smi, 0x55a0a1f3)                                                           \
  V(_Double, unary-, DoubleFlipSignBit, Double, 0x6a4ab611)                    \
  V(_Double, truncateToDouble, DoubleTruncate, Double, 0x2f27e5d3)             \
  V(_Double, roundToDouble, DoubleRound, Double, 0x2f89c512)                   \
  V(_Double, floorToDouble, DoubleFloor, Double, 0x6aa87a5f)                   \
  V(_Double, ceilToDouble, DoubleCeil, Double, 0x1b045e9e)                     \
  V(_Double, _modulo, DoubleMod, Double, 0x5b8ceed7)


#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, Dynamic, 0x0b3066fd)           \
  V(::, _getDefaultTag, UserTag_defaultTag, Dynamic, 0x69f3f1ad)               \
  V(::, _getCurrentTag, Profiler_getCurrentTag, Dynamic, 0x05fa99d2)           \
  V(::, _isDartStreamEnabled, Timeline_isDartStreamEnabled, Dynamic,           \
    0x72f13f7a)                                                                \

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
  CORE_LIB_INTRINSIC_LIST(V)                                                   \
  DEVELOPER_LIB_INTRINSIC_LIST(V)                                              \
  MATH_LIB_INTRINSIC_LIST(V)                                                   \
  TYPED_DATA_LIB_INTRINSIC_LIST(V)                                             \

#define ALL_INTRINSICS_LIST(V)                                                 \
  ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                        \
  CORE_INTEGER_LIB_INTRINSIC_LIST(V)

#define RECOGNIZED_LIST(V)                                                     \
  OTHER_RECOGNIZED_LIST(V)                                                     \
  ALL_INTRINSICS_LIST(V)                                                       \
  GRAPH_INTRINSICS_LIST(V)

// A list of core function that should always be inlined.
#define INLINE_WHITE_LIST(V)                                                   \
  V(Object, ==, ObjectEquals, 0x11662ed8)                                      \
  V(_List, get:length, ObjectArrayLength, 0x25943ad2)                          \
  V(_ImmutableList, get:length, ImmutableArrayLength, 0x25943ad2)              \
  V(_TypedList, get:length, TypedDataLength, 0x2090dc1a)                       \
  V(_GrowableList, get:length, GrowableArrayLength, 0x18dc9df6)                \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 0x2e03d5a2)           \
  V(_GrowableList, add, GrowableListAdd, 0x71f49ac8)                           \
  V(_GrowableList, removeLast, GrowableListRemoveLast, 0x7add0363)             \
  V(_StringBase, get:length, StringBaseLength, 0x2a2c1b13)                     \
  V(ListIterator, moveNext, ListIteratorMoveNext, 0x4f8ff9cc)                  \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 0x50e0604b)  \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 0x6db11a73)            \
  V(_GrowableList, forEach, GrowableArrayForEach, 0x250036fe)                  \
  V(_List, ., ObjectArrayAllocate, 0x375519ad)                                 \
  V(ListMixin, get:isEmpty, ListMixinIsEmpty, 0x787d9bc6)                      \
  V(_List, get:iterator, ObjectArrayIterator, 0x7e634791)                      \
  V(_List, forEach, ObjectArrayForEach, 0x0abce191)                            \
  V(_List, _slice, ObjectArraySlice, 0x01b71c13)                               \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 0x7e634791)          \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 0x0abce191)                \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 0x760ba8c2)                 \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 0x44fc1997)                \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 0x7735aad3)                   \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 0x4237db0d)                  \
  V(_ByteDataView, setInt8, ByteDataViewSetInt8, 0x66702980)                   \
  V(_ByteDataView, setUint8, ByteDataViewSetUint8, 0x7c729d61)                 \
  V(_ByteDataView, setInt16, ByteDataViewSetInt16, 0x203478e8)                 \
  V(_ByteDataView, setUint16, ByteDataViewSetUint16, 0x16c35617)               \
  V(_ByteDataView, setInt32, ByteDataViewSetInt32, 0x200c1aae)                 \
  V(_ByteDataView, setUint32, ByteDataViewSetUint32, 0x281c378e)               \
  V(_ByteDataView, setInt64, ByteDataViewSetInt64, 0x10595a04)                 \
  V(_ByteDataView, setUint64, ByteDataViewSetUint64, 0x364fcc46)               \
  V(_ByteDataView, setFloat32, ByteDataViewSetFloat32, 0x30628609)             \
  V(_ByteDataView, setFloat64, ByteDataViewSetFloat64, 0x331b1f4b)             \
  V(_ByteDataView, getInt8, ByteDataViewGetInt8, 0x62761d8f)                   \
  V(_ByteDataView, getUint8, ByteDataViewGetUint8, 0x579a5e34)                 \
  V(_ByteDataView, getInt16, ByteDataViewGetInt16, 0x73e0175b)                 \
  V(_ByteDataView, getUint16, ByteDataViewGetUint16, 0x3691576a)               \
  V(_ByteDataView, getInt32, ByteDataViewGetInt32, 0x44d407a8)                 \
  V(_ByteDataView, getUint32, ByteDataViewGetUint32, 0x160c7450)               \
  V(_ByteDataView, getInt64, ByteDataViewGetInt64, 0x02a2ffca)                 \
  V(_ByteDataView, getUint64, ByteDataViewGetUint64, 0x4dd4eedd)               \
  V(_ByteDataView, getFloat32, ByteDataViewGetFloat32, 0x474b4719)             \
  V(_ByteDataView, getFloat64, ByteDataViewGetFloat64, 0x47207cf7)             \
  V(::, exp, MathExp, 0x4ccba23a)                                              \
  V(::, log, MathLog, 0x3908fd3c)                                              \
  V(::, max, MathMax, 0x4f51acb6)                                              \
  V(::, min, MathMin, 0x0bee5d52)                                              \
  V(::, pow, MathPow, 0x443379a8)                                              \
  V(::, _classRangeCheck, ClassRangeCheck, 0x025e8d82)                         \
  V(::, _classRangeCheckNegative, ClassRangeCheckNegated, 0x32451d73)          \
  V(Lists, copy, ListsCopy, 0x21a194fa)                                        \
  V(_Bigint, get:_neg, Bigint_getNeg, 0x355fa565)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 0x33b9dcd2)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 0x68de883a)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 0x02468899)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 0x577d9e20)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 0x2d7987ee)                 \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 0x1674fb28)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 0x0884b12f)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 0x66f792c6)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 0x32f2c87d)         \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 0x79ce8c9b)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 0x55839904)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 0x625e50cd)   \

// A list of core function that should never be inlined.
#define INLINE_BLACK_LIST(V)                                                   \
  V(::, asin, MathAsin, 0x48ec330d)                                            \
  V(::, acos, MathAcos, 0x22ef2552)                                            \
  V(::, atan, MathAtan, 0x38473515)                                            \
  V(::, atan2, MathAtan2, 0x39f1fa41)                                          \
  V(::, cos, MathCos, 0x337a20be)                                              \
  V(::, sin, MathSin, 0x595a044c)                                              \
  V(::, sqrt, MathSqrt, 0x0a683033)                                            \
  V(::, tan, MathTan, 0x29aba1ea)                                              \
  V(_Bigint, _lsh, Bigint_lsh, 0x0619eb8a)                                     \
  V(_Bigint, _rsh, Bigint_rsh, 0x0e1b80df)                                     \
  V(_Bigint, _absAdd, Bigint_absAdd, 0x1a2b6326)                               \
  V(_Bigint, _absSub, Bigint_absSub, 0x3bebab4e)                               \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 0x7d48a0b3)                               \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 0x638b5f5d)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 0x467dee78)           \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 0x36065c30)                       \
  V(_Double, >, Double_greaterThan, 0x452cd763)                                \
  V(_Double, >=, Double_greaterEqualThan, 0x6c317340)                          \
  V(_Double, <, Double_lessThan, 0x26dda4bc)                                   \
  V(_Double, <=, Double_lessEqualThan, 0x1e869d20)                             \
  V(_Double, ==, Double_equal, 0x5244dca3)                                     \
  V(_Double, +, Double_add, 0x49b2a530)                                        \
  V(_Double, -, Double_sub, 0x31833626)                                        \
  V(_Double, *, Double_mul, 0x21d31f1d)                                        \
  V(_Double, /, Double_div, 0x3e584fe8)                                        \
  V(_IntegerImplementation, +, Integer_add, 0x20192008)                        \
  V(_IntegerImplementation, -, Integer_sub, 0x5b877969)                        \
  V(_IntegerImplementation, *, Integer_mul, 0x142887aa)                        \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 0x5b740346)               \
  V(_IntegerImplementation, unary-, Integer_negate, 0x59dce57c)                \
  V(_IntegerImplementation, &, Integer_bitAnd, 0x50aab6e4)                     \
  V(_IntegerImplementation, |, Integer_bitOr, 0x40b9d4c2)                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 0x16edce03)                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 0x6220711f)                \
  V(_IntegerImplementation, ==, Integer_equal, 0x0d4d7f2c)                     \
  V(_IntegerImplementation, <, Integer_lessThan, 0x26dda4bc)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 0x1e869d20)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 0x6c317340)          \
  V(_IntegerImplementation, <<, Integer_shl, 0x5f43ef06)                       \
  V(_IntegerImplementation, >>, Integer_sar, 0x08a241c7)                       \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 0x2cf92c45)                             \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0x7041895a)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0x336fa3ea)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0x231bbe2e)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0x0371785f)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0x65ab3a20)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x0cb0fcf6)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0x6674ea6f)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0x236c6e7a)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0x5c367ffb)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0x772d1c0f)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0x68f17de8)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 0x6bb8b747)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0x75b8d278)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 0x6e54f794)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0x54123a05)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0x4a3fea0b)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0x5a11a2f9)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0x0edea58b)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x163bc6cc)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0x5def39d2)              \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x00e7c26b)

// clang-format on

// Forward declarations.
class Function;

// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class MethodRecognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name, type, fp)       \
  k##enum_name,
    RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
        kNumRecognizedMethods
  };

  static Kind RecognizeKind(const Function& function);
  static bool AlwaysInline(const Function& function);
  static bool PolymorphicTarget(const Function& function);
  static intptr_t ResultCid(const Function& function);
  static intptr_t MethodKindToReceiverCid(Kind kind);
  static const char* KindToCString(Kind kind);

#if !defined(DART_PRECOMPILED_RUNTIME)
  static void InitializeState();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};


#if !defined(DART_PRECOMPILED_RUNTIME)
#define CHECK_FINGERPRINT2(f, p0, p1, fp)                                      \
  ASSERT(f.CheckSourceFingerprint(#p0 ", " #p1, fp))

#define CHECK_FINGERPRINT3(f, p0, p1, p2, fp)                                  \
  ASSERT(f.CheckSourceFingerprint(#p0 ", " #p1 ", " #p2, fp))
#endif  // !defined(DART_PRECOMPILED_RUNTIME)


// clang-format off
// List of recognized list factories:
// (factory-name-symbol, class-name-string, constructor-name-string,
//  result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, _List, ., kArrayCid, 0x375519ad)                             \
  V(_GrowableListWithData, _GrowableList, .withData, kGrowableObjectArrayCid,  \
    0x401f3150)                                                                \
  V(_GrowableListFactory, _GrowableList, ., kGrowableObjectArrayCid,           \
    0x0b8d9feb)                                                                \
  V(_Int8ArrayFactory, Int8List, ., kTypedDataInt8ArrayCid, 0x2e7749e3)        \
  V(_Uint8ArrayFactory, Uint8List, ., kTypedDataUint8ArrayCid, 0x6ab75439)     \
  V(_Uint8ClampedArrayFactory, Uint8ClampedList, .,                            \
    kTypedDataUint8ClampedArrayCid, 0x183129d7)                                \
  V(_Int16ArrayFactory, Int16List, ., kTypedDataInt16ArrayCid, 0x14b563ea)     \
  V(_Uint16ArrayFactory, Uint16List, ., kTypedDataUint16ArrayCid, 0x07456be4)  \
  V(_Int32ArrayFactory, Int32List, ., kTypedDataInt32ArrayCid, 0x5bd49250)     \
  V(_Uint32ArrayFactory, Uint32List, ., kTypedDataUint32ArrayCid, 0x3c59b3a4)  \
  V(_Int64ArrayFactory, Int64List, ., kTypedDataInt64ArrayCid, 0x57d85ac7)     \
  V(_Uint64ArrayFactory, Uint64List, ., kTypedDataUint64ArrayCid, 0x2c093004)  \
  V(_Float64ArrayFactory, Float64List, ., kTypedDataFloat64ArrayCid,           \
    0x501be4f1)                                                                \
  V(_Float32ArrayFactory, Float32List, ., kTypedDataFloat32ArrayCid,           \
    0x738e124b)                                                                \
  V(_Float32x4ArrayFactory, Float32x4List, ., kTypedDataFloat32x4ArrayCid,     \
    0x7a7dd718)

// clang-format on

// Class that recognizes factories and returns corresponding result cid.
class FactoryRecognizer : public AllStatic {
 public:
  // Return kDynamicCid if factory is not recognized.
  static intptr_t ResultCid(const Function& factory);
};

}  // namespace dart

#endif  // RUNTIME_VM_METHOD_RECOGNIZER_H_
