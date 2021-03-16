// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// SharedOptions=--enable-null-aware-operators
import "package:expect/expect.dart";

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

class A {
  int x;
  m() => "a";
}

main(args) {
  var a = confuse(true) ? null : new A();
  a?.x = 3;
  Expect.throws(() => a.m());
}
