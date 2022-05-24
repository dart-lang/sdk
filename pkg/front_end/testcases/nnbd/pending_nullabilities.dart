// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class A {
  foo<T1 extends FutureOr<S1>, S1 extends FutureOr<T1>>(T1 t, S1 s) {}
  bar<T2 extends FutureOr<S2>, S2 extends FutureOr<Object>>(T2 t, S2 s) {}
  baz<U3 extends FutureOr<T3>, T3 extends FutureOr<S3>, S3 extends FutureOr<Object>>(U3 u, T3 t, S3 s) {}

}

main() {}
