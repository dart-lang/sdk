// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for self referencing function type alias.

typedef A(B x);
typedef B(A x);

main() {
  var aFunc = _(B x) { };
  var bFunc = _(A x) { };
  Expect.isTrue(aFunc is A);
  Expect.isTrue(bFunc is B);
}
