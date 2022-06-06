// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import 'codegen_dart.dart';

export 'meta_model_cleaner.dart';
export 'meta_model_reader.dart';

/// Whether this type allows any value (including null).
bool isAnyType(TypeBase t) =>
    t is Type &&
    (t.name == 'any' ||
        t.name == 'LSPAny' ||
        t.name == 'object' ||
        t.name == 'LSPObject');

bool isLiteralType(TypeBase t) => t is LiteralType;

bool isNullType(TypeBase t) => t is Type && t.name == 'null';

bool isUndefinedType(TypeBase t) => t is Type && t.name == 'undefined';

class ArrayType extends TypeBase {
  final TypeBase elementType;

  ArrayType(this.elementType);

  @override
  String get dartType => 'List';
  @override
  String get typeArgsString => '<${elementType.dartTypeWithTypeArgs}>';
}

abstract class AstNode {
  final String name;
  final String? comment;
  final bool isDeprecated;
  AstNode({
    required this.name,
    required this.comment,
  }) : isDeprecated = comment?.contains('@deprecated') ?? false;
}

class Const extends Member with LiteralValueMixin {
  TypeBase type;
  String value;
  Const({
    required super.name,
    super.comment,
    required this.type,
    required this.value,
  });

  String get valueAsLiteral => _asLiteral(value);
}

class Field extends Member {
  final TypeBase type;
  final bool allowsNull;
  final bool allowsUndefined;
  Field({
    required super.name,
    super.comment,
    required this.type,
    required this.allowsNull,
    required this.allowsUndefined,
  });
}

class FixedValueField extends Field {
  final String value;
  FixedValueField({
    required super.name,
    super.comment,
    required this.value,
    required super.type,
    required super.allowsNull,
    required super.allowsUndefined,
  });
}

class Interface extends AstNode {
  final List<String> typeArgs;
  final List<Type> baseTypes;
  final List<Member> members;

  Interface({
    required super.name,
    super.comment,
    this.typeArgs = const [],
    this.baseTypes = const [],
    required this.members,
  }) {
    baseTypes.sortBy((type) => type.dartTypeWithTypeArgs.toLowerCase());
    members.sortBy((member) => member.name.toLowerCase());
  }

  Interface.inline(String name, List<Member> members)
      : this(name: name, members: members);

  String get nameWithTypeArgs => '$name$typeArgsString';

  String get typeArgsString =>
      typeArgs.isNotEmpty ? '<${typeArgs.join(', ')}>' : '';
}

class LiteralType extends TypeBase with LiteralValueMixin {
  final TypeBase type;
  final String _literal;

  LiteralType(this.type, this._literal);

  @override
  String get dartType => type.dartType;

  @override
  String get typeArgsString => type.typeArgsString;

  @override
  String get uniqueTypeIdentifier => '$_literal:${super.uniqueTypeIdentifier}';

  String get valueAsLiteral => _asLiteral(_literal);
}

/// A special class of Union types where the values are all literals of the same
/// type so the Dart field can be the base type rather than an EitherX<>.
class LiteralUnionType extends UnionType {
  final List<LiteralType> literalTypes;

  LiteralUnionType(this.literalTypes) : super(literalTypes);

  @override
  String get dartType => types.first.dartType;

  @override
  String get typeArgsString => types.first.typeArgsString;
}

mixin LiteralValueMixin {
  /// Returns [value] as the literal Dart code required to represent this value.
  String _asLiteral(String value) {
    if (num.tryParse(value) == null) {
      // Add quotes around strings.
      final prefix = value.contains(r'$') ? 'r' : '';
      return "$prefix'$value'";
    } else {
      return value;
    }
  }
}

class LspMetaModel {
  final List<AstNode> types;

  LspMetaModel(this.types);
}

class MapType extends TypeBase {
  final TypeBase indexType;
  final TypeBase valueType;

  MapType(this.indexType, this.valueType);

  @override
  String get dartType => 'Map';

  @override
  String get typeArgsString =>
      '<${indexType.dartTypeWithTypeArgs}, ${valueType.dartTypeWithTypeArgs}>';
}

abstract class Member extends AstNode {
  Member({
    required super.name,
    super.comment,
  });
}

class Namespace extends AstNode {
  final TypeBase typeOfValues;
  final List<Member> members;
  Namespace({
    required super.name,
    super.comment,
    required this.typeOfValues,
    required this.members,
  }) {
    members.sortBy((member) => member.name.toLowerCase());
  }
}

class Type extends TypeBase {
  static final TypeBase Undefined = Type.identifier('undefined');
  static final TypeBase Null_ = Type.identifier('null');
  static final TypeBase Any = Type.identifier('any');
  final String name;
  final List<TypeBase> typeArgs;

  Type(this.name, this.typeArgs) {
    if (name == 'Array' || name.endsWith('[]')) {
      throw 'Type should not be used for arrays, use ArrayType instead';
    }
  }

  Type.identifier(String identifier) : this(identifier, []);

  @override
  String get dartType {
    // Always resolve type aliases when asked for our Dart type.
    final resolvedType = resolveTypeAlias(this);
    if (resolvedType != this) {
      return resolvedType.dartType;
    }

    const mapping = <String, String>{
      'boolean': 'bool',
      'string': 'String',
      'number': 'num',
      'integer': 'int',
      // Map decimal to num because clients may sent "1.0" or "1" and we want
      // to consider both valid.
      'decimal': 'num',
      'uinteger': 'int',
      'any': 'Object?',
      'LSPAny': 'Object?',
      'object': 'Object?',
      'LSPObject': 'Object?',
      // Simplify MarkedString from
      //     string | { language: string; value: string }
      // to just String
      'MarkedString': 'String'
    };

    final typeName = mapping[name] ?? name;
    return typeName;
  }

  @override
  String get typeArgsString {
    // Always resolve type aliases when asked for our Dart type.
    final resolvedType = resolveTypeAlias(this);
    if (resolvedType != this) {
      return resolvedType.typeArgsString;
    }

    return typeArgs.isNotEmpty
        ? '<${typeArgs.map((t) => t.dartTypeWithTypeArgs).join(', ')}>'
        : '';
  }
}

class TypeAlias extends AstNode {
  final TypeBase baseType;
  TypeAlias({
    required super.name,
    super.comment,
    required this.baseType,
  });
}

abstract class TypeBase {
  String get dartType;
  String get dartTypeWithTypeArgs => '$dartType$typeArgsString';
  String get typeArgsString;

  /// A unique identifier for this type. Used for folding types together
  /// (for example two types that resolve to "Object?" in Dart).
  String get uniqueTypeIdentifier => dartTypeWithTypeArgs;
}

class UnionType extends TypeBase {
  final List<TypeBase> types;

  UnionType(this.types) {
    // Ensure types are always sorted alphabetically to simplify sharing code
    // because `Either2<A, B>` and `Either2<B, A>` are not the same.
    types.sortBy((type) => type.dartTypeWithTypeArgs.toLowerCase());
  }

  UnionType.nullable(TypeBase type) : this([type, Type.Null_]);

  @override
  String get dartType {
    if (types.length > 4) {
      throw 'Unions of more than 4 types are not supported.';
    }
    return 'Either${types.length}';
  }

  @override
  String get typeArgsString {
    final typeArgs = types.map((t) => t.dartTypeWithTypeArgs).join(', ');
    return '<$typeArgs>';
  }
}
