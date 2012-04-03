// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B {
  final test = const A(1, b: 2);
  const B();
}

class A {
  final x;
  final y;
  const A(a, [b]) : x = a, y = b;
  final test = const B();
}

void main() {
  print(new A(1));
}
