// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implements support for two variants of the native syntax extension.
///
///   * The Dart VM variant, where native method bodies have this form:
///
///     methodDeclaration() native STRING;
///
///   * The Dart2js and DDC variant, where native method bodies have this form:
///
///     methodDeclaration() native;
///
/// This support is kept separate from parser.dart as this isn't specified in
/// the Dart Language Specification, also we hope to remove this syntax long
/// term and replace it with annotations and external declarations.
library fasta.parser.dart_vm_native;

import '../../scanner/token.dart' show Token;

import '../scanner/token_constants.dart' show STRING_TOKEN;

import '../util/link.dart' show Link;

import 'parser.dart' show optional;

import '../quote.dart' show unescapeString;

/// When parsing a library file, we may encounter a native clause
/// instead of a function body. This method skips such a clause. The
/// [expectString] argument is used to choose which variant of the native clause
/// we expect to parse.
///
/// This method is designed to be called when encountering
/// [ErrorKind.ExpectedBlockToSkip] in [Listener.handleUnrecoverableError].
Token skipNativeClause(Token token, bool expectString) {
  if (!optional("native", token)) return null;
  if (expectString) {
    token = token.next;
    if (token.kind != STRING_TOKEN) return null;
  }
  if (!optional(";", token.next)) return null;
  return token;
}

/// When parsing a library file, we may encounter native getters like
///
///     int get length native "List_getLength";
///
/// This will result in [identifiers] being
///
///     [";", '"List_getLength"', "native", "length", "get"]
///
/// Similarly if [expectString] is false, we expect a getter like:
///
///     int get length native;
///
/// And [identifiers] being
///
///     [";", "native", "length", "get"]
///
/// This method returns a new list where '"List_getLength"' and "native" are
/// removed.
///
/// This method is designed to be called from [Listener.handleMemberName].
Link<Token> removeNativeClause(Link<Token> identifiers, bool expectString) {
  Link<Token> result = identifiers.tail;
  if (result.isEmpty) return identifiers;
  if (expectString) {
    if (result.head.kind != STRING_TOKEN) return identifiers;
    result = result.tail;
  }
  if (result.isEmpty) return identifiers;
  if (optional('native', result.head)) {
    return result.tail.prepend(identifiers.head);
  }
  return identifiers;
}

/// When the parser encounters a native clause and expects a string (like in VM
/// and flutter patch files), this method extracts the native name in that
/// string.
String extractNativeMethodName(Token token) {
  return unescapeString(token.next.lexeme);
}
