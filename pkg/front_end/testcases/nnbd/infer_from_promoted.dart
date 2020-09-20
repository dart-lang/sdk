// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<T> = T Function(T, T);

test1() {
  dynamic d = (int a, int b) => a;
  d as F<int>; // Promote [d] to `int Function(int, int)`.
  d = <S>(S a, S b) => a;
}

test2() {
  dynamic d = (int a, int b) => a;
  d as F<int>; // Promote [d] to `int Function(int, int)`.
  d = (a, b) => '$a';
}

main() {}
