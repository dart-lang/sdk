// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/6036. dart2js used to fail
// this method because it was computing that intersecting type D with
// type C is conflicting.

foo(a, b) {
  if (identical(a, b)) return;
  throw 'broken';
}

class D {}

class C implements D {}

main() {
  var c = new C();
  foo(c, c as D);
}
