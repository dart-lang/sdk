// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart';

/// Kernel nodes for classes and members referenced specifically by the
/// compiler.
mixin KernelNodes {
  Component get component;

  late final LibraryIndex index = LibraryIndex(component, [
    "dart:_internal",
    "dart:async",
    "dart:collection",
    "dart:core",
    "dart:ffi",
    "dart:typed_data",
    "dart:wasm"
  ]);

  // dart:_internal classes
  late final Class symbolClass = index.getClass("dart:_internal", "Symbol");

  // dart:collection classes
  late final Class hashFieldBaseClass =
      index.getClass("dart:collection", "_HashFieldBase");
  late final Class immutableMapClass =
      index.getClass("dart:collection", "_WasmImmutableMap");
  late final Class immutableSetClass =
      index.getClass("dart:collection", "_WasmImmutableSet");

  // dart:core various classes
  late final Class boxedBoolClass = index.getClass("dart:core", "_BoxedBool");
  late final Class boxedDoubleClass =
      index.getClass("dart:core", "_BoxedDouble");
  late final Class boxedIntClass = index.getClass("dart:core", "_BoxedInt");
  late final Class closureClass = index.getClass("dart:core", "_Closure");
  late final Class listBaseClass = index.getClass("dart:core", "_ListBase");
  late final Class fixedLengthListClass = index.getClass("dart:core", "_List");
  late final Class growableListClass =
      index.getClass("dart:core", "_GrowableList");
  late final Class immutableListClass =
      index.getClass("dart:core", "_ImmutableList");
  late final Class stringBaseClass = index.getClass("dart:core", "_StringBase");
  late final Class oneByteStringClass =
      index.getClass("dart:core", "_OneByteString");
  late final Class twoByteStringClass =
      index.getClass("dart:core", "_TwoByteString");
  late final Class invocationClass = index.getClass("dart:core", 'Invocation');
  late final Class noSuchMethodErrorClass =
      index.getClass("dart:core", "NoSuchMethodError");
  late final Class typeErrorClass = index.getClass("dart:core", "_TypeError");
  late final Class javaScriptErrorClass =
      index.getClass("dart:core", "_JavaScriptError");

  // dart:core runtime type classes
  late final Class typeClass = index.getClass("dart:core", "_Type");
  late final Class dynamicTypeClass =
      index.getClass("dart:core", "_DynamicType");
  late final Class functionTypeClass =
      index.getClass("dart:core", "_FunctionType");
  late final Class functionTypeParameterTypeClass =
      index.getClass("dart:core", "_FunctionTypeParameterType");
  late final Class futureOrTypeClass =
      index.getClass("dart:core", "_FutureOrType");
  late final Class interfaceTypeClass =
      index.getClass("dart:core", "_InterfaceType");
  late final Class interfaceTypeParameterTypeClass =
      index.getClass("dart:core", "_InterfaceTypeParameterType");
  late final Class namedParameterClass =
      index.getClass("dart:core", "_NamedParameter");
  late final Class neverTypeClass = index.getClass("dart:core", "_NeverType");
  late final Class nullTypeClass = index.getClass("dart:core", "_NullType");
  late final Class voidTypeClass = index.getClass("dart:core", "_VoidType");
  late final Class stackTraceClass = index.getClass("dart:core", "StackTrace");
  late final Class typeUniverseClass =
      index.getClass("dart:core", "_TypeUniverse");
  late final Class recordTypeClass = index.getClass("dart:core", "_RecordType");

  // dart:core sync* support classes
  late final Class suspendStateClass =
      index.getClass("dart:core", "_SuspendState");
  late final Class syncStarIterableClass =
      index.getClass("dart:core", "_SyncStarIterable");
  late final Class syncStarIteratorClass =
      index.getClass("dart:core", "_SyncStarIterator");

  // dart:ffi classes
  late final Class ffiCompoundClass = index.getClass("dart:ffi", "_Compound");
  late final Class ffiPointerClass = index.getClass("dart:ffi", "Pointer");

  // dart:typed_data classes
  late final Class typedListBaseClass =
      index.getClass("dart:typed_data", "_TypedListBase");
  late final Class typedListClass =
      index.getClass("dart:typed_data", "_TypedList");
  late final Class typedListViewClass =
      index.getClass("dart:typed_data", "_TypedListView");
  late final Class byteDataViewClass =
      index.getClass("dart:typed_data", "_ByteDataView");
  late final Class unmodifiableByteDataViewClass =
      index.getClass("dart:typed_data", "_UnmodifiableByteDataView");

  // dart:wasm classes
  late final Class wasmTypesBaseClass =
      index.getClass("dart:wasm", "_WasmBase");
  late final wasmI8Class = index.getClass("dart:wasm", "WasmI8");
  late final wasmI16Class = index.getClass("dart:wasm", "WasmI16");
  late final wasmI32Class = index.getClass("dart:wasm", "WasmI32");
  late final wasmI64Class = index.getClass("dart:wasm", "WasmI64");
  late final wasmF32Class = index.getClass("dart:wasm", "WasmF32");
  late final wasmF64Class = index.getClass("dart:wasm", "WasmF64");
  late final Class wasmAnyRefClass = index.getClass("dart:wasm", "WasmAnyRef");
  late final Class wasmExternRefClass =
      index.getClass("dart:wasm", "WasmExternRef");
  late final Class wasmFuncRefClass =
      index.getClass("dart:wasm", "WasmFuncRef");
  late final Class wasmEqRefClass = index.getClass("dart:wasm", "WasmEqRef");
  late final Class wasmStructRefClass =
      index.getClass("dart:wasm", "WasmStructRef");
  late final Class wasmArrayRefClass =
      index.getClass("dart:wasm", "WasmArrayRef");
  late final Class wasmFunctionClass =
      index.getClass("dart:wasm", "WasmFunction");
  late final Class wasmVoidClass = index.getClass("dart:wasm", "WasmVoid");
  late final Class wasmTableClass = index.getClass("dart:wasm", "WasmTable");

  // dart:_internal procedures
  late final Procedure loadLibrary =
      index.getTopLevelProcedure("dart:_internal", "loadLibrary");
  late final Procedure checkLibraryIsLoaded =
      index.getTopLevelProcedure("dart:_internal", "checkLibraryIsLoaded");

  // dart:async procedures
  late final Procedure asyncHelper =
      index.getTopLevelProcedure("dart:async", "_asyncHelper");
  late final Procedure awaitHelper =
      index.getTopLevelProcedure("dart:async", "_awaitHelper");

  // dart:collection procedures
  late final Procedure mapFactory =
      index.getProcedure("dart:collection", "LinkedHashMap", "_default");
  late final Procedure mapPut = index
      .getClass("dart:collection", "_WasmDefaultMap")
      .superclass! // _LinkedHashMapMixin<K, V>
      .procedures
      .firstWhere((p) => p.name.text == "[]=");
  late final Procedure setFactory =
      index.getProcedure("dart:collection", "LinkedHashSet", "_default");
  late final Procedure setAdd = index
      .getClass("dart:collection", "_WasmDefaultSet")
      .superclass! // _LinkedHashSetMixin<K, V>
      .procedures
      .firstWhere((p) => p.name.text == "add");
  late final Procedure growableListAdd =
      index.getProcedure("dart:core", "_GrowableList", "add");
  late final Procedure hashImmutableIndexNullable = index.getProcedure(
      "dart:collection", "_HashAbstractImmutableBase", "get:_indexNullable");

  // dart:core various procedures
  late final Procedure objectNoSuchMethod =
      index.getProcedure("dart:core", "Object", "noSuchMethod");
  late final Procedure objectGetTypeArguments =
      index.getProcedure("dart:core", "Object", "_getTypeArguments");
  late final Procedure nullToString =
      index.getProcedure("dart:core", "Object", "_nullToString");
  late final Procedure nullNoSuchMethod =
      index.getProcedure("dart:core", "Object", "_nullNoSuchMethod");
  late final Procedure recordGetRecordRuntimeType =
      index.getProcedure("dart:core", "Record", "_getRecordRuntimeType");
  late final Procedure stringEquals =
      index.getProcedure("dart:core", "_StringBase", "==");
  late final Procedure stringInterpolate =
      index.getProcedure("dart:core", "_StringBase", "_interpolate");

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
  late final Procedure throwNullCheckError =
      index.getProcedure("dart:core", "_TypeError", "_throwNullCheckError");
  late final Procedure throwAsCheckError =
      index.getProcedure("dart:core", "_TypeError", "_throwAsCheckError");
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
  late final Procedure rangeErrorCheckValueInInterval =
      index.getProcedure("dart:core", "RangeError", "checkValueInInterval");
  late final Class errorClass = index.getClass("dart:core", "Error");
  late final Field errorClassStackTraceField =
      index.getField("dart:core", "Error", "_stackTrace");
  late final Procedure errorThrow =
      index.getProcedure("dart:core", "Error", "_throw");

  // dart:core type procedures
  late final Procedure getActualRuntimeType =
      index.getTopLevelProcedure("dart:core", "_getActualRuntimeType");
  late final Procedure getMasqueradedRuntimeType =
      index.getTopLevelProcedure("dart:core", "_getMasqueradedRuntimeType");
  late final Procedure isSubtype =
      index.getTopLevelProcedure("dart:core", "_isSubtype");
  late final Procedure isTypeSubtype =
      index.getTopLevelProcedure("dart:core", "_isTypeSubtype");
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
  late final Procedure namedParameterListToMap =
      index.getTopLevelProcedure("dart:core", "_namedParameterListToMap");
  late final Procedure namedParameterMapToList =
      index.getTopLevelProcedure("dart:core", "_namedParameterMapToList");
  late final Procedure listOf = index.getProcedure("dart:core", "_List", "of");

  // dart:wasm procedures
  late final Procedure wasmFunctionCall =
      index.getProcedure("dart:wasm", "WasmFunction", "get:call");
  late final Procedure wasmTableCallIndirect =
      index.getProcedure("dart:wasm", "WasmTable", "callIndirect");
}
