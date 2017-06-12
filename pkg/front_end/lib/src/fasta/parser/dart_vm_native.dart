// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implements support for Dart VM native method bodies of this form:
///
///     native STRING
///
/// This support is kept separate from parser.dart as this isn't specified in
/// the Dart Language Specification, also we hope to remove this syntax long
/// term and replace it with annotations as in `dart2js`.
library fasta.parser.dart_vm_native;

import '../../scanner/token.dart' show Token;

import '../scanner/token_constants.dart' show STRING_TOKEN;

import '../util/link.dart' show Link;

import 'parser.dart' show optional;

/// When parsing a Dart VM library file, we may encounter a native clause
/// instead of a function body. This method skips such a clause.
///
/// This method is designed to be called when encountering
/// [ErrorKind.ExpectedBlockToSkip] in [Listener.handleUnrecoverableError].
Token skipNativeClause(Token token) {
  if (!optional("native", token)) return null;
  token = token.next;
  if (token.kind != STRING_TOKEN) return null;
  if (!optional(";", token.next)) return null;
  return token;
}

/// When parsing a Dart VM library file, we may encounter native getters like
///
///     int get length native "List_getLength";
///
/// This will result in [identifiers] being
///
///     [";", '"List_getLength"', "native", "length", "get"]
///
/// We need to remove '"List_getLength"' and "native" from that list.
///
/// This method designed to be called from [Listener.handleMemberName].
Link<Token> removeNativeClause(Link<Token> identifiers) {
  Link<Token> result = identifiers.tail;
  if (result.head.kind != STRING_TOKEN) return identifiers;
  result = result.tail;
  if (result.isEmpty) return identifiers;
  if (optional('native', result.head)) {
    return result.tail.prepend(identifiers.head);
  }
  return identifiers;
}
