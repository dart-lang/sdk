// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportLegacySymbolTest);
  });
}

@reflectiveTest
class ExportLegacySymbolTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;

  test_exportDartAsync() async {
    await assertNoErrorsInCode(r'''
export 'dart:async';
''');
  }

  test_exportDartCore() async {
    await assertNoErrorsInCode(r'''
export 'dart:core';
''');
  }

  test_exportOptedIn() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');
    await assertNoErrorsInCode(r'''
export 'a.dart';
''');
  }

  test_exportOptedOut_exportOptedIn_hasLegacySymbol() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');

    newFile('/test/lib/b.dart', content: r'''
// @dart = 2.5
export 'a.dart';
class B {}
''');

    await assertErrorsInCode(r'''
export 'b.dart';
''', [
      error(CompileTimeErrorCode.EXPORT_LEGACY_SYMBOL, 7, 8),
    ]);
  }

  test_exportOptedOut_exportOptedIn_hideLegacySymbol() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');

    newFile('/test/lib/b.dart', content: r'''
// @dart = 2.5
export 'a.dart';
class B {}
''');

    await assertNoErrorsInCode(r'''
export 'b.dart' hide B;
''');
  }

  test_exportOptedOut_hasLegacySymbol() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
class A {}
class B {}
''');

    await assertErrorsInCode(r'''
export 'a.dart';
''', [
      error(CompileTimeErrorCode.EXPORT_LEGACY_SYMBOL, 7, 8),
    ]);
  }
}
