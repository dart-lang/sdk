// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E<T> {
  element<int>(),
  element2<int>();

  static void set element(E<int> val) {} // Ok.
  static void set element2(E<String> val) {} // Error.
}

main() {}
