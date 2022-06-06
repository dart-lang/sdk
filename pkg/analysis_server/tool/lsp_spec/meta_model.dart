// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import 'codegen_dart.dart';

export 'meta_model_cleaner.dart';
export 'meta_model_reader.dart';

/// A fabricated field name for indexers in case they result in generation
/// of type names for inline types.
const fieldNameForIndexer = 'indexer';

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

TypeBase typeOfLiteral(Token token) {
  final tokenType = token.type;
  final typeName = tokenType == TokenType.STRING
      ? 'string'
      : tokenType == TokenType.NUMBER
          ? 'int' // all literal numeric values in LSP spec are ints
          : throw 'Unknown literal type $tokenType';
  return Type.identifier(typeName);
}

class ArrayType extends TypeBase {
  final TypeBase elementType;

  ArrayType(this.elementType);

  @override
  String get dartType => 'List';
  @override
  String get typeArgsString => '<${elementType.dartTypeWithTypeArgs}>';
}

abstract class AstNode {
  final Comment? commentNode;
  final bool isDeprecated;
  AstNode(this.commentNode)
      : isDeprecated = commentNode?.text.contains('@deprecated') ?? false;
  String? get commentText => commentNode?.text;

  String get name;
}

class Comment extends AstNode {
  final Token token;
  final String text;

  Comment(this.token)
      : text = token.lexeme,
        super(null);

  @override
  String get name => throw UnsupportedError('Comments do not have a name.');
}

class Const extends Member with LiteralValueMixin {
  Token nameToken;
  TypeBase type;
  Token valueToken;
  Const(super.comment, this.nameToken, this.type, this.valueToken);

  @override
  String get name => nameToken.lexeme;

  String get valueAsLiteral => _asLiteral(valueToken.lexeme);
}

class Field extends Member {
  final Token nameToken;
  final TypeBase type;
  final bool allowsNull;
  final bool allowsUndefined;
  Field(
    super.comment,
    this.nameToken,
    this.type, {
    required this.allowsNull,
    required this.allowsUndefined,
  });

  @override
  String get name => nameToken.lexeme;
}

class FixedValueField extends Field {
  final Token valueToken;
  FixedValueField(
    Comment? comment,
    Token nameToken,
    this.valueToken,
    TypeBase type,
    bool allowsNull,
    bool allowsUndefined,
  ) : super(comment, nameToken, type,
            allowsNull: allowsNull, allowsUndefined: allowsUndefined);
}

class Interface extends AstNode {
  final Token nameToken;
  final List<Token> typeArgs;
  final List<Type> baseTypes;
  final List<Member> members;

  Interface(
    super.comment,
    this.nameToken,
    this.typeArgs,
    this.baseTypes,
    this.members,
  ) {
    baseTypes.sortBy((type) => type.dartTypeWithTypeArgs.toLowerCase());
    members.sortBy((member) => member.name.toLowerCase());
  }

  Interface.inline(String name, List<Member> members)
      : this(null, Token.identifier(name), [], [], members);

  @override
  String get name => nameToken.lexeme;
  String get nameWithTypeArgs => '$name$typeArgsString';

  String get typeArgsString => typeArgs.isNotEmpty
      ? '<${typeArgs.map((t) => t.lexeme).join(', ')}>'
      : '';
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
  Member(super.comment);
}

class Namespace extends AstNode {
  final Token nameToken;
  final TypeBase typeOfValues;
  final List<Member> members;
  Namespace(
    super.comment,
    this.nameToken,
    this.typeOfValues,
    this.members,
  ) {
    members.sortBy((member) => member.name.toLowerCase());
  }

  @override
  String get name => nameToken.lexeme;
}

class Token {
  static final Token EOF = Token(TokenType.EOF, '');

  final TokenType type;
  final String lexeme;

  Token(this.type, this.lexeme);

  Token.identifier(String identifier) : this(TokenType.IDENTIFIER, identifier);

  @override
  String toString() => '${type.toString().padRight(25)} '
      '${lexeme.padRight(10)}\n';
}

enum TokenType {
  AMPERSAND,
  CLASS_KEYWORD,
  COLON,
  COMMA,
  COMMENT,
  CONST_KEYWORD,
  DOT,
  ENUM_KEYWORD,
  EOF,
  EQUAL,
  EXPORT_KEYWORD,
  EXTENDS_KEYWORD,
  GREATER_EQUAL,
  GREATER,
  IDENTIFIER,
  INTERFACE_KEYWORD,
  LEFT_BRACE,
  LEFT_BRACKET,
  LEFT_PAREN,
  LESS_EQUAL,
  LESS,
  NAMESPACE_KEYWORD,
  NUMBER,
  PIPE,
  QUESTION,
  READONLY_KEYWORD,
  RIGHT_BRACE,
  RIGHT_BRACKET,
  RIGHT_PAREN,
  SEMI_COLON,
  SLASH,
  STAR,
  STRING,
}

class Type extends TypeBase {
  static final TypeBase Undefined = Type.identifier('undefined');
  static final TypeBase Null_ = Type.identifier('null');
  static final TypeBase Any = Type.identifier('any');
  final Token nameToken;
  final List<TypeBase> typeArgs;

  Type(this.nameToken, this.typeArgs) {
    if (name == 'Array' || name.endsWith('[]')) {
      throw 'Type should not be used for arrays, use ArrayType instead';
    }
  }

  Type.identifier(String identifier) : this(Token.identifier(identifier), []);

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

  String get name => nameToken.lexeme;

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
  final Token nameToken;
  final TypeBase baseType;
  TypeAlias(
    super.comment,
    this.nameToken,
    this.baseType,
  );

  @override
  String get name => nameToken.lexeme;
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
