// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

// Any string can be made into a `Symbol` using the `Symbol` constructor.
// Most can be converted back to the same string.

void validateSymbol(String string) {
  var expected = string;
  if (string.contains('@')) {
    // VM cuts off everything after `@`.
    expected = string.substring(0, string.indexOf('@'));
  }
  Expect.equals(
    expected,
    MirrorSystem.getName(Symbol(string)),
    'Valid symbol "$string" should be convertible back to string',
  );
  if (!string.startsWith('_')) {
    Expect.equals(
      expected,
      MirrorSystem.getName(MirrorSystem.getSymbol(string)),
      'Valid symbol "$string" should be convertible back to string',
    );
  } else {
    // MirrorSystem.getSymbol does not accept strings starting with `_`.
    Expect.throwsArgumentError(
      () => MirrorSystem.getSymbol(string),
      'Invalid symbol "$string" should be rejected',
    );
  }
}

void validatePrivateSymbol(String string) {
  ClosureMirror closure = reflect(main) as ClosureMirror;
  LibraryMirror library = closure.function.owner as LibraryMirror;
  Expect.equals(
    string,
    MirrorSystem.getName(MirrorSystem.getSymbol(string, library)),
    'Valid private symbol "$string" should be convertible back to string',
  );
}

void main() {
  // Operators that can be declared as class member operators.
  // These are all valid as symbols.
  var operators = [
    '%',
    '&',
    '*',
    '+',
    '-',
    '/',
    '<',
    '<<',
    '<=',
    '==',
    '>',
    '>=',
    '>>',
    '[]',
    '[]=',
    '^',
    'unary-',
    '|',
    '~',
    '~/',
  ];
  operators.expand((op) => [op, "x.$op"]).forEach(validateSymbol);
  operators
      .expand((op) => [".$op", "$op.x", "x$op", "_x$op"])
      .forEach(validateSymbol);
  operators
      .expand<String>(
        (op) => operators.contains("$op=") ? [] : ["x.$op=", "$op="],
      )
      .forEach(validateSymbol);

  var simpleSymbols = [
    'foo',
    'bar_',
    'baz.quz',
    'fisk1',
    'hest2fisk',
    'a.b.c.d.e',
    r'$',
    r'foo$',
    r'bar$bar',
    r'$.$',
    r'x6$_',
    r'$6_',
    r'x.$$6_',
    'x_',
    'x_.x_',
    'unary',
    'x.unary',
  ];
  simpleSymbols.expand((s) => [s, "s="]).forEach(validateSymbol);

  var nonSymbols = [
    // Non-identifiers.
    '6', '0foo', ',', 'S with M', '_invalid&private', '#foo', ' foo', 'foo ',
    // Operator variants.
    '+=', '()', 'operator+', 'unary+', '>>>', '&&', '||', '!', '@', '#', '[',
    'x@y',
    // Private symbols.
    '_', '_x', 'x._y', 'x._',
    // Empty parts of "qualified" symbols.
    '.', 'x.', '.x', 'x..y',
  ];
  nonSymbols.forEach(validateSymbol);

  // Reserved words are not valid identifiers.
  var reservedWords = [
    "assert",
    "break",
    "case",
    "catch",
    "class",
    "const",
    "continue",
    "default",
    "do",
    "else",
    "enum",
    "extends",
    "false",
    "final",
    "finally",
    "for",
    "if",
    "in",
    "is",
    "new",
    "null",
    "rethrow",
    "return",
    "super",
    "switch",
    "this",
    "throw",
    "true",
    "try",
    "var",
    "void",
    "while",
    "with",
  ];
  reservedWords
      .expand((w) => [w, "$w=", "x.$w", "$w.x", "x.$w.x"])
      .forEach(validateSymbol);
  reservedWords
      .expand((w) => ["${w}_", "${w}\$", "${w}q"])
      .forEach(validateSymbol);

  // Built-in identifiers are valid identifiers that are restricted from being
  // used in some cases, but they are all valid symbols. (List not complete.)
  var builtInIdentifiers = [
    "abstract",
    "as",
    "dynamic",
    "export",
    "external",
    "factory",
    "get",
    "implements",
    "import",
    "library",
    "operator",
    "part",
    "set",
    "static",
    "typedef",
  ];
  builtInIdentifiers
      .expand((w) => [w, "$w=", "x.$w", "$w.x", "x.$w.x", "$w=", "x.$w="])
      .forEach(validateSymbol);

  var privateSymbols = ['_', '_x', 'x._y', 'x._', 'x.y._', 'x._.y', '_true'];
  privateSymbols.forEach(validateSymbol);
  privateSymbols.forEach(validatePrivateSymbol);
}
