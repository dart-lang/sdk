// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Foo(dynamic x) {
  late final foo1 = bar;
  late final foo2 = baz(0);

  int baz(int i) {
    print(bar);
    print(x.bar);
    if (i == 0) {
      var b1 = baz(1);
      var b2 = this.baz(1);
      print(b1 + b2);
    }
    return 42;
  }
}

// OK
extension type Foo2._(dynamic _input) {
  Foo2.fromInt(int i) : this._(i * 2);
}
