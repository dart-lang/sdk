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
  V(ClassID, getID, ClassIDgetID, 1322490980)                                  \
  V(Object, Object., ObjectConstructor, 1066669787)                            \
  V(_List, ., ObjectArrayAllocate, 1595327584)                                 \
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
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 433348464)                     \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 149406583)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 805477162)                   \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 888580944)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 1708248181)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 1863152792)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 1148703855)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 972883980)               \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 950522310)           \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 1301138078)              \
  V(_StringBase, _interpolate, StringBaseInterpolate, 1540062866)              \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 1084977108)             \
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
  V(::, min, MathMin, 1022567780)                                              \
  V(::, max, MathMax, 612058870)                                               \
  V(::, _doublePow, MathDoublePow, 823139975)                                  \
  V(Float32x4, Float32x4., Float32x4Constructor, 1755873079)                   \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 1494069379)                      \
  V(Float32x4, Float32x4.splat, Float32x4Splat, 916211464)                     \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits,            \
      640076216)                                                               \
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, 1279591344)    \
  V(_Float32x4, shuffle, Float32x4Shuffle, 1636488139)                         \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, 597555927)                    \
  V(_Float32x4, get:x, Float32x4ShuffleX, 384850558)                           \
  V(_Float32x4, get:y, Float32x4ShuffleY, 1398002778)                          \
  V(_Float32x4, get:z, Float32x4ShuffleZ, 1178056441)                          \
  V(_Float32x4, get:w, Float32x4ShuffleW, 480831839)                           \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, 630761511)                 \
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
  V(Float64x2, Float64x2., Float64x2Constructor, 1399581872)                   \
  V(Float64x2, Float64x2.zero, Float64x2Zero, 1836770587)                      \
  V(Float64x2, Float64x2.splat, Float64x2Splat, 939291159)                     \
  V(Float64x2, Float64x2.fromFloat32x4, Float64x2FromFloat32x4, 1499726406)    \
  V(_Float64x2, get:x, Float64x2GetX, 261044094)                               \
  V(_Float64x2, get:y, Float64x2GetY, 1942257886)                              \
  V(_Float64x2, _negate, Float64x2Negate, 2133212774)                          \
  V(_Float64x2, abs, Float64x2Abs, 1224776282)                                 \
  V(_Float64x2, sqrt, Float64x2Sqrt, 1037569520)                               \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, 252936800)                 \
  V(_Float64x2, scale, Float64x2Scale, 1199438744)                             \
  V(_Float64x2, withX, Float64x2WithX, 1042725932)                             \
  V(_Float64x2, withY, Float64x2WithY, 1496958947)                             \
  V(_Float64x2, min, Float64x2Min, 485240583)                                  \
  V(_Float64x2, max, Float64x2Max, 2146148204)                                 \
  V(Int32x4, Int32x4., Int32x4Constructor, 665986284)                          \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, 87082660)                   \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Int32x4FromFloat32x4Bits,              \
      372517418)                                                               \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, 1077555238)                          \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, 779160284)                           \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, 181912283)                           \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, 977675534)                           \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, 1929271914)                    \
  V(_Int32x4, shuffle, Int32x4Shuffle, 1870018702)                             \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, 967644870)                        \
  V(_Int32x4, select, Int32x4Select, 1696037681)                               \
  V(_Int32x4, withFlagX, Int32x4WithFlagX, 467852789)                          \
  V(_Int32x4, withFlagY, Int32x4WithFlagY, 1903359978)                         \
  V(_Int32x4, withFlagZ, Int32x4WithFlagZ, 862460960)                          \
  V(_Int32x4, withFlagW, Int32x4WithFlagW, 1095242907)                         \
  V(_Float32Array, [], Float32ArrayGetIndexed, 856653338)                      \
  V(_Float32Array, []=, Float32ArraySetIndexed, 2086166464)                    \
  V(_Int8Array, [], Int8ArrayGetIndexed, 321230586)                            \
  V(_Int8Array, []=, Int8ArraySetIndexed, 2050598685)                          \
  V(_Uint8ClampedArray, [], Uint8ClampedArrayGetIndexed, 430672063)            \
  V(_Uint8ClampedArray, []=, Uint8ClampedArraySetIndexed, 821294340)           \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    1346536303)                                                                \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    1794849214)                                                                \
  V(_Int16Array, [], Int16ArrayGetIndexed, 74127855)                           \
  V(_Int16Array, []=, Int16ArraySetIndexed, 1610252345)                        \
  V(_Uint16Array, [], Uint16ArrayGetIndexed, 470411953)                        \
  V(_Uint16Array, []=, Uint16ArraySetIndexed, 1648929040)                      \
  V(_Int32Array, [], Int32ArrayGetIndexed, 203101370)                          \
  V(_Int32Array, []=, Int32ArraySetIndexed, 338968571)                         \
  V(_Uint32Array, [], Uint32ArrayGetIndexed, 1640672852)                       \
  V(_Uint32Array, []=, Uint32ArraySetIndexed, 1472976717)                      \
  V(_Float32x4Array, [], Float32x4ArrayGetIndexed, 1466627059)                 \
  V(_Float32x4Array, []=, Float32x4ArraySetIndexed, 2141660076)                \
  V(_Int32x4Array, [], Int32x4ArrayGetIndexed, 818792056)                      \
  V(_Int32x4Array, []=, Int32x4ArraySetIndexed, 1021474038)                    \
  V(_Float64x2Array, [], Float64x2ArrayGetIndexed, 288114492)                  \
  V(_Float64x2Array, []=, Float64x2ArraySetIndexed, 941746736)                 \
  V(_Bigint, get:_neg, Bigint_getNeg, 1151514099)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1308529543)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 1408062672)                        \

// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 105519892)                                         \
  V(_Smi, get:bitLength, Smi_bitLength, 869956497)                             \
  V(_Bigint, set:_neg, Bigint_setNeg, 920204960)                               \
  V(_Bigint, set:_used, Bigint_setUsed, 1857576743)                            \
  V(_Bigint, _set_digits, Bigint_setDigits, 582835804)                         \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 258927651)                                \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 1665155090)                               \
  V(_Double, >, Double_greaterThan, 381325711)                                 \
  V(_Double, >=, Double_greaterEqualThan, 1409267140)                          \
  V(_Double, <, Double_lessThan, 2080387973)                                   \
  V(_Double, <=, Double_lessEqualThan, 106225572)                              \
  V(_Double, ==, Double_equal, 2093918133)                                     \
  V(_Double, +, Double_add, 1646350451)                                        \
  V(_Double, -, Double_sub, 1477459276)                                        \
  V(_Double, *, Double_mul, 1334580777)                                        \
  V(_Double, /, Double_div, 1938037155)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 843050033)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 1637875580)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 1594796483)               \
  V(_Double, .fromInteger, DoubleFromInteger, 999771940)                       \
  V(_List, []=, ObjectArraySetIndexed, 1288827575)                             \
  V(_GrowableList, .withData, GrowableArray_Allocate, 732923072)               \
  V(_GrowableList, [], GrowableArrayGetIndexed, 919108233)                     \
  V(_GrowableList, []=, GrowableArraySetIndexed, 1218649853)                   \
  V(_GrowableList, _setLength, GrowableArraySetLength, 89389299)               \
  V(_GrowableList, _setData, GrowableArraySetData, 2126927509)                 \
  V(_GrowableList, add, GrowableArray_add, 1899133961)                         \
  V(Object, ==, ObjectEquals, 1068471689)                                      \
  V(_StringBase, get:hashCode, String_getHashCode, 2102906241)                 \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 49873871)                     \
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 397735324)                  \
  V(_StringBase, [], StringBaseCharAt, 1512210677)                             \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 1111837929)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 1527498975)                            \
  V(_OneByteString, _setAt, OneByteStringSetAt, 468605749)                     \
  V(_OneByteString, _allocate, OneByteString_allocate, 2035417022)             \
  V(_OneByteString, ==, OneByteString_equality, 1727047023)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 951149689)                     \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    438687793)                                                                 \
  V(_IntegerImplementation, +, Integer_add, 501253666)                         \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    562800077)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, 1819430179)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    67891834)                                                                  \
  V(_IntegerImplementation, *, Integer_mul, 1787870724)                        \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    93478264)                                                                  \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 1309867000)               \
  V(_IntegerImplementation, unary-, Integer_negate, 2095203689)                \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 504496713)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 648886925)                      \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 1763728073)                                      \
  V(_IntegerImplementation, |, Integer_bitOr, 1473764427)                      \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 281425907)                                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 99980524)                       \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 787426822)                                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 123961041)                 \
  V(_IntegerImplementation, ==, Integer_equal, 1423724294)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    1790821042)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 425560117)                    \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 1512735828)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 668293748)           \
  V(_IntegerImplementation, <<, Integer_shl, 656407087)                        \
  V(_IntegerImplementation, >>, Integer_sar, 487746736)                        \
  V(_Double, toInt, DoubleToInteger, 1547535151)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, 101545548)                                             \
  V(_Random, _nextState, Random_nextState, 55890711)                           \


#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(_Int8Array, _new, TypedData_Int8Array_new, 1150131819)                     \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 2019665760)                   \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 726412668)      \
  V(_Int16Array, _new, TypedData_Int16Array_new, 1879541015)                   \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 189496401)                  \
  V(_Int32Array, _new, TypedData_Int32Array_new, 1725327048)                   \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 10306485)                   \
  V(_Int64Array, _new, TypedData_Int64Array_new, 1299501918)                   \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 1635318703)                 \
  V(_Float32Array, _new, TypedData_Float32Array_new, 577737480)                \
  V(_Float64Array, _new, TypedData_Float64Array_new, 645355686)                \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 596639418)            \
  V(_Int32x4Array, _new, TypedData_Int32x4Array_new, 496358233)                \
  V(_Float64x2Array, _new, TypedData_Float64x2Array_new, 1506975080)           \
  V(_Int8Array, ., TypedData_Int8Array_factory, 1499010120)                    \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 354210806)                   \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 231626935)     \
  V(_Int16Array, ., TypedData_Int16Array_factory, 1044203454)                  \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 616427808)                 \
  V(_Int32Array, ., TypedData_Int32Array_factory, 26656923)                    \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 297463966)                 \
  V(_Int64Array, ., TypedData_Int64Array_factory, 105050331)                   \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 1469861670)                \
  V(_Float32Array, ., TypedData_Float32Array_factory, 105860920)               \
  V(_Float64Array, ., TypedData_Float64Array_factory, 342242776)               \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 1217848993)          \
  V(_Int32x4Array, ., TypedData_Int32x4Array_factory, 100825417)               \
  V(_Float64x2Array, ., TypedData_Float64x2Array_factory, 611308575)           \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V) \
  V(_Uint8Array, [], Uint8ArrayGetIndexed, 16125140)                           \
  V(_Uint8Array, []=, Uint8ArraySetIndexed, 2018064553)                        \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 1678777951)         \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 918478513)         \
  V(_Float64Array, []=, Float64ArraySetIndexed, 243929230)                     \
  V(_Float64Array, [], Float64ArrayGetIndexed, 1779054297)                     \
  V(_TypedList, get:length, TypedDataLength, 522565357)                        \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, 1181352729)                          \
  V(_List, [], ObjectArrayGetIndexed, 795612476)                               \
  V(_ImmutableList, get:length, ImmutableArrayLength, 274917727)               \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 1990177341)                  \
  V(_GrowableList, get:length, GrowableArrayLength, 778505107)                 \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 555140075)            \
  V(_StringBase, get:length, StringBaseLength, 784399628)                      \

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
  V(Object, ==, ObjectEquals, 1068471689)                                      \
  V(_List, get:length, ObjectArrayLength, 1181352729)                          \
  V(_ImmutableList, get:length, ImmutableArrayLength, 274917727)               \
  V(_TypedList, get:length, TypedDataLength, 522565357)                        \
  V(_GrowableList, get:length, GrowableArrayLength, 778505107)                 \
  V(_StringBase, get:length, StringBaseLength, 784399628)                      \
  V(ListIterator, moveNext, ListIteratorMoveNext, 210829138)                   \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 1147271335)  \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 1812933946)            \
  V(_GrowableList, forEach, GrowableArrayForEach, 2085943947)                  \
  V(_List, ., ObjectArrayAllocate, 1595327584)                                 \
  V(_List, [], ObjectArrayGetIndexed, 795612476)                               \
  V(_List, []=, ObjectArraySetIndexed, 1288827575)                             \
  V(_List, get:isEmpty, ObjectArrayIsEmpty, 2130247737)                        \
  V(_List, get:iterator, ObjectArrayIterator, 458612415)                       \
  V(_List, forEach, ObjectArrayForEach, 592525445)                             \
  V(_List, _slice, ObjectArraySlice, 1891508040)                               \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 362084797)           \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 63658053)                  \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 1990177341)                  \
  V(_GrowableList, [], GrowableArrayGetIndexed, 919108233)                     \
  V(_GrowableList, []=, GrowableArraySetIndexed, 1218649853)                   \
  V(_Float32Array, [], Float32ArrayGetIndexed, 856653338)                      \
  V(_Float32Array, []=, Float32ArraySetIndexed, 2086166464)                    \
  V(_Float64Array, [], Float64ArrayGetIndexed, 1779054297)                     \
  V(_Float64Array, []=, Float64ArraySetIndexed, 243929230)                     \
  V(_Int8Array, [], Int8ArrayGetIndexed, 321230586)                            \
  V(_Int8Array, []=, Int8ArraySetIndexed, 2050598685)                          \
  V(_Uint8Array, [], Uint8ArrayGetIndexed, 16125140)                           \
  V(_Uint8Array, []=, Uint8ArraySetIndexed, 2018064553)                        \
  V(_Uint8ClampedArray, [], Uint8ClampedArrayGetIndexed, 430672063)            \
  V(_Uint8ClampedArray, []=, Uint8ClampedArraySetIndexed, 821294340)           \
  V(_Uint16Array, [], Uint16ArrayGetIndexed, 470411953)                        \
  V(_Uint16Array, []=, Uint16ArraySetIndexed, 1648929040)                      \
  V(_Int16Array, [], Int16ArrayGetIndexed, 74127855)                           \
  V(_Int16Array, []=, Int16ArraySetIndexed, 1610252345)                        \
  V(_Int32Array, [], Int32ArrayGetIndexed, 203101370)                          \
  V(_Int32Array, []=, Int32ArraySetIndexed, 338968571)                         \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 1543480955)                 \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 936729641)                 \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 1898018934)                   \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 111684506)                   \
  V(::, asin, MathASin, 1651042633)                                            \
  V(::, acos, MathACos, 1139647090)                                            \
  V(::, atan, MathATan, 1668754384)                                            \
  V(::, atan2, MathATan2, 1845649456)                                          \
  V(::, cos, MathCos, 1951197905)                                              \
  V(::, exp, MathExp, 1809210829)                                              \
  V(::, log, MathLog, 1620336448)                                              \
  V(::, max, MathMax, 612058870)                                               \
  V(::, min, MathMin, 1022567780)                                              \
  V(::, pow, MathPow, 930962530)                                               \
  V(::, sin, MathSin, 1741396147)                                              \
  V(::, sqrt, MathSqrt, 101545548)                                             \
  V(::, tan, MathTan, 982072809)                                               \
  V(Lists, copy, ListsCopy, 902244797)                                         \
  V(_Bigint, get:_neg, Bigint_getNeg, 1151514099)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1308529543)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 1408062672)                        \
  V(_Bigint, set:_digits, Bigint_setDigits, 1135754410)                        \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 1512210677)                             \
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
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 433348464)                     \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 149406583)                    \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 805477162)                   \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 888580944)                  \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 1708248181)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 1863152792)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 1148703855)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 972883980)               \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 950522310)           \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 1301138078)              \

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
