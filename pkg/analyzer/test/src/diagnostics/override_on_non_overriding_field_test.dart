// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingFieldTest);
  });
}

@reflectiveTest
class OverrideOnNonOverridingFieldTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(
      r'''
class A {
  @override
  int? foo;
}
''',
      [error(diag.overrideOnNonOverridingField, 29, 3)],
    );
  }

  test_class_extends() async {
    await assertErrorsInCode(
      r'''
class A {
  int get a => 0;
  void set b(_) {}
  int c = 0;
}
class B extends A {
  @override
  final int a = 1;
  @override
  int b = 0;
  @override
  int c = 0;
}''',
      [
        error(
          diag.invalidOverrideSetter,
          131,
          1,
          contextMessages: [message(testFile, 39, 1)],
        ),
      ],
    );
  }

  test_class_extends_primaryConstructor() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int get foo;
}
class B(@override final int foo) extends A;
''');
  }

  test_class_implements() async {
    await assertNoErrorsInCode(r'''
class A {
  int get a => 0;
}
class B implements A {
  @override
  final int a = 1;
}''');
  }

  test_class_implements_overriddenSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  void set b(_) {}
}
class B implements A {
  @override
  int b = 0;
}''',
      [
        error(
          diag.invalidOverrideSetter,
          72,
          1,
          contextMessages: [message(testFile, 21, 1)],
        ),
      ],
    );
  }

  test_class_implements_overrideIsFinal() async {
    await assertNoErrorsInCode(r'''
class A {
  int c = 0;
}
class B implements A {
  @override
  int c = 0;
}''');
  }

  test_class_implements_primaryConstructor() async {
    await assertNoErrorsInCode(r'''
class A(final int foo);
class B(@override final int foo) implements A;
''');
  }

  test_class_primaryConstructor() async {
    await assertErrorsInCode(
      r'''
class A(@override final int foo);
''',
      [error(diag.overrideOnNonOverridingField, 28, 3)],
    );
  }

  test_class_static() async {
    await assertErrorsInCode(
      r'''
class A {
  @override
  static int foo = 1;
}
''',
      [error(diag.overrideOnNonOverridingField, 35, 3)],
    );
  }

  test_enum() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  @override
  final int foo = 0;
}
''',
      [error(diag.overrideOnNonOverridingField, 38, 3)],
    );
  }

  test_enum_implements() async {
    await assertNoErrorsInCode(r'''
class A {
  int get a => 0;
  void set b(int _) {}
}

enum E implements A {
  v;
  @override
  int get a => 0;

  @override
  void set b(int _) {}
}
''');
  }

  test_enum_with() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get a => 0;
  void set b(int _) {}
}

enum E with M {
  v;
  @override
  int get a => 0;

  @override
  void set b(int _) {}
}
''');
  }
}
