// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidReopenAnnotationTest);
  });
}

@reflectiveTest
class InvalidReopenAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_baseClass_mixedInTypeIsBase() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

base mixin M {}

@reopen
base class B with M {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 52, 6),
    ]);
  }

  test_baseClass_supertypeHasNoModifiers() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {}

@reopen
base class B extends A {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 47, 6),
    ]);
  }

  test_baseClass_supertypeIsBase() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

base class A {}

@reopen
base class B extends A {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 52, 6),
    ]);
  }

  test_baseClass_supertypeIsFinal() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

final class A {}

@reopen
base class B extends A {}
''');
  }

  test_baseClass_supertypeIsInterface() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

interface class A {}

@reopen
base class B extends A {}
''');
  }

  test_baseClass_supertypeIsSealed() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

sealed class A {}

@reopen
base class B extends A {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 54, 6),
    ]);
  }

  test_baseMixinClass_supertypeIsFinal() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

final class A {}

@reopen
base mixin class B implements A {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 53, 6),
    ]);
  }

  test_extensionType() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@reopen
extension type E(int i) {
  void m() { }
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 35, 6),
    ]);
  }

  test_finalClass_supertypeIsFinal() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

final class A {}

@reopen
final class B extends A {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 53, 6),
    ]);
  }

  test_finalClassTypeAlias_supertypeIsFinal() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

final class A {}
mixin M {}

@reopen
final class B = A with M;
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 64, 6),
    ]);
  }

  test_noModifiers_noSupertype() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@reopen
class A {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 35, 6),
    ]);
  }

  test_noModifiers_supertypeInDifferentLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
interface class A {}
''');
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
import 'lib.dart';

@reopen
class B implements A {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 54, 6),
    ]);
  }

  test_noModifiers_supertypeIsInterface() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

interface class A {}

@reopen
class B extends A {}
''');
  }

  test_sealedClass_mixedInTypeIsBase() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

base mixin M {}

@reopen
sealed class B with M {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 52, 6),
    ]);
  }

  test_sealedClass_supertypeIsFinal() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

final class A {}

@reopen
sealed class B extends A {}
''', [
      error(WarningCode.INVALID_REOPEN_ANNOTATION, 53, 6),
    ]);
  }
}
