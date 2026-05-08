// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithNonFinalFieldTest);
  });
}

@reflectiveTest
class ConstConstructorWithNonFinalFieldTest extends PubPackageResolutionTest {
  test_constFactory_named_hasNonFinal_redirect() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
  const factory A.named() = B;
}

class B implements A {
  const B();
  int get x => 0;
  void set x(_) {}
}
''');
  }

  test_constFactory_unnamed_hasNonFinal_redirect() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
  const factory A() = B;
}

class B implements A {
  const B();
  int get x => 0;
  void set x(_) {}
}
''');
  }

  test_constructor_newHead_unnamed_hasAbstract() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  abstract int x;
  const new();
}
''');
  }

  test_constructor_newHead_unnamed_hasFinal() async {
    await assertNoErrorsInCode('''
class A {
  final int x = 0;
  const new();
}
''');
  }

  test_constructor_newHead_unnamed_hasNonFinal() async {
    await assertErrorsInCode(
      r'''
class A {
  int x = 0;
  const new();
}
''',
      [error(diag.constConstructorWithNonFinalField, 31, 3)],
    );
  }

  test_constructor_typeName_named_hasAbstract() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  abstract int x;
  const A.named();
}
''');
  }

  test_constructor_typeName_named_hasFinal() async {
    await assertNoErrorsInCode('''
class A {
  final int x = 0;
  const A.named();
}
''');
  }

  test_constructor_typeName_named_hasNonFinal() async {
    await assertErrorsInCode(
      r'''
class A {
  int x = 0;
  const A.named();
}
''',
      [error(diag.constConstructorWithNonFinalField, 31, 7)],
    );
  }

  test_constructor_typeName_unnamed_hasAbstract() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  abstract int x;
  const A();
}
''');
  }

  test_constructor_typeName_unnamed_hasFinal() async {
    await assertNoErrorsInCode('''
class A {
  final int x = 0;
  const A();
}
''');
  }

  test_constructor_typeName_unnamed_hasNonFinal() async {
    await assertErrorsInCode(
      r'''
class A {
  int x = 0;
  const A();
}
''',
      [error(diag.constConstructorWithNonFinalField, 31, 1)],
    );
  }

  test_primaryConstructor_named_hasNonFinal() async {
    await assertErrorsInCode(
      r'''
class const A.named() {
  int x = 0;
}
''',
      [error(diag.constConstructorWithNonFinalField, 6, 13)],
    );
  }

  test_primaryConstructor_unnamed_hasAbstract() async {
    await assertNoErrorsInCode(r'''
abstract class const A() {
  abstract int x;
}
''');
  }

  test_primaryConstructor_unnamed_hasFinal() async {
    await assertNoErrorsInCode('''
class const A() {
  final int x = 0;
}
''');
  }

  test_primaryConstructor_unnamed_hasNonFinal() async {
    await assertErrorsInCode(
      r'''
class const A() {
  int x = 0;
}
''',
      [error(diag.constConstructorWithNonFinalField, 6, 5)],
    );
  }
}
