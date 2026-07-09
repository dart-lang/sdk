// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/56051.

// VMOptions=--compiler-passes=-Inlining

import 'package:expect/expect.dart';

class Foo {
  covariant late num a;
}

class Bar extends Foo {
  @override
  late int a;
}

void main() {
  Foo bar = Bar();
  bar.a = 2;
  Expect.equals(2, bar.a);
  Expect.throws(() {
    bar.a = 3.14 as dynamic;
    print('bar.a is now ${bar.a}');
  });
  print("success!");
}
