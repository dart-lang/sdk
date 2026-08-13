// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  Future<int> bar() async => 3;
}

Future<void> main() async {
  Object x = Object();
  if (x is Foo && (await x.bar()) > 2) {
    print('hello');
  }
}
