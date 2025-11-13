// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSubtypeOfBaseIsNotBaseTest);
  });
}

@reflectiveTest
class MixinSubtypeOfBaseIsNotBaseTest extends PubPackageResolutionTest {
  test_class_implements() async {
    await assertErrorsInCode(
      r'''
base class A {}
mixin B implements A {}
''',
      [
        this.error(
          diag.mixinSubtypeOfBaseIsNotBase,
          22,
          1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'base'.",
        ),
      ],
    );
  }

  test_class_implements_indirect() async {
    await assertErrorsInCode(
      r'''
base class A {}
sealed class B implements A {}
mixin C implements B {}
''',
      [
        this.error(
          diag.mixinSubtypeOfBaseIsNotBase,
          53,
          1,
          text:
              "The mixin 'C' must be 'base' because the supertype 'A' is 'base'.",
          contextMessages: [
            contextMessage(
              testFile,
              11,
              1,
              textContains: [
                "The type 'B' is a subtype of 'A', and 'A' is defined here.",
              ],
            ),
          ],
        ),
      ],
    );
  }

  test_class_on() async {
    await assertErrorsInCode(
      r'''
base class A {}
mixin B on A {}
''',
      [
        this.error(
          diag.mixinSubtypeOfBaseIsNotBase,
          22,
          1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'base'.",
        ),
      ],
    );
  }

  test_mixin_implements() async {
    await assertErrorsInCode(
      r'''
base mixin A {}
mixin B implements A {}
''',
      [
        this.error(
          diag.mixinSubtypeOfBaseIsNotBase,
          22,
          1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'base'.",
        ),
      ],
    );
  }
}
