// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../constant/potentially_constant_test.dart';
import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableTest);
    defineReflectiveTests(TopLevelVariableWithNullSafetyTest);
  });
}

@reflectiveTest
class TopLevelVariableTest extends DriverResolutionTest {
  test_type_inferred_int() async {
    await resolveTestCode('''
var v = 0;
''');
    assertType(findElement.topVar('v').type, 'int');
  }

  test_type_inferred_Never() async {
    await resolveTestCode('''
var v = throw 42;
''');
    assertType(
      findElement.topVar('v').type,
      typeStringByNullability(
        nullable: 'Never',
        legacy: 'dynamic',
      ),
    );
  }

  test_type_inferred_noInitializer() async {
    await resolveTestCode('''
var v;
''');
    assertType(findElement.topVar('v').type, 'dynamic');
  }

  test_type_inferred_null() async {
    await resolveTestCode('''
var v = null;
''');
    assertType(findElement.topVar('v').type, 'dynamic');
  }
}

@reflectiveTest
class TopLevelVariableWithNullSafetyTest extends TopLevelVariableTest
    with WithNullSafetyMixin {
  test_type_inferred_nonNullify() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
var a = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

var v = a;
''');

    assertType(findElement.topVar('v').type, 'int');
  }
}
