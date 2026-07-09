// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

base mixin M {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
base class B with M {}
''');
  }

  test_baseClass_supertypeHasNoModifiers() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
base class B extends A {}
''');
  }

  test_baseClass_supertypeIsBase() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

base class A {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
base class B extends A {}
''');
  }

  test_baseClass_supertypeIsFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final class A {}

@reopen
base class B extends A {}
''');
  }

  test_baseClass_supertypeIsInterface() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

interface class A {}

@reopen
base class B extends A {}
''');
  }

  test_baseClass_supertypeIsSealed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

sealed class A {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
base class B extends A {}
''');
  }

  test_baseMixinClass_supertypeIsFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final class A {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
base mixin class B implements A {}
''');
  }

  test_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@reopen
// [diag.invalidAnnotationTarget][column 2][length 6] The annotation 'reopen' can only be used on classes or mixins.
extension type E(int i) {
  void m() { }
}
''');
  }

  test_finalClass_supertypeIsFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final class A {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
final class B extends A {}
''');
  }

  test_finalClassTypeAlias_supertypeIsFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final class A {}
mixin M {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
final class B = A with M;
''');
  }

  test_noModifiers_noSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
class A {}
''');
  }

  test_noModifiers_supertypeInDifferentLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
interface class A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
import 'lib.dart';

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
class B implements A {}
''');
  }

  test_noModifiers_supertypeIsInterface() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

interface class A {}

@reopen
class B extends A {}
''');
  }

  test_sealedClass_mixedInTypeIsBase() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

base mixin M {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
sealed class B with M {}
''');
  }

  test_sealedClass_supertypeIsFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final class A {}

@reopen
// [diag.invalidReopenAnnotation][column 2][length 6] The annotation '@reopen' can only be applied to a class that opens capabilities that the supertype intentionally disallows.
sealed class B extends A {}
''');
  }
}
