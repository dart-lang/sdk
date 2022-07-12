// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/238653741.
//
// Verifies that calling async function through dynamic invocation forwarder
// does not result in a runtime error.

import "package:expect/expect.dart";

class A {
  Future<int> foo(int arg) async => arg + 3;
}

class B {
  Future<int> foo(String arg) async => int.parse(arg);
}

List<dynamic> objects = [A(), B(), 42];

void main() async {
  Expect.equals(7, await objects[0].foo(4));
  Expect.equals(8, await objects[1].foo("8"));
}
