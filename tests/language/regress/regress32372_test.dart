// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
