// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks for compile-time errors or their absence for cases involving
// nullable receiver.

class A {
  foo() {}
  int get bar => 42;
  void set baz(int value) {}
  void call() {}
}

class B {
  String toString([int extra = 42]) => super.toString();
}

error(String? s, A? a, B? b) {
  s.length;
  s.substring(1, 1);

  a.foo();
  a.bar;
  a.baz = 42;
  a();
  b.toString(0);

  Function f1 = a;
  void Function() f2 = a;
  void Function()? f3 = a;
}

// It's ok to invoke members of Object on nullable types.
ok<T extends Object?>(String? s, A? a, T t, B? b, Invocation i) {
  s == s;
  a == a;
  t == t;
  b == b;

  s.hashCode;
  a.hashCode;
  t.hashCode;
  b.hashCode;

  s.toString();
  a.toString();
  t.toString();
  b.toString();

  try { s.noSuchMethod(i); } catch (e, t) {}
  try { a.noSuchMethod(i); } catch (e, t) {}
  try { t.noSuchMethod(i); } catch (e, t) {}
  try { b.noSuchMethod(i); } catch (e, t) {}

  s.runtimeType;
  a.runtimeType;
  t.runtimeType;
  b.runtimeType;
}

main() {}
