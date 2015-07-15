// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fieldtest;

class A {
  int x = 42;
}

class B<T> {
  int x;
  num y;
  T z;
}

int foo(A a) {
  print(a.x);
  return a.x;
}

int bar(a) {
  print(a.x);
  return a.x;
}

baz(A a) => a.x;

int compute() => 123;
int y = compute() + 444;

String get q => 'life, ' + 'the universe ' + 'and everything';
int get z => 42;
void set z(value) {
  y = value;
}

// Supported: use field to implement a getter
abstract class BaseWithGetter {
  int get foo => 1;
  int get bar;
}
class Derived extends BaseWithGetter {
  int foo = 2;
  int bar = 3;
}

class Generic<T> {
  foo(T t) => print(bar + (t as String));

  static String bar = 'hello';
}

class StaticFieldOrder1 {
  static const a = b + 1;
  static const c = d + 2;
  static const b = c + 3;
  static const d = 4;
}
class StaticFieldOrder2 {
  static const a = StaticFieldOrder2.b + 1;
  static const c = StaticFieldOrder2.d + 2;
  static const b = StaticFieldOrder2.c + 3;
  static const d = 4;
}

enum MyEnum { Val1, Val2, Val3, Val4 }

void main() {
  var a = new A();
  foo(a);
  bar(a);
  print(baz(a));

  print(new Generic<String>().foo(' world'));

  print(MyEnum.values);
}
