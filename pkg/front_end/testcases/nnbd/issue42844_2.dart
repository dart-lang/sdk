// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  final dynamic n; // Error.

  factory C(dynamic n) = D;
}

class D implements C {
  final dynamic n;

  D(this.n);
}

main() {}
