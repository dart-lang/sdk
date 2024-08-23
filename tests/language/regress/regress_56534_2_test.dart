// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool get runtimeTrue => int.parse('1') == 1;

class C {
  void test<T>([T? x]) {}
}

void main() {
  final c = C();
  void Function() x = runtimeTrue ? c.test : () {};
  x();
}
