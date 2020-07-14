// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int f<T>(T a) => 0;

typedef int F<R>(R a);

class B<S> {
  F<S> c;

  B() : c = f;
}

main() {
  B<int>().c(0);
}
