// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T extends num> {
  final int a;
  final T b;

  const Class.constConstructor(int a, T b)
      : this.a = a,
        this.b = b;

  Class.constructor(int a, T b)
      : this.a = a,
        this.b = b {
    int k;
    k;
  }

  external Class.patchedConstructor(int a, T b);

  int method(int a) {
    int k;
    int j = a;
    return k;
  }

  external int patchedMethod(int a);
}

int method(int a) {
  int k;
  int j = a;
  return k;
}

external void patchedMethod(int a);
