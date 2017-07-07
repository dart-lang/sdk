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
  V(ClassID, getID, ClassIDgetID, Smi, 0x66d44356)                             \
  V(Object, Object., ObjectConstructor, Dynamic, 0x681617fe)                   \
  V(_List, ., ObjectArrayAllocate, Array, 0x6c3b54ee)                          \
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
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, Dynamic, 0x7dd630a9)           \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, Dynamic, 0x009d6a08)         \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, Dynamic, 0x0a9d8539)         \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, Dynamic, 0x0339aa55)       \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, Dynamic, 0x68f6ecc6)         \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, Dynamic, 0x5f249ccc)       \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, Dynamic, 0x325c86ad)         \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, Dynamic, 0x6ef655ba)     \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, Dynamic, 0x23c3584c)     \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, Dynamic, 0x2b20798d) \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, Dynamic, 0x72d3ec93)     \
  V(_StringBase, _interpolate, StringBaseInterpolate, Dynamic, 0x051d283a)     \
  V(_IntegerImplementation, toDouble, IntegerToDouble, Double, 0x09b4f74c)     \
  V(_Double, _add, DoubleAdd, Double, 0x2a38277b)                              \
  V(_Double, _sub, DoubleSub, Double, 0x4f466391)                              \
  V(_Double, _mul, DoubleMul, Double, 0x175e4f66)                              \
  V(_Double, _div, DoubleDiv, Double, 0x0854181b)                              \
  V(::, min, MathMin, Dynamic, 0x154735b3)                                     \
  V(::, max, MathMax, Dynamic, 0x217af195)                                     \
  V(::, _doublePow, MathDoublePow, Double, 0x61369cfd)                         \
  V(Float32x4, Float32x4., Float32x4Constructor, Float32x4, 0x5640679a)        \
  V(Float32x4, Float32x4.zero, Float32x4Zero, Float32x4, 0x2f0b7925)           \
  V(Float32x4, Float32x4.splat, Float32x4Splat, Float32x4, 0x750512c4)         \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits, Float32x4, \
    0x3b197ab4)                                                                \
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, Float32x4,     \
    0x5ca3f7f1)                                                                \
  V(_Float32x4, shuffle, Float32x4Shuffle, Float32x4, 0x7829101f)              \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, Float32x4, 0x4182c06b)        \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, Dynamic, 0x1d083ef2)       \
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
  V(_Float32x4, unary-, Float32x4Negate, Float32x4, 0x35f7f2b3)                \
  V(_Float32x4, abs, Float32x4Absolute, Float32x4, 0x471cdd87)                 \
  V(_Float32x4, clamp, Float32x4Clamp, Float32x4, 0x2cb30492)                  \
  V(_Float32x4, withX, Float32x4WithX, Float32x4, 0x4e336aff)                  \
  V(_Float32x4, withY, Float32x4WithY, Float32x4, 0x0a72b910)                  \
  V(_Float32x4, withZ, Float32x4WithZ, Float32x4, 0x31e93658)                  \
  V(_Float32x4, withW, Float32x4WithW, Float32x4, 0x60ddc105)                  \
  V(Float64x2, Float64x2., Float64x2Constructor, Float64x2, 0x2e2098de)        \
  V(Float64x2, Float64x2.zero, Float64x2Zero, Float64x2, 0x631002be)           \
  V(Float64x2, Float64x2.splat, Float64x2Splat, Float64x2, 0x1f056dd1)         \
  V(Float64x2, Float64x2.fromFloat32x4, Float64x2FromFloat32x4, Float64x2,     \
    0x238d44c5)                                                                \
  V(_Float64x2, get:x, Float64x2GetX, Double, 0x58c027f9)                      \
  V(_Float64x2, get:y, Float64x2GetY, Double, 0x3cf57159)                      \
  V(_Float64x2, unary-, Float64x2Negate, Float64x2, 0x3fa7c76a)                \
  V(_Float64x2, abs, Float64x2Abs, Float64x2, 0x031f9e47)                      \
  V(_Float64x2, sqrt, Float64x2Sqrt, Float64x2, 0x77f711dd)                    \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, Dynamic, 0x27de65ec)       \
  V(_Float64x2, scale, Float64x2Scale, Float64x2, 0x26830a61)                  \
  V(_Float64x2, withX, Float64x2WithX, Float64x2, 0x1d2bcaf5)                  \
  V(_Float64x2, withY, Float64x2WithY, Float64x2, 0x383ed6ac)                  \
  V(_Float64x2, min, Float64x2Min, Float64x2, 0x28d7ddf6)                      \
  V(_Float64x2, max, Float64x2Max, Float64x2, 0x0bd74e5b)                      \
  V(Int32x4, Int32x4., Int32x4Constructor, Int32x4, 0x775b77a8)                \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, Int32x4, 0x690007a2)        \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Int32x4FromFloat32x4Bits, Int32x4,     \
    0x72cbc76b)                                                                \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, Bool, 0x5638f823)                    \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, Bool, 0x446fd2d9)                    \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, Bool, 0x20d68ad8)                    \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, Bool, 0x5044ed0b)                    \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, Dynamic, 0x2c1f3e44)           \
  V(_Int32x4, shuffle, Int32x4Shuffle, Int32x4, 0x20bc0b16)                    \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, Int32x4, 0x5c7056e1)              \
  V(_Int32x4, select, Int32x4Select, Float32x4, 0x6b49654f)                    \
  V(_Int32x4, withFlagX, Int32x4WithFlagX, Int32x4, 0x0ef58fcf)                \
  V(_Int32x4, withFlagY, Int32x4WithFlagY, Int32x4, 0x6485a9c4)                \
  V(_Int32x4, withFlagZ, Int32x4WithFlagZ, Int32x4, 0x267acdfa)                \
  V(_Int32x4, withFlagW, Int32x4WithFlagW, Int32x4, 0x345ac675)                \
  V(_Int64List, [], Int64ArrayGetIndexed, Dynamic, 0x1cfce099)                 \
  V(_Int64List, []=, Int64ArraySetIndexed, Dynamic, 0x6b2911f5)                \
  V(_Bigint, get:_neg, Bigint_getNeg, Bool, 0x356019c4)                        \
  V(_Bigint, get:_used, Bigint_getUsed, Smi, 0x33ba5131)                       \
  V(_Bigint, get:_digits, Bigint_getDigits, TypedDataUint32Array, 0x68defc99)  \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, Dynamic, 0x0246fcf8)      \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, Dynamic, 0x53a33a00)      \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, Array, 0x2d79fc4d)          \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, Dynamic, 0x129a9708)        \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, Smi, 0x0885258e)    \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, Dynamic, 0x631d2ea6)\
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, Smi, 0x32f33cdc)    \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, Dynamic, 0x75f4287b)\
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, Smi,          \
    0x55840d63)                                                                \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, Dynamic,      \
    0x5e83ecad)                                                                \
  V(::, _classRangeCheck, ClassRangeCheck, Bool, 0x16a2fc83)                   \
  V(::, _classRangeCheckNegative, ClassRangeCheckNegated, Bool, 0x46898c74)    \
  V(::, _classRangeAssert, ClassRangeAssert, Dynamic, 0x3ccbdf6e)              \
  V(::, _classIdEqualsAssert, ClassIdEqualsAssert, Dynamic, 0x4dc80932)        \


// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, Smi, 0x6574c6b0)                                   \
  V(_Smi, get:bitLength, Smi_bitLength, Smi, 0x25b356ab)                       \
  V(_Smi, _bitAndFromSmi, Smi_bitAndFromSmi, Smi, 0x490a4da1)                  \
  V(_Bigint, _lsh, Bigint_lsh, Dynamic, 0x40d9f1cc)                            \
  V(_Bigint, _rsh, Bigint_rsh, Dynamic, 0x703f1a40)                            \
  V(_Bigint, _absAdd, Bigint_absAdd, Dynamic, 0x50fb1e47)                      \
  V(_Bigint, _absSub, Bigint_absSub, Dynamic, 0x2beeb34d)                      \
  V(_Bigint, _mulAdd, Bigint_mulAdd, Dynamic, 0x4feffd35)                      \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, Dynamic, 0x1acf0bbe)                      \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, Dynamic, 0x0a2898bb)  \
  V(_Montgomery, _mulMod, Montgomery_mulMod, Dynamic, 0x26d5b8ee)              \
  V(_Double, >, Double_greaterThan, Bool, 0x0a202683)                          \
  V(_Double, >=, Double_greaterEqualThan, Bool, 0x57491a62)                    \
  V(_Double, <, Double_lessThan, Bool, 0x2e9d61bb)                             \
  V(_Double, <=, Double_lessEqualThan, Bool, 0x099e4442)                       \
  V(_Double, ==, Double_equal, Bool, 0x04c399a1)                               \
  V(_Double, +, Double_add, Double, 0x0ea5f450)                                \
  V(_Double, -, Double_sub, Double, 0x76768546)                                \
  V(_Double, *, Double_mul, Double, 0x66c66e3d)                                \
  V(_Double, /, Double_div, Double, 0x034b9f08)                                \
  V(_Double, get:isNaN, Double_getIsNaN, Bool, 0x0af9604a)                     \
  V(_Double, get:isInfinite, Double_getIsInfinite, Bool, 0x0f7a56e8)           \
  V(_Double, get:isNegative, Double_getIsNegative, Bool, 0x3a597395)           \
  V(_Double, _mulFromInteger, Double_mulFromInteger, Double, 0x4fb72915)       \
  V(_Double, .fromInteger, DoubleFromInteger, Double, 0x78d9de2c)              \
  V(_List, []=, ObjectArraySetIndexed, Dynamic, 0x51691f4c)                    \
  V(_GrowableList, .withData, GrowableArray_Allocate, GrowableObjectArray,     \
    0x3468a26f)                                                                \
  V(_GrowableList, add, GrowableArray_add, Dynamic, 0x1ce3b4f8)                \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, Dynamic, 0x380184b1)          \
  V(_RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky, Dynamic,          \
    0x79b8f955)                                                                \
  V(Object, ==, ObjectEquals, Bool, 0x464c6a19)                                \
  V(Object, get:runtimeType, ObjectRuntimeType, Type, 0x00e836ca)              \
  V(Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType, Bool, 0x597b967a) \
  V(_StringBase, get:hashCode, String_getHashCode, Smi, 0x78c35fe7)            \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, Bool, 0x1fa6a4c9)             \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, Bool,          \
    0x649cbeef)                                                                \
  V(_StringBase, [], StringBaseCharAt, Dynamic, 0x14da5924)                    \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, Smi, 0x78c35fe7)  \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked, OneByteString, 0x3538ad86)               \
  V(_OneByteString, _setAt, OneByteStringSetAt, Dynamic, 0x7d1b2b10)           \
  V(_OneByteString, _allocate, OneByteString_allocate, OneByteString,          \
    0x604ec475)                                                                \
  V(_OneByteString, ==, OneByteString_equality, Bool, 0x4719e83f)              \
  V(_TwoByteString, ==, TwoByteString_equality, Bool, 0x4719e83f)              \
  V(::, _getHash, Object_getHash, Smi, 0x2827856d)                             \
  V(::, _setHash, Object_setHash, Object, 0x302d1fe8)                          \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    Dynamic, 0x6a10c54a)                                                       \
  V(_IntegerImplementation, +, Integer_add, Dynamic, 0x5125faaa)               \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, Dynamic,  \
    0x3fa4b1ed)                                                                \
  V(_IntegerImplementation, -, Integer_sub, Dynamic, 0x0c94540b)               \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    Dynamic, 0x3216e299)                                                       \
  V(_IntegerImplementation, *, Integer_mul, Dynamic, 0x4535624c)               \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    Dynamic, 0x6348b974)                                                       \
  V(_IntegerImplementation, ~/, Integer_truncDivide, Dynamic, 0x1f48f4c9)      \
  V(_IntegerImplementation, unary-, Integer_negate, Dynamic, 0x4e346e3b)       \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    Dynamic, 0x395b1678)                                                       \
  V(_IntegerImplementation, &, Integer_bitAnd, Dynamic, 0x01b79186)            \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    Dynamic, 0x6a36b395)                                                       \
  V(_IntegerImplementation, |, Integer_bitOr, Dynamic, 0x71c6af64)             \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    Dynamic, 0x72da93f0)                                                       \
  V(_IntegerImplementation, ^, Integer_bitXor, Dynamic, 0x47faa8a5)            \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, Bool, 0x4a50ed58)                              \
  V(_IntegerImplementation, >, Integer_greaterThan, Bool, 0x23dd0c00)          \
  V(_IntegerImplementation, ==, Integer_equal, Bool, 0x7d51f04d)               \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, Bool,     \
    0x063be842)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, Bool, 0x2e9d61bb)             \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, Bool, 0x099e4442)       \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, Bool, 0x57491a62)    \
  V(_IntegerImplementation, <<, Integer_shl, Dynamic, 0x1050c9a8)              \
  V(_IntegerImplementation, >>, Integer_sar, Dynamic, 0x39af1c69)              \
  V(_Double, toInt, DoubleToInteger, Dynamic, 0x26ef344b)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, Double, 0x70482cf3)                                    \
  V(_Random, _nextState, Random_nextState, Dynamic, 0x268dec36)                \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, Double, 0x6b7bd98c)                                      \
  V(::, cos, MathCos, Double, 0x459bf5fe)                                      \
  V(::, tan, MathTan, Double, 0x3bcd772a)                                      \
  V(::, asin, MathAsin, Double, 0x2ecc2fcd)                                    \
  V(::, acos, MathAcos, Double, 0x08cf2212)                                    \
  V(::, atan, MathAtan, Double, 0x1e2731d5)                                    \
  V(::, atan2, MathAtan2, Double, 0x39f1fa41)                                  \

#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(Int8List, ., TypedData_Int8Array_factory, TypedDataInt8Array, 0x165876c2)  \
  V(Uint8List, ., TypedData_Uint8Array_factory, TypedDataUint8Array,           \
    0x52988118)                                                                \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory,                  \
    TypedDataUint8ClampedArray, 0x001256b6)                                    \
  V(Int16List, ., TypedData_Int16Array_factory, TypedDataInt16Array,           \
    0x7c9690c9)                                                                \
  V(Uint16List, ., TypedData_Uint16Array_factory, TypedDataUint16Array,        \
    0x6f2698c3)                                                                \
  V(Int32List, ., TypedData_Int32Array_factory, TypedDataInt32Array,           \
    0x43b5bf2f)                                                                \
  V(Uint32List, ., TypedData_Uint32Array_factory,                              \
    TypedDataUint32Array, 0x243ae083)                                          \
  V(Int64List, ., TypedData_Int64Array_factory,                                \
    TypedDataInt64Array, 0x3fb987a6)                                           \
  V(Uint64List, ., TypedData_Uint64Array_factory,                              \
    TypedDataUint64Array, 0x13ea5ce3)                                          \
  V(Float32List, ., TypedData_Float32Array_factory,                            \
    TypedDataFloat32Array, 0x5b6f3f2a)                                         \
  V(Float64List, ., TypedData_Float64Array_factory,                            \
    TypedDataFloat64Array, 0x37fd11d0)                                         \
  V(Float32x4List, ., TypedData_Float32x4Array_factory,                        \
    TypedDataFloat32x4Array, 0x625f03f7)                                       \
  V(Int32x4List, ., TypedData_Int32x4Array_factory,                            \
    TypedDataInt32x4Array, 0x05eef727)                                         \
  V(Float64x2List, ., TypedData_Float64x2Array_factory,                        \
    TypedDataFloat64x2Array, 0x00ad21b8)                                       \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(_Int8List, [], Int8ArrayGetIndexed, Smi, 0x14885f2e)                       \
  V(_Int8List, []=, Int8ArraySetIndexed, Dynamic, 0x423e16f0)                  \
  V(_Uint8List, [], Uint8ArrayGetIndexed, Smi, 0x539f6bd6)                     \
  V(_Uint8List, []=, Uint8ArraySetIndexed, Dynamic, 0x2fad7f61)                \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, Smi, 0x539f6bd6)    \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, Dynamic,           \
    0x2fad7f61)                                                                \
  V(_Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, Smi, 0x539f6bd6)       \
  V(_Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, Dynamic, 0x04dac5c1)  \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    Smi, 0x539f6bd6)                                                           \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    Dynamic, 0x04dac5c1)                                                       \
  V(_Int16List, [], Int16ArrayGetIndexed, Smi, 0x29d82e4a)                     \
  V(_Int16List, []=, Int16ArraySetIndexed, Dynamic, 0x2b986c41)                \
  V(_Uint16List, [], Uint16ArrayGetIndexed, Smi, 0x2a5bb595)                   \
  V(_Uint16List, []=, Uint16ArraySetIndexed, Dynamic, 0x4c45b32f)              \
  V(_Int32List, [], Int32ArrayGetIndexed, Dynamic, 0x16d2b8df)                 \
  V(_Int32List, []=, Int32ArraySetIndexed, Dynamic, 0x38298243)                \
  V(_Uint32List, [], Uint32ArrayGetIndexed, Dynamic, 0x63983dd0)               \
  V(_Uint32List, []=, Uint32ArraySetIndexed, Dynamic, 0x1f3f0499)              \
  V(_Float64List, [], Float64ArrayGetIndexed, Double, 0x55832988)              \
  V(_Float64List, []=, Float64ArraySetIndexed, Dynamic, 0x2cfebd47)            \
  V(_Float32List, [], Float32ArrayGetIndexed, Double, 0x25f01521)              \
  V(_Float32List, []=, Float32ArraySetIndexed, Dynamic, 0x35c7780b)            \
  V(_Float32x4List, [], Float32x4ArrayGetIndexed, Float32x4, 0x5d9ec2ed)       \
  V(_Float32x4List, []=, Float32x4ArraySetIndexed, Dynamic, 0x2340a652)        \
  V(_Int32x4List, [], Int32x4ArrayGetIndexed, Int32x4, 0x168a949e)             \
  V(_Int32x4List, []=, Int32x4ArraySetIndexed, Dynamic, 0x59b0878b)            \
  V(_Float64x2List, [], Float64x2ArrayGetIndexed, Float64x2, 0x2f5bf0e3)       \
  V(_Float64x2List, []=, Float64x2ArraySetIndexed, Dynamic, 0x13eeb4eb)        \
  V(_TypedList, get:length, TypedDataLength, Smi, 0x20915079)                  \
  V(_Float32x4, get:x, Float32x4ShuffleX, Double, 0x63d1359e)                  \
  V(_Float32x4, get:y, Float32x4ShuffleY, Double, 0x2034af7a)                  \
  V(_Float32x4, get:z, Float32x4ShuffleZ, Double, 0x13189219)                  \
  V(_Float32x4, get:w, Float32x4ShuffleW, Double, 0x6989c47f)                  \
  V(_Float32x4, *, Float32x4Mul, Float32x4, 0x760b3bd3)                        \
  V(_Float32x4, -, Float32x4Sub, Float32x4, 0x56c01782)                        \
  V(_Float32x4, +, Float32x4Add, Float32x4, 0x181bc622)                        \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, Smi, 0x2594af31)                     \
  V(_List, [], ObjectArrayGetIndexed, Dynamic, 0x7d5c734f)                     \
  V(_ImmutableList, get:length, ImmutableArrayLength, Smi, 0x2594af31)         \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, Dynamic, 0x7d5c734f)         \
  V(_GrowableList, get:length, GrowableArrayLength, Smi, 0x18dd1255)           \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, Smi, 0x2e044a01)      \
  V(_GrowableList, _setData, GrowableArraySetData, Dynamic, 0x55dd7669)        \
  V(_GrowableList, _setLength, GrowableArraySetLength, Dynamic, 0x0d5d28fb)    \
  V(_GrowableList, [], GrowableArrayGetIndexed, Dynamic, 0x5c8eb511)           \
  V(_GrowableList, []=, GrowableArraySetIndexed, Dynamic, 0x2a0356b6)          \
  V(_StringBase, get:length, StringBaseLength, Smi, 0x2a2c8f72)                \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, Smi, 0x55a0a1f3)      \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, Smi, 0x55a0a1f3)      \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    Smi, 0x55a0a1f3)                                                           \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    Smi, 0x55a0a1f3)                                                           \
  V(_Double, unary-, DoubleFlipSignBit, Double, 0x6bff8eb0)                    \
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

#define ASYNC_LIB_INTRINSIC_LIST(V)                                            \
  V(::, _clearAsyncThreadStackTrace, ClearAsyncThreadStackTrace,               \
    Dynamic, 0x2d287286)                                                       \
  V(::, _setAsyncThreadStackTrace, SetAsyncThreadStackTrace,                   \
    Dynamic, 0x1d12fcc8)

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
  ASYNC_LIB_INTRINSIC_LIST(V)                                                  \
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
  V(Object, ==, ObjectEquals, 0x464c6a19)                                      \
  V(_List, get:length, ObjectArrayLength, 0x2594af31)                          \
  V(_ImmutableList, get:length, ImmutableArrayLength, 0x2594af31)              \
  V(_TypedList, get:length, TypedDataLength, 0x20915079)                       \
  V(_GrowableList, get:length, GrowableArrayLength, 0x18dd1255)                \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 0x2e044a01)           \
  V(_GrowableList, add, GrowableListAdd, 0x1ce3b4f8)                           \
  V(_GrowableList, removeLast, GrowableListRemoveLast, 0x3daaaca4)             \
  V(_StringBase, get:length, StringBaseLength, 0x2a2c8f72)                     \
  V(ListIterator, moveNext, ListIteratorMoveNext, 0x7ead154d)                  \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 0x4197892b)  \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 0x64c204d5)            \
  V(_GrowableList, forEach, GrowableArrayForEach, 0x4cc8215b)                  \
  V(_List, ., ObjectArrayAllocate, 0x6c3b54ee)                                 \
  V(ListMixin, get:isEmpty, ListMixinIsEmpty, 0x7a327465)                      \
  V(_List, get:iterator, ObjectArrayIterator, 0x757431f3)                      \
  V(_List, forEach, ObjectArrayForEach, 0x4dfea652)                            \
  V(_List, _slice, ObjectArraySlice, 0x671ebc98)                               \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 0x757431f3)          \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 0x4dfea652)                \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 0x4e8a9e40)                 \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 0x46f85777)                \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 0x4fb4a051)                   \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 0x443418ed)                  \
  V(_ByteDataView, setInt8, ByteDataViewSetInt8, 0x6502a95f)                   \
  V(_ByteDataView, setUint8, ByteDataViewSetUint8, 0x7b051d40)                 \
  V(_ByteDataView, setInt16, ByteDataViewSetInt16, 0x41bf9a68)                 \
  V(_ByteDataView, setUint16, ByteDataViewSetUint16, 0x384e7797)               \
  V(_ByteDataView, setInt32, ByteDataViewSetInt32, 0x41973c2e)                 \
  V(_ByteDataView, setUint32, ByteDataViewSetUint32, 0x49a7590e)               \
  V(_ByteDataView, setInt64, ByteDataViewSetInt64, 0x31e47b84)                 \
  V(_ByteDataView, setUint64, ByteDataViewSetUint64, 0x57daedc6)               \
  V(_ByteDataView, setFloat32, ByteDataViewSetFloat32, 0x6c92cb69)             \
  V(_ByteDataView, setFloat64, ByteDataViewSetFloat64, 0x6f4b64ab)             \
  V(_ByteDataView, getInt8, ByteDataViewGetInt8, 0x655d546e)                   \
  V(_ByteDataView, getUint8, ByteDataViewGetUint8, 0x5a819513)                 \
  V(_ByteDataView, getInt16, ByteDataViewGetInt16, 0x449cf8de)                 \
  V(_ByteDataView, getUint16, ByteDataViewGetUint16, 0x2f585007)               \
  V(_ByteDataView, getInt32, ByteDataViewGetInt32, 0x1590e92b)                 \
  V(_ByteDataView, getUint32, ByteDataViewGetUint32, 0x0ed36ced)               \
  V(_ByteDataView, getInt64, ByteDataViewGetInt64, 0x535fe14d)                 \
  V(_ByteDataView, getUint64, ByteDataViewGetUint64, 0x469be77a)               \
  V(_ByteDataView, getFloat32, ByteDataViewGetFloat32, 0x32567817)             \
  V(_ByteDataView, getFloat64, ByteDataViewGetFloat64, 0x322badf5)             \
  V(::, exp, MathExp, 0x32ab9efa)                                              \
  V(::, log, MathLog, 0x1ee8f9fc)                                              \
  V(::, max, MathMax, 0x217af195)                                              \
  V(::, min, MathMin, 0x154735b3)                                              \
  V(::, pow, MathPow, 0x5f119fa5)                                              \
  V(::, _classRangeCheck, ClassRangeCheck, 0x16a2fc83)                         \
  V(::, _classRangeCheckNegative, ClassRangeCheckNegated, 0x46898c74)          \
  V(::, _classRangeAssert, ClassRangeAssert, 0x3ccbdf6e)                       \
  V(::, _classIdEqualsAssert, ClassIdEqualsAssert, 0x4dc80932)                 \
  V(Lists, copy, ListsCopy, 0x714584f8)                                        \
  V(_Bigint, get:_neg, Bigint_getNeg, 0x356019c4)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 0x33ba5131)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 0x68defc99)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 0x0246fcf8)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 0x53a33a00)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 0x2d79fc4d)                 \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 0x129a9708)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 0x0885258e)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 0x631d2ea6)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 0x32f33cdc)         \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 0x75f4287b)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 0x55840d63)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 0x5e83ecad)   \

// A list of core function that should never be inlined.
#define INLINE_BLACK_LIST(V)                                                   \
  V(::, asin, MathAsin, 0x2ecc2fcd)                                            \
  V(::, acos, MathAcos, 0x08cf2212)                                            \
  V(::, atan, MathAtan, 0x1e2731d5)                                            \
  V(::, atan2, MathAtan2, 0x39f1fa41)                                          \
  V(::, cos, MathCos, 0x459bf5fe)                                              \
  V(::, sin, MathSin, 0x6b7bd98c)                                              \
  V(::, sqrt, MathSqrt, 0x70482cf3)                                            \
  V(::, tan, MathTan, 0x3bcd772a)                                              \
  V(_Bigint, _lsh, Bigint_lsh, 0x40d9f1cc)                                     \
  V(_Bigint, _rsh, Bigint_rsh, 0x703f1a40)                                     \
  V(_Bigint, _absAdd, Bigint_absAdd, 0x50fb1e47)                               \
  V(_Bigint, _absSub, Bigint_absSub, 0x2beeb34d)                               \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 0x4feffd35)                               \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 0x1acf0bbe)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 0x0a2898bb)           \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 0x26d5b8ee)                       \
  V(_Double, >, Double_greaterThan, 0x0a202683)                                \
  V(_Double, >=, Double_greaterEqualThan, 0x57491a62)                          \
  V(_Double, <, Double_lessThan, 0x2e9d61bb)                                   \
  V(_Double, <=, Double_lessEqualThan, 0x099e4442)                             \
  V(_Double, ==, Double_equal, 0x04c399a1)                                     \
  V(_Double, +, Double_add, 0x0ea5f450)                                        \
  V(_Double, -, Double_sub, 0x76768546)                                        \
  V(_Double, *, Double_mul, 0x66c66e3d)                                        \
  V(_Double, /, Double_div, 0x034b9f08)                                        \
  V(_IntegerImplementation, +, Integer_add, 0x5125faaa)                        \
  V(_IntegerImplementation, -, Integer_sub, 0x0c94540b)                        \
  V(_IntegerImplementation, *, Integer_mul, 0x4535624c)                        \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 0x1f48f4c9)               \
  V(_IntegerImplementation, unary-, Integer_negate, 0x4e346e3b)                \
  V(_IntegerImplementation, &, Integer_bitAnd, 0x01b79186)                     \
  V(_IntegerImplementation, |, Integer_bitOr, 0x71c6af64)                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 0x47faa8a5)                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 0x23dd0c00)                \
  V(_IntegerImplementation, ==, Integer_equal, 0x7d51f04d)                     \
  V(_IntegerImplementation, <, Integer_lessThan, 0x2e9d61bb)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 0x099e4442)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 0x57491a62)          \
  V(_IntegerImplementation, <<, Integer_shl, 0x1050c9a8)                       \
  V(_IntegerImplementation, >>, Integer_sar, 0x39af1c69)                       \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 0x14da5924)                             \
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
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0x7dd630a9)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 0x009d6a08)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0x0a9d8539)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 0x0339aa55)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0x68f6ecc6)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0x5f249ccc)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0x6ef655ba)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0x23c3584c)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x2b20798d)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0x72d3ec93)              \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x00e836ca)

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
  V(_ListFactory, _List, ., kArrayCid, 0x6c3b54ee)                             \
  V(_GrowableListWithData, _GrowableList, .withData, kGrowableObjectArrayCid,  \
    0x3468a26f)                                                                \
  V(_GrowableListFactory, _GrowableList, ., kGrowableObjectArrayCid,           \
    0x7c4346ab)                                                                \
  V(_Int8ArrayFactory, Int8List, ., kTypedDataInt8ArrayCid, 0x165876c2)        \
  V(_Uint8ArrayFactory, Uint8List, ., kTypedDataUint8ArrayCid, 0x52988118)     \
  V(_Uint8ClampedArrayFactory, Uint8ClampedList, .,                            \
    kTypedDataUint8ClampedArrayCid, 0x001256b6)                                \
  V(_Int16ArrayFactory, Int16List, ., kTypedDataInt16ArrayCid, 0x7c9690c9)     \
  V(_Uint16ArrayFactory, Uint16List, ., kTypedDataUint16ArrayCid, 0x6f2698c3)  \
  V(_Int32ArrayFactory, Int32List, ., kTypedDataInt32ArrayCid, 0x43b5bf2f)     \
  V(_Uint32ArrayFactory, Uint32List, ., kTypedDataUint32ArrayCid, 0x243ae083)  \
  V(_Int64ArrayFactory, Int64List, ., kTypedDataInt64ArrayCid, 0x3fb987a6)     \
  V(_Uint64ArrayFactory, Uint64List, ., kTypedDataUint64ArrayCid, 0x13ea5ce3)  \
  V(_Float64ArrayFactory, Float64List, ., kTypedDataFloat64ArrayCid,           \
    0x37fd11d0)                                                                \
  V(_Float32ArrayFactory, Float32List, ., kTypedDataFloat32ArrayCid,           \
    0x5b6f3f2a)                                                                \
  V(_Float32x4ArrayFactory, Float32x4List, ., kTypedDataFloat32x4ArrayCid,     \
    0x625f03f7)

// clang-format on

// Class that recognizes factories and returns corresponding result cid.
class FactoryRecognizer : public AllStatic {
 public:
  // Return kDynamicCid if factory is not recognized.
  static intptr_t ResultCid(const Function& factory);
};

}  // namespace dart

#endif  // RUNTIME_VM_METHOD_RECOGNIZER_H_
