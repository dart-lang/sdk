// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/47645.
// To reproduce the issue the class declaration must appear before the mixin
// declaration.
class C<T> with M<C<T>> {}

mixin M<T> {
  bool fn() => true;
}

void main() {
  var c = C<int>();
  Expect.isTrue(c.fn());
}
