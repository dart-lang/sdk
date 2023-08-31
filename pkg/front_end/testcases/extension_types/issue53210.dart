// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET1.c0(int id) {
  ET1.c1() : this.c0(0);
  ET1.c2(this.id);
  ET1.c3(int a, int b) : id = a + b;
  ET1.c4(int a, [int b = 1]) : id = a + b;
  ET1.c5(int a, {int b = 2}) : id = a + b;
  ET1.c6(int a, {required int b}) : id = a + b;
  factory ET1.f1() = ET1.c1;
  factory ET1.f2(int v) => ET1.c2(v);
}