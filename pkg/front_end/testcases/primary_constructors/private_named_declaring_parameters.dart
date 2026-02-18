// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C({
    var int? _a,
    final int? _b,
    required var int _c,
    required final int _d});

enum E({final int? _a, required final int _b}) {
  x(b: 1), y(a: 0, b: 1)
}

extension type ET1({int? _a});

extension type ET2({required int _a});

main() {
  C(c: 0, d: 1);
  C(a: 0, b: 1, c: 2, d: 3);
  ET1();
  ET1(a: 0);
  ET2(a: 1);
}
