// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that user field names cannot clash with internal names of the
// dart2js compiler.

class A<T> {
  var $isA;
  var $eq;
  var $builtinTypeInfo;
}

main() {
  var c = [new A()];
  Expect.isTrue(c[0] is A);
  Expect.isTrue(c[0] == c[0]);

  c = [new A<int>()];
  c[0].$builtinTypeInfo = 42;
  Expect.isTrue(c[0] is! A<String>);
}
