// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

final _any = AnyTypeRef._();
final _unknown = UnknownTypeRef._();
final _null = NullTypeRef();

/// JavaScript type reference, designed to support a subset of the type systems
/// of the Closure Compiler and TypeScript:
/// - https://developers.google.com/closure/compiler/docs/js-for-compiler#types
/// - https://github.com/Microsoft/TypeScript/blob/v1.8.0-beta/doc/spec.md#3
///
/// Note that some subtleties like "nullability" or "optionality" are handled
/// using unions (with a [NullTypeRef] or with an "undefined" named typeref).
/// Also, primitives aren't modeled differently than named / qualified types,
/// as it brings little value for now. Primitive-specific type formatting is
/// handled by the type printers (for instance, the knowledge that
/// `number|null` is just `number` in TypeScript, and is `number?` in Closure).
abstract class TypeRef extends Expression {
  int get precedenceLevel => PRIMARY;

  TypeRef();

  factory TypeRef.any() => _any;

  factory TypeRef.void_() => TypeRef.named('void');

  factory TypeRef.unknown() => _unknown;

  factory TypeRef.generic(TypeRef rawType, Iterable<TypeRef> typeArgs) {
    if (typeArgs.isEmpty) {
      throw ArgumentError.value(typeArgs, "typeArgs", "is empty");
    }
    return GenericTypeRef(rawType, typeArgs.toList());
  }

  factory TypeRef.array([TypeRef elementType]) => ArrayTypeRef(elementType);

  factory TypeRef.object([TypeRef keyType, TypeRef valueType]) {
    // TODO(ochafik): Roll out a dedicated ObjectTypeRef?
    var rawType = TypeRef.named('Object');
    return keyType == null && valueType == null
        ? rawType
        : GenericTypeRef(rawType, [keyType ?? _any, valueType ?? _any]);
  }

  factory TypeRef.function(
          [TypeRef returnType, Map<Identifier, TypeRef> paramTypes]) =>
      FunctionTypeRef(returnType, paramTypes);

  factory TypeRef.record(Map<Identifier, TypeRef> types) =>
      RecordTypeRef(types);

  factory TypeRef.string() => TypeRef.named('string');

  factory TypeRef.number() => TypeRef.named('number');

  factory TypeRef.undefined() => TypeRef.named('undefined');

  factory TypeRef.boolean() => TypeRef.named('boolean');

  factory TypeRef.qualified(List<Identifier> path) => QualifiedTypeRef(path);

  factory TypeRef.named(String name) =>
      TypeRef.qualified(<Identifier>[Identifier(name)]);

  bool get isAny => this is AnyTypeRef;
  bool get isUnknown => this is UnknownTypeRef;
  bool get isNull => this is NullTypeRef;

  TypeRef or(TypeRef other) => UnionTypeRef([this, other]);

  TypeRef orUndefined() => or(TypeRef.undefined());
  TypeRef orNull() => or(_null);

  TypeRef toOptional() => OptionalTypeRef(this);
}

class AnyTypeRef extends TypeRef {
  AnyTypeRef._() : super();

  factory AnyTypeRef() => _any;
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAnyTypeRef(this);
  void visitChildren(NodeVisitor visitor) {}
  _clone() => AnyTypeRef();
}

class NullTypeRef extends QualifiedTypeRef {
  NullTypeRef() : super([Identifier("null")]);
  _clone() => NullTypeRef();
}

class UnknownTypeRef extends TypeRef {
  UnknownTypeRef._() : super();

  factory UnknownTypeRef() => _unknown;
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitUnknownTypeRef(this);
  void visitChildren(NodeVisitor visitor) {}
  _clone() => UnknownTypeRef();
}

class QualifiedTypeRef extends TypeRef {
  final List<Identifier> path;
  QualifiedTypeRef(this.path);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitQualifiedTypeRef(this);
  void visitChildren(NodeVisitor visitor) =>
      path.forEach((p) => p.accept(visitor));
  _clone() => QualifiedTypeRef(path);
}

class ArrayTypeRef extends TypeRef {
  final TypeRef elementType;
  ArrayTypeRef(this.elementType);
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayTypeRef(this);
  void visitChildren(NodeVisitor visitor) {
    elementType.accept(visitor);
  }

  _clone() => ArrayTypeRef(elementType);
}

class GenericTypeRef extends TypeRef {
  final TypeRef rawType;
  final List<TypeRef> typeArgs;
  GenericTypeRef(this.rawType, this.typeArgs);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitGenericTypeRef(this);
  void visitChildren(NodeVisitor visitor) {
    rawType.accept(visitor);
    typeArgs.forEach((p) => p.accept(visitor));
  }

  _clone() => GenericTypeRef(rawType, typeArgs);
}

class UnionTypeRef extends TypeRef {
  final List<TypeRef> types;
  UnionTypeRef(this.types);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitUnionTypeRef(this);
  void visitChildren(NodeVisitor visitor) {
    types.forEach((p) => p.accept(visitor));
  }

  _clone() => UnionTypeRef(types);

  @override
  TypeRef or(TypeRef other) {
    if (types.contains(other)) return this;
    return UnionTypeRef([]
      ..addAll(types)
      ..add(other));
  }
}

class OptionalTypeRef extends TypeRef {
  final TypeRef type;
  OptionalTypeRef(this.type);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitOptionalTypeRef(this);
  void visitChildren(NodeVisitor visitor) {
    type.accept(visitor);
  }

  _clone() => OptionalTypeRef(type);

  @override
  TypeRef orUndefined() => this;
}

class RecordTypeRef extends TypeRef {
  final Map<Identifier, TypeRef> types;
  RecordTypeRef(this.types);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitRecordTypeRef(this);
  void visitChildren(NodeVisitor visitor) {
    types.values.forEach((p) => p.accept(visitor));
  }

  _clone() => RecordTypeRef(types);
}

class FunctionTypeRef extends TypeRef {
  final TypeRef returnType;
  final Map<Identifier, TypeRef> paramTypes;
  FunctionTypeRef(this.returnType, this.paramTypes);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFunctionTypeRef(this);
  void visitChildren(NodeVisitor visitor) {
    returnType.accept(visitor);
    paramTypes.forEach((n, t) {
      n.accept(visitor);
      t.accept(visitor);
    });
  }

  _clone() => FunctionTypeRef(returnType, paramTypes);
}
