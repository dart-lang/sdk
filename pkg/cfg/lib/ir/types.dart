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
  objectType,
  nullType,
  neverType,
  top,
  otherDartType,
  // Extended (non-Dart) types.
  nothing,
  typeParameters,
  typeArguments,
}

/// Base class for types used in the CFG IR.
sealed class CType {
  const CType();

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

  @override
  bool operator ==(Object other) =>
      other is CType &&
      this.kind == other.kind &&
      this.dartType == other.dartType;

  @override
  int get hashCode => finalizeHash(combineHash(dartType.hashCode, kind.index));
}

/// Dart `int` type.
final class IntType extends CType {
  final ast.DartType? _dartType;

  const IntType([this._dartType]);

  @override
  TypeKind get kind => TypeKind.intType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.intNonNullableRawType;

  @override
  String toString() => 'int';
}

/// Dart `double` type.
final class DoubleType extends CType {
  final ast.DartType? _dartType;

  const DoubleType([this._dartType]);

  @override
  TypeKind get kind => TypeKind.doubleType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.doubleNonNullableRawType;

  @override
  String toString() => 'double';
}

/// Dart `bool` type.
final class BoolType extends CType {
  final ast.DartType? _dartType;

  const BoolType([this._dartType]);

  @override
  TypeKind get kind => TypeKind.boolType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.boolNonNullableRawType;

  @override
  String toString() => 'bool';
}

/// Dart `String` type.
final class StringType extends CType {
  final ast.DartType? _dartType;

  const StringType([this._dartType]);

  @override
  TypeKind get kind => TypeKind.stringType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.stringNonNullableRawType;

  @override
  String toString() => 'String';
}

/// Dart `Object` type.
final class ObjectType extends CType {
  final ast.DartType? _dartType;

  const ObjectType([this._dartType]);

  @override
  TypeKind get kind => TypeKind.objectType;

  @override
  ast.DartType get dartType =>
      _dartType ?? GlobalContext.instance.coreTypes.objectNonNullableRawType;

  @override
  String toString() => 'Object';
}

/// Dart `Null` type.
final class NullType extends CType {
  const NullType();

  @override
  TypeKind get kind => TypeKind.nullType;

  @override
  ast.DartType get dartType => const ast.NullType();

  @override
  String toString() => 'Null';
}

/// Dart `Never` type.
final class NeverType extends CType {
  const NeverType();

  @override
  TypeKind get kind => TypeKind.neverType;

  @override
  ast.DartType get dartType => const ast.NeverType.nonNullable();

  @override
  String toString() => 'Never';
}

/// Dart top type such as `Object?`, `dynamic`, `void`, or `FutureOr` of those.
final class TopType extends CType {
  final ast.DartType? _dartType;

  const TopType([this._dartType]);

  @override
  TypeKind get kind => TypeKind.top;

  @override
  ast.DartType get dartType => _dartType ?? const ast.DynamicType();

  @override
  String toString() => '<top>';
}

/// Dart types not covered by the built-in types above.
final class StaticType extends CType {
  @override
  TypeKind get kind => TypeKind.otherDartType;

  @override
  final ast.DartType dartType;

  StaticType(this.dartType);

  @override
  String toString() => dartType.getDisplayString();
}

/// Base class for non-Dart types.
/// These types are used for instructions which do not yield Dart instances.
sealed class ExtendedType extends CType {
  const ExtendedType();

  @override
  ast.DartType get dartType => throw ArgumentError(
    '${runtimeType} does not have corresponding Dart type',
  );

  @override
  bool isSubtypeOf(CType other) => this == other;

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
final class NothingType extends ExtendedType {
  const NothingType();

  @override
  TypeKind get kind => TypeKind.nothing;

  @override
  String toString() => '<nothing>';
}

/// Type of [TypeParameters] instruction.
final class TypeParametersType extends ExtendedType {
  const TypeParametersType();

  @override
  TypeKind get kind => TypeKind.typeParameters;

  @override
  String toString() => '<type-parameters>';
}

/// Type of [TypeArguments] instruction.
final class TypeArgumentsType extends ExtendedType {
  const TypeArgumentsType();

  @override
  TypeKind get kind => TypeKind.typeArguments;

  @override
  String toString() => '<type-arguments>';
}
