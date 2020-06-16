// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B<T> extends C<T> {
  B();
  factory B.foo() = B<T>;

}

class C<K> {
  C();
  factory C.bar() = B<K>.foo;
}

main() {
  new C.bar();
}
