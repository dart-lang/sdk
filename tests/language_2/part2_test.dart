// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library org.dartlang.test.part2_test;

part "part_part.dart"; //# 01: compile-time error

main() {
  print(foo); //# 01: continued
}
