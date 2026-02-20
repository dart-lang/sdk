// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart';

/// Kernel nodes for classes and members referenced specifically by the
/// compiler.
mixin KernelNodes {
  LibraryIndex get index;

  CoreTypes get coreTypes;

  // dart:_internal classes
  late final Class symbolClass = index.getClass("dart:_internal", "Symbol");

  // dart:_js_types classes
  late final Class jsStringClass =
      index.getClass("dart:_string", "JSStringImpl");

  // dart:collection classes
  late final Class hashFieldBaseClass =
      index.getClass("dart:_compact_hash", "_HashFieldBase");
  late final Class immutableMapClass =
      index.getClass("dart:_compact_hash", "_ConstMap");
  late final Class immutableSetClass =
      index.getClass("dart:_compact_hash", "_ConstSet");

  // dart:core various classes
  late final Class boxedBoolClass =
      index.getClass("dart:_boxed_bool", "BoxedBool");
  late final Class boxedDoubleClass =
      index.getClass("dart:_boxed_double", "BoxedDouble");
  late final Class boxedIntClass =
      index.getClass("dart:_boxed_int", "BoxedInt");
  late final Class closureClass = index.getClass("dart:core", "_Closure");
  late final Class listBaseClass = index.getClass("dart:_list", "WasmListBase");
  late final Field listBaseLengthField =
      index.getField("dart:_list", "WasmListBase", "_length");
  late final Field listBaseDataField =
      index.getField("dart:_list", "WasmListBase", "_data");
  late final Procedure listBaseIndexOperator =
      index.getProcedure("dart:_list", "WasmListBase", "[]");
  late final Class fixedLengthListClass =
      index.getClass("dart:_list", "ModifiableFixedLengthList");
  late final Class growableListClass =
      index.getClass("dart:_list", "GrowableList");
  late final Class immutableListClass =
      index.getClass("dart:_list", "ImmutableList");
  late final Class invocationClass = index.getClass("dart:core", 'Invocation');
  late final Class noSuchMethodErrorClass =
      index.getClass("dart:core", "NoSuchMethodError");
  late final Class typeErrorClass = index.getClass("dart:core", "_TypeError");
  late final Class javaScriptErrorClass =
      index.getClass("dart:core", "_JavaScriptError");
  late final Field enumIndexField =
      index.getField('dart:core', '_Enum', 'index');

  // dart:core runtime type classes
  late final Class typeClass = index.getClass("dart:core", "_Type");
  late final Field typeIsDeclaredNullableField =
      index.getField("dart:core", "_Type", "isDeclaredNullable");
  late final InterfaceType typeType =
      InterfaceType(typeClass, Nullability.nonNullable);
  late final Class abstractFunctionTypeClass =
      index.getClass("dart:core", "_AbstractFunctionType");
  late final Class functionTypeClass =
      index.getClass("dart:core", "_FunctionType");
  late final Field functionTypeTypeParameterOffsetField =
      index.getField("dart:core", "_FunctionType", "typeParameterOffset");
  late final Field functionTypeTypeParameterBoundsField =
      index.getField("dart:core", "_FunctionType", "typeParameterBounds");
  late final Field functionTypeTypeParameterDefaultsField =
      index.getField("dart:core", "_FunctionType", "typeParameterDefaults");
  late final Field functionTypeReturnTypeField =
      index.getField("dart:core", "_FunctionType", "returnType");
  late final Field functionTypePositionalParametersField =
      index.getField("dart:core", "_FunctionType", "positionalParameters");
  late final Field functionTypeRequiredParameterCountField =
      index.getField("dart:core", "_FunctionType", "requiredParameterCount");
  late final Field functionTypeTypeParameterNamedParamsField =
      index.getField("dart:core", "_FunctionType", "namedParameters");
  late final Class functionTypeParameterTypeClass =
      index.getClass("dart:core", "_FunctionTypeParameterType");
  late final Field functionTypeParameterTypeIndexField =
      index.getField("dart:core", "_FunctionTypeParameterType", "index");
  late final Class futureOrTypeClass =
      index.getClass("dart:core", "_FutureOrType");
  late final Field futureOrTypeTypeArgumentField =
      index.getField("dart:core", "_FutureOrType", "typeArgument");
  late final Class interfaceTypeClass =
      index.getClass("dart:core", "_InterfaceType");
  late final Field interfaceTypeClassIdField =
      index.getField("dart:core", "_InterfaceType", "classId");
  late final Field interfaceTypeTypeArguments =
      index.getField("dart:core", "_InterfaceType", "typeArguments");
  late final Class interfaceTypeParameterTypeClass =
      index.getClass("dart:core", "_InterfaceTypeParameterType");
  late final Field interfaceTypeParameterTypeEnvironmentIndexField = index
      .getField("dart:core", "_InterfaceTypeParameterType", "environmentIndex");
  late final Class namedParameterClass =
      index.getClass("dart:core", "_NamedParameter");
  late final Field namedParameterNameField =
      index.getField("dart:core", "_NamedParameter", "name");
  late final Field namedParameterTypeField =
      index.getField("dart:core", "_NamedParameter", "type");
  late final Field namedParameterIsRequiredField =
      index.getField("dart:core", "_NamedParameter", "isRequired");
  late final InterfaceType namedParameterType =
      InterfaceType(namedParameterClass, Nullability.nonNullable);
  late final Class bottomTypeClass = index.getClass("dart:core", "_BottomType");
  late final Class topTypeClass = index.getClass("dart:core", "_TopType");
  late final Field topTypeKindField =
      index.getField("dart:core", "_TopType", "_kind");
  late final Class stackTraceClass = index.getClass("dart:core", "StackTrace");
  late final Class abstractRecordTypeClass =
      index.getClass("dart:core", "_AbstractRecordType");
  late final Class recordTypeClass = index.getClass("dart:core", "_RecordType");
  late final Field recordTypeFieldTypesField =
      index.getField("dart:core", "_RecordType", "fieldTypes");
  late final Field recordTypeNamesField =
      index.getField("dart:core", "_RecordType", "names");
  late final Class moduleRtt = index.getClass("dart:core", "_ModuleRtt");
  late final Field moduleRttOffsets =
      index.getField("dart:core", "_ModuleRtt", "typeRowDisplacementOffsets");
  late final Field moduleRttDisplacementTable =
      index.getField("dart:core", "_ModuleRtt", "typeRowDisplacementTable");
  late final Field moduleRttDisplacementSubstTable = index.getField(
      "dart:core", "_ModuleRtt", "typeRowDisplacementSubstTable");
  late final Field moduleRttSubstTable =
      index.getField("dart:core", "_ModuleRtt", "canonicalSubstitutionTable");
  late final Field moduleRttTypeNames =
      index.getField("dart:core", "_ModuleRtt", "typeNames");
  late final Procedure registerModuleRtt =
      index.getTopLevelProcedure("dart:core", "_registerModuleRtt");

  // dart:core sync* support classes
  late final Class suspendStateClass =
      index.getClass("dart:core", "_SuspendState");
  late final Class syncStarIterableClass =
      index.getClass("dart:core", "_SyncStarIterable");
  late final Class syncStarIteratorClass =
      index.getClass("dart:core", "_SyncStarIterator");

  // async support classes
  late final Class asyncSuspendStateClass =
      index.getClass("dart:async", "_AsyncSuspendState");
  late final Procedure awaitHelper =
      index.getTopLevelProcedure("dart:async", "_awaitHelper");
  late final Procedure awaitHelperWithTypeCheck =
      index.getTopLevelProcedure("dart:async", "_awaitHelperWithTypeCheck");
  late final Procedure newAsyncSuspendState =
      index.getTopLevelProcedure("dart:async", "_newAsyncSuspendState");

  late final Procedure asyncSuspendStateComplete =
      index.getProcedure("dart:async", "_AsyncSuspendState", "_complete");
  late final Procedure asyncSuspendStateCompleteError =
      index.getProcedure("dart:async", "_AsyncSuspendState", "_completeError");
  late final Procedure makeFuture =
      index.getTopLevelProcedure("dart:async", "_makeFuture");

  // dart:ffi classes
  late final Class ffiPointerClass = index.getClass("dart:ffi", "Pointer");

  // dart:_wasm classes
  late final Library wasmLibrary = index.getLibrary("dart:_wasm");
  late final Class wasmTypesBaseClass =
      index.getClass("dart:_wasm", "_WasmBase");
  late final wasmI8Class = index.getClass("dart:_wasm", "WasmI8");
  late final wasmI16Class = index.getClass("dart:_wasm", "WasmI16");
  late final wasmI32Class = index.getClass("dart:_wasm", "WasmI32");
  late final wasmI32Value = index.getField("dart:_wasm", "WasmI32", "_value");
  late final wasmI64Class = index.getClass("dart:_wasm", "WasmI64");
  late final wasmF32Class = index.getClass("dart:_wasm", "WasmF32");
  late final wasmF64Class = index.getClass("dart:_wasm", "WasmF64");
  late final wasmV128Class = index.getClass("dart:_wasm", "WasmV128");
  late final Class wasmAnyRefClass = index.getClass("dart:_wasm", "WasmAnyRef");
  late final Class wasmExternRefClass =
      index.getClass("dart:_wasm", "WasmExternRef");
  late final Class wasmFuncRefClass =
      index.getClass("dart:_wasm", "WasmFuncRef");
  late final Class wasmEqRefClass = index.getClass("dart:_wasm", "WasmEqRef");
  late final Class wasmStructRefClass =
      index.getClass("dart:_wasm", "WasmStructRef");
  late final Class wasmArrayRefClass =
      index.getClass("dart:_wasm", "WasmArrayRef");
  late final Class wasmFunctionClass =
      index.getClass("dart:_wasm", "WasmFunction");
  late final Class wasmVoidClass = index.getClass("dart:_wasm", "WasmVoid");
  late final Class wasmTableClass = index.getClass("dart:_wasm", "WasmTable");
  late final Class wasmI31RefClass = index.getClass("dart:_wasm", "WasmI31Ref");
  late final Class wasmArrayClass = index.getClass("dart:_wasm", "WasmArray");
  late final Class immutableWasmArrayClass =
      index.getClass("dart:_wasm", "ImmutableWasmArray");
  late final Field wasmArrayValueField =
      index.getField("dart:_wasm", "WasmArray", "_value");
  late final Field immutableWasmArrayValueField =
      index.getField("dart:_wasm", "ImmutableWasmArray", "_value");
  late final Field uninitializedHashBaseIndex = index.getTopLevelField(
      "dart:_compact_hash", "_uninitializedHashBaseIndex");
  late final Field wasmI64ValueField =
      index.getField("dart:_wasm", "WasmI64", "_value");

  late final Class wasmMemoryClass = index.getClass('dart:_wasm', 'Memory');
  late final Class wasmMemoryTypeClass =
      index.getClass('dart:_wasm', 'MemoryType');
  late final Field wasmLimitsMinimum =
      index.getField('dart:_wasm', 'Limits', 'minimum');
  late final Field wasmLimitsMaximum =
      index.getField('dart:_wasm', 'Limits', 'maximum');

  // dart:_js_helper procedures
  late final Procedure getInternalizedString =
      index.getTopLevelProcedure("dart:_js_helper", "getInternalizedString");
  late final Procedure areEqualInJS =
      index.getTopLevelProcedure("dart:_js_helper", "areEqualInJS");
  late final Procedure toJSNumber =
      index.getTopLevelProcedure("dart:_js_helper", "toJSNumber");

  // dart:_js_types procedures
  late final Procedure jsStringEquals =
      index.getProcedure("dart:_string", "JSStringImpl", "==");
  late final Procedure jsStringInterpolate =
      index.getProcedure("dart:_string", "JSStringImpl", "_interpolate");
  late final Procedure jsStringInterpolate1 =
      index.getProcedure("dart:_string", "JSStringImpl", "_interpolate1");
  late final Procedure jsStringInterpolate2 =
      index.getProcedure("dart:_string", "JSStringImpl", "_interpolate2");
  late final Procedure jsStringInterpolate3 =
      index.getProcedure("dart:_string", "JSStringImpl", "_interpolate3");
  late final Procedure jsStringInterpolate4 =
      index.getProcedure("dart:_string", "JSStringImpl", "_interpolate4");

  // dart:collection procedures and fields
  late final Procedure mapFactory =
      index.getProcedure("dart:collection", "LinkedHashMap", "_default");
  late final Procedure mapFromWasmArray =
      index.getProcedure("dart:_compact_hash", "DefaultMap", "fromWasmArray");
  late final Procedure setFactory =
      index.getProcedure("dart:collection", "LinkedHashSet", "_default");
  late final Procedure setFromWasmArray =
      index.getProcedure("dart:_compact_hash", "DefaultSet", "fromWasmArray");
  late final Procedure growableListEmpty =
      index.getProcedure("dart:_list", "GrowableList", "empty");
  late final Constructor growableListFromWasmArray =
      index.getConstructor("dart:_list", "GrowableList", "_withData");
  late final Procedure hashImmutableIndexNullable = index.getProcedure(
      "dart:collection", "_HashAbstractImmutableBase", "get:_indexNullable");
  late final Field hashFieldBaseIndexField =
      index.getField("dart:_compact_hash", "_HashFieldBase", "_index");
  late final Field hashFieldBaseHashMaskField =
      index.getField("dart:_compact_hash", "_HashFieldBase", "_hashMask");
  late final Field hashFieldBaseDataField =
      index.getField("dart:_compact_hash", "_HashFieldBase", "_data");
  late final Field hashFieldBaseUsedDataField =
      index.getField("dart:_compact_hash", "_HashFieldBase", "_usedData");
  late final Field hashFieldBaseDeletedKeysField =
      index.getField("dart:_compact_hash", "_HashFieldBase", "_deletedKeys");

  // dart:core various procedures
  late final Procedure boxedBoolEquals =
      index.getProcedure("dart:_boxed_bool", "BoxedBool", "==");
  late final Procedure boxedIntEquals =
      index.getProcedure("dart:_boxed_int", "BoxedInt", "==");
  late final Procedure objectHashCode =
      index.getProcedure("dart:core", "Object", "get:hashCode");
  late final Procedure objectNoSuchMethod =
      index.getProcedure("dart:core", "Object", "noSuchMethod");
  late final Procedure objectGetTypeArguments =
      index.getProcedure("dart:core", "Object", "_getTypeArguments");
  late final Procedure objectTypeArguments =
      index.getProcedure("dart:core", "Object", "get:_typeArguments");
  late final Procedure nullToString =
      index.getProcedure("dart:core", "Object", "_nullToString");
  late final Procedure nullNoSuchMethod =
      index.getProcedure("dart:core", "Object", "_nullNoSuchMethod");
  late final Procedure truncDiv =
      index.getProcedure("dart:_boxed_int", "BoxedInt", "_truncDiv");
  late final Procedure runtimeTypeEquals =
      index.getTopLevelProcedure("dart:core", "_runtimeTypeEquals");
  late final Procedure runtimeTypeHashCode =
      index.getTopLevelProcedure("dart:core", "_runtimeTypeHashCode");
  late final Procedure? functionApply =
      index.tryGetProcedure('dart:core', 'Function', 'apply');

  // dart:core invocation/exception procedures
  late final Procedure invocationGetterFactory =
      index.getProcedure("dart:core", "Invocation", "getter");
  late final Procedure invocationSetterFactory =
      index.getProcedure("dart:core", "Invocation", "setter");
  late final Procedure invocationMethodFactory =
      index.getProcedure("dart:core", "Invocation", "method");
  late final Procedure invocationGenericMethodFactory =
      index.getProcedure("dart:core", "Invocation", "genericMethod");
  late final Procedure noSuchMethodErrorThrowWithInvocation = index
      .getProcedure("dart:core", "NoSuchMethodError", "_throwWithInvocation");
  late final Procedure noSuchMethodErrorThrowUnimplementedExternalMemberError =
      index.getProcedure("dart:core", "NoSuchMethodError",
          "_throwUnimplementedExternalMemberError");
  late final Procedure stackTraceCurrent =
      index.getProcedure("dart:core", "StackTrace", "get:current");
  late final Procedure throwNullCheckErrorWithCurrentStack = index.getProcedure(
      "dart:core", "_TypeError", "_throwNullCheckErrorWithCurrentStack");
  late final Procedure throwAsCheckError =
      index.getProcedure("dart:core", "_TypeError", "_throwAsCheckError");
  late final Procedure throwErrorWithoutDetails =
      index.getTopLevelProcedure("dart:core", "_throwErrorWithoutDetails");
  late final Procedure throwInterfaceTypeAsCheckError1 = index
      .getTopLevelProcedure("dart:core", "_throwInterfaceTypeAsCheckError1");
  late final Procedure throwInterfaceTypeAsCheckError2 = index
      .getTopLevelProcedure("dart:core", "_throwInterfaceTypeAsCheckError2");
  late final Procedure throwInterfaceTypeAsCheckError = index
      .getTopLevelProcedure("dart:core", "_throwInterfaceTypeAsCheckError");
  late final Procedure throwWasmRefError =
      index.getProcedure("dart:core", "_TypeError", "_throwWasmRefError");
  late final Procedure throwArgumentTypeCheckError = index.getProcedure(
      "dart:core", "_TypeError", "_throwArgumentTypeCheckError");
  late final Procedure throwTypeArgumentBoundCheckError = index.getProcedure(
      "dart:core", "_TypeError", "_throwTypeArgumentBoundCheckError");
  late final Procedure throwAssertionError =
      index.getProcedure("dart:core", "AssertionError", "_throwWithMessage");
  late final Procedure javaScriptErrorFactory =
      index.getProcedure("dart:core", "_JavaScriptError", "_");
  late final Procedure javaScriptErrorStackTraceGetter =
      index.getProcedure("dart:core", "_JavaScriptError", "get:stackTrace");
  late final Procedure rangeErrorCheckValueInInterval =
      index.getProcedure("dart:core", "RangeError", "checkValueInInterval");
  late final Class errorClass = index.getClass("dart:core", "Error");
  late final Field errorClassStackTraceField =
      index.getField("dart:core", "Error", "_stackTrace");
  late final Procedure errorThrow =
      index.getProcedure("dart:core", "Error", "_throw");
  late final Procedure errorThrowWithCurrentStackTrace =
      index.getProcedure("dart:core", "Error", "_throwWithCurrentStackTrace");

  // dart:core type procedures
  late final Procedure getClosureRuntimeType =
      index.getProcedure("dart:core", '_Closure', "_getClosureRuntimeType");
  late final Procedure getMasqueradedRuntimeType =
      index.getTopLevelProcedure("dart:core", "_getMasqueradedRuntimeType");
  late final Procedure isNullabilityCheck =
      index.getTopLevelProcedure("dart:core", "_isNullabilityCheck");
  late final Procedure isSubtype =
      index.getTopLevelProcedure("dart:core", "_isSubtype");
  late final Procedure isInterfaceSubtype =
      index.getTopLevelProcedure("dart:core", "_isInterfaceSubtype");
  late final Procedure isInterfaceSubtype0 =
      index.getTopLevelProcedure("dart:core", "_isInterfaceSubtype0");
  late final Procedure isInterfaceSubtype1 =
      index.getTopLevelProcedure("dart:core", "_isInterfaceSubtype1");
  late final Procedure isInterfaceSubtype2 =
      index.getTopLevelProcedure("dart:core", "_isInterfaceSubtype2");
  late final Procedure asSubtype =
      index.getTopLevelProcedure("dart:core", "_asSubtype");
  late final Procedure asInterfaceSubtype =
      index.getTopLevelProcedure("dart:core", "_asInterfaceSubtype");
  late final Procedure asInterfaceSubtype0 =
      index.getTopLevelProcedure("dart:core", "_asInterfaceSubtype0");
  late final Procedure asInterfaceSubtype1 =
      index.getTopLevelProcedure("dart:core", "_asInterfaceSubtype1");
  late final Procedure asInterfaceSubtype2 =
      index.getTopLevelProcedure("dart:core", "_asInterfaceSubtype2");
  late final Procedure isTypeSubtype =
      index.getTopLevelProcedure("dart:core", "_isTypeSubtype");
  late final Procedure verifyOptimizedTypeCheck =
      index.getTopLevelProcedure("dart:core", "_verifyOptimizedTypeCheck");
  late final Procedure checkClosureShape =
      index.getTopLevelProcedure("dart:core", "_checkClosureShape");
  late final Procedure checkClosureType =
      index.getTopLevelProcedure("dart:core", "_checkClosureType");
  late final Procedure typeAsNullable =
      index.getProcedure("dart:core", "_Type", "get:asNullable");
  late final Procedure createNormalizedFutureOrType = index.getProcedure(
      "dart:core", "_TypeUniverse", "createNormalizedFutureOrType");
  late final Procedure substituteFunctionTypeArgument = index.getProcedure(
      "dart:core", "_TypeUniverse", "substituteFunctionTypeArgument");

  // dart:core dynamic invocation helper procedures
  late final Procedure getNamedParameterIndex =
      index.getTopLevelProcedure("dart:core", "_getNamedParameterIndex");
  late final Procedure typeArgumentsToList =
      index.getTopLevelProcedure("dart:core", "_typeArgumentsToList");
  late final Procedure positionalParametersToList =
      index.getTopLevelProcedure("dart:core", "_positionalParametersToList");
  late final Procedure namedParametersToMap =
      index.getTopLevelProcedure("dart:core", "_namedParametersToMap");
  late final Procedure namedParameterMapToArray =
      index.getTopLevelProcedure("dart:core", "_namedParameterMapToArray");
  late final Procedure listOf =
      index.getProcedure("dart:_list", "ModifiableFixedLengthList", "of");

  // dart:_wasm procedures
  late final Procedure wasmFunctionCall =
      index.getProcedure("dart:_wasm", "WasmFunction", "get:call");
  late final Procedure wasmTableCallIndirect =
      index.getProcedure("dart:_wasm", "WasmTable", "callIndirect");

  // Hash utils
  late final Field hashSeed = index.getTopLevelField('dart:core', '_hashSeed');
  late final Procedure systemHashCombine =
      index.getProcedure("dart:_internal", "SystemHash", "combine");

  // Dynamic module helpers
  late final Class constCacheClass =
      index.getClass('dart:_internal', 'WasmConstCache');
  late final Constructor constCacheInit =
      index.getConstructor('dart:_internal', 'WasmConstCache', '');
  late final Procedure constCacheCanonicalize = index.getProcedure(
      'dart:_internal', 'WasmConstCache', 'canonicalizeValue');
  late final Procedure constCacheArrayCanonicalize = index.getProcedure(
      'dart:_internal', 'WasmArrayConstCache', 'canonicalizeArrayValue');
  late final Procedure dummyValueConstCanonicalize = index.getProcedure(
      'dart:_internal', 'DummyValueConstCache', 'canonicalizeDummyValue');
  late final Procedure registerUpdateableFuncRefs = index.getTopLevelProcedure(
      'dart:_internal', 'registerUpdateableFuncRefs');
  late final Procedure getUpdateableFuncRef =
      index.getTopLevelProcedure('dart:_internal', 'getUpdateableFuncRef');
  late final Procedure classIdToModuleId =
      index.getTopLevelProcedure('dart:_internal', 'classIdToModuleId');
  late final Procedure localizeClassId =
      index.getTopLevelProcedure('dart:_internal', 'localizeClassId');
  late final Procedure scopeClassId =
      index.getTopLevelProcedure('dart:_internal', 'scopeClassId');
  late final Procedure globalizeClassId =
      index.getTopLevelProcedure('dart:_internal', 'globalizeClassId');
  late final Procedure registerModuleClassRange =
      index.getTopLevelProcedure('dart:_internal', 'registerModuleClassRange');
  late final Procedure constCacheGetter =
      index.getTopLevelProcedure('dart:_internal', 'getConstCache');
  late final Field objectConstArrayCache =
      index.getTopLevelField('dart:_internal', 'objectConstArray');
  late final Field stringConstArrayCache =
      index.getTopLevelField('dart:_internal', 'stringConstArray');
  late final Field stringConstImmutableArrayCache =
      index.getTopLevelField('dart:_internal', 'stringConstImmutableArray');
  late final Field typeConstArrayCache =
      index.getTopLevelField('dart:_internal', 'typeConstArray');
  late final Field typeArrayConstArrayCache =
      index.getTopLevelField('dart:_internal', 'typeArrayConstArray');
  late final Field namedParameterConstArrayCache =
      index.getTopLevelField('dart:_internal', 'nameParameterConstArray');
  late final Field i8ConstImmutableArrayCache =
      index.getTopLevelField('dart:_internal', 'i8ConstImmutableArray');
  late final Field i32ConstArrayCache =
      index.getTopLevelField('dart:_internal', 'i32ConstArray');
  late final Field i16ConstArrayCache =
      index.getTopLevelField('dart:_internal', 'i16ConstArray');
  late final Field i64ConstImmutableArrayCache =
      index.getTopLevelField('dart:_internal', 'i64ConstImmutableArray');
  late final Field boxedIntImmutableArrayCache =
      index.getTopLevelField('dart:_internal', 'boxedIntImmutableArray');

  // Deferred loading.
  late final Procedure? checkLibraryIsLoadedFromLoadId = index.tryGetProcedure(
      'dart:_internal',
      LibraryIndex.topLevel,
      'checkLibraryIsLoadedFromLoadId');
  late final Procedure? dartInternalLoadingMapGetter = index.tryGetProcedure(
      'dart:_internal', LibraryIndex.topLevel, 'get:_loadingMap');
  late final Procedure? dartInternalLoadingMapNamesGetter =
      index.tryGetProcedure(
          'dart:_internal', LibraryIndex.topLevel, 'get:_loadingMapNames');

  // Debugging
  late final Procedure printToConsole =
      index.getTopLevelProcedure("dart:_internal", "printToConsole");

  late final Map<Member, (Extension, ExtensionMemberDescriptor)>
      _extensionCache = {};

  late final Map<InterfaceType, Field> wasmArrayConstCache = {
    _makeElementType(coreTypes.objectClass, nullable: true):
        objectConstArrayCache,
    _makeElementType(typeClass): typeConstArrayCache,
    _makeElementType(namedParameterClass): namedParameterConstArrayCache,
    _makeElementType(coreTypes.stringClass): stringConstArrayCache,
    _makeElementType(wasmI32Class): i32ConstArrayCache,
    _makeElementType(wasmI16Class): i16ConstArrayCache,
    _makeElementType(wasmArrayClass,
        typeArguments: [_makeElementType(typeClass)]): typeArrayConstArrayCache,
  };
  late final Map<InterfaceType, Field> immutableWasmArrayConstCache = {
    _makeElementType(coreTypes.stringClass): stringConstImmutableArrayCache,
    _makeElementType(wasmI8Class): i8ConstImmutableArrayCache,
    _makeElementType(wasmI64Class): i64ConstImmutableArrayCache,
    _makeElementType(boxedIntClass): boxedIntImmutableArrayCache,
  };

  InterfaceType _makeElementType(Class c,
          {bool nullable = false, List<InterfaceType>? typeArguments}) =>
      InterfaceType(
          c,
          nullable ? Nullability.nullable : Nullability.nonNullable,
          typeArguments);

  (Extension, ExtensionMemberDescriptor) extensionOfMember(Member member) {
    return _extensionCache.putIfAbsent(member, () {
      assert(member.isExtensionMember);

      final memberRef = member.reference;
      for (final ext in member.enclosingLibrary.extensions) {
        for (final descriptor in ext.memberDescriptors) {
          if (memberRef == descriptor.memberReference) {
            return (ext, descriptor);
          }
        }
      }
      throw 'Did not find extension for $member';
    });
  }
}
