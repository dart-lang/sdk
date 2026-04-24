// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'part1.dart';
part 'part2.dart';
part 'part3.dart';

String concatenate1(String a, String b) {
  // Padding...........................
  // 'return' is at line 12, column 3, offset 410.
  return '$a$b'; // Breakpoint: Concatenate1
}
