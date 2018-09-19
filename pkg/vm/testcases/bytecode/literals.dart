// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum A {
  elem1,
  elem2,
  elem3,
  elem4,
}

class B {
  final int i;
  const B(this.i);
}

class C extends B {
  final int j;
  const C(int a, int b, int c)
      : j = a + b,
        super(c * 5);
}

class D {
  final x;
  final y;
  const D(this.x, [this.y]);
}

const c1 = A.elem3;
const c2 = 'hello!';
const c3 = c2.length;
const c4 = const C(1, 2, 3);
const c5 = const D(const B(4));

void test_constants1() {
  print(c1);
  print(c2);
  print(c3);
  print(c4);
  print(c5);
}

void test_constants2() {
  print(42);
  print('foo');
  print(A.elem2);
  print(const [42, 'foo', int]);
  print(const <String, A>{'E2': A.elem2, 'E4': A.elem4});
  print(
      const D(const C(4, 5, 6), const {'foo': 42, 'bar': const B(c2.length)}));
}

void test_list_literal(int a) {
  print([1, a, 3]);
  print(<String>['a', a.toString(), 'b']);
}

void test_map_literal<T>(int a, int b, T c) {
  print({1: a, b: 2});
  print(<String, int>{'foo': a, b.toString(): 3});
  print(<String, T>{});
  print(<T, int>{c: 4});
}

void test_symbol() {
  print(#test_symbol);
  print(#_private_symbol);
}

void test_type_literal<T>() {
  print(String);
  print(T);
}

class E<T> {
  const E();
}

class F<P, Q> extends E<Map<P, Q>> {
  const F();
}

testGenericConstInstance() => const F<int, String>();

typedef GenericFunctionType = X Function<X>(X);
testGenericFunctionTypeLiteral() => GenericFunctionType;

double fieldWithDoubleLiteralInitializer = 1.0;
testFieldWithDoubleLiteralInitializer() => fieldWithDoubleLiteralInitializer;

main() {}
