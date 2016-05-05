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
  V(_List, ., ObjectArrayAllocate, 1661438741)                                 \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 1508321565)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 953411007)                   \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 433971756)                   \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 1329446488)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 137212209)                   \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 499907480)                 \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 1639388276)                  \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 1672834581)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 966634744)               \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 1197581758)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 810805548)               \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 1317196265)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 1328908284)                  \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 1827614958)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 1694054572)                \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 915652649)                   \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 1958474336)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 1970687707)                  \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 1853026980)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 1197862362)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 2093630771)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 1982971324)              \
  V(_StringBase, _interpolate, StringBaseInterpolate, 1872292681)              \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 792762465)              \
  V(_Double, _add, DoubleAdd, 2213216)                                         \
  V(_Double, _sub, DoubleSub, 1100692582)                                      \
  V(_Double, _mul, DoubleMul, 436784097)                                       \
  V(_Double, _div, DoubleDiv, 953317135)                                       \
  V(::, min, MathMin, 1115051548)                                              \
  V(::, max, MathMax, 1410473322)                                              \
  V(::, _doublePow, MathDoublePow, 1770960781)                                 \
  V(Float32x4, Float32x4., Float32x4Constructor, 93751705)                     \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 1193954374)                      \
  V(Float32x4, Float32x4.splat, Float32x4Splat, 12296613)                      \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits, 1188039061)\
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, 1750763218)    \
  V(Float32x4, shuffle, Float32x4Shuffle, 2015957023)                          \
  V(Float32x4, shuffleMix, Float32x4ShuffleMix, 1099087979)                    \
  V(Float32x4, get:signMask, Float32x4GetSignMask, 487049875)                  \
  V(Float32x4, _cmpequal, Float32x4Equal, 127403211)                           \
  V(Float32x4, _cmpgt, Float32x4GreaterThan, 2118391173)                       \
  V(Float32x4, _cmpgte, Float32x4GreaterThanOrEqual, 557807661)                \
  V(Float32x4, _cmplt, Float32x4LessThan, 1061691185)                          \
  V(Float32x4, _cmplte, Float32x4LessThanOrEqual, 102608993)                   \
  V(Float32x4, _cmpnequal, Float32x4NotEqual, 1873649982)                      \
  V(Float32x4, _min, Float32x4Min, 1158016632)                                 \
  V(Float32x4, _max, Float32x4Max, 118915526)                                  \
  V(Float32x4, _scale, Float32x4Scale, 415757469)                              \
  V(Float32x4, _sqrt, Float32x4Sqrt, 1934518992)                               \
  V(Float32x4, _reciprocalSqrt, Float32x4ReciprocalSqrt, 1586141174)           \
  V(Float32x4, _reciprocal, Float32x4Reciprocal, 1651466502)                   \
  V(Float32x4, _negate, Float32x4Negate, 2142478676)                           \
  V(Float32x4, _abs, Float32x4Absolute, 337704007)                             \
  V(Float32x4, _clamp, Float32x4Clamp, 1107305005)                             \
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
  V(Float64x2, _negate, Float64x2Negate, 1693416311)                           \
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
  V(Int32x4, select, Int32x4Select, 1368318775)                                \
  V(Int32x4, withFlagX, Int32x4WithFlagX, 250974159)                           \
  V(Int32x4, withFlagY, Int32x4WithFlagY, 1686481348)                          \
  V(Int32x4, withFlagZ, Int32x4WithFlagZ, 645582330)                           \
  V(Int32x4, withFlagW, Int32x4WithFlagW, 878364277)                           \
  V(Float32List, [], Float32ArrayGetIndexed, 1451643535)                       \
  V(Float32List, []=, Float32ArraySetIndexed, 453873887)                       \
  V(Int8List, [], Int8ArrayGetIndexed, 110819507)                              \
  V(Int8List, []=, Int8ArraySetIndexed, 865684695)                             \
  V(Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, 41288685)               \
  V(Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, 687206488)             \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    41288685)                                                                  \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    687206488)                                                                 \
  V(Int16List, [], Int16ArrayGetIndexed, 389863073)                            \
  V(Int16List, []=, Int16ArraySetIndexed, 855133756)                           \
  V(Uint16List, [], Uint16ArrayGetIndexed, 1053739567)                         \
  V(Uint16List, []=, Uint16ArraySetIndexed, 1547307961)                        \
  V(Int32List, [], Int32ArrayGetIndexed, 640610057)                            \
  V(Int32List, []=, Int32ArraySetIndexed, 453358705)                           \
  V(Int64List, [], Int64ArrayGetIndexed, 202150810)                            \
  V(Int64List, []=, Int64ArraySetIndexed, 924110852)                           \
  V(Float32x4List, [], Float32x4ArrayGetIndexed, 29819259)                     \
  V(Float32x4List, []=, Float32x4ArraySetIndexed, 1458062250)                  \
  V(Int32x4List, [], Int32x4ArrayGetIndexed, 137707405)                        \
  V(Int32x4List, []=, Int32x4ArraySetIndexed, 496650149)                       \
  V(Float64x2List, [], Float64x2ArrayGetIndexed, 1721439384)                   \
  V(Float64x2List, []=, Float64x2ArraySetIndexed, 1994027006)                  \
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


// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 1673522705)                                        \
  V(_Smi, get:bitLength, Smi_bitLength, 632480332)                             \
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
  V(_Double, get:isNaN, Double_getIsNaN, 184085483)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 978911030)                  \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 1893886883)               \
  V(_Double, .fromInteger, DoubleFromInteger, 2129942595)                      \
  V(_List, []=, ObjectArraySetIndexed, 886228780)                              \
  V(_GrowableList, .withData, GrowableArray_Allocate, 631736030)               \
  V(_GrowableList, add, GrowableArray_add, 219371757)                          \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, 1614206970)                   \
  V(Object, ==, ObjectEquals, 291909336)                                       \
  V(Object, get:runtimeType, ObjectRuntimeType, 15188587)                      \
  V(_StringBase, get:hashCode, String_getHashCode, 2026040200)                 \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 1958879178)                   \
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 1436590579)                 \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, 797253099)     \
  V(_StringBase, [], StringBaseCharAt, 754527301)                              \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 2026040200)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked, 1670133538)                              \
  V(_OneByteString, _setAt, OneByteStringSetAt, 1160066031)                    \
  V(_OneByteString, _allocate, OneByteString_allocate, 1028631946)             \
  V(_OneByteString, ==, OneByteString_equality, 1062844160)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 1062844160)                    \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    2042488139)                                                                \
  V(_IntegerImplementation, +, Integer_add, 239272130)                         \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, 957923759)\
  V(_IntegerImplementation, -, Integer_sub, 216175811)                         \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    2032062140)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 1301152164)                        \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    779285842)                                                                 \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 1018128256)               \
  V(_IntegerImplementation, unary-, Integer_negate, 1507648892)                \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    503046514)                                                                 \
  V(_IntegerImplementation, &, Integer_bitAnd, 1500136766)                     \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    1031383580)                                                                \
  V(_IntegerImplementation, |, Integer_bitOr, 119412028)                       \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    1339506501)                                                                \
  V(_IntegerImplementation, ^, Integer_bitXor, 210430781)                      \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, 780147656)                                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 673741711)                 \
  V(_IntegerImplementation, ==, Integer_equal, 272474439)                      \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    2004079901)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 652059836)                    \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 512138528)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 1815180096)          \
  V(_IntegerImplementation, <<, Integer_shl, 1127538624)                       \
  V(_IntegerImplementation, >>, Integer_sar, 1243972513)                       \
  V(_Double, toInt, DoubleToInteger, 653210699)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, 417912310)                                             \
  V(_Random, _nextState, Random_nextState, 508231939)                          \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, 65032)                                                   \
  V(::, cos, MathCos, 2006233918)                                              \
  V(::, tan, MathTan, 1276867325)                                              \
  V(::, asin, MathAsin, 1678592173)                                            \
  V(::, acos, MathAcos, 1121218433)                                            \
  V(::, atan, MathAtan, 1109653625)                                            \
  V(::, atan2, MathAtan2, 894696289)                                           \

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
  V(Uint8List, [], Uint8ArrayGetIndexed, 41288685)                             \
  V(Uint8List, []=, Uint8ArraySetIndexed, 101536342)                           \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 41288685)           \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 101536342)         \
  V(Uint32List, [], Uint32ArrayGetIndexed, 1614870523)                         \
  V(Uint32List, []=, Uint32ArraySetIndexed, 978194713)                         \
  V(Float64List, []=, Float64ArraySetIndexed, 328934501)                       \
  V(Float64List, [], Float64ArrayGetIndexed, 2049378701)                       \
  V(_TypedList, get:length, TypedDataLength, 546364442)                        \
  V(Float32x4, get:x, Float32x4ShuffleX, 1674625343)                           \
  V(Float32x4, get:y, Float32x4ShuffleY, 540293915)                            \
  V(Float32x4, get:z, Float32x4ShuffleZ, 320347578)                            \
  V(Float32x4, get:w, Float32x4ShuffleW, 1770606624)                           \
  V(Float32x4, _mul, Float32x4Mul, 42807622)                                   \
  V(Float32x4, _sub, Float32x4Sub, 103774455)                                  \
  V(Float32x4, _add, Float32x4Add, 1352634374)                                 \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, 630471378)                           \
  V(_List, [], ObjectArrayGetIndexed, 360400496)                               \
  V(_ImmutableList, get:length, ImmutableArrayLength, 630471378)               \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 360400496)                   \
  V(_GrowableList, get:length, GrowableArrayLength, 417111542)                 \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 41110914)             \
  V(_GrowableList, _setData, GrowableArraySetData, 210059283)                  \
  V(_GrowableList, _setLength, GrowableArraySetLength, 335652822)              \
  V(_GrowableList, [], GrowableArrayGetIndexed, 1957529650)                    \
  V(_GrowableList, []=, GrowableArraySetIndexed, 225246870)                    \
  V(_StringBase, get:length, StringBaseLength, 707533587)                      \
  V(_Double, unary-, DoubleFlipSignBit, 1783281169)                            \
  V(_Double, truncateToDouble, DoubleTruncate, 791143891)                      \
  V(_Double, roundToDouble, DoubleRound, 797558034)                            \
  V(_Double, floorToDouble, DoubleFloor, 1789426271)                           \
  V(_Double, ceilToDouble, DoubleCeil, 453271198)                              \
  V(_Double, _modulo, DoubleMod, 776062204)


#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, 187721469)                     \
  V(::, _getDefaultTag, UserTag_defaultTag, 350077879)                         \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 1215225901)                    \

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
  V(::, asin, MathASin, 1678592173)                                            \
  V(::, acos, MathACos, 1121218433)                                            \
  V(::, atan, MathATan, 1109653625)                                            \
  V(::, atan2, MathATan2, 894696289)                                           \
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
  V(_StringBase, codeUnitAt, StringBaseCodeUnitAt, 1436590579)                 \
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
