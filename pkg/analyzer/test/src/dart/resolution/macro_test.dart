// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MacroResolutionTest);
  });
}

@reflectiveTest
class MacroResolutionTest extends PubPackageResolutionTest
    with ElementsTypesMixin {
  @override
  void setUp() {
    super.setUp();

    newFile('$testPackageLibPath/macro_annotations.dart', content: r'''
library analyzer.macro.annotations;
const observable = 0;
''');
  }

  test_observable() async {
    await assertErrorsInCode(r'''
import 'macro_annotations.dart';

class A {
  @observable
  int _foo = 0;
}

void f(A a) {
  a.foo;
  a.foo = 2;
}
''', [
      error(HintCode.UNUSED_FIELD, 64, 4),
    ]);
  }
}
