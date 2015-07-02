// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  foo() => 499;
}

bar() => 42;

main() {
  String runtimeStringFoo = new A().foo.runtimeType.toString();
  String runtimeStringBar = bar.runtimeType.toString();
  // Check for the VM string, the unminified dart2js string, and a short
  // string (in case it was minified).
  Expect.isTrue(
      runtimeStringFoo == "() => dynamic" ||
      runtimeStringFoo == "BoundClosure" ||
      new RegExp('[a-zA-Z]{1,3}').hasMatch(runtimeStringFoo));
  Expect.isTrue(
      runtimeStringBar == "() => dynamic" ||
      runtimeStringBar == "StaticClosure" ||
      new RegExp('[a-zA-Z]{1,3}').hasMatch(runtimeStringFoo));
}
