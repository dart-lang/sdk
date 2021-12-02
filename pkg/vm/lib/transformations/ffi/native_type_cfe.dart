// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:kernel/ast.dart';

import 'abi.dart';
import 'common.dart';

/// AST node wrapper for native types.
///
/// This algebraic data structure does not stand on its own but refers
/// intimately to AST nodes such as [Class].
abstract class NativeTypeCfe {
  factory NativeTypeCfe(FfiTransformer transformer, DartType dartType,
      {List<int>? arrayDimensions,
      Map<Class, NativeTypeCfe> compoundCache = const {}}) {
    if (transformer.isPrimitiveType(dartType)) {
      final clazz = (dartType as InterfaceType).classNode;
      final nativeType = transformer.getType(clazz)!;
      return PrimitiveNativeTypeCfe(nativeType, clazz);
    }
    if (transformer.isPointerType(dartType)) {
      return PointerNativeTypeCfe();
    }
    if (transformer.isCompoundSubtype(dartType)) {
      final clazz = (dartType as InterfaceType).classNode;
      if (compoundCache.containsKey(clazz)) {
        return compoundCache[clazz]!;
      } else {
        throw "Class '$clazz' not found in compoundCache.";
      }
    }
    if (transformer.isArrayType(dartType)) {
      if (arrayDimensions == null) {
        throw "Must have array dimensions for ArrayType.";
      }
      if (arrayDimensions.length == 0) {
        throw "Must have a size for this array dimension.";
      }
      final elementType = transformer.arraySingleElementType(dartType);
      final elementCfeType =
          NativeTypeCfe(transformer, elementType, compoundCache: compoundCache);
      if (elementCfeType is InvalidNativeTypeCfe) {
        return elementCfeType;
      }
      return ArrayNativeTypeCfe.multi(elementCfeType, arrayDimensions);
    }
    throw "Invalid type $dartType";
  }

  /// The size in bytes per [Abi].
  Map<Abi, int> get size;

  /// The alignment inside structs in bytes per [Abi].
  ///
  /// This is not the alignment on stack, this is only calculated in the VM.
  Map<Abi, int> get alignment;

  /// Generates a Constant representing the type which is consumed by the VM.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ///
  /// See runtime/vm/compiler/ffi/native_type.cc:NativeType::FromAbstractType.
  Constant generateConstant(FfiTransformer transformer);

  /// Generates the return statement for a compound field getter with this type.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
      Map<Abi, int> offsets, bool unalignedAccess, FfiTransformer transformer);

  /// Generates the return statement for a compound field setter with this type.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ReturnStatement generateSetterStatement(
      DartType dartType,
      int fileOffset,
      Map<Abi, int> offsets,
      bool unalignedAccess,
      VariableDeclaration argument,
      FfiTransformer transformer);
}

class InvalidNativeTypeCfe implements NativeTypeCfe {
  final String reason;

  InvalidNativeTypeCfe(this.reason);

  @override
  Map<Abi, int> get alignment => throw reason;

  @override
  Constant generateConstant(FfiTransformer transformer) => throw reason;

  @override
  ReturnStatement generateGetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          FfiTransformer transformer) =>
      throw reason;

  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      throw reason;

  @override
  Map<Abi, int> get size => throw reason;
}

class PrimitiveNativeTypeCfe implements NativeTypeCfe {
  final NativeType nativeType;

  final Class clazz;

  PrimitiveNativeTypeCfe(this.nativeType, this.clazz);

  @override
  Map<Abi, int> get size {
    final int size = nativeTypeSizes[nativeType]!;
    if (size == WORD_SIZE) {
      return wordSize;
    }
    return {for (var abi in Abi.values) abi: size};
  }

  @override
  Map<Abi, int> get alignment => {
        for (var abi in Abi.values)
          abi: nonSizeAlignment[abi]![nativeType] ?? size[abi]!
      };

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      TypeLiteralConstant(InterfaceType(clazz, Nullability.nonNullable));

  bool get isFloat =>
      nativeType == NativeType.kFloat || nativeType == NativeType.kDouble;

  bool isUnaligned(Map<Abi, int> offsets) {
    final alignments = alignment;
    for (final abi in offsets.keys) {
      final offset = offsets[abi]!;
      final alignment = alignments[abi]!;
      if (offset % alignment != 0) {
        return true;
      }
    }
    return false;
  }

  /// Sample output for `int get x =>`:
  ///
  /// ```
  /// _loadInt8(_typedDataBase, offset);
  /// ```
  @override
  ReturnStatement generateGetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          (unalignedAccess && isFloat
              ? transformer.loadUnalignedMethods
              : transformer.loadMethods)[nativeType]!,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets)
          ]))
        ..fileOffset = fileOffset);

  /// Sample output for `set x(int #v) =>`:
  ///
  /// ```
  /// _storeInt8(_typedDataBase, offset, #v);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          (unalignedAccess && isFloat
              ? transformer.storeUnalignedMethods
              : transformer.storeMethods)[nativeType]!,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets),
            VariableGet(argument)
          ]))
        ..fileOffset = fileOffset);
}

class PointerNativeTypeCfe implements NativeTypeCfe {
  @override
  Map<Abi, int> get size => wordSize;

  @override
  Map<Abi, int> get alignment => wordSize;

  @override
  Constant generateConstant(FfiTransformer transformer) => TypeLiteralConstant(
          InterfaceType(transformer.pointerClass, Nullability.nonNullable, [
        InterfaceType(
            transformer.pointerClass.superclass!, Nullability.nonNullable)
      ]));

  /// Sample output for `Pointer<Int8> get x =>`:
  ///
  /// ```
  /// _fromAddress<Int8>(_loadIntPtr(_typedDataBase, offset));
  /// ```
  @override
  ReturnStatement generateGetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.fromAddressInternal,
          Arguments([
            StaticInvocation(
                transformer.loadMethods[NativeType.kIntptr]!,
                Arguments([
                  transformer.getCompoundTypedDataBaseField(
                      ThisExpression(), fileOffset),
                  transformer.runtimeBranchOnLayout(offsets)
                ]))
              ..fileOffset = fileOffset
          ], types: [
            (dartType as InterfaceType).typeArguments.single
          ]))
        ..fileOffset = fileOffset);

  /// Sample output for `set x(Pointer<Int8> #v) =>`:
  ///
  /// ```
  /// _storeIntPtr(_typedDataBase, offset, (#v as Pointer<Int8>).address);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.storeMethods[NativeType.kIntptr]!,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets),
            InstanceGet(InstanceAccessKind.Instance, VariableGet(argument),
                transformer.addressGetter.name,
                interfaceTarget: transformer.addressGetter,
                resultType: transformer.addressGetter.getterType)
              ..fileOffset = fileOffset
          ]))
        ..fileOffset = fileOffset);
}

/// The layout of a `Struct` or `Union` in one [Abi].
class CompoundLayout {
  /// Size of the entire struct or union.
  final int size;

  /// Alignment of struct or union when nested in a struct.
  final int alignment;

  /// Offset in bytes for each field, indexed by field number.
  ///
  /// Always 0 for unions.
  final List<int> offsets;

  CompoundLayout(this.size, this.alignment, this.offsets);
}

abstract class CompoundNativeTypeCfe implements NativeTypeCfe {
  final Class clazz;

  final List<NativeTypeCfe> members;

  final Map<Abi, CompoundLayout> layout;

  CompoundNativeTypeCfe._(this.clazz, this.members, this.layout);

  @override
  Map<Abi, int> get size =>
      layout.map((abi, layout) => MapEntry(abi, layout.size));

  @override
  Map<Abi, int> get alignment =>
      layout.map((abi, layout) => MapEntry(abi, layout.alignment));

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      TypeLiteralConstant(InterfaceType(clazz, Nullability.nonNullable));

  /// Sample output for `MyStruct get x =>`:
  ///
  /// ```
  /// MyStruct.#fromTypedDataBase(
  ///   typedDataBaseOffset(_typedDataBase, offset, size, dartType)
  /// );
  /// ```
  @override
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
      Map<Abi, int> offsets, bool unalignedAccess, FfiTransformer transformer) {
    final constructor = clazz.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));

    return ReturnStatement(ConstructorInvocation(
        constructor,
        Arguments([
          transformer.typedDataBaseOffset(
              transformer.getCompoundTypedDataBaseField(
                  ThisExpression(), fileOffset),
              transformer.runtimeBranchOnLayout(offsets),
              transformer.runtimeBranchOnLayout(size),
              dartType,
              fileOffset)
        ]))
      ..fileOffset = fileOffset);
  }

  /// Sample output for `set x(MyStruct #v) =>`:
  ///
  /// ```
  /// _memCopy(_typedDataBase, offset, #v._typedDataBase, 0, size);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.memCopy,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets),
            transformer.getCompoundTypedDataBaseField(
                VariableGet(argument), fileOffset),
            ConstantExpression(IntConstant(0)),
            transformer.runtimeBranchOnLayout(size),
          ]))
        ..fileOffset = fileOffset);
}

class StructNativeTypeCfe extends CompoundNativeTypeCfe {
  // Nullable int.
  final int? packing;

  factory StructNativeTypeCfe(Class clazz, List<NativeTypeCfe> members,
      {int? packing}) {
    final layout = {
      for (var abi in Abi.values) abi: _calculateLayout(members, packing, abi)
    };
    return StructNativeTypeCfe._(clazz, members, packing, layout);
  }

  StructNativeTypeCfe._(Class clazz, List<NativeTypeCfe> members, this.packing,
      Map<Abi, CompoundLayout> layout)
      : super._(clazz, members, layout);

  // Keep consistent with runtime/vm/compiler/ffi/native_type.cc
  // NativeStructType::FromNativeTypes.
  static CompoundLayout _calculateLayout(
      List<NativeTypeCfe> types, int? packing, Abi abi) {
    int offset = 0;
    final offsets = <int>[];
    int structAlignment = 1;
    for (int i = 0; i < types.length; i++) {
      final int size = types[i].size[abi]!;
      int alignment = types[i].alignment[abi]!;
      if (packing != null && packing < alignment) {
        alignment = packing;
      }
      if (alignment > 0) {
        offset = _alignOffset(offset, alignment);
      }
      offsets.add(offset);
      offset += size;
      structAlignment = math.max(structAlignment, alignment);
    }
    final int size = _alignOffset(offset, structAlignment);
    return CompoundLayout(size, structAlignment, offsets);
  }
}

class UnionNativeTypeCfe extends CompoundNativeTypeCfe {
  factory UnionNativeTypeCfe(Class clazz, List<NativeTypeCfe> members) {
    final layout = {
      for (var abi in Abi.values) abi: _calculateLayout(members, abi)
    };
    return UnionNativeTypeCfe._(clazz, members, layout);
  }

  UnionNativeTypeCfe._(
      Class clazz, List<NativeTypeCfe> members, Map<Abi, CompoundLayout> layout)
      : super._(clazz, members, layout);

  // Keep consistent with runtime/vm/compiler/ffi/native_type.cc
  // NativeUnionType::FromNativeTypes.
  static CompoundLayout _calculateLayout(List<NativeTypeCfe> types, Abi abi) {
    int unionSize = 1;
    int unionAlignment = 1;
    for (int i = 0; i < types.length; i++) {
      final int size = types[i].size[abi]!;
      int alignment = types[i].alignment[abi]!;
      unionSize = math.max(unionSize, size);
      unionAlignment = math.max(unionAlignment, alignment);
    }
    final int size = _alignOffset(unionSize, unionAlignment);
    return CompoundLayout(size, unionAlignment, List.filled(types.length, 0));
  }
}

class ArrayNativeTypeCfe implements NativeTypeCfe {
  final NativeTypeCfe elementType;
  final int length;

  ArrayNativeTypeCfe(this.elementType, this.length);

  factory ArrayNativeTypeCfe.multi(
      NativeTypeCfe elementType, List<int> dimensions) {
    if (dimensions.length == 1) {
      return ArrayNativeTypeCfe(elementType, dimensions.single);
    }
    return ArrayNativeTypeCfe(
        ArrayNativeTypeCfe.multi(elementType, dimensions.sublist(1)),
        dimensions.first);
  }

  List<int> get dimensions {
    final elementType = this.elementType;
    if (elementType is ArrayNativeTypeCfe) {
      return [length, ...elementType.dimensions];
    }
    return [length];
  }

  List<int> get nestedDimensions => dimensions.sublist(1);

  int get dimensionsFlattened =>
      dimensions.fold(1, (accumulator, element) => accumulator * element);

  NativeTypeCfe get singleElementType {
    final elementType = this.elementType;
    if (elementType is ArrayNativeTypeCfe) {
      return elementType.singleElementType;
    }
    return elementType;
  }

  @override
  Map<Abi, int> get size =>
      elementType.size.map((abi, size) => MapEntry(abi, size * length));

  @override
  Map<Abi, int> get alignment => elementType.alignment;

  // Note that we flatten multi dimensional arrays.
  @override
  Constant generateConstant(FfiTransformer transformer) =>
      InstanceConstant(transformer.ffiInlineArrayClass.reference, [], {
        transformer.ffiInlineArrayElementTypeField.fieldReference:
            singleElementType.generateConstant(transformer),
        transformer.ffiInlineArrayLengthField.fieldReference:
            IntConstant(dimensionsFlattened)
      });

  /// Sample output for `Array<Int8> get x =>`:
  ///
  /// ```
  /// Array<Int8>._(
  ///   typedDataBaseOffset(_typedDataBase, offset, size, typeArgument)
  /// );
  /// ```
  @override
  ReturnStatement generateGetterStatement(DartType dartType, int fileOffset,
      Map<Abi, int> offsets, bool unalignedAccess, FfiTransformer transformer) {
    InterfaceType typeArgument =
        (dartType as InterfaceType).typeArguments.single as InterfaceType;
    return ReturnStatement(ConstructorInvocation(
        transformer.arrayConstructor,
        Arguments([
          transformer.typedDataBaseOffset(
              transformer.getCompoundTypedDataBaseField(
                  ThisExpression(), fileOffset),
              transformer.runtimeBranchOnLayout(offsets),
              transformer.runtimeBranchOnLayout(size),
              typeArgument,
              fileOffset),
          ConstantExpression(IntConstant(length)),
          transformer.intListConstantExpression(nestedDimensions)
        ], types: [
          typeArgument
        ]))
      ..fileOffset = fileOffset);
  }

  /// Sample output for `set x(Array #v) =>`:
  ///
  /// ```
  /// _memCopy(_typedDataBase, offset, #v._typedDataBase, 0, size);
  /// ```
  @override
  ReturnStatement generateSetterStatement(
          DartType dartType,
          int fileOffset,
          Map<Abi, int> offsets,
          bool unalignedAccess,
          VariableDeclaration argument,
          FfiTransformer transformer) =>
      ReturnStatement(StaticInvocation(
          transformer.memCopy,
          Arguments([
            transformer.getCompoundTypedDataBaseField(
                ThisExpression(), fileOffset),
            transformer.runtimeBranchOnLayout(offsets),
            transformer.getArrayTypedDataBaseField(
                VariableGet(argument), fileOffset),
            ConstantExpression(IntConstant(0)),
            transformer.runtimeBranchOnLayout(size),
          ]))
        ..fileOffset = fileOffset);
}

int _alignOffset(int offset, int alignment) =>
    ((offset + alignment - 1) ~/ alignment) * alignment;
