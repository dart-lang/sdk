// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T> {
  foo(T x);
}

abstract class B<T> implements A<T> {}

class C {
  foo(num x) {}
}

class D<T extends num> extends C with B<T> {}

class E<T extends num> = C with B<T>;

main() {}
