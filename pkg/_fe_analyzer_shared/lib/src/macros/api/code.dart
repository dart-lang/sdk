// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base class representing an arbitrary chunk of Dart code, which may or
/// may not be syntactically or semantically valid yet.
class Code {
  /// All the chunks of [Code] or raw [String]s that comprise this [Code]
  /// object.
  final List<Object> parts;

  Code.fromString(String code) : parts = [code];

  Code.fromParts(this.parts);
}

/// A piece of code representing a syntactically valid declaration.
class DeclarationCode extends Code {
  DeclarationCode.fromString(String code) : super.fromString(code);

  DeclarationCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid element.
///
/// Should not include any trailing commas,
class ElementCode extends Code {
  ElementCode.fromString(String code) : super.fromString(code);

  ElementCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid expression.
class ExpressionCode extends Code {
  ExpressionCode.fromString(String code) : super.fromString(code);

  ExpressionCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid function body.
///
/// This includes any and all code after the parameter list of a function,
/// including modifiers like `async`.
///
/// Both arrow and block function bodies are allowed.
class FunctionBodyCode extends Code {
  FunctionBodyCode.fromString(String code) : super.fromString(code);

  FunctionBodyCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid identifier.
class IdentifierCode extends Code {
  IdentifierCode.fromString(String code) : super.fromString(code);

  IdentifierCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code identifying a named argument.
///
/// This should not include any trailing commas.
class NamedArgumentCode extends Code {
  NamedArgumentCode.fromString(String code) : super.fromString(code);

  NamedArgumentCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code identifying a syntactically valid function parameter.
///
/// This should not include any trailing commas, but may include modifiers
/// such as `required`, and default values.
///
/// There is no distinction here made between named and positional parameters,
/// nor between optional or required parameters. It is the job of the user to
/// construct and combine these together in a way that creates valid parameter
/// lists.
class ParameterCode extends Code {
  ParameterCode.fromString(String code) : super.fromString(code);

  ParameterCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid statement.
///
/// Should always end with a semicolon.
class StatementCode extends Code {
  StatementCode.fromString(String code) : super.fromString(code);

  StatementCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

extension Join<T extends Code> on List<T> {
  /// Joins all the items in [this] with [separator], and returns
  /// a new list.
  List<Code> joinAsCode(String separator) => [
        for (int i = 0; i < length - 1; i++) ...[
          this[i],
          new Code.fromString(separator),
        ],
        last,
      ];
}
