// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/48948.

// @dart = 2.9

import 'package:expect/expect.dart';

class Foo {
  const Foo(this.x, this.y);

  final int x;
  final int y;

  static int hashCodeCounter = 0;

  @override
  int get hashCode {
    hashCodeCounter++;
    return x.hashCode ^ y.hashCode;
  }
}

void main() {
  final Map<Foo, int> someMap = {};
  final Set<Foo> someSet = {};
  Expect.equals(0, Foo.hashCodeCounter);

  someMap[Foo(1, 100)] = 2;
  Expect.equals(1, Foo.hashCodeCounter);

  someSet.add(Foo(1, 100));
  Expect.equals(2, Foo.hashCodeCounter);
}
