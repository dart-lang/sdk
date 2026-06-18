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

void recordLiterals<T>(int a, String b, T c) {
  print((a,));
  print((a, b, c));
  print((foo: b, bar: c));
  print((a, foo: b, bar: c));
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
    void local1() {
      print(T);
      print(U);
    }

    local1();
    void local2<V>() {
      print(Map<U, V>);
    }

    local2();
  }
}

void nestedFunctionTypeParameters1<S>() {
  void nested1<T>() {
    void nested2<U>() {
      print(S);
      print(T);
      print(U);
    }

    nested2<int>();
  }

  nested1<String>();
}

void nestedFunctionTypeParameters2<S>() {
  void nested1() {
    void nested2<T>() {
      print(S);
      print(T);
    }

    nested2<int>();
  }

  nested1();
}

class D<S, T> {}

class E<T, U> extends D<String, T> {}

class F extends E<num, double> {}

void allocateObjects<K>() {
  print(D<int, double>());
  print(E<int, double>());
  print(E<K, List<K>>());
  print(F());
}

void instantiateClosures<T1, T2>(
  void Function<S1>() foo,
  S2 Function<S2, S3>(S3) bar,
) {
  print(foo<int>);
  print(bar<T1, String>);
  int Function(T2) baz = bar;
  print(baz);
}

void main() {}
