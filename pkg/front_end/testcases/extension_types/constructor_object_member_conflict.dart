// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check the we don't complain about extension type constructor with the same
// name Object instance members.

extension type E1(int i) {
  E1.hashCode(int i) : this(i);
  E1.runtimeType(int i) : this(i);
  E1.toString(int i) : this(i);
}

extension type E2(int i) {
  factory E2.hashCode(int i) = E2;
  factory E2.runtimeType(int i) = E2;
  factory E2.toString(int i) = E2;
}
