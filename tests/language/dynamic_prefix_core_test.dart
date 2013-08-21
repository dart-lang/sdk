// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test explicit import of dart:core in the source code..

library DynamicPrefixCoreTest.dart;
import "package:expect/expect.dart";
import "dart:core" as mycore;

void main() {
  // Should still be available because it is not a member of dart:core.
  Expect.isTrue(dynamic is Type);
  
  Expect.throws(() => mycore.dynamic is Type,
                (e) => e is NoSuchMethodError,
                'dynamic is not a member of dart:core');
}
