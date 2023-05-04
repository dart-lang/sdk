// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

topLevel({int x: 3}) {}

class Class {
  method({int x: 3}) {
    local({int x: 3}) {}
    ({int x: 3}) {};
  }
}
