// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  final Object? a;

  A1({required this.a});
}

class B1 extends A1 {
  B1({super.a}) {}
}

class A2 {
  final Object? a;

  A2(this.a);
}

class B2 extends A2 {
  B2([super.a]);
}

void main() {
  var f1 = B1.new;
  var f2 = B2.new;
}
