// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test division by power of two.
// Test that results before and after optimization are the same.

import "package:expect/expect.dart";

class Foo {
  final Bar<Foo> bar = const Bar /* comment here use to trigger bug 323 */ ();
}

class Bar<T extends Foo> {
  const Bar();
}

main() {
  Expect.equals(new Foo().bar, const Bar());
}
