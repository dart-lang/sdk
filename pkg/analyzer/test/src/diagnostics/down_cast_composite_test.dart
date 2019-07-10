// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DownCastCompositeDisabledTest);
    defineReflectiveTests(DownCastCompositeEnabledTest);
  });
}

@reflectiveTest
class DownCastCompositeDisabledTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..strongModeHints = false;

  test_use() async {
    await assertNoErrorsInCode('''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}
''');
  }
}

@reflectiveTest
class DownCastCompositeEnabledTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..strongModeHints = true;

  test_use() async {
    await assertErrorsInCode('''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}
''', [
      error(StrongModeCode.DOWN_CAST_COMPOSITE, 54, 11),
    ]);
  }
}
