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
  V(::, identical, ObjectIdentical, 317103244)                                 \
  V(ClassID, getID, ClassIDgetID, 1385157717)                                  \
  V(Object, Object., ObjectConstructor, 1746278398)                            \
  V(_List, ., ObjectArrayAllocate, 184405219)                                  \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 187609847)                     \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 1826086346)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 1174755987)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 1936358273)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 1123951931)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 853172551)                 \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 1115954619)                  \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 165422183)               \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 1564825450)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 1123952315)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 831892409)               \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 2043203289)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 1759261408)                  \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 267848339)                   \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 350952121)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 1170619358)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 1325523969)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 935451230)                   \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 541136999)               \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 365317124)               \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 1766802707)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 2075229300)              \
  V(_StringBase, _interpolate, StringBaseInterpolate, 1597087225)              \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 150718448)              \
  V(_Double, _add, DoubleAdd, 1190606283)                                      \
  V(_Double, _sub, DoubleSub, 1086286468)                                      \
  V(_Double, _mul, DoubleMul, 166332351)                                       \
  V(_Double, _div, DoubleDiv, 821396195)                                       \
  V(::, min, MathMin, 1115051548)                                              \
  V(::, max, MathMax, 1410473322)                                              \
  V(::, _doublePow, MathDoublePow, 562154128)                                  \
  V(Float32x4, Float32x4., Float32x4Constructor, 93751705)                     \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 1193954374)                      \
  V(Float32x4, Float32x4.splat, Float32x4Splat, 12296613)                      \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits, 1188039061)\
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, 1750763218)    \
  V(Float32x4, shuffle, Float32x4Shuffle, 2015957023)                          \
  V(Float32x4, shuffleMix, Float32x4ShuffleMix, 1099087979)                    \
  V(Float32x4, get:signMask, Float32x4GetSignMask, 487049875)                  \
  V(Float32x4, _cmpequal, Float32x4Equal, 1069901308)                          \
  V(Float32x4, _cmpgt, Float32x4GreaterThan, 2112381651)                       \
  V(Float32x4, _cmpgte, Float32x4GreaterThanOrEqual, 1088241265)               \
  V(Float32x4, _cmplt, Float32x4LessThan, 2001171012)                          \
  V(Float32x4, _cmplte, Float32x4LessThanOrEqual, 1568686387)                  \
  V(Float32x4, _cmpnequal, Float32x4NotEqual, 1833412828)                      \
  V(Float32x4, _min, Float32x4Min, 1194113943)                                 \
  V(Float32x4, _max, Float32x4Max, 1876936155)                                 \
  V(Float32x4, _scale, Float32x4Scale, 1176743640)                             \
  V(Float32x4, _sqrt, Float32x4Sqrt, 526238610)                                \
  V(Float32x4, _reciprocalSqrt, Float32x4ReciprocalSqrt, 860560177)            \
  V(Float32x4, _reciprocal, Float32x4Reciprocal, 1703468100)                   \
  V(Float32x4, _negate, Float32x4Negate, 1409902640)                           \
  V(Float32x4, _abs, Float32x4Absolute, 2116840471)                            \
  V(Float32x4, _clamp, Float32x4Clamp, 1789892357)                             \
  V(Float32x4, withX, Float32x4WithX, 1311992575)                              \
  V(Float32x4, withY, Float32x4WithY, 175290640)                               \
  V(Float32x4, withZ, Float32x4WithZ, 837367384)                               \
  V(Float32x4, withW, Float32x4WithW, 1625145605)                              \
  V(Float64x2, Float64x2., Float64x2Constructor, 423355933)                    \
  V(Float64x2, Float64x2.zero, Float64x2Zero, 2066666975)                      \
  V(Float64x2, Float64x2.splat, Float64x2Splat, 716962994)                     \
  V(Float64x2, Float64x2.fromFloat32x4, Float64x2FromFloat32x4, 792974246)     \
  V(Float64x2, get:x, Float64x2GetX, 1488958362)                               \
  V(Float64x2, get:y, Float64x2GetY, 1022688506)                               \
  V(Float64x2, _negate, Float64x2Negate, 960840275)                            \
  V(Float64x2, abs, Float64x2Abs, 52403783)                                    \
  V(Float64x2, sqrt, Float64x2Sqrt, 2012680669)                                \
  V(Float64x2, get:signMask, Float64x2GetSignMask, 668856717)                  \
  V(Float64x2, scale, Float64x2Scale, 646122081)                               \
  V(Float64x2, withX, Float64x2WithX, 489409269)                               \
  V(Float64x2, withY, Float64x2WithY, 943642284)                               \
  V(Float64x2, min, Float64x2Min, 685235702)                                   \
  V(Float64x2, max, Float64x2Max, 198659675)                                   \
  V(Int32x4, Int32x4., Int32x4Constructor, 649173415)                          \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, 458597857)                  \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Int32x4FromFloat32x4Bits, 2122470988)  \
  V(Int32x4, get:flagX, Int32x4GetFlagX, 1446544324)                           \
  V(Int32x4, get:flagY, Int32x4GetFlagY, 1148149370)                           \
  V(Int32x4, get:flagZ, Int32x4GetFlagZ, 550901369)                            \
  V(Int32x4, get:flagW, Int32x4GetFlagW, 1346664620)                           \
  V(Int32x4, get:signMask, Int32x4GetSignMask, 740215269)                      \
  V(Int32x4, shuffle, Int32x4Shuffle, 549194518)                               \
  V(Int32x4, shuffleMix, Int32x4ShuffleMix, 1550866145)                        \
  V(Int32x4, select, Int32x4Select, 614943686)                                 \
  V(Int32x4, withFlagX, Int32x4WithFlagX, 250974159)                           \
  V(Int32x4, withFlagY, Int32x4WithFlagY, 1686481348)                          \
  V(Int32x4, withFlagZ, Int32x4WithFlagZ, 645582330)                           \
  V(Int32x4, withFlagW, Int32x4WithFlagW, 878364277)                           \
  V(Float32List, [], Float32ArrayGetIndexed, 1002307136)                       \
  V(Float32List, []=, Float32ArraySetIndexed, 279546769)                       \
  V(Int8List, [], Int8ArrayGetIndexed, 1141846285)                             \
  V(Int8List, []=, Int8ArraySetIndexed, 1486839324)                            \
  V(Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, 513704632)              \
  V(Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, 1015846567)            \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    513704632)                                                                 \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    1015846567)                                                                \
  V(Int16List, [], Int16ArrayGetIndexed, 1826359619)                           \
  V(Int16List, []=, Int16ArraySetIndexed, 1108689116)                          \
  V(Uint16List, [], Uint16ArrayGetIndexed, 118958722)                          \
  V(Uint16List, []=, Uint16ArraySetIndexed, 658824450)                         \
  V(Int32List, [], Int32ArrayGetIndexed, 681203163)                            \
  V(Int32List, []=, Int32ArraySetIndexed, 1786886245)                          \
  V(Int64List, [], Int64ArrayGetIndexed, 1883155004)                           \
  V(Int64List, []=, Int64ArraySetIndexed, 905815059)                           \
  V(Float32x4List, [], Float32x4ArrayGetIndexed, 694822356)                    \
  V(Float32x4List, []=, Float32x4ArraySetIndexed, 1166109127)                  \
  V(Int32x4List, [], Int32x4ArrayGetIndexed, 668249259)                        \
  V(Int32x4List, []=, Int32x4ArraySetIndexed, 654739449)                       \
  V(Float64x2List, [], Float64x2ArrayGetIndexed, 196472005)                    \
  V(Float64x2List, []=, Float64x2ArraySetIndexed, 1421858500)                  \
  V(_Bigint, get:_neg, Bigint_getNeg, 1681019799)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1439136438)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 769722770)                         \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 2048715833)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 1882796480)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 942992497)                  \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 1410623019)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 1698421819)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 1858754514)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 98745045)           \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 340628211)          \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 1340385546)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 638315987)    \


// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 1673522705)                                        \
  V(_Smi, get:bitLength, Smi_bitLength, 632480332)                             \
  V(_Bigint, _lsh, Bigint_lsh, 834311957)                                      \
  V(_Bigint, _rsh, Bigint_rsh, 333337658)                                      \
  V(_Bigint, _absAdd, Bigint_absAdd, 473436659)                                \
  V(_Bigint, _absSub, Bigint_absSub, 1018678324)                               \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 571005736)                                \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 372896038)                                \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 540033329)            \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 118781828)                        \
  V(_Double, >, Double_greaterThan, 1413076759)                                \
  V(_Double, >=, Double_greaterEqualThan, 1815180096)                          \
  V(_Double, <, Double_lessThan, 652059836)                                    \
  V(_Double, <=, Double_lessEqualThan, 512138528)                              \
  V(_Double, ==, Double_equal, 752327620)                                      \
  V(_Double, +, Double_add, 854024064)                                         \
  V(_Double, -, Double_sub, 685132889)                                         \
  V(_Double, *, Double_mul, 542254390)                                         \
  V(_Double, /, Double_div, 1145710768)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 184085483)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 978911030)                  \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 543831179)                \
  V(_Double, .fromInteger, DoubleFromInteger, 1453449234)                      \
  V(_List, []=, ObjectArraySetIndexed, 886228780)                              \
  V(_GrowableList, .withData, GrowableArray_Allocate, 131424500)               \
  V(_GrowableList, add, GrowableArray_add, 242296201)                          \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, 2077783530)                   \
  V(Object, ==, ObjectEquals, 291909336)                                       \
  V(Object, get:runtimeType, ObjectRuntimeType, 15188587)                      \
  V(_StringBase, get:hashCode, String_getHashCode, 2026040200)                 \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 1958879178)                   \
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 1436590579)                 \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, 1548648995)    \
  V(_StringBase, [], StringBaseCharAt, 754527301)                              \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 2026040200)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked, 2063670029)                              \
  V(_OneByteString, _setAt, OneByteStringSetAt, 929822971)                     \
  V(_OneByteString, _allocate, OneByteString_allocate, 1737851380)             \
  V(_OneByteString, ==, OneByteString_equality, 1062844160)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 1062844160)                    \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger, 298045644)\
  V(_IntegerImplementation, +, Integer_add, 364498398)                         \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, 422157928)\
  V(_IntegerImplementation, -, Integer_sub, 1682674911)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    2074733333)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 1651115456)                        \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    2100319763)                                                                \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 108494012)                \
  V(_IntegerImplementation, unary-, Integer_negate, 1507648892)                \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    363854564)                                                                 \
  V(_IntegerImplementation, &, Integer_bitAnd, 286231290)                      \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    1623085924)                                                                \
  V(_IntegerImplementation, |, Integer_bitOr, 1111108792)                      \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    140783758)                                                                 \
  V(_IntegerImplementation, ^, Integer_bitXor, 1884808537)                     \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, 814932166)                                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 293890061)                 \
  V(_IntegerImplementation, ==, Integer_equal, 4489308)                        \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    1818326386)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 652059836)                    \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 512138528)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 1815180096)          \
  V(_IntegerImplementation, <<, Integer_shl, 293751452)                        \
  V(_IntegerImplementation, >>, Integer_sar, 125091101)                        \
  V(_Double, toInt, DoubleToInteger, 653210699)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, 1446681622)                                            \
  V(_Random, _nextState, Random_nextState, 1241583299)                         \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, 939048573)                                               \
  V(::, cos, MathCos, 1148850331)                                              \
  V(::, tan, MathTan, 179725235)                                               \
  V(::, asin, MathAsin, 848695059)                                             \
  V(::, acos, MathAcos, 337299516)                                             \
  V(::, atan, MathAtan, 866406810)                                             \
  V(::, atan2, MathAtan2, 1901969510)                                          \

#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(Int8List, ., TypedData_Int8Array_factory, 779569635)                       \
  V(Uint8List, ., TypedData_Uint8Array_factory, 1790399545)                    \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory, 405875159)       \
  V(Int16List, ., TypedData_Int16Array_factory, 347431914)                     \
  V(Uint16List, ., TypedData_Uint16Array_factory, 121990116)                   \
  V(Int32List, ., TypedData_Int32Array_factory, 1540657744)                    \
  V(Uint32List, ., TypedData_Uint32Array_factory, 1012511652)                  \
  V(Int64List, ., TypedData_Int64Array_factory, 1473796807)                    \
  V(Uint64List, ., TypedData_Uint64Array_factory, 738799620)                   \
  V(Float32List, ., TypedData_Float32Array_factory, 1938690635)                \
  V(Float64List, ., TypedData_Float64Array_factory, 1344005361)                \
  V(Float32x4List, ., TypedData_Float32x4Array_factory, 2055067416)            \
  V(Int32x4List, ., TypedData_Int32x4Array_factory, 504220232)                 \
  V(Float64x2List, ., TypedData_Float64x2Array_factory, 416019673)             \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(Uint8List, [], Uint8ArrayGetIndexed, 513704632)                            \
  V(Uint8List, []=, Uint8ArraySetIndexed, 2123520783)                          \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 513704632)          \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 2123520783)        \
  V(Uint32List, [], Uint32ArrayGetIndexed, 1179675338)                         \
  V(Uint32List, []=, Uint32ArraySetIndexed, 1455695417)                        \
  V(Float64List, []=, Float64ArraySetIndexed, 1929239576)                      \
  V(Float64List, [], Float64ArrayGetIndexed, 816943529)                        \
  V(_TypedList, get:length, TypedDataLength, 546364442)                        \
  V(Float32x4, get:x, Float32x4ShuffleX, 1674625343)                           \
  V(Float32x4, get:y, Float32x4ShuffleY, 540293915)                            \
  V(Float32x4, get:z, Float32x4ShuffleZ, 320347578)                            \
  V(Float32x4, get:w, Float32x4ShuffleW, 1770606624)                           \
  V(Float32x4, _mul, Float32x4Mul, 861549065)                                  \
  V(Float32x4, _sub, Float32x4Sub, 460363214)                                  \
  V(Float32x4, _add, Float32x4Add, 1487592255)                                 \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, 630471378)                           \
  V(_List, [], ObjectArrayGetIndexed, 360400496)                               \
  V(_ImmutableList, get:length, ImmutableArrayLength, 630471378)               \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 360400496)                   \
  V(_GrowableList, get:length, GrowableArrayLength, 417111542)                 \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 193746510)            \
  V(_GrowableList, _setData, GrowableArraySetData, 1496536873)                 \
  V(_GrowableList, _setLength, GrowableArraySetLength, 32203572)               \
  V(_GrowableList, [], GrowableArrayGetIndexed, 1957529650)                    \
  V(_GrowableList, []=, GrowableArraySetIndexed, 225246870)                    \
  V(_StringBase, get:length, StringBaseLength, 707533587)                      \
  V(_Double, unary-, DoubleFlipSignBit, 1783281169)                            \
  V(_Double, truncateToDouble, DoubleTruncate, 791143891)                      \
  V(_Double, roundToDouble, DoubleRound, 797558034)                            \
  V(_Double, floorToDouble, DoubleFloor, 1789426271)                           \
  V(_Double, ceilToDouble, DoubleCeil, 453271198)                              \
  V(_Double, _modulo, DoubleMod, 1093862165)


#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, 187721469)                     \
  V(::, _getDefaultTag, UserTag_defaultTag, 1872263331)                        \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 692104531)                     \

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
  V(_GrowableList, add, GrowableListAdd, 242296201)                            \
  V(_GrowableList, removeLast, GrowableListRemoveLast, 1655383014)             \
  V(_StringBase, get:length, StringBaseLength, 707533587)                      \
  V(ListIterator, moveNext, ListIteratorMoveNext, 1467737539)                  \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 784200630)   \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 1840323187)            \
  V(_GrowableList, forEach, GrowableArrayForEach, 620771070)                   \
  V(_List, ., ObjectArrayAllocate, 184405219)                                  \
  V(_List, [], ObjectArrayGetIndexed, 360400496)                               \
  V(_List, []=, ObjectArraySetIndexed, 886228780)                              \
  V(ListMixin, get:isEmpty, ListMixinIsEmpty, 2021497798)                      \
  V(_List, get:iterator, ObjectArrayIterator, 1930956161)                      \
  V(_List, forEach, ObjectArrayForEach, 180150673)                             \
  V(_List, _slice, ObjectArraySlice, 1785552519)                               \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 1930956161)          \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 180150673)                 \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 360400496)                   \
  V(_GrowableList, [], GrowableArrayGetIndexed, 1957529650)                    \
  V(_GrowableList, []=, GrowableArraySetIndexed, 225246870)                    \
  V(Float32List, [], Float32ArrayGetIndexed, 1002307136)                       \
  V(Float32List, []=, Float32ArraySetIndexed, 279546769)                       \
  V(Float64List, [], Float64ArrayGetIndexed, 816943529)                        \
  V(Float64List, []=, Float64ArraySetIndexed, 1929239576)                      \
  V(Int8List, [], Int8ArrayGetIndexed, 1141846285)                             \
  V(Int8List, []=, Int8ArraySetIndexed, 1486839324)                            \
  V(Uint8List, [], Uint8ArrayGetIndexed, 513704632)                            \
  V(Uint8List, []=, Uint8ArraySetIndexed, 2123520783)                          \
  V(Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, 513704632)              \
  V(Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, 1015846567)            \
  V(Uint16List, [], Uint16ArrayGetIndexed, 118958722)                          \
  V(Uint16List, []=, Uint16ArraySetIndexed, 658824450)                         \
  V(Int16List, [], Int16ArrayGetIndexed, 1826359619)                           \
  V(Int16List, []=, Int16ArraySetIndexed, 1108689116)                          \
  V(Int32List, [], Int32ArrayGetIndexed, 681203163)                            \
  V(Int32List, []=, Int32ArraySetIndexed, 1786886245)                          \
  V(Int64List, [], Int64ArrayGetIndexed, 1883155004)                           \
  V(Int64List, []=, Int64ArraySetIndexed, 905815059)                           \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 215420949)                  \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 1138146450)                \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 1003520035)                   \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 225448326)                   \
  V(_ByteDataView, setInt8, ByteDataViewSetInt8, 1091734252)                   \
  V(_ByteDataView, setUint8, ByteDataViewSetUint8, 549773093)                  \
  V(_ByteDataView, setInt16, ByteDataViewSetInt16, 1580120352)                 \
  V(_ByteDataView, setUint16, ByteDataViewSetUint16, 948267909)                \
  V(_ByteDataView, setInt32, ByteDataViewSetInt32, 2088513508)                 \
  V(_ByteDataView, setUint32, ByteDataViewSetUint32, 1125319)                  \
  V(_ByteDataView, setInt64, ByteDataViewSetInt64, 192928709)                  \
  V(_ByteDataView, setUint64, ByteDataViewSetUint64, 483118836)                \
  V(_ByteDataView, setFloat32, ByteDataViewSetFloat32, 1241910514)             \
  V(_ByteDataView, setFloat64, ByteDataViewSetFloat64, 1950485343)             \
  V(_ByteDataView, getInt8, ByteDataViewGetInt8, 1939363561)                   \
  V(_ByteDataView, getUint8, ByteDataViewGetUint8, 121087953)                  \
  V(_ByteDataView, getInt16, ByteDataViewGetInt16, 591911343)                  \
  V(_ByteDataView, getUint16, ByteDataViewGetUint16, 2114157459)               \
  V(_ByteDataView, getInt32, ByteDataViewGetInt32, 712570242)                  \
  V(_ByteDataView, getUint32, ByteDataViewGetUint32, 162058988)                \
  V(_ByteDataView, getInt64, ByteDataViewGetInt64, 1566486016)                 \
  V(_ByteDataView, getUint64, ByteDataViewGetUint64, 1397980812)               \
  V(_ByteDataView, getFloat32, ByteDataViewGetFloat32, 1251636679)             \
  V(_ByteDataView, getFloat64, ByteDataViewGetFloat64, 1940177769)             \
  V(::, asin, MathASin, 848695059)                                             \
  V(::, acos, MathACos, 337299516)                                             \
  V(::, atan, MathATan, 866406810)                                             \
  V(::, atan2, MathATan2, 1901969510)                                          \
  V(::, cos, MathCos, 1148850331)                                              \
  V(::, exp, MathExp, 1006863255)                                              \
  V(::, log, MathLog, 817988874)                                               \
  V(::, max, MathMax, 1410473322)                                              \
  V(::, min, MathMin, 1115051548)                                              \
  V(::, pow, MathPow, 864430827)                                               \
  V(::, sin, MathSin, 939048573)                                               \
  V(::, sqrt, MathSqrt, 1446681622)                                            \
  V(::, tan, MathTan, 179725235)                                               \
  V(Lists, copy, ListsCopy, 564237562)                                         \
  V(_Bigint, get:_neg, Bigint_getNeg, 1681019799)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 1439136438)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 769722770)                         \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 2048715833)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 1882796480)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 942992497)                  \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 1410623019)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 1698421819)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 1858754514)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 98745045)           \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 340628211)          \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 1340385546)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 638315987)    \

// A list of core function that should never be inlined.
#define INLINE_BLACK_LIST(V)                                                   \
  V(_Bigint, _lsh, Bigint_lsh, 834311957)                                      \
  V(_Bigint, _rsh, Bigint_rsh, 333337658)                                      \
  V(_Bigint, _absAdd, Bigint_absAdd, 473436659)                                \
  V(_Bigint, _absSub, Bigint_absSub, 1018678324)                               \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 571005736)                                \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 372896038)                                \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 540033329)            \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 118781828)                        \
  V(_Double, >, Double_greaterThan, 1413076759)                                \
  V(_Double, >=, Double_greaterEqualThan, 1815180096)                          \
  V(_Double, <, Double_lessThan, 652059836)                                    \
  V(_Double, <=, Double_lessEqualThan, 512138528)                              \
  V(_Double, ==, Double_equal, 752327620)                                      \
  V(_Double, +, Double_add, 854024064)                                         \
  V(_Double, -, Double_sub, 685132889)                                         \
  V(_Double, *, Double_mul, 542254390)                                         \
  V(_Double, /, Double_div, 1145710768)                                        \
  V(_IntegerImplementation, +, Integer_add, 364498398)                         \
  V(_IntegerImplementation, -, Integer_sub, 1682674911)                        \
  V(_IntegerImplementation, *, Integer_mul, 1651115456)                        \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 108494012)                \
  V(_IntegerImplementation, unary-, Integer_negate, 1507648892)                \
  V(_IntegerImplementation, &, Integer_bitAnd, 286231290)                      \
  V(_IntegerImplementation, |, Integer_bitOr, 1111108792)                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 1884808537)                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 293890061)                 \
  V(_IntegerImplementation, ==, Integer_equal, 4489308)                        \
  V(_IntegerImplementation, <, Integer_lessThan, 652059836)                    \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 512138528)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 1815180096)          \
  V(_IntegerImplementation, <<, Integer_shl, 293751452)                        \
  V(_IntegerImplementation, >>, Integer_sar, 125091101)                        \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 754527301)                              \
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 1436590579)                 \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 187609847)                     \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 1826086346)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 1174755987)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 1936358273)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 1123951931)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 853172551)                 \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 165422183)               \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 1564825450)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 1123952315)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 831892409)               \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 2043203289)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 1759261408)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 267848339)                   \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 350952121)                  \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 1170619358)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 1325523969)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 541136999)               \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 365317124)               \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 1766802707)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 2075229300)              \

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
  V(_ListFactory, kArrayCid, 184405219)                                        \
  V(_GrowableListWithData, kGrowableObjectArrayCid, 131424500)                 \
  V(_GrowableListFactory, kGrowableObjectArrayCid, 664918385)                  \
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
