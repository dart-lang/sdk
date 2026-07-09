// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SealedClassSubtypeOutsideOfLibraryTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SealedClassSubtypeOutsideOfLibraryTest extends PubPackageResolutionTest {
  test_extends_sealed_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class Foo {}
class Bar extends Foo {}
''');
  }

  test_extends_sealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar extends Foo {}
//                ^^^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'Foo' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_extends_sealed_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar extends FooTypedef {}
//                ^^^^^^^^^^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'Foo' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_extends_sealed_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar extends FooTypedef {}
//                ^^^^^^^^^^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'Foo' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_extends_subtypeOfSealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
class Bar extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar2 extends Bar {}
''');
  }

  test_implements_sealed_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class Foo {}
class Bar implements Foo {}
''');
  }

  test_implements_sealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar implements Foo {}
//                   ^^^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'Foo' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_implements_sealed_outside_mixin() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
mixin Bar implements Foo {}
//                   ^^^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'Foo' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_implements_sealed_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar implements FooTypedef {}
//                   ^^^^^^^^^^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'Foo' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_implements_sealed_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar implements FooTypedef {}
//                   ^^^^^^^^^^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'Foo' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_implements_subtypeOfSealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
class Bar implements Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar2 implements Bar {}
''');
  }

  test_induced_base_implements() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
sealed class B extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base class Bar extends B {}
//                     ^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'B' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_induced_final_extends() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
sealed class B extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
final class Bar extends B {}
//                      ^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'B' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_induced_final_implements() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
sealed class B extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
final class Bar implements B {}
//                         ^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'B' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_induced_interface_extends() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface class Foo {}
sealed class B extends Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar extends B {}
//                ^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'B' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_mixinOutside_rawClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with Foo {}
//             ^^^
// [diag.classUsedAsMixin] The class 'Foo' can't be used as a mixin because it's neither a mixin class nor a mixin.
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'Foo' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_on_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
mixin B on A {}
''');
  }

  test_on_inside_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
sealed class B {}
mixin C on A, B {}
''');
  }

  test_on_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
sealed class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
mixin B on A {}
//         ^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'A' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }

  test_on_outside_multiple() async {
    newFile('$testPackageLibPath/a.dart', r'''
sealed class A {}
sealed class B {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
mixin C on A, B {}
//         ^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'A' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
//            ^
// [diag.sealedClassSubtypeOutsideOfLibrary] The class 'B' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.
''');
  }
}
