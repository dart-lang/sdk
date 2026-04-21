// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationOfMixinApplicationClassTest);
  });
}

@reflectiveTest
class AugmentationOfMixinApplicationClassTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin M {}
class C = A with M;
augment class C {}
''',
      [
        error(
          diag.augmentationOfMixinApplicationClass,
          42,
          7,
          contextMessages: [message(testFile, 28, 1)],
        ),
      ],
    );
  }
}
