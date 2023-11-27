// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef A<X> = B<X, Function(X)>;

class B<T, Invariance extends Function(T)> {
  B(_);
  B() : this._(1);
}

test() {
  final A<double> doubles = A();
}
