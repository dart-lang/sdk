// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Test<T> {
  foo(a) => a is T;
}

main() {
  Expect.isTrue(new Test<Object>().foo(null));
  Expect.isTrue(new Test<dynamic>().foo(null));
  Expect.isFalse(new Test<int>().foo(null));
  Expect.isFalse(null is List<Object>);
}
