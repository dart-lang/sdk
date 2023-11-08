// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'types.dart';

// Representations of all Wasm types.

/// A *storage type*.
abstract class StorageType implements Serializable {
  /// Returns whether this type is a subtype of the [other] type, i.e. whether
  /// it can be used as input where [other] is expected.
  bool isSubtypeOf(StorageType other);

  /// The *unpacked* form of this storage type, i.e. the *value type* to use
  /// when reading/writing this storage type from/to memory.
  ValueType get unpacked;

  /// Whether this is a primitive (i.e. not reference) type.
  bool get isPrimitive;

  /// For primitive types: the size in bytes of a value of this type.
  int get byteSize;
}

/// A *value type*.
abstract class ValueType implements StorageType {
  const ValueType();

  @override
  ValueType get unpacked => this;

  @override
  bool get isPrimitive => false;

  @override
  int get byteSize => throw "Size of non-primitive type $runtimeType";

  /// Whether this type is nullable. Primitive types are never nullable.
  bool get nullable => false;

  /// If this exists in both a nullable and non-nullable version, return the
  /// version with the given nullability.
  ValueType withNullability(bool nullable) => this;

  /// Whether this type is defaultable. Primitive types are always defaultable.
  bool get defaultable => true;
}

enum NumTypeKind { i32, i64, f32, f64, v128 }

/// A *number type* or *vector type*.
class NumType extends ValueType {
  final NumTypeKind kind;

  const NumType._(this.kind);

  /// The `i32` type.
  static const i32 = NumType._(NumTypeKind.i32);

  /// The `i64` type.
  static const i64 = NumType._(NumTypeKind.i64);

  /// The `f32` type.
  static const f32 = NumType._(NumTypeKind.f32);

  /// The `f64` type.
  static const f64 = NumType._(NumTypeKind.f64);

  /// The `v128` type.
  static const v128 = NumType._(NumTypeKind.v128);

  @override
  bool isSubtypeOf(StorageType other) => this == other;

  @override
  bool get isPrimitive => true;

  @override
  int get byteSize {
    switch (kind) {
      case NumTypeKind.i32:
      case NumTypeKind.f32:
        return 4;
      case NumTypeKind.i64:
      case NumTypeKind.f64:
        return 8;
      case NumTypeKind.v128:
        return 16;
    }
  }

  @override
  void serialize(Serializer s) {
    switch (kind) {
      case NumTypeKind.i32:
        s.writeByte(0x7F);
        break;
      case NumTypeKind.i64:
        s.writeByte(0x7E);
        break;
      case NumTypeKind.f32:
        s.writeByte(0x7D);
        break;
      case NumTypeKind.f64:
        s.writeByte(0x7C);
        break;
      case NumTypeKind.v128:
        s.writeByte(0x7B);
        break;
    }
  }

  @override
  String toString() {
    switch (kind) {
      case NumTypeKind.i32:
        return "i32";
      case NumTypeKind.i64:
        return "i64";
      case NumTypeKind.f32:
        return "f32";
      case NumTypeKind.f64:
        return "f64";
      case NumTypeKind.v128:
        return "v128";
    }
  }
}

/// A *reference type*.
class RefType extends ValueType {
  /// The *heap type* of this reference type.
  final HeapType heapType;

  /// The nullability of this reference type.
  @override
  final bool nullable;

  RefType(this.heapType, {bool? nullable})
      : nullable = nullable ??
            heapType.nullableByDefault ??
            (throw "Unspecified nullability");

  const RefType._(this.heapType, this.nullable);

  /// Internal supertype above any, func and extern. Not a real Wasm ref type.
  const RefType.common({required bool nullable})
      : this._(HeapType.common, nullable);

  /// A (possibly nullable) reference to the `extern` heap type.
  const RefType.extern({required bool nullable})
      : this._(HeapType.extern, nullable);

  /// A (possibly nullable) reference to the `any` heap type.
  const RefType.any({required bool nullable}) : this._(HeapType.any, nullable);

  /// A (possibly nullable) reference to the `eq` heap type.
  const RefType.eq({required bool nullable}) : this._(HeapType.eq, nullable);

  /// A (possibly nullable) reference to the `func` heap type.
  const RefType.func({required bool nullable})
      : this._(HeapType.func, nullable);

  /// A (possibly nullable) reference to the `struct` heap type.
  const RefType.struct({required bool nullable})
      : this._(HeapType.struct, nullable);

  /// A (possibly nullable) reference to the `array` heap type.
  const RefType.array({required bool nullable})
      : this._(HeapType.array, nullable);

  /// A (possibly nullable) reference to the `i31` heap type.
  const RefType.i31({required bool nullable}) : this._(HeapType.i31, nullable);

  /// A (possibly nullable) reference to the `none` heap type.
  const RefType.none({required bool nullable})
      : this._(HeapType.none, nullable);

  /// A (possibly nullable) reference to the `noextern` heap type.
  const RefType.noextern({required bool nullable})
      : this._(HeapType.noextern, nullable);

  /// A (possibly nullable) reference to the `nofunc` heap type.
  const RefType.nofunc({required bool nullable})
      : this._(HeapType.nofunc, nullable);

  /// A (possibly nullable) reference to a custom heap type.
  RefType.def(DefType defType, {required bool nullable})
      : this(defType, nullable: nullable);

  @override
  RefType withNullability(bool nullable) =>
      nullable == this.nullable ? this : RefType(heapType, nullable: nullable);

  @override
  bool get defaultable => nullable;

  @override
  bool isSubtypeOf(StorageType other) {
    if (other is! RefType) return false;
    if (nullable && !other.nullable) return false;
    return heapType.isSubtypeOf(other.heapType);
  }

  @override
  void serialize(Serializer s) {
    if (nullable != heapType.nullableByDefault) {
      s.writeByte(nullable ? 0x6C : 0x6B);
    }
    s.write(heapType);
  }

  @override
  String toString() {
    if (nullable == heapType.nullableByDefault) {
      return "${heapType.shorthandName}ref";
    }
    return "ref${nullable ? " null " : " "}$heapType";
  }

  @override
  bool operator ==(Object other) =>
      other is RefType &&
      other.heapType == heapType &&
      other.nullable == nullable;

  @override
  int get hashCode => heapType.hashCode * (nullable ? -1 : 1);
}

/// A *heap type*.
abstract class HeapType implements Serializable {
  const HeapType();

  /// Internal supertype above any, func and extern. Not a real Wasm heap type.
  static const common = CommonHeapType._();

  /// The `extern` heap type.
  static const extern = ExternHeapType._();

  /// The `any` heap type.
  static const any = AnyHeapType._();

  /// The `eq` heap type.
  static const eq = EqHeapType._();

  /// The `func` heap type.
  static const func = FuncHeapType._();

  /// The `struct` heap type.
  static const struct = StructHeapType._();

  /// The `array` heap type.
  static const array = ArrayHeapType._();

  /// The `i31` heap type.
  static const i31 = I31HeapType._();

  /// The `none` heap type.
  static const none = NoneHeapType._();

  /// The `noextern` heap type.
  static const noextern = NoExternHeapType._();

  /// The `nofunc` heap type.
  static const nofunc = NoFuncHeapType._();

  /// Whether this heap type is nullable by default, i.e. when written with the
  /// -`ref` shorthand. A `null` value here means the heap type has no default
  /// nullability, so the nullability of a reference has to be specified
  /// explicitly.
  bool? get nullableByDefault;

  /// The top type of the hierarchy containing this type.
  HeapType get topType;

  /// The bottom type of the hierarchy containing this type.
  HeapType get bottomType;

  /// Whether this heap type is a declared subtype of the other heap type.
  bool isSubtypeOf(HeapType other);

  /// Whether this heap type is a structural subtype of the other heap type.
  bool isStructuralSubtypeOf(HeapType other) => isSubtypeOf(other);

  String get shorthandName => toString();
}

/// Internal supertype above any, func and extern. This is only used to specify
/// input constraints for instructions that are polymorphic across the three
/// type hierarchies. It's not a real Wasm heap type.
class CommonHeapType extends HeapType {
  const CommonHeapType._();

  @override
  bool? get nullableByDefault => null;

  @override
  HeapType get topType => throw "No top type of internal common supertype";

  @override
  HeapType get bottomType =>
      throw "No bottom type of internal common supertype";

  @override
  bool isSubtypeOf(HeapType other) => other == HeapType.common;

  @override
  void serialize(Serializer s) =>
      throw "Attempt to serialize internal common supertype";

  @override
  String toString() => "#common";
}

/// The `extern` heap type.
class ExternHeapType extends HeapType {
  const ExternHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.extern;

  @override
  HeapType get bottomType => HeapType.noextern;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common || other == HeapType.extern;

  @override
  void serialize(Serializer s) => s.writeByte(0x6F);

  @override
  String toString() => "extern";
}

/// The `any` heap type.
class AnyHeapType extends HeapType {
  const AnyHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.any;

  @override
  HeapType get bottomType => HeapType.none;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common || other == HeapType.any;

  @override
  void serialize(Serializer s) => s.writeByte(0x6E);

  @override
  String toString() => "any";
}

/// The `eq` heap type.
class EqHeapType extends HeapType {
  const EqHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.any;

  @override
  HeapType get bottomType => HeapType.none;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common || other == HeapType.any || other == HeapType.eq;

  @override
  void serialize(Serializer s) => s.writeByte(0x6D);

  @override
  String toString() => "eq";
}

/// The `func` heap type.
class FuncHeapType extends HeapType {
  const FuncHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.func;

  @override
  HeapType get bottomType => HeapType.nofunc;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common || other == HeapType.func;

  @override
  void serialize(Serializer s) => s.writeByte(0x70);

  @override
  String toString() => "func";
}

/// The `struct` heap type.
class StructHeapType extends HeapType {
  const StructHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.any;

  @override
  HeapType get bottomType => HeapType.none;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common ||
      other == HeapType.any ||
      other == HeapType.eq ||
      other == HeapType.struct;

  @override
  void serialize(Serializer s) => s.writeByte(0x67);

  @override
  String toString() => "struct";
}

/// The `array` heap type.
class ArrayHeapType extends HeapType {
  const ArrayHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.any;

  @override
  HeapType get bottomType => HeapType.none;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common ||
      other == HeapType.any ||
      other == HeapType.eq ||
      other == HeapType.array;

  @override
  void serialize(Serializer s) => s.writeByte(0x66);

  @override
  String toString() => "array";
}

/// The `i31` heap type.
class I31HeapType extends HeapType {
  const I31HeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.any;

  @override
  HeapType get bottomType => HeapType.none;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common ||
      other == HeapType.any ||
      other == HeapType.eq ||
      other == HeapType.i31;

  @override
  void serialize(Serializer s) => s.writeByte(0x6A);

  @override
  String toString() => "i31";
}

/// The `none` heap type.
class NoneHeapType extends HeapType {
  const NoneHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.any;

  @override
  HeapType get bottomType => HeapType.none;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common || other.bottomType == HeapType.none;

  @override
  void serialize(Serializer s) => s.writeByte(0x65);

  @override
  String toString() => "none";

  @override
  String get shorthandName => "null";
}

/// The `noextern` heap type.
class NoExternHeapType extends HeapType {
  const NoExternHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.extern;

  @override
  HeapType get bottomType => HeapType.noextern;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common || other.bottomType == HeapType.noextern;

  @override
  void serialize(Serializer s) => s.writeByte(0x69);

  @override
  String toString() => "extern";

  @override
  String get shorthandName => "nullextern";
}

/// The `nofunc` heap type.
class NoFuncHeapType extends HeapType {
  const NoFuncHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.func;

  @override
  HeapType get bottomType => HeapType.nofunc;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common || other.bottomType == HeapType.nofunc;

  @override
  void serialize(Serializer s) => s.writeByte(0x68);

  @override
  String toString() => "nofunc";

  @override
  String get shorthandName => "nullfunc";
}

/// A custom heap type.
abstract class DefType extends HeapType {
  int? _index;

  /// The declared supertype of this heap type.
  final DefType? superType;

  /// The length of the supertype chain of this heap type.
  final int depth;

  bool hasAnySubtypes = false;

  DefType({this.superType})
      : depth = superType != null ? superType.depth + 1 : 0 {
    superType?.hasAnySubtypes = true;
  }

  int get index => _index ?? (throw "$runtimeType $this not added to module");
  set index(int i) => _index = i;

  bool get hasSuperType => superType != null;

  @override
  bool? get nullableByDefault => null;

  @override
  bool isSubtypeOf(HeapType other) {
    if (this == other) return true;
    return (superType ?? abstractSuperType).isSubtypeOf(other);
  }

  HeapType get abstractSuperType;

  Iterable<StorageType> get constituentTypes;

  @override
  void serialize(Serializer s) => s.writeSigned(index);

  // Serialize the type for the type section, including the supertype reference,
  // if any.
  void serializeDefinition(Serializer s) {
    if (hasSuperType) {
      s.writeByte(hasAnySubtypes ? 0x50 : 0x4E);
      s.writeUnsigned(1);
      assert(isStructuralSubtypeOf(superType!));
      s.write(superType!);
    } else if (hasAnySubtypes) {
      s.writeByte(0x50);
      s.writeUnsigned(0);
    }
    serializeDefinitionInner(s);
  }

  // Serialize the type for the type section, excluding supertype references.
  void serializeDefinitionInner(Serializer s);
}

/// A custom function type.
class FunctionType extends DefType {
  final List<ValueType> inputs;
  final List<ValueType> outputs;

  FunctionType(this.inputs, this.outputs, {super.superType});

  @override
  HeapType get abstractSuperType => HeapType.func;

  @override
  HeapType get topType => HeapType.func;

  @override
  HeapType get bottomType => HeapType.nofunc;

  @override
  Iterable<StorageType> get constituentTypes => [...inputs, ...outputs];

  @override
  bool isStructuralSubtypeOf(HeapType other) {
    if (other == HeapType.common || other == HeapType.func) return true;
    if (other is! FunctionType) return false;
    if (inputs.length != other.inputs.length) return false;
    if (outputs.length != other.outputs.length) return false;
    for (int i = 0; i < inputs.length; i++) {
      // Inputs are contravariant.
      if (!other.inputs[i].isSubtypeOf(inputs[i])) return false;
    }
    for (int i = 0; i < outputs.length; i++) {
      // Outputs are covariant.
      if (!outputs[i].isSubtypeOf(other.outputs[i])) return false;
    }
    return true;
  }

  @override
  void serializeDefinitionInner(Serializer s) {
    s.writeByte(0x60);
    s.writeList(inputs);
    s.writeList(outputs);
  }

  @override
  String toString() => "(${inputs.join(", ")}) -> (${outputs.join(", ")})";
}

/// A named deftype, i.e. `struct` or `array`.
abstract class DataType extends DefType {
  final String name;

  DataType(this.name, {super.superType});

  @override
  HeapType get topType => HeapType.any;

  @override
  HeapType get bottomType => HeapType.none;

  @override
  String toString() => name;
}

/// A custom `struct` type.
class StructType extends DataType {
  final List<FieldType> fields = [];

  StructType(super.name, {Iterable<FieldType>? fields, super.superType}) {
    if (fields != null) this.fields.addAll(fields);
  }

  @override
  HeapType get abstractSuperType => HeapType.struct;

  @override
  Iterable<StorageType> get constituentTypes =>
      [for (FieldType f in fields) f.type];

  @override
  bool isStructuralSubtypeOf(HeapType other) {
    if (other == HeapType.common ||
        other == HeapType.any ||
        other == HeapType.eq ||
        other == HeapType.struct) {
      return true;
    }
    if (other is! StructType) return false;
    if (fields.length < other.fields.length) return false;
    for (int i = 0; i < other.fields.length; i++) {
      if (!fields[i].isSubtypeOf(other.fields[i])) return false;
    }
    return true;
  }

  @override
  void serializeDefinitionInner(Serializer s) {
    s.writeByte(0x5F);
    s.writeList(fields);
  }
}

/// A custom `array` type.
class ArrayType extends DataType {
  late final FieldType elementType;

  ArrayType(super.name, {FieldType? elementType, super.superType}) {
    if (elementType != null) this.elementType = elementType;
  }

  @override
  HeapType get abstractSuperType => HeapType.array;

  @override
  Iterable<StorageType> get constituentTypes => [elementType.type];

  @override
  bool isStructuralSubtypeOf(HeapType other) {
    if (other == HeapType.common ||
        other == HeapType.any ||
        other == HeapType.eq ||
        other == HeapType.array) {
      return true;
    }
    if (other is! ArrayType) return false;
    return elementType.isSubtypeOf(other.elementType);
  }

  @override
  void serializeDefinitionInner(Serializer s) {
    s.writeByte(0x5E);
    s.write(elementType);
  }
}

class _WithMutability<T extends StorageType> implements Serializable {
  final T type;
  final bool mutable;

  _WithMutability(this.type, {required this.mutable});

  @override
  void serialize(Serializer s) {
    s.write(type);
    s.writeByte(mutable ? 0x01 : 0x00);
  }

  @override
  String toString() => "${mutable ? "var " : "const "}$type";
}

/// A type for a global.
///
/// It consists of a type and a mutability.
class GlobalType extends _WithMutability<ValueType> {
  GlobalType(super.type, {super.mutable = true});
}

/// A type for a struct field or an array element.
///
/// It consists of a value type and a mutability.
class FieldType extends _WithMutability<StorageType> {
  FieldType(super.type, {super.mutable = true});

  /// The `i8` storage type as a field type.
  FieldType.i8({bool mutable = true}) : this(PackedType.i8, mutable: mutable);

  /// The `i16` storage type as a field type.
  FieldType.i16({bool mutable = true}) : this(PackedType.i16, mutable: mutable);

  bool isSubtypeOf(FieldType other) {
    if (mutable != other.mutable) return false;
    if (mutable) {
      // Mutable fields are invariant.
      return type == other.type;
    } else {
      // Immutable fields are covariant.
      return type.isSubtypeOf(other.type);
    }
  }
}

enum PackedTypeKind { i8, i16 }

/// A *packed type*, i.e. a storage type that only exists in memory.
class PackedType implements StorageType {
  final PackedTypeKind kind;

  const PackedType._(this.kind);

  /// The `i8` storage type.
  static const i8 = PackedType._(PackedTypeKind.i8);

  /// The `i16` storage type.
  static const i16 = PackedType._(PackedTypeKind.i16);

  @override
  ValueType get unpacked => NumType.i32;

  @override
  bool isSubtypeOf(StorageType other) => this == other;

  @override
  bool get isPrimitive => true;

  @override
  int get byteSize {
    switch (kind) {
      case PackedTypeKind.i8:
        return 1;
      case PackedTypeKind.i16:
        return 2;
    }
  }

  @override
  void serialize(Serializer s) {
    switch (kind) {
      case PackedTypeKind.i8:
        s.writeByte(0x7A);
        break;
      case PackedTypeKind.i16:
        s.writeByte(0x79);
        break;
    }
  }

  @override
  String toString() {
    switch (kind) {
      case PackedTypeKind.i8:
        return "i8";
      case PackedTypeKind.i16:
        return "i16";
    }
  }
}
