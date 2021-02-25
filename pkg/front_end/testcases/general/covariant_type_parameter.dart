// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<S> {
  void method<T extends S>(S s) {}
}

class B<S> {
  void method<T extends S>(covariant S s) {}
}

class C<S> extends A<S> implements B<S> {
  void method<T extends S>(S s);
}

class D<S> extends A<S> implements B<S> {}

main() {}
