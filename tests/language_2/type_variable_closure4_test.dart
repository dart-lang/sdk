// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {}

class C<T> {
  map() {
    return () => <T, T>{};
  }
}

main() {
  Expect.isTrue(new C<int>().map()() is Map<int, int>);
  Expect.isFalse(new C<int>().map()() is Map<String, int>);
  Expect.isFalse(new C<int>().map()() is Map<int, String>);
}
