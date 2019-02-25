// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:front_end/src/fasta/scanner.dart" show scanString, Token;

import "package:front_end/src/fasta/parser/type_info_impl.dart"
    show splitCloser;

abstract class ParsedType {
  R accept<R, A>(Visitor<R, A> visitor, [A a]);
}

class ParsedInterfaceType extends ParsedType {
  final String name;

  final List<ParsedType> arguments;

  ParsedInterfaceType(this.name, this.arguments);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(name);
    if (arguments.isNotEmpty) {
      sb.write("<");
      sb.writeAll(arguments, ", ");
      sb.write(">");
    }
    return "$sb";
  }

  R accept<R, A>(Visitor<R, A> visitor, [A a]) {
    return visitor.visitInterfaceType(this, a);
  }
}

abstract class ParsedDeclaration extends ParsedType {
  final String name;

  ParsedDeclaration(this.name);
}

class ParsedClass extends ParsedDeclaration {
  final List<ParsedTypeVariable> typeVariables;
  final ParsedInterfaceType supertype;
  final ParsedInterfaceType mixedInType;
  final List<ParsedType> interfaces;
  final ParsedFunctionType callableType;

  ParsedClass(String name, this.typeVariables, this.supertype, this.mixedInType,
      this.interfaces, this.callableType)
      : super(name);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("class ");
    sb.write(name);
    if (typeVariables.isNotEmpty) {
      sb.write("<");
      sb.writeAll(typeVariables, ", ");
      sb.write(">");
    }
    if (supertype != null) {
      sb.write(" extends ");
      sb.write(supertype);
    }
    if (interfaces.isNotEmpty) {
      sb.write(" implements ");
      sb.writeAll(interfaces, ", ");
    }
    if (callableType != null) {
      sb.write("{\n  ");
      sb.write(callableType);
      sb.write("\n}");
    } else {
      sb.write(";");
    }
    return "$sb";
  }

  R accept<R, A>(Visitor<R, A> visitor, [A a]) {
    return visitor.visitClass(this, a);
  }
}

class ParsedTypedef extends ParsedDeclaration {
  final List<ParsedTypeVariable> typeVariables;

  final ParsedType type;

  ParsedTypedef(String name, this.typeVariables, this.type) : super(name);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("typedef ");
    sb.write(name);
    if (typeVariables.isNotEmpty) {
      sb.write("<");
      sb.writeAll(typeVariables, ", ");
      sb.write(">");
    }
    sb.write(" ");
    sb.write(type);
    return "$sb;";
  }

  R accept<R, A>(Visitor<R, A> visitor, [A a]) {
    return visitor.visitTypedef(this, a);
  }
}

class ParsedFunctionType extends ParsedType {
  final List<ParsedTypeVariable> typeVariables;

  final ParsedType returnType;

  final ParsedArguments arguments;

  ParsedFunctionType(this.typeVariables, this.returnType, this.arguments);

  String toString() {
    StringBuffer sb = new StringBuffer();
    if (typeVariables.isNotEmpty) {
      sb.write("<");
      sb.writeAll(typeVariables, ", ");
      sb.write(">");
    }
    sb.write(arguments);
    sb.write(" -> ");
    sb.write(returnType);
    return "$sb";
  }

  R accept<R, A>(Visitor<R, A> visitor, [A a]) {
    return visitor.visitFunctionType(this, a);
  }
}

class ParsedVoidType extends ParsedType {
  String toString() => "void";

  R accept<R, A>(Visitor<R, A> visitor, [A a]) {
    return visitor.visitVoidType(this, a);
  }
}

class ParsedTypeVariable extends ParsedType {
  final String name;

  final ParsedType bound;

  ParsedTypeVariable(this.name, this.bound);

  String toString() {
    if (bound == null) return name;
    StringBuffer sb = new StringBuffer();
    sb.write(name);
    sb.write(" extends ");
    sb.write(bound);
    return "$sb";
  }

  R accept<R, A>(Visitor<R, A> visitor, [A a]) {
    return visitor.visitTypeVariable(this, a);
  }
}

class ParsedIntersectionType extends ParsedType {
  final ParsedType a;

  final ParsedType b;

  ParsedIntersectionType(this.a, this.b);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(a);
    sb.write(" & ");
    sb.write(b);
    return "$sb";
  }

  R accept<R, A>(Visitor<R, A> visitor, [A a]) {
    return visitor.visitIntersectionType(this, a);
  }
}

class ParsedArguments {
  final List<ParsedType> required;
  final List optional;
  final bool optionalAreNamed;

  ParsedArguments(this.required, this.optional, this.optionalAreNamed);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("(");
    sb.writeAll(required, ", ");
    if (optional.isNotEmpty) {
      if (required.isNotEmpty) {
        sb.write(", ");
      }
      if (optionalAreNamed) {
        sb.write("{");
        for (int i = 0; i < optional.length; i += 2) {
          if (i != 0) {
            sb.write(", ");
          }
          sb.write(optional[i]);
          sb.write(" ");
          sb.write(optional[i + 1]);
        }
        sb.write("}");
      } else {
        sb.write("[");
        sb.writeAll(optional, ", ");
        sb.write("]");
      }
    }
    sb.write(")");
    return "$sb";
  }
}

class Parser {
  Token peek;

  String source;

  Parser(this.peek, this.source);

  bool get atEof => peek.isEof;

  void advance() {
    peek = peek.next;
  }

  String computeLocation() {
    return "${source.substring(0, peek.charOffset)}\n>>>"
        "\n${source.substring(peek.charOffset)}";
  }

  void expect(String string) {
    if (!identical(string, peek.stringValue)) {
      throw "Expected '$string', but got '${peek.lexeme}'\n${computeLocation()}";
    }
    advance();
  }

  bool optional(String value) {
    return identical(value, peek.stringValue);
  }

  bool optionalAdvance(String value) {
    if (optional(value)) {
      advance();
      return true;
    } else {
      return false;
    }
  }

  ParsedType parseType() {
    if (optional("class")) return parseClass();
    if (optional("typedef")) return parseTypedef();
    ParsedType result;
    do {
      ParsedType type;
      if (optional("(") || optional("<")) {
        type = parseFunctionType();
      } else if (optionalAdvance("void")) {
        type = new ParsedInterfaceType("void", <ParsedType>[]);
      } else {
        String name = parseName();
        List<ParsedType> arguments = <ParsedType>[];
        if (optional("<")) {
          advance();
          arguments.add(parseType());
          while (optional(",")) {
            advance();
            arguments.add(parseType());
          }
          peek = splitCloser(peek) ?? peek;
          expect(">");
        }
        type = new ParsedInterfaceType(name, arguments);
      }
      if (result == null) {
        result = type;
      } else {
        result = new ParsedIntersectionType(result, type);
      }
    } while (optionalAdvance("&"));
    return result;
  }

  ParsedType parseReturnType() {
    if (optionalAdvance("void")) return new ParsedVoidType();
    return parseType();
  }

  ParsedFunctionType parseFunctionType() {
    List<ParsedTypeVariable> typeVariables = parseTypeVariablesOpt();
    ParsedArguments arguments = parseArguments();
    expect("-");
    expect(">");
    ParsedType returnType = parseReturnType();
    return new ParsedFunctionType(typeVariables, returnType, arguments);
  }

  String parseName() {
    if (!peek.isIdentifier) {
      throw "Expected a name, but got '${peek.stringValue}'\n${computeLocation()}";
    }
    String result = peek.lexeme;
    advance();
    return result;
  }

  ParsedArguments parseArguments() {
    List<ParsedType> requiredArguments = <ParsedType>[];
    List optionalArguments = [];
    bool optionalAreNamed = false;
    expect("(");
    do {
      if (optional(")")) break;
      if (optionalAdvance("[")) {
        do {
          optionalArguments.add(parseType());
        } while (optionalAdvance(","));
        expect("]");
        break;
      } else if (optionalAdvance("{")) {
        optionalAreNamed = true;
        do {
          optionalArguments.add(parseType());
          optionalArguments.add(parseName());
        } while (optionalAdvance(","));
        expect("}");
        break;
      } else {
        requiredArguments.add(parseType());
      }
    } while (optionalAdvance(","));
    expect(")");
    return new ParsedArguments(
        requiredArguments, optionalArguments, optionalAreNamed);
  }

  List<ParsedTypeVariable> parseTypeVariablesOpt() {
    List<ParsedTypeVariable> typeVariables = <ParsedTypeVariable>[];
    if (optionalAdvance("<")) {
      do {
        typeVariables.add(parseTypeVariable());
      } while (optionalAdvance(","));
      peek = splitCloser(peek) ?? peek;
      expect(">");
    }
    return typeVariables;
  }

  ParsedTypeVariable parseTypeVariable() {
    String name = parseName();
    ParsedType bound;
    if (optionalAdvance("extends")) {
      bound = parseType();
    }
    return new ParsedTypeVariable(name, bound);
  }

  ParsedClass parseClass() {
    expect("class");
    String name = parseName();
    List<ParsedTypeVariable> typeVariables = parseTypeVariablesOpt();
    ParsedType supertype;
    ParsedType mixedInType;
    if (optionalAdvance("extends")) {
      supertype = parseType();
      if (optionalAdvance("with")) {
        mixedInType = parseType();
      }
    }
    List<ParsedType> interfaces = <ParsedType>[];
    if (optionalAdvance("implements")) {
      do {
        interfaces.add(parseType());
      } while (optionalAdvance(","));
    }
    ParsedFunctionType callableType;
    if (optionalAdvance("{")) {
      callableType = parseFunctionType();
      expect("}");
    } else {
      expect(";");
    }
    return new ParsedClass(
        name, typeVariables, supertype, mixedInType, interfaces, callableType);
  }

  /// This parses a general typedef on this form:
  ///
  ///     typedef <name> <type-variables-opt> <type> ;
  ///
  /// This is unlike Dart typedef.
  ParsedTypedef parseTypedef() {
    expect("typedef");
    String name = parseName();
    List<ParsedTypeVariable> typeVariables = parseTypeVariablesOpt();
    ParsedType type = parseType();
    expect(";");
    return new ParsedTypedef(name, typeVariables, type);
  }
}

List<ParsedType> parse(String text) {
  Parser parser = new Parser(scanString(text).tokens, text);
  List<ParsedType> types = <ParsedType>[];
  while (!parser.atEof) {
    types.add(parser.parseType());
  }
  return types;
}

List<ParsedTypeVariable> parseTypeVariables(String text) {
  Parser parser = new Parser(scanString(text).tokens, text);
  List<ParsedType> result = parser.parseTypeVariablesOpt();
  if (!parser.atEof) {
    throw "Expected EOF, but got '${parser.peek.stringValue}'\n"
        "${parser.computeLocation()}";
  }
  return result;
}

abstract class DefaultAction<R, A> {
  R defaultAction(ParsedType node, A a);

  static perform<R, A>(Visitor<R, A> visitor, ParsedType node, A a) {
    if (visitor is DefaultAction<R, A>) {
      DefaultAction<R, A> defaultAction = visitor as DefaultAction<R, A>;
      return defaultAction.defaultAction(node, a);
    } else {
      return null;
    }
  }
}

abstract class Visitor<R, A> {
  R visitInterfaceType(ParsedInterfaceType node, A a) {
    return DefaultAction.perform<R, A>(this, node, a);
  }

  R visitClass(ParsedClass node, A a) {
    return DefaultAction.perform<R, A>(this, node, a);
  }

  R visitTypedef(ParsedTypedef node, A a) {
    return DefaultAction.perform<R, A>(this, node, a);
  }

  R visitFunctionType(ParsedFunctionType node, A a) {
    return DefaultAction.perform<R, A>(this, node, a);
  }

  R visitVoidType(ParsedVoidType node, A a) {
    return DefaultAction.perform<R, A>(this, node, a);
  }

  R visitTypeVariable(ParsedTypeVariable node, A a) {
    return DefaultAction.perform<R, A>(this, node, a);
  }

  R visitIntersectionType(ParsedIntersectionType node, A a) {
    return DefaultAction.perform<R, A>(this, node, a);
  }
}
