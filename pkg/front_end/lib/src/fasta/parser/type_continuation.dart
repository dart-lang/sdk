// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_continuation;

import 'formal_parameter_kind.dart' show FormalParameterKind;

/// Indication of how the parser should continue after (attempting) to parse a
/// type.
///
/// Depending on the continuation, the parser may not parse a type at all.
enum TypeContinuation {
  /// Indicates that a type is unconditionally expected.
  Required,

  /// Indicates that a type may follow. If the following matches one of these
  /// productions, it is parsed as a type:
  ///
  ///  - `'void'`
  ///  - `'Function' ( '(' | '<' )`
  ///  - `identifier ('.' identifier)? ('<' ... '>')? identifer`
  ///
  /// Otherwise, do nothing.
  Optional,

  /// Same as [Optional], but we have seen `var`.
  OptionalAfterVar,

  /// Indicates that the keyword `typedef` has just been seen, and the parser
  /// should parse the following as a type unless it is followed by `=`.
  Typedef,

  /// Indicates that what follows is either a local declaration or an
  /// expression.
  ExpressionStatementOrDeclaration,

  /// Indicates that the keyword `const` has just been seen, and what follows
  /// may be a local variable declaration or an expression.
  ExpressionStatementOrConstDeclaration,

  /// Indicates that the parser is parsing an expression and has just seen an
  /// identifier.
  SendOrFunctionLiteral,

  /// Indicates that the parser has just parsed `for '('` and is looking to
  /// parse a variable declaration or expression.
  VariablesDeclarationOrExpression,

  /// Indicates that an optional type followed by a normal formal parameter is
  /// expected.
  NormalFormalParameter,

  /// Indicates that an optional type followed by an optional positional formal
  /// parameter is expected.
  OptionalPositionalFormalParameter,

  /// Indicates that an optional type followed by a named formal parameter is
  /// expected.
  NamedFormalParameter,

  /// Same as [NormalFormalParameter], but we have seen `var`.
  NormalFormalParameterAfterVar,

  /// Same as [OptionalPositionalFormalParameter], but we have seen `var`.
  OptionalPositionalFormalParameterAfterVar,

  /// Same as [NamedFormalParameter], but we have seen `var`.
  NamedFormalParameterAfterVar,
}

TypeContinuation typeContinuationFromFormalParameterKind(
    FormalParameterKind type) {
  if (type != null) {
    switch (type) {
      case FormalParameterKind.mandatory:
        return TypeContinuation.NormalFormalParameter;

      case FormalParameterKind.optionalNamed:
        return TypeContinuation.NamedFormalParameter;

      case FormalParameterKind.optionalPositional:
        return TypeContinuation.OptionalPositionalFormalParameter;
    }
  }
  return null;
}
