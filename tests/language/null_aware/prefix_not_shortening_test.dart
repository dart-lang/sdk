// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C e() => this;
  C operator -() => this;
  C operator ~() => this;
}

void main() {
  final C? c = new C();
  /**/ -c?.e();
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //   ^
  // [cfe] Operator 'unary-' cannot be called on 'C?' because it is potentially null.

  /**/ ~c?.e();
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //   ^
  // [cfe] Operator '~' cannot be called on 'C?' because it is potentially null.
}
