// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for Issue 16407.

void main() {
  foo(null, true);
  foo('x', false);
}

var foo = (x, result) {
  Expect.equals(result, x is Null, '$x is Null');
};
