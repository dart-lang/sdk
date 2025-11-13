// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
@Deprecated.optional()
void f([int p = 0]) {}
''',
      [error(diag.invalidDeprecatedOptionalAnnotation, 1, 19)],
    );
  }

  test_parameter_ofConstructor() async {
    await assertNoErrorsInCode(r'''
class C {
  C([@Deprecated.optional() int? p]);
}
''');
  }

  test_parameter_ofFunctionParameter() async {
    await assertErrorsInCode(
      r'''
void f(void cb([@Deprecated.optional() int? p])) {
  cb();
}
''',
      [error(diag.invalidDeprecatedOptionalAnnotation, 17, 19)],
    );
  }

  test_parameter_ofFunctionTypedParameter() async {
    await assertErrorsInCode(
      r'''
void f(void Function([@Deprecated.optional() int? p]) cb) {
  cb();
}
''',
      [error(diag.invalidDeprecatedOptionalAnnotation, 23, 19)],
    );
  }

  test_parameter_ofLocalFunction() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g([@Deprecated.optional() int? p]) {}
  g();
}
''',
      [error(diag.invalidDeprecatedOptionalAnnotation, 22, 19)],
    );
  }

  test_parameter_ofMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  void m([@Deprecated.optional() int? p]) {}
}
''');
  }

  test_parameter_ofTypedef() async {
    await assertErrorsInCode(
      r'''
typedef Cb = void Function([@Deprecated.optional() int? p]);
void f(Cb cb) {
  cb();
}
''',
      [error(diag.invalidDeprecatedOptionalAnnotation, 29, 19)],
    );
  }

  test_parameter_optionalNamedWithDefault() async {
    await assertNoErrorsInCode(r'''
void f(
  {@Deprecated.optional() int p = 0}
) {}
''');
  }

  test_parameter_optionalNamedWithoutDefault() async {
    await assertNoErrorsInCode(r'''
void f(
  {@Deprecated.optional() int? p}
) {}
''');
  }

  test_parameter_optionalPositionalWithDefault() async {
    await assertNoErrorsInCode(r'''
void f(
  [@Deprecated.optional() int p = 0]
) {}
''');
  }

  test_parameter_optionalPositionalWithoutDefault() async {
    await assertNoErrorsInCode(r'''
void f(
  [@Deprecated.optional() int? p]
) {}
''');
  }

  test_parameter_requiredNamed() async {
    await assertErrorsInCode(
      r'''
void f(
  {@Deprecated.optional() required int? p}
) {}
''',
      [error(diag.invalidDeprecatedOptionalAnnotation, 12, 19)],
    );
  }

  test_parameter_requiredPositional() async {
    await assertErrorsInCode(
      r'''
void f(
  @Deprecated.optional() int? p
) {}
''',
      [error(diag.invalidDeprecatedOptionalAnnotation, 11, 19)],
    );
  }
}
