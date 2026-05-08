// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Foo on int {
  set foo({newFoo}) {
    print(foo);
  }

  int get foo => 42;

  void bar() {
    --foo;
  }
}

extension type Bar(int i) {
  set foo({newFoo}) {
    print(foo);
  }

  int get foo => 42;

  void bar() {
    --foo;
  }
}

class Baz {
  set foo({newFoo}) {
    print(foo);
  }

  int get foo => 42;

  void bar() {
    --foo;
  }
}
