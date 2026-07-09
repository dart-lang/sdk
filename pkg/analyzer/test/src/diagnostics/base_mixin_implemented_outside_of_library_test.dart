// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BaseMixinImplementedOutsideOfLibraryTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BaseMixinImplementedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin Foo {}
base class Bar implements Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base class Bar implements Foo {}
//                        ^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }

  test_class_outside_viaExtends() async {
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
base mixin A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
''',
      testFile: r'''
import 'a.dart';

sealed class B extends Object with A {}
class C implements B {}
//                 ^
// [diag.baseMixinImplementedOutsideOfLibrary][context 1] The mixin 'A' can't be implemented outside of its library because it's a base mixin.
''',
    });
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base class Bar implements FooTypedef {}
//                        ^^^^^^^^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
base class Bar implements FooTypedef {}
//                        ^^^^^^^^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }

  test_enum_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin Foo {}
enum Bar implements Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar implements Foo { bar }
//                  ^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar implements FooTypedef { bar }
//                  ^^^^^^^^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar implements FooTypedef { bar }
//                  ^^^^^^^^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }

  test_mixin_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin Foo {}
base mixin Bar implements Foo {}
''');
  }

  test_mixin_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base mixin Bar implements Foo {}
//                        ^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }

  test_mixin_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base mixin Bar implements FooTypedef {}
//                        ^^^^^^^^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }

  test_mixin_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
base mixin Bar implements FooTypedef {}
//                        ^^^^^^^^^^
// [diag.baseMixinImplementedOutsideOfLibrary] The mixin 'Foo' can't be implemented outside of its library because it's a base mixin.
''');
  }
}
