// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to infer that code following
// a dynamic call could assume the receiver is not null. This does not
// work for Object methods.

import "package:expect/expect.dart";
import "compiler_annotations.dart";

main() {
  var a = true ? null : 42;
  a.toString();
  foo(a);
}

@DontInline()
foo(a) {
  var f = () => 42;
  Expect.throwsNoSuchMethodError(() => a + 42);
}
