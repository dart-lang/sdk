// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedOptionalTest);
  });
}

@reflectiveTest
class DeprecatedOptionalTest extends PubPackageResolutionTest {
  test_argumentGiven() async {
    await assertNoErrorsInCode(r'''
void f([@Deprecated.optional() int? p]) {}

void g() {
  f(1);
}
''');
  }

  test_argumentGiven_named() async {
    await assertNoErrorsInCode(r'''
void f({@Deprecated.optional() int? p}) {}

void g() {
  f(p: 1);
}
''');
  }

  test_argumentOmitted() async {
    await assertErrorsInCode(
      r'''
void f([@Deprecated.optional() int? p]) {}

void g() {
  f();
}
''',
      [error(WarningCode.deprecatedOptional, 57, 1)],
    );
  }

  test_argumentOmitted_dotShorthand() async {
    await assertErrorsInCode(
      r'''
class C {
  static C m({@Deprecated.optional() int? p}) => C();
}

C f() {
  return .m();
}
''',
      [error(WarningCode.deprecatedOptional, 85, 1)],
    );
  }

  test_argumentOmitted_dotShorthandConstructor() async {
    await assertErrorsInCode(
      r'''
class C {
  C({@Deprecated.optional() int? p});
}

C f() {
  return .new();
}
''',
      [error(WarningCode.deprecatedOptional, 69, 3)],
    );
  }

  test_argumentOmitted_instanceCreation() async {
    await assertErrorsInCode(
      r'''
class C {
  C([@Deprecated.optional() int? p]);
}

void f() {
  C();
}
''',
      [error(WarningCode.deprecatedOptional, 64, 1)],
    );
  }

  test_argumentOmitted_methodInvocation() async {
    await assertErrorsInCode(
      r'''
class C {
  void m({@Deprecated.optional() int? p}) {}
}

void f(C c) {
  c.m();
}
''',
      [error(WarningCode.deprecatedOptional, 76, 1)],
    );
  }

  test_argumentOmitted_named() async {
    await assertErrorsInCode(
      r'''
void f({@Deprecated.optional() int? p}) {}

void g() {
  f();
}
''',
      [error(WarningCode.deprecatedOptional, 57, 1)],
    );
  }

  test_argumentOmitted_override() async {
    await assertNoErrorsInCode(r'''
class C {
  void m({@Deprecated.optional() int? p}) {}
}

class D extends C {
  @override
  void m({int? p}) {}
}

void g(D d) {
  d.m();
}
''');
  }

  test_noAnnotation() async {
    await assertNoErrorsInCode(r'''
void f([int? p]) {}

void g() {
  f();
}
''');
  }
}
