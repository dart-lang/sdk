// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'nested_part_declarations.dart';

part 'nested_part_declarations_part2.dart';

void declaredInPart1() {
  declaredInMain();
  declaredInPart1();
  declaredInPart2();
  declaredInPart3();
}