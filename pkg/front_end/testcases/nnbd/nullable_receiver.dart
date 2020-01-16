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

error(String? s, A? a) {
  s.length;
  s.substring(1, 1);

  a.foo();
  a.bar;
  a.baz = 42;
  a();

  Function f1 = a;
  void Function() f2 = a;
  void Function()? f3 = a;
}

// It's ok to invoke members of Object on nullable types.
ok(String? s, A? a, Invocation i) {
  s == s;
  a == a;

  s.hashCode;
  a.hashCode;

  s.toString();
  a.toString();

  try { s.noSuchMethod(i); } catch (e, t) {}
  try { a.noSuchMethod(i); } catch (e, t) {}

  s.runtimeType;
  a.runtimeType;
}

main() {}
