// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type const ET3<T extends num>(int id) {
  const ET3.c1() : this(0);
  factory ET3.f1() = ET3.c1;
}
