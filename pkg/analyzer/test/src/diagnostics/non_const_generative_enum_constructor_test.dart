// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstGenerativeEnumConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstGenerativeEnumConstructorTest extends PubPackageResolutionTest {
  test_factoryHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named();
  const E.named();
  factory () => v;
}
''');
  }

  test_generative_const_newHead_named() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named();
  const new named();
}
''');
  }

  test_generative_const_newHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const new ();
}
''');
  }

  test_generative_const_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
}
''');
  }

  test_generative_nonConst_newHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  new ();
}
''');
  }

  test_generative_nonConst_typeName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.named();
  E.named();
}
''');
  }

  test_generative_nonConst_typeName_named_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
enum E {
  v.named();
  E.named();
//^^^^^^^
// [diag.nonConstGenerativeEnumConstructor] Generative enum constructors must be 'const'.
}
''');
  }

  test_generative_nonConst_typeName_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  E();
}
''');
  }

  test_generative_nonConst_typeName_unnamed_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
enum E {
  v;
  E();
//^
// [diag.nonConstGenerativeEnumConstructor] Generative enum constructors must be 'const'.
}
''');
  }

  test_typeName_factory_named() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.foo() => v;
}
''');
  }
}
