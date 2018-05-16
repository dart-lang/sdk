// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_continuation;

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

  /// Indicates that the parser is parsing an expression and has just seen an
  /// identifier.
  SendOrFunctionLiteral,
}
