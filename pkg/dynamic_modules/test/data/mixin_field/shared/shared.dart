// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin Foo {
  final Map<int, String> _foo = {};

  void add(int i, String s) {
    _foo[i] = s;
  }

  void printAll() {
    print(_foo);
  }
}
