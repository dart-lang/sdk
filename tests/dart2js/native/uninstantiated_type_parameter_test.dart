// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test for uninstantiated native classes as type parameters.

class UA {}

@Native("B")
class UB {}

class C<T> {}

main() {
  var a = new C<UA>();
  var b = new C<UB>();

  Expect.isTrue(a is! C<int>);
  Expect.isTrue(a is! C<C>);
}
