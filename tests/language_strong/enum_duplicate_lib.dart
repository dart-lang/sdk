// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library enum_duplicate_lib;

enum Enum1 {
  A,
  B,
}

class Enum2 {
  static Iterable get values => ['Enum2.A', 'Enum2.B'];
}
