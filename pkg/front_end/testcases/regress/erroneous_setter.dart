// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.10

extension Foo on int {
  set foo({final newFoo}) {
    print(foo);
  }

  int get foo => 42;

  void bar() {
    --foo;
  }
}

extension type Bar(int i) {
  set foo({final newFoo}) {
    print(foo);
  }

  int get foo => 42;

  void bar() {
    --foo;
  }
}

class Baz {
  set foo({final newFoo}) {
    print(foo);
  }

  int get foo => 42;

  void bar() {
    --foo;
  }
}
