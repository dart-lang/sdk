// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'conditional_parts_part2.dart'
    if (dart.library.io) 'conditional_parts_part1.dart';

test() {
  method1();
  method2();
}