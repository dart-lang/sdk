// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool test1(int a, int b) => (a & b) == 0;

void test2(int a, int b) {
  if ((a & b) == 0) {
    print('yes');
  }
  if ((a & b) != 0) {
    print('no');
  }
}

bool test3(int a, int b) {
  var c = (a & b) == 0;
  if (c) {
    print('yes');
  }
  return c;
}

void test4(int a, int b, bool c) {
  if (a > b || c) {
    print(1);
  }
  if (a > b) {
    print(2);
  }
}

int test5(int a) {
  if ((a & 32) == 32) {
    return 1;
  }
  if ((a & 16) == 8) {
    return 2;
  }
  var mask = 0x101;
  if ((a & mask) == mask) {
    return 3;
  }
  if ((a & 8) != 8) {
    return 4;
  }
  if ((a & 7) != 7) {
    return 5;
  }
  return -1;
}

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

void stringInterpolation(int x, String s, Object o) {
  print('$o');
  print('Hey, x=$x, s=$s, o=$o');
}

class C<T> {
  void typeParameters<U>(Object x) {
    print(x is List<T>);
    print(x is List<U>);
    print(x as Map<T, U>);
  }
}

void main() {}
