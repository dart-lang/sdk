// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for http://dartbug.com/40600.

import 'dart:async';

class B<Y> {
  bar(FutureOr<Y> y) {}
}

class A<X> {
  final b = new B<X>();
  foo([FutureOr<X>? x]) {
    if (x is Future<X>) {
      b.bar(x as FutureOr<X>);
    }
  }
}

class C<T> {
  FutureOr<T> baz<X extends FutureOr<T>>(FutureOr<T> x) => x;
}

class D<T> extends C<T> {
  FutureOr<T> baz<X extends FutureOr<T>>(FutureOr<T> x) => x;
}

main() {}
