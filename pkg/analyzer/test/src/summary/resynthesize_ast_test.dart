// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_text.dart';
import 'resynthesize_common.dart';
import 'test_strategies.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeAstStrongTest);
    defineReflectiveTests(ApplyCheckElementTextReplacements);
  });
}

@reflectiveTest
class ApplyCheckElementTextReplacements {
  test_applyReplacements() {
    applyCheckElementTextReplacements();
  }
}

@reflectiveTest
class ResynthesizeAstStrongTest extends ResynthesizeTestStrategyTwoPhase
    with ResynthesizeTestCases, GetElementTestCases, ResynthesizeTestHelpers {
  @failingTest // See dartbug.com/32290
  test_const_constructor_inferred_args() =>
      super.test_const_constructor_inferred_args();

  @failingTest // See dartbug.com/33441
  test_const_list_inferredType() => super.test_const_list_inferredType();

  @failingTest // See dartbug.com/33441
  test_const_map_inferredType() => super.test_const_map_inferredType();

  @failingTest // See dartbug.com/33441
  test_const_set_inferredType() => super.test_const_set_inferredType();

  @override
  @failingTest
  test_syntheticFunctionType_inGenericClass() async {
    await super.test_syntheticFunctionType_inGenericClass();
  }
}
