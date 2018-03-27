// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_iterable_whereType`

main() {
  var l = [];
  l.where((e) => e is String); // LINT
  l.where(// LINT
      (e) {
    return e is String;
  });
  l.where((e) => (e is String)); // LINT
  l.where((e) => e.f is String); // OK
  l.where((e) => l is String); // OK
  l.where(// OK
      (e) {
    print('');
    return e is String;
  });
  l.whereType<String>(); // OK
}

class A {
  bool where() => true;

  m() {
    final o = new A();
    o.where(); // OK
  }
}
class B {
  bool where(bool Function(Object e) f) => null;

  m() {
    final o = new B();
    o.where((e) => false); // OK
  }
}
