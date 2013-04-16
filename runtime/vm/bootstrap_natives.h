// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BOOTSTRAP_NATIVES_H_
#define VM_BOOTSTRAP_NATIVES_H_

#include "vm/native_entry.h"

// bootstrap dart natives used in the core dart library.

namespace dart {

// List of bootstrap native entry points used in the core dart library.
#define BOOTSTRAP_NATIVE_LIST(V)                                               \
  V(Object_toString, 1)                                                        \
  V(Object_noSuchMethod, 6)                                                    \
  V(Object_runtimeType, 1)                                                     \
  V(Object_instanceOf, 5)                                                      \
  V(Object_as, 4)                                                              \
  V(Function_apply, 2)                                                         \
  V(InvocationMirror_invoke, 4)                                                \
  V(AbstractType_toString, 1)                                                  \
  V(Identical_comparison, 2)                                                   \
  V(Integer_bitAndFromInteger, 2)                                              \
  V(Integer_bitOrFromInteger, 2)                                               \
  V(Integer_bitXorFromInteger, 2)                                              \
  V(Integer_addFromInteger, 2)                                                 \
  V(Integer_subFromInteger, 2)                                                 \
  V(Integer_mulFromInteger, 2)                                                 \
  V(Integer_truncDivFromInteger, 2)                                            \
  V(Integer_moduloFromInteger, 2)                                              \
  V(Integer_greaterThanFromInteger, 2)                                         \
  V(Integer_equalToInteger, 2)                                                 \
  V(Integer_parse, 1)                                                          \
  V(ReceivePortImpl_factory, 1)                                                \
  V(ReceivePortImpl_closeInternal, 1)                                          \
  V(SendPortImpl_sendInternal_, 3)                                             \
  V(Smi_shlFromInt, 2)                                                         \
  V(Smi_shrFromInt, 2)                                                         \
  V(Smi_bitNegate, 1)                                                          \
  V(Mint_bitNegate, 1)                                                         \
  V(Bigint_bitNegate, 1)                                                       \
  V(Double_getIsNegative, 1)                                                   \
  V(Double_getIsInfinite, 1)                                                   \
  V(Double_getIsNaN, 1)                                                        \
  V(Double_add, 2)                                                             \
  V(Double_sub, 2)                                                             \
  V(Double_mul, 2)                                                             \
  V(Double_div, 2)                                                             \
  V(Double_trunc_div, 2)                                                       \
  V(Double_remainder, 2)                                                       \
  V(Double_modulo, 2)                                                          \
  V(Double_greaterThanFromInteger, 2)                                          \
  V(Double_equalToInteger, 2)                                                  \
  V(Double_greaterThan, 2)                                                     \
  V(Double_equal, 2)                                                           \
  V(Double_doubleFromInteger, 2)                                               \
  V(Double_round, 1)                                                           \
  V(Double_floor, 1)                                                           \
  V(Double_ceil, 1)                                                            \
  V(Double_truncate, 1)                                                        \
  V(Double_toInt, 1)                                                           \
  V(Double_parse, 1)                                                           \
  V(Double_toStringAsFixed, 2)                                                 \
  V(Double_toStringAsExponential, 2)                                           \
  V(Double_toStringAsPrecision, 2)                                             \
  V(Double_pow, 2)                                                             \
  V(JSSyntaxRegExp_factory, 4)                                                 \
  V(JSSyntaxRegExp_getPattern, 1)                                              \
  V(JSSyntaxRegExp_getIsMultiLine, 1)                                          \
  V(JSSyntaxRegExp_getIsCaseSensitive, 1)                                      \
  V(JSSyntaxRegExp_getGroupCount, 1)                                           \
  V(JSSyntaxRegExp_ExecuteMatch, 3)                                            \
  V(ObjectArray_allocate, 2)                                                   \
  V(ObjectArray_getIndexed, 2)                                                 \
  V(ObjectArray_setIndexed, 3)                                                 \
  V(ObjectArray_getLength, 1)                                                  \
  V(ObjectArray_copyFromObjectArray, 5)                                        \
  V(StringBase_createFromCodePoints, 1)                                        \
  V(StringBase_substringUnchecked, 3)                                          \
  V(StringBuffer_createStringFromUint16Array, 3)                               \
  V(OneByteString_substringUnchecked, 3)                                       \
  V(OneByteString_splitWithCharCode, 2)                                        \
  V(String_getHashCode, 1)                                                     \
  V(String_getLength, 1)                                                       \
  V(String_charAt, 2)                                                          \
  V(String_codeUnitAt, 2)                                                      \
  V(String_concat, 2)                                                          \
  V(String_toLowerCase, 1)                                                     \
  V(String_toUpperCase, 1)                                                     \
  V(Strings_concatAll, 1)                                                      \
  V(Math_sqrt, 1)                                                              \
  V(Math_sin, 1)                                                               \
  V(Math_cos, 1)                                                               \
  V(Math_tan, 1)                                                               \
  V(Math_asin, 1)                                                              \
  V(Math_acos, 1)                                                              \
  V(Math_atan, 1)                                                              \
  V(Math_atan2, 2)                                                             \
  V(Math_exp, 1)                                                               \
  V(Math_log, 1)                                                               \
  V(DateNatives_currentTimeMillis, 0)                                          \
  V(DateNatives_timeZoneName, 1)                                               \
  V(DateNatives_timeZoneOffsetInSeconds, 1)                                    \
  V(DateNatives_localTimeZoneAdjustmentInSeconds, 0)                           \
  V(AssertionError_throwNew, 2)                                                \
  V(TypeError_throwNew, 5)                                                     \
  V(FallThroughError_throwNew, 1)                                              \
  V(AbstractClassInstantiationError_throwNew, 2)                               \
  V(Stacktrace_getFullStacktrace, 1)                                           \
  V(Stacktrace_getStacktrace, 1)                                               \
  V(Stacktrace_setupFullStacktrace, 1)                                         \
  V(Stopwatch_now, 0)                                                          \
  V(Stopwatch_frequency, 0)                                                    \
  V(TypedData_Int8Array_new, 1)                                                \
  V(TypedData_Uint8Array_new, 1)                                               \
  V(TypedData_Uint8ClampedArray_new, 1)                                        \
  V(TypedData_Int16Array_new, 1)                                               \
  V(TypedData_Uint16Array_new, 1)                                              \
  V(TypedData_Int32Array_new, 1)                                               \
  V(TypedData_Uint32Array_new, 1)                                              \
  V(TypedData_Int64Array_new, 1)                                               \
  V(TypedData_Uint64Array_new, 1)                                              \
  V(TypedData_Float32Array_new, 1)                                             \
  V(TypedData_Float64Array_new, 1)                                             \
  V(TypedData_Float32x4Array_new, 1)                                           \
  V(ExternalTypedData_Int8Array_new, 1)                                        \
  V(ExternalTypedData_Uint8Array_new, 1)                                       \
  V(ExternalTypedData_Uint8ClampedArray_new, 1)                                \
  V(ExternalTypedData_Int16Array_new, 1)                                       \
  V(ExternalTypedData_Uint16Array_new, 1)                                      \
  V(ExternalTypedData_Int32Array_new, 1)                                       \
  V(ExternalTypedData_Uint32Array_new, 1)                                      \
  V(ExternalTypedData_Int64Array_new, 1)                                       \
  V(ExternalTypedData_Uint64Array_new, 1)                                      \
  V(ExternalTypedData_Float32Array_new, 1)                                     \
  V(ExternalTypedData_Float64Array_new, 1)                                     \
  V(ExternalTypedData_Float32x4Array_new, 1)                                   \
  V(TypedData_length, 1)                                                       \
  V(TypedData_setRange, 5)                                                     \
  V(TypedData_GetInt8, 2)                                                      \
  V(TypedData_SetInt8, 3)                                                      \
  V(TypedData_GetUint8, 2)                                                     \
  V(TypedData_SetUint8, 3)                                                     \
  V(TypedData_GetInt16, 2)                                                     \
  V(TypedData_SetInt16, 3)                                                     \
  V(TypedData_GetUint16, 2)                                                    \
  V(TypedData_SetUint16, 3)                                                    \
  V(TypedData_GetInt32, 2)                                                     \
  V(TypedData_SetInt32, 3)                                                     \
  V(TypedData_GetUint32, 2)                                                    \
  V(TypedData_SetUint32, 3)                                                    \
  V(TypedData_GetInt64, 2)                                                     \
  V(TypedData_SetInt64, 3)                                                     \
  V(TypedData_GetUint64, 2)                                                    \
  V(TypedData_SetUint64, 3)                                                    \
  V(TypedData_GetFloat32, 2)                                                   \
  V(TypedData_SetFloat32, 3)                                                   \
  V(TypedData_GetFloat64, 2)                                                   \
  V(TypedData_SetFloat64, 3)                                                   \
  V(TypedData_GetFloat32x4, 2)                                                 \
  V(TypedData_SetFloat32x4, 3)                                                 \
  V(Float32x4_fromDoubles, 5)                                                  \
  V(Float32x4_zero, 1)                                                         \
  V(Float32x4_add, 2)                                                          \
  V(Float32x4_negate, 1)                                                       \
  V(Float32x4_sub, 2)                                                          \
  V(Float32x4_mul, 2)                                                          \
  V(Float32x4_div, 2)                                                          \
  V(Float32x4_cmplt, 2)                                                        \
  V(Float32x4_cmplte, 2)                                                       \
  V(Float32x4_cmpgt, 2)                                                        \
  V(Float32x4_cmpgte, 2)                                                       \
  V(Float32x4_cmpequal, 2)                                                     \
  V(Float32x4_cmpnequal, 2)                                                    \
  V(Float32x4_scale, 2)                                                        \
  V(Float32x4_abs, 1)                                                          \
  V(Float32x4_clamp, 3)                                                        \
  V(Float32x4_getX, 1)                                                         \
  V(Float32x4_getY, 1)                                                         \
  V(Float32x4_getZ, 1)                                                         \
  V(Float32x4_getW, 1)                                                         \
  V(Float32x4_getXXXX, 1)                                                      \
  V(Float32x4_getYYYY, 1)                                                      \
  V(Float32x4_getZZZZ, 1)                                                      \
  V(Float32x4_getWWWW, 1)                                                      \
  V(Float32x4_setX, 2)                                                         \
  V(Float32x4_setY, 2)                                                         \
  V(Float32x4_setZ, 2)                                                         \
  V(Float32x4_setW, 2)                                                         \
  V(Float32x4_min, 2)                                                          \
  V(Float32x4_max, 2)                                                          \
  V(Float32x4_sqrt, 1)                                                         \
  V(Float32x4_reciprocal, 1)                                                   \
  V(Float32x4_reciprocalSqrt, 1)                                               \
  V(Float32x4_toUint32x4, 1)                                                   \
  V(Uint32x4_fromInts, 5)                                                      \
  V(Uint32x4_fromBools, 5)                                                     \
  V(Uint32x4_or, 2)                                                            \
  V(Uint32x4_and, 2)                                                           \
  V(Uint32x4_xor, 2)                                                           \
  V(Uint32x4_getX, 1)                                                          \
  V(Uint32x4_getY, 1)                                                          \
  V(Uint32x4_getZ, 1)                                                          \
  V(Uint32x4_getW, 1)                                                          \
  V(Uint32x4_setX, 2)                                                          \
  V(Uint32x4_setY, 2)                                                          \
  V(Uint32x4_setZ, 2)                                                          \
  V(Uint32x4_setW, 2)                                                          \
  V(Uint32x4_getFlagX, 1)                                                      \
  V(Uint32x4_getFlagY, 1)                                                      \
  V(Uint32x4_getFlagZ, 1)                                                      \
  V(Uint32x4_getFlagW, 1)                                                      \
  V(Uint32x4_setFlagX, 2)                                                      \
  V(Uint32x4_setFlagY, 2)                                                      \
  V(Uint32x4_setFlagZ, 2)                                                      \
  V(Uint32x4_setFlagW, 2)                                                      \
  V(Uint32x4_select, 3)                                                        \
  V(Uint32x4_toFloat32x4, 1)                                                   \
  V(isolate_getPortInternal, 0)                                                \
  V(isolate_spawnFunction, 2)                                                  \
  V(isolate_spawnUri, 1)                                                       \
  V(Mirrors_isLocalPort, 1)                                                    \
  V(Mirrors_makeLocalInstanceMirror, 1)                                        \
  V(Mirrors_makeLocalMirrorSystem, 0)                                          \
  V(LocalObjectMirrorImpl_invoke, 4)                                           \
  V(LocalObjectMirrorImpl_getField, 2)                                         \
  V(LocalObjectMirrorImpl_setField, 4)                                         \
  V(LocalClosureMirrorImpl_apply, 3)                                           \
  V(LocalClassMirrorImpl_invokeConstructor, 4)                                 \
  V(GrowableObjectArray_allocate, 2)                                           \
  V(GrowableObjectArray_getIndexed, 2)                                         \
  V(GrowableObjectArray_setIndexed, 3)                                         \
  V(GrowableObjectArray_getLength, 1)                                          \
  V(GrowableObjectArray_getCapacity, 1)                                        \
  V(GrowableObjectArray_setLength, 2)                                          \
  V(GrowableObjectArray_setData, 2)                                            \
  V(WeakProperty_new, 2)                                                       \
  V(WeakProperty_getKey, 1)                                                    \
  V(WeakProperty_getValue, 1)                                                  \
  V(WeakProperty_setValue, 2)                                                  \

class BootstrapNatives : public AllStatic {
 public:
  static Dart_NativeFunction Lookup(Dart_Handle name, int argument_count);

#define DECLARE_BOOTSTRAP_NATIVE(name, ignored)                                \
  static void DN_##name(Dart_NativeArguments args);

  BOOTSTRAP_NATIVE_LIST(DECLARE_BOOTSTRAP_NATIVE)

#undef DECLARE_BOOTSTRAP_NATIVE
};

}  // namespace dart

#endif  // VM_BOOTSTRAP_NATIVES_H_
