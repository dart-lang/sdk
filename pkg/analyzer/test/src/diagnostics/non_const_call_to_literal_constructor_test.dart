// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstCallToLiteralConstructorTest);
  });
}

@reflectiveTest
class NonConstCallToLiteralConstructorTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
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

  test_constContextCreation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
const a = A();
''');
  }

  test_constCreation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
const a = const A();
''');
  }

  test_constCreation_extensionType() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
extension type const E(int i) { 
  @literal
  const E.zero(): this(0);
}
E e = const E.zero();
''');
  }

  test_dotShorthand_namedConstructor() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A.named();
}
A a = .named();
''',
      [error(WarningCode.nonConstCallToLiteralConstructor, 81, 8)],
    );
  }

  test_dotShorthand_unnamedConstructor() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
A a = .new();
''',
      [error(WarningCode.nonConstCallToLiteralConstructor, 75, 6)],
    );
  }

  test_namedConstructor() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A.named();
}
var a = A.named();
''',
      [error(WarningCode.nonConstCallToLiteralConstructor, 83, 9)],
    );
  }

  test_nonConstContext() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
var a = A();
''',
      [error(WarningCode.nonConstCallToLiteralConstructor, 77, 3)],
    );
  }

  test_unconstableCreation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A(List list);
}
var a = A(new List.filled(1, ''));
''');
  }

  test_usingNew() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
var a = new A();
''',
      [error(WarningCode.nonConstCallToLiteralConstructorUsingNew, 77, 7)],
    );
  }

  test_usingNew_extensionType() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
extension type const E(int i) { 
  @literal
  const E.zero(): this(0);
}
E e = E.zero();
''',
      [error(WarningCode.nonConstCallToLiteralConstructor, 112, 8)],
    );
  }
}
