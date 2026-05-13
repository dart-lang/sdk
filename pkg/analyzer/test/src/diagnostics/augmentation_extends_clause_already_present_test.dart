// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationExtendsClauseAlreadyPresentTest);
  });
}

@reflectiveTest
class AugmentationExtendsClauseAlreadyPresentTest
    extends PubPackageResolutionTest {
  test_alreadyPresent() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {}
augment class B extends A {}
''',
      [
        error(
          diag.augmentationExtendsClauseAlreadyPresent,
          49,
          7,
          contextMessages: [message(testFile, 18, 1)],
        ),
      ],
    );
  }

  test_alreadyPresent2() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {}
augment class B {}
augment class B extends A {}
''',
      [
        error(
          diag.augmentationExtendsClauseAlreadyPresent,
          68,
          7,
          contextMessages: [message(testFile, 18, 1)],
        ),
      ],
    );
  }

  test_notPresent() async {
    await assertNoErrorsInCode(r'''
class A {}

class B {}
augment class B extends A {}
''');
  }
}
