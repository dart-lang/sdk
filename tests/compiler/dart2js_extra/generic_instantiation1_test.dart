// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

int f<T>(T a) => null;

typedef int F<R>(R a);

class B<S> {
  F<S> c;

  B() : c = f;
}

main() {
  new B<int>().c(0);
}
