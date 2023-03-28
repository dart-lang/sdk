// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

import "package:expect/expect.dart";

class A extends Object with B<String>, C {}

class B<T> {}

mixin C<T> on B<T> {
  get t => T;
}

main() {
  var x = new A();
  Expect.equals(x.t, String);
}
