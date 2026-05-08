// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void listLiterals<T>(T x) {
  print([]);
  print(<T>[]);
  print([1, 2, 3]);
  print([1, 2, 3, 4, 5, 6, 7, 8, 9]);
  print(<T>[x, x, x, x, x, x, x, x, x]);
}

void mapLiterals<S, T>(S key, T Function() value, S key2, T value2) {
  print({});
  print(<S, T>{});
  print({'a': 'aa', 'b': 'bb'});
  print({key: value(), key2: value2});
}

void nullChecks(Object? x) {
  print(x!);
  Object? y;
  if (1 != 2) {
    y = 42;
  }
  print(y!);
}

void logical(bool x, bool Function() y, bool z) {
  print(!x);
  print(x || y());
  print(y() && x);
  print(!(x && (y() || z)));
}

void main() {}
