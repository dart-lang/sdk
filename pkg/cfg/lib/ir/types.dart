// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Type system used by CFG IR.
///
/// CFG types are based on Dart static types which are represented with
/// DartType AST nodes. Eventually we can add more attributes to CFG IR types,
/// such as known class or exact type.
///
/// In addition to Dart types, there are a few extended types, used to
/// represent types of IR instructions which yield non-Dart values
/// (such as type arguments).
///
/// Important features of CFG IR types:
///
/// * Built-in types are const-constructible,
///   e.g. `const IntType()` can be used to obtain Dart `int` type.
///   This allows built-in types to be used in constant data-structures.
///
/// * Built-in types can be recognized with simple `is` test,
///   e.g. `type is StringType` can be used to recognize Dart `String` type,
///   even when there are several implementation types like `_OneByteString`
///   and `_TwoByteString`.
///
/// * CFG IR types is a superset of Dart static types (any Dart static type
///   can be converted to CFG IR type).
library;

import 'package:cfg/ir/global_context.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;

/// Kinds of CFG IR types.
enum TypeKind {
  // Dart types.
  intType,
  doubleType,
  boolType,
  stringType,
  recordType,
  objectType,
  nullType,
  neverType,
  top,
  otherDartType,
  // Extended (non-Dart) types.
  nothing,
  lateValue,
  typeParameters,
  typeArguments,
  context,
}

/// Base class for types used in the CFG IR.
sealed class const CType() {
  /// Create CFG IR type from Dart static type.
  static CType fromStaticType(ast.DartType dartType) =>
      GlobalContext.instance.astToIrTypes.translate(dartType);

  /// Kind of this CFG IR type.
  TypeKind get kind;

  /// Dart static type corresponding to this CFG IR type.
  /// Cannot be queried for extended (non-Dart) types.
  ast.DartType get dartType;

  /// Returns true if [this] type is a subtype of [other].
  bool isSubtypeOf(CType other) => GlobalContext.instance.typeEnvironment
      .isSubtypeOf(this.dartType, other.dartType);

  /// Returns true if value of this type can be `null`.
  bool get isNullable;

  /// Return non-nullable variant of this type (if possible).
  CType get toNonNullableType;

  /// Returns true if value of this type can be `int`.
  bool get canBeInt;

  /// Returns true if value of this type can be `Future`.
  bool get canBeFuture;

  @override
  bool operator ==(Object other) =>
      other is CType &&
      this.kind == other.kind &&
      this.dartType == other.dartType;

  @override
  int get hashCode => finalizeHash(combineHash(dartType.hashCode, kind.index));
}

/// Dart `int` type.
final class const IntType([final ast.DartType? _dartType]) extends CType {
  @override
  TypeKind get kind => TypeKind.intType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.intNonNullableRawType;

  @override
  bool get isNullable => false;

  @override
  CType get toNonNullableType => this;

  @override
  bool get canBeInt => true;

  @override
  bool get canBeFuture => false;

  @override
  String toString() => 'int';
}

/// Dart `double` type.
final class const DoubleType([final ast.DartType? _dartType]) extends CType {
  @override
  TypeKind get kind => TypeKind.doubleType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.doubleNonNullableRawType;

  @override
  bool get isNullable => false;

  @override
  CType get toNonNullableType => this;

  @override
  bool get canBeInt => false;

  @override
  bool get canBeFuture => false;

  @override
  String toString() => 'double';
}

/// Dart `bool` type.
final class const BoolType([final ast.DartType? _dartType]) extends CType {
  @override
  TypeKind get kind => TypeKind.boolType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.boolNonNullableRawType;

  @override
  bool get isNullable => false;

  @override
  CType get toNonNullableType => this;

  @override
  bool get canBeInt => false;

  @override
  bool get canBeFuture => false;

  @override
  String toString() => 'bool';
}

/// Dart `String` type.
final class const StringType([final ast.DartType? _dartType]) extends CType {
  @override
  TypeKind get kind => TypeKind.stringType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.stringNonNullableRawType;

  @override
  bool get isNullable => false;

  @override
  CType get toNonNullableType => this;

  @override
  bool get canBeInt => false;

  @override
  bool get canBeFuture => false;

  @override
  String toString() => 'String';
}

/// Shape of the Dart record.
/// Records with the same shape are compatible wrt field access.
final class RecordShape {
  // Number of positional fields.
  final int positional;
  // Named fields (sorted lexicographically).
  final List<String> named;

  const RecordShape(this.positional, this.named);

  @override
  String toString() =>
      'Record[$positional${named.isNotEmpty ? ', named: $named' : ''}]';

  @override
  bool operator ==(Object other) =>
      other is RecordShape &&
      this.positional == other.positional &&
      listEquals(this.named, other.named);

  @override
  int get hashCode =>
      finalizeHash(combineHash(positional.hashCode, listHashCode(named)));
}

/// Non-nullable Dart record type.
final class RecordType extends CType {
  @override
  TypeKind get kind => TypeKind.recordType;

  @override
  final ast.RecordType dartType;

  late final shape = RecordShape(dartType.positional.length, [
    for (final namedType in dartType.named) namedType.name,
  ]);

  RecordType(this.dartType) : assert(dartType.nullability == .nonNullable);

  int get numFields => dartType.positional.length + dartType.named.length;

  @override
  bool get isNullable => false;

  @override
  CType get toNonNullableType => this;

  @override
  bool get canBeInt => false;

  @override
  bool get canBeFuture => false;

  @override
  String toString() => dartType.getDisplayString();
}

/// Dart `Object` type.
final class const ObjectType([final ast.DartType? _dartType]) extends CType {
  @override
  TypeKind get kind => TypeKind.objectType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.objectNonNullableRawType;

  @override
  bool get isNullable => false;

  @override
  CType get toNonNullableType => this;

  @override
  bool get canBeInt => true;

  @override
  bool get canBeFuture => true;

  @override
  String toString() => 'Object';
}

/// Dart `Null` type.
final class const NullType() extends CType {
  @override
  TypeKind get kind => TypeKind.nullType;

  @override
  ast.DartType get dartType => const ast.NullType();

  @override
  bool get isNullable => true;

  @override
  CType get toNonNullableType => const NeverType();

  @override
  bool get canBeInt => false;

  @override
  bool get canBeFuture => false;

  @override
  String toString() => 'Null';
}

/// Dart `Never` type.
final class const NeverType() extends CType {
  @override
  TypeKind get kind => TypeKind.neverType;

  @override
  ast.DartType get dartType => const ast.NeverType.nonNullable();

  @override
  bool get isNullable => false;

  @override
  CType get toNonNullableType => this;

  @override
  bool get canBeInt => false;

  @override
  bool get canBeFuture => false;

  @override
  String toString() => 'Never';
}

/// Dart top type such as `Object?`, `dynamic`, `void`, or `FutureOr` of those.
final class const TopType([final ast.DartType? _dartType]) extends CType {
  @override
  TypeKind get kind => TypeKind.top;

  @override
  ast.DartType get dartType => _dartType ?? const ast.DynamicType();

  @override
  bool get isNullable => true;

  @override
  CType get toNonNullableType => const ObjectType();

  @override
  bool get canBeInt => true;

  @override
  bool get canBeFuture => true;

  @override
  String toString() => '<top>';
}

/// Dart types not covered by the built-in types above.
final class StaticType(final ast.DartType dartType) extends CType {
  @override
  TypeKind get kind => TypeKind.otherDartType;

  @override
  bool get isNullable => dartType.isPotentiallyNullable;

  @override
  CType get toNonNullableType => CType.fromStaticType(dartType.toNonNull());

  @override
  bool get canBeInt {
    ast.DartType type = dartType;
    for (;;) {
      switch (type) {
        case ast.InterfaceType():
          return GlobalContext.instance.typeEnvironment.isSubtypeOf(
            GlobalContext.instance.coreTypes.intNonNullableRawType,
            type,
          );
        case ast.RecordType() ||
            ast.FunctionType() ||
            ast.NeverType() ||
            ast.NullType():
          return false;
        case ast.DynamicType() || ast.VoidType():
          return true;
        case ast.ClassTypeParameterType():
          type = type.parameter.bound;
          break;
        case ast.FunctionTypeParameterType():
          type = type.parameter.bound;
          break;
        case ast.FutureOrType():
          type = type.typeArgument;
          break;
        case ast.ExtensionType():
          type = type.extensionTypeErasure;
          break;
        case ast.TypedefType():
          type = type.unalias;
          break;
        case ast.IntersectionType():
          type = type.left;
          break;
        case ast.TypeParameterType():
          type = type.parameter.bound;
          break;
        case ast.AuxiliaryType() ||
            ast.InvalidType() ||
            ast.StructuralParameterType():
          throw 'Unexpected type ${type.runtimeType} $type';
      }
    }
  }

  @override
  bool get canBeFuture => true;

  @override
  String toString() => dartType.getDisplayString();
}

/// Base class for non-Dart types.
/// These types are used for instructions which do not yield Dart instances.
sealed class const ExtendedType() extends CType {
  @override
  ast.DartType get dartType => throw ArgumentError(
    '${runtimeType} does not have corresponding Dart type',
  );

  @override
  bool isSubtypeOf(CType other) => this == other;

  @override
  bool get isNullable => false;

  @override
  CType get toNonNullableType => this;

  @override
  bool get canBeInt => false;

  @override
  bool get canBeFuture => false;

  @override
  bool operator ==(Object other) =>
      other is ExtendedType && this.kind == other.kind;

  @override
  int get hashCode => kind.index;
}

/// Type of an instruction which doesn't yield a value.
///
/// [NothingType] is different to [NeverType]. [NothingType] is used for
/// 'statement-like' instructions which do not yield a value, whereas
/// [NeverType] is used when the instruction cannot complete normally.
///
/// [NothingType] is different from the Dart `void` type. `void` means
/// 'the value can be anything, but you must not use the value', and is
/// represented with [TopType].
final class const NothingType() extends ExtendedType {
  @override
  TypeKind get kind => TypeKind.nothing;

  @override
  String toString() => '<nothing>';
}

/// Type of a late variable which can have an uninitialized state
/// (represented with [SentinelConstant] value).
///
/// After checking, it can be casted to a regular Dart type.
final class const LateValueType() extends ExtendedType {
  @override
  TypeKind get kind => TypeKind.lateValue;

  @override
  String toString() => '<late-value>';
}

/// Type of [TypeParameters] instruction.
final class const TypeParametersType() extends ExtendedType {
  @override
  TypeKind get kind => TypeKind.typeParameters;

  @override
  String toString() => '<type-parameters>';
}

/// Type of [TypeArguments] instruction and [Constant] type arguments.
final class const TypeArgumentsType() extends ExtendedType {
  @override
  TypeKind get kind => TypeKind.typeArguments;

  @override
  String toString() => '<type-arguments>';
}

/// Type of [AllocateContext] instruction.
final class const ContextType() extends ExtendedType {
  @override
  TypeKind get kind => TypeKind.context;

  @override
  String toString() => '<context>';
}
