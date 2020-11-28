// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextBuilderImplTest);
  });
}

@reflectiveTest
class ContextBuilderImplTest with ResourceProviderMixin {
  ContextBuilderImpl contextBuilder;
  ContextRoot contextRoot;

  void assertEquals(DeclaredVariables actual, DeclaredVariables expected) {
    Iterable<String> actualNames = actual.variableNames;
    Iterable<String> expectedNames = expected.variableNames;
    expect(actualNames, expectedNames);
    for (String name in expectedNames) {
      expect(actual.get(name), expected.get(name));
    }
  }

  void setUp() {
    var folder = newFolder('/home/test');
    contextBuilder = ContextBuilderImpl(resourceProvider: resourceProvider);
    contextRoot = ContextRootImpl(resourceProvider, folder);
  }

  test_createContext_declaredVariables() {
    MockSdk(resourceProvider: resourceProvider);
    DeclaredVariables declaredVariables =
        DeclaredVariables.fromMap({'foo': 'true'});
    DriverBasedAnalysisContext context = contextBuilder.createContext(
      contextRoot: contextRoot,
      declaredVariables: declaredVariables,
      sdkPath: resourceProvider.convertPath(sdkRoot),
    );
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    assertEquals(context.driver.declaredVariables, declaredVariables);
  }

  test_createContext_declaredVariables_sdkPath() {
    DeclaredVariables declaredVariables =
        DeclaredVariables.fromMap({'bar': 'true'});
    MockSdk sdk = MockSdk(resourceProvider: resourceProvider);
    DriverBasedAnalysisContext context = contextBuilder.createContext(
        contextRoot: contextRoot,
        declaredVariables: declaredVariables,
        sdkPath: resourceProvider.convertPath(sdkRoot));
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    assertEquals(context.driver.declaredVariables, declaredVariables);
    expect(context.driver.sourceFactory.dartSdk.mapDartUri('dart:core'),
        sdk.mapDartUri('dart:core'));
  }

  test_createContext_defaults() {
    MockSdk(resourceProvider: resourceProvider);
    AnalysisContext context = contextBuilder.createContext(
      contextRoot: contextRoot,
      sdkPath: resourceProvider.convertPath(sdkRoot),
    );
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
  }

  test_createContext_sdkPath() {
    MockSdk sdk = MockSdk(resourceProvider: resourceProvider);
    DriverBasedAnalysisContext context = contextBuilder.createContext(
        contextRoot: contextRoot,
        sdkPath: resourceProvider.convertPath(sdkRoot));
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    expect(context.driver.sourceFactory.dartSdk.mapDartUri('dart:core'),
        sdk.mapDartUri('dart:core'));
  }
}
