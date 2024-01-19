// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumConstantInvokesFactoryConstructorTest);
  });
}

@reflectiveTest
class EnumConstantInvokesFactoryConstructorTest
    extends PubPackageResolutionTest {
  test_factory_named() async {
    await assertErrorsInCode('''
enum E {
  e1,
  e2.named();

  const E();
  const factory E.named() = ET.named;
}

extension type const ET(E it) implements E {
  const ET.named() : this(E.e1);
}
''', [
      error(CompileTimeErrorCode.ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR, 20,
          5),
    ]);
  }

  test_factory_unnamed() async {
    await assertErrorsInCode('''
enum E {
  e1.primary(),
  e2;

  const E.primary();
  const factory E() = ET.named;
}

extension type const ET(E it) implements E {
  const ET.named() : this(E.e1);
}
''', [
      error(CompileTimeErrorCode.ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR, 27,
          2),
    ]);
  }

  test_factory_unnamed_withArguments() async {
    await assertErrorsInCode('''
enum E {
  e1.primary(),
  e2();

  const E.primary();
  const factory E() = ET.named;
}

extension type const ET(E it) implements E {
  const ET.named() : this(E.e1);
}
''', [
      error(CompileTimeErrorCode.ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR, 27,
          2),
    ]);
  }
}
