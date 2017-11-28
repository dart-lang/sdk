// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library symbol_validation_test;

@MirrorsUsed(targets: "symbol_validation_test")
import 'dart:mirrors';
import 'package:expect/expect.dart';

validSymbol(String string) {
  Expect.equals(string, MirrorSystem.getName(new Symbol(string)),
      'Valid symbol "$string" should be invertable');
  Expect.equals(string, MirrorSystem.getName(MirrorSystem.getSymbol(string)),
      'Valid symbol "$string" should be invertable');
}

invalidSymbol(String string) {
  Expect.throwsArgumentError(() => new Symbol(string),
      'Invalid symbol "$string" should be rejected');
  Expect.throwsArgumentError(() => MirrorSystem.getSymbol(string),
      'Invalid symbol "$string" should be rejected');
}

validPrivateSymbol(String string) {
  ClosureMirror closure = reflect(main);
  LibraryMirror library = closure.function.owner;
  Expect.equals(
      string,
      MirrorSystem.getName(MirrorSystem.getSymbol(string, library)),
      'Valid private symbol "$string" should be invertable');
}

main() {
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
    '~/'
  ];
  operators.expand((op) => [op, "x.$op"]).forEach(validSymbol);
  operators
      .expand((op) => [".$op", "$op.x", "x$op", "_x.$op"])
      .forEach(invalidSymbol);
  operators
      .expand((op) => operators.contains("$op=") ? [] : ["x.$op=", "$op="])
      .forEach(invalidSymbol);

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
    'x.unary'
  ];
  simpleSymbols.expand((s) => [s, "s="]).forEach(validSymbol);

  var nonSymbols = [
    // Non-identifiers.
    '6', '0foo', ',', 'S with M', '_invalid&private', "#foo", " foo", "foo ",
    // Operator variants.
    '+=', '()', 'operator+', 'unary+', '>>>', "&&", "||", "!", "@", "#", "[",
    // Private symbols.
    '_', '_x', 'x._y', 'x._',
    // Empty parts of "qualified" symbols.
    '.', 'x.', '.x', 'x..y'
  ];
  nonSymbols.forEach(invalidSymbol);

  // Reserved words are not valid identifiers and therefore not valid symbols.
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
    "with"
  ];
  reservedWords
      .expand((w) => [w, "$w=", "x.$w", "$w.x", "x.$w.x"])
      .forEach(invalidSymbol);
  reservedWords
      .expand((w) => ["${w}_", "${w}\$", "${w}q"])
      .forEach(validSymbol);

  // Built-in identifiers are valid identifiers that are restricted from being
  // used in some cases, but they are all valid symbols.
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
    "typedef"
  ];
  builtInIdentifiers
      .expand((w) => [w, "$w=", "x.$w", "$w.x", "x.$w.x", "$w=", "x.$w="])
      .forEach(validSymbol);

  var privateSymbols = ['_', '_x', 'x._y', 'x._', 'x.y._', 'x._.y', '_true'];
  privateSymbols.forEach(invalidSymbol);
  privateSymbols.forEach(validPrivateSymbol); //  //# 01: ok
}
