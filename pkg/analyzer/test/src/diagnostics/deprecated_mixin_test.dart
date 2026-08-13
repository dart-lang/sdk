// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMixinTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedMixinTest extends PubPackageResolutionTest {
  test_annotatedClass_typedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.mixin()
mixin class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with Foo {}
//             ^^^
// [diag.deprecatedMixin] Mixing in 'Foo' is deprecated.
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin M {}
@Deprecated.mixin()
mixin class Foo = Object with M;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with Foo {}
//             ^^^
// [diag.deprecatedMixin] Mixing in 'Foo' is deprecated.
''');
  }

  test_class() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.mixin()
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with Foo {}
//             ^^^
// [diag.deprecatedMixin] Mixing in 'Foo' is deprecated.
''');
  }

  test_classTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.mixin()
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar = Object with Foo;
//                      ^^^
// [diag.deprecatedMixin] Mixing in 'Foo' is deprecated.
''');
  }

  test_enum() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.mixin()
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar with Foo {
//            ^^^
// [diag.deprecatedMixin] Mixing in 'Foo' is deprecated.
  one, two;
}
''');
  }

  test_insideLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.mixin()
mixin class Foo {}
class Bar with Foo {}
''');
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with Foo {}
''');
  }
}
