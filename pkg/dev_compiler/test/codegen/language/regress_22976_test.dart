// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 22976.

class A<T> {}
class B<T> implements A<T> {}
class C<S, T> implements B<S>, A<T> {}

main() {
  A<int> a0 = new C<int, String>(); /// 01: ok
  A<int> a1 = new C<String, int>(); /// 02: ok
}
