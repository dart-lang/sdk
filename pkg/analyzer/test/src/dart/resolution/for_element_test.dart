// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForEachElementTest);
    defineReflectiveTests(ForLoopElementTest);
  });
}

@reflectiveTest
class ForEachElementTest extends DriverResolutionTest {
  test_declaredIdentifierScope() async {
    await resolveTestCode(r'''
main() {
  <int>[for (var i in [1, 2, 3]) i]; // 1
  <double>[for (var i in [1.1, 2.2, 3.3]) i]; // 2
}
''');
    assertNoTestErrors();

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.simple('i in [1, 2').staticElement,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.simple('i in [1.1').staticElement,
    );
  }
}

@reflectiveTest
class ForLoopElementTest extends DriverResolutionTest {
  test_declaredVariableScope() async {
    await resolveTestCode(r'''
main() {
  <int>[for (var i = 1; i < 10; i += 3) i]; // 1
  <double>[for (var i = 1.1; i < 10; i += 5) i]; // 2
}
''');
    assertNoTestErrors();

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.simple('i = 1;').staticElement,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.simple('i = 1.1;').staticElement,
    );
  }
}
