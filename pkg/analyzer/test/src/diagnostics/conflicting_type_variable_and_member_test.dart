// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingTypeVariableAndMemberClassTest);
    defineReflectiveTests(ConflictingTypeVariableAndMemberEnumTest);
    defineReflectiveTests(ConflictingTypeVariableAndMemberExtensionTest);
    defineReflectiveTests(ConflictingTypeVariableAndMemberExtensionTypeTest);
    defineReflectiveTests(ConflictingTypeVariableAndMemberMixinTest);
  });
}

@reflectiveTest
class ConflictingTypeVariableAndMemberClassTest
    extends PubPackageResolutionTest {
  test_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberClass] 'T' can't be used to name both a type parameter and a member in this class.
  A.T();
}
''');
  }

  test_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberClass] 'T' can't be used to name both a type parameter and a member in this class.
  var T;
}
''');
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberClass] 'T' can't be used to name both a type parameter and a member in this class.
  get T => null;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberClass] 'T' can't be used to name both a type parameter and a member in this class.
  T() {}
}
''');
  }

  test_method_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberClass] 'T' can't be used to name both a type parameter and a member in this class.
  static T() {}
}
''');
  }

  test_method_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<_> {
  _() {}
//^
// [diag.unusedElement] The declaration '_' isn't referenced.
}
''');
  }

  test_method_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A<_> {
//      ^
// [diag.conflictingTypeVariableAndMemberClass] '_' can't be used to name both a type parameter and a member in this class.
  _() {}
//^
// [diag.unusedElement] The declaration '_' isn't referenced.
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberClass] 'T' can't be used to name both a type parameter and a member in this class.
  set T(x) {}
}
''');
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberEnumTest
    extends PubPackageResolutionTest {
  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A<T> {
//     ^
// [diag.conflictingTypeVariableAndMemberEnum] 'T' can't be used to name both a type parameter and a member in this enum.
  v;
  get T => null;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A<T> {
//     ^
// [diag.conflictingTypeVariableAndMemberEnum] 'T' can't be used to name both a type parameter and a member in this enum.
  v;
  void T() {}
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A<T> {
//     ^
// [diag.conflictingTypeVariableAndMemberEnum] 'T' can't be used to name both a type parameter and a member in this enum.
  v;
  set T(x) {}
}
''');
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberExtensionTest
    extends PubPackageResolutionTest {
  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A<T> on String {
//          ^
// [diag.conflictingTypeVariableAndMemberExtension] 'T' can't be used to name both a type parameter and a member in this extension.
  get T => null;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A<T> on String {
//          ^
// [diag.conflictingTypeVariableAndMemberExtension] 'T' can't be used to name both a type parameter and a member in this extension.
  T() {}
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A<T> on String {
//          ^
// [diag.conflictingTypeVariableAndMemberExtension] 'T' can't be used to name both a type parameter and a member in this extension.
  set T(x) {}
}
''');
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberExtensionTypeTest
    extends PubPackageResolutionTest {
  test_constructor_explicit() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {
//               ^
// [diag.conflictingTypeVariableAndMemberExtensionType] 'T' can't be used to name both a type parameter and a member in this extension type.
  A.T(int it) : this(it);
}
''');
  }

  test_constructor_primary() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>.T(int it) {}
//               ^
// [diag.conflictingTypeVariableAndMemberExtensionType] 'T' can't be used to name both a type parameter and a member in this extension type.
''');
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {
//               ^
// [diag.conflictingTypeVariableAndMemberExtensionType] 'T' can't be used to name both a type parameter and a member in this extension type.
  get T => null;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {
//               ^
// [diag.conflictingTypeVariableAndMemberExtensionType] 'T' can't be used to name both a type parameter and a member in this extension type.
  T() {}
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {
//               ^
// [diag.conflictingTypeVariableAndMemberExtensionType] 'T' can't be used to name both a type parameter and a member in this extension type.
  set T(x) {}
}
''');
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberMixinTest
    extends PubPackageResolutionTest {
  test_field() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberMixin] 'T' can't be used to name both a type parameter and a member in this mixin.
  var T;
}
''');
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberMixin] 'T' can't be used to name both a type parameter and a member in this mixin.
  get T => null;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberMixin] 'T' can't be used to name both a type parameter and a member in this mixin.
  T() {}
}
''');
  }

  test_method_static() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberMixin] 'T' can't be used to name both a type parameter and a member in this mixin.
  static T() {}
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M<T> {
//      ^
// [diag.conflictingTypeVariableAndMemberMixin] 'T' can't be used to name both a type parameter and a member in this mixin.
  set T(x) {}
}
''');
  }
}
