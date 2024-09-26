// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextBuilderImplTest);
  });
}

@reflectiveTest
class ContextBuilderImplTest with ResourceProviderMixin {
  late final ContextBuilderImpl contextBuilder;
  late final ContextRoot contextRoot;

  Folder get sdkRoot => newFolder('/sdk');

  void assertEquals(DeclaredVariables actual, DeclaredVariables expected) {
    Iterable<String> actualNames = actual.variableNames;
    Iterable<String> expectedNames = expected.variableNames;
    expect(actualNames, expectedNames);
    for (String name in expectedNames) {
      expect(actual.get(name), expected.get(name));
    }
  }

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    var folder = newFolder('/home/test');
    contextBuilder = ContextBuilderImpl(resourceProvider: resourceProvider);
    var workspace =
        BasicWorkspace.find(resourceProvider, Packages.empty, folder.path);
    contextRoot = ContextRootImpl(resourceProvider, folder, workspace);
  }

  void test_analysisOptions_invalid() {
    var projectPath = convertPath('/home/test');
    var optionsFile = newAnalysisOptionsYamlFile(projectPath, ';');

    var analysisContext = _createSingleAnalysisContext(projectPath);
    var analysisOptions =
        analysisContext.getAnalysisOptionsImplForFile(optionsFile);
    _expectEqualOptions(analysisOptions, AnalysisOptionsImpl());
  }

  void test_analysisOptions_languageOptions() {
    var projectPath = convertPath('/home/test');
    var optionsFile = newAnalysisOptionsYamlFile(
      projectPath,
      analysisOptionsContent(strictRawTypes: true),
    );

    var analysisContext = _createSingleAnalysisContext(projectPath);
    var analysisOptions =
        analysisContext.getAnalysisOptionsImplForFile(optionsFile);
    _expectEqualOptions(
      analysisOptions,
      AnalysisOptionsImpl()..strictRawTypes = true,
    );
  }

  test_createContext_declaredVariables() {
    DeclaredVariables declaredVariables =
        DeclaredVariables.fromMap({'foo': 'true'});
    var context = contextBuilder.createContext(
      contextRoot: contextRoot,
      declaredVariables: declaredVariables,
      sdkPath: sdkRoot.path,
    );
    expect(context.contextRoot, contextRoot);
    assertEquals(context.driver.declaredVariables, declaredVariables);
  }

  test_createContext_declaredVariables_sdkPath() {
    DeclaredVariables declaredVariables =
        DeclaredVariables.fromMap({'bar': 'true'});
    var context = contextBuilder.createContext(
      contextRoot: contextRoot,
      declaredVariables: declaredVariables,
      sdkPath: sdkRoot.path,
    );
    expect(context.contextRoot, contextRoot);
    assertEquals(context.driver.declaredVariables, declaredVariables);
    expect(
      context.driver.sourceFactory.dartSdk!.mapDartUri('dart:core')!.fullName,
      sdkRoot.getChildAssumingFile('lib/core/core.dart').path,
    );
  }

  test_createContext_defaults() {
    AnalysisContext context = contextBuilder.createContext(
      contextRoot: contextRoot,
      sdkPath: sdkRoot.path,
    );
    expect(context.contextRoot, contextRoot);
  }

  test_createContext_sdkPath() {
    var context = contextBuilder.createContext(
      contextRoot: contextRoot,
      sdkPath: sdkRoot.path,
    );
    expect(context.contextRoot, contextRoot);
    expect(
      context.driver.sourceFactory.dartSdk!.mapDartUri('dart:core')!.fullName,
      sdkRoot.getChildAssumingFile('lib/core/core.dart').path,
    );
  }

  test_createContext_sdkRoot() {
    var context = contextBuilder.createContext(
        contextRoot: contextRoot, sdkPath: sdkRoot.path);
    expect(context.contextRoot, contextRoot);
    expect(context.sdkRoot, sdkRoot);
  }

  void test_sourceFactory_basicWorkspace() {
    var projectPath = convertPath('/home/my');
    newFile('/home/my/pubspec.yaml', '');

    // no package uri resolution information
    var analysisContext = _createSingleAnalysisContext(projectPath);
    expect(analysisContext.contextRoot.workspace, isA<BasicWorkspace>());

    expect(
      analysisContext.uriResolvers,
      unorderedEquals([
        isA<DartUriResolver>(),
        isA<PackageMapUriResolver>(),
        isA<ResourceUriResolver>(),
      ]),
    );
  }

  void test_sourceFactory_blazeWorkspace() {
    var projectPath = convertPath('/workspace/my/module');
    newFile('/workspace/${file_paths.blazeWorkspaceMarker}', '');
    newFolder('/workspace/blaze-bin');
    newFolder('/workspace/blaze-genfiles');

    var analysisContext = _createSingleAnalysisContext(projectPath);
    expect(analysisContext.contextRoot.workspace, isA<BlazeWorkspace>());

    expect(
      analysisContext.uriResolvers,
      unorderedEquals([
        isA<DartUriResolver>(),
        isA<BlazePackageUriResolver>(),
        isA<BlazeFileUriResolver>(),
      ]),
    );
  }

  /// Return a single expected analysis context at the [path].
  DriverBasedAnalysisContext _createSingleAnalysisContext(String path) {
    var roots = ContextLocatorImpl(
      resourceProvider: resourceProvider,
    ).locateRoots(includedPaths: [path]);

    return ContextBuilderImpl(
      resourceProvider: resourceProvider,
    ).createContext(
      contextRoot: roots.single,
      sdkPath: sdkRoot.path,
    );
  }

  static void _expectEqualOptions(
    AnalysisOptionsImpl actual,
    AnalysisOptionsImpl expected,
  ) {
    // TODO(brianwilkerson): Consider moving this to AnalysisOptionsImpl.==.
    expect(actual.enableTiming, expected.enableTiming);
    expect(actual.lint, expected.lint);
    expect(actual.warning, expected.warning);
    expect(
      actual.lintRules.map((l) => l.name),
      unorderedEquals(expected.lintRules.map((l) => l.name)),
    );
    expect(
        actual.propagateLinterExceptions, expected.propagateLinterExceptions);
    expect(actual.strictInference, expected.strictInference);
    expect(actual.strictRawTypes, expected.strictRawTypes);
  }
}

extension on DriverBasedAnalysisContext {
  List<UriResolver> get uriResolvers {
    return (driver.sourceFactory as SourceFactoryImpl).resolvers;
  }

  AnalysisOptionsImpl getAnalysisOptionsImplForFile(File file) =>
      driver.getAnalysisOptionsForFile(file);
}
