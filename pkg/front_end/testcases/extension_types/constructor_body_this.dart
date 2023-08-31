// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type V1.n0(int id) {
  V1.new(this.id) {
    expect(this, id);
  }
  V1.n1([int x = 0]) : id = x {
    expect(this, id);
  }
  V1.n2(int id) : this.n1(id);
}

main() {
  V1(0);
  V1.n1(1);
  V1.n2(2);
}

expect(expected, actual) {
  if (!identical(expected, actual)) throw 'Expected $expected, actual $actual';
}