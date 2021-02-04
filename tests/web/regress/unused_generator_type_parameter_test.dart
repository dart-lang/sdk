// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo<X> {
  // T is unused, so can be erased, but that should not break anything.  The
  // generator should still have a header and a body since it needs to compute
  // the return type.
  Iterable<Set<X>> bar<T>() sync* {}
}

main() {
  var f = Foo<String>();
  var c = f.bar<int>();
  Expect.isFalse(c.iterator is Iterator<Set<int>>);
  Expect.isTrue(c.iterator is Iterator<Set<String>>);
}
