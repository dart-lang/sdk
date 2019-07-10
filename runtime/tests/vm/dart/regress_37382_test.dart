// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A<X, Y> {
  R f<R>(R Function<S, T>(A<S, T>) t) => t<X, Y>(this);
}

main() {
  A<num, num> a = A<int, int>();
  Expect.equals(a.f.runtimeType.toString(), '<R>(<S, T>(A<S, T>) => R) => R');
}
