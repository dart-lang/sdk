// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedExtendTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedExtendTest extends PubPackageResolutionTest {
  test_annotatedClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar extends Foo {}
//                ^^^
// [diag.deprecatedExtend] Extending 'Foo' is deprecated.
''');
  }

  test_annotatedClass_indirect() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo {}
class Bar extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Baz extends Bar {}
''');
  }

  test_annotatedClass_typedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar extends Foo2 {}
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo = Object with M;
mixin M {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar extends Foo {}
//                ^^^
// [diag.deprecatedExtend] Extending 'Foo' is deprecated.
''');
  }

  test_classTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
mixin M {}
class Bar = Foo with M;
//          ^^^
// [diag.deprecatedExtend] Extending 'Foo' is deprecated.
''');
  }

  test_insideLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.extend()
class Foo {}
class Bar extends Foo {}
''');
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar extends Foo {}
''');
  }
}
