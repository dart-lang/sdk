// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
class A<T> {
  A.T();
}
''',
      [error(diag.conflictingTypeVariableAndMemberClass, 8, 1)],
    );
  }

  test_field() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  var T;
}
''',
      [error(diag.conflictingTypeVariableAndMemberClass, 8, 1)],
    );
  }

  test_getter() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  get T => null;
}
''',
      [error(diag.conflictingTypeVariableAndMemberClass, 8, 1)],
    );
  }

  test_method() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  T() {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberClass, 8, 1)],
    );
  }

  test_method_static() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  static T() {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberClass, 8, 1)],
    );
  }

  test_method_wildcard() async {
    await assertErrorsInCode(
      r'''
class A<_> {
  _() {}
}
''',
      [error(diag.unusedElement, 15, 1)],
    );
  }

  test_method_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A<_> {
  _() {}
}
''',
      [
        error(diag.conflictingTypeVariableAndMemberClass, 52, 1),
        error(diag.unusedElement, 59, 1),
      ],
    );
  }

  test_setter() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  set T(x) {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberClass, 8, 1)],
    );
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberEnumTest
    extends PubPackageResolutionTest {
  test_getter() async {
    await assertErrorsInCode(
      r'''
enum A<T> {
  v;
  get T => null;
}
''',
      [error(diag.conflictingTypeVariableAndMemberEnum, 7, 1)],
    );
  }

  test_method() async {
    await assertErrorsInCode(
      r'''
enum A<T> {
  v;
  void T() {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberEnum, 7, 1)],
    );
  }

  test_setter() async {
    await assertErrorsInCode(
      r'''
enum A<T> {
  v;
  set T(x) {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberEnum, 7, 1)],
    );
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberExtensionTest
    extends PubPackageResolutionTest {
  test_getter() async {
    await assertErrorsInCode(
      r'''
extension A<T> on String {
  get T => null;
}
''',
      [error(diag.conflictingTypeVariableAndMemberExtension, 12, 1)],
    );
  }

  test_method() async {
    await assertErrorsInCode(
      r'''
extension A<T> on String {
  T() {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberExtension, 12, 1)],
    );
  }

  test_setter() async {
    await assertErrorsInCode(
      r'''
extension A<T> on String {
  set T(x) {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberExtension, 12, 1)],
    );
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberExtensionTypeTest
    extends PubPackageResolutionTest {
  test_constructor_explicit() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {
  A.T(int it) : this(it);
}
''',
      [error(diag.conflictingTypeVariableAndMemberExtensionType, 17, 1)],
    );
  }

  test_constructor_primary() async {
    await assertErrorsInCode(
      r'''
extension type A<T>.T(int it) {}
''',
      [error(diag.conflictingTypeVariableAndMemberExtensionType, 17, 1)],
    );
  }

  test_getter() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {
  get T => null;
}
''',
      [error(diag.conflictingTypeVariableAndMemberExtensionType, 17, 1)],
    );
  }

  test_method() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {
  T() {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberExtensionType, 17, 1)],
    );
  }

  test_setter() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {
  set T(x) {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberExtensionType, 17, 1)],
    );
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberMixinTest
    extends PubPackageResolutionTest {
  test_field() async {
    await assertErrorsInCode(
      r'''
mixin M<T> {
  var T;
}
''',
      [error(diag.conflictingTypeVariableAndMemberMixin, 8, 1)],
    );
  }

  test_getter() async {
    await assertErrorsInCode(
      r'''
mixin M<T> {
  get T => null;
}
''',
      [error(diag.conflictingTypeVariableAndMemberMixin, 8, 1)],
    );
  }

  test_method() async {
    await assertErrorsInCode(
      r'''
mixin M<T> {
  T() {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberMixin, 8, 1)],
    );
  }

  test_method_static() async {
    await assertErrorsInCode(
      r'''
mixin M<T> {
  static T() {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberMixin, 8, 1)],
    );
  }

  test_setter() async {
    await assertErrorsInCode(
      r'''
mixin M<T> {
  set T(x) {}
}
''',
      [error(diag.conflictingTypeVariableAndMemberMixin, 8, 1)],
    );
  }
}
