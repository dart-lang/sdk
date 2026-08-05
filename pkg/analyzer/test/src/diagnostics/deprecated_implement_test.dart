// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedImplementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedImplementTest extends PubPackageResolutionTest {
  test_annotatedClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar implements Foo {}
//                   ^^^
// [diag.deprecatedImplement] Implementing 'Foo' is deprecated.
''');
  }

  test_annotatedClass_indirect() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
class Bar extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Baz implements Bar {}
''');
  }

  test_annotatedClass_typedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar implements Foo2 {}
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo = Object with M;
mixin M {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar implements Foo {}
//                   ^^^
// [diag.deprecatedImplement] Implementing 'Foo' is deprecated.
''');
  }

  test_classTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
mixin M {}
class Bar = Object with M implements Foo;
//                                   ^^^
// [diag.deprecatedImplement] Implementing 'Foo' is deprecated.
''');
  }

  test_enum() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar implements Foo { one; }
//                  ^^^
// [diag.deprecatedImplement] Implementing 'Foo' is deprecated.
''');
  }

  test_insideLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
class Foo {}
class Bar implements Foo {}
''');
  }

  test_mixinImplementsClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
mixin Bar implements Foo {}
//                   ^^^
// [diag.deprecatedImplement] Implementing 'Foo' is deprecated.
''');
  }

  test_mixinOnClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
mixin Bar on Foo {}
//           ^^^
// [diag.deprecatedImplement] Implementing 'Foo' is deprecated.
''');
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar implements Foo {}
''');
  }
}
