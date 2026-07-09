// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'nested_part_declarations_part1.dart';
part 'nested_part_declarations_part3.dart';

void declaredInMain() {
  declaredInMain();
  declaredInPart1();
  declaredInPart2();
  declaredInPart3();
}
