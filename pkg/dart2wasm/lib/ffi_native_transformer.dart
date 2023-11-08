// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:vm/transformations/ffi/abi.dart' show Abi;
import 'package:vm/transformations/ffi/common.dart' show NativeType;
import 'package:vm/transformations/ffi/native.dart' show FfiNativeTransformer;
import 'abi.dart' show kWasmAbiEnumIndex;

/// Transform `@Native`-annotated functions to convert Dart arguments to
/// Wasm arguments expected by the FFI functions, and convert the Wasm function
/// return value to the Dart value.
///
/// Add a new `external` procedure for the Wasm import.
///
/// Example:
///
///   @Native<Int8 Function(Int8, Int8)>(symbol: "addInt8")
///   external int addInt8(int a, int b);
///
/// Converted to:
///
///   external static wasm::WasmI32 addInt8_$import(wasm::WasmI32 a, wasm::WasmI32 b);
///
///   static int addInt8(int a, int b) =>
///     addInt8_$import(WasmI32::int8FromInt(a), WasmI32::int8FromInt(b)).toIntSigned();
///
void transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex? referenceFromIndex) {
  final index = LibraryIndex(component, [
    'dart:core',
    'dart:ffi',
    'dart:_internal',
    'dart:typed_data',
    'dart:nativewrappers',
    'dart:_wasm',
    'dart:isolate',
  ]);
  final transformer = WasmFfiNativeTransformer(
      index, coreTypes, hierarchy, diagnosticReporter, referenceFromIndex);
  libraries.forEach(transformer.visitLibrary);
}

class WasmFfiNativeTransformer extends FfiNativeTransformer {
  final Class wasmI32Class;
  final Class wasmI64Class;
  final Class wasmF32Class;
  final Class wasmF64Class;
  final Class wasmEqRefClass;
  final Procedure wasmI32FromInt;
  final Procedure wasmI32Int8FromInt;
  final Procedure wasmI32Uint8FromInt;
  final Procedure wasmI32Int16FromInt;
  final Procedure wasmI32Uint16FromInt;
  final Procedure wasmI32FromBool;
  final Procedure wasmI32ToIntSigned;
  final Procedure wasmI32ToIntUnsigned;
  final Procedure wasmI32ToBool;
  final Procedure wasmI64FromInt;
  final Procedure wasmI64ToInt;
  final Procedure wasmF32FromDouble;
  final Procedure wasmF32ToDouble;
  final Procedure wasmF64FromDouble;
  final Procedure wasmF64ToDouble;

  WasmFfiNativeTransformer(
      LibraryIndex index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex)
      : wasmI32Class = index.getClass('dart:_wasm', 'WasmI32'),
        wasmI64Class = index.getClass('dart:_wasm', 'WasmI64'),
        wasmF32Class = index.getClass('dart:_wasm', 'WasmF32'),
        wasmF64Class = index.getClass('dart:_wasm', 'WasmF64'),
        wasmEqRefClass = index.getClass('dart:_wasm', 'WasmEqRef'),
        wasmI32FromInt = index.getProcedure('dart:_wasm', 'WasmI32', 'fromInt'),
        wasmI32Int8FromInt =
            index.getProcedure('dart:_wasm', 'WasmI32', 'int8FromInt'),
        wasmI32Uint8FromInt =
            index.getProcedure('dart:_wasm', 'WasmI32', 'uint8FromInt'),
        wasmI32Int16FromInt =
            index.getProcedure('dart:_wasm', 'WasmI32', 'int16FromInt'),
        wasmI32Uint16FromInt =
            index.getProcedure('dart:_wasm', 'WasmI32', 'uint16FromInt'),
        wasmI32FromBool =
            index.getProcedure('dart:_wasm', 'WasmI32', 'fromBool'),
        wasmI32ToIntSigned =
            index.getProcedure('dart:_wasm', 'WasmI32', 'toIntSigned'),
        wasmI32ToIntUnsigned =
            index.getProcedure('dart:_wasm', 'WasmI32', 'toIntUnsigned'),
        wasmI32ToBool = index.getProcedure('dart:_wasm', 'WasmI32', 'toBool'),
        wasmI64ToInt = index.getProcedure('dart:_wasm', 'WasmI64', 'toInt'),
        wasmI64FromInt = index.getProcedure('dart:_wasm', 'WasmI64', 'fromInt'),
        wasmF32FromDouble =
            index.getProcedure('dart:_wasm', 'WasmF32', 'fromDouble'),
        wasmF32ToDouble =
            index.getProcedure('dart:_wasm', 'WasmF32', 'toDouble'),
        wasmF64FromDouble =
            index.getProcedure('dart:_wasm', 'WasmF64', 'fromDouble'),
        wasmF64ToDouble =
            index.getProcedure('dart:_wasm', 'WasmF64', 'toDouble'),
        super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex);

  @override
  visitProcedure(Procedure node) {
    // Only transform functions that are external and have Native annotation:
    //   @Native<Double Function(Double)>('Math_sqrt')
    //   external double _square_root(double x);
    final nativeAnnotation = tryGetNativeAnnotation(node);
    if (nativeAnnotation == null) {
      return node;
    }
    final annotationOffset = nativeAnnotation.fileOffset;
    final ffiConstant = nativeAnnotation.constant as InstanceConstant;
    final ffiFunctionType = ffiConstant.typeArguments.first as FunctionType;
    final isLeafField =
        ffiConstant.fieldValues[nativeIsLeafField.fieldReference];
    final isLeaf = (isLeafField as BoolConstant).value;
    final assetField = ffiConstant.fieldValues[nativeAssetField.fieldReference];
    final assetName = (assetField is StringConstant)
        ? assetField
        : (currentAsset ?? StringConstant("ffi"));
    final nameField = ffiConstant.fieldValues[nativeSymbolField.fieldReference];
    final functionName = (nameField is StringConstant)
        ? nameField
        : StringConstant(node.name.text);
    final nativeFunctionName =
        StringConstant("${assetName.value}.${functionName.value}");

    // Original function should be external and without body
    assert(node.isExternal == true);
    assert(node.function.body == null);

    final dartFunctionType =
        node.function.computeThisFunctionType(Nullability.nonNullable);

    final wrappedDartFunctionType = checkFfiType(
        node, dartFunctionType, ffiFunctionType, isLeaf, annotationOffset);

    if (wrappedDartFunctionType == null) {
      // It's OK to continue because the diagnostics issued will cause
      // compilation to fail. By continuing, we can report more diagnostics
      // before compilation ends.
      return node;
    }

    // Create a new extern static procedure for the import. The original
    // function will be calling this one with arguments converted to right Wasm
    // types, and it will convert the return value to the right Dart type.
    final wasmImportName = Name('${node.name.text}_\$import', currentLibrary);
    final wasmImportPragma =
        ConstantExpression(InstanceConstant(pragmaClass.reference, [], {
      pragmaName.fieldReference: StringConstant("wasm:import"),
      pragmaOptions.fieldReference: nativeFunctionName,
    }));

    // For the imported function arguments, use names in the Dart function but
    // types in the FFI declaration
    final List<VariableDeclaration> wasmImportProcedureArgs = [];
    for (int i = 0; i < ffiFunctionType.positionalParameters.length; i += 1) {
      final argWasmType =
          _convertFfiTypeToWasmType(ffiFunctionType.positionalParameters[i]);
      if (argWasmType != null) {
        wasmImportProcedureArgs.add(VariableDeclaration(
          node.function.positionalParameters[i].name!,
          type: argWasmType,
          isSynthesized: true,
        ));
      }
    }

    final retWasmType = _convertFfiTypeToWasmType(ffiFunctionType.returnType);
    final retWasmType_ = retWasmType ?? VoidType();

    final wasmImportProcedure = Procedure(
        wasmImportName,
        ProcedureKind.Method,
        FunctionNode(null,
            positionalParameters: wasmImportProcedureArgs,
            returnType: retWasmType_),
        fileUri: node.fileUri,
        isExternal: true,
        isStatic: true,
        isSynthetic: true)
      ..fileOffset = node.fileOffset
      ..isNonNullableByDefault = true;
    wasmImportProcedure.addAnnotation(wasmImportPragma);
    currentLibrary.addProcedure(wasmImportProcedure);

    // Update the original procedure to call the Wasm import, converting
    // arguments and return value
    node.isExternal = false;
    node.annotations.remove(nativeAnnotation);

    // Convert arguments
    assert(ffiFunctionType.positionalParameters.length ==
        node.function.positionalParameters.length);

    final ffiCallArgs = <Expression>[];

    for (int i = 0; i < node.function.positionalParameters.length; i += 1) {
      final ffiArgumentType = ffiFunctionType.positionalParameters[i];

      final ffiValue = _dartValueToFfiValue(
          ffiArgumentType, VariableGet(node.function.positionalParameters[i]));

      if (ffiValue != null) {
        ffiCallArgs.add(ffiValue);
      }
    }

    // Convert return value
    node.function.body = ReturnStatement(_ffiValueToDartValue(
        ffiFunctionType.returnType,
        StaticInvocation(wasmImportProcedure, Arguments(ffiCallArgs))));

    return node;
  }

  /// Converts a Dart value to the corresponding Wasm FFI value according to
  /// emscripten ABI.
  ///
  /// For example, converts a Dart `int` for an `Uint8` native type to Wasm I32
  /// and masks high bits.
  ///
  /// Returns `null` for [Void] values.
  Expression? _dartValueToFfiValue(DartType ffiType, Expression expr) {
    final InterfaceType abiType_ =
        _getFixedWidthIntegerFromAbiSpecificInteger(ffiType as InterfaceType);
    final NativeType abiTypeNativeType = getType(abiType_.classNode)!;

    switch (abiTypeNativeType) {
      case NativeType.kInt8:
        return StaticInvocation(wasmI32Int8FromInt, Arguments([expr]));

      case NativeType.kUint8:
        return StaticInvocation(wasmI32Uint8FromInt, Arguments([expr]));

      case NativeType.kInt16:
        return StaticInvocation(wasmI32Int16FromInt, Arguments([expr]));

      case NativeType.kUint16:
        return StaticInvocation(wasmI32Uint16FromInt, Arguments([expr]));

      case NativeType.kInt32:
      case NativeType.kUint32:
        return StaticInvocation(wasmI32FromInt, Arguments([expr]));

      case NativeType.kInt64:
      case NativeType.kUint64:
        return StaticInvocation(wasmI64FromInt, Arguments([expr]));

      case NativeType.kFloat:
        return StaticInvocation(wasmF32FromDouble, Arguments([expr]));

      case NativeType.kDouble:
        return StaticInvocation(wasmF64FromDouble, Arguments([expr]));

      case NativeType.kPointer:
      case NativeType.kStruct:
        return expr;

      case NativeType.kBool:
        return StaticInvocation(wasmI32FromBool, Arguments([expr]));

      case NativeType.kVoid:
        return null;

      case NativeType.kHandle:
      case NativeType.kNativeDouble:
      case NativeType.kNativeFunction:
      case NativeType.kNativeInteger:
      case NativeType.kNativeType:
      case NativeType.kOpaque:
        throw '_dartValueToFfiValue: $abiTypeNativeType cannot be converted';
    }
  }

  /// Converts a Wasm FFI value to the corresponding Dart value according to
  /// emscripten ABI.
  ///
  /// For example, converts an `Bool` native type to Dart bool by checking the
  /// Wasm I32 value for the bool: 0 means `false`, non-0 means `true`.
  Expression _ffiValueToDartValue(DartType ffiType, Expression expr) {
    final InterfaceType ffiType_ =
        _getFixedWidthIntegerFromAbiSpecificInteger(ffiType as InterfaceType);
    final NativeType nativeType = getType(ffiType_.classNode)!;

    Expression instanceInvocation(Procedure converter, Expression receiver) =>
        InstanceInvocation(
          InstanceAccessKind.Instance,
          receiver,
          converter.name,
          Arguments([]),
          interfaceTarget: converter,
          functionType: converter.getterType as FunctionType,
        );

    switch (nativeType) {
      case NativeType.kInt8:
      case NativeType.kInt16:
      case NativeType.kInt32:
        return instanceInvocation(wasmI32ToIntSigned, expr);

      case NativeType.kUint8:
      case NativeType.kUint16:
      case NativeType.kUint32:
        return instanceInvocation(wasmI32ToIntUnsigned, expr);

      case NativeType.kPointer:
      case NativeType.kVoid:
      case NativeType.kStruct:
        return expr;

      case NativeType.kUint64:
      case NativeType.kInt64:
        return instanceInvocation(wasmI64ToInt, expr);

      case NativeType.kFloat:
        return instanceInvocation(wasmF32ToDouble, expr);

      case NativeType.kDouble:
        return instanceInvocation(wasmF64ToDouble, expr);

      case NativeType.kBool:
        return instanceInvocation(wasmI32ToBool, expr);

      case NativeType.kHandle:
      case NativeType.kNativeDouble:
      case NativeType.kNativeFunction:
      case NativeType.kNativeInteger:
      case NativeType.kNativeType:
      case NativeType.kOpaque:
        throw '_ffiValueToDartValue: $nativeType cannot be converted';
    }
  }

  InterfaceType _getFixedWidthIntegerFromAbiSpecificInteger(
      InterfaceType ffiType) {
    final MapConstant? abiIntegerMapping =
        getAbiSpecificIntegerMappingAnnotation(ffiType.classNode);
    if (abiIntegerMapping == null) {
      // This isn't an ABI specific integer. Just return the type itself
      return ffiType;
    }
    final Abi wasmAbi = Abi.values[kWasmAbiEnumIndex];
    final entry = abiIntegerMapping.entries
        .firstWhere((e) => constantAbis[e.key] == wasmAbi);
    return (entry.value as InstanceConstant)
        .classNode
        .getThisType(coreTypes, Nullability.nonNullable);
  }

  /// Converts an FFI type like `InterfaceType(Int8)` to the corresponding Wasm
  /// type (`InterfaceType(WasmI32)`) according to emscripten Wasm ABI.
  ///
  /// Returns `null` for [Void]. Other types are converted to their
  /// [InterfaceType]s.
  DartType? _convertFfiTypeToWasmType(DartType ffiType) {
    if (ffiType is! InterfaceType) {
      throw 'Native type is not an interface type: $ffiType';
    }
    ffiType = _getFixedWidthIntegerFromAbiSpecificInteger(ffiType);
    final NativeType nativeType_ = getType(ffiType.classNode)!;

    switch (nativeType_) {
      case NativeType.kInt8:
      case NativeType.kUint8:
      case NativeType.kInt16:
      case NativeType.kUint16:
      case NativeType.kInt32:
      case NativeType.kUint32:
      case NativeType.kBool:
        return InterfaceType(wasmI32Class, Nullability.nonNullable);

      case NativeType.kInt64:
      case NativeType.kUint64:
        return InterfaceType(wasmI64Class, Nullability.nonNullable);

      case NativeType.kFloat:
        return InterfaceType(wasmF32Class, Nullability.nonNullable);

      case NativeType.kDouble:
        return InterfaceType(wasmF64Class, Nullability.nonNullable);

      case NativeType.kPointer:
      case NativeType.kStruct:
        return ffiType;

      case NativeType.kVoid:
        return null;

      case NativeType.kHandle:
      case NativeType.kNativeDouble:
      case NativeType.kNativeFunction:
      case NativeType.kNativeInteger:
      case NativeType.kNativeType:
      case NativeType.kOpaque:
        throw '_convertFfiTypeToWasmType: $nativeType_ cannot be converted';
    }
  }
}
