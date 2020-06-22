// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../constant/potentially_constant_test.dart';
import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldTest);
    defineReflectiveTests(FieldWithNullSafetyTest);
  });
}

@reflectiveTest
class FieldTest extends DriverResolutionTest {
  test_type_inferred_int() async {
    await resolveTestCode('''
class A {
  var f = 0;
}
''');
    assertType(findElement.field('f').type, 'int');
  }

  test_type_inferred_Never() async {
    await resolveTestCode('''
class A {
  var f = throw 42;
}
''');
    assertType(
      findElement.field('f').type,
      typeStringByNullability(
        nullable: 'Never',
        legacy: 'dynamic',
      ),
    );
  }

  test_type_inferred_noInitializer() async {
    await resolveTestCode('''
class A {
  var f;
}
''');
    assertType(findElement.field('f').type, 'dynamic');
  }

  test_type_inferred_null() async {
    await resolveTestCode('''
class A {
  var f = null;
}
''');
    assertType(findElement.field('f').type, 'dynamic');
  }
}

@reflectiveTest
class FieldWithNullSafetyTest extends FieldTest with WithNullSafetyMixin {
  test_type_inferred_nonNullify() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
var a = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class A {
  var f = a;
}
''');

    assertType(findElement.field('f').type, 'int');
  }
}
