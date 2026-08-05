// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDeprecatedOptionalAnnotationTest);
  });
}

@reflectiveTest
class InvalidDeprecatedOptionalAnnotationTest extends PubPackageResolutionTest {
  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.optional()
// [diag.invalidDeprecatedOptionalAnnotation][column 2][length 19] The annotation '@Deprecated.optional' can only be applied to optional parameters.
void f([int p = 0]) {}
''');
  }

  test_parameter_ofConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C([@Deprecated.optional() int? p]);
}
''');
  }

  test_parameter_ofFunctionParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void cb([@Deprecated.optional() int? p])) {
//               ^^^^^^^^^^^^^^^^^^^
// [diag.invalidDeprecatedOptionalAnnotation] The annotation '@Deprecated.optional' can only be applied to optional parameters.
  cb();
}
''');
  }

  test_parameter_ofFunctionTypedParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function([@Deprecated.optional() int? p]) cb) {
//                     ^^^^^^^^^^^^^^^^^^^
// [diag.invalidDeprecatedOptionalAnnotation] The annotation '@Deprecated.optional' can only be applied to optional parameters.
  cb();
}
''');
  }

  test_parameter_ofLocalFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g([@Deprecated.optional() int? p]) {}
//         ^^^^^^^^^^^^^^^^^^^
// [diag.invalidDeprecatedOptionalAnnotation] The annotation '@Deprecated.optional' can only be applied to optional parameters.
  g();
}
''');
  }

  test_parameter_ofMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void m([@Deprecated.optional() int? p]) {}
}
''');
  }

  test_parameter_ofTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Cb = void Function([@Deprecated.optional() int? p]);
//                           ^^^^^^^^^^^^^^^^^^^
// [diag.invalidDeprecatedOptionalAnnotation] The annotation '@Deprecated.optional' can only be applied to optional parameters.
void f(Cb cb) {
  cb();
}
''');
  }

  test_parameter_optionalNamedWithDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(
  {@Deprecated.optional() int p = 0}
) {}
''');
  }

  test_parameter_optionalNamedWithoutDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(
  {@Deprecated.optional() int? p}
) {}
''');
  }

  test_parameter_optionalPositionalWithDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(
  [@Deprecated.optional() int p = 0]
) {}
''');
  }

  test_parameter_optionalPositionalWithoutDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(
  [@Deprecated.optional() int? p]
) {}
''');
  }

  test_parameter_requiredNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(
  {@Deprecated.optional() required int? p}
//  ^^^^^^^^^^^^^^^^^^^
// [diag.invalidDeprecatedOptionalAnnotation] The annotation '@Deprecated.optional' can only be applied to optional parameters.
) {}
''');
  }

  test_parameter_requiredPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(
  @Deprecated.optional() int? p
// ^^^^^^^^^^^^^^^^^^^
// [diag.invalidDeprecatedOptionalAnnotation] The annotation '@Deprecated.optional' can only be applied to optional parameters.
) {}
''');
  }
}
