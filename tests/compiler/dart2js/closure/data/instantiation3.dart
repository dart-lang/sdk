// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

int f<T>(T a) => null;

typedef int F<R>(R a);

method<S>() {
  return
      /*strong.fields=[S],free=[S]*/
      /*omit.*/
      () {
    F<S> c = f;
    return c;
  };
}

main() {
  method();
}
