// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base class representing an arbitrary chunk of Dart code, which may or
/// may not be syntactically or semantically valid yet.
class Code {
  /// All the chunks of [Code], raw [String]s, or [TypeAnnotation]s that
  /// comprise this [Code] object.
  final List<Object> parts;

  /// Can be used to more efficiently detect the kind of code, avoiding is
  /// checks and enabling switch statements.
  CodeKind get kind => CodeKind.raw;

  Code.fromString(String code) : parts = [code];

  Code.fromParts(this.parts);
}

/// A piece of code representing a syntactically valid declaration.
class DeclarationCode extends Code {
  @override
  CodeKind get kind => CodeKind.declaration;

  DeclarationCode.fromString(String code) : super.fromString(code);

  DeclarationCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid element.
///
/// Should not include any trailing commas,
class ElementCode extends Code {
  @override
  CodeKind get kind => CodeKind.element;

  ElementCode.fromString(String code) : super.fromString(code);

  ElementCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid expression.
class ExpressionCode extends Code {
  @override
  CodeKind get kind => CodeKind.expression;

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
  @override
  CodeKind get kind => CodeKind.functionBody;

  FunctionBodyCode.fromString(String code) : super.fromString(code);

  FunctionBodyCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid identifier.
class IdentifierCode extends Code {
  @override
  CodeKind get kind => CodeKind.identifier;

  IdentifierCode.fromString(String code) : super.fromString(code);

  IdentifierCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code identifying a named argument.
///
/// This should not include any trailing commas.
class NamedArgumentCode extends Code {
  @override
  CodeKind get kind => CodeKind.namedArgument;

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
  @override
  CodeKind get kind => CodeKind.parameter;

  ParameterCode.fromString(String code) : super.fromString(code);

  ParameterCode.fromParts(List<Object> parts) : super.fromParts(parts);
}

/// A piece of code representing a syntactically valid statement.
///
/// Should always end with a semicolon.
class StatementCode extends Code {
  @override
  CodeKind get kind => CodeKind.statement;

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

enum CodeKind {
  raw,
  declaration,
  element,
  expression,
  functionBody,
  identifier,
  namedArgument,
  parameter,
  statement,
}
