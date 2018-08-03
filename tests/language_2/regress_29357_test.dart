// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T extends A<T>> {}

abstract class B<T extends A<T>> {}

class C<U> extends B<D<U>> {}

class D<U> extends A<D<U>> {}

main() {
  new D();
  new C();
  new D<C>();
  new C<D>();
}
