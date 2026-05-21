// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInExtensionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SuperInExtensionTest extends PubPackageResolutionTest {
  test_binaryOperator_inMethod() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  int plusOne() => super + 1;
//                 ^^^^^
// [diag.superInExtension] The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.
}
''');
  }

  test_binaryOperator_withGenericExtendedType() async {
    await resolveTestCodeWithDiagnostics('''
extension <T> on T {
  f() {
//^
// [diag.unusedElement] The declaration 'f' isn't referenced.
    super + 1;
//  ^^^^^
// [diag.superInExtension] The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.
  }
}
''');
  }

  test_getter_inSetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  int get value => 0;
  set value(int newValue) {}
}
extension E on C {
  set sign(int sign) {
    value = super.value * sign;
//          ^^^^^
// [diag.superInExtension] The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.
  }
}
''');
  }

  test_indexOperator_inMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  int operator[](int i) => 0;
}
extension E on C {
  int at(int i) => super[i];
//                 ^^^^^
// [diag.superInExtension] The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.
}
''');
  }

  test_method_inGetter() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  String get displayText => super.toString();
//                          ^^^^^
// [diag.superInExtension] The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.
}
''');
  }

  test_methodInvocation_field_instance_late() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  late final v = super.foo();
//           ^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
//               ^^^^^
// [diag.superInExtension] The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.
}
''');
  }

  test_methodInvocation_method_instance() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  void foo() {
    super.foo();
//  ^^^^^
// [diag.superInExtension] The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.
  }
}
''');
  }

  test_prefixOperator_inGetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C operator-() => this;
}
extension E on C {
  C get negated => -super;
//                  ^^^^^
// [diag.superInExtension] The 'super' keyword can't be used in an extension because an extension doesn't have a superclass.
}
''');
  }
}
