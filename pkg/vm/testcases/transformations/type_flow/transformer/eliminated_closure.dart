// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  List<D> get bar;
}

class B implements A {
  List<D> bar;
  B(this.bar);
}

abstract class C {
  A get foo;

  String toString() => foo.bar.map((key) => key.baz((arg) {})).join('\n');
}

class D {
  String baz(void Function(dynamic) callback) {
    print(callback);
    return 'hey';
  }
}

class E extends C {
  A get foo => throw 'Not today';
}

void main() {
  print(D());
  print(E());
}
