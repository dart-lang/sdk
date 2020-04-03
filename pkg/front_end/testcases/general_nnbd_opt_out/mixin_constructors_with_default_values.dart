// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import "package:expect/expect.dart";

class C<T> {
  String trace;
  C({a: 0, b: T}) : trace = "a: $a, b: $b";
}

class M {}

class D = C<String> with M;

class E extends D {}

class F extends C<int> with M {}

main() {
  Expect.stringEquals(
      // TODO(ahe): This is wrong, it should be "a: 0, b: Object" or an error.
      "a: 0, b: T",
      new C<Object>().trace);
  Expect.stringEquals(
      // TODO(ahe): This is wrong, it should be "a: 0, b: Object" or an error.
      "a: 0, b: T",
      new C().trace);
  Expect.stringEquals("a: 0, b: String", new D().trace);
  Expect.stringEquals("a: 0, b: String", new E().trace);
  Expect.stringEquals("a: 0, b: int", new F().trace);
}
