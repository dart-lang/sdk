// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for dart2js's type inferrer, that used to not
// correctly infer optional named parameters.

import "package:expect/expect.dart";

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
foo({path}) {
  () => 42;
  return path;
}

main() {
  foo(path: '42');
  Expect.isFalse(foo() is String);
}
