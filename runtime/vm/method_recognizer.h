// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_METHOD_RECOGNIZER_H_
#define VM_METHOD_RECOGNIZER_H_

#include "vm/allocation.h"

namespace dart {

// (class-name, function-name, recognized enum, fingerprint).
// When adding a new function add a 0 as fingerprint, build and run to get the
// correct fingerprint from the mismatch error.
#define OTHER_RECOGNIZED_LIST(V)                                               \
  V(::, identical, ObjectIdentical, 554128144)                                 \
  V(ClassID, getID, ClassIDgetID, 535124072)                                   \
  V(Object, Object., ObjectConstructor, 1066759160)                            \
  V(_List, ., ObjectArrayAllocate, 850375012)                                  \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 1541411498)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 1032404349)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 381073990)                   \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 1142676276)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 330269934)                   \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 59490554)                  \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 322272622)                   \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 393003933)               \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 1792407200)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 1338379857)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 1469917805)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 1892735922)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 1608794041)                  \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 117380972)                   \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 200484754)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 1020151991)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 1175056602)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 784983863)                   \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 460607665)               \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 284787790)               \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 262426120)           \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 613041888)               \
  V(_StringBase, _interpolate, StringBaseInterpolate, 1214901263)              \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 826404440)              \
  V(_IntegerImplementation, _leftShiftWithMask32,                              \
      IntegerLeftShiftWithMask32, 598958097)                                   \
  V(_Double, truncateToDouble, DoubleTruncate, 2117801967)                     \
  V(_Double, roundToDouble, DoubleRound, 2124216110)                           \
  V(_Double, floorToDouble, DoubleFloor, 968600699)                            \
  V(_Double, ceilToDouble, DoubleCeil, 1779929274)                             \
  V(_Double, _modulo, DoubleMod, 1473971007)                                   \
  V(_Double, _add, DoubleAdd, 1570715125)                                      \
  V(_Double, _sub, DoubleSub, 1466395310)                                      \
  V(_Double, _mul, DoubleMul, 546441193)                                       \
  V(_Double, _div, DoubleDiv, 1201505037)                                      \
  V(::, sin, MathSin, 1741396147)                                              \
  V(::, cos, MathCos, 1951197905)                                              \
  V(::, min, MathMin, 478627534)                                               \
  V(::, max, MathMax, 212291192)                                               \
  V(::, _doublePow, MathDoublePow, 1286501289)                                 \
  V(Float32x4, Float32x4., Float32x4Constructor, 1413513587)                   \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 865663495)                       \
  V(Float32x4, Float32x4.splat, Float32x4Splat, 964312836)                     \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits, 688177588) \
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, 1327692716)    \
  V(_Float32x4, shuffle, Float32x4Shuffle, 1636488139)                         \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, 654814229)                    \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, 630880675)                 \
  V(_Float32x4, _cmpequal, Float32x4Equal, 571062952)                          \
  V(_Float32x4, _cmpgt, Float32x4GreaterThan, 1613543295)                      \
  V(_Float32x4, _cmpgte, Float32x4GreaterThanOrEqual, 589402909)               \
  V(_Float32x4, _cmplt, Float32x4LessThan, 1502332656)                         \
  V(_Float32x4, _cmplte, Float32x4LessThanOrEqual, 1069848031)                 \
  V(_Float32x4, _cmpnequal, Float32x4NotEqual, 1334574472)                     \
  V(_Float32x4, _min, Float32x4Min, 2036349551)                                \
  V(_Float32x4, _max, Float32x4Max, 571688115)                                 \
  V(_Float32x4, _scale, Float32x4Scale, 1311297761)                            \
  V(_Float32x4, _sqrt, Float32x4Sqrt, 1709659395)                              \
  V(_Float32x4, _reciprocalSqrt, Float32x4ReciprocalSqrt, 2043980962)          \
  V(_Float32x4, _reciprocal, Float32x4Reciprocal, 739405237)                   \
  V(_Float32x4, _negate, Float32x4Negate, 445839777)                           \
  V(_Float32x4, _abs, Float32x4Absolute, 1152777608)                           \
  V(_Float32x4, _clamp, Float32x4Clamp, 410673744)                             \
  V(_Float32x4, withX, Float32x4WithX, 1446546696)                             \
  V(_Float32x4, withY, Float32x4WithY, 309844761)                              \
  V(_Float32x4, withZ, Float32x4WithZ, 971921505)                              \
  V(_Float32x4, withW, Float32x4WithW, 1759699726)                             \
  V(Float64x2, Float64x2., Float64x2Constructor, 1047027504)                   \
  V(Float64x2, Float64x2.zero, Float64x2Zero, 1208364703)                      \
  V(Float64x2, Float64x2.splat, Float64x2Splat, 987392531)                     \
  V(Float64x2, Float64x2.fromFloat32x4, Float64x2FromFloat32x4, 1547827778)    \
  V(_Float64x2, get:x, Float64x2GetX, 261163258)                               \
  V(_Float64x2, get:y, Float64x2GetY, 1942377050)                              \
  V(_Float64x2, _negate, Float64x2Negate, 2133212774)                          \
  V(_Float64x2, abs, Float64x2Abs, 1224776282)                                 \
  V(_Float64x2, sqrt, Float64x2Sqrt, 1037569520)                               \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, 253055964)                 \
  V(_Float64x2, scale, Float64x2Scale, 1199438744)                             \
  V(_Float64x2, withX, Float64x2WithX, 1042725932)                             \
  V(_Float64x2, withY, Float64x2WithY, 1496958947)                             \
  V(_Float64x2, min, Float64x2Min, 485240583)                                  \
  V(_Float64x2, max, Float64x2Max, 2146148204)                                 \
  V(Int32x4, Int32x4., Int32x4Constructor, 323626792)                          \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, 637206368)                  \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Int32x4FromFloat32x4Bits, 420618790)   \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, 1077674402)                          \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, 779279448)                           \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, 182031447)                           \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, 977794698)                           \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, 1929391078)                    \
  V(_Int32x4, shuffle, Int32x4Shuffle, 1870018702)                             \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, 1024903172)                       \
  V(_Int32x4, select, Int32x4Select, 1638081645)                               \
  V(_Int32x4, withFlagX, Int32x4WithFlagX, 467852789)                          \
  V(_Int32x4, withFlagY, Int32x4WithFlagY, 1903359978)                         \
  V(_Int32x4, withFlagZ, Int32x4WithFlagZ, 862460960)                          \
  V(_Int32x4, withFlagW, Int32x4WithFlagW, 1095242907)                         \
  V(_Float32Array, [], Float32ArrayGetIndexed, 321832479)                      \
  V(_Float32Array, []=, Float32ArraySetIndexed, 979306169)                     \
  V(_Int8Array, [], Int8ArrayGetIndexed, 1390782783)                           \
  V(_Int8Array, []=, Int8ArraySetIndexed, 1774152196)                          \
  V(_Uint8ClampedArray, [], Uint8ClampedArrayGetIndexed, 1297457028)           \
  V(_Uint8ClampedArray, []=, Uint8ClampedArraySetIndexed, 2018722539)          \
  V(_ExternalUint8ClampedArray, [],                                            \
      ExternalUint8ClampedArrayGetIndexed, 1871828532)                         \
  V(_ExternalUint8ClampedArray, []=,                                           \
      ExternalUint8ClampedArraySetIndexed, 1746834469)                         \
  V(_Int16Array, [], Int16ArrayGetIndexed, 1699340532)                         \
  V(_Int16Array, []=, Int16ArraySetIndexed, 799870496)                         \
  V(_Uint16Array, [], Uint16ArrayGetIndexed, 452576118)                        \
  V(_Uint16Array, []=, Uint16ArraySetIndexed, 1594961463)                      \
  V(_Int32Array, [], Int32ArrayGetIndexed, 2052925823)                         \
  V(_Int32Array, []=, Int32ArraySetIndexed, 504626978)                         \
  V(_Int64Array, [], Int64ArrayGetIndexed, 297668331)                          \
  V(_Int64Array, []=, Int64ArraySetIndexed, 36465128)                          \
  V(_Float32x4Array, [], Float32x4ArrayGetIndexed, 35821240)                   \
  V(_Float32x4Array, []=, Float32x4ArraySetIndexed, 428758949)                 \
  V(_Int32x4Array, [], Int32x4ArrayGetIndexed, 1830534333)                     \
  V(_Int32x4Array, []=, Int32x4ArraySetIndexed, 1631676655)                    \
  V(_Float64x2Array, [], Float64x2ArrayGetIndexed, 1860837505)                 \
  V(_Float64x2Array, []=, Float64x2ArraySetIndexed, 821269609)                 \
  V(_Bigint, get:_neg, Bigint_getNeg, 1151633263)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1308648707)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 1408181836)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 1431607529)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 2007926178)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 958070909)                  \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 1134236592)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 421669312)          \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 1152062737)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 969476186)          \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 1781420082)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 63633039)     \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 2079107858)   \


// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 221883538)                                         \
  V(_Smi, get:bitLength, Smi_bitLength, 870075661)                             \
  V(_Bigint, _lsh, Bigint_lsh, 1457834861)                                     \
  V(_Bigint, _rsh, Bigint_rsh, 1619318930)                                     \
  V(_Bigint, _absAdd, Bigint_absAdd, 1029882563)                               \
  V(_Bigint, _absSub, Bigint_absSub, 1407667556)                               \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 1408994809)                               \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 2025116181)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 919247767)            \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 401580778)                        \
  V(_Double, >, Double_greaterThan, 1329424300)                                \
  V(_Double, >=, Double_greaterEqualThan, 805805707)                           \
  V(_Double, <, Double_lessThan, 1504529159)                                   \
  V(_Double, <=, Double_lessEqualThan, 1650247787)                             \
  V(_Double, ==, Double_equal, 1107327662)                                     \
  V(_Double, +, Double_add, 957499569)                                         \
  V(_Double, -, Double_sub, 788608394)                                         \
  V(_Double, *, Double_mul, 645729895)                                         \
  V(_Double, /, Double_div, 1249186273)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 843169197)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 1637994744)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 63390017)                 \
  V(_Double, .fromInteger, DoubleFromInteger, 213717920)                       \
  V(_List, []=, ObjectArraySetIndexed, 527521746)                              \
  V(_GrowableList, .withData, GrowableArray_Allocate, 2094352700)              \
  V(_GrowableList, add, GrowableArray_add, 1675959698)                         \
  V(_JSSyntaxRegExp, _ExecuteMatch, JSRegExp_ExecuteMatch, 1711509198)         \
  V(Object, ==, ObjectEquals, 409406570)                                       \
  V(Object, get:runtimeType, ObjectRuntimeType, 2076963579)                    \
  V(_StringBase, get:hashCode, String_getHashCode, 2103025405)                 \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 780870414)                    \
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 397735324)                  \
  V(_StringBase, [], StringBaseCharAt, 408544820)                              \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 1111957093)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 1584757277)                            \
  V(_OneByteString, _setAt, OneByteStringSetAt, 1927993207)                    \
  V(_OneByteString, _allocate, OneByteString_allocate, 1248050114)             \
  V(_OneByteString, ==, OneByteString_equality, 1151307249)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 375409915)                     \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    438687793)                                                                 \
  V(_IntegerImplementation, +, Integer_add, 6890122)                           \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    562800077)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, 1325066635)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    67891834)                                                                  \
  V(_IntegerImplementation, *, Integer_mul, 1293507180)                        \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    93478264)                                                                  \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 1401079912)               \
  V(_IntegerImplementation, unary-, Integer_negate, 1992904169)                \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 504496713)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 154523381)                      \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 1763728073)                                      \
  V(_IntegerImplementation, |, Integer_bitOr, 979400883)                       \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 281425907)                                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 1753100628)                     \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 787426822)                                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 871319346)                 \
  V(_IntegerImplementation, ==, Integer_equal, 150126631)                      \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    1790821042)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 1997184951)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 909274395)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 64832315)            \
  V(_IntegerImplementation, <<, Integer_shl, 162043543)                        \
  V(_IntegerImplementation, >>, Integer_sar, 2140866840)                       \
  V(_Double, toInt, DoubleToInteger, 1547535151)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, 101545548)                                             \
  V(_Random, _nextState, Random_nextState, 170407315)                          \


#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(_Int8Array, _new, TypedData_Int8Array_new, 362764911)                      \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 1232298852)                   \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 2086529408)     \
  V(_Int16Array, _new, TypedData_Int16Array_new, 1092174107)                   \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 1549613141)                 \
  V(_Int32Array, _new, TypedData_Int32Array_new, 937960140)                    \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 1370423225)                 \
  V(_Int64Array, _new, TypedData_Int64Array_new, 512135010)                    \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 847951795)                  \
  V(_Float32Array, _new, TypedData_Float32Array_new, 1937854220)               \
  V(_Float64Array, _new, TypedData_Float64Array_new, 2005472426)               \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 1956756158)           \
  V(_Int32x4Array, _new, TypedData_Int32x4Array_new, 1856474973)               \
  V(_Float64x2Array, _new, TypedData_Float64x2Array_new, 719608172)            \
  V(_Int8Array, ., TypedData_Int8Array_factory, 439914696)                     \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 1442599030)                  \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 1320015159)    \
  V(_Int16Array, ., TypedData_Int16Array_factory, 2132591678)                  \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 1704816032)                \
  V(_Int32Array, ., TypedData_Int32Array_factory, 1115045147)                  \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 1385852190)                \
  V(_Int64Array, ., TypedData_Int64Array_factory, 1193438555)                  \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 410766246)                 \
  V(_Float32Array, ., TypedData_Float32Array_factory, 1194249144)              \
  V(_Float64Array, ., TypedData_Float64Array_factory, 1430631000)              \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 158753569)           \
  V(_Int32x4Array, ., TypedData_Int32x4Array_factory, 1189213641)              \
  V(_Float64x2Array, ., TypedData_Float64x2Array_factory, 1699696799)          \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V) \
  V(_Uint8Array, [], Uint8ArrayGetIndexed, 579862489)                          \
  V(_Uint8Array, []=, Uint8ArraySetIndexed, 447309008)                         \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 1293647140)         \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 1593599192)        \
  V(_Uint32Array, [], Uint32ArrayGetIndexed, 1034114777)                       \
  V(_Uint32Array, []=, Uint32ArraySetIndexed, 918159348)                       \
  V(_Float64Array, []=, Float64ArraySetIndexed, 887301703)                     \
  V(_Float64Array, [], Float64ArrayGetIndexed, 1959896670)                     \
  V(_TypedList, get:length, TypedDataLength, 522684521)                        \
  V(_Float32x4, get:x, Float32x4ShuffleX, 384969722)                           \
  V(_Float32x4, get:y, Float32x4ShuffleY, 1398121942)                          \
  V(_Float32x4, get:z, Float32x4ShuffleZ, 1178175605)                          \
  V(_Float32x4, get:w, Float32x4ShuffleW, 480951003)                           \
  V(_Float32x4, _mul, Float32x4Mul, 1703784673)                                \
  V(_Float32x4, _sub, Float32x4Sub, 1302598822)                                \
  V(_Float32x4, _add, Float32x4Add, 182344215)                                 \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, 1181471893)                          \
  V(_List, [], ObjectArrayGetIndexed, 1839430267)                              \
  V(_ImmutableList, get:length, ImmutableArrayLength, 275036891)               \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 886511484)                   \
  V(_GrowableList, get:length, GrowableArrayLength, 778624271)                 \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 555259239)            \
  V(_GrowableList, _setData, GrowableArraySetData, 508234257)                  \
  V(_GrowableList, _setLength, GrowableArraySetLength, 618179695)              \
  V(_GrowableList, [], GrowableArrayGetIndexed, 1962926024)                    \
  V(_GrowableList, []=, GrowableArraySetIndexed, 457344024)                    \
  V(_StringBase, get:length, StringBaseLength, 784518792)                      \
  V(_Double, unary-, DoubleFlipSignBit, 2107492213)

#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, 788201614)                     \
  V(::, _getDefaultTag, UserTag_defaultTag, 1080704381)                        \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 2048029229)                    \

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
  V(Object, ==, ObjectEquals, 409406570)                                       \
  V(_List, get:length, ObjectArrayLength, 1181471893)                          \
  V(_ImmutableList, get:length, ImmutableArrayLength, 275036891)               \
  V(_TypedList, get:length, TypedDataLength, 522684521)                        \
  V(_GrowableList, get:length, GrowableArrayLength, 778624271)                 \
  V(_GrowableList, add, GrowableListAdd, 1675959698)                           \
  V(_GrowableList, removeLast, GrowableListRemoveLast, 1687341910)             \
  V(_StringBase, get:length, StringBaseLength, 784518792)                      \
  V(ListIterator, moveNext, ListIteratorMoveNext, 1698922708)                  \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 53548649)    \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 830391682)             \
  V(_GrowableList, forEach, GrowableArrayForEach, 792224678)                   \
  V(_List, ., ObjectArrayAllocate, 850375012)                                  \
  V(_List, [], ObjectArrayGetIndexed, 1839430267)                              \
  V(_List, []=, ObjectArraySetIndexed, 527521746)                              \
  V(ListMixin, get:isEmpty, ListMixinIsEmpty, 40656674)                        \
  V(_List, get:iterator, ObjectArrayIterator, 1623553799)                      \
  V(_List, forEach, ObjectArrayForEach, 1840334181)                            \
  V(_List, _slice, ObjectArraySlice, 1370223553)                               \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 1527026181)          \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 1311466789)                \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 886511484)                   \
  V(_GrowableList, [], GrowableArrayGetIndexed, 1962926024)                    \
  V(_GrowableList, []=, GrowableArraySetIndexed, 457344024)                    \
  V(_Float32Array, [], Float32ArrayGetIndexed, 321832479)                      \
  V(_Float32Array, []=, Float32ArraySetIndexed, 979306169)                     \
  V(_Float64Array, [], Float64ArrayGetIndexed, 1959896670)                     \
  V(_Float64Array, []=, Float64ArraySetIndexed, 887301703)                     \
  V(_Int8Array, [], Int8ArrayGetIndexed, 1390782783)                           \
  V(_Int8Array, []=, Int8ArraySetIndexed, 1774152196)                          \
  V(_Uint8Array, [], Uint8ArrayGetIndexed, 579862489)                          \
  V(_Uint8Array, []=, Uint8ArraySetIndexed, 447309008)                         \
  V(_Uint8ClampedArray, [], Uint8ClampedArrayGetIndexed, 1297457028)           \
  V(_Uint8ClampedArray, []=, Uint8ClampedArraySetIndexed, 2018722539)          \
  V(_Uint16Array, [], Uint16ArrayGetIndexed, 452576118)                        \
  V(_Uint16Array, []=, Uint16ArraySetIndexed, 1594961463)                      \
  V(_Int16Array, [], Int16ArrayGetIndexed, 1699340532)                         \
  V(_Int16Array, []=, Int16ArraySetIndexed, 799870496)                         \
  V(_Int32Array, [], Int32ArrayGetIndexed, 2052925823)                         \
  V(_Int32Array, []=, Int32ArraySetIndexed, 504626978)                         \
  V(_Int64Array, [], Int64ArrayGetIndexed, 297668331)                          \
  V(_Int64Array, []=, Int64ArraySetIndexed, 36465128)                          \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 662241408)                  \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 1550171024)                \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 875752635)                    \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 689961281)                   \
  V(_ByteDataView, setInt8, ByteDataViewSetInt8, 1039277590)                   \
  V(_ByteDataView, setUint8, ByteDataViewSetUint8, 497316431)                  \
  V(_ByteDataView, setInt16, ByteDataViewSetInt16, 27520778)                   \
  V(_ByteDataView, setUint16, ByteDataViewSetUint16, 1543151983)               \
  V(_ByteDataView, setInt32, ByteDataViewSetInt32, 535913934)                  \
  V(_ByteDataView, setUint32, ByteDataViewSetUint32, 596009393)                \
  V(_ByteDataView, setInt64, ByteDataViewSetInt64, 787812783)                  \
  V(_ByteDataView, setUint64, ByteDataViewSetUint64, 1078002910)               \
  V(_ByteDataView, setFloat32, ByteDataViewSetFloat32, 2098528020)             \
  V(_ByteDataView, setFloat64, ByteDataViewSetFloat64, 659619201)              \
  V(_ByteDataView, getInt8, ByteDataViewGetInt8, 2117136369)                   \
  V(_ByteDataView, getUint8, ByteDataViewGetUint8, 298860761)                  \
  V(_ByteDataView, getInt16, ByteDataViewGetInt16, 975961124)                  \
  V(_ByteDataView, getUint16, ByteDataViewGetUint16, 1503060990)               \
  V(_ByteDataView, getInt32, ByteDataViewGetInt32, 1096620023)                 \
  V(_ByteDataView, getUint32, ByteDataViewGetUint32, 1698446167)               \
  V(_ByteDataView, getInt64, ByteDataViewGetInt64, 1950535797)                 \
  V(_ByteDataView, getUint64, ByteDataViewGetUint64, 786884343)                \
  V(_ByteDataView, getFloat32, ByteDataViewGetFloat32, 889064264)              \
  V(_ByteDataView, getFloat64, ByteDataViewGetFloat64, 1577605354)             \
  V(::, asin, MathASin, 1651042633)                                            \
  V(::, acos, MathACos, 1139647090)                                            \
  V(::, atan, MathATan, 1668754384)                                            \
  V(::, atan2, MathATan2, 1931713076)                                          \
  V(::, cos, MathCos, 1951197905)                                              \
  V(::, exp, MathExp, 1809210829)                                              \
  V(::, log, MathLog, 1620336448)                                              \
  V(::, max, MathMax, 212291192)                                               \
  V(::, min, MathMin, 478627534)                                               \
  V(::, pow, MathPow, 582475257)                                               \
  V(::, sin, MathSin, 1741396147)                                              \
  V(::, sqrt, MathSqrt, 101545548)                                             \
  V(::, tan, MathTan, 982072809)                                               \
  V(Lists, copy, ListsCopy, 618211805)                                         \
  V(_Bigint, get:_neg, Bigint_getNeg, 1151633263)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1308648707)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 1408181836)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 1431607529)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 2007926178)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 958070909)                  \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 1134236592)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 421669312)          \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 1152062737)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 969476186)          \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 1781420082)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 63633039)     \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 2079107858)   \
  V(Uint8List, ., Uint8ListFactory, 1844890525)                                \
  V(Int8List, ., Int8ListFactory, 1802068996)                                  \
  V(Uint16List, ., Uint16ListFactory, 1923962567)                              \
  V(Int16List, ., Int16ListFactory, 2000007495)                                \
  V(Uint32List, ., Uint32ListFactory, 1836019363)                              \
  V(Int32List, ., Int32ListFactory, 442847136)                                 \
  V(Uint64List, ., Uint64ListFactory, 196248223)                               \
  V(Int64List, ., Int64ListFactory, 1668869084)                                \
  V(Float32List, ., Float32ListFactory, 1367032554)                            \
  V(Float64List, ., Float64ListFactory, 1886443347)                            \
  V(Int32x4List, ., Int32x4ListFactory, 1409401969)                            \
  V(Float32x4List, ., Float32x4ListFactory, 556438009)                         \
  V(Float64x2List, ., Float64x2ListFactory, 1269752759)


// A list of core function that should never be inlined.
#define INLINE_BLACK_LIST(V)                                                   \
  V(_Bigint, _lsh, Bigint_lsh, 1457834861)                                     \
  V(_Bigint, _rsh, Bigint_rsh, 1619318930)                                     \
  V(_Bigint, _absAdd, Bigint_absAdd, 1029882563)                               \
  V(_Bigint, _absSub, Bigint_absSub, 1407667556)                               \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 1408994809)                               \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 2025116181)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 919247767)            \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 401580778)                        \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 408544820)                              \
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 397735324)                  \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 1541411498)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 1032404349)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 381073990)                   \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 1142676276)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 330269934)                   \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 59490554)                  \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 393003933)               \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 1792407200)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 1338379857)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 1469917805)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 1892735922)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 1608794041)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 117380972)                   \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 200484754)                  \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 1020151991)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 1175056602)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 460607665)               \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 284787790)               \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 262426120)           \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 613041888)               \

// Forward declarations.
class Function;

// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class MethodRecognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name, fp) k##enum_name,
RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
    kNumRecognizedMethods
  };

  static Kind RecognizeKind(const Function& function);
  static bool AlwaysInline(const Function& function);
  static bool PolymorphicTarget(const Function& function);
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
  V(_ListFactory, kArrayCid, 850375012)                                        \
  V(_GrowableListWithData, kGrowableObjectArrayCid, 2094352700)                \
  V(_GrowableListFactory, kGrowableObjectArrayCid, 1518848600)                 \
  V(_Int8ArrayFactory, kTypedDataInt8ArrayCid, 439914696)                      \
  V(_Uint8ArrayFactory, kTypedDataUint8ArrayCid, 1442599030)                   \
  V(_Uint8ClampedArrayFactory, kTypedDataUint8ClampedArrayCid, 1320015159)     \
  V(_Int16ArrayFactory, kTypedDataInt16ArrayCid, 2132591678)                   \
  V(_Uint16ArrayFactory, kTypedDataUint16ArrayCid, 1704816032)                 \
  V(_Int32ArrayFactory, kTypedDataInt32ArrayCid, 1115045147)                   \
  V(_Uint32ArrayFactory, kTypedDataUint32ArrayCid, 1385852190)                 \
  V(_Int64ArrayFactory, kTypedDataInt64ArrayCid, 1193438555)                   \
  V(_Uint64ArrayFactory, kTypedDataUint64ArrayCid, 410766246)                  \
  V(_Float64ArrayFactory, kTypedDataFloat64ArrayCid, 1430631000)               \
  V(_Float32ArrayFactory, kTypedDataFloat32ArrayCid, 1194249144)               \
  V(_Float32x4ArrayFactory, kTypedDataFloat32x4ArrayCid, 158753569)            \


// Class that recognizes factories and returns corresponding result cid.
class FactoryRecognizer : public AllStatic {
 public:
  // Return kDynamicCid if factory is not recognized.
  static intptr_t ResultCid(const Function& factory);
};

}  // namespace dart

#endif  // VM_METHOD_RECOGNIZER_H_
