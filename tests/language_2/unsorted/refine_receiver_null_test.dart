// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for dart2js that used to infer that code following
// a dynamic call could assume the receiver is not null. This does not
// work for Object methods.

import "package:expect/expect.dart";

main() {
  var a = true ? null : 42;
  a.toString();
  foo(a);
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
foo(a) {
  var f = () => 42;
  Expect.throwsNoSuchMethodError(() => a + 42);
}
