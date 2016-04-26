// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// A very simple parser for a subset of DartTypes for use in testing type
// algebra.
library kernel.test.type_parser;

import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';

typedef TreeNode TypeEnvironment(String name);

/// [lookupType] should return a [Class] or [TypeParameter].
DartType parseDartType(String type, TreeNode lookupType(String name)) {
  return new DartTypeParser(type, lookupType).parseType();
}

class Token {
  static const int Eof = 0;
  static const int Name = 1;
  static const int Comma = 2;
  static const int LeftAngle = 3; // '<'
  static const int RightAngle = 4; // '>'
  static const int LeftParen = 5;
  static const int RightParen = 6;
  static const int LeftBracket = 7;
  static const int RightBracket = 8;
  static const int LeftBrace = 9;
  static const int RightBrace = 10;
  static const int Arrow = 11; // '=>'
  static const int Invalid = 100;
}

class DartTypeParser {
  final String string;
  int index = 0;
  String tokenText;
  final TypeEnvironment environment;
  final Map<String, TypeParameter> localTypeParameters =
      <String, TypeParameter>{};

  DartTypeParser(this.string, this.environment);

  TreeNode lookupType(String name) {
    return localTypeParameters[name] ?? environment(name);
  }

  bool isIdentifierChar(int charCode) {
    return 65 <= charCode && charCode <= 90 ||
        97 <= charCode && charCode <= 122 ||
        charCode == 95 || // '_'
        charCode == 36; // '$'
  }

  bool isWhitespaceChar(int charCode) {
    return charCode == 32;
  }

  int next() => string.codeUnitAt(index++);
  int peek() => index < string.length ? string.codeUnitAt(index) : 0;

  void skipWhitespace() {
    while (isWhitespaceChar(peek())) {
      next();
    }
  }

  int scanToken() {
    skipWhitespace();
    if (index >= string.length) return Token.Eof;
    int startIndex = index;
    int x = next();
    if (isIdentifierChar(x)) {
      while (isIdentifierChar(peek())) {
        x = next();
      }
      tokenText = string.substring(startIndex, index);
      return Token.Name;
    } else {
      tokenText = string[index-1];
      int type = getTokenType(x);
      return type;
    }
  }

  int peekToken() {
    skipWhitespace();
    if (index >= string.length) return Token.Eof;
    return getTokenType(peek());
  }

  int getTokenType(int character) {
    switch (character) {
      case 44:
        return Token.Comma;
      case 60:
        return Token.LeftAngle;
      case 62:
        return Token.RightAngle;
      case 40:
        return Token.LeftParen;
      case 41:
        return Token.RightParen;
      case 91:
        return Token.LeftBracket;
      case 92:
        return Token.RightBracket;
      case 123:
        return Token.LeftBrace;
      case 125:
        return Token.RightBrace;
      default:
        if (isIdentifierChar(character)) return Token.Name;
        return Token.Invalid;
    }
  }

  void consumeString(String text) {
    skipWhitespace();
    if (string.startsWith(text, index)) {
      index += text.length;
    } else {
      return fail('Expected token $text');
    }
  }

  DartType parseType() {
    int token = peekToken();
    switch (token) {
      case Token.Name:
        scanToken();
        String name = this.tokenText;
        var target = lookupType(name);
        if (target == null) {
          return fail('Unresolved type $name');
        } else if (target is Class) {
          return new InterfaceType(target, parseOptionalTypeArgumentList());
        } else if (target is TypeParameter) {
          if (peekToken() == Token.LeftAngle) {
            return fail('Attempt to apply type arguments to a type variable');
          }
          return new TypeParameterType(target);
        }
        return fail("Unexpected lookup result for $name: $target");

      case Token.LeftParen:
        // TODO: Support rest of function type features.
        var parameters = parseList(Token.LeftParen, Token.RightParen);
        consumeString('=>');
        var returnType = parseType();
        return new FunctionType(parameters, returnType);

      case Token.LeftAngle:
        var typeParameters =
            parseAndPushTypeParameterList();
        var parameters = parseList(Token.LeftParen, Token.RightParen);
        consumeString('=>');
        var returnType = parseType();
        popTypeParameters(typeParameters);
        return new FunctionType(parameters, returnType,
            typeParameters: typeParameters);

      default:
        return fail('Unexpected token: $tokenText');
    }
  }

  List<DartType> parseList(int open, int close) {
    int token = scanToken();
    assert(token == open);
    List<DartType> types = <DartType>[];
    token = peekToken();
    while (token != close) {
      types.add(parseType());
      token = scanToken();
      if (token == Token.Comma) {
      } else if (token != close) {
        return fail('Unterminated list');
      }
    }
    return types;
  }

  List<DartType> parseOptionalList(int open, int close) {
    if (peekToken() != open) return null;
    return parseList(open, close);
  }

  List<DartType> parseOptionalTypeArgumentList() {
    return parseOptionalList(Token.LeftAngle, Token.RightAngle);
  }

  void popTypeParameters(List<TypeParameter> typeParameters) {
    typeParameters.forEach(localTypeParameters.remove);
  }

  List<TypeParameter> parseAndPushTypeParameterList() {
    int token = scanToken();
    assert(token == Token.LeftAngle);
    List<TypeParameter> typeParameters = <TypeParameter>[];
    token = peekToken();
    while (token != Token.RightAngle) {
      typeParameters.add(parseAndPushTypeParameter());
      token = scanToken();
      if (token == Token.Comma) {
      } else if (token != Token.RightAngle) {
        return fail('Unterminated type parameter list');
      }
    }
    return typeParameters;
  }

  TypeParameter parseAndPushTypeParameter() {
    var nameTok = scanToken();
    if (nameTok != Token.Name) return fail('Expected a name');
    var typeParameter = new TypeParameter(tokenText);
    if (localTypeParameters.containsKey(typeParameter.name)) {
      return fail('Shadowing a type parameter is not allowed');
    }
    localTypeParameters[typeParameter.name] = typeParameter;
    return typeParameter;
  }

  dynamic fail(String message) {
    throw '$message at index $index';
  }
}

class LazyTypeEnvironment {
  final Map<String, TreeNode> environment = <String, TreeNode>{};

  TreeNode lookup(String name) {
    return environment.putIfAbsent(name, () =>
        name.length == 1
            ? new TypeParameter(name)
            : new NormalClass(null, name: name));
  }

  DartType parse(String type) => parseDartType(type, lookup);

  TypeParameter getTypeParameter(String name) {
    if (name.length != 1) throw 'Type parameter names must have length 1';
    return lookup(name);
  }
}

void main(List<String> args) {
  if (args.length != 1) {
    print('Usage: type_parser TYPE');
  }
  var environment = new LazyTypeEnvironment();
  var type = parseDartType(args[0], environment.lookup);
  var buffer = new StringBuffer();
  new Printer(buffer).writeType(type);
  print(buffer);
}
