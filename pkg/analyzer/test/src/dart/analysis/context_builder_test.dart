// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../context/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextBuilderImplTest);
  });
}

@reflectiveTest
class ContextBuilderImplTest extends Object with ResourceProviderMixin {
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
    resourceProvider.newFolder(resourceProvider.pathContext.dirname(
        resourceProvider.pathContext.dirname(io.Platform.resolvedExecutable)));
    contextBuilder = new ContextBuilderImpl(resourceProvider: resourceProvider);
    String path = resourceProvider.convertPath('/temp/root');
    Folder folder = resourceProvider.newFolder(path);
    contextRoot = new ContextRootImpl(resourceProvider, folder);
  }

  test_createContext_declaredVariables() {
    DeclaredVariables declaredVariables =
        new DeclaredVariables.fromMap({'foo': 'true'});
    DriverBasedAnalysisContext context = contextBuilder.createContext(
        contextRoot: contextRoot, declaredVariables: declaredVariables);
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    assertEquals(context.driver.declaredVariables, declaredVariables);
  }

  test_createContext_declaredVariables_sdkPath() {
    DeclaredVariables declaredVariables =
        new DeclaredVariables.fromMap({'bar': 'true'});
    MockSdk sdk = new MockSdk(resourceProvider: resourceProvider);
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
    AnalysisContext context =
        contextBuilder.createContext(contextRoot: contextRoot);
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
  }

  test_createContext_sdkPath() {
    MockSdk sdk = new MockSdk(resourceProvider: resourceProvider);
    DriverBasedAnalysisContext context = contextBuilder.createContext(
        contextRoot: contextRoot,
        sdkPath: resourceProvider.convertPath(sdkRoot));
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    expect(context.driver.sourceFactory.dartSdk.mapDartUri('dart:core'),
        sdk.mapDartUri('dart:core'));
  }
}
