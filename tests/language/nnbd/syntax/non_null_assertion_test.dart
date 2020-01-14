// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that the trailing "!" is accepted after a sampling of expression
// syntaxes.  Verify that the compiler understands the resulting type to be
// non-nullable by constructing a list containing the expression, and assigning
// it to List<Object>.  Where possible, verify that the runtime implements the
// proper null-check semantics by verifying that the presence of `null` causes
// an exception to be thrown.
import 'package:expect/expect.dart';

class C {
  const C();

  Object? get x => null;

  void f() {}
}

Object? f() => null;

main() {
  List<Object> listOfObject = [];

  var x1 = [0!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x1;

  var x2 = [true!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x2;

  var x3 = ["foo"!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x3;

  var x4 = [#foo!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x4;

  var x5 = [[1]!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x5;

  var x6 = [{1:2}!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x6;

  var x7 = [{1}!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x7;

  var x8 = [new C()!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x8;

  var x9 = [const C()!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x9;

  Expect.throws(() {
      var x10 = [f()!];
      listOfObject = x10;
  });

  C c = new C();
  Expect.throws(() {
      var x11 = [c.x!];
      listOfObject = x11;
  });

  var g = f;
  Expect.throws(() {
      var x12 = [g()!];
      listOfObject = x12;
  });

  int i = 0;
  var x13 = [(i++)!]; // ignore: unnecessary_non_null_assertion
  listOfObject = x13;
}
