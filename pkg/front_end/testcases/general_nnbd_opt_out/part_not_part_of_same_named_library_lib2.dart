// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

library foo;

part "part_not_part_of_same_named_library_lib1.dart";

methodFromLib2() {
  methodFromLib1();
}
