// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Poor-man's representation of a Closure type.
/// See https://developers.google.com/closure/compiler/docs/js-for-compiler
///
/// The goal here is not to completely support Closure's type system, but to
/// be able to generate just the types needed for DDC's JS output.
///
/// TODO(ochafik): Consider convergence with TypeScript, which has no nullability-awareness
/// (see http://www.typescriptlang.org/Handbook).
class ClosureType {
  static const ClosureType _ALL = const ClosureType._("*");
  static const ClosureType _UNKNOWN = const ClosureType._("?");

  final String _representation;
  final bool isNullable;

  const ClosureType._(this._representation, {this.isNullable: true});

  bool get isAll => _representation == "*";
  bool get isUnknown => _representation == "?";

  @override
  toString() => _representation;

  factory ClosureType.all() => _ALL;
  factory ClosureType.unknown() => _UNKNOWN;

  factory ClosureType.record(Map<String, ClosureType> fieldTypes) {
    var entries = <String>[];
    fieldTypes.forEach((n, t) => entries.add('$n: $t'));
    return new ClosureType._('{${entries.join(', ')}}');
  }
  factory ClosureType.function(
      [List<ClosureType> paramTypes, ClosureType returnType]) {
    if (paramTypes == null && returnType == null) {
      return new ClosureType.type("Function");
    }
    var suffix = returnType == null ? '' : ':$returnType';
    return new ClosureType._(
        'function(${paramTypes == null ? '...*' : paramTypes.join(', ')})$suffix');
  }

  factory ClosureType.map([ClosureType keyType, ClosureType valueType]) =>
      new ClosureType._("Object<${keyType ?? _ALL}, ${valueType ?? _ALL}>");

  factory ClosureType.type([String className = "Object"]) =>
      new ClosureType._(className);

  factory ClosureType.array([ClosureType componentType]) =>
      new ClosureType._("Array<${componentType ?? _ALL}>");

  factory ClosureType.undefined() =>
      new ClosureType._("undefined", isNullable: false);
  factory ClosureType.number() =>
      new ClosureType._("number", isNullable: false);
  factory ClosureType.boolean() =>
      new ClosureType._("boolean", isNullable: false);
  factory ClosureType.string() => new ClosureType._("string");

  ClosureType toOptional() => new ClosureType._("$this=");

  ClosureType toNullable() => isNullable
      ? this
      : new ClosureType._(
          _representation.startsWith('!')
              ? _representation.substring(1)
              : "?$this",
          isNullable: true);

  ClosureType toNonNullable() => !isNullable
      ? this
      : new ClosureType._(
          _representation.startsWith('?')
              ? _representation.substring(1)
              : "!$this",
          isNullable: false);

  /// TODO(ochafik): See which optimizations make sense here (it could be that `(*|undefined)`
  /// cannot be optimized to `*` when used to model optional record fields).
  ClosureType or(ClosureType other) => new ClosureType._("($this|$other)",
      isNullable: isNullable || other.isNullable);

  ClosureType orUndefined() => or(new ClosureType.undefined());
}
