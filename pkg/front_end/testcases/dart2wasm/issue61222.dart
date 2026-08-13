// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  const [E.vn(), E.v1()];
  var eList = <E>[?E.vn(), ?E.v1()];

  const [C.vn(), C.v1()];
  var cList = <C>[if (C.vn() != C.v1()) C.v1()];
}

extension type const E._(int? _) {
  const E.vn() : this._(null);
  const E.v1() : this._(1);
}

class C {
  final int? field;
  const C._(this.field);
  const C.vn() : this._(null);
  const C.v1() : this._(1);
}
