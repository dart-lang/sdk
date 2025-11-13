// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSubtypeOfFinalIsNotBaseTest);
  });
}

@reflectiveTest
class MixinSubtypeOfFinalIsNotBaseTest extends PubPackageResolutionTest {
  test_implements() async {
    await assertErrorsInCode(
      r'''
final class A {}
mixin B implements A {}
''',
      [
        this.error(
          diag.mixinSubtypeOfFinalIsNotBase,
          23,
          1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'final'.",
        ),
      ],
    );
  }

  test_implements_indirect() async {
    await assertErrorsInCode(
      r'''
final class A {}
sealed class B implements A {}
mixin C implements B {}
''',
      [
        this.error(
          diag.mixinSubtypeOfFinalIsNotBase,
          54,
          1,
          text:
              "The mixin 'C' must be 'base' because the supertype 'A' is 'final'.",
          contextMessages: [
            contextMessage(
              testFile,
              12,
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

  test_on() async {
    await assertErrorsInCode(
      r'''
final class A {}
mixin B on A {}
''',
      [
        this.error(
          diag.mixinSubtypeOfFinalIsNotBase,
          23,
          1,
          text:
              "The mixin 'B' must be 'base' because the supertype 'A' is 'final'.",
        ),
      ],
    );
  }
}
