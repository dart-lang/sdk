// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:collection/collection.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      GetterNotSubtypeSetterTypesTest_withoutGetterSetterErrorFeature,
    );
    defineReflectiveTests(
      GetterNotSubtypeSetterTypesTest_withGetterSetterErrorFeature,
    );
  });
}

@reflectiveTest
class GetterNotSubtypeSetterTypesTest_withGetterSetterErrorFeature
    extends _GetterNotSubtypeSetterTypesTest {}

@reflectiveTest
class GetterNotSubtypeSetterTypesTest_withoutGetterSetterErrorFeature
    extends _GetterNotSubtypeSetterTypesTest {}

class _GetterNotSubtypeSetterTypesTest extends PubPackageResolutionTest {
  test_class_instance() async {
    await assertNoErrorsInCode('''
class C {
  num get foo => 0;
  set foo(int v) {}
}
''');
  }

  test_class_instance_dynamicGetter() async {
    await assertNoErrorsInCode(r'''
class C {
  get foo => 0;
  set foo(String v) {}
}
''');
  }

  test_class_instance_dynamicSetter() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(v) {}
}
''');
  }

  test_class_instance_field() async {
    await assertNoErrorsInCode('''
class C {
  final num foo = 0;
  set foo(int v) {}
}
''');
  }

  test_class_instance_interfaces() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B {
  set foo(String _) {}
}

abstract class X implements A, B {}
''');
  }

  test_class_instance_private_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  set _foo(String _) {}
}
''', _filterGetterSetterTypeErrors([error(WarningCode.unusedElement, 44, 4)]));
  }

  test_class_instance_private_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
class B {
  set _foo(String _) {}
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';
import 'b.dart';

class X implements A, B {}
''');
  }

  test_class_instance_private_interfaces2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}

class B {
  set _foo(String _) {}
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';

class X implements A, B {}
''');
  }

  test_class_instance_private_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(String _) {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  int get _foo => 0;
}
''', _filterGetterSetterTypeErrors([error(WarningCode.unusedElement, 48, 4)]));
  }

  test_class_instance_sameClass() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(String _) {}
}
''');
  }

  test_class_instance_sameTypes() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(int v) {}
}
''');
  }

  test_class_instance_superGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  set foo(String _) {}
}
''');
  }

  test_class_instance_superSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  set foo(String _) {}
}

class B extends A {
  int get foo => 0;
}
''');
  }

  test_class_static() async {
    await assertNoErrorsInCode('''
class C {
  static num get foo => 0;
  static set foo(int v) {}
}
''');
  }

  test_class_static_field() async {
    await assertNoErrorsInCode('''
class C {
  static final num foo = 0;
  static set foo(int v) {}
}
''');
  }

  test_class_static_sameTypes() async {
    await assertNoErrorsInCode('''
class C {
  static int get foo => 0;
  static set foo(int v) {}
}
''');
  }

  test_enum_instance_mixinGetter_mixinSetter() async {
    await assertNoErrorsInCode('''
mixin M1 {
  num get foo => 0;
}

mixin M2 {
  set foo(int v) {}
}

enum E with M1, M2 {
  v
}
''');
  }

  test_enum_instance_mixinGetter_thisSetter() async {
    await assertNoErrorsInCode('''
mixin M {
  num get foo => 0;
}

enum E with M {
  v;
  set foo(int v) {}
}
''');
  }

  test_enum_instance_superGetter_thisSetter_index() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  set index(String _) {}
}
''');
  }

  test_enum_instance_thisField_thisSetter() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  final num foo = 0;
  set foo(int v) {}
}
''');
  }

  test_enum_instance_thisGetter_thisSetter() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  num get foo => 0;
  set foo(int v) {}
}
''');
  }

  test_enum_static() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  static num get foo => 0;
  static set foo(int v) {}
}
''');
  }

  test_enum_static_field() async {
    await assertNoErrorsInCode('''
enum E {
  foo;
  static set foo(int v) {}
}
''');
  }

  test_enum_static_generatedGetter_thisSetter_index() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  static set values(int _) {}
}
''');
  }

  test_extension_instance() async {
    await assertNoErrorsInCode('''
extension E on Object {
  int get foo => 0;
  set foo(String v) {}
}
''');
  }

  test_extension_static() async {
    await assertNoErrorsInCode('''
extension E on Object {
  static int get foo => 0;
  static set foo(String v) {}
}
''');
  }

  test_extension_static_field() async {
    await assertNoErrorsInCode('''
extension E on Object {
  static final int foo = 0;
  static set foo(String v) {}
}
''');
  }

  test_extensionType_instance() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  int get foo => 0;
  void set foo(String _) {}
}
''');
  }

  test_extensionType_instance_fromImplements() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  void set foo(String _) {}
}

extension type B(int it) implements A {
  int get foo => 0;
}
''');
  }

  test_extensionType_instance_representationField() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  void set it(String _) {}
}
''');
  }

  test_extensionType_static() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  static int get foo => 0;
  static set foo(String v) {}
}
''');
  }

  test_extensionType_static_field() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  static final int foo = 0;
  static set foo(String v) {}
}
''');
  }

  test_topLevel() async {
    await assertNoErrorsInCode('''
int get foo => 0;
set foo(String v) {}
''');
  }

  test_topLevel_dynamicGetter() async {
    await assertNoErrorsInCode(r'''
get foo => 0;
set foo(int v) {}
''');
  }

  test_topLevel_dynamicSetter() async {
    await assertNoErrorsInCode(r'''
int get foo => 0;
set foo(v) {}
''');
  }

  test_topLevel_sameTypes() async {
    await assertNoErrorsInCode(r'''
int get foo => 0;
set foo(int v) {}
''');
  }

  test_topLevel_variable() async {
    await assertNoErrorsInCode('''
final int foo = 0;
set foo(String v) {}
''');
  }

  List<ExpectedError> _filterGetterSetterTypeErrors(
    List<ExpectedError> expectedErrors,
  ) {
    if (experiments.contains(Feature.getter_setter_error.enableString)) {
      return expectedErrors.whereNot((error) {
        return error.code == CompileTimeErrorCode.getterNotSubtypeSetterTypes;
      }).toList();
    } else {
      return expectedErrors;
    }
  }
}
