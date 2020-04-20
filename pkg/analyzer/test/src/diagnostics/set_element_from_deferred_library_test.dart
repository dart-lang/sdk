// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetElementFromDeferredLibraryTest);
    defineReflectiveTests(SetElementFromDeferredLibraryWithConstantsTest);
  });
}

@reflectiveTest
class SetElementFromDeferredLibraryTest extends DriverResolutionTest {
  @failingTest
  test_const_ifElement_thenTrue_elseDeferred() async {
    // reports wrong error code
    newFile(convertPath('/test/lib/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const {if (cond) null else a.c};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY, 88, 3),
    ]);
  }

  test_const_ifElement_thenTrue_thenDeferred() async {
    newFile(convertPath('/test/lib/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorsInCode(
        r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const {if (cond) a.c};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY,
                    78, 3),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 68, 13),
              ]);
  }

  test_const_topLevel_deferred() async {
    newFile(convertPath('/test/lib/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const {a.c};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY, 49, 3),
    ]);
  }

  test_const_topLevel_deferred_nested() async {
    newFile(convertPath('/test/lib/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const {a.c + 1};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY, 49, 7),
    ]);
  }
}

@reflectiveTest
class SetElementFromDeferredLibraryWithConstantsTest
    extends SetElementFromDeferredLibraryTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );
}
