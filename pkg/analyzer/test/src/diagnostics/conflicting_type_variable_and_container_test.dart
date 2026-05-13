// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingTypeVariableAndClassTest);
    defineReflectiveTests(ConflictingTypeVariableAndEnumTest);
    defineReflectiveTests(ConflictingTypeVariableAndExtensionTest);
    defineReflectiveTests(ConflictingTypeVariableAndExtensionTypeTest);
    defineReflectiveTests(ConflictingTypeVariableAndMixinTest);
  });
}

@reflectiveTest
class ConflictingTypeVariableAndClassTest extends PubPackageResolutionTest {
  test_conflict_on_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class T<T> {}
//      ^
// [diag.conflictingTypeVariableAndClass] 'T' can't be used to name both a type parameter and the class in which the type parameter is defined.
''');
  }
}

@reflectiveTest
class ConflictingTypeVariableAndEnumTest extends PubPackageResolutionTest {
  test_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E<E> {
//     ^
// [diag.conflictingTypeVariableAndEnum] 'E' can't be used to name both a type parameter and the enum in which the type parameter is defined.
  v
}
''');
  }
}

@reflectiveTest
class ConflictingTypeVariableAndExtensionTest extends PubPackageResolutionTest {
  test_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension T<T> on String {}
//          ^
// [diag.conflictingTypeVariableAndExtension] 'T' can't be used to name both a type parameter and the extension in which the type parameter is defined.
''');
  }
}

@reflectiveTest
class ConflictingTypeVariableAndExtensionTypeTest
    extends PubPackageResolutionTest {
  test_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type T<T>(int it) {}
//               ^
// [diag.conflictingTypeVariableAndExtensionType] 'T' can't be used to name both a type parameter and the extension type in which the type parameter is defined.
''');
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMixinTest extends PubPackageResolutionTest {
  test_conflict_on_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin T<T> {}
//      ^
// [diag.conflictingTypeVariableAndMixin] 'T' can't be used to name both a type parameter and the mixin in which the type parameter is defined.
''');
  }
}
