// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IssuesTest);
  });
}

/// Tests for various end-to-end cases reported as user issues, where it is
/// not obvious where to put the test otherwise.
@reflectiveTest
class IssuesTest extends DriverResolutionTest {
  /// https://github.com/dart-lang/sdk/issues/38589
  test_issue38589() async {
    await resolveTestCode('''
mixin M {}

class A implements M {}

class B implements M {}

var b = true;
var c = b ? A() : B();
''');
    assertElementTypeString(findElement.topVar('c').type, 'M');
  }
}
