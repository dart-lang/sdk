// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unused_local_variable

String? badFoo, badBar, badBaz; // LINT

String? goodFoo;
String? goodBar;
String? goodBaz;

methodContainingBadDeclaration() {
  String? badFoo, badBar, badBaz; // LINT
}

methodContainingGoodDeclaration() {
  String? goodFoo;
  String? goodBar;
  String? goodBaz;
}

class BadClass {
  String? foo, bar, baz; // LINT

  methodContainingBadDeclaration() {
    String? badFoo, badBar, badBaz; // LINT
  }
}

class GoodClass {
  String? foo;
  String? bar;
  String? baz;

  methodContainingGoodDeclaration() {
    String? goodFoo;
    String? goodBar;
    String? goodBaz;
  }
}

extension BadExtension on Object {
  static String? badFoo, badBar, badBaz; // LINT
}

extension GoodExtension on Object {
  static String? foo;
  static String? bar;
  static String? baz;
}

// https://github.com/dart-lang/linter/issues/2543
okInForLoop() {
  for (var i = 0, j = 0; i < 2 && j < 2; ++i, ++j) // OK
  {
    //
  }
}
