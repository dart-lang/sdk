// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithMixinWithFieldTest);
  });
}

@reflectiveTest
class ConstConstructorWithMixinWithFieldTest extends DriverResolutionTest {
  test_class_instance() async {
    addTestFile(r'''
class A {
  var a;
}

class B extends Object with A {
  const B();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD,
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
    ]);
  }

  test_class_instance_final() async {
    addTestFile(r'''
class A {
  final a = 0;
}

class B extends Object with A {
  const B();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD,
    ]);
  }

  test_class_noFields() async {
    addTestFile(r'''
class M {}

class X extends Object with M {
  const X();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_class_static() async {
    addTestFile(r'''
class M {
  static final a = 0;
}

class X extends Object with M {
  const X();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_mixin_instance() async {
    addTestFile(r'''
mixin M {
  var a;
}

class X extends Object with M {
  const X();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD,
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
    ]);
  }

  test_mixin_instance_final() async {
    addTestFile(r'''
mixin M {
  final a = 0;
}

class X extends Object with M {
  const X();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD,
    ]);
  }

  test_mixin_noFields() async {
    addTestFile(r'''
mixin M {}

class X extends Object with M {
  const X();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_mixin_static() async {
    addTestFile(r'''
mixin M {
  static final a = 0;
}

class X extends Object with M {
  const X();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }
}
