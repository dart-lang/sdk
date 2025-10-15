// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import '../serialize/printer.dart';

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

  static StorageType deserialize(Deserializer d, List<DefType> types) {
    final code = d.peekByte();
    switch (code) {
      case 0x78: // -0x8
      case 0x77: // -0x9
        return PackedType.deserialize(d);
      default:
        return ValueType.deserialize(d, types);
    }
  }
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

  /// The heap [DefType] referenced by this type if any.
  ///
  /// Used by the type builder to determine the set of [DefType]s referenced in
  /// a module.
  DefType? get containedDefType => null;

  static ValueType deserialize(Deserializer d, List<DefType> types) {
    final code = d.peekByte();
    switch (code) {
      case 0x7F: // -0x01
      case 0x7E: // -0x02
      case 0x7D: // -0x03
      case 0x7C: // -0x04
      case 0x7B: // -0x05
        return NumType.deserialize(d);
      default:
        return RefType.deserialize(d, types);
    }
  }
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
        s.writeByte(0x7F); // -0x01
        break;
      case NumTypeKind.i64:
        s.writeByte(0x7E); // -0x02
        break;
      case NumTypeKind.f32:
        s.writeByte(0x7D); // -0x03
        break;
      case NumTypeKind.f64:
        s.writeByte(0x7C); // -0x04
        break;
      case NumTypeKind.v128:
        s.writeByte(0x7B); // -0x05
        break;
    }
  }

  static NumType deserialize(Deserializer d) {
    final code = d.readByte();
    switch (code) {
      case 0x7F: // -0x01
        return i32;
      case 0x7E: // -0x02
        return i64;
      case 0x7D: // -0x03
        return f32;
      case 0x7C: // -0x04
        return f64;
      case 0x7B: // -0x05
        return v128;
      default:
        throw "Invalid NumType code: $code";
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

  /// A (possibly nullable) reference to the `exn` heap type.
  const RefType.exn({required bool nullable}) : this._(HeapType.exn, nullable);

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
  DefType? get containedDefType {
    final type = heapType;
    return type is DefType ? type : null;
  }

  @override
  void serialize(Serializer s) {
    if (nullable != heapType.nullableByDefault) {
      s.writeByte(nullable ? 0x63 : 0x64); // -0x1d, -0x1c
    }
    s.write(heapType);
  }

  static RefType deserialize(Deserializer d, List<DefType> types) {
    final code = d.peekByte();
    bool nullable;
    HeapType heapType;
    switch (code) {
      case 0x63: // -0x1d
        d.readByte();
        nullable = true;
        heapType = HeapType.deserialize(d, types);
        break;
      case 0x64: // -0x1c
        d.readByte();
        nullable = false;
        heapType = HeapType.deserialize(d, types);
        break;
      default:
        heapType = HeapType.deserialize(d, types);
        nullable = heapType.nullableByDefault!;
        assert(heapType is! UnresolvedDefType);
        break;
    }
    return RefType._(heapType, nullable);
  }

  @override
  String toString() {
    if (nullable == heapType.nullableByDefault) {
      return "${heapType.shorthandName}ref";
    }
    return "ref ${nullable ? "null " : ""}$heapType";
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

  /// The `exn` heap type.
  static const exn = ExnHeapType._();

  /// The `noexn` heap type.
  static const noexn = NoExnHeapType._();

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

  static HeapType deserialize(Deserializer d, List<DefType> types) {
    final code = d.readSigned();
    if (code >= 0) {
      if (code < types.length) {
        return types[code];
      }
      // This happens in wasm type section reading if circular types are
      // involved.
      return UnresolvedDefType(code);
    }
    switch (code) {
      case -0x11: // 0x6F
        return extern;
      case -0x12: // 0x6E
        return any;
      case -0x13: // 0x6D
        return eq;
      case -0x10: // 0x70
        return func;
      case -0x15: // 0x6B
        return struct;
      case -0x16: // 0x6A
        return array;
      case -0x14: // 0x6C
        return i31;
      case -0x0f: // 0x71
        return none;
      case -0x0e: // 0x72
        return noextern;
      case -0x0d: // 0x73
        return nofunc;
      case -0x17: // 0x69
        return exn;
      case -0x0c: // 0x74
        return noexn;
      default:
        throw "Invalid heap type code: $code";
    }
  }
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
  void serialize(Serializer s) => s.writeByte(0x6F); // -0x11

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
  void serialize(Serializer s) => s.writeByte(0x6E); // -0x12

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
  void serialize(Serializer s) => s.writeByte(0x6D); // -0x13

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
  void serialize(Serializer s) => s.writeByte(0x70); // -0x10

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
  void serialize(Serializer s) => s.writeByte(0x6B); // -0x15

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
  void serialize(Serializer s) => s.writeByte(0x6A); // -0x16

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
  void serialize(Serializer s) => s.writeByte(0x6C); // -0x14

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
  void serialize(Serializer s) => s.writeByte(0x71); // -0x0f

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
  void serialize(Serializer s) => s.writeByte(0x72); // -0x0e

  @override
  String toString() => "noextern";

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
  void serialize(Serializer s) => s.writeByte(0x73); // -0x0d

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
      s.writeByte(hasAnySubtypes ? 0x50 : 0x4F); // -0x30, -0x31
      s.writeUnsigned(1);
      assert(isStructuralSubtypeOf(superType!));
      s.write(superType!);
    } else if (hasAnySubtypes) {
      s.writeByte(0x50); // -0x30
      s.writeUnsigned(0);
    }
    serializeDefinitionInner(s);
  }

  // Serialize the type for the type section, excluding supertype references.
  void serializeDefinitionInner(Serializer s);

  static DefType deserializeAllocate(Deserializer d, List<DefType> existing) {
    final code = d.peekByte();
    DefType? superType;
    bool hasSubtypes;
    switch (code) {
      case 0x50: // -0x30
        d.readByte();
        hasSubtypes = true;
        final count = d.readUnsigned();
        if (count == 1) {
          final superTypeIndex = d.readUnsigned();
          superType = existing[superTypeIndex];
        } else {
          assert(count == 0);
        }
        break;
      case 0x4F: // -0x31
        d.readByte();
        hasSubtypes = false;
        final count = d.readUnsigned();
        if (count == 1) {
          final superTypeIndex = d.readUnsigned();
          superType = existing[superTypeIndex];
        } else {
          assert(count == 0);
        }
        break;
      default:
        hasSubtypes = false;
        break;
    }
    final code2 = d.readByte();
    DefType result;
    switch (code2) {
      case 0x60: // -0x20
        result = FunctionType.deserializeAllocate(d, superType, existing);
      case 0x5F: // -0x21
        result = StructType.deserializeAllocate(d, superType, existing);
      case 0x5E: // -0x22
        result = ArrayType.deserializeAllocate(d, superType, existing);
      default:
        throw "Invalid DefType code: $code2";
    }
    result.hasAnySubtypes = hasSubtypes;
    return result;
  }

  void deserializeFill(Deserializer d, List<DefType> existing) {
    final code = d.peekByte();
    DefType? superType;
    bool hasSubtypes;
    switch (code) {
      case 0x50: // -0x30
        d.readByte();
        hasSubtypes = true;
        final count = d.readUnsigned();
        if (count == 1) {
          final superTypeIndex = d.readUnsigned();
          superType = existing[superTypeIndex];
        } else {
          assert(count == 0);
        }
        break;
      case 0x4F: // -0x31
        d.readByte();
        hasSubtypes = false;
        final count = d.readUnsigned();
        if (count == 1) {
          final superTypeIndex = d.readUnsigned();
          superType = existing[superTypeIndex];
        } else {
          assert(count == 0);
        }
        break;
      default:
        hasSubtypes = false;
        break;
    }
    if (!identical(superType, this.superType) ||
        hasSubtypes != hasAnySubtypes) {
      throw 'Mismatch between Allocate+Fill implementation.';
    }
    final code2 = d.readByte();
    switch (code2) {
      case 0x60: // -0x20
        assert(this is FunctionType);
      case 0x5F: // -0x21
        assert(this is StructType);
      case 0x5E: // -0x22
        assert(this is ArrayType);
      default:
        throw "Invalid DefType code: $code2";
    }
    deserializeFillInner(d, existing);
  }

  void deserializeFillInner(Deserializer d, List<DefType> existing);

  void printTypeDefTo(IrPrinter p) {
    // This may generate other types that this one refers to.
    final ip = p.dup();
    printTypeDefToInternal(ip);

    p.write('(type ');
    p.writeDefTypeReference(this);
    p.write(' ');
    p.write(ip.getText());
    p.write(')');
  }

  void printTypeDefToInternal(IrPrinter p);
}

class UnresolvedDefType extends DefType {
  final int typeIndex;

  UnresolvedDefType(this.typeIndex);

  @override
  bool get nullableByDefault =>
      throw 'Cannot obtain nullableByDefault of unresolved type';

  @override
  HeapType get abstractSuperType =>
      throw 'Cannot obtain abstractSuperType of unresolved type';

  @override
  Iterable<StorageType> get constituentTypes =>
      throw 'Cannot obtain constituentTypes of unresolved type';

  @override
  HeapType get topType => throw 'Cannot obtain topType of unresolved type';

  @override
  HeapType get bottomType =>
      throw 'Cannot obtain bottomType of unresolved type';

  @override
  void serializeDefinitionInner(Serializer s) =>
      throw 'Cannot serialize unresolved type';

  @override
  void deserializeFillInner(Deserializer d, List<DefType> existing) =>
      throw 'Cannot deserialize unresolved type';

  @override
  void printTypeDefToInternal(IrPrinter p) =>
      throw 'Cannot print unresolved type';
}

/// The `exn` heap type.
class ExnHeapType extends HeapType {
  const ExnHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.exn;

  @override
  HeapType get bottomType => HeapType.noexn;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common || other == HeapType.exn;

  @override
  void serialize(Serializer s) => s.writeByte(0x69); // -0x17

  @override
  String toString() => "exn";
}

/// The `noexn` heap type.
class NoExnHeapType extends HeapType {
  const NoExnHeapType._();

  static const defaultNullability = true;

  @override
  bool? get nullableByDefault => defaultNullability;

  @override
  HeapType get topType => HeapType.exn;

  @override
  HeapType get bottomType => HeapType.noexn;

  @override
  bool isSubtypeOf(HeapType other) =>
      other == HeapType.common ||
      other == HeapType.exn ||
      other == HeapType.noexn;

  @override
  void serialize(Serializer s) => s.writeByte(0x74); // -0x0c

  @override
  String toString() => "noexn";
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

  bool isStructurallyEqualTo(FunctionType other) {
    if (inputs.length != other.inputs.length) return false;
    if (outputs.length != other.outputs.length) return false;
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i] != other.inputs[i]) return false;
    }
    for (int i = 0; i < outputs.length; i++) {
      if (outputs[i] != other.outputs[i]) return false;
    }
    return true;
  }

  @override
  void serializeDefinitionInner(Serializer s) {
    s.writeByte(0x60); // -0x20
    s.writeList(inputs);
    s.writeList(outputs);
  }

  static FunctionType deserializeAllocate(
      Deserializer d, DefType? superType, List<DefType> existing) {
    d.readList((d) => ValueType.deserialize(d, existing));
    d.readList((d) => ValueType.deserialize(d, existing));
    return FunctionType([], [], superType: superType);
  }

  @override
  void deserializeFillInner(Deserializer d, List<DefType> existing) {
    inputs.addAll(d.readList((d) => ValueType.deserialize(d, existing)));
    outputs.addAll(d.readList((d) => ValueType.deserialize(d, existing)));
  }

  @override
  void printTypeDefToInternal(IrPrinter p) {
    p.withLocalNames({}, () {
      p.write('(func ');
      printSignatureWithNamesTo(p, oneLine: false);
      p.write(')');
    });
  }

  void printOneLineSignatureTo(IrPrinter p) {
    if (inputs.isNotEmpty) {
      p.write('(param ');
      for (int i = 0; i < inputs.length; ++i) {
        if (i > 0) p.write(' ');
        p.writeValueType(inputs[i]);
      }
      p.write(')');
    }
    if (inputs.isNotEmpty && outputs.isNotEmpty) {
      p.write(' ');
    }
    for (int i = 0; i < outputs.length; ++i) {
      if (i > 0) p.write(' ');
      p.write('(result ');
      p.writeValueType(outputs[i]);
      p.write(')');
    }
  }

  void printSignatureWithNamesTo(IrPrinter p, {bool oneLine = true}) {
    final indent = !oneLine && (inputs.length + outputs.length) > 2;
    final sep = indent ? '\n  ' : ' ';

    if (indent) p.write(sep);
    for (int i = 0; i < inputs.length; ++i) {
      if (i > 0) p.write(sep);
      p.write('(param ');
      p.writeLocalIndexReference(i);
      p.write(' ');
      p.writeValueType(inputs[i]);
      p.write(')');
    }
    if (inputs.isNotEmpty && outputs.isNotEmpty) {
      p.write(sep);
    }
    for (int i = 0; i < outputs.length; ++i) {
      if (i > 0) p.write(sep);
      p.write('(result ');
      p.writeValueType(outputs[i]);
      p.write(')');
    }
  }

  @override
  String toString() => "(${inputs.join(", ")}) -> (${outputs.join(", ")})";
}

/// A named deftype, i.e. `struct` or `array`.
abstract class DataType extends DefType {
  String? name;

  DataType(this.name, {super.superType});

  @override
  HeapType get topType => HeapType.any;

  @override
  HeapType get bottomType => HeapType.none;

  @override
  String toString() => name ?? '<unnamed>';
}

/// A custom `struct` type.
class StructType extends DataType {
  final List<FieldType> fields = [];
  final Map<int, String> fieldNames = {};

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

  /// Whether this is structurally equivalent to [other].
  ///
  /// The result should be the same as:
  /// `isStructuralSubtypeOf(other) && other.isStructuralSubtypeOf(this)`.
  bool isStructurallyEqualTo(StructType other) {
    if (fields.length != other.fields.length) return false;
    for (int i = 0; i < other.fields.length; i++) {
      var f1 = fields[i];
      var f2 = other.fields[i];
      if (f1.mutable != f2.mutable) return false;
      if (f1.type != f2.type) return false;
    }
    return true;
  }

  @override
  void serializeDefinitionInner(Serializer s) {
    s.writeByte(0x5F); // -0x21
    s.writeList(fields);
  }

  static StructType deserializeAllocate(
      Deserializer d, DefType? superType, List<DefType> existing) {
    d.readList((d) => FieldType.deserialize(d, existing));
    return StructType(null, fields: [], superType: superType);
  }

  @override
  void deserializeFillInner(Deserializer d, List<DefType> existing) {
    fields.addAll(d.readList((d) => FieldType.deserialize(d, existing)));
  }

  @override
  void printTypeDefToInternal(IrPrinter p) {
    final sup = superType;

    p.write('(');
    if (sup != null) {
      p.write('sub ');
      if (!hasAnySubtypes) {
        p.write('final ');
      }
      p.writeDefTypeReference(sup);
      p.write(' (');
    }
    p.write('struct');
    p.withIndent(() {
      for (int i = 0; i < fields.length; ++i) {
        if (fields.length > 2) {
          p.writeln();
        } else {
          p.write(' ');
        }

        final field = fields[i];
        final name = '\$${fieldNames[i] ?? 'field$i'}';
        p.write('(field $name ');
        if (field.mutable) {
          p.write('(mut ');
          p.writeStorageTypeTypeReference(field.type);
          p.write(')');
        } else {
          p.writeStorageTypeTypeReference(field.type);
        }
        p.write(')');
      }
    });
    if (sup != null) {
      p.write(')');
    }
    p.write(')');
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
    s.writeByte(0x5E); // -0x22
    s.write(elementType);
  }

  static ArrayType deserializeAllocate(
      Deserializer d, DefType? superType, List<DefType> existing) {
    FieldType.deserialize(d, existing);
    return ArrayType(null, elementType: null, superType: superType);
  }

  @override
  void deserializeFillInner(Deserializer d, List<DefType> existing) {
    elementType = FieldType.deserialize(d, existing);
  }

  @override
  void printTypeDefToInternal(IrPrinter p) {
    p.write('(array ');
    p.write('(field ');
    if (elementType.mutable) {
      p.write('(mut ');
    }
    p.writeStorageTypeTypeReference(elementType.type);
    if (elementType.mutable) {
      p.write(')');
    }
    p.write('))');
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

  static (T, bool) deserialize<T extends StorageType>(
      Deserializer d, T Function(Deserializer) fun) {
    final type = fun(d);
    final mutable = d.readByte() == 0x01;
    return (type, mutable);
  }

  @override
  String toString() => "${mutable ? "var " : "const "}$type";
}

/// A type for a global.
///
/// It consists of a type and a mutability.
class GlobalType extends _WithMutability<ValueType> {
  GlobalType(super.type, {super.mutable = true});

  static GlobalType deserialize(Deserializer d, List<DefType> types) {
    final (type, mutable) =
        _WithMutability.deserialize(d, (d) => ValueType.deserialize(d, types));
    return GlobalType(type, mutable: mutable);
  }

  void printTo(IrPrinter p) {
    if (mutable) p.write('(mut ');
    p.writeValueType(type);
    if (mutable) p.write(')');
  }
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

  static FieldType deserialize(Deserializer d, List<DefType> existing) {
    final (type, mutable) = _WithMutability.deserialize(
        d, (d) => StorageType.deserialize(d, existing));
    return FieldType(type, mutable: mutable);
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
        s.writeByte(0x78); // -0x8
        break;
      case PackedTypeKind.i16:
        s.writeByte(0x77); // -0x9
        break;
    }
  }

  static PackedType deserialize(Deserializer d) {
    final code = d.readByte();
    switch (code) {
      case 0x78: // -0x8
        return i8;
      case 0x77: // -0x9
        return i16;
      default:
        throw "Invalid PackedType code: $code";
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
