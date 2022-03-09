// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T> extends T {}

abstract class B<T> extends T {
  B();
}

class C<T> extends T {}

main() {
  new A();
  new B();
  new C();
}
