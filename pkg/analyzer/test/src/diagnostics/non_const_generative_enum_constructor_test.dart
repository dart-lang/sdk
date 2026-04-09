// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstGenerativeEnumConstructorTest);
  });
}

@reflectiveTest
class NonConstGenerativeEnumConstructorTest extends PubPackageResolutionTest {
  test_factoryHead_unnamed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.named();
  const E.named();
  factory () => v;
}
''');
  }

  test_generative_const_newHead_named() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.named();
  const new named();
}
''');
  }

  test_generative_const_newHead_unnamed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const new ();
}
''');
  }

  test_generative_const_typeName() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E();
}
''');
  }

  test_generative_nonConst_newHead_unnamed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  new ();
}
''');
  }

  test_generative_nonConst_typeName_named() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.named();
  E.named();
}
''');
  }

  test_generative_nonConst_typeName_named_language310() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.10
enum E {
  v.named();
  E.named();
}
''',
      [error(diag.nonConstGenerativeEnumConstructor, 40, 7)],
    );
  }

  test_generative_nonConst_typeName_unnamed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  E();
}
''');
  }

  test_generative_nonConst_typeName_unnamed_language310() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.10
enum E {
  v;
  E();
}
''',
      [error(diag.nonConstGenerativeEnumConstructor, 32, 1)],
    );
  }

  test_typeName_factory_named() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  factory E.foo() => v;
}
''');
  }
}
