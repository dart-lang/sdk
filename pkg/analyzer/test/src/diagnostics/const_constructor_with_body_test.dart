// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithBodyTest);
  });
}

@reflectiveTest
class ConstConstructorWithBodyTest extends PubPackageResolutionTest {
  test_class_constructor_hasAssert() async {
    await assertNoErrorsInCode(r'''
class C {
  const C() : assert(true);
}
''');
  }

  test_class_constructor_hasBody() async {
    await assertErrorsInCode(
      r'''
class C {
  const C() {}
}
''',
      [error(diag.constConstructorWithBody, 22, 1)],
    );
  }

  test_class_constructor_noBody() async {
    await assertNoErrorsInCode(r'''
class C {
  const C();
}
''');
  }

  test_class_primaryConstructor_hasBody_block() async {
    await assertErrorsInCode(
      r'''
class const C() {
  this {}
}
''',
      [error(diag.constConstructorWithBody, 25, 1)],
    );
  }

  test_class_primaryConstructor_hasBody_empty() async {
    await assertNoErrorsInCode(r'''
class const C() {
  this;
}
''');
  }

  test_class_primaryConstructor_hasBody_empty_hasAssert() async {
    await assertNoErrorsInCode(r'''
class const C() {
  this : assert(true);
}
''');
  }

  test_class_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class const C() {}
''');
  }

  test_enum_constructor_hasBody_block() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E() {}
}
''',
      [error(diag.constConstructorWithBody, 26, 1)],
    );
  }

  test_enum_constructor_hasBody_empty_hasAssert() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E() : assert(true);
}
''');
  }

  test_enum_constructor_noBody_empty() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E();
}
''');
  }

  test_enum_primaryConstructor_hasAssert() async {
    await assertNoErrorsInCode(r'''
enum const E() {
  v;
  this : assert(true);
}
''');
  }

  test_enum_primaryConstructor_hasBody_block() async {
    await assertErrorsInCode(
      r'''
enum const E() {
  v;
  this {}
}
''',
      [error(diag.constConstructorWithBody, 29, 1)],
    );
  }

  test_enum_primaryConstructor_hasBody_empty() async {
    await assertNoErrorsInCode(r'''
enum const E() {
  v;
  this;
}
''');
  }

  test_enum_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
enum const E() {
  v;
}
''');
  }

  test_extensionType_primaryConstructor_hasBody_block() async {
    await assertErrorsInCode(
      r'''
extension type const E(int it) {
  this {}
}
''',
      [error(diag.constConstructorWithBody, 40, 1)],
    );
  }

  test_extensionType_primaryConstructor_hasBody_empty() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  this;
}
''');
  }

  test_extensionType_primaryConstructor_hasBody_empty_hasAssert() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {
  this : assert(true);
}
''');
  }

  test_extensionType_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}
''');
  }
}
