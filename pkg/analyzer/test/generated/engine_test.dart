// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsImplTest);
  });
}

@reflectiveTest
class AnalysisOptionsImplTest {
  test_resetToDefaults() {
    // Note that this only tests options visible from the interface.
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    AnalysisOptionsImpl modifiedOptions = new AnalysisOptionsImpl();
    modifiedOptions.dart2jsHint = true;
    modifiedOptions.disableCacheFlushing = true;
    modifiedOptions.enabledPluginNames = ['somePackage'];
    modifiedOptions.enableLazyAssignmentOperators = true;
    modifiedOptions.enableTiming = true;
    modifiedOptions.errorProcessors = [null];
    modifiedOptions.excludePatterns = ['a'];
    modifiedOptions.generateImplicitErrors = false;
    modifiedOptions.generateSdkErrors = true;
    modifiedOptions.hint = false;
    modifiedOptions.lint = true;
    modifiedOptions.lintRules = [null];
    modifiedOptions.patchPaths = {
      'dart:core': ['/dart_core.patch.dart']
    };
    modifiedOptions.preserveComments = false;
    modifiedOptions.trackCacheDependencies = false;

    modifiedOptions.resetToDefaults();

    expect(modifiedOptions.dart2jsHint, defaultOptions.dart2jsHint);
    expect(modifiedOptions.disableCacheFlushing,
        defaultOptions.disableCacheFlushing);
    expect(modifiedOptions.enabledPluginNames, isEmpty);
    expect(modifiedOptions.enableLazyAssignmentOperators,
        defaultOptions.enableLazyAssignmentOperators);
    expect(modifiedOptions.enableTiming, defaultOptions.enableTiming);
    expect(modifiedOptions.errorProcessors, defaultOptions.errorProcessors);
    expect(modifiedOptions.excludePatterns, defaultOptions.excludePatterns);
    expect(modifiedOptions.generateImplicitErrors,
        defaultOptions.generateImplicitErrors);
    expect(modifiedOptions.generateSdkErrors, defaultOptions.generateSdkErrors);
    expect(modifiedOptions.hint, defaultOptions.hint);
    expect(modifiedOptions.lint, defaultOptions.lint);
    expect(modifiedOptions.lintRules, defaultOptions.lintRules);
    expect(modifiedOptions.patchPaths, defaultOptions.patchPaths);
    expect(modifiedOptions.preserveComments, defaultOptions.preserveComments);
    expect(modifiedOptions.trackCacheDependencies,
        defaultOptions.trackCacheDependencies);
  }
}
