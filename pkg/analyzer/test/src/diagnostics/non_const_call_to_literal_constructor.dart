// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstCallToLiteralConstructorTest);
  });
}

@reflectiveTest
class NonConstCallToLiteralConstructorTest extends DriverResolutionTest
    with PackageMixin {
  @override
  void setUp() {
    super.setUp();
    addMetaPackage();
  }

  test_nonConstContext() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
void main() {
  var a = A();
}
''', [HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR]);
  }

  test_usingNew() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
void main() {
  var a = new A();
}
''', [HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW]);
  }

  test_namedConstructor() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A.named();
}
void main() {
  var a = A.named();
}
''', [HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR]);
  }

  test_constConstructor() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
''');
  }

  test_constCreation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}

void main() {
  const a = const A();
}
''');
  }

  test_constContextCreation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}

void main() {
  const a = A();
}
''');
  }

  test_unconstableCreation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A(List list);
}

void main() {
  var a = A(new List());
}
''');
  }
}
