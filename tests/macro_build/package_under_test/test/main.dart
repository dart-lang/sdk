// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:package_under_test/declare_x.dart';
import 'package:test/test.dart';

@DeclareX()
class ClassWithMacroApplied {}

/// Checks that the macro applied correctly.
///
/// Not named `*_test.dart` because the test runner would pick it up and run
/// it, when what we want is the outer build test to run it.
void main() {
  test('macro was applied correctly', () {
    expect(ClassWithMacroApplied().x, 'OK');
  });
}
