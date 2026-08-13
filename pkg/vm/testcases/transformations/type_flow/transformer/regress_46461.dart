// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum A { a1, a2 }

class B {
  void foo({A? x = A.a1}) {}
}

class C implements B {
  void foo({A? x}) {}
}

B obj = C();

void main() {
  obj.foo();
}
