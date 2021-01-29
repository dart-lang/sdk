// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analysis_server/src/utilities/strings.dart' show capitalize;

import 'codegen_dart.dart';
import 'typescript.dart';

/// A fabricated field name for indexers in case they result in generation
/// of type names for inline types.
const fieldNameForIndexer = 'indexer';

final _keywords = const <String, TokenType>{
  'class': TokenType.CLASS_KEYWORD,
  'const': TokenType.CONST_KEYWORD,
  'enum': TokenType.ENUM_KEYWORD,
  'export': TokenType.EXPORT_KEYWORD,
  'extends': TokenType.EXTENDS_KEYWORD,
  'interface': TokenType.INTERFACE_KEYWORD,
  'namespace': TokenType.NAMESPACE_KEYWORD,
  'readonly': TokenType.READONLY_KEYWORD,
};

final _validIdentifierCharacters = RegExp('[a-zA-Z0-9_]');

bool isAnyType(TypeBase t) =>
    t is Type && (t.name == 'any' || t.name == 'object');

bool isLiteralType(TypeBase t) => t is LiteralType;

bool isNullType(TypeBase t) => t is Type && t.name == 'null';

bool isUndefinedType(TypeBase t) => t is Type && t.name == 'undefined';

List<AstNode> parseString(String input) {
  final scanner = Scanner(input);
  final tokens = scanner.scan();
  final parser = Parser(tokens);
  return parser.parse();
}

TypeBase typeOfLiteral(TokenType tokenType) {
  final typeName = tokenType == TokenType.STRING
      ? 'string'
      : tokenType == TokenType.NUMBER
          ? 'number'
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

class AstNode {
  final Comment commentNode;
  final bool isDeprecated;
  AstNode(this.commentNode)
      : isDeprecated = commentNode?.text?.contains('@deprecated') ?? false;
  String get commentText => commentNode?.text;

  String get name => null;
}

class Comment extends AstNode {
  final Token token;
  final String text;

  Comment(this.token)
      : text = cleanComment(token.lexeme),
        super(null);
}

class Const extends Member {
  Token nameToken;
  TypeBase type;
  Token valueToken;
  Const(Comment comment, this.nameToken, this.type, this.valueToken)
      : super(comment);

  @override
  String get name => nameToken.lexeme;

  String get valueAsLiteral {
    if (type.dartType == 'String') {
      // Write strings as raw strings, since some have dollars in them (eg. for
      // LSP method names). valueToken.lexeme already includes the quotes as
      // read from the spec.
      return 'r${valueToken.lexeme}';
    } else {
      return valueToken.lexeme;
    }
  }
}

class Field extends Member {
  final Token nameToken;
  final TypeBase type;
  final bool allowsNull;
  final bool allowsUndefined;
  Field(
    Comment comment,
    this.nameToken,
    this.type,
    this.allowsNull,
    this.allowsUndefined,
  ) : super(comment);

  @override
  String get name => nameToken.lexeme;
}

class FixedValueField extends Field {
  final Token valueToken;
  FixedValueField(
    Comment comment,
    Token nameToken,
    this.valueToken,
    TypeBase type,
    bool allowsNull,
    bool allowsUndefined,
  ) : super(comment, nameToken, type, allowsNull, allowsUndefined);
}

class Indexer extends Member {
  final TypeBase indexType;
  final TypeBase valueType;
  Indexer(
    Comment comment,
    this.indexType,
    this.valueType,
  ) : super(comment);

  @override
  String get name => fieldNameForIndexer;
}

class InlineInterface extends Interface {
  InlineInterface(
    String name,
    List<Member> members,
  ) : super(null, Token.identifier(name), [], [], members);
}

class Interface extends AstNode {
  final Token nameToken;
  final List<Token> typeArgs;
  final List<TypeBase> baseTypes;
  final List<Member> members;

  Interface(
    Comment comment,
    this.nameToken,
    this.typeArgs,
    this.baseTypes,
    this.members,
  ) : super(comment);

  @override
  String get name => nameToken.lexeme;
  String get nameWithTypeArgs => '$name$typeArgsString';

  String get typeArgsString => typeArgs.isNotEmpty
      ? '<${typeArgs.map((t) => t.lexeme).join(', ')}>'
      : '';
}

class LiteralType extends TypeBase {
  final Type type;
  final String literal;

  LiteralType(this.type, this.literal);

  @override
  String get dartType => type.dartType;

  @override
  String get typeArgsString => type.typeArgsString;

  @override
  String get uniqueTypeIdentifier => '$literal:${super.uniqueTypeIdentifier}';
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

class Member extends AstNode {
  Member(Comment comment) : super(comment);
}

class Namespace extends AstNode {
  final Token nameToken;
  final List<Member> members;
  Namespace(
    Comment comment,
    this.nameToken,
    this.members,
  ) : super(comment);

  @override
  String get name => nameToken.lexeme;
}

class Parser {
  final List<Token> _tokens;
  int _current = 0;
  List<AstNode> _nodes;
  Parser(this._tokens);

  bool get _isAtEnd => _peek().type == TokenType.EOF;

  List<AstNode> parse() {
    if (_nodes == null) {
      _nodes = <AstNode>[];
      while (!_isAtEnd) {
        _nodes.add(_topLevel());
      }
    }
    return _nodes;
  }

  /// Returns the current token and moves to the next.
  Token _advance() => _tokenAt(_current++);

  /// Checks if the next token is [type] without advancing.
  bool _check(TokenType type) => !_isAtEnd && _peek().type == type;

  Comment _comment() {
    if (_peek().type != TokenType.COMMENT) {
      return null;
    }
    return Comment(_advance());
  }

  Const _const(String containerName, Comment leadingComment) {
    _eatUnwantedKeywords();
    final name = _consume(TokenType.IDENTIFIER, 'Expected identifier');
    TypeBase type;
    if (_match([TokenType.COLON])) {
      type = _type(containerName, name.lexeme);
    }
    final value = _match([TokenType.EQUAL]) ? _advance() : null;

    if (type == null && value != null) {
      type = typeOfLiteral(value.type);
    }

    _consume(TokenType.SEMI_COLON, 'Expected ;');
    return Const(leadingComment, name, type, value);
  }

  /// Ensures the next token is [type] and moves to the next, throwing [message]
  /// if not.
  Token _consume(TokenType type, String message) {
    // Skip over any inline comments when looking for a specific token.
    _match([TokenType.COMMENT]);

    if (_check(type)) {
      return _advance();
    }

    // The scanner currently reads keywords with specific token types
    // (eg. TokenType.NAMESPACE_KEYWORD) however v3.16 of the LSP spec also uses
    // some of these words as identifiers. If the requested type is an identifier
    // but we have a keyword token, then treat it as an identifier.
    if (type == TokenType.IDENTIFIER) {
      final next = !_isAtEnd ? _peek() : null;
      if (_isKeyword(next?.type)) {
        _advance();
        return Token(TokenType.IDENTIFIER, next.lexeme);
      }
    }

    throw '$message\n\n${_peek()}';
  }

  void _eatUnwantedKeywords() {
    _match([TokenType.EXPORT_KEYWORD]);
    _match([TokenType.READONLY_KEYWORD]);
  }

  Namespace _enum(Comment leadingComment) {
    final name = _consume(TokenType.IDENTIFIER, 'Expected identifier');
    _consume(TokenType.LEFT_BRACE, 'Expected {');
    final consts = <Const>[];
    while (!_check(TokenType.RIGHT_BRACE)) {
      consts.add(_enumValue(name.lexeme));
      // Commas might not be present (eg. for last one).
      _match([TokenType.COMMA]);
    }
    _consume(TokenType.RIGHT_BRACE, 'Expected }');

    return Namespace(leadingComment, name, consts);
  }

  Const _enumValue(String enumName) {
    final leadingComment = _comment();
    final name = _consume(TokenType.IDENTIFIER, 'Expected identifier');
    TypeBase type;
    if (_match([TokenType.COLON])) {
      type = _type(enumName, name.lexeme);
    }
    final value = _match([TokenType.EQUAL]) ? _advance() : null;

    if (type == null && value != null) {
      type = typeOfLiteral(value.type);
    }
    return Const(leadingComment, name, type, value);
  }

  Field _field(String containerName, Comment leadingComment) {
    _eatUnwantedKeywords();
    final name = _consume(TokenType.IDENTIFIER, 'Expected identifier');
    var canBeUndefined = _match([TokenType.QUESTION]);
    _consume(TokenType.COLON, 'Expected :');
    TypeBase type;
    Token value;
    type = _type(containerName, name.lexeme,
        includeUndefined: canBeUndefined, improveTypes: true);

    // Overwrite comment if we have an improved one.
    final improvedComment = getImprovedComment(containerName, name.lexeme);
    leadingComment = improvedComment != null
        ? Comment(Token(TokenType.COMMENT, improvedComment))
        : leadingComment;

    // Some fields have weird comments like this in the spec:
    //     {@link MessageType}
    // These seem to be the correct type of the field, while the field is
    // marked with number.
    final commentText = leadingComment?.text;
    if (commentText != null) {
      final _linkTypePattern = RegExp(r'See \{@link (\w+)\}\.?');
      final linkTypeMatch = _linkTypePattern.firstMatch(commentText);
      if (linkTypeMatch != null) {
        type = Type.identifier(linkTypeMatch.group(1));
        leadingComment = Comment(Token(TokenType.COMMENT,
            '// ' + commentText.replaceAll(_linkTypePattern, '')));
      }
    }

    // Ideally this would be _consume(), but there are no semi-colons after the
    // "inline types" since they're blocks.
    _match([TokenType.SEMI_COLON]);

    // Special handling for fields that have fixed values.
    if (value != null) {
      return FixedValueField(
          leadingComment, name, value, type, false, canBeUndefined);
    }

    var canBeNull = false;
    if (type is UnionType) {
      UnionType union = type;
      // Since undefined and null can appear in the union type list but we want to
      // handle it specially in the code generation, we promote them to fields on
      // the Field.
      canBeUndefined |= union.types.any(isUndefinedType);
      canBeNull = union.types.any((t) => isNullType(t) || isAnyType(t));
      // Finally, we need to remove them from the union.
      final remainingTypes = union.types
          .where((t) => !isNullType(t) && !isUndefinedType(t))
          .toList();

      // We also remove any types that are deprecated and/or we won't use to
      // simplify the unions.
      remainingTypes.removeWhere((t) => !allowTypeInSignatures(t));

      type = _simplifyUnionTypes(remainingTypes);
    } else if (isAnyType(type)) {
      // There are values in the spec marked as `any` that allow nulls (for
      // example, the result field on ResponseMessage can be null for a
      // successful response that has no return value, eg. shutdown).
      canBeNull = true;
    }
    return Field(leadingComment, name, type, canBeNull, canBeUndefined);
  }

  Indexer _indexer(String containerName, Comment leadingComment) {
    final indexer = _field(containerName, leadingComment);
    _consume(TokenType.RIGHT_BRACKET, 'Expected ]');
    _consume(TokenType.COLON, 'Expected :');

    TypeBase type;
    type = _type(containerName, fieldNameForIndexer, improveTypes: true);

    //_consume(TokenType.RIGHT_BRACE, 'Expected }');
    _match([TokenType.SEMI_COLON]);

    return Indexer(leadingComment, indexer.type, type);
  }

  Interface _interface(Comment leadingComment) {
    final name = _consume(TokenType.IDENTIFIER, 'Expected identifier');
    final typeArgs = <Token>[];
    if (_match([TokenType.LESS])) {
      while (true) {
        typeArgs.add(_consume(TokenType.IDENTIFIER, 'Expected identifier'));
        if (_check(TokenType.GREATER)) {
          break;
        }
        _consume(TokenType.COMMA, 'Expected , or >');
      }
      _consume(TokenType.GREATER, 'Expected >');
    }
    final baseTypes = <TypeBase>[];
    if (_match([TokenType.EXTENDS_KEYWORD])) {
      while (true) {
        baseTypes.add(_type(name.lexeme, null));
        if (_check(TokenType.LEFT_BRACE)) {
          break;
        }
        _consume(TokenType.COMMA, 'Expected , or {');
      }
    }
    _consume(TokenType.LEFT_BRACE, 'Expected {');
    final members = <Member>[];
    while (!_check(TokenType.RIGHT_BRACE)) {
      members.add(_member(name.lexeme));
    }

    _consume(TokenType.RIGHT_BRACE, 'Expected }');

    return Interface(leadingComment, name, typeArgs, baseTypes, members);
  }

  bool _isKeyword(TokenType type) => _keywords.values.contains(type);

  String _joinNames(String parent, String child) {
    return '$parent${capitalize(child)}';
  }

  /// Returns [true] an advances if the next token is one of [types], otherwise
  /// returns [false].
  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }

    return false;
  }

  Member _member(String containerName) {
    final leadingComment = _comment();
    _eatUnwantedKeywords();

    if (_match([TokenType.CONST_KEYWORD])) {
      return _const(containerName, leadingComment);
    } else if (_match([TokenType.LEFT_BRACKET])) {
      return _indexer(containerName, leadingComment);
    } else {
      return _field(containerName, leadingComment);
    }
  }

  Namespace _namespace(Comment leadingComment) {
    final name = _consume(TokenType.IDENTIFIER, 'Expected identifier');
    _consume(TokenType.LEFT_BRACE, 'Expected {');
    final members = <Member>[];
    while (!_check(TokenType.RIGHT_BRACE)) {
      members.add(_member(name.lexeme));
    }
    _consume(TokenType.RIGHT_BRACE, 'Expected }');

    return Namespace(leadingComment, name, members);
  }

  /// Returns the next token without advancing.
  Token _peek() => _tokenAt(_current);

  /// Remove any duplicate types (for ex. if we map multiple types into dynamic)
  /// we don't want to end up with `dynamic | dynamic`. Key on dartType to
  /// ensure we different types that will map down to the same type.
  TypeBase _simplifyUnionTypes(List<TypeBase> types) {
    final uniqueTypes = Map.fromEntries(
      types.map((t) => MapEntry(t.uniqueTypeIdentifier, t)),
    ).values.toList();

    // If our list includes something that maps to dynamic as well as other
    // types, we should just treat the whole thing as dynamic as we get no value
    // typing Either4<bool, String, num, dynamic> but it becomes much more
    // difficult to use.
    if (uniqueTypes.any(isAnyType)) {
      return uniqueTypes.firstWhere(isAnyType);
    }

    return uniqueTypes.length == 1
        ? uniqueTypes.single
        : uniqueTypes.every(isLiteralType)
            ? LiteralUnionType(uniqueTypes.cast<LiteralType>())
            : UnionType(uniqueTypes);
  }

  Token _tokenAt(int index) =>
      index < _tokens.length ? _tokens[index] : Token.EOF;

  AstNode _topLevel() {
    final leadingComment = _comment();
    _match([TokenType.EXPORT_KEYWORD]);

    final token = _peek();
    if (_match([TokenType.NAMESPACE_KEYWORD])) {
      return _namespace(leadingComment);
    } else if (_match([TokenType.INTERFACE_KEYWORD])) {
      return _interface(leadingComment);
    } else if (_match([TokenType.CLASS_KEYWORD])) {
      // Classes are the same as interfaces in this spec.
      return _interface(leadingComment);
    } else if (_match([TokenType.ENUM_KEYWORD])) {
      return _enum(leadingComment);
    } else if (token.type == TokenType.IDENTIFIER && token.lexeme == 'type') {
      // TODO(dantup): This is a hack... We don't have a TYPE_KEYWORD because
      // the spec has `type` as an identifier.
      _advance(); // Eat the 'type' keyword.
      return _typeAlias(leadingComment);
    } else {
      throw 'Unexpected token ${_peek()}';
    }
  }

  TypeBase _type(
    String containerName,
    String fieldName, {
    bool includeUndefined = false,
    bool improveTypes = false,
  }) {
    var types = <TypeBase>[];
    if (includeUndefined) {
      types.add(Type.Undefined);
    }
    var typeIndex = 0;
    while (true) {
      typeIndex++;
      TypeBase type;
      if (_match([TokenType.LEFT_BRACE])) {
        // Inline interfaces.
        final members = <Member>[];
        while (!_check(TokenType.RIGHT_BRACE)) {
          members.add(_member(containerName));
        }

        _consume(TokenType.RIGHT_BRACE, 'Expected }');
        // Some of the inline interfaces have trailing commas (and some do not!)
        _match([TokenType.COMMA]);

        // If we have a single member that is an indexer type, we can use a Map.
        if (members.length == 1 && members.single is Indexer) {
          Indexer indexer = members.single;
          type = MapType(indexer.indexType, indexer.valueType);
        } else {
          // Add a synthetic interface to the parsers list of nodes to represent this type.
          // If we have no fieldName to base the synthetic name from, we should use
          // the index of this type, for example in:
          //    type Foo = { [..] } | { [...] }
          // we will generate Foo1 and Foo2 for the types.
          final nameSuffix = fieldName ?? '$typeIndex';
          final generatedName = _joinNames(containerName, nameSuffix);
          _nodes.add(InlineInterface(generatedName, members));
          // Record the type as a simple type that references this interface.
          type = Type.identifier(generatedName);
        }
      } else if (_match([TokenType.LEFT_PAREN])) {
        // Some types are in (parens), so we just parse the contents as a nested type.
        type = _type(containerName, fieldName);
        _consume(TokenType.RIGHT_PAREN, 'Expected )');
      } else if (_check(TokenType.STRING)) {
        final token = _advance();
        // In TS and the spec, literal strings can be types:
        // export const PlainText: 'plaintext' = 'plaintext';
        // trace?: 'off' | 'messages' | 'verbose';
        type = LiteralType(Type.identifier('string'), token.lexeme);
      } else if (_check(TokenType.NUMBER)) {
        final token = _advance();
        // In TS and the spec, literal numbers can be types:
        // export const Invoked: 1 = 1;
        type = LiteralType(Type.identifier('number'), token.lexeme);
      } else if (_match([TokenType.LEFT_BRACKET])) {
        // Tuples will just be converted to List/Array.
        final tupleElementTypes = <TypeBase>[];
        while (!_check(TokenType.RIGHT_BRACKET)) {
          tupleElementTypes.add(_type(containerName, fieldName));
          // Remove commas in between.
          _match([TokenType.COMMA]);
        }
        _consume(TokenType.RIGHT_BRACKET, 'Expected ]');

        var tupleType = _simplifyUnionTypes(tupleElementTypes);
        type = ArrayType(tupleType);
      } else {
        var typeName = _consume(TokenType.IDENTIFIER, 'Expected identifier');
        final typeArgs = <Type>[];
        if (_match([TokenType.LESS])) {
          while (true) {
            typeArgs.add(_type(containerName, fieldName));
            if (_peek().type != TokenType.COMMA) {
              _consume(TokenType.GREATER, 'Expected >');
              break;
            }
          }
        }

        type = typeName.lexeme == 'Array'
            ? ArrayType(typeArgs.single)
            : Type(typeName, typeArgs);
      }
      if (_match([TokenType.LEFT_BRACKET])) {
        _consume(TokenType.RIGHT_BRACKET, 'Expected ]');
        type = ArrayType(type);
      }
      // TODO(dantup): Handle types like This & That.
      // For now, map to any.
      if (_match([TokenType.AMPERSAND])) {
        while (true) {
          // Eat as many types/ampersands as we have.
          _type(containerName, fieldName);
          if (!_check(TokenType.AMPERSAND)) {
            break;
          }
        }
        type = Type.Any;
      }

      types.add(type);

      if (!_match([TokenType.PIPE])) {
        break;
      }
    }

    var type = _simplifyUnionTypes(types);

    // Handle improved type mappings for things that aren't very tight in the spec.
    if (improveTypes) {
      final improvedTypeName = getImprovedType(containerName, fieldName);
      if (improvedTypeName != null) {
        type = Type.identifier(improvedTypeName);
      }
    }
    return type;
  }

  TypeAlias _typeAlias(Comment leadingComment) {
    final name = _consume(TokenType.IDENTIFIER, 'Expected identifier');
    _consume(TokenType.EQUAL, 'Expected =');
    final type = _type(name.lexeme, null);
    if (!_isAtEnd) {
      _consume(TokenType.SEMI_COLON, 'Expected ;');
    }

    return TypeAlias(leadingComment, name, type);
  }
}

class Scanner {
  final String _source;
  int _startOfToken = 0;
  int _currentPos = 0;
  final _tokens = <Token>[];
  Scanner(this._source);

  bool get _isAtEnd => _currentPos >= _source.length;
  bool get _isNextAtEnd => _currentPos + 1 >= _source.length;

  List<Token> scan() {
    while (!_isAtEnd) {
      _startOfToken = _currentPos;
      _scanToken();
    }
    return _tokens;
  }

  void _addToken(TokenType type, {bool mergeSameTypes = false}) {
    var text = _source.substring(_startOfToken, _currentPos);

    // Consecutive tokens of some types (for example Comments) are merged
    // together.
    if (mergeSameTypes && _tokens.isNotEmpty && type == _tokens.last.type) {
      text = '${_tokens.last.lexeme}\n$text';
      _tokens.removeLast();
    }

    _tokens.add(Token(type, text));
  }

  String _advance() => _currentPos < _source.length
      ? _source[_currentPos++]
      : throw 'Cannot advance past end of source';

  void _identifier() {
    while (_isAlpha(_peek())) {
      _advance();
    }

    final string = _source.substring(_startOfToken, _currentPos);
    if (_keywords.containsKey(string)) {
      _addToken(_keywords[string]);
    } else {
      _addToken(TokenType.IDENTIFIER);
    }
  }

  bool _isAlpha(String s) => _validIdentifierCharacters.hasMatch(s);

  bool _isDigit(String s) => s != null && (s.codeUnitAt(0) ^ 0x30) <= 9;

  bool _match(String expected) {
    if (_isAtEnd || _source[_currentPos] != expected) {
      return false;
    }
    _currentPos++;
    return true;
  }

  void _number() {
    // Optionally process a negative.
    _match('-');
    while (_isDigit(_peek())) {
      _advance();
    }

    // Handle fractional parts.
    if (_peek() == '.' && _isDigit(_peekNext())) {
      // Consume the decimal point.
      _advance();

      while (_isDigit(_peek())) {
        _advance();
      }
    }

    _addToken(TokenType.NUMBER);
  }

  String _peek() => _isAtEnd ? null : _source[_currentPos];

  String _peekNext() => _isNextAtEnd ? null : _source[_currentPos + 1];

  void _scanToken() {
    const singleCharTokens = <String, TokenType>{
      ',': TokenType.COMMA,
      ';': TokenType.SEMI_COLON,
      ':': TokenType.COLON,
      '?': TokenType.QUESTION,
      '.': TokenType.DOT,
      '(': TokenType.LEFT_PAREN,
      ')': TokenType.RIGHT_PAREN,
      '[': TokenType.LEFT_BRACKET,
      ']': TokenType.RIGHT_BRACKET,
      '{': TokenType.LEFT_BRACE,
      '}': TokenType.RIGHT_BRACE,
      '*': TokenType.STAR,
      '&': TokenType.AMPERSAND,
      '=': TokenType.EQUAL,
      '|': TokenType.PIPE,
    };

    final c = _advance();
    if (singleCharTokens.containsKey(c)) {
      _addToken(singleCharTokens[c]);
      return;
    }
    switch (c) {
      case '/':
        if (_match('*')) {
          // Block comment.
          while (!_isAtEnd && (_peek() != '*' || _peekNext() != '/')) {
            _advance();
          }
          // Eat the closing comment markers detected above.
          if (!_isAtEnd) {
            _advance();
            _advance();
          }
          _addToken(TokenType.COMMENT, mergeSameTypes: true);
        } else if (_match('/')) {
          // Single line comment.
          while (_peek() != '\n' && !_isAtEnd) {
            _advance();
          }
          _addToken(TokenType.COMMENT, mergeSameTypes: true);
        } else {
          _addToken(TokenType.SLASH);
        }
        break;
      case '<':
        _addToken(_match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);
        break;
      case '>':
        _addToken(_match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);
        break;
      case ' ':
      case '\r':
      case '\n':
      case '\t':
        // Whitespace.
        break;
      case '"':
      case "'":
        _string(c);
        break;
      default:
        if (_isDigit(c) || c == '-' && _isDigit(_peek())) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          final start = max(0, _currentPos - 20);
          final end = min(_currentPos + 20, _source.length);
          final snippet = _source.substring(start, end);
          throw "Unexpected character '$c'.\n\n$snippet";
        }
        break;
    }
  }

  void _string(String terminator) {
    // TODO(dantup): Handle escape sequences, inc. quotes.
    while (!_isAtEnd && _peek() != terminator) {
      _advance();

      if (_isAtEnd) {
        throw 'Unterminated string.';
      }
    }

    // Skip over the closing terminator.
    _advance();

    _addToken(TokenType.STRING);
  }
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
      'any': 'dynamic',
      'object': 'dynamic',
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
    Comment comment,
    this.nameToken,
    this.baseType,
  ) : super(comment);

  @override
  String get name => nameToken.lexeme;
}

abstract class TypeBase {
  String get dartType;
  String get dartTypeWithTypeArgs => '$dartType$typeArgsString';
  String get typeArgsString;

  /// A unique identifier for this type. Used for folding types together
  /// (for example two types that resolve to "dynamic" in Dart).
  String get uniqueTypeIdentifier => dartTypeWithTypeArgs;
}

class UnionType extends TypeBase {
  final List<TypeBase> types;

  UnionType(this.types);

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
