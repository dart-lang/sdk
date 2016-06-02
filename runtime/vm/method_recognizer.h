// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_METHOD_RECOGNIZER_H_
#define VM_METHOD_RECOGNIZER_H_

#include "vm/allocation.h"

namespace dart {

// (class-name, function-name, recognized enum, result type, fingerprint).
// When adding a new function add a 0 as fingerprint, build and run to get the
// correct fingerprint from the mismatch error.
#define OTHER_RECOGNIZED_LIST(V)                                               \
  V(::, identical, ObjectIdentical, Bool, 317103244)                           \
  V(ClassID, getID, ClassIDgetID, Smi, 1385157717)                             \
  V(Object, Object., ObjectConstructor, Dynamic, 1746278398)                   \
  V(_List, ., ObjectArrayAllocate, Array, 1661438741)                          \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, Smi, 1508321565)               \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, Smi, 953411007)              \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, Smi, 433971756)              \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, Smi, 1329446488)           \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, Dynamic, 137212209)          \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, Dynamic, 499907480)        \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, Dynamic, 1639388276)         \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, Double, 1672834581)      \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, Double, 966634744)       \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, Float32x4,           \
    1197581758)                                                                \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, Int32x4, 810805548)      \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, Dynamic, 1317196265)           \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, Dynamic, 1328908284)         \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, Dynamic, 1827614958)         \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, Dynamic, 1694054572)       \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, Dynamic, 915652649)          \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, Dynamic, 1958474336)       \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, Dynamic, 1970687707)         \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, Dynamic, 1853026980)     \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, Dynamic, 1197862362)     \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, Dynamic, 2093630771) \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, Dynamic, 1982971324)     \
  V(_StringBase, _interpolate, StringBaseInterpolate, Dynamic, 1872292681)     \
  V(_IntegerImplementation, toDouble, IntegerToDouble, Double, 792762465)      \
  V(_Double, _add, DoubleAdd, Double, 2213216)                                 \
  V(_Double, _sub, DoubleSub, Double, 1100692582)                              \
  V(_Double, _mul, DoubleMul, Double, 436784097)                               \
  V(_Double, _div, DoubleDiv, Double, 953317135)                               \
  V(::, min, MathMin, Dynamic, 1115051548)                                     \
  V(::, max, MathMax, Dynamic, 1410473322)                                     \
  V(::, _doublePow, MathDoublePow, Double, 1770960781)                         \
  V(Float32x4, Float32x4., Float32x4Constructor, Float32x4, 93751705)          \
  V(Float32x4, Float32x4.zero, Float32x4Zero, Float32x4, 1193954374)           \
  V(Float32x4, Float32x4.splat, Float32x4Splat, Float32x4, 12296613)           \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits, Float32x4, \
    1188039061)                                                                \
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, Float32x4,     \
    1750763218)                                                                \
  V(Float32x4, shuffle, Float32x4Shuffle, Float32x4, 2015957023)               \
  V(Float32x4, shuffleMix, Float32x4ShuffleMix, Float32x4, 1099087979)         \
  V(Float32x4, get:signMask, Float32x4GetSignMask, Dynamic, 487049875)         \
  V(Float32x4, _cmpequal, Float32x4Equal, Int32x4, 127403211)                  \
  V(Float32x4, _cmpgt, Float32x4GreaterThan, Int32x4, 2118391173)              \
  V(Float32x4, _cmpgte, Float32x4GreaterThanOrEqual, Int32x4, 557807661)       \
  V(Float32x4, _cmplt, Float32x4LessThan, Int32x4, 1061691185)                 \
  V(Float32x4, _cmplte, Float32x4LessThanOrEqual, Int32x4, 102608993)          \
  V(Float32x4, _cmpnequal, Float32x4NotEqual, Int32x4, 1873649982)             \
  V(Float32x4, _min, Float32x4Min, Float32x4, 1158016632)                      \
  V(Float32x4, _max, Float32x4Max, Float32x4, 118915526)                       \
  V(Float32x4, _scale, Float32x4Scale, Float32x4, 415757469)                   \
  V(Float32x4, _sqrt, Float32x4Sqrt, Float32x4, 1934518992)                    \
  V(Float32x4, _reciprocalSqrt, Float32x4ReciprocalSqrt, Float32x4,            \
    1586141174)                                                                \
  V(Float32x4, _reciprocal, Float32x4Reciprocal, Float32x4, 1651466502)        \
  V(Float32x4, _negate, Float32x4Negate, Float32x4, 2142478676)                \
  V(Float32x4, _abs, Float32x4Absolute, Float32x4, 337704007)                  \
  V(Float32x4, _clamp, Float32x4Clamp, Float32x4, 1107305005)                  \
  V(Float32x4, withX, Float32x4WithX, Float32x4, 1311992575)                   \
  V(Float32x4, withY, Float32x4WithY, Float32x4, 175290640)                    \
  V(Float32x4, withZ, Float32x4WithZ, Float32x4, 837367384)                    \
  V(Float32x4, withW, Float32x4WithW, Float32x4, 1625145605)                   \
  V(Float64x2, Float64x2., Float64x2Constructor, Float64x2, 423355933)         \
  V(Float64x2, Float64x2.zero, Float64x2Zero, Float64x2, 2066666975)           \
  V(Float64x2, Float64x2.splat, Float64x2Splat, Float64x2, 716962994)          \
  V(Float64x2, Float64x2.fromFloat32x4, Float64x2FromFloat32x4, Float64x2,     \
    792974246)                                                                 \
  V(Float64x2, get:x, Float64x2GetX, Double, 1488958362)                       \
  V(Float64x2, get:y, Float64x2GetY, Double, 1022688506)                       \
  V(Float64x2, _negate, Float64x2Negate, Float64x2, 1693416311)                \
  V(Float64x2, abs, Float64x2Abs, Float64x2, 52403783)                         \
  V(Float64x2, sqrt, Float64x2Sqrt, Float64x2, 2012680669)                     \
  V(Float64x2, get:signMask, Float64x2GetSignMask, Dynamic, 668856717)         \
  V(Float64x2, scale, Float64x2Scale, Float64x2, 646122081)                    \
  V(Float64x2, withX, Float64x2WithX, Float64x2, 489409269)                    \
  V(Float64x2, withY, Float64x2WithY, Float64x2, 943642284)                    \
  V(Float64x2, min, Float64x2Min, Float64x2, 685235702)                        \
  V(Float64x2, max, Float64x2Max, Float64x2, 198659675)                        \
  V(Int32x4, Int32x4., Int32x4Constructor, Int32x4, 649173415)                 \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, Int32x4, 458597857)         \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Int32x4FromFloat32x4Bits, Int32x4,     \
    2122470988)                                                                \
  V(Int32x4, get:flagX, Int32x4GetFlagX, Bool, 1446544324)                     \
  V(Int32x4, get:flagY, Int32x4GetFlagY, Bool, 1148149370)                     \
  V(Int32x4, get:flagZ, Int32x4GetFlagZ, Bool, 550901369)                      \
  V(Int32x4, get:flagW, Int32x4GetFlagW, Bool, 1346664620)                     \
  V(Int32x4, get:signMask, Int32x4GetSignMask, Dynamic, 740215269)             \
  V(Int32x4, shuffle, Int32x4Shuffle, Int32x4, 549194518)                      \
  V(Int32x4, shuffleMix, Int32x4ShuffleMix, Int32x4, 1550866145)               \
  V(Int32x4, select, Int32x4Select, Float32x4, 1368318775)                     \
  V(Int32x4, withFlagX, Int32x4WithFlagX, Int32x4, 250974159)                  \
  V(Int32x4, withFlagY, Int32x4WithFlagY, Int32x4, 1686481348)                 \
  V(Int32x4, withFlagZ, Int32x4WithFlagZ, Int32x4, 645582330)                  \
  V(Int32x4, withFlagW, Int32x4WithFlagW, Int32x4, 878364277)                  \
  V(Float32List, [], Float32ArrayGetIndexed, Double, 1451643535)               \
  V(Float32List, []=, Float32ArraySetIndexed, Dynamic, 453873887)              \
  V(Int8List, [], Int8ArrayGetIndexed, Smi, 110819507)                         \
  V(Int8List, []=, Int8ArraySetIndexed, Dynamic, 865684695)                    \
  V(Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, Smi, 41288685)          \
  V(Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, Dynamic, 687206488)    \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    Smi, 41288685)                                                             \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    Dynamic, 687206488)                                                        \
  V(Int16List, [], Int16ArrayGetIndexed, Smi, 389863073)                       \
  V(Int16List, []=, Int16ArraySetIndexed, Dynamic, 855133756)                  \
  V(Uint16List, [], Uint16ArrayGetIndexed, Smi, 1053739567)                    \
  V(Uint16List, []=, Uint16ArraySetIndexed, Dynamic, 1547307961)               \
  V(Int32List, [], Int32ArrayGetIndexed, Dynamic, 640610057)                   \
  V(Int32List, []=, Int32ArraySetIndexed, Dynamic, 453358705)                  \
  V(Int64List, [], Int64ArrayGetIndexed, Dynamic, 202150810)                   \
  V(Int64List, []=, Int64ArraySetIndexed, Dynamic, 924110852)                  \
  V(Float32x4List, [], Float32x4ArrayGetIndexed, Float32x4, 29819259)          \
  V(Float32x4List, []=, Float32x4ArraySetIndexed, Dynamic, 1458062250)         \
  V(Int32x4List, [], Int32x4ArrayGetIndexed, Int32x4, 137707405)               \
  V(Int32x4List, []=, Int32x4ArraySetIndexed, Dynamic, 496650149)              \
  V(Float64x2List, [], Float64x2ArrayGetIndexed, Float64x2, 1721439384)        \
  V(Float64x2List, []=, Float64x2ArraySetIndexed, Dynamic, 1994027006)         \
  V(_Bigint, get:_neg, Bigint_getNeg, Bool, 2079423063)                        \
  V(_Bigint, get:_used, Bigint_getUsed, Smi, 1426329619)                       \
  V(_Bigint, get:_digits, Bigint_getDigits, TypedDataUint32Array, 1185333683)  \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, Dynamic,                  \
    2104211307)                                                                \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, Dynamic, 1273697266)      \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, Array,       \
    1274399923)                                                                \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, Dynamic, 1611093357)        \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, Smi, 367462469)     \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, Dynamic,            \
    1049390812)                                                                \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, Smi, 902147072)     \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, Dynamic,            \
    1236137630)                                                                \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, Smi,          \
    812542585)                                                                 \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, Dynamic,      \
    1072259010)                                                                \


// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, Smi, 1673522705)                                   \
  V(_Smi, get:bitLength, Smi_bitLength, Smi, 632480332)                        \
  V(_Bigint, _lsh, Bigint_lsh, Dynamic, 1557746963)                            \
  V(_Bigint, _rsh, Bigint_rsh, Dynamic, 761843937)                             \
  V(_Bigint, _absAdd, Bigint_absAdd, Dynamic, 1227835493)                      \
  V(_Bigint, _absSub, Bigint_absSub, Dynamic, 390740532)                       \
  V(_Bigint, _mulAdd, Bigint_mulAdd, Dynamic, 617534446)                       \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, Dynamic, 1623635507)                      \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, Dynamic, 797340802)   \
  V(_Montgomery, _mulMod, Montgomery_mulMod, Dynamic, 1947987219)              \
  V(_Double, >, Double_greaterThan, Bool, 1453001345)                          \
  V(_Double, >=, Double_greaterEqualThan, Bool, 1815180096)                    \
  V(_Double, <, Double_lessThan, Bool, 652059836)                              \
  V(_Double, <=, Double_lessEqualThan, Bool, 512138528)                        \
  V(_Double, ==, Double_equal, Bool, 1468668497)                               \
  V(_Double, +, Double_add, Double, 1269587413)                                \
  V(_Double, -, Double_sub, Double, 1644506555)                                \
  V(_Double, *, Double_mul, Double, 600860888)                                 \
  V(_Double, /, Double_div, Double, 1220198876)                                \
  V(_Double, get:isNaN, Double_getIsNaN, Bool, 184085483)                      \
  V(_Double, get:isNegative, Double_getIsNegative, Bool, 978911030)            \
  V(_Double, _mulFromInteger, Double_mulFromInteger, Double, 856594998)        \
  V(_Double, .fromInteger, DoubleFromInteger, Double, 2129942595)              \
  V(_List, []=, ObjectArraySetIndexed, Dynamic, 886228780)                     \
  V(_GrowableList, .withData, GrowableArray_Allocate, GrowableObjectArray,     \
    631736030)                                                                 \
  V(_GrowableList, add, GrowableArray_add, Dynamic, 219371757)                 \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, Dynamic, 1614206970)          \
  V(Object, ==, ObjectEquals, Bool, 291909336)                                 \
  V(Object, get:runtimeType, ObjectRuntimeType, Type, 15188587)                \
  V(_StringBase, get:hashCode, String_getHashCode, Smi, 2026040200)            \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, Bool, 1958879178)             \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, Bool,          \
    797253099)                                                                 \
  V(_StringBase, [], StringBaseCharAt, Dynamic, 754527301)                     \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, Smi, 2026040200)  \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked, OneByteString, 1670133538)               \
  V(_OneByteString, _setAt, OneByteStringSetAt, Dynamic, 1160066031)           \
  V(_OneByteString, _allocate, OneByteString_allocate, OneByteString,          \
    1028631946)                                                                \
  V(_OneByteString, ==, OneByteString_equality, Bool, 1062844160)              \
  V(_TwoByteString, ==, TwoByteString_equality, Bool, 1062844160)              \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    Dynamic, 2042488139)                                                       \
  V(_IntegerImplementation, +, Integer_add, Dynamic, 239272130)                \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, Dynamic,  \
    957923759)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, Dynamic, 216175811)                \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    Dynamic, 2032062140)                                                       \
  V(_IntegerImplementation, *, Integer_mul, Dynamic, 1301152164)               \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    Dynamic, 779285842)                                                        \
  V(_IntegerImplementation, ~/, Integer_truncDivide, Dynamic, 1018128256)      \
  V(_IntegerImplementation, unary-, Integer_negate, Dynamic, 1507648892)       \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    Dynamic, 503046514)                                                        \
  V(_IntegerImplementation, &, Integer_bitAnd, Dynamic, 1500136766)            \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    Dynamic, 1031383580)                                                       \
  V(_IntegerImplementation, |, Integer_bitOr, Dynamic, 119412028)              \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    Dynamic, 1339506501)                                                       \
  V(_IntegerImplementation, ^, Integer_bitXor, Dynamic, 210430781)             \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, Bool, 780147656)                               \
  V(_IntegerImplementation, >, Integer_greaterThan, Bool, 673741711)           \
  V(_IntegerImplementation, ==, Integer_equal, Bool, 272474439)                \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, Bool,     \
    2004079901)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, Bool, 652059836)              \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, Bool, 512138528)        \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, Bool, 1815180096)    \
  V(_IntegerImplementation, <<, Integer_shl, Dynamic, 1127538624)              \
  V(_IntegerImplementation, >>, Integer_sar, Dynamic, 1243972513)              \
  V(_Double, toInt, DoubleToInteger, Dynamic, 653210699)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, Double, 417912310)                                     \
  V(_Random, _nextState, Random_nextState, Dynamic, 508231939)                 \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, Double, 65032)                                           \
  V(::, cos, MathCos, Double, 2006233918)                                      \
  V(::, tan, MathTan, Double, 1276867325)                                      \
  V(::, asin, MathAsin, Double, 1678592173)                                    \
  V(::, acos, MathAcos, Double, 1121218433)                                    \
  V(::, atan, MathAtan, Double, 1109653625)                                    \
  V(::, atan2, MathAtan2, Double, 894696289)                                   \

#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(Int8List, ., TypedData_Int8Array_factory, TypedDataInt8Array, 779569635)   \
  V(Uint8List, ., TypedData_Uint8Array_factory, TypedDataUint8Array,           \
    1790399545)                                                                \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory,                  \
    TypedDataUint8ClampedArray, 405875159)       \
  V(Int16List, ., TypedData_Int16Array_factory, TypedDataInt16Array,           \
    347431914)                                                                 \
  V(Uint16List, ., TypedData_Uint16Array_factory, TypedDataUint16Array,        \
    121990116)                                                                 \
  V(Int32List, ., TypedData_Int32Array_factory, TypedDataInt32Array,           \
    1540657744)                                                                \
  V(Uint32List, ., TypedData_Uint32Array_factory,                              \
    TypedDataUint32Array, 1012511652)                                          \
  V(Int64List, ., TypedData_Int64Array_factory,                                \
    TypedDataInt64Array, 1473796807)                                           \
  V(Uint64List, ., TypedData_Uint64Array_factory,                              \
    TypedDataUint64Array, 738799620)                                           \
  V(Float32List, ., TypedData_Float32Array_factory,                            \
    TypedDataFloat32Array, 1938690635)                                         \
  V(Float64List, ., TypedData_Float64Array_factory,                            \
    TypedDataFloat64Array, 1344005361)                                         \
  V(Float32x4List, ., TypedData_Float32x4Array_factory,                        \
    TypedDataFloat32x4Array, 2055067416)                                       \
  V(Int32x4List, ., TypedData_Int32x4Array_factory,                            \
    TypedDataInt32x4Array, 504220232)                                          \
  V(Float64x2List, ., TypedData_Float64x2Array_factory,                        \
    TypedDataFloat64x2Array, 416019673)                                        \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(Uint8List, [], Uint8ArrayGetIndexed, Smi, 41288685)                        \
  V(Uint8List, []=, Uint8ArraySetIndexed, Dynamic, 101536342)                  \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, Smi, 41288685)      \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, Dynamic,           \
    101536342)                                                                 \
  V(Uint32List, [], Uint32ArrayGetIndexed, Dynamic, 1614870523)                \
  V(Uint32List, []=, Uint32ArraySetIndexed, Dynamic, 978194713)                \
  V(Float64List, [], Float64ArrayGetIndexed, Double, 2049378701)               \
  V(Float64List, []=, Float64ArraySetIndexed, Dynamic, 328934501)              \
  V(_TypedList, get:length, TypedDataLength, Smi, 546364442)                   \
  V(Float32x4, get:x, Float32x4ShuffleX, Double, 1674625343)                   \
  V(Float32x4, get:y, Float32x4ShuffleY, Double, 540293915)                    \
  V(Float32x4, get:z, Float32x4ShuffleZ, Double, 320347578)                    \
  V(Float32x4, get:w, Float32x4ShuffleW, Double, 1770606624)                   \
  V(Float32x4, _mul, Float32x4Mul, Float32x4, 42807622)                        \
  V(Float32x4, _sub, Float32x4Sub, Float32x4, 103774455)                       \
  V(Float32x4, _add, Float32x4Add, Float32x4, 1352634374)                      \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, Smi, 630471378)                      \
  V(_List, [], ObjectArrayGetIndexed, Dynamic, 360400496)                      \
  V(_ImmutableList, get:length, ImmutableArrayLength, Smi, 630471378)          \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, Dynamic, 360400496)          \
  V(_GrowableList, get:length, GrowableArrayLength, Smi, 417111542)            \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, Smi, 41110914)        \
  V(_GrowableList, _setData, GrowableArraySetData, Dynamic, 210059283)         \
  V(_GrowableList, _setLength, GrowableArraySetLength, Dynamic, 335652822)     \
  V(_GrowableList, [], GrowableArrayGetIndexed, Dynamic, 1957529650)           \
  V(_GrowableList, []=, GrowableArraySetIndexed, Dynamic, 225246870)           \
  V(_StringBase, get:length, StringBaseLength, Smi, 707533587)                 \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, Smi, 1436590579)      \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, Smi, 1436590579)      \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    Smi, 1436590579)                                                           \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    Smi, 1436590579)                                                           \
  V(_Double, unary-, DoubleFlipSignBit, Double, 1783281169)                    \
  V(_Double, truncateToDouble, DoubleTruncate, Double, 791143891)              \
  V(_Double, roundToDouble, DoubleRound, Double, 797558034)                    \
  V(_Double, floorToDouble, DoubleFloor, Double, 1789426271)                   \
  V(_Double, ceilToDouble, DoubleCeil, Double, 453271198)                      \
  V(_Double, _modulo, DoubleMod, Double, 776062204)


#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, Dynamic, 187721469)            \
  V(::, _getDefaultTag, UserTag_defaultTag, Dynamic, 350077879)                \
  V(::, _getCurrentTag, Profiler_getCurrentTag, Dynamic, 1215225901)           \
  V(::, _isDartStreamEnabled, Timeline_isDartStreamEnabled, Dynamic,           \
    1072246292)                                                                \

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
  V(Object, ==, ObjectEquals, 291909336)                                       \
  V(_List, get:length, ObjectArrayLength, 630471378)                           \
  V(_ImmutableList, get:length, ImmutableArrayLength, 630471378)               \
  V(_TypedList, get:length, TypedDataLength, 546364442)                        \
  V(_GrowableList, get:length, GrowableArrayLength, 417111542)                 \
  V(_GrowableList, add, GrowableListAdd, 219371757)                            \
  V(_GrowableList, removeLast, GrowableListRemoveLast, 324891524)              \
  V(_StringBase, get:length, StringBaseLength, 707533587)                      \
  V(ListIterator, moveNext, ListIteratorMoveNext, 1065954929)                  \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 1451346178)  \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 1840323187)            \
  V(_GrowableList, forEach, GrowableArrayForEach, 620771070)                   \
  V(_List, ., ObjectArrayAllocate, 1661438741)                                 \
  V(_List, [], ObjectArrayGetIndexed, 360400496)                               \
  V(_List, []=, ObjectArraySetIndexed, 886228780)                              \
  V(ListMixin, get:isEmpty, ListMixinIsEmpty, 2021497798)                      \
  V(_List, get:iterator, ObjectArrayIterator, 295498778)                       \
  V(_List, forEach, ObjectArrayForEach, 180150673)                             \
  V(_List, _slice, ObjectArraySlice, 840558357)                                \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 295498778)           \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 180150673)                 \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 360400496)                   \
  V(_GrowableList, [], GrowableArrayGetIndexed, 1957529650)                    \
  V(_GrowableList, []=, GrowableArraySetIndexed, 225246870)                    \
  V(Float32List, [], Float32ArrayGetIndexed, 1451643535)                       \
  V(Float32List, []=, Float32ArraySetIndexed, 453873887)                       \
  V(Float64List, [], Float64ArrayGetIndexed, 2049378701)                       \
  V(Float64List, []=, Float64ArraySetIndexed, 328934501)                       \
  V(Int8List, [], Int8ArrayGetIndexed, 110819507)                              \
  V(Int8List, []=, Int8ArraySetIndexed, 865684695)                             \
  V(Uint8List, [], Uint8ArrayGetIndexed, 41288685)                             \
  V(Uint8List, []=, Uint8ArraySetIndexed, 101536342)                           \
  V(Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, 41288685)               \
  V(Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, 687206488)             \
  V(Uint16List, [], Uint16ArrayGetIndexed, 1053739567)                         \
  V(Uint16List, []=, Uint16ArraySetIndexed, 1547307961)                        \
  V(Int16List, [], Int16ArrayGetIndexed, 389863073)                            \
  V(Int16List, []=, Int16ArraySetIndexed, 855133756)                           \
  V(Int32List, [], Int32ArrayGetIndexed, 640610057)                            \
  V(Int32List, []=, Int32ArraySetIndexed, 453358705)                           \
  V(Int64List, [], Int64ArrayGetIndexed, 202150810)                            \
  V(Int64List, []=, Int64ArraySetIndexed, 924110852)                           \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 1338422227)                 \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 540212720)                 \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 302213458)                    \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 1837635160)                  \
  V(_ByteDataView, setInt8, ByteDataViewSetInt8, 660389322)                    \
  V(_ByteDataView, setUint8, ByteDataViewSetUint8, 1651986039)                 \
  V(_ByteDataView, setInt16, ByteDataViewSetInt16, 2051262146)                 \
  V(_ByteDataView, setUint16, ByteDataViewSetUint16, 1692244111)               \
  V(_ByteDataView, setInt32, ByteDataViewSetInt32, 862135882)                  \
  V(_ByteDataView, setUint32, ByteDataViewSetUint32, 361732249)                \
  V(_ByteDataView, setInt64, ByteDataViewSetInt64, 1208972197)                 \
  V(_ByteDataView, setUint64, ByteDataViewSetUint64, 1545853836)               \
  V(_ByteDataView, setFloat32, ByteDataViewSetFloat32, 1333183642)             \
  V(_ByteDataView, setFloat64, ByteDataViewSetFloat64, 1579015503)             \
  V(_ByteDataView, getInt8, ByteDataViewGetInt8, 29018237)                     \
  V(_ByteDataView, getUint8, ByteDataViewGetUint8, 312322868)                  \
  V(_ByteDataView, getInt16, ByteDataViewGetInt16, 1613243255)                 \
  V(_ByteDataView, getUint16, ByteDataViewGetUint16, 284020105)                \
  V(_ByteDataView, getInt32, ByteDataViewGetInt32, 2036535169)                 \
  V(_ByteDataView, getUint32, ByteDataViewGetUint32, 571293096)                \
  V(_ByteDataView, getInt64, ByteDataViewGetInt64, 1971181000)                 \
  V(_ByteDataView, getUint64, ByteDataViewGetUint64, 799775022)                \
  V(_ByteDataView, getFloat32, ByteDataViewGetFloat32, 947822534)              \
  V(_ByteDataView, getFloat64, ByteDataViewGetFloat64, 1402356525)             \
  V(::, asin, MathAsin, 1678592173)                                            \
  V(::, acos, MathAcos, 1121218433)                                            \
  V(::, atan, MathAtan, 1109653625)                                            \
  V(::, atan2, MathAtan2, 894696289)                                           \
  V(::, cos, MathCos, 2006233918)                                              \
  V(::, exp, MathExp, 1500946333)                                              \
  V(::, log, MathLog, 739403086)                                               \
  V(::, max, MathMax, 1410473322)                                              \
  V(::, min, MathMin, 1115051548)                                              \
  V(::, pow, MathPow, 2058759335)                                              \
  V(::, sin, MathSin, 65032)                                                   \
  V(::, sqrt, MathSqrt, 417912310)                                             \
  V(::, tan, MathTan, 1276867325)                                              \
  V(Lists, copy, ListsCopy, 564237562)                                         \
  V(_Bigint, get:_neg, Bigint_getNeg, 2079423063)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1426329619)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 1185333683)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 2104211307)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 1273697266)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 1274399923)                 \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 1611093357)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 367462469)          \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 1049390812)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 902147072)          \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 1236137630)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 812542585)    \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 1072259010)   \

// A list of core function that should never be inlined.
#define INLINE_BLACK_LIST(V)                                                   \
  V(_Bigint, _lsh, Bigint_lsh, 1557746963)                                     \
  V(_Bigint, _rsh, Bigint_rsh, 761843937)                                      \
  V(_Bigint, _absAdd, Bigint_absAdd, 1227835493)                               \
  V(_Bigint, _absSub, Bigint_absSub, 390740532)                                \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 617534446)                                \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 1623635507)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 797340802)            \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 1947987219)                       \
  V(_Double, >, Double_greaterThan, 1453001345)                                \
  V(_Double, >=, Double_greaterEqualThan, 1815180096)                          \
  V(_Double, <, Double_lessThan, 652059836)                                    \
  V(_Double, <=, Double_lessEqualThan, 512138528)                              \
  V(_Double, ==, Double_equal, 1468668497)                                     \
  V(_Double, +, Double_add, 1269587413)                                        \
  V(_Double, -, Double_sub, 1644506555)                                        \
  V(_Double, *, Double_mul, 600860888)                                         \
  V(_Double, /, Double_div, 1220198876)                                        \
  V(_IntegerImplementation, +, Integer_add, 239272130)                         \
  V(_IntegerImplementation, -, Integer_sub, 216175811)                         \
  V(_IntegerImplementation, *, Integer_mul, 1301152164)                        \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 1018128256)               \
  V(_IntegerImplementation, unary-, Integer_negate, 1507648892)                \
  V(_IntegerImplementation, &, Integer_bitAnd, 1500136766)                     \
  V(_IntegerImplementation, |, Integer_bitOr, 119412028)                       \
  V(_IntegerImplementation, ^, Integer_bitXor, 210430781)                      \
  V(_IntegerImplementation, >, Integer_greaterThan, 673741711)                 \
  V(_IntegerImplementation, ==, Integer_equal, 272474439)                      \
  V(_IntegerImplementation, <, Integer_lessThan, 652059836)                    \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 512138528)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 1815180096)          \
  V(_IntegerImplementation, <<, Integer_shl, 1127538624)                       \
  V(_IntegerImplementation, >>, Integer_sar, 1243972513)                       \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 754527301)                              \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 1508321565)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 953411007)                   \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 433971756)                   \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 1329446488)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 137212209)                   \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 499907480)                 \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 1672834581)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 966634744)               \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 1197581758)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 810805548)               \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 1317196265)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 1328908284)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 1827614958)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 1694054572)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 915652649)                   \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 1958474336)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 1853026980)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 1197862362)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 2093630771)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 1982971324)              \

// Forward declarations.
class Function;

// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class MethodRecognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name, type, fp) \
    k##enum_name,
    RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
    kNumRecognizedMethods
  };

  static Kind RecognizeKind(const Function& function);
  static bool AlwaysInline(const Function& function);
  static bool PolymorphicTarget(const Function& function);
  static intptr_t ResultCid(const Function& function);
  static const char* KindToCString(Kind kind);
#if defined(DART_NO_SNAPSHOT)
  static void InitializeState();
#endif  // defined(DART_NO_SNAPSHOT).
};


#if defined(DART_NO_SNAPSHOT)
#define CHECK_FINGERPRINT2(f, p0, p1, fp) \
  ASSERT(f.CheckSourceFingerprint(#p0 ", " #p1, fp))

#define CHECK_FINGERPRINT3(f, p0, p1, p2, fp) \
  ASSERT(f.CheckSourceFingerprint(#p0 ", " #p1 ", " #p2, fp))
#endif  // defined(DART_NO_SNAPSHOT).


// List of recognized list factories:
// (factory-name-symbol, result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, kArrayCid, 1661438741)                                       \
  V(_GrowableListWithData, kGrowableObjectArrayCid, 631736030)                 \
  V(_GrowableListFactory, kGrowableObjectArrayCid, 1330464656)                 \
  V(_Int8ArrayFactory, kTypedDataInt8ArrayCid, 779569635)                      \
  V(_Uint8ArrayFactory, kTypedDataUint8ArrayCid, 1790399545)                   \
  V(_Uint8ClampedArrayFactory, kTypedDataUint8ClampedArrayCid, 405875159)      \
  V(_Int16ArrayFactory, kTypedDataInt16ArrayCid, 347431914)                    \
  V(_Uint16ArrayFactory, kTypedDataUint16ArrayCid, 121990116)                  \
  V(_Int32ArrayFactory, kTypedDataInt32ArrayCid, 1540657744)                   \
  V(_Uint32ArrayFactory, kTypedDataUint32ArrayCid, 1012511652)                 \
  V(_Int64ArrayFactory, kTypedDataInt64ArrayCid, 1473796807)                   \
  V(_Uint64ArrayFactory, kTypedDataUint64ArrayCid, 738799620)                  \
  V(_Float64ArrayFactory, kTypedDataFloat64ArrayCid, 1344005361)               \
  V(_Float32ArrayFactory, kTypedDataFloat32ArrayCid, 1938690635)               \
  V(_Float32x4ArrayFactory, kTypedDataFloat32x4ArrayCid, 2055067416)           \


// Class that recognizes factories and returns corresponding result cid.
class FactoryRecognizer : public AllStatic {
 public:
  // Return kDynamicCid if factory is not recognized.
  static intptr_t ResultCid(const Function& factory);
};

}  // namespace dart

#endif  // VM_METHOD_RECOGNIZER_H_
