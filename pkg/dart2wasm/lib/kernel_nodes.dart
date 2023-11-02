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
    "dart:_js_helper",
    "dart:_js_types",
    "dart:_string",
    "dart:_wasm",
    "dart:async",
    "dart:collection",
    "dart:core",
    "dart:ffi",
    "dart:typed_data",
  ]);

  // dart:_internal classes
  late final Class symbolClass = index.getClass("dart:_internal", "Symbol");

  // dart:_js_types classes
  late final Class jsStringClass =
      index.getClass("dart:_js_types", "JSStringImpl");

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
  late final Class stringBaseClass =
      index.getClass("dart:_string", "StringBase");
  late final Class oneByteStringClass =
      index.getClass("dart:_string", "OneByteString");
  late final Class twoByteStringClass =
      index.getClass("dart:_string", "TwoByteString");
  late final Class invocationClass = index.getClass("dart:core", 'Invocation');
  late final Class noSuchMethodErrorClass =
      index.getClass("dart:core", "NoSuchMethodError");
  late final Class typeErrorClass = index.getClass("dart:core", "_TypeError");
  late final Class javaScriptErrorClass =
      index.getClass("dart:core", "_JavaScriptError");

  // dart:core runtime type classes
  late final Class typeClass = index.getClass("dart:core", "_Type");
  late final Class abstractFunctionTypeClass =
      index.getClass("dart:core", "_AbstractFunctionType");
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
  late final Class bottomTypeClass = index.getClass("dart:core", "_BottomType");
  late final Class topTypeClass = index.getClass("dart:core", "_TopType");
  late final Class stackTraceClass = index.getClass("dart:core", "StackTrace");
  late final Class typeUniverseClass =
      index.getClass("dart:core", "_TypeUniverse");
  late final Class abstractRecordTypeClass =
      index.getClass("dart:core", "_AbstractRecordType");
  late final Class recordTypeClass = index.getClass("dart:core", "_RecordType");

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
  late final Procedure makeAsyncCompleter =
      index.getTopLevelProcedure("dart:async", "_makeAsyncCompleter");
  late final Field completerFuture =
      index.getField("dart:async", "_Completer", "future");
  late final Procedure completerComplete =
      index.getProcedure("dart:async", "_AsyncCompleter", "complete");
  late final Procedure completerCompleteError =
      index.getProcedure("dart:async", "_Completer", "completeError");
  late final Procedure awaitHelper =
      index.getTopLevelProcedure("dart:async", "_awaitHelper");
  late final Procedure newAsyncSuspendState =
      index.getTopLevelProcedure("dart:async", "_newAsyncSuspendState");

  // dart:ffi classes
  late final Class ffiCompoundClass = index.getClass("dart:ffi", "_Compound");
  late final Class ffiPointerClass = index.getClass("dart:ffi", "Pointer");

  // dart:_wasm classes
  late final Class wasmTypesBaseClass =
      index.getClass("dart:_wasm", "_WasmBase");
  late final wasmI8Class = index.getClass("dart:_wasm", "WasmI8");
  late final wasmI16Class = index.getClass("dart:_wasm", "WasmI16");
  late final wasmI32Class = index.getClass("dart:_wasm", "WasmI32");
  late final wasmI64Class = index.getClass("dart:_wasm", "WasmI64");
  late final wasmF32Class = index.getClass("dart:_wasm", "WasmF32");
  late final wasmF64Class = index.getClass("dart:_wasm", "WasmF64");
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
  late final Class wasmObjectArrayClass =
      index.getClass("dart:_wasm", "WasmObjectArray");
  late final Field wasmObjectArrayValueField =
      index.getField("dart:_wasm", "WasmObjectArray", "_value");

  // dart:_internal procedures
  late final Procedure loadLibrary =
      index.getTopLevelProcedure("dart:_internal", "loadLibrary");
  late final Procedure checkLibraryIsLoaded =
      index.getTopLevelProcedure("dart:_internal", "checkLibraryIsLoaded");

  // dart:_js_helper procedures
  late final Procedure getInternalizedString =
      index.getTopLevelProcedure("dart:_js_helper", "getInternalizedString");
  late final Procedure areEqualInJS =
      index.getTopLevelProcedure("dart:_js_helper", "areEqualInJS");

  // dart:_js_types procedures
  late final Procedure jsStringEquals =
      index.getProcedure("dart:_js_types", "JSStringImpl", "==");
  late final Procedure jsStringInterpolate =
      index.getProcedure("dart:_js_types", "JSStringImpl", "interpolate");

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
  late final Procedure objectHashCode =
      index.getProcedure("dart:core", "Object", "get:hashCode");
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
      index.getProcedure("dart:_string", "StringBase", "==");
  late final Procedure stringInterpolate =
      index.getProcedure("dart:_string", "StringBase", "_interpolate");
  late final Procedure truncDiv =
      index.getProcedure("dart:core", "_BoxedInt", "_truncDiv");

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

  // dart:_wasm procedures
  late final Procedure wasmFunctionCall =
      index.getProcedure("dart:_wasm", "WasmFunction", "get:call");
  late final Procedure wasmTableCallIndirect =
      index.getProcedure("dart:_wasm", "WasmTable", "callIndirect");

  // Debugging
  late final Procedure printToConsole =
      index.getTopLevelProcedure("dart:_internal", "printToConsole");
}
