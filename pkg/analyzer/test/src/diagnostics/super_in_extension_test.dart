// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInExtensionTest);
  });
}

@reflectiveTest
class SuperInExtensionTest extends PubPackageResolutionTest {
  test_binaryOperator_inMethod() async {
    await assertErrorsInCode(
      '''
extension E on int {
  int plusOne() => super + 1;
}
''',
      [error(diag.superInExtension, 40, 5)],
    );
  }

  test_binaryOperator_withGenericExtendedType() async {
    await assertErrorsInCode(
      '''
extension <T> on T {
  f() {
    super + 1;
  }
}
''',
      [error(diag.unusedElement, 23, 1), error(diag.superInExtension, 33, 5)],
    );
  }

  test_getter_inSetter() async {
    await assertErrorsInCode(
      '''
class C {
  int get value => 0;
  set value(int newValue) {}
}
extension E on C {
  set sign(int sign) {
    value = super.value * sign;
  }
}
''',
      [error(diag.superInExtension, 117, 5)],
    );
  }

  test_indexOperator_inMethod() async {
    await assertErrorsInCode(
      '''
class C {
  int operator[](int i) => 0;
}
extension E on C {
  int at(int i) => super[i];
}
''',
      [error(diag.superInExtension, 80, 5)],
    );
  }

  test_method_inGetter() async {
    await assertErrorsInCode(
      '''
extension E on int {
  String get displayText => super.toString();
}
''',
      [error(diag.superInExtension, 49, 5)],
    );
  }

  test_methodInvocation_field_instance_late() async {
    await assertErrorsInCode(
      '''
extension E on int {
  late final v = super.foo();
}
''',
      [
        error(diag.extensionDeclaresInstanceField, 34, 1),
        error(diag.superInExtension, 38, 5),
      ],
    );
  }

  test_methodInvocation_method_instance() async {
    await assertErrorsInCode(
      '''
extension E on int {
  void foo() {
    super.foo();
  }
}
''',
      [error(diag.superInExtension, 40, 5)],
    );
  }

  test_prefixOperator_inGetter() async {
    await assertErrorsInCode(
      '''
class C {
  C operator-() => this;
}
extension E on C {
  C get negated => -super;
}
''',
      [error(diag.superInExtension, 76, 5)],
    );
  }
}
