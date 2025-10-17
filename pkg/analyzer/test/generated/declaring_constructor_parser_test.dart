// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclaringConstructorsParserTest);
  });
}

@reflectiveTest
class DeclaringConstructorsParserTest extends PubPackageResolutionTest {
  test_constWithoutPrimaryConstructor_class() async {
    await assertErrorsInCode(
      r'''
class const C {}
''',
      [error(ParserErrorCode.constWithoutPrimaryConstructor, 6, 5)],
    );
  }

  test_constWithoutPrimaryConstructor_enum() async {
    await assertErrorsInCode(
      r'''
enum const E {
  a
}
''',
      [error(ParserErrorCode.constWithoutPrimaryConstructor, 5, 5)],
    );
  }

  test_constWithoutPrimaryConstructor_extensionType() async {
    await assertErrorsInCode(
      r'''
extension type const E {}
''',
      [error(ParserErrorCode.missingPrimaryConstructor, 21, 1)],
    );
  }

  test_constWithoutPrimaryConstructor_namedMixinApplication() async {
    await assertErrorsInCode(
      r'''
mixin M {}
class const C = Object with M;
''',
      [error(ParserErrorCode.constWithoutPrimaryConstructor, 17, 5)],
    );
  }

  test_primaryConstructor_class_const() async {
    await assertNoErrorsInCode(r'''
class const C() {}
''');
  }

  test_primaryConstructor_class_const_named() async {
    await assertNoErrorsInCode(r'''
class const C.named() {}
''');
  }

  test_primaryConstructor_class_const_typeParameters() async {
    await assertNoErrorsInCode(r'''
class const C<T>() {}
''');
  }

  test_primaryConstructor_class_const_typeParameters_named() async {
    await assertNoErrorsInCode(r'''
class const C<T>.named() {}
''');
  }

  test_primaryConstructor_class_nonconst() async {
    await assertNoErrorsInCode(r'''
class C() {}
''');
  }

  test_primaryConstructor_class_nonconst_named() async {
    await assertNoErrorsInCode(r'''
class C.named() {}
''');
  }

  test_primaryConstructor_class_nonconst_typeParameters() async {
    await assertNoErrorsInCode(r'''
class C<T>() {}
''');
  }

  test_primaryConstructor_class_nonconst_typeParameters_named() async {
    await assertNoErrorsInCode(r'''
class C<T>.named() {}
''');
  }

  test_primaryConstructor_enum_const() async {
    await assertNoErrorsInCode(r'''
enum const E() {
  a
}
''');
  }

  test_primaryConstructor_enum_const_named() async {
    await assertNoErrorsInCode(r'''
enum const E.named() {
  a
}
''');
  }

  test_primaryConstructor_enum_const_typeParameters() async {
    await assertNoErrorsInCode(r'''
enum const E<T>() {
  a
}
''');
  }

  test_primaryConstructor_enum_const_typeParameters_named() async {
    await assertNoErrorsInCode(r'''
enum const E<T>.named() {
  a
}
''');
  }

  test_primaryConstructor_enum_nonconst() async {
    await assertNoErrorsInCode(r'''
enum E() {
  a
}
''');
  }

  test_primaryConstructor_enum_nonconst_named() async {
    await assertNoErrorsInCode(r'''
enum E.named() {
  a
}
''');
  }

  test_primaryConstructor_enum_nonconst_typeParameters() async {
    await assertNoErrorsInCode(r'''
enum E<T>() {
  a
}
''');
  }

  test_primaryConstructor_enum_nonconst_typeParameters_named() async {
    await assertNoErrorsInCode(r'''
enum E<T>.named() {
  a
}
''');
  }

  test_primaryConstructor_extensionType_const() async {
    await assertNoErrorsInCode(r'''
extension type const E(int i) {}
''');
  }

  test_primaryConstructor_extensionType_const_named() async {
    await assertNoErrorsInCode(r'''
extension type const E.named(int i) {}
''');
  }

  test_primaryConstructor_extensionType_const_typeParameters() async {
    await assertNoErrorsInCode(r'''
extension type const E<T>(int i) {}
''');
  }

  test_primaryConstructor_extensionType_const_typeParameters_named() async {
    await assertNoErrorsInCode(r'''
extension type const E<T>.named(int i) {}
''');
  }

  test_primaryConstructor_extensionType_nonconst() async {
    await assertNoErrorsInCode(r'''
extension type E(int i) {}
''');
  }

  test_primaryConstructor_extensionType_nonconst_named() async {
    await assertNoErrorsInCode(r'''
extension type E.named(int i) {}
''');
  }

  test_primaryConstructor_extensionType_nonconst_typeParameters() async {
    await assertNoErrorsInCode(r'''
extension type E<T>(int i) {}
''');
  }

  test_primaryConstructor_extensionType_nonconst_typeParameters_named() async {
    await assertNoErrorsInCode(r'''
extension type E<T>.named(int i) {}
''');
  }
}
