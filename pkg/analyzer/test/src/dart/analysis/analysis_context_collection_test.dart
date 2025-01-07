// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisContextCollectionLowTest);
    defineReflectiveTests(AnalysisContextCollectionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AnalysisContextCollectionLowTest with ResourceProviderMixin {
  Folder get sdkRoot => newFolder('/sdk');

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    registerLintRules();
  }

  test_contextFor_noContext() {
    var collection = _newCollection(includedPaths: [convertPath('/root')]);
    expect(
      () => collection.contextFor(convertPath('/other/test.dart')),
      throwsStateError,
    );
  }

  test_contextFor_notAbsolute() {
    var collection = _newCollection(includedPaths: [convertPath('/root')]);
    expect(
      () => collection.contextFor(convertPath('test.dart')),
      throwsArgumentError,
    );
  }

  test_contextFor_notNormalized() {
    var collection = _newCollection(includedPaths: [convertPath('/root')]);
    expect(
      () => collection.contextFor(convertPath('/test/lib/../lib/test.dart')),
      throwsArgumentError,
    );
  }

  test_new_analysisOptions_includes() {
    var rootFolder = newFolder('/home/test');
    var fooFolder = newFolder('/home/packages/foo');
    newFile('${fooFolder.path}/lib/included.yaml', r'''
linter:
  rules:
    - empty_statements
''');

    var packageConfigFileBuilder = PackageConfigFileBuilder()
      ..add(name: 'foo', rootPath: fooFolder.path);
    newPackageConfigJsonFileFromBuilder(
      rootFolder.path,
      packageConfigFileBuilder,
    );

    var optionsFile = newAnalysisOptionsYamlFile(rootFolder.path, r'''
include: package:foo/included.yaml

linter:
  rules:
    - unnecessary_parenthesis
''');

    var collection = _newCollection(includedPaths: [rootFolder.path]);
    var analysisContext = collection.contextFor(rootFolder.path);
    var analysisOptions =
        analysisContext.getAnalysisOptionsForFile(optionsFile);

    expect(
      analysisOptions.lintRules.map((e) => e.name),
      unorderedEquals(['empty_statements', 'unnecessary_parenthesis']),
    );
  }

  test_new_analysisOptions_lintRules() {
    var rootFolder = newFolder('/home/test');
    var optionsFile = newAnalysisOptionsYamlFile(rootFolder.path, r'''
linter:
  rules:
    - non_existent_lint_rule
    - unnecessary_parenthesis
''');

    var collection = _newCollection(includedPaths: [rootFolder.path]);
    var analysisContext = collection.contextFor(rootFolder.path);
    var analysisOptions =
        analysisContext.getAnalysisOptionsForFile(optionsFile);

    expect(
      analysisOptions.lintRules.map((e) => e.name),
      unorderedEquals(['unnecessary_parenthesis']),
    );
  }

  test_new_includedPaths_notAbsolute() {
    expect(
      () => AnalysisContextCollectionImpl(includedPaths: ['root']),
      throwsArgumentError,
    );
  }

  test_new_includedPaths_notNormalized() {
    expect(
      () => AnalysisContextCollectionImpl(
          includedPaths: [convertPath('/root/lib/../lib')]),
      throwsArgumentError,
    );
  }

  test_new_outer_inner() {
    var outerFolder = newFolder('/test/outer');
    newFile('/test/outer/lib/outer.dart', '');

    newFolder('/test/outer/inner');
    newAnalysisOptionsYamlFile('/test/outer/inner', '');
    newFile('/test/outer/inner/inner.dart', '');

    var collection = _newCollection(includedPaths: [outerFolder.path]);
    expect(collection.contexts, hasLength(1));
  }

  test_new_sdkPath_notAbsolute() {
    expect(
      () => AnalysisContextCollectionImpl(
          includedPaths: ['/root'], sdkPath: 'sdk'),
      throwsArgumentError,
    );
  }

  test_new_sdkPath_notNormalized() {
    expect(
      () => AnalysisContextCollectionImpl(
          includedPaths: [convertPath('/root')], sdkPath: '/home/sdk/../sdk'),
      throwsArgumentError,
    );
  }

  AnalysisContextCollectionImpl _newCollection(
      {required List<String> includedPaths}) {
    return AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: includedPaths,
      sdkPath: sdkRoot.path,
    );
  }
}

@reflectiveTest
class AnalysisContextCollectionTest with ResourceProviderMixin {
  final _AnalysisContextCollectionPrinterConfiguration configuration =
      _AnalysisContextCollectionPrinterConfiguration();

  Folder get sdkRoot => newFolder('/sdk');

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    registerLintRules();
  }

  test_basicWorkspace() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    newFile('$testPackageRootPath/lib/a.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /home
    workspacePackage_0_0
''');
  }

  /// Verify the type of invalid data in
  /// https://github.com/dart-lang/sdk/issues/55594 doesn't result in unhandled
  /// exceptions when building contexts.
  test_basicWorkspace_invalidAnalysisOption_issue55594() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    newFile('$testPackageRootPath/lib/a.dart', '');

    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    - camel_case_types
    - file_names
    - non_constant_identifier_names
    - comment_references
    -
''');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: BasicWorkspace
    root: /home
    workspacePackage_0_0
''');
  }

  /// Verify the type of invalid data in
  /// https://github.com/dart-lang/sdk/issues/56577 doesn't result in unhandled
  /// exceptions when building contexts.
  test_basicWorkspace_invalidAnalysisOption_issue56577() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    newFile('$testPackageRootPath/lib/a.dart', '');

    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    analyzer:
      errors:
        todo: ignore
''');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: BasicWorkspace
    root: /home
    workspacePackage_0_0
''');
  }

  test_multiplePackageConfigWorkspace_singleAnalysisOptions_exclude() async {
    configuration.withOptionFilesForContext = true;

    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.g.dart', '');
    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
analyzer:
  exclude:
    - "**/*.g.dart"
''');

    var nestedPath = '$testPackageLibPath/nested';
    newFile('$nestedPath/lib/c.dart', '');
    newFile('$nestedPath/lib/d.g.dart', '');

    newSinglePackageConfigJsonFile(
      packagePath: nestedPath,
      name: 'nested',
    );
    newPubspecYamlFile(nestedPath, r'''
name: nested
''');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
  /home/test/lib/nested
    packagesFile: /home/test/lib/nested/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/lib/nested/lib/c.dart
        uri: package:nested/c.dart
        analysisOptions_0
        workspacePackage_1_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
  workspace_1: PackageConfigWorkspace
    root: /home/test/lib/nested
    pubPackages
      workspacePackage_1_0: PubPackage
        root: /home/test/lib/nested
''');
  }

  test_packageConfigWorkspace_enabledExperiment() async {
    configuration.withEnabledFeatures = true;

    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newAnalysisOptionsYamlFile(testPackageRootPath, '');

    newFile('$testPackageLibPath/a.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, updateAnalysisOptions: (
            {required AnalysisOptions analysisOptions,
            required ContextRoot contextRoot,
            required DartSdk sdk}) {
      (analysisOptions as AnalysisOptionsImpl).contextFeatures =
          FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: ExperimentStatus.currentVersion,
        flags: ['digit-separators', 'variance'],
      );
    }, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
    features
      class-modifiers
      constant-update-2018
      constructor-tearoffs
      control-flow-collections
      digit-separators
      enhanced-enums
      extension-methods
      generic-metadata
      inference-update-1
      inference-update-2
      inference-update-3
      inline-class
      named-arguments-anywhere
      non-nullable
      nonfunction-type-aliases
      patterns
      records
      sealed-class
      set-literals
      spread-collections
      super-parameters
      triple-shift
      unnamed-libraries
      variance
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_enabledExperiment_noAnalysisOptionsFile() async {
    configuration
      ..withAnalysisOptionsWithoutFiles = true
      ..withEnabledFeatures = true;

    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newFile('$testPackageLibPath/a.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, updateAnalysisOptions: (
            {required AnalysisOptions analysisOptions,
            required ContextRoot contextRoot,
            required DartSdk sdk}) {
      (analysisOptions as AnalysisOptionsImpl).contextFeatures =
          FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: ExperimentStatus.currentVersion,
        flags: ['variance'],
      );
    }, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: <no file>
    features
      class-modifiers
      constant-update-2018
      constructor-tearoffs
      control-flow-collections
      digit-separators
      enhanced-enums
      extension-methods
      generic-metadata
      inference-update-1
      inference-update-2
      inference-update-3
      inline-class
      named-arguments-anywhere
      non-nullable
      nonfunction-type-aliases
      patterns
      records
      sealed-class
      set-literals
      spread-collections
      super-parameters
      triple-shift
      unnamed-libraries
      variance
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_multipleAnalysisOptions() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newAnalysisOptionsYamlFile(testPackageRootPath, '');
    newFile('$testPackageLibPath/a.dart', '');

    var nestedPath = '$testPackageLibPath/nested';
    newAnalysisOptionsYamlFile(nestedPath, '');
    newFile('$nestedPath/b.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/b.dart
        uri: package:test/nested/b.dart
        analysisOptions_1
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
  analysisOptions_1: /home/test/lib/nested/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_multipleAnalysisOptions_nestedExclude() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newAnalysisOptionsYamlFile(testPackageRootPath, '');
    newFile('$testPackageLibPath/a.dart', '');

    var nestedPath = '$testPackageLibPath/nested';
    newAnalysisOptionsYamlFile(nestedPath, r'''
analyzer:
  exclude:
    - excluded/**
''');
    newFile('$nestedPath/b.dart', '');
    newFile('$nestedPath/excluded/b.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/b.dart
        uri: package:test/nested/b.dart
        analysisOptions_1
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
  analysisOptions_1: /home/test/lib/nested/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_multipleAnalysisOptions_nestedNestedExclude() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newAnalysisOptionsYamlFile(testPackageRootPath, '');
    newFile('$testPackageLibPath/a.dart', '');

    var nestedPath = '$testPackageLibPath/nested';
    newAnalysisOptionsYamlFile(nestedPath, r'''
analyzer:
  exclude:
    - excluded/**
''');
    newFile('$nestedPath/b.dart', '');
    newFile('$nestedPath/excluded/b.dart', '');

    var nestedNestedPath = '$nestedPath/nested';
    newAnalysisOptionsYamlFile(nestedNestedPath, r'''
analyzer:
  exclude:
    - excluded2/**
''');
    newFile('$nestedNestedPath/c.dart', '');
    newFile('$nestedNestedPath/excluded2/d.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/b.dart
        uri: package:test/nested/b.dart
        analysisOptions_1
        workspacePackage_0_0
      /home/test/lib/nested/nested/c.dart
        uri: package:test/nested/nested/c.dart
        analysisOptions_2
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
  analysisOptions_1: /home/test/lib/nested/analysis_options.yaml
  analysisOptions_2: /home/test/lib/nested/nested/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_multipleAnalysisOptions_outerExclude() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
analyzer:
  exclude:
    - excluded/**
''');
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageRootPath/excluded/b.dart', '');

    var nestedPath = '$testPackageLibPath/nested';
    newAnalysisOptionsYamlFile(nestedPath, '');
    newFile('$nestedPath/b.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/b.dart
        uri: package:test/nested/b.dart
        analysisOptions_1
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
  analysisOptions_1: /home/test/lib/nested/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_multipleAnalysisOptions_overridingOptions() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    var rootOptionsFile = newAnalysisOptionsYamlFile(testPackageRootPath, '');
    newFile('$testPackageLibPath/a.dart', '');

    var nestedPath = '$testPackageLibPath/nested';
    newAnalysisOptionsYamlFile(nestedPath, '');
    newFile('$nestedPath/b.dart', '');

    // Verify that despite the nested options file
    // (/home/test/nested/analysis_options.yaml), the nested file gets analyzed
    // with the outer one (/home/test/analysis_options.yaml) as passed into
    // the AnalysisContextCollection.
    _assertWorkspaceCollectionText(
        workspaceRootPath, optionsFile: rootOptionsFile, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/b.dart
        uri: package:test/nested/b.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_multipleAnalysisOptions_overridingOptions_outsideWorspaceRoot() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    var definedOptionsFile = newAnalysisOptionsYamlFile('/outside', '');

    newFile('$testPackageLibPath/a.dart', '');

    var nestedPath = '$testPackageLibPath/nested';
    newAnalysisOptionsYamlFile(nestedPath, '');
    newFile('$nestedPath/b.dart', '');

    // Verify that despite the nested options file
    // (/home/test/nested/analysis_options.yaml), the nested file gets analyzed
    // with the defined one which is outside the workspace
    // (/outside/analysis_options.yaml) as passed into the
    // AnalysisContextCollection.
    _assertWorkspaceCollectionText(
        workspaceRootPath, optionsFile: definedOptionsFile, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/b.dart
        uri: package:test/nested/b.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /outside/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_multiplePackageConfigs() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newFile('$testPackageLibPath/a.dart', '');

    var nestedPackageRootPath = '$testPackageRootPath/nested';
    newPubspecYamlFile(nestedPackageRootPath, r'''
name: nested
''');
    newSinglePackageConfigJsonFile(
      packagePath: nestedPackageRootPath,
      name: 'nested',
    );
    newFile('$nestedPackageRootPath/lib/b.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        workspacePackage_0_0
  /home/test/nested
    packagesFile: /home/test/nested/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/test/nested/lib/b.dart
        uri: package:nested/b.dart
        workspacePackage_1_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
  workspace_1: PackageConfigWorkspace
    root: /home/test/nested
    pubPackages
      workspacePackage_1_0: PubPackage
        root: /home/test/nested
''');
  }

  test_packageConfigWorkspace_sdkVersionConstraint() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';

    newPubspecYamlFile(testPackageRootPath, r'''
environment:
  sdk: ^3.0.0
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newFile('$testPackageRootPath/lib/a.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        workspacePackage_0_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
        sdkVersionConstraint: ^3.0.0
''');
  }

  test_packageConfigWorkspace_singleAnalysisOptions() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newAnalysisOptionsYamlFile(testPackageRootPath, '');

    newFile('$testPackageLibPath/a.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_singleAnalysisOptions_exclude() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');
    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );
    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
analyzer:
  exclude:
    - lib/nested/**
''');

    newFile('$testPackageLibPath/a.dart', '');
    var nestedPath = '$testPackageLibPath/nested';
    newFile('$nestedPath/b.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''');
  }

  test_packageConfigWorkspace_singleAnalysisOptions_multipleContexts() async {
    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newAnalysisOptionsYamlFile(testPackageRootPath, '');

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newFile('$testPackageLibPath/a.dart', '');

    var nestedPackageRootPath = '$testPackageRootPath/nested';
    newPubspecYamlFile(nestedPackageRootPath, r'''
name: nested
''');
    newSinglePackageConfigJsonFile(
      packagePath: nestedPackageRootPath,
      name: 'nested',
    );
    newFile('$nestedPackageRootPath/lib/b.dart', '');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
  /home/test/nested
    packagesFile: /home/test/nested/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/test/nested/lib/b.dart
        uri: package:nested/b.dart
        analysisOptions_0
        workspacePackage_1_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
  workspace_1: PackageConfigWorkspace
    root: /home/test/nested
    pubPackages
      workspacePackage_1_0: PubPackage
        root: /home/test/nested
''');
  }

  void _assertCollectionText(
    AnalysisContextCollectionImpl collection,
    String expected,
  ) {
    var actual = _getContextCollectionText(collection);
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  /// Asserts the text of a context collection created for a single included
  /// workspace path, without any excludes.
  void _assertWorkspaceCollectionText(
    String workspaceRootPath,
    String expected, {
    File? optionsFile,
    void Function({
      required AnalysisOptionsImpl analysisOptions,
      required ContextRoot contextRoot,
      required DartSdk sdk,
    })? updateAnalysisOptions,
  }) {
    if (optionsFile != null) {
      expect(optionsFile.exists, isTrue);
    }
    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(workspaceRootPath).path,
      ],
      optionsFile: optionsFile?.path,
      updateAnalysisOptions2: updateAnalysisOptions,
    );

    _assertCollectionText(collection, expected);
  }

  String _getContextCollectionText(
    AnalysisContextCollectionImpl contextCollection,
  ) {
    var buffer = StringBuffer();
    _AnalysisContextCollectionPrinter(
      configuration: configuration,
      resourceProvider: resourceProvider,
      sink: TreeStringSink(sink: buffer, indent: ''),
    ).write(contextCollection);
    return buffer.toString();
  }
}

class _AnalysisContextCollectionPrinter {
  final _AnalysisContextCollectionPrinterConfiguration configuration;
  final ResourceProvider resourceProvider;
  final TreeStringSink sink;

  final Map<AnalysisOptionsImpl, String> _analysisOptions = Map.identity();
  final Map<Workspace, (int, String)> _workspaces = Map.identity();
  final Map<Workspace, Map<WorkspacePackage, String>> _workspacePackages =
      Map.identity();

  _AnalysisContextCollectionPrinter({
    required this.configuration,
    required this.resourceProvider,
    required this.sink,
  });

  void write(AnalysisContextCollectionImpl contextCollection) {
    sink.writeElements(
      'contexts',
      contextCollection.contexts,
      _writeAnalysisContext,
    );

    _writeAnalysisOptions();

    sink.writeElements(
      'workspaces',
      _workspaces.keys.toList(),
      _writeWorkspace,
    );
  }

  String _idOfAnalysisOptions(AnalysisOptionsImpl analysisOptions) {
    return _analysisOptions[analysisOptions] ??=
        'analysisOptions_${_analysisOptions.length}';
  }

  String _idOfWorkspace(Workspace workspace) {
    return _indexIdOfWorkspace(workspace).$2;
  }

  String _idOfWorkspacePackage(WorkspacePackage package) {
    var workspace = package.workspace;
    var packages = _workspacePackages[workspace] ??= Map.identity();
    if (packages[package] case var id?) {
      return id;
    } else {
      var workspaceIndex = _indexIdOfWorkspace(workspace).$1;
      var id = 'workspacePackage_${workspaceIndex}_${packages.length}';
      return packages[package] ??= id;
    }
  }

  (int, String) _indexIdOfWorkspace(Workspace workspace) {
    if (_workspaces[workspace] case var existing?) {
      return existing;
    }

    var index = _workspaces.length;
    var id = 'workspace_$index';
    return _workspaces[workspace] = (index, id);
  }

  bool _isDartFile(File file) {
    return file_paths.isDart(resourceProvider.pathContext, file.path);
  }

  void _writeAnalysisContext(DriverBasedAnalysisContext analysisContext) {
    var contextRoot = analysisContext.contextRoot;
    var fsState = analysisContext.driver.fsState;

    var analyzedFiles = contextRoot.analyzedFiles().toList();
    if (!configuration.withEmptyContextRoots && analyzedFiles.isEmpty) {
      return;
    }

    sink.writelnWithIndent(contextRoot.root.posixPath);
    sink.withIndent(() {
      _writeNamedFile('packagesFile', contextRoot.packagesFile);
      if (configuration.withOptionFilesForContext) {
        _writeNamedFile('optionsFile', contextRoot.optionsFile);
      }
      sink.writelnWithIndent(
        'workspace: ${_idOfWorkspace(contextRoot.workspace)}',
      );
      sink.writeElements('analyzedFiles', analyzedFiles, (path) {
        var file = resourceProvider.getFile(path);
        if (_isDartFile(file)) {
          _writeDartFile(fsState, file);
        }
      });
    });
  }

  void _writeAnalysisOptions() {
    var filtered = _analysisOptions.keys
        .map((analysisOption) {
          var file = analysisOption.file;
          return configuration.withAnalysisOptionsWithoutFiles || file != null
              ? (analysisOption, file)
              : null;
        })
        .nonNulls
        .toList();

    sink.writeElements('analysisOptions', filtered, (pair) {
      var analysisOptions = pair.$1;
      var file = pair.$2;
      var id = _idOfAnalysisOptions(analysisOptions);
      if (file == null && configuration.withAnalysisOptionsWithoutFiles) {
        sink.writelnWithIndent('$id: <no file>');
      } else {
        _writeNamedFile(id, file);
      }
      sink.withIndent(() {
        if (configuration.withEnabledFeatures) {
          var contextFeatures = analysisOptions.contextFeatures;
          var enabledFeatures = ExperimentStatus.knownFeatures.values
              .where((f) => contextFeatures.isEnabled(f))
              .toList();
          sink.writeElements('features', enabledFeatures, (feature) {
            sink.writelnWithIndent(feature);
          });
        }
        if (configuration.withLintRules) {
          sink.writeElements(
            'lintRules',
            analysisOptions.lintRules,
            (lintRule) {
              sink.writelnWithIndent(lintRule.name);
            },
          );
        }
      });
    });
  }

  void _writeDartFile(FileSystemState fsState, File file) {
    sink.writelnWithIndent(file.posixPath);
    sink.withIndent(() {
      var fileState = fsState.getFileForPath(file.path);
      var uri = fileState.uri;
      // If file uri, don't print it out, causes test failure on Windows.
      if (uri.scheme != 'file') {
        sink.writelnWithIndent('uri: $uri');
      }

      var analysisOptions = fileState.analysisOptions;
      if (configuration.withAnalysisOptionsWithoutFiles ||
          analysisOptions.file != null) {
        var id = _idOfAnalysisOptions(analysisOptions);
        sink.writelnWithIndent(id);
      }

      var workspacePackage = fileState.workspacePackage;
      if (workspacePackage != null) {
        var id = _idOfWorkspacePackage(workspacePackage);
        sink.writelnWithIndent(id);
      }
    });
  }

  void _writeNamedFile(String name, File? file) {
    if (file != null) {
      sink.writelnWithIndent('$name: ${file.posixPath}');
    }
  }

  void _writeWorkspace(Workspace workspace) {
    var id = _idOfWorkspace(workspace);
    switch (workspace) {
      case BasicWorkspace():
        sink.writelnWithIndent('$id: BasicWorkspace');
        sink.withIndent(() {
          var root = resourceProvider.getFolder(workspace.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
          sink.writelnWithIndent(
            _idOfWorkspacePackage(workspace.theOnlyPackage),
          );
        });
      case PackageConfigWorkspace():
        sink.writelnWithIndent('$id: PackageConfigWorkspace');
        sink.withIndent(() {
          var root = resourceProvider.getFolder(workspace.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
          sink.writeElements(
            'pubPackages',
            workspace.allPackages.toList(),
            _writeWorkspacePackage,
          );
        });

      default:
        throw UnimplementedError('${workspace.runtimeType}');
    }
  }

  void _writeWorkspacePackage(WorkspacePackage package) {
    var id = _idOfWorkspacePackage(package);
    switch (package) {
      case BasicWorkspacePackage():
        sink.writelnWithIndent('$id: BasicWorkspacePackage');
        sink.withIndent(() {
          var root = resourceProvider.getFolder(package.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
        });
      case PubPackage():
        sink.writelnWithIndent('$id: PubPackage');
        sink.withIndent(() {
          var root = resourceProvider.getFolder(package.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
          var sdkVersionConstraint = package.sdkVersionConstraint;
          if (sdkVersionConstraint != null) {
            sink.writelnWithIndent(
                'sdkVersionConstraint: $sdkVersionConstraint');
          }
        });
      default:
        throw UnimplementedError('${package.runtimeType}');
    }
  }
}

class _AnalysisContextCollectionPrinterConfiguration {
  bool withAnalysisOptionsWithoutFiles = false;
  bool withEmptyContextRoots = false;
  bool withEnabledFeatures = false;
  bool withLintRules = false;
  bool withOptionFilesForContext = false;
}
