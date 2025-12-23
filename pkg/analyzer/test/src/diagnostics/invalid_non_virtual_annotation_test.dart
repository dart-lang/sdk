// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidNonVirtualAnnotationTest);
  });
}

@reflectiveTest
class InvalidNonVirtualAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_instanceMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

abstract class C {
  @nonVirtual
  void m() {}
}
''');
  }

  test_instanceMethod_abstract() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

abstract class C {
  @nonVirtual
  void m();
}
''',
      [error(diag.invalidNonVirtualAnnotation, 56, 10)],
    );
  }

  test_instanceMethod_onExtensionType() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

extension type E(int i) {
  @nonVirtual
  void m() { }
}
''',
      [error(diag.invalidNonVirtualAnnotation, 63, 10)],
    );
  }
}
