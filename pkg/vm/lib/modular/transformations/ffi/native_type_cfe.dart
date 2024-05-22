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
sealed class NativeTypeCfe {
  NativeTypeCfe._();

  /// Constructs a [NativeTypeCfe] for transformers that can refer to types
  /// without having to know their internal layout or size.
  factory NativeTypeCfe.withoutLayout(
    FfiTransformer transformer,
    DartType dartType, {
    List<int>? arrayDimensions,
  }) {
    if (transformer.isStructOrUnionSubtype(dartType)) {
      return ReferencedCompoundSubtypeCfe(
          (dartType as InterfaceType).classNode);
    } else {
      return NativeTypeCfe(transformer, dartType,
          arrayDimensions: arrayDimensions);
    }
  }

  factory NativeTypeCfe(
    FfiTransformer transformer,
    DartType dartType, {
    List<int>? arrayDimensions,
    Map<Class, NativeTypeCfe> compoundCache = const {},
    bool alreadyInAbiSpecificType = false,
  }) {
    if (transformer.isPrimitiveType(dartType)) {
      final clazz = (dartType as InterfaceType).classNode;
      final nativeType = transformer.getType(clazz)!;
      return PrimitiveNativeTypeCfe(nativeType, clazz);
    }
    if (transformer.isPointerType(dartType)) {
      return PointerNativeTypeCfe();
    }
    if (transformer.isStructOrUnionSubtype(dartType)) {
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
      if (arrayDimensions.isEmpty) {
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
    if (transformer.isAbiSpecificIntegerSubtype(dartType)) {
      final clazz = (dartType as InterfaceType).classNode;
      final mappingConstant =
          transformer.getAbiSpecificIntegerMappingAnnotation(clazz);
      if (alreadyInAbiSpecificType || mappingConstant == null) {
        // Unsupported mapping.
        return AbiSpecificNativeTypeCfe({}, clazz);
      }
      final mapping = Map.fromEntries(
        mappingConstant.entries.map(
          (e) {
            var type = transformer.constantAbis[e.key];
            if (type == null) {
              throw "Type ${clazz.name} has no mapping for ABI ${e.key}";
            }
            return MapEntry(
              type,
              NativeTypeCfe(
                transformer,
                (e.value as InstanceConstant).classNode.getThisType(
                      transformer.coreTypes,
                      Nullability.nonNullable,
                    ),
                alreadyInAbiSpecificType: true,
              ),
            );
          },
        ),
      );
      for (final value in mapping.values) {
        if (value is! PrimitiveNativeTypeCfe ||
            !nativeIntTypesFixedSize.contains(value.nativeType)) {
          // Unsupported mapping.
          return AbiSpecificNativeTypeCfe({}, clazz);
        }
      }
      return AbiSpecificNativeTypeCfe(mapping, clazz);
    }
    return InvalidNativeTypeCfe("Invalid type $dartType");
  }

  /// The size in bytes per [Abi].
  Map<Abi, int?> get size;

  /// The size in bytes for [Abi].
  int? getSizeFor(Abi abi);

  /// The alignment inside structs in bytes per [Abi].
  ///
  /// This is not the alignment on stack, this is only calculated in the VM.
  Map<Abi, int?> get alignment;

  /// The alignment inside structs in bytes for [Abi].
  ///
  /// This is not the alignment on stack, this is only calculated in the VM.
  int? getAlignmentFor(Abi abi);

  /// Generates a Constant representing the type which is consumed by the VM.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ///
  /// See runtime/vm/compiler/ffi/native_type.cc:NativeType::FromAbstractType.
  Constant generateConstant(FfiTransformer transformer);

  /// Generates an expression evaluating to an instance of [dartType], which is
  /// assumed to be a Dart type compatible to this native type, by loading this
  /// instance from memory.
  ///
  /// [typedDataBase] is an expression evaluating to a `Pointer` or `TypedData`,
  /// the type will be loaded from that buffer, starting at [offsetInBytes].
  ///
  /// For example, loading a `Pointer` from memory (via [PointerNativeTypeCfe])
  /// would build an expression like `ffi._loadPointer<T>
  /// (#typedDataBase, #offsetInBytes)`, where `Pointer<T> == dartType`.
  ///
  /// For struct fields, [generateGetterStatement] fills in values for
  /// [offsetInBytes] and [unaligned] based on the ABI of the struct. It also
  /// wraps the expression in a return statement.
  Expression generateLoad({
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  });

  /// Generates an expression storing [value], which must evaluate to a
  /// [dartType] compatible with this native type, in native memory.
  ///
  /// [typedDataBase] is an expression evaluating to a `Pointer` or `TypedData`,
  /// the [value] will be stored in that buffer from [offsetInBytes].
  ///
  /// For example, storing a `Pointer` (via [PointerNativeTypeCfe]) would
  /// generate a call to `ffi._storePointer`.
  ///
  /// For struct fields, [generateSetterStatement] fills in values for
  /// [offsetInBytes] and [unaligned] based on the ABI of the struct. It also
  /// wraps the expression in a return statement.
  Expression generateStore(
    VariableDeclaration value, {
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  });

  /// Generates the return statement for a compound field getter with this type.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ReturnStatement generateGetterStatement(
    DartType dartType,
    int fileOffset,
    bool unalignedAccess,
    FfiTransformer transformer,
    Procedure offsetGetter,
  ) {
    return ReturnStatement(
      generateLoad(
        dartType: dartType,
        fileOffset: fileOffset,
        typedDataBase: transformer.getCompoundTypedDataBaseField(
          ThisExpression(),
          fileOffset,
        ),
        transformer: transformer,
        unaligned: unalignedAccess,
        offsetInBytes: transformer.add(
          StaticGet(offsetGetter),
          transformer.getCompoundOffsetInBytesField(
            ThisExpression(),
            fileOffset,
          ),
        ),
      ),
    );
  }

  /// Generates the return statement for a compound field setter with this type.
  ///
  /// Takes [transformer] to be able to lookup classes and methods.
  ReturnStatement generateSetterStatement(
    DartType dartType,
    int fileOffset,
    bool unalignedAccess,
    VariableDeclaration argument,
    FfiTransformer transformer,
    Procedure offsetGetter,
  ) {
    return ReturnStatement(generateStore(
      argument,
      dartType: dartType,
      fileOffset: fileOffset,
      typedDataBase: transformer.getCompoundTypedDataBaseField(
        ThisExpression(),
        fileOffset,
      ),
      transformer: transformer,
      offsetInBytes: transformer.add(
        StaticGet(offsetGetter),
        transformer.getCompoundOffsetInBytesField(
          ThisExpression(),
          fileOffset,
        ),
      ),
      unaligned: unalignedAccess,
    ));
  }
}

final class InvalidNativeTypeCfe extends NativeTypeCfe {
  final String reason;

  InvalidNativeTypeCfe(this.reason) : super._();

  @override
  Map<Abi, int?> get alignment => throw reason;

  @override
  int? getAlignmentFor(Abi abi) => throw reason;

  @override
  Constant generateConstant(FfiTransformer transformer) => throw reason;

  @override
  Expression generateLoad({
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    throw reason;
  }

  @override
  Expression generateStore(
    VariableDeclaration value, {
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    throw reason;
  }

  @override
  Map<Abi, int?> get size => throw reason;

  @override
  int? getSizeFor(Abi abi) => throw reason;
}

class PrimitiveNativeTypeCfe extends NativeTypeCfe {
  final NativeType nativeType;

  final Class clazz;

  PrimitiveNativeTypeCfe(this.nativeType, this.clazz) : super._();

  @override
  Map<Abi, int?> get size {
    final int size = nativeTypeSizes[nativeType]!;
    if (size == WORD_SIZE) {
      return wordSize;
    }
    return {for (var abi in Abi.values) abi: size};
  }

  @override
  int? getSizeFor(Abi abi) {
    final int size = nativeTypeSizes[nativeType]!;
    if (size == WORD_SIZE) {
      return wordSize[abi];
    }
    return size;
  }

  @override
  Map<Abi, int> get alignment => {
        for (var abi in Abi.values)
          abi: nonSizeAlignment[abi]![nativeType] ?? getSizeFor(abi)!
      };

  @override
  int? getAlignmentFor(Abi abi) =>
      nonSizeAlignment[abi]![nativeType] ?? getSizeFor(abi)!;

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      TypeLiteralConstant(InterfaceType(clazz, Nullability.nonNullable));

  bool get isFloat =>
      nativeType == NativeType.kFloat || nativeType == NativeType.kDouble;

  bool isUnaligned(Map<Abi, int?> offsets) {
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

  /// Sample output for [nativeType] being [NativeType.kInt8]:
  ///
  /// ```
  /// _loadInt8(#typedDataBase, #offsetInBytes)
  /// ```
  @override
  Expression generateLoad({
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    return StaticInvocation(
        (unaligned && isFloat
            ? transformer.loadUnalignedMethods
            : transformer.loadMethods)[nativeType]!,
        Arguments([typedDataBase, offsetInBytes]))
      ..fileOffset = fileOffset;
  }

  /// Sample output for [nativeType] being [NativeType.kInt8]:
  ///
  /// ```
  /// _storeInt8(#typedDataBase, #offsetInBytes, #value)
  /// ```
  @override
  Expression generateStore(
    VariableDeclaration value, {
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    return StaticInvocation(
      (unaligned && isFloat
          ? transformer.storeUnalignedMethods
          : transformer.storeMethods)[nativeType]!,
      Arguments([
        typedDataBase,
        offsetInBytes,
        VariableGet(value)..fileOffset = fileOffset,
      ]),
    )..fileOffset = fileOffset;
  }
}

class PointerNativeTypeCfe extends NativeTypeCfe {
  PointerNativeTypeCfe() : super._();

  @override
  Map<Abi, int?> get size => wordSize;

  @override
  int? getSizeFor(Abi abi) => wordSize[abi];

  @override
  Map<Abi, int?> get alignment => wordSize;

  @override
  int? getAlignmentFor(Abi abi) => wordSize[abi];

  @override
  Constant generateConstant(FfiTransformer transformer) => TypeLiteralConstant(
        InterfaceType(
          transformer.pointerClass,
          Nullability.nonNullable,
          [
            InterfaceType(
              transformer.pointerClass.superclass!,
              Nullability.nonNullable,
            )
          ],
        ),
      );

  /// Sample output:
  ///
  /// ```
  /// _loadPointer<#dartType>(#typedDataBase, #offsetInBytes);
  /// ```
  @override
  Expression generateLoad({
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    return StaticInvocation(
      transformer.loadMethods[NativeType.kPointer]!,
      Arguments(
        [
          typedDataBase,
          offsetInBytes,
        ],
        types: [(dartType as InterfaceType).typeArguments.single],
      ),
    )..fileOffset = fileOffset;
  }

  /// Sample output:
  ///
  /// ```
  /// _storePointer<#dartType>(
  ///   #typedDataBase,
  ///   #offsetInBytes,
  ///   (#value as Pointer<#dartType>),
  /// );
  /// ```
  @override
  Expression generateStore(
    VariableDeclaration value, {
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    return StaticInvocation(
      transformer.storeMethods[NativeType.kPointer]!,
      Arguments(
        [
          typedDataBase,
          offsetInBytes,
          VariableGet(value)..fileOffset = fileOffset,
        ],
        types: [(dartType as InterfaceType).typeArguments.single],
      ),
    )..fileOffset = fileOffset;
  }
}

/// The layout of a `Struct` or `Union` in one [Abi].
class CompoundLayout {
  /// Size of the entire struct or union.
  final int? size;

  /// Alignment of struct or union when nested in a struct.
  final int? alignment;

  /// Offset in bytes for each field, indexed by field number.
  ///
  /// Always 0 for unions.
  final List<int?> offsets;

  CompoundLayout(this.size, this.alignment, this.offsets);
}

abstract mixin class _CompoundLoadAndStoreMixin implements NativeTypeCfe {
  Class get clazz;
  bool get knowsLayout;

  /// Generates an expression evaluating to the size of this compound subtype in
  /// bytes.
  ///
  /// If we know the size, we can construct a constant or a runtime lookup based
  /// on the ABI. Otherwise, we'll look it up from the `#size` field generated
  /// by the definitions transformer.
  Expression _generateSize(FfiTransformer transformer) {
    if (knowsLayout) {
      return transformer.runtimeBranchOnLayout(size);
    } else {
      return transformer.inlineSizeOf(
        clazz.getThisType(
          transformer.coreTypes,
          Nullability.nonNullable,
        ),
      )!;
    }
  }

  /// Sample output for `MyStruct`:
  ///
  /// ```
  /// MyStruct.#fromTypedDataBase(
  ///   #typedDataBase,
  ///   #offsetInBytes,
  /// );
  /// ```
  @override
  Expression generateLoad({
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    final constructor = clazz.constructors.firstWhere(
      (c) => c.name == Name("#fromTypedDataBase"),
    );

    return ConstructorInvocation(
      constructor,
      Arguments([
        typedDataBase,
        offsetInBytes,
      ]),
    )..fileOffset = fileOffset;
  }

  /// Sample output for `set x(MyStruct #v) =>`:
  ///
  /// ```
  /// _memCopy(#typedDataBase, #offsetInBytes, #v._typedDataBase, 0, size);
  /// ```
  @override
  Expression generateStore(
    VariableDeclaration value, {
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    return StaticInvocation(
      transformer.memCopy,
      Arguments([
        typedDataBase,
        offsetInBytes,
        transformer.getCompoundTypedDataBaseField(
          VariableGet(value)..fileOffset = fileOffset,
          fileOffset,
        ),
        transformer.getCompoundOffsetInBytesField(
          VariableGet(value)..fileOffset = fileOffset,
          fileOffset,
        ),
        _generateSize(transformer),
      ]),
    )..fileOffset = fileOffset;
  }
}

abstract class StructOrUnionNativeTypeCfe extends NativeTypeCfe
    with _CompoundLoadAndStoreMixin {
  @override
  final Class clazz;

  final List<NativeTypeCfe> members;

  final Map<Abi, CompoundLayout> layout;

  @override
  bool get knowsLayout => true;

  StructOrUnionNativeTypeCfe._(this.clazz, this.members, this.layout)
      : super._();

  @override
  Map<Abi, int?> get size =>
      layout.map((abi, layout) => MapEntry(abi, layout.size));

  @override
  int? getSizeFor(Abi abi) => layout[abi]?.size;

  @override
  Map<Abi, int?> get alignment =>
      layout.map((abi, layout) => MapEntry(abi, layout.alignment));

  @override
  int? getAlignmentFor(Abi abi) => layout[abi]?.alignment;

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      TypeLiteralConstant(InterfaceType(clazz, Nullability.nonNullable));
}

class StructNativeTypeCfe extends StructOrUnionNativeTypeCfe {
  // Nullable int.
  final int? packing;

  factory StructNativeTypeCfe(
    Class clazz,
    List<NativeTypeCfe> members, {
    int? packing,
  }) {
    final layout = {
      for (var abi in Abi.values) abi: _calculateLayout(members, packing, abi)
    };
    return StructNativeTypeCfe._(clazz, members, packing, layout);
  }

  StructNativeTypeCfe._(
    Class clazz,
    List<NativeTypeCfe> members,
    this.packing,
    Map<Abi, CompoundLayout> layout,
  ) : super._(clazz, members, layout);

  // Keep consistent with runtime/vm/compiler/ffi/native_type.cc
  // NativeStructType::FromNativeTypes.
  static CompoundLayout _calculateLayout(
    List<NativeTypeCfe> types,
    int? packing,
    Abi abi,
  ) {
    int? offset = 0;
    final offsets = <int?>[];
    int? structAlignment = 1;
    for (int i = 0; i < types.length; i++) {
      final int? size = types[i].getSizeFor(abi);
      int? alignment = types[i].getAlignmentFor(abi);
      if (packing != null) {
        alignment = min(packing, alignment);
      }
      if (alignment != null && alignment > 0) {
        offset = offset.align(alignment);
      }
      offsets.add(offset);
      offset += size;
      structAlignment = max(structAlignment, alignment);
    }
    final int? size = offset.align(structAlignment);
    return CompoundLayout(size, structAlignment, offsets);
  }
}

class UnionNativeTypeCfe extends StructOrUnionNativeTypeCfe {
  factory UnionNativeTypeCfe(Class clazz, List<NativeTypeCfe> members) {
    final layout = {
      for (var abi in Abi.values) abi: _calculateLayout(members, abi)
    };
    return UnionNativeTypeCfe._(clazz, members, layout);
  }

  UnionNativeTypeCfe._(
    Class clazz,
    List<NativeTypeCfe> members,
    Map<Abi, CompoundLayout> layout,
  ) : super._(clazz, members, layout);

  // Keep consistent with runtime/vm/compiler/ffi/native_type.cc
  // NativeUnionType::FromNativeTypes.
  static CompoundLayout _calculateLayout(List<NativeTypeCfe> types, Abi abi) {
    int? unionSize = 1;
    int? unionAlignment = 1;
    for (int i = 0; i < types.length; i++) {
      final int? size = types[i].getSizeFor(abi);
      int? alignment = types[i].getAlignmentFor(abi);
      unionSize = max(unionSize, size);
      unionAlignment = max(unionAlignment, alignment);
    }
    final int? size = unionSize.align(unionAlignment);
    return CompoundLayout(size, unionAlignment, List.filled(types.length, 0));
  }
}

/// A compound type only being referenced (instead of being fully resolved like
/// in [StructOrUnionNativeTypeCfe]).
///
/// This type can't report the underlying size, alignment or inner fields of
/// the struct or union.
///
/// Since the definitions transformer generates static size fields on compounds,
/// other transformers not needing access to individual fields can use this type
/// to generate loads and stores to compounds when only having their class.
class ReferencedCompoundSubtypeCfe extends NativeTypeCfe
    with _CompoundLoadAndStoreMixin {
  @override
  final Class clazz;

  ReferencedCompoundSubtypeCfe(this.clazz) : super._();

  Never _informationUnavailable() {
    throw UnsupportedError('Reference to struct');
  }

  @override
  bool get knowsLayout => false;

  @override
  Map<Abi, int?> get alignment => _informationUnavailable();

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      _informationUnavailable();

  @override
  int? getAlignmentFor(Abi abi) => _informationUnavailable();

  @override
  int? getSizeFor(Abi abi) => _informationUnavailable();

  @override
  Map<Abi, int?> get size => _informationUnavailable();
}

class ArrayNativeTypeCfe extends NativeTypeCfe {
  final NativeTypeCfe elementType;
  final int length;

  ArrayNativeTypeCfe(this.elementType, this.length) : super._();

  factory ArrayNativeTypeCfe.multi(
      NativeTypeCfe elementType, List<int> dimensions) {
    if (dimensions.length == 1) {
      return ArrayNativeTypeCfe(elementType, dimensions.single);
    }
    return ArrayNativeTypeCfe(
      ArrayNativeTypeCfe.multi(elementType, dimensions.sublist(1)),
      dimensions.first,
    );
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
  Map<Abi, int?> get size =>
      elementType.size.map((abi, size) => MapEntry(abi, size * length));

  @override
  int? getSizeFor(Abi abi) => elementType.getSizeFor(abi) * length;

  @override
  Map<Abi, int?> get alignment => elementType.alignment;

  @override
  int? getAlignmentFor(Abi abi) => elementType.getAlignmentFor(abi);

  // Note that we flatten multi dimensional arrays.
  @override
  Constant generateConstant(FfiTransformer transformer) => InstanceConstant(
        transformer.ffiInlineArrayClass.reference,
        [],
        {
          transformer.ffiInlineArrayElementTypeField.fieldReference:
              singleElementType.generateConstant(transformer),
          transformer.ffiInlineArrayLengthField.fieldReference:
              IntConstant(dimensionsFlattened)
        },
      );

  /// Sample output for `Array<Int8>`:
  ///
  /// ```
  /// Array<Int8>._(
  ///   #typedDataBase,
  ///   #offsetInBytes,
  ///   ...
  /// );
  /// ```
  @override
  Expression generateLoad({
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    InterfaceType typeArgument =
        (dartType as InterfaceType).typeArguments.single as InterfaceType;

    return ConstructorInvocation(
      transformer.arrayConstructor,
      Arguments(
        [
          typedDataBase,
          offsetInBytes,
          ConstantExpression(IntConstant(length)),
          transformer.intListConstantExpression(
              nestedDimensions, Nullability.nonNullable)
        ],
        types: [typeArgument],
      ),
    )..fileOffset = fileOffset;
  }

  /// Sample output for `set x(Array #v) =>`:
  ///
  /// ```
  /// _memCopy(#typedDataBase, #offsetInBytes, #v._typedDataBase, 0, size);
  /// ```
  @override
  Expression generateStore(
    VariableDeclaration value, {
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    return StaticInvocation(
      transformer.memCopy,
      Arguments([
        typedDataBase,
        offsetInBytes,
        transformer.getCompoundTypedDataBaseField(
          VariableGet(value)..fileOffset = fileOffset,
          fileOffset,
        ),
        transformer.getCompoundOffsetInBytesField(
          VariableGet(value)..fileOffset = fileOffset,
          fileOffset,
        ),
        transformer.runtimeBranchOnLayout(size),
      ]),
    )..fileOffset = fileOffset;
  }
}

class AbiSpecificNativeTypeCfe extends NativeTypeCfe {
  final Map<Abi, NativeTypeCfe> abiSpecificTypes;

  final Class clazz;

  AbiSpecificNativeTypeCfe(this.abiSpecificTypes, this.clazz) : super._();

  @override
  Map<Abi, int?> get size => abiSpecificTypes.map(
      (abi, nativeTypeCfe) => MapEntry(abi, nativeTypeCfe.getSizeFor(abi)));

  @override
  int? getSizeFor(Abi abi) => abiSpecificTypes[abi]?.getSizeFor(abi);

  @override
  Map<Abi, int?> get alignment => abiSpecificTypes
      .map((abi, nativeTypeCfe) => MapEntry(abi, nativeTypeCfe.alignment[abi]));

  @override
  int? getAlignmentFor(Abi abi) => abiSpecificTypes[abi]?.getAlignmentFor(abi);

  @override
  Constant generateConstant(FfiTransformer transformer) =>
      TypeLiteralConstant(InterfaceType(clazz, Nullability.nonNullable));

  @override
  Expression generateLoad({
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    return transformer.abiSpecificLoadOrStoreExpression(
      this,
      typedDataBase: typedDataBase,
      offsetInBytes: offsetInBytes,
      fileOffset: fileOffset,
    );
  }

  @override
  Expression generateStore(
    VariableDeclaration value, {
    required DartType dartType,
    required int fileOffset,
    required Expression typedDataBase,
    required FfiTransformer transformer,
    required Expression offsetInBytes,
    bool unaligned = false,
  }) {
    return transformer.abiSpecificLoadOrStoreExpression(
      this,
      typedDataBase: typedDataBase,
      offsetInBytes: offsetInBytes,
      value: VariableGet(value)..fileOffset = fileOffset,
      fileOffset: fileOffset,
    );
  }
}

extension on int? {
  int? align(int? alignment) =>
      ((this + alignment - 1) ~/ alignment) * alignment;

  int? operator *(int? other) {
    final this_ = this;
    if (this_ == null) {
      return null;
    }
    if (other == null) {
      return null;
    }
    return this_ * other;
  }

  int? operator +(int? other) {
    final this_ = this;
    if (this_ == null) {
      return null;
    }
    if (other == null) {
      return null;
    }
    return this_ + other;
  }

  int? operator -(int? other) {
    final this_ = this;
    if (this_ == null) {
      return null;
    }
    if (other == null) {
      return null;
    }
    return this_ - other;
  }

  int? operator ~/(int? other) {
    final this_ = this;
    if (this_ == null) {
      return null;
    }
    if (other == null) {
      return null;
    }
    return this_ ~/ other;
  }
}

int? max(int? a, int? b) {
  if (a == null) {
    return null;
  }
  if (b == null) {
    return null;
  }
  return math.max(a, b);
}

int? min(int? a, int? b) {
  if (a == null) {
    return null;
  }
  if (b == null) {
    return null;
  }
  return math.min(a, b);
}
