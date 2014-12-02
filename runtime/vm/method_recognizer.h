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
  V(::, identical, ObjectIdentical, 496869842)                                 \
  V(ClassID, getID, ClassIDgetID, 1662520165)                                  \
  V(Object, Object., ObjectConstructor, 1066669787)                            \
  V(_List, ., ObjectArrayAllocate, 335347617)                                  \
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
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 783880753)                     \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 499938872)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 1156009451)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 1239113233)                \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 2058780470)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 66201433)                  \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 1823612342)                  \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 1499236144)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 1323416269)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 1301054599)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 1651670367)              \
  V(_StringBase, _interpolate, StringBaseInterpolate, 1503544722)              \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 1020333941)             \
  V(_IntegerImplementation, _leftShiftWithMask32, IntegerLeftShiftWithMask32,  \
      597111055)                                                               \
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
  V(::, min, MathMin, 214919172)                                               \
  V(::, max, MathMax, 989552054)                                               \
  V(::, _doublePow, MathDoublePow, 275712742)                                  \
  V(Float32x4, Float32x4., Float32x4Constructor, 137170840)                    \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 1336967908)                      \
  V(Float32x4, Float32x4.splat, Float32x4Splat, 2001978631)                    \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits,            \
      1725843383)                                                              \
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, 217874863)     \
  V(_Float32x4, shuffle, Float32x4Shuffle, 1636488139)                         \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, 597555927)                    \
  V(_Float32x4, get:x, Float32x4ShuffleX, 384880349)                           \
  V(_Float32x4, get:y, Float32x4ShuffleY, 1398032569)                          \
  V(_Float32x4, get:z, Float32x4ShuffleZ, 1178086232)                          \
  V(_Float32x4, get:w, Float32x4ShuffleW, 480861630)                           \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, 630791302)                 \
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
  V(_Float32x4, _clamp, Float32x4Clamp, 353415442)                             \
  V(_Float32x4, withX, Float32x4WithX, 1446546696)                             \
  V(_Float32x4, withY, Float32x4WithY, 309844761)                              \
  V(_Float32x4, withZ, Float32x4WithZ, 971921505)                              \
  V(_Float32x4, withW, Float32x4WithW, 1759699726)                             \
  V(Float64x2, Float64x2., Float64x2Constructor, 490465873)                    \
  V(Float64x2, Float64x2.zero, Float64x2Zero, 1679669116)                      \
  V(Float64x2, Float64x2.splat, Float64x2Splat, 2025058326)                    \
  V(Float64x2, Float64x2.fromFloat32x4, Float64x2FromFloat32x4, 438009925)     \
  V(_Float64x2, get:x, Float64x2GetX, 261073885)                               \
  V(_Float64x2, get:y, Float64x2GetY, 1942287677)                              \
  V(_Float64x2, _negate, Float64x2Negate, 2133212774)                          \
  V(_Float64x2, abs, Float64x2Abs, 1224776282)                                 \
  V(_Float64x2, sqrt, Float64x2Sqrt, 1037569520)                               \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, 252966591)                 \
  V(_Float64x2, scale, Float64x2Scale, 1199438744)                             \
  V(_Float64x2, withX, Float64x2WithX, 1042725932)                             \
  V(_Float64x2, withY, Float64x2WithY, 1496958947)                             \
  V(_Float64x2, min, Float64x2Min, 485240583)                                  \
  V(_Float64x2, max, Float64x2Max, 2146148204)                                 \
  V(Int32x4, Int32x4., Int32x4Constructor, 1194767693)                         \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, 1052882565)                 \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Int32x4FromFloat32x4Bits,              \
      1458284585)                                                              \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, 1077585029)                          \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, 779190075)                           \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, 181942074)                           \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, 977705325)                           \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, 1929301705)                    \
  V(_Int32x4, shuffle, Int32x4Shuffle, 1870018702)                             \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, 967644870)                        \
  V(_Int32x4, select, Int32x4Select, 1291364368)                               \
  V(_Int32x4, withFlagX, Int32x4WithFlagX, 467852789)                          \
  V(_Int32x4, withFlagY, Int32x4WithFlagY, 1903359978)                         \
  V(_Int32x4, withFlagZ, Int32x4WithFlagZ, 862460960)                          \
  V(_Int32x4, withFlagW, Int32x4WithFlagW, 1095242907)                         \
  V(_Float32Array, [], Float32ArrayGetIndexed, 1092936601)                     \
  V(_Float32Array, []=, Float32ArraySetIndexed, 102284991)                     \
  V(_Int8Array, [], Int8ArrayGetIndexed, 557513849)                            \
  V(_Int8Array, []=, Int8ArraySetIndexed, 1135113150)                          \
  V(_Uint8ClampedArray, [], Uint8ClampedArrayGetIndexed, 666955326)            \
  V(_Uint8ClampedArray, []=, Uint8ClampedArraySetIndexed, 2053292453)          \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    1582819566)                                                                \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    879363679)                                                                 \
  V(_Int16Array, [], Int16ArrayGetIndexed, 310411118)                          \
  V(_Int16Array, []=, Int16ArraySetIndexed, 694766810)                         \
  V(_Uint16Array, [], Uint16ArrayGetIndexed, 706695216)                        \
  V(_Uint16Array, []=, Uint16ArraySetIndexed, 733443505)                       \
  V(_Int32Array, [], Int32ArrayGetIndexed, 439384633)                          \
  V(_Int32Array, []=, Int32ArraySetIndexed, 1570966684)                        \
  V(_Uint32Array, [], Uint32ArrayGetIndexed, 1876956115)                       \
  V(_Uint32Array, []=, Uint32ArraySetIndexed, 557491182)                       \
  V(_Int64Array, [], Int64ArrayGetIndexed, 443139045)                          \
  V(_Int64Array, []=, Int64ArraySetIndexed, 342796642)                         \
  V(_Float32x4Array, [], Float32x4ArrayGetIndexed, 1702910322)                 \
  V(_Float32x4Array, []=, Float32x4ArraySetIndexed, 157778603)                 \
  V(_Int32x4Array, [], Int32x4ArrayGetIndexed, 1055075319)                     \
  V(_Int32x4Array, []=, Int32x4ArraySetIndexed, 1185076213)                    \
  V(_Float64x2Array, [], Float64x2ArrayGetIndexed, 524397755)                  \
  V(_Float64x2Array, []=, Float64x2ArraySetIndexed, 1105348911)                \
  V(_Bigint, get:_neg, Bigint_getNeg, 1151543890)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1308559334)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 1408092463)                        \

// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 134149043)                                         \
  V(_Smi, get:bitLength, Smi_bitLength, 869986288)                             \
  V(_Bigint, set:_neg, Bigint_setNeg, 1924982939)                              \
  V(_Bigint, set:_used, Bigint_setUsed, 1574448752)                            \
  V(_Bigint, _set_digits, Bigint_setDigits, 1865626071)                        \
  V(_Bigint, _absAdd, Bigint_absAdd, 97148049)                                 \
  V(_Bigint, _absSub, Bigint_absSub, 159012285)                                \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 101252203)                                \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 1684445648)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 649845040)            \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 1551846228)                       \
  V(_Double, >, Double_greaterThan, 1538121903)                                \
  V(_Double, >=, Double_greaterEqualThan, 1058495718)                          \
  V(_Double, <, Double_lessThan, 62910596)                                     \
  V(_Double, <=, Double_lessEqualThan, 1902937798)                             \
  V(_Double, ==, Double_equal, 793601203)                                      \
  V(_Double, +, Double_add, 655662995)                                         \
  V(_Double, -, Double_sub, 486771820)                                         \
  V(_Double, *, Double_mul, 343893321)                                         \
  V(_Double, /, Double_div, 947349699)                                         \
  V(_Double, get:isNaN, Double_getIsNaN, 843079824)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 1637905371)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 1748815298)               \
  V(_Double, .fromInteger, DoubleFromInteger, 803258435)                       \
  V(_List, []=, ObjectArraySetIndexed, 1768442583)                             \
  V(_GrowableList, .withData, GrowableArray_Allocate, 536409567)               \
  V(_GrowableList, [], GrowableArrayGetIndexed, 514434920)                     \
  V(_GrowableList, []=, GrowableArraySetIndexed, 1698264861)                   \
  V(_GrowableList, _setLength, GrowableArraySetLength, 1832199634)             \
  V(_GrowableList, _setData, GrowableArraySetData, 1722254196)                 \
  V(_GrowableList, add, GrowableArray_add, 422087403)                          \
  V(_JSSyntaxRegExp, _ExecuteMatch, JSRegExp_ExecuteMatch, 1654250896)         \
  V(Object, ==, ObjectEquals, 1955975370)                                      \
  V(_StringBase, get:hashCode, String_getHashCode, 2102936032)                 \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 769493198)                    \
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 397735324)                  \
  V(_StringBase, [], StringBaseCharAt, 1107537364)                             \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 1111867720)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 1527498975)                            \
  V(_OneByteString, _setAt, OneByteStringSetAt, 819138038)                     \
  V(_OneByteString, _allocate, OneByteString_allocate, 227962559)              \
  V(_OneByteString, ==, OneByteString_equality, 1857083054)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 1081185720)                    \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    438687793)                                                                 \
  V(_IntegerImplementation, +, Integer_add, 1324179652)                        \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    562800077)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, 494872517)                         \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    67891834)                                                                  \
  V(_IntegerImplementation, *, Integer_mul, 463313062)                         \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    93478264)                                                                  \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 300412283)                \
  V(_IntegerImplementation, unary-, Integer_negate, 1899613736)                \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 504496713)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 1471812911)                     \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 1763728073)                                      \
  V(_IntegerImplementation, |, Integer_bitOr, 149206765)                       \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 281425907)                                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 922906510)                      \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 787426822)                                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 1226840498)                \
  V(_IntegerImplementation, ==, Integer_equal, 1155579943)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    1790821042)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 555566388)                    \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 1161964406)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 317522326)           \
  V(_IntegerImplementation, <<, Integer_shl, 1479333073)                       \
  V(_IntegerImplementation, >>, Integer_sar, 1310672722)                       \
  V(_Double, toInt, DoubleToInteger, 1547535151)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, 101545548)                                             \
  V(_Random, _nextState, Random_nextState, 84519862)                           \


#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(_Int8Array, _new, TypedData_Int8Array_new, 1490161004)                     \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 212211297)                    \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 1066441853)     \
  V(_Int16Array, _new, TypedData_Int16Array_new, 72086552)                     \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 529525586)                  \
  V(_Int32Array, _new, TypedData_Int32Array_new, 2065356233)                   \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 350335670)                  \
  V(_Int64Array, _new, TypedData_Int64Array_new, 1639531103)                   \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 1975347888)                 \
  V(_Float32Array, _new, TypedData_Float32Array_new, 917766665)                \
  V(_Float64Array, _new, TypedData_Float64Array_new, 985384871)                \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 936668603)            \
  V(_Int32x4Array, _new, TypedData_Int32x4Array_new, 836387418)                \
  V(_Float64x2Array, _new, TypedData_Float64x2Array_new, 1847004265)           \
  V(_Int8Array, ., TypedData_Int8Array_factory, 1234236264)                    \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 89436950)                    \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 2114336727)    \
  V(_Int16Array, ., TypedData_Int16Array_factory, 779429598)                   \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 351653952)                 \
  V(_Int32Array, ., TypedData_Int32Array_factory, 1909366715)                  \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 32690110)                  \
  V(_Int64Array, ., TypedData_Int64Array_factory, 1987760123)                  \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 1205087814)                \
  V(_Float32Array, ., TypedData_Float32Array_factory, 1988570712)              \
  V(_Float64Array, ., TypedData_Float64Array_factory, 77468920)                \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 953075137)           \
  V(_Int32x4Array, ., TypedData_Int32x4Array_factory, 1983535209)              \
  V(_Float64x2Array, ., TypedData_Float64x2Array_factory, 346534719)           \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V) \
  V(_Uint8Array, [], Uint8ArrayGetIndexed, 252408403)                          \
  V(_Uint8Array, []=, Uint8ArraySetIndexed, 1102579018)                        \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 1915061214)         \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 2992978)           \
  V(_Float64Array, []=, Float64ArraySetIndexed, 407531405)                     \
  V(_Float64Array, [], Float64ArrayGetIndexed, 2015337560)                     \
  V(_TypedList, get:length, TypedDataLength, 522595148)                        \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, 1181382520)                          \
  V(_List, [], ObjectArrayGetIndexed, 390939163)                               \
  V(_ImmutableList, get:length, ImmutableArrayLength, 274947518)               \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 1585504028)                  \
  V(_GrowableList, get:length, GrowableArrayLength, 778534898)                 \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 555169866)            \
  V(_StringBase, get:length, StringBaseLength, 784429419)                      \

#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \

#define PROFILER_LIB_INTRINSIC_LIST(V)                                         \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, 370414636)                     \
  V(::, _getDefaultTag, UserTag_defaultTag, 1159885970)                        \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 1182126114)                    \

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
  CORE_LIB_INTRINSIC_LIST(V)                                                   \
  MATH_LIB_INTRINSIC_LIST(V)                                                   \
  TYPED_DATA_LIB_INTRINSIC_LIST(V)                                             \
  PROFILER_LIB_INTRINSIC_LIST(V)

#define ALL_INTRINSICS_LIST(V)                                                 \
  ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                        \
  CORE_INTEGER_LIB_INTRINSIC_LIST(V)

#define RECOGNIZED_LIST(V)                                                     \
  OTHER_RECOGNIZED_LIST(V)                                                     \
  ALL_INTRINSICS_LIST(V)                                                       \
  GRAPH_INTRINSICS_LIST(V)

// A list of core function that should always be inlined.
#define INLINE_WHITE_LIST(V)                                                   \
  V(Object, ==, ObjectEquals, 1955975370)                                      \
  V(_List, get:length, ObjectArrayLength, 1181382520)                          \
  V(_ImmutableList, get:length, ImmutableArrayLength, 274947518)               \
  V(_TypedList, get:length, TypedDataLength, 522595148)                        \
  V(_GrowableList, get:length, GrowableArrayLength, 778534898)                 \
  V(_GrowableList, add, GrowableListAdd, 422087403)                            \
  V(_GrowableList, removeLast, GrowableListRemoveLast, 1285719639)             \
  V(_StringBase, get:length, StringBaseLength, 784429419)                      \
  V(ListIterator, moveNext, ListIteratorMoveNext, 1001265875)                  \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 890839431)   \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 1663047580)            \
  V(_GrowableList, forEach, GrowableArrayForEach, 605873384)                   \
  V(_List, ., ObjectArrayAllocate, 335347617)                                  \
  V(_List, [], ObjectArrayGetIndexed, 390939163)                               \
  V(_List, []=, ObjectArraySetIndexed, 1768442583)                             \
  V(ListMixin, get:isEmpty, ListMixinIsEmpty, 2102252776)                      \
  V(_List, get:iterator, ObjectArrayIterator, 308726049)                       \
  V(_List, forEach, ObjectArrayForEach, 1720909126)                            \
  V(_List, _slice, ObjectArraySlice, 1738717516)                               \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 212198431)           \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 1192041734)                \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 1585504028)                  \
  V(_GrowableList, [], GrowableArrayGetIndexed, 514434920)                     \
  V(_GrowableList, []=, GrowableArraySetIndexed, 1698264861)                   \
  V(_Float32Array, [], Float32ArrayGetIndexed, 1092936601)                     \
  V(_Float32Array, []=, Float32ArraySetIndexed, 102284991)                     \
  V(_Float64Array, [], Float64ArrayGetIndexed, 2015337560)                     \
  V(_Float64Array, []=, Float64ArraySetIndexed, 407531405)                     \
  V(_Int8Array, [], Int8ArrayGetIndexed, 557513849)                            \
  V(_Int8Array, []=, Int8ArraySetIndexed, 1135113150)                          \
  V(_Uint8Array, [], Uint8ArrayGetIndexed, 252408403)                          \
  V(_Uint8Array, []=, Uint8ArraySetIndexed, 1102579018)                        \
  V(_Uint8ClampedArray, [], Uint8ClampedArrayGetIndexed, 666955326)            \
  V(_Uint8ClampedArray, []=, Uint8ClampedArraySetIndexed, 2053292453)          \
  V(_Uint16Array, [], Uint16ArrayGetIndexed, 706695216)                        \
  V(_Uint16Array, []=, Uint16ArraySetIndexed, 733443505)                       \
  V(_Int16Array, [], Int16ArrayGetIndexed, 310411118)                          \
  V(_Int16Array, []=, Int16ArraySetIndexed, 694766810)                         \
  V(_Int32Array, [], Int32ArrayGetIndexed, 439384633)                          \
  V(_Int32Array, []=, Int32ArraySetIndexed, 1570966684)                        \
  V(_Int64Array, [], Int64ArrayGetIndexed, 443139045)                          \
  V(_Int64Array, []=, Int64ArraySetIndexed, 342796642)                         \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 735017274)                  \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 1913230218)                \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 1089555253)                   \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 1088185083)                  \
  V(::, asin, MathASin, 1651042633)                                            \
  V(::, acos, MathACos, 1139647090)                                            \
  V(::, atan, MathATan, 1668754384)                                            \
  V(::, atan2, MathATan2, 1845649456)                                          \
  V(::, cos, MathCos, 1951197905)                                              \
  V(::, exp, MathExp, 1809210829)                                              \
  V(::, log, MathLog, 1620336448)                                              \
  V(::, max, MathMax, 989552054)                                               \
  V(::, min, MathMin, 214919172)                                               \
  V(::, pow, MathPow, 1381728863)                                              \
  V(::, sin, MathSin, 1741396147)                                              \
  V(::, sqrt, MathSqrt, 101545548)                                             \
  V(::, tan, MathTan, 982072809)                                               \
  V(Lists, copy, ListsCopy, 605584668)                                         \
  V(_Bigint, get:_neg, Bigint_getNeg, 1151543890)                              \
  V(_Bigint, set:_neg, Bigint_setNeg, 1924982939)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1308559334)                            \
  V(_Bigint, set:_used, Bigint_setUsed, 1574448752)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 1408092463)                        \
  V(_Bigint, set:_digits, Bigint_setDigits, 1625268649)                        \
  V(_Bigint, _set_digits, Bigint_setDigits, 1865626071)                        \

// A list of core function that should never be inlined.
#define INLINE_BLACK_LIST(V)                                                   \
  V(_Bigint, _absAdd, Bigint_absAdd, 97148049)                                 \
  V(_Bigint, _absSub, Bigint_absSub, 159012285)                                \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 101252203)                                \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 1684445648)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 649845040)            \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 1551846228)                       \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 1107537364)                             \
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
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 783880753)                     \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 499938872)                    \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 1156009451)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 1239113233)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 2058780470)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 66201433)                  \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 1499236144)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 1323416269)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 1301054599)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 1651670367)              \

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
  static void InitializeState();
};

}  // namespace dart

#endif  // VM_METHOD_RECOGNIZER_H_
