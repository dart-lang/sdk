// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingRequiredParamTest);
    defineReflectiveTests(MissingRequiredParamWithNnbdTest);
  });
}

@reflectiveTest
class MissingRequiredParamTest extends DriverResolutionTest with PackageMixin {
  @override
  setUp() {
    super.setUp();
    addMetaPackage();
  }

  test_constructor_argumentGiven() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C(a: 2);
}
''');
  }

  test_constructor_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  final int a;
  C({@required this.a});
}

main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 102, 1),
    ]);
  }

  test_constructor_hasReason() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  C({@Required('must specify an `a`') int a}) {}
}
main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 109, 1),
    ]);
  }

  test_constructor_noReason() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 88, 1),
    ]);
  }

  test_constructor_noReason_generic() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C<T> {
  C({@required int a}) {}
}

main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 91, 1),
    ]);
  }

  test_constructor_nullReason() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required(null) int a}) {}
}

main() {
  new C();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 94, 1),
    ]);
  }

  test_constructor_redirectingConstructorCall() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  C({@required int x});
  C.named() : this();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 81, 6),
    ]);
  }

  test_constructor_superCall() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

class D extends C {
  D() : super();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 124, 7),
    ]);
  }

  test_function() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

void f({@Required('must specify an `a`') int a}) {}

main() {
  f();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 98, 1),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
f() {
  new A().m();
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 115, 1),
    ]);
  }

  test_method_generic() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A<T> {
  void m<U>(U a, {@Required('must specify an `b`') int b}) {}
}
f() {
  new A<double>().m(true);
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 135, 1),
    ]);
  }

  test_method_inOtherLib() async {
    newFile('/a_lib.dart', content: r'''
library a_lib;
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
''');
    newFile('/test.dart', content: r'''
import "a_lib.dart";
f() {
  new A().m();
}
''');

    await _resolveFile('/a_lib.dart');
    await _resolveFile('/test.dart', [
      error(HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS, 37, 1),
    ]);
  }

  @FailingTest(reason: r'''
MISSING_REQUIRED_PARAM cannot be reported here with summary2, because
the return type of `C.m` is a structural FunctionType, which does
not know its elements, and does not know that there was a parameter
marked `@required`. There is exactly one such typedef in Flutter.
''')
  test_typedef_function() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

String test(C c) => c.m()();

typedef String F({@required String x});

class C {
  F m() => ({@required String x}) => null;
}
''', [
      error(HintCode.MISSING_REQUIRED_PARAM, 54, 7),
    ]);
  }

  /// Resolve the file with the given [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveFile(
    String path, [
    List<ExpectedError> expectedErrors = const [],
  ]) async {
    result = await resolveFile(convertPath(path));
    assertErrorsInResolvedUnit(result, expectedErrors);
  }
}

@reflectiveTest
class MissingRequiredParamWithNnbdTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_constructor_argumentGiven() async {
    await assertNoErrorsInCode(r'''
class C {
  C({required int a}) {}
}

main() {
  new C(a: 2);
}
''');
  }

  test_constructor_missingArgument() async {
    await assertErrorsInCode(r'''
class C {
  C({required int a}) {}
}
main() {
  new C();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 52, 1),
    ]);
  }

  test_constructor_redirectingConstructorCall() async {
    await assertErrorsInCode(r'''
class C {
  C({required int x});
  C.named() : this();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 47, 6),
    ]);
  }

  test_constructor_superCall() async {
    await assertErrorsInCode(r'''
class C {
  C({required int a}) {}
}

class D extends C {
  D() : super();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 66, 7),
    ]);
  }

  test_function() async {
    await assertErrorsInCode(r'''
void f({required int a}) {}

main() {
  f();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 40, 1),
    ]);
  }

  test_functionInvocation() async {
    await assertErrorsInCode(r'''
void Function({required int a}) f() => throw '';
g() {
  f()();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 57, 5),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class A {
  void m({required int a}) {}
}
f() {
  new A().m();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 58, 1),
    ]);
  }

  test_method_inOtherLib() async {
    newFile('/test/lib/a_lib.dart', content: r'''
class A {
  void m({required int a}) {}
}
''');
    await assertErrorsInCode(r'''
import "a_lib.dart";
f() {
  new A().m();
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 37, 1),
    ]);
  }

  test_method_legacy() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void foo({required int a}) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.7
import "a.dart";

f() {
  A().foo();
}
''');
  }

  test_typedef_function() async {
    await assertErrorsInCode(r'''
String test(C c) => c.m()();

typedef String F({required String x});

class C {
  F m() => ({required String x}) => throw '';
}
''', [
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 20, 7),
    ]);
  }
}
