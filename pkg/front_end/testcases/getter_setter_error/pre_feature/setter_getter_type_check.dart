// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.6

enum E<T> {
  element2<int>();

  static void set element2(E<String> val) {} // Error.
}
