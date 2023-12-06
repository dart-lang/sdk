// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int? f1;
  double? f2;

  @pragma('vm:never-inline')
  String foo() {
    return switch ((this.f1, this.f2)) {
      (final f1, _) => '$f1',
      (null, final f2) => '$f2',
      (null, null) => '?',
    };
  }
}

void main() {
  print(A().foo());
}
