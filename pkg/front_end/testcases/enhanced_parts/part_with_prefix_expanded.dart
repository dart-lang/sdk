// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'part_with_prefix_expanded_lib1.dart' as foo;
import 'part_with_prefix_expanded_lib1.dart' as bar;

part 'part_with_prefix_expanded_part1.dart';

method1() {
  foo.method1(); // Ok
  foo.method2(); // Error
  foo.method3(); // Error

  bar.method1(); // Ok
  bar.method2(); // Error
  bar.method3(); // Error
}