// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingRequiredParamTest);
  });
}

@reflectiveTest
class MissingRequiredParamTest extends DriverResolutionTest with PackageMixin {
  test_constructorParam_missingArgument() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  C({@Required('must specify an `a`') int a}) {}
}
main() {
  new C();
}
''', [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
  }

  test_constructorParam_noReason() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C();
}
''', [HintCode.MISSING_REQUIRED_PARAM]);
  }

  test_constructorParam_nullReason() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required(null) int a}) {}
}

main() {
  new C();
}
''', [HintCode.MISSING_REQUIRED_PARAM]);
  }

  test_constructorParam_argumentGiven() async {
    addMetaPackage();
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

  test_constructorParam_redirectingConstructorCall() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  C({@required int x});
  C.named() : this();
}
''', [HintCode.MISSING_REQUIRED_PARAM]);
  }

  test_requiredConstructor_paramSuperCall() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

class D extends C {
  D() : super();
}
''', [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
  }

  test_functionParam() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

void f({@Required('must specify an `a`') int a}) {}

main() {
  f();
}
''', [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
  }

  test_methodParam() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
f() {
  new A().m();
}
''', [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
  }

  test_methodParam_inOtherLib() async {
    addMetaPackage();
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

    await _resolveTestFile('/a_lib.dart');
    await _resolveTestFile('/test.dart');
    assertTestErrors([HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
  }

  test_typedef_functionParam() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

String test(C c) => c.m()();

typedef String F({@required String x});

class C {
  F m() => ({@required String x}) => null;
}
''', [HintCode.MISSING_REQUIRED_PARAM]);
  }

  /// Resolve the test file at [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveTestFile(String path) async {
    result = await resolveFile(convertPath(path));
  }
}
