// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/diff.dart';
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
    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);
    registerLintRules();
  }

  test_contextFor_noContext() {
    var collection = _newCollection(includedPaths: [convertPath('/home/test')]);
    expect(
      () => collection.contextFor(convertPath('/home/other/test.dart')),
      throwsStateError,
    );
  }

  test_contextFor_notAbsolute() {
    var collection = _newCollection(includedPaths: [convertPath('/home/test')]);
    expect(
      () => collection.contextFor(convertPath('test.dart')),
      throwsArgumentError,
    );
  }

  test_contextFor_notNormalized() {
    var collection = _newCollection(includedPaths: [convertPath('/home/test')]);
    expect(
      () =>
          collection.contextFor(convertPath('/home/test/lib/../lib/test.dart')),
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
      ..add(name: 'foo', rootFolder: fooFolder);
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
    var analysisOptions = analysisContext.getAnalysisOptionsForFile(
      optionsFile,
    );

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
    var analysisOptions = analysisContext.getAnalysisOptionsForFile(
      optionsFile,
    );

    expect(
      analysisOptions.lintRules.map((e) => e.name),
      unorderedEquals(['unnecessary_parenthesis']),
    );
  }

  @Deprecated('Tests compatibility for updateAnalysisOptions4.')
  test_new_analysisOptions_updateAnalysisOptions4() {
    var rootFolder = newFolder('/home/test');
    var optionsFile = newAnalysisOptionsYamlFile(rootFolder.path, '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: [rootFolder.path],
      sdkPath: sdkRoot.path,
      updateAnalysisOptions4: ({required analysisOptions}) {
        analysisOptions.warning = false;
        analysisOptions.lint = true;
        analysisOptions.contextFeatures = FeatureSet.latestLanguageVersion(
          flags: ['variance'],
        );
      },
      withFineDependencies: true,
    );
    var analysisContext = collection.contextFor(rootFolder.path);
    var analysisOptions =
        analysisContext.getAnalysisOptionsForFile(optionsFile)
            as AnalysisOptionsImpl;

    expect(analysisOptions.warning, isFalse);
    expect(analysisOptions.lint, isTrue);
    expect(
      analysisOptions.contextFeatures.isEnabled(ExperimentalFeatures.variance),
      isTrue,
    );
  }

  test_new_includedPaths_notAbsolute() {
    expect(
      () => AnalysisContextCollectionImpl(
        includedPaths: ['root'],
        withFineDependencies: true,
      ),
      throwsArgumentError,
    );
  }

  test_new_includedPaths_notNormalized() {
    expect(
      () => AnalysisContextCollectionImpl(
        includedPaths: [convertPath('/home/test/lib/../lib')],
        withFineDependencies: true,
      ),
      throwsArgumentError,
    );
  }

  test_new_outer_inner() {
    var outerFolder = newFolder('/home/test/outer');
    newFile('/home/test/outer/lib/outer.dart', '');

    newFolder('/home/test/outer/inner');
    newAnalysisOptionsYamlFile('/home/test/outer/inner', '');
    newFile('/home/test/outer/inner/inner.dart', '');

    var collection = _newCollection(includedPaths: [outerFolder.path]);
    expect(collection.contexts, hasLength(1));
  }

  test_new_sdkPath_notAbsolute() {
    expect(
      () => AnalysisContextCollectionImpl(
        includedPaths: ['/home/test'],
        sdkPath: 'sdk',
        withFineDependencies: true,
      ),
      throwsArgumentError,
    );
  }

  test_new_sdkPath_notNormalized() {
    expect(
      () => AnalysisContextCollectionImpl(
        includedPaths: [convertPath('/home/test')],
        sdkPath: '/home/sdk/../sdk',
        withFineDependencies: true,
      ),
      throwsArgumentError,
    );
  }

  AnalysisContextCollectionImpl _newCollection({
    required List<String> includedPaths,
  }) {
    return AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: includedPaths,
      sdkPath: sdkRoot.path,
      withFineDependencies: true,
    );
  }
}

@reflectiveTest
class AnalysisContextCollectionTest with ResourceProviderMixin {
  final _AnalysisContextCollectionPrinterConfiguration configuration =
      _AnalysisContextCollectionPrinterConfiguration();

  Folder get sdkRoot => newFolder('/sdk');

  void setUp() {
    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);
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
      /home/test/analysis_options.yaml
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
      /home/test/analysis_options.yaml
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: BasicWorkspace
    root: /home
    workspacePackage_0_0
''');
  }

  void test_contextRoots_excludedByOptions_directoryWithParenthesis() {
    var rootFolder = newFolder('/home/test (copy)');
    var rootPath = rootFolder.path;
    newAnalysisOptionsYamlFile(rootPath, r'''
analyzer:
  exclude:
    - "**/*.g.dart"
''');
    newPackageConfigJsonFile(rootPath, '');
    var fooFile = newFile('$rootPath/lib/foo.dart', '');
    newFile('$rootPath/lib/bar.g.dart', '');

    _assertContextRootsText(
      included: [rootFolder, fooFile],
      expected: r'''
contexts
  /home/test (copy)
    includedPaths
      /home/test (copy)
    packagesFile: /home/test (copy)/.dart_tool/package_config.json
    optionsFile: /home/test (copy)/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test (copy)/analysis_options.yaml
      /home/test (copy)/lib/foo.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      **/*.g.dart in /home/test (copy)
analysisOptions
  analysisOptions_0: /home/test (copy)/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test (copy)
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test (copy)
''',
    );
  }

  void test_contextRoots_excludedByOptions_in_subDirectory() {
    var rootFolder = newFolder('/home/test (copy)');
    var rootPath = rootFolder.path;
    newAnalysisOptionsYamlFile(rootPath, r'''
analyzer:
  exclude:
    - "**/*.g.dart"
''');
    newPackageConfigJsonFile(rootPath, '');
    newFile('$rootPath/lib/foo.dart', '');
    newFile('$rootPath/lib/bar.g.dart', '');

    var pkg1Folder = newFolder('$rootPath/lib/pkg1');
    newPackageConfigJsonFile(pkg1Folder.path, '');
    newFile('${pkg1Folder.path}/lib/src/bar.g.dart', '');
    newFile('${pkg1Folder.path}/lib/foo.dart', '');
    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test (copy)
    includedPaths
      /home/test (copy)
    excludedPaths
      /home/test (copy)/lib/pkg1
    packagesFile: /home/test (copy)/.dart_tool/package_config.json
    optionsFile: /home/test (copy)/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test (copy)/analysis_options.yaml
      /home/test (copy)/lib/foo.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      **/*.g.dart in /home/test (copy)
  /home/test (copy)/lib/pkg1
    includedPaths
      /home/test (copy)/lib/pkg1
    packagesFile: /home/test (copy)/lib/pkg1/.dart_tool/package_config.json
    optionsFile: /home/test (copy)/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test (copy)/lib/pkg1/lib/foo.dart
        analysisOptions_0
        workspacePackage_1_0
    excludedGlobs
      **/*.g.dart in /home/test (copy)
analysisOptions
  analysisOptions_0: /home/test (copy)/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test (copy)
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test (copy)
  workspace_1: PackageConfigWorkspace
    root: /home/test (copy)/lib/pkg1
    pubPackages
      workspacePackage_1_0: BasicWorkspacePackage
        root: /home/test (copy)/lib/pkg1
''',
    );
  }

  void test_contextRoots_link_file_toOutOfRoot() {
    var rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart', '');
    newFile('/home/b.dart', '');
    newLink('/home/test/lib/c.dart', '/home/b.dart');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage_0_0
      /home/test/lib/c.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_link_file_toSiblingInRoot() {
    var rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart', '');
    newLink('/home/test/lib/b.dart', '/home/test/lib/a.dart');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage_0_0
      /home/test/lib/b.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_link_folder_notExistingTarget() {
    var rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart', '');
    newFolder('/home/test/lib/foo');
    newLink('/home/test/lib/foo', '/home/test/lib/bar');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_link_folder_toParentInRoot() {
    var rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart', '');
    newLink('/home/test/lib/foo', '/home/test/lib');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_link_folder_toParentOfRoot() {
    var rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart', '');
    newFile('/home/b.dart', '');
    newFile('/home/other/c.dart', '');
    newLink('/home/test/lib/foo', '/home');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage_0_0
      /home/test/lib/foo/b.dart
        workspacePackage_0_0
      /home/test/lib/foo/other/c.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_link_folder_toSiblingInRoot() {
    var rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart', '');
    newFile('/home/test/lib/foo/b.dart', '');
    newLink('/home/test/lib/bar', '/home/test/lib/foo');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage_0_0
      /home/test/lib/foo/b.dart
        workspacePackage_0_0
      /home/test/lib/bar/b.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_multiple_dirAndNestedDir_excludedByOptions() {
    var rootFolder = newFolder('/home/test');
    var rootPath = rootFolder.path;
    newAnalysisOptionsYamlFile(rootPath, r'''
analyzer:
  exclude:
    - examples/**
''');
    newPackageConfigJsonFile(rootPath, '');
    var includedFolder = newFolder('$rootPath/examples/included');
    newFile('${includedFolder.path}/included.dart', '');
    var excludedFolder = newFolder('$rootPath/examples/not_included');
    newFile('${excludedFolder.path}/excluded.dart', '');

    _assertContextRootsText(
      included: [rootFolder, includedFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
      /home/test/examples/included
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/analysis_options.yaml
      /home/test/examples/included/included.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      examples/** in /home/test
      examples in /home/test
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test
''',
    );
  }

  void test_contextRoots_multiple_dirAndNestedDir_innerConfigurationFiles() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer/examples/inner', '');
    newPackageConfigJsonFile('/home/test/outer/examples/inner', '');
    var innerRootFolder = newFolder('/home/test/outer/examples/inner');

    _assertContextRootsText(
      included: [outerRootFolder, innerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    excludedPaths
      /home/test/outer/examples/inner
    workspace: workspace_0
  /home/test/outer/examples/inner
    includedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/examples/inner/.dart_tool/package_config.json
    optionsFile: /home/test/outer/examples/inner/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/outer/examples/inner/analysis_options.yaml
workspaces
  workspace_0: BasicWorkspace
    root: /home/test/outer
    workspacePackage_0_0
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer/examples/inner
''',
    );
  }

  void test_contextRoots_multiple_dirAndNestedDir_noConfigurationFiles() {
    var outerRootFolder = newFolder('/home/test/outer');
    var innerRootFolder = newFolder('/home/test/outer/examples/inner');

    _assertContextRootsText(
      included: [outerRootFolder, innerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    workspace: workspace_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test/outer
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_multiple_dirAndNestedDir_outerConfigurationFiles() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    var innerRootFolder = newFolder('/home/test/outer/examples/inner');

    _assertContextRootsText(
      included: [outerRootFolder, innerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
''',
    );
  }

  test_contextRoots_multiple_dirAndNestedDir_outerIsBlaze_innerConfigurationFiles() {
    var outerRootFolder = newFolder('/home/test/outer');
    newFile('$outerRootFolder/${file_paths.blazeWorkspaceMarker}', '');
    newBazelBuildFile('$outerRootFolder', '');
    var innerRootFolder = newFolder('/home/test/outer/examples/inner');
    newAnalysisOptionsYamlFile('$innerRootFolder', '');
    newPackageConfigJsonFile('$innerRootFolder', '');
    newPubspecYamlFile('$innerRootFolder', '');

    _assertContextRootsText(
      included: [outerRootFolder, innerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    excludedPaths
      /home/test/outer/examples/inner
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/dart/config/ide/flutter.json
      /home/test/outer/BUILD
  /home/test/outer/examples/inner
    includedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/examples/inner/.dart_tool/package_config.json
    optionsFile: /home/test/outer/examples/inner/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/outer/examples/inner/analysis_options.yaml
      /home/test/outer/examples/inner/pubspec.yaml
workspaces
  workspace_0: BlazeWorkspace
    root: /home/test/outer
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer/examples/inner
''',
    );
  }

  void test_contextRoots_multiple_dirAndNestedFile_excludedByOptions() {
    var rootFolder = newFolder('/home/test');
    var rootPath = rootFolder.path;
    newAnalysisOptionsYamlFile(rootPath, r'''
analyzer:
  exclude:
    - lib/f*.dart
''');
    newPackageConfigJsonFile(rootPath, '');
    var fooFile = newFile('$rootPath/lib/foo.dart', '');
    newFile('$rootPath/lib/far.dart', ''); // not used
    newFile('$rootPath/lib/bar.dart', '');

    _assertContextRootsText(
      included: [rootFolder, fooFile],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
      /home/test/lib/foo.dart
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/analysis_options.yaml
      /home/test/lib/bar.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/foo.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      lib/f*.dart in /home/test
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test
''',
    );
  }

  void test_contextRoots_multiple_dirAndNestedFile_noConfigurationFiles() {
    var outerRootFolder = newFolder('/home/test/outer');
    var testFile = newFile('/home/test/outer/examples/inner/test.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder, testFile],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/examples/inner/test.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test/outer
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_multiple_dirAndNestedFile_outerConfigurationFiles() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    var testFile = newFile('/home/test/outer/examples/inner/test.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder, testFile],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
      /home/test/outer/examples/inner/test.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/outer/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/outer
''',
    );
  }

  void test_contextRoots_multiple_dirAndSiblingDir_bothConfigurationFiles() {
    var outer1RootFolder = newFolder('/home/test/outer1');
    newAnalysisOptionsYamlFile('/home/test/outer1', '');
    newPackageConfigJsonFile('/home/test/outer1', '');

    var outer2RootFolder = newFolder('/home/test/outer2');
    newAnalysisOptionsYamlFile('/home/test/outer2', '');
    newPackageConfigJsonFile('/home/test/outer2', '');

    _assertContextRootsText(
      included: [outer1RootFolder, outer2RootFolder],
      expected: r'''
contexts
  /home/test/outer1
    includedPaths
      /home/test/outer1
    packagesFile: /home/test/outer1/.dart_tool/package_config.json
    optionsFile: /home/test/outer1/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer1/analysis_options.yaml
  /home/test/outer2
    includedPaths
      /home/test/outer2
    packagesFile: /home/test/outer2/.dart_tool/package_config.json
    optionsFile: /home/test/outer2/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/outer2/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer1
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer2
''',
    );
  }

  void test_contextRoots_multiple_dirAndSiblingDir_noConfigurationFiles() {
    var outer1RootFolder = newFolder('/home/test/outer1');
    var outer2RootFolder = newFolder('/home/test/outer2');

    _assertContextRootsText(
      included: [outer1RootFolder, outer2RootFolder],
      expected: r'''
contexts
  /home/test/outer1
    includedPaths
      /home/test/outer1
    workspace: workspace_0
  /home/test/outer2
    includedPaths
      /home/test/outer2
    workspace: workspace_1
workspaces
  workspace_0: BasicWorkspace
    root: /home/test/outer1
    workspacePackage_0_0
  workspace_1: BasicWorkspace
    root: /home/test/outer2
    workspacePackage_1_0
''',
    );
  }

  void test_contextRoots_multiple_dirAndSiblingFile() {
    var outer1RootFolder = newFolder('/home/test/outer1');
    newAnalysisOptionsYamlFile('/home/test/outer1', '');
    newPackageConfigJsonFile('/home/test/outer1', '');

    newAnalysisOptionsYamlFile('/home/test/outer2', '');
    newPackageConfigJsonFile('/home/test/outer2', '');
    var testFile = newFile('/home/test/outer2/test.dart', '');

    _assertContextRootsText(
      included: [outer1RootFolder, testFile],
      expected: r'''
contexts
  /home/test/outer1
    includedPaths
      /home/test/outer1
    packagesFile: /home/test/outer1/.dart_tool/package_config.json
    optionsFile: /home/test/outer1/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer1/analysis_options.yaml
  /home/test/outer2
    includedPaths
      /home/test/outer2/test.dart
    packagesFile: /home/test/outer2/.dart_tool/package_config.json
    optionsFile: /home/test/outer2/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/outer2/test.dart
        analysisOptions_0
        workspacePackage_1_0
analysisOptions
  analysisOptions_0: /home/test/outer2/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer1
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer2
''',
    );
  }

  void test_contextRoots_multiple_dirAndSiblingFile_noConfigurationFiles() {
    var outer1RootFolder = newFolder('/home/test/outer1');
    var testFile = newFile('/home/test/outer2/test.dart', '');

    _assertContextRootsText(
      included: [outer1RootFolder, testFile],
      expected: r'''
contexts
  /home/test/outer1
    includedPaths
      /home/test/outer1
    workspace: workspace_0
  /
    includedPaths
      /home/test/outer2/test.dart
    workspace: workspace_1
    analyzedFiles
      /home/test/outer2/test.dart
        workspacePackage_1_0
workspaces
  workspace_0: BasicWorkspace
    root: /home/test/outer1
    workspacePackage_0_0
  workspace_1: BasicWorkspace
    root: /
    workspacePackage_1_0
''',
    );
  }

  void test_contextRoots_multiple_dirs_blaze_differentWorkspaces() {
    var workspacePath1 = '/home/workspace1';
    var workspacePath2 = '/home/workspace2';
    var pkgPath1 = '$workspacePath1/pkg1';
    var pkgPath2 = '$workspacePath2/pkg2';

    newFile('$workspacePath1/${file_paths.blazeWorkspaceMarker}', '');
    newFile('$workspacePath2/${file_paths.blazeWorkspaceMarker}', '');
    newBazelBuildFile(pkgPath1, '');
    newBazelBuildFile(pkgPath2, '');

    var folder1 = newFolder('$pkgPath1/lib/folder1');
    var folder2 = newFolder('$pkgPath2/lib/folder2');
    newFile('$pkgPath1/lib/folder1/file1.dart', '');
    newFile('$pkgPath2/lib/folder2/file2.dart', '');

    _assertContextRootsText(
      included: [folder1, folder2],
      expected: r'''
contexts
  /home/workspace1/pkg1/lib/folder1
    includedPaths
      /home/workspace1/pkg1/lib/folder1
    workspace: workspace_0
    analyzedFiles
      /home/workspace1/pkg1/lib/folder1/file1.dart
  /home/workspace2/pkg2/lib/folder2
    includedPaths
      /home/workspace2/pkg2/lib/folder2
    workspace: workspace_1
    analyzedFiles
      /home/workspace2/pkg2/lib/folder2/file2.dart
workspaces
  workspace_0: BlazeWorkspace
    root: /home/workspace1
  workspace_1: BlazeWorkspace
    root: /home/workspace2
''',
    );
  }

  /// Even if a file is excluded by the options, when it is explicitly included
  /// into analysis, it should be analyzed.
  void test_contextRoots_multiple_fileAndSiblingFile_excludedByOptions() {
    newAnalysisOptionsYamlFile('/home/test', r'''
analyzer:
  exclude:
    - lib/test2.dart
''');
    newPackageConfigJsonFile('/home/test', '');
    var testFile1 = newFile('/home/test/lib/test1.dart', '');
    var testFile2 = newFile('/home/test/lib/test2.dart', '');

    _assertContextRootsText(
      included: [testFile1, testFile2],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test/lib/test1.dart
      /home/test/lib/test2.dart
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/test1.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/test2.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      lib/test2.dart in /home/test
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test
''',
    );
  }

  void test_contextRoots_multiple_fileAndSiblingFile_hasOptions() {
    newAnalysisOptionsYamlFile('/home/test', '');
    var testFile1 = newFile('/home/test/lib/test1.dart', '');
    var testFile2 = newFile('/home/test/lib/test2.dart', '');

    _assertContextRootsText(
      included: [testFile1, testFile2],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test/lib/test1.dart
      /home/test/lib/test2.dart
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/test1.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/test2.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: BasicWorkspace
    root: /home/test/lib
    workspacePackage_0_0
''',
    );
  }

  test_contextRoots_multiple_fileAndSiblingFile_hasOptions_overrideOptions() {
    newAnalysisOptionsYamlFile('/home/test', ''); // not used
    var overrideOptionsFile = newAnalysisOptionsYamlFile('/home', '');
    var testFile1 = newFile('/home/test/lib/test1.dart', '');
    var testFile2 = newFile('/home/test/lib/test2.dart', '');

    _assertContextRootsText(
      included: [testFile1, testFile2],
      optionsFile: overrideOptionsFile,
      expected: r'''
contexts
  /
    includedPaths
      /home/test/lib/test1.dart
      /home/test/lib/test2.dart
    optionsFile: /home/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/test1.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/test2.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/analysis_options.yaml
workspaces
  workspace_0: BasicWorkspace
    root: /
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_multiple_fileAndSiblingFile_hasOptionsPackages() {
    newAnalysisOptionsYamlFile('/home/test', '');
    newPackageConfigJsonFile('/home/test', '');
    var testFile1 = newFile('/home/test/lib/test1.dart', '');
    var testFile2 = newFile('/home/test/lib/test2.dart', '');

    _assertContextRootsText(
      included: [testFile1, testFile2],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test/lib/test1.dart
      /home/test/lib/test2.dart
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/test1.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/test2.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test
''',
    );
  }

  void test_contextRoots_multiple_fileAndSiblingFile_hasPackages() {
    newPackageConfigJsonFile('/home/test', '');
    var testFile1 = newFile('/home/test/lib/test1.dart', '');
    var testFile2 = newFile('/home/test/lib/test2.dart', '');

    _assertContextRootsText(
      included: [testFile1, testFile2],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test/lib/test1.dart
      /home/test/lib/test2.dart
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/test1.dart
        workspacePackage_0_0
      /home/test/lib/test2.dart
        workspacePackage_0_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test
''',
    );
  }

  test_contextRoots_multiple_fileAndSiblingFile_hasPackages_overridePackages() {
    newPackageConfigJsonFile('/home/test', ''); // not used
    var overridePackagesFile = newPackageConfigJsonFile('/home', '');
    var testFile1 = newFile('/home/test/lib/test1.dart', '');
    var testFile2 = newFile('/home/test/lib/test2.dart', '');

    _assertContextRootsText(
      included: [testFile1, testFile2],
      packageConfigFile: overridePackagesFile,
      expected: r'''
contexts
  /home
    includedPaths
      /home/test/lib/test1.dart
      /home/test/lib/test2.dart
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/test1.dart
        workspacePackage_0_0
      /home/test/lib/test2.dart
        workspacePackage_0_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test
''',
    );
  }

  /// When there are no configuration files, we can use the root of the file
  /// system, because it contains all the files.
  void test_contextRoots_multiple_fileAndSiblingFile_noConfigurationFiles() {
    var testFile1 = newFile('/home/test/lib/test1.dart', '');
    var testFile2 = newFile('/home/test/lib/test2.dart', '');

    _assertContextRootsText(
      included: [testFile1, testFile2],
      expected: r'''
contexts
  /
    includedPaths
      /home/test/lib/test1.dart
      /home/test/lib/test2.dart
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/test1.dart
        workspacePackage_0_0
      /home/test/lib/test2.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_multiple_files_blaze_differentWorkspaces() {
    var workspacePath1 = '/home/workspace1';
    var workspacePath2 = '/home/workspace2';
    var pkgPath1 = '$workspacePath1/pkg1';
    var pkgPath2 = '$workspacePath2/pkg2';

    newFile('$workspacePath1/${file_paths.blazeWorkspaceMarker}', '');
    newFile('$workspacePath2/${file_paths.blazeWorkspaceMarker}', '');
    newBazelBuildFile(pkgPath1, '');
    newBazelBuildFile(pkgPath2, '');

    var file1 = newFile('$pkgPath1/lib/file1.dart', '');
    var file2 = newFile('$pkgPath2/lib/file2.dart', '');

    _assertContextRootsText(
      included: [file1, file2],
      expected: r'''
contexts
  /home/workspace1
    includedPaths
      /home/workspace1/pkg1/lib/file1.dart
    workspace: workspace_0
    analyzedFiles
      /home/workspace1/pkg1/lib/file1.dart
  /home/workspace2
    includedPaths
      /home/workspace2/pkg2/lib/file2.dart
    workspace: workspace_1
    analyzedFiles
      /home/workspace2/pkg2/lib/file2.dart
workspaces
  workspace_0: BlazeWorkspace
    root: /home/workspace1
  workspace_1: BlazeWorkspace
    root: /home/workspace2
''',
    );
  }

  void
  test_contextRoots_multiple_files_blaze_sameWorkspace_differentPackages() {
    var workspacePath = '/home/workspace';
    var fooPath = '$workspacePath/foo';
    var barPath = '$workspacePath/bar';

    newFile('$workspacePath/${file_paths.blazeWorkspaceMarker}', '');
    newBazelBuildFile(fooPath, '');
    newBazelBuildFile(barPath, '');

    var fooFile = newFile('$fooPath/lib/foo.dart', '');
    var barFile = newFile('$barPath/lib/bar.dart', '');

    _assertContextRootsText(
      included: [fooFile, barFile],
      expected: r'''
contexts
  /home/workspace
    includedPaths
      /home/workspace/foo/lib/foo.dart
      /home/workspace/bar/lib/bar.dart
    workspace: workspace_0
    analyzedFiles
      /home/workspace/foo/lib/foo.dart
      /home/workspace/bar/lib/bar.dart
workspaces
  workspace_0: BlazeWorkspace
    root: /home/workspace
''',
    );
  }

  void test_contextRoots_multiple_files_differentWorkspaces_packageConfig() {
    var rootPath = '/home';
    var fooPath = '$rootPath/foo';
    var barPath = '$rootPath/bar';

    newPackageConfigJsonFile(fooPath, '');
    newPackageConfigJsonFile(barPath, '');

    var fooFile = newFile('$fooPath/lib/foo.dart', '');
    var barFile = newFile('$barPath/lib/bar.dart', '');

    _assertContextRootsText(
      included: [fooFile, barFile],
      expected: r'''
contexts
  /home/foo
    includedPaths
      /home/foo/lib/foo.dart
    packagesFile: /home/foo/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/foo/lib/foo.dart
        workspacePackage_0_0
  /home/bar
    includedPaths
      /home/bar/lib/bar.dart
    packagesFile: /home/bar/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/bar/lib/bar.dart
        workspacePackage_1_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/foo
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/foo
  workspace_1: PackageConfigWorkspace
    root: /home/bar
    pubPackages
      workspacePackage_1_0: BasicWorkspacePackage
        root: /home/bar
''',
    );
  }

  void test_contextRoots_multiple_files_gnWorkspace() {
    var workspaceRootPath = '/home/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    newFolder(myRootPath);
    newBuildGnFile(myRootPath, '');
    var myFile1 = newFile('$myRootPath/lib/file1.dart', '');
    var myFile2 = newFile('$myRootPath/lib/file2.dart', '');
    newFile('$myRootPath/lib/file3.dart', '');
    newFile('$dartGenPath/my/my_package_config.json', '');

    _assertContextRootsText(
      included: [myFile1, myFile2],
      expected: r'''
contexts
  /home/workspace/my
    includedPaths
      /home/workspace/my/lib/file1.dart
      /home/workspace/my/lib/file2.dart
    workspace: workspace_0
    analyzedFiles
      /home/workspace/my/lib/file1.dart
        workspacePackage_0_0
      /home/workspace/my/lib/file2.dart
        workspacePackage_0_1
workspaces
  workspace_0: GnWorkspace
    root: /home/workspace
    buildGnFile: /home/workspace/my/BUILD.gn
    workspacePackages
      workspacePackage_0_0: GnWorkspacePackage
        root: /home/workspace/my
      workspacePackage_0_1: GnWorkspacePackage
        root: /home/workspace/my
''',
    );
  }

  void test_contextRoots_multiple_files_sameOptions_differentPackages() {
    newPackageConfigJsonFile('/home/foo', '');
    newPackageConfigJsonFile('/home/bar', '');
    newAnalysisOptionsYamlFile('/home', '');
    var fooFile = newFile('/home/foo/lib/foo.dart', '');
    var barFile = newFile('/home/bar/lib/bar.dart', '');

    _assertContextRootsText(
      included: [fooFile, barFile],
      expected: r'''
contexts
  /home/foo
    includedPaths
      /home/foo/lib/foo.dart
    packagesFile: /home/foo/.dart_tool/package_config.json
    optionsFile: /home/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/foo/lib/foo.dart
        analysisOptions_0
        workspacePackage_0_0
  /home/bar
    includedPaths
      /home/bar/lib/bar.dart
    packagesFile: /home/bar/.dart_tool/package_config.json
    optionsFile: /home/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/bar/lib/bar.dart
        analysisOptions_1
        workspacePackage_1_0
analysisOptions
  analysisOptions_0: /home/analysis_options.yaml
  analysisOptions_1: /home/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/foo
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/foo
  workspace_1: PackageConfigWorkspace
    root: /home/bar
    pubPackages
      workspacePackage_1_0: BasicWorkspacePackage
        root: /home/bar
''',
    );
  }

  void test_contextRoots_multiplePackages_monorepo() {
    var rootFolder = newFolder('/home/test/outer');
    var rootPath = rootFolder.path;
    newPackageConfigJsonFile(rootPath, '');
    newPubspecYamlFile(rootPath, '');
    var package1 = newFolder('$rootPath/package1');
    newPubspecYamlFile(package1.path, '');
    newFile('${package1.path}/lib/a.dart', '');
    var package2 = newFolder('$rootPath/package2');
    newPubspecYamlFile(package2.path, '');
    newFile('${package2.path}/lib/a.dart', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/pubspec.yaml
      /home/test/outer/package1/pubspec.yaml
      /home/test/outer/package1/lib/a.dart
        workspacePackage_0_0
      /home/test/outer/package2/pubspec.yaml
      /home/test/outer/package2/lib/a.dart
        workspacePackage_0_1
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test/outer/package1
      workspacePackage_0_1: PubPackage
        root: /home/test/outer/package2
''',
    );
  }

  void test_contextRoots_nested_excluded_dot() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');

    newFolder('/home/test/outer/.examples');
    newAnalysisOptionsYamlFile('/home/test/outer/.examples/inner', '');

    // Only one analysis root, we skipped `.examples` for context roots.
    _assertContextRootsText(
      included: [outerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
''',
    );
  }

  /// Verify that overlapped roots do not result in nested files being analyzed
  /// in multiple contexts (when the nested folder is passed first).
  ///
  /// See https://github.com/Dart-Code/Dart-Code/issues/5548')
  void test_contextRoots_nested_issueDartCode5548_nestedThenRoot() {
    var rootFolder = newFolder('/home/test');
    newAnalysisOptionsYamlFile(rootFolder.path, '');

    var nestedFolder = newFolder('/home/test/packages/foo');
    newAnalysisOptionsYamlFile(nestedFolder.path, '');
    newFile(join(nestedFolder.path, 'main.dart'), '');

    _assertContextRootsText(
      included: [nestedFolder, rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    excludedPaths
      /home/test/packages/foo
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/analysis_options.yaml
  /home/test/packages/foo
    includedPaths
      /home/test/packages/foo
    optionsFile: /home/test/packages/foo/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/packages/foo/analysis_options.yaml
      /home/test/packages/foo/main.dart
        analysisOptions_0
        workspacePackage_1_0
analysisOptions
  analysisOptions_0: /home/test/packages/foo/analysis_options.yaml
workspaces
  workspace_0: BasicWorkspace
    root: /home/test
    workspacePackage_0_0
  workspace_1: BasicWorkspace
    root: /home/test/packages/foo
    workspacePackage_1_0
''',
    );
  }

  /// Verify that overlapped roots do not result in nested files being analyzed
  /// in multiple contexts (when the nested folder is passed last).
  ///
  /// See https://github.com/Dart-Code/Dart-Code/issues/5548')
  void test_contextRoots_nested_issueDartCode5548_rootThenNested() {
    var rootFolder = newFolder('/home/test');
    newAnalysisOptionsYamlFile(rootFolder.path, '');

    var nestedFolder = newFolder('/home/test/packages/foo');
    newAnalysisOptionsYamlFile(nestedFolder.path, '');
    newFile(join(nestedFolder.path, 'main.dart'), '');

    _assertContextRootsText(
      included: [rootFolder, nestedFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    excludedPaths
      /home/test/packages/foo
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/analysis_options.yaml
  /home/test/packages/foo
    includedPaths
      /home/test/packages/foo
    optionsFile: /home/test/packages/foo/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/packages/foo/analysis_options.yaml
      /home/test/packages/foo/main.dart
        analysisOptions_0
        workspacePackage_1_0
analysisOptions
  analysisOptions_0: /home/test/packages/foo/analysis_options.yaml
workspaces
  workspace_0: BasicWorkspace
    root: /home/test
    workspacePackage_0_0
  workspace_1: BasicWorkspace
    root: /home/test/packages/foo
    workspacePackage_1_0
''',
    );
  }

  void test_contextRoots_nested_multiple() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newFolder('/home/test/outer/examples/inner1');
    newAnalysisOptionsYamlFile('/home/test/outer/examples/inner1', '');
    newFolder('/home/test/outer/examples/inner2');
    newPackageConfigJsonFile('/home/test/outer/examples/inner2', '');
    newFile('/home/test/outer/lib/a.dart', '');
    newFile('/home/test/outer/examples/inner1/lib/b.dart', '');
    newFile('/home/test/outer/examples/inner2/lib/c.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    excludedPaths
      /home/test/outer/examples/inner2
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
      /home/test/outer/examples/inner1/analysis_options.yaml
      /home/test/outer/examples/inner1/lib/b.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/outer/lib/a.dart
        analysisOptions_1
        workspacePackage_0_1
  /home/test/outer/examples/inner2
    includedPaths
      /home/test/outer/examples/inner2
    packagesFile: /home/test/outer/examples/inner2/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/outer/examples/inner2/lib/c.dart
        analysisOptions_1
        workspacePackage_1_0
analysisOptions
  analysisOptions_0: /home/test/outer/examples/inner1/analysis_options.yaml
  analysisOptions_1: /home/test/outer/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/outer
      workspacePackage_0_1: BasicWorkspacePackage
        root: /home/test/outer
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer/examples/inner2
    pubPackages
      workspacePackage_1_0: BasicWorkspacePackage
        root: /home/test/outer/examples/inner2
''',
    );
  }

  void test_contextRoots_nested_options() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newAnalysisOptionsYamlFile('/home/test/outer/examples/inner', '');
    newFile('/home/test/outer/lib/a.dart', '');
    newFile('/home/test/outer/examples/inner/lib/b.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
      /home/test/outer/examples/inner/analysis_options.yaml
      /home/test/outer/examples/inner/lib/b.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/outer/lib/a.dart
        analysisOptions_1
        workspacePackage_0_1
analysisOptions
  analysisOptions_0: /home/test/outer/examples/inner/analysis_options.yaml
  analysisOptions_1: /home/test/outer/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/outer
      workspacePackage_0_1: BasicWorkspacePackage
        root: /home/test/outer
''',
    );
  }

  void test_contextRoots_nested_options_overriddenOptions() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newFolder('/home/test/outer/examples/inner');
    newAnalysisOptionsYamlFile('/home/test/outer/examples/inner', '');
    var overrideOptionsFile = newAnalysisOptionsYamlFile(
      '/home/test/override',
      '',
    );
    newFile('/home/test/outer/lib/a.dart', '');
    newFile('/home/test/outer/examples/inner/lib/b.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      optionsFile: overrideOptionsFile,
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/override/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
      /home/test/outer/examples/inner/analysis_options.yaml
      /home/test/outer/examples/inner/lib/b.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/outer/lib/a.dart
        analysisOptions_0
        workspacePackage_0_1
analysisOptions
  analysisOptions_0: /home/test/override/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/outer
      workspacePackage_0_1: BasicWorkspacePackage
        root: /home/test/outer
''',
    );
  }

  void test_contextRoots_nested_options_overriddenPackages() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newAnalysisOptionsYamlFile('/home/test/outer/examples/inner', '');
    var overridePackagesFile = newPackageConfigJsonFile(
      '/home/test/override',
      '',
    );
    newFile('/home/test/outer/lib/a.dart', '');
    newFile('/home/test/outer/examples/inner/lib/b.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      packageConfigFile: overridePackagesFile,
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/override/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
      /home/test/outer/examples/inner/analysis_options.yaml
      /home/test/outer/examples/inner/lib/b.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/outer/lib/a.dart
        analysisOptions_1
        workspacePackage_0_1
analysisOptions
  analysisOptions_0: /home/test/outer/examples/inner/analysis_options.yaml
  analysisOptions_1: /home/test/outer/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/outer
      workspacePackage_0_1: BasicWorkspacePackage
        root: /home/test/outer
''',
    );
  }

  void test_contextRoots_nested_optionsAndPackages() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newFolder('/home/test/outer/examples/inner');
    newAnalysisOptionsYamlFile('/home/test/outer/examples/inner', '');
    newPackageConfigJsonFile('/home/test/outer/examples/inner', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    excludedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
  /home/test/outer/examples/inner
    includedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/examples/inner/.dart_tool/package_config.json
    optionsFile: /home/test/outer/examples/inner/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/outer/examples/inner/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer/examples/inner
''',
    );
  }

  void test_contextRoots_nested_optionsAndPackages_overriddenBoth() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newFolder('/home/test/outer/examples/inner');
    newAnalysisOptionsYamlFile('/home/test/outer/examples/inner', '');
    newPackageConfigJsonFile('/home/test/outer/examples/inner', '');
    var overrideOptionsFile = newAnalysisOptionsYamlFile(
      '/home/test/override',
      '',
    );
    var overridePackagesFile = newPackageConfigJsonFile(
      '/home/test/override',
      '',
    );
    newFile('/home/test/outer/lib/a.dart', '');
    newFile('/home/test/outer/examples/inner/lib/b.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      optionsFile: overrideOptionsFile,
      packageConfigFile: overridePackagesFile,
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/override/.dart_tool/package_config.json
    optionsFile: /home/test/override/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
      /home/test/outer/examples/inner/analysis_options.yaml
      /home/test/outer/examples/inner/lib/b.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/outer/lib/a.dart
        analysisOptions_0
        workspacePackage_0_1
analysisOptions
  analysisOptions_0: /home/test/override/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/outer
      workspacePackage_0_1: BasicWorkspacePackage
        root: /home/test/outer
''',
    );
  }

  void test_contextRoots_nested_packageConfigJson() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newFolder('/home/test/outer/examples/inner');
    newPackageConfigJsonFile('/home/test/outer/examples/inner', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    excludedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
  /home/test/outer/examples/inner
    includedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/examples/inner/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_1
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer/examples/inner
''',
    );
  }

  void test_contextRoots_nested_packages() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newFolder('/home/test/outer/examples/inner');
    newPackageConfigJsonFile('/home/test/outer/examples/inner', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    excludedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
  /home/test/outer/examples/inner
    includedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/examples/inner/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_1
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer/examples/inner
''',
    );
  }

  void test_contextRoots_nested_packages_overriddenOptions() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newFolder('/home/test/outer/examples/inner');
    newPackageConfigJsonFile('/home/test/outer/examples/inner', '');
    var overrideOptionsFile = newAnalysisOptionsYamlFile(
      '/home/test/override',
      '',
    );
    newFile('/home/test/outer/lib/a.dart', '');
    newFile('/home/test/outer/examples/inner/lib/b.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      optionsFile: overrideOptionsFile,
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    excludedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/override/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
      /home/test/outer/lib/a.dart
        analysisOptions_0
        workspacePackage_0_0
  /home/test/outer/examples/inner
    includedPaths
      /home/test/outer/examples/inner
    packagesFile: /home/test/outer/examples/inner/.dart_tool/package_config.json
    optionsFile: /home/test/override/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/outer/examples/inner/lib/b.dart
        analysisOptions_1
        workspacePackage_1_0
analysisOptions
  analysisOptions_0: /home/test/override/analysis_options.yaml
  analysisOptions_1: /home/test/override/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/outer
  workspace_1: PackageConfigWorkspace
    root: /home/test/outer/examples/inner
    pubPackages
      workspacePackage_1_0: BasicWorkspacePackage
        root: /home/test/outer/examples/inner
''',
    );
  }

  void test_contextRoots_nested_packages_overriddenPackages() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newFolder('/home/test/outer/examples/inner');
    newPackageConfigJsonFile('/home/test/outer/examples/inner', '');
    var overridePackagesFile = newPackageConfigJsonFile(
      '/home/test/override',
      '',
    );

    _assertContextRootsText(
      included: [outerRootFolder],
      packageConfigFile: overridePackagesFile,
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/override/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
''',
    );
  }

  void test_contextRoots_nested_packagesDirectory_included() {
    var outerRootFolder = newFolder('/home/test/outer');
    newAnalysisOptionsYamlFile('/home/test/outer', '');
    newPackageConfigJsonFile('/home/test/outer', '');
    newAnalysisOptionsYamlFile('/home/test/outer/packages/inner', '');
    newFile('/home/test/outer/lib/a.dart', '');
    newFile('/home/test/outer/packages/inner/lib/b.dart', '');

    _assertContextRootsText(
      included: [outerRootFolder],
      expected: r'''
contexts
  /home/test/outer
    includedPaths
      /home/test/outer
    packagesFile: /home/test/outer/.dart_tool/package_config.json
    optionsFile: /home/test/outer/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/outer/analysis_options.yaml
      /home/test/outer/packages/inner/analysis_options.yaml
      /home/test/outer/packages/inner/lib/b.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/outer/lib/a.dart
        analysisOptions_1
        workspacePackage_0_1
analysisOptions
  analysisOptions_0: /home/test/outer/packages/inner/analysis_options.yaml
  analysisOptions_1: /home/test/outer/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/outer
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/outer
      workspacePackage_0_1: BasicWorkspacePackage
        root: /home/test/outer
''',
    );
  }

  void test_contextRoots_options_default_blaze() {
    var workspacePath = '/home/workspace';
    getFolder(workspacePath);
    newFile('$workspacePath/${file_paths.blazeWorkspaceMarker}', '');
    newFile('$workspacePath/dart/analysis_options/lib/default.yaml', '');

    var rootFolder = getFolder('$workspacePath/test');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/workspace
    includedPaths
      /home/workspace/test
    optionsFile: /home/workspace/dart/analysis_options/lib/default.yaml
    workspace: workspace_0
    analyzedFiles
      /home/workspace/test
workspaces
  workspace_0: BlazeWorkspace
    root: /home/workspace
''',
    );
  }

  void test_contextRoots_options_default_flutter() {
    var rootFolder = newFolder('/home/test');

    var flutterPath = '/home/packages/flutter';

    var packageConfigFileBuilder = PackageConfigFileBuilder()
      ..add(name: 'flutter', rootFolder: getFolder(flutterPath));
    newPackageConfigJsonFile(
      rootFolder.path,
      packageConfigFileBuilder.toContent(),
    );

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
''',
    );
  }

  void test_contextRoots_options_hasError() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '''
analyzer:
  exclude:
    - **.g.dart
analyzer:
''');
    newPackageConfigJsonFile('/home/test/root', '');
    newFile('/home/test/root/lib/a.dart', '');
    newFile('/home/test/root/lib/a.g.dart', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
      /home/test/root/lib/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/root/lib/a.g.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/root
''',
    );
  }

  void test_contextRoots_options_withExclude_someFiles() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '''
analyzer:
  exclude:
    - data/**.g.dart
''');
    newPackageConfigJsonFile('/home/test/root', '');
    newFile('/home/test/root/data/f.g.dart', '');
    newFile('/home/test/root/data/foo/f.g.dart', '');
    newFile('/home/test/root/data/foo/bar/f.g.dart', '');
    newFile('/home/test/root/f.g.dart', '');
    newFile('/home/test/root/data/f.dart', '');
    newFile('/home/test/root/data/foo/f.dart', '');
    newFile('/home/test/root/data/foo/bar/f.dart', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
      /home/test/root/data/foo/bar/f.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/root/data/foo/f.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/root/data/f.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/root/f.g.dart
        analysisOptions_0
        workspacePackage_0_1
    excludedGlobs
      data/**.g.dart in /home/test/root
analysisOptions
  analysisOptions_0: /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/root
''',
    );
  }

  void test_contextRoots_options_withExclude_someFolders() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '''
analyzer:
  exclude:
    - data/**/foo/**
''');
    newPackageConfigJsonFile('/home/test/root', '');
    newFile('/home/test/root/data/foo/f.dart', '');
    newFile('/home/test/root/data/aaa/foo/f.dart', '');
    newFile('/home/test/root/data/aaa/foo/bar/f.dart', '');
    newFile('/home/test/root/f.dart', '');
    newFile('/home/test/root/data/f.dart', '');
    newFile('/home/test/root/data/aaa/bar/f.dart', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
      /home/test/root/data/aaa/bar/f.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/root/data/f.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/root/f.dart
        analysisOptions_0
        workspacePackage_0_1
    excludedGlobs
      data/**/foo/** in /home/test/root
      data/**/foo in /home/test/root
analysisOptions
  analysisOptions_0: /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
    pubPackages
      workspacePackage_0_0: BasicWorkspacePackage
        root: /home/test/root
''',
    );
  }

  void test_contextRoots_options_withExclude_wholeFolder() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '''
analyzer:
  exclude:
    - data/**
''');
    newPackageConfigJsonFile('/home/test/root', '');
    newFile('/home/test/root/data/f.dart', '');
    newFile('/home/test/root/data/foo/f.dart', '');
    newFile('/home/test/root/f.dart', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
      /home/test/root/f.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      data/** in /home/test/root
      data in /home/test/root
analysisOptions
  analysisOptions_0: /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
''',
    );
  }

  void test_contextRoots_options_withExclude_wholeFolder_includedOptions() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '''
include: has_excludes.yaml
''');
    newFile('/home/test/root/has_excludes.yaml', '''
analyzer:
  exclude:
    - data/**
''');

    newPackageConfigJsonFile('/home/test/root', '');
    newFile('/home/test/root/data/f.dart', '');
    newFile('/home/test/root/data/foo/f.dart', '');
    newFile('/home/test/root/f.dart', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
      /home/test/root/has_excludes.yaml
      /home/test/root/f.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      data/** in /home/test/root
      data in /home/test/root
analysisOptions
  analysisOptions_0: /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
''',
    );
  }

  void
  test_contextRoots_options_withExclude_wholeFolder_includedOptionsMerge() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '''
include: has_excludes.yaml
analyzer:
  exclude:
    - bar/**
''');
    newFile('/home/test/root/has_excludes.yaml', '''
analyzer:
  exclude:
    - foo/**
''');

    newPackageConfigJsonFile('/home/test/root', '');
    newFile('/home/test/root/foo/f.dart', '');
    newFile('/home/test/root/foo/aaa/f.dart', '');
    newFile('/home/test/root/bar/f.dart', '');
    newFile('/home/test/root/bar/aaa/f.dart', '');
    newFile('/home/test/root/f.dart', '');
    newFile('/home/test/root/baz/f.dart', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
      /home/test/root/has_excludes.yaml
      /home/test/root/f.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/root/baz/f.dart
        analysisOptions_0
        workspacePackage_0_1
    excludedGlobs
      foo/** in /home/test/root
      foo in /home/test/root
      bar/** in /home/test/root
      bar in /home/test/root
analysisOptions
  analysisOptions_0: /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
    pubPackages
      workspacePackage_0_1: BasicWorkspacePackage
        root: /home/test/root
''',
    );
  }

  void test_contextRoots_options_withExclude_wholeFolder_withItsOptions() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '''
analyzer:
  exclude:
    - data/**
''');
    newPackageConfigJsonFile('/home/test/root', '');
    newAnalysisOptionsYamlFile('/home/test/root/data', '');
    newFile('/home/test/root/data/f.dart', '');
    newFile('/home/test/root/data/foo/f.dart', '');
    newFile('/home/test/root/f.dart', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
      /home/test/root/f.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      data/** in /home/test/root
      data in /home/test/root
analysisOptions
  analysisOptions_0: /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
''',
    );
  }

  test_contextRoots_single_dir_children_gnWorkspaces_noPubspecYaml() {
    var workspaceRootPath = '/home/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var dartPath = '$workspaceRootPath/dart';
    var fooRootPath = '$dartPath/foo';
    newFolder(fooRootPath);
    newBuildGnFile(fooRootPath, '');
    newFile('$dartGenPath/dart/foo/foo_package_config.json', '');

    var barRootPath = '$dartPath/bar';
    newFolder(barRootPath);
    newBuildGnFile(barRootPath, '');
    newFile('$dartGenPath/dart/bar/bar_package_config.json', '');

    _assertContextRootsText(
      included: [getFolder(dartPath)],
      expected: r'''
contexts
  /home/workspace/dart
    includedPaths
      /home/workspace/dart
    excludedPaths
      /home/workspace/dart/foo
      /home/workspace/dart/bar
    workspace: workspace_0
  /home/workspace/dart/foo
    includedPaths
      /home/workspace/dart/foo
    workspace: workspace_1
    analyzedFiles
      /home/workspace/dart/foo/BUILD.gn
  /home/workspace/dart/bar
    includedPaths
      /home/workspace/dart/bar
    workspace: workspace_2
    analyzedFiles
      /home/workspace/dart/bar/BUILD.gn
workspaces
  workspace_0: BasicWorkspace
    root: /home/workspace/dart
    workspacePackage_0_0
  workspace_1: GnWorkspace
    root: /home/workspace
    buildGnFile: /home/workspace/dart/foo/BUILD.gn
  workspace_2: GnWorkspace
    root: /home/workspace
    buildGnFile: /home/workspace/dart/bar/BUILD.gn
''',
    );
  }

  void test_contextRoots_single_dir_directOptions_directPackages() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '');
    newPackageConfigJsonFile('/home/test/root', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
''',
    );
  }

  void test_contextRoots_single_dir_directOptions_inheritedPackages() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test/root', '');
    newPackageConfigJsonFile('/home/test', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/root/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
''',
    );
  }

  void test_contextRoots_single_dir_gnWorkspace_hasPubspecYaml() {
    var workspaceRootPath = '/home/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    var myRoot = newFolder(myRootPath);
    newBuildGnFile(myRootPath, '');
    newFile('$dartGenPath/my/my_package_config.json', '');
    newPubspecYamlFile(myRootPath, '');

    _assertContextRootsText(
      included: [myRoot],
      expected: r'''
contexts
  /home/workspace/my
    includedPaths
      /home/workspace/my
    workspace: workspace_0
    analyzedFiles
      /home/workspace/my/BUILD.gn
      /home/workspace/my/pubspec.yaml
workspaces
  workspace_0: GnWorkspace
    root: /home/workspace
    buildGnFile: /home/workspace/my/BUILD.gn
''',
    );
  }

  void test_contextRoots_single_dir_gnWorkspace_noPubspecYaml() {
    var workspaceRootPath = '/home/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    var myRoot = newFolder(myRootPath);
    newBuildGnFile(myRootPath, '');
    newFile('$dartGenPath/my/my_package_config.json', '');

    _assertContextRootsText(
      included: [myRoot],
      expected: r'''
contexts
  /home/workspace/my
    includedPaths
      /home/workspace/my
    workspace: workspace_0
    analyzedFiles
      /home/workspace/my/BUILD.gn
workspaces
  workspace_0: GnWorkspace
    root: /home/workspace
    buildGnFile: /home/workspace/my/BUILD.gn
''',
    );
  }

  void test_contextRoots_single_dir_inheritedOptions_directPackages() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test', '');
    newPackageConfigJsonFile('/home/test/root', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
''',
    );
  }

  void test_contextRoots_single_dir_inheritedOptions_inheritedPackages() {
    var rootFolder = newFolder('/home/test/root');
    newAnalysisOptionsYamlFile('/home/test', '');
    newPackageConfigJsonFile('/home/test', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
''',
    );
  }

  void test_contextRoots_single_dir_prefer_packageConfigJson() {
    var rootFolder = newFolder('/home/test');
    newAnalysisOptionsYamlFile('/home/test', '');
    newPackageConfigJsonFile('/home/test', ''); // the file is not used
    newPackageConfigJsonFile('/home/test', '');

    _assertContextRootsText(
      included: [rootFolder],
      expected: r'''
contexts
  /home/test
    includedPaths
      /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
''',
    );
  }

  /// See https://buganizer.corp.google.com/issues/273584249
  void
  test_contextRoots_single_directory_blaze_hasPubspecYaml_thirdPartyDart() {
    var workspacePath = '/home/workspace';
    var thirdPartyDartPath = '$workspacePath/third_party/dart';

    var myPackagePath = '$thirdPartyDartPath/my';
    var myPackage = getFolder(myPackagePath);

    newFile('$workspacePath/${file_paths.blazeWorkspaceMarker}', '');
    newBazelBuildFile(myPackagePath, '');
    newPubspecYamlFile(myPackagePath, '');
    newFile('$myPackagePath/lib/my.dart', '');

    _assertContextRootsText(
      included: [myPackage],
      expected: r'''
contexts
  /home/workspace/third_party/dart/my
    includedPaths
      /home/workspace/third_party/dart/my
    workspace: workspace_0
    analyzedFiles
      /home/workspace/third_party/dart/my/BUILD
      /home/workspace/third_party/dart/my/pubspec.yaml
      /home/workspace/third_party/dart/my/lib/my.dart
        uri: package:my/my.dart
        workspacePackage_0_0
workspaces
  workspace_0: BlazeWorkspace
    root: /home/workspace
    workspacePackages
      workspacePackage_0_0: BlazeWorkspacePackage
        root: /home/workspace/third_party/dart/my
''',
    );
  }

  void test_contextRoots_single_file_gnWorkspace() {
    var workspaceRootPath = '/home/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    newFolder(myRootPath);
    newBuildGnFile(myRootPath, '');
    var myFile = newFile('$myRootPath/lib/a.dart', '');
    newFile('$myRootPath/lib/b.dart', '');
    newFile('$dartGenPath/my/my_package_config.json', '');

    _assertContextRootsText(
      included: [myFile],
      expected: r'''
contexts
  /home/workspace/my
    includedPaths
      /home/workspace/my/lib/a.dart
    workspace: workspace_0
    analyzedFiles
      /home/workspace/my/lib/a.dart
        workspacePackage_0_0
workspaces
  workspace_0: GnWorkspace
    root: /home/workspace
    buildGnFile: /home/workspace/my/BUILD.gn
    workspacePackages
      workspacePackage_0_0: GnWorkspacePackage
        root: /home/workspace/my
''',
    );
  }

  void test_contextRoots_single_file_inheritedOptions_directPackages() {
    newAnalysisOptionsYamlFile('/home/test', '');
    newPackageConfigJsonFile('/home/test/root', '');
    var testFile = newFile('/home/test/root/test.dart', '');

    _assertContextRootsText(
      included: [testFile],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root/test.dart
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/test.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
''',
    );
  }

  void test_contextRoots_single_file_jiriRoot_noBuildGn_noPubspecYaml() {
    var workspaceRootPath = '/home/workspace';
    newFolder(workspaceRootPath);
    newFolder('$workspaceRootPath/.jiri_root');

    var outPath = '$workspaceRootPath/out/default';
    var dartGenPath = '$outPath/dartlang/gen';
    newFile('$workspaceRootPath/.fx-build-dir', '''
${getFolder(outPath).path}
''');

    var myRootPath = '$workspaceRootPath/my';
    var myFile = newFile('$myRootPath/lib/a.dart', '');
    newFile('$myRootPath/lib/b.dart', '');
    newFile('$dartGenPath/my/my_package_config.json', '');

    _assertContextRootsText(
      included: [myFile],
      expected: r'''
contexts
  /
    includedPaths
      /home/workspace/my/lib/a.dart
    workspace: workspace_0
    analyzedFiles
      /home/workspace/my/lib/a.dart
        workspacePackage_0_0
workspaces
  workspace_0: BasicWorkspace
    root: /
    workspacePackage_0_0
''',
    );
  }

  void test_contextRoots_single_file_notExisting() {
    newAnalysisOptionsYamlFile('/home/test', '');
    newPackageConfigJsonFile('/home/test/root', '');
    var testFile = getFile('/home/test/root/test.dart');

    _assertContextRootsText(
      included: [testFile],
      expected: r'''
contexts
  /home/test/root
    includedPaths
      /home/test/root/test.dart
    packagesFile: /home/test/root/.dart_tool/package_config.json
    optionsFile: /home/test/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/root/test.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test/root
''',
    );
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
    newAnalysisOptionsYamlFile(testPackageLibPath, r'''
analyzer:
  exclude:
    - "**/*.g.dart"
''');

    var nestedNoYamlPath = '$testPackageLibPath/nestedNoYaml';
    newFile('$nestedNoYamlPath/a.dart', '');
    newFile('$nestedNoYamlPath/b.g.dart', '');

    var nestedPath = '$testPackageLibPath/nested';
    newFile('$nestedPath/lib/c.dart', '');
    newFile('$nestedPath/lib/d.g.dart', '');

    newSinglePackageConfigJsonFile(packagePath: nestedPath, name: 'nested');
    newPubspecYamlFile(nestedPath, r'''
name: nested
''');

    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/pubspec.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/analysis_options.yaml
      /home/test/lib/nestedNoYaml/a.dart
        uri: package:test/nestedNoYaml/a.dart
        analysisOptions_0
        workspacePackage_0_0
  /home/test/lib/nested
    packagesFile: /home/test/lib/nested/.dart_tool/package_config.json
    optionsFile: /home/test/lib/analysis_options.yaml
    workspace: workspace_1
    analyzedFiles
      /home/test/lib/nested/lib/c.dart
        uri: package:nested/c.dart
        analysisOptions_0
        workspacePackage_1_0
      /home/test/lib/nested/pubspec.yaml
analysisOptions
  analysisOptions_0: /home/test/lib/analysis_options.yaml
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

    _assertWorkspaceCollectionText(
      workspaceRootPath,
      configureAnalysisOptionsBuilder: ({required analysisOptionsBuilder}) {
        analysisOptionsBuilder.contextFeatures = FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: ExperimentStatus.currentVersion,
          flags: ['digit-separators', 'variance'],
        );
      },
      r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
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
      dot-shorthands
      enhanced-enums
      extension-methods
      generic-metadata
      getter-setter-error
      inference-update-1
      inference-update-2
      inference-update-3
      inference-using-bounds
      inline-class
      named-arguments-anywhere
      native-assets
      non-nullable
      nonfunction-type-aliases
      null-aware-elements
      patterns
      primary-constructors
      private-named-parameters
      record-use
      records
      sealed-class
      set-literals
      sound-flow-analysis
      spread-collections
      super-parameters
      triple-shift
      unnamed-libraries
      variance
      wildcard-variables
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''',
    );
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

    _assertWorkspaceCollectionText(
      workspaceRootPath,
      configureAnalysisOptionsBuilder: ({required analysisOptionsBuilder}) {
        analysisOptionsBuilder.contextFeatures = FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: ExperimentStatus.currentVersion,
          flags: ['variance'],
        );
      },
      r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/pubspec.yaml
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
      dot-shorthands
      enhanced-enums
      extension-methods
      generic-metadata
      getter-setter-error
      inference-update-1
      inference-update-2
      inference-update-3
      inference-using-bounds
      inline-class
      named-arguments-anywhere
      native-assets
      non-nullable
      nonfunction-type-aliases
      null-aware-elements
      patterns
      primary-constructors
      private-named-parameters
      record-use
      records
      sealed-class
      set-literals
      sound-flow-analysis
      spread-collections
      super-parameters
      triple-shift
      unnamed-libraries
      variance
      wildcard-variables
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/test
''',
    );
  }

  test_packageConfigWorkspace_includedAnalysisOptions_exclude_relativeToDeclaringFile() async {
    configuration.withExcludedGlobs = true;

    var workspaceRootPath = '/home';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newAnalysisOptionsYamlFile(workspaceRootPath, r'''
analyzer:
  exclude:
    - test/lib/nested/b.dart
''');

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');
    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );
    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
include: ../analysis_options.yaml
''');

    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/nested/b.dart', '');
    newFile('$testPackageRootPath/test/lib/nested/b.dart', '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [getFolder(testPackageRootPath).path],
    );

    _assertCollectionText(collection, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/test/lib/nested/b.dart
        analysisOptions_0
        workspacePackage_0_0
    excludedGlobs
      test/lib/nested/b.dart in /home
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
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/analysis_options.yaml
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
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/analysis_options.yaml
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

    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
analyzer:
  exclude:
    - foo/**
''');
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

    // There's still an issue here with these exclude globs being there twice:
    // - foo/** in /home/test
    // - foo in /home/test
    // But at least that's it.
    configuration.withExcludedGlobs = true;
    _assertWorkspaceCollectionText(workspaceRootPath, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/analysis_options.yaml
      /home/test/lib/nested/b.dart
        uri: package:test/nested/b.dart
        analysisOptions_1
        workspacePackage_0_0
      /home/test/lib/nested/nested/analysis_options.yaml
      /home/test/lib/nested/nested/c.dart
        uri: package:test/nested/nested/c.dart
        analysisOptions_2
        workspacePackage_0_0
    excludedGlobs
      foo/** in /home/test
      foo in /home/test
      foo/** in /home/test
      foo in /home/test
      excluded/** in /home/test/lib/nested
      excluded in /home/test/lib/nested
      excluded2/** in /home/test/lib/nested/nested
      excluded2 in /home/test/lib/nested/nested
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
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/analysis_options.yaml
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
      workspaceRootPath,
      optionsFile: rootOptionsFile,
      r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/nested/analysis_options.yaml
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
''',
    );
  }

  test_packageConfigWorkspace_multipleAnalysisOptions_overridingOptions_outsideWorkspaceRoot() async {
    var workspaceRootPath = '/home/workspace';
    var testPackageRootPath = '$workspaceRootPath/test';
    var testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    var definedOptionsFile = newAnalysisOptionsYamlFile('/home/outside', '');

    newFile('$testPackageLibPath/a.dart', '');

    var nestedPath = '$testPackageLibPath/nested';
    newAnalysisOptionsYamlFile(nestedPath, '');
    newFile('$nestedPath/b.dart', '');

    // Verify that despite the nested options file
    // (/home/workspace/test/lib/nested/analysis_options.yaml), the nested file
    // gets analyzed with the defined one which is outside the workspace
    // (/home/outside/analysis_options.yaml) as passed into the
    // AnalysisContextCollection.
    _assertWorkspaceCollectionText(
      workspaceRootPath,
      optionsFile: definedOptionsFile,
      r'''
contexts
  /home/workspace/test
    packagesFile: /home/workspace/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/workspace/test/pubspec.yaml
      /home/workspace/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/workspace/test/lib/nested/analysis_options.yaml
      /home/workspace/test/lib/nested/b.dart
        uri: package:test/nested/b.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/outside/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home/workspace/test
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/workspace/test
''',
    );
  }

  test_packageConfigWorkspace_multipleFiles_sameWorkspace_differentOptions() async {
    configuration
      ..withIncludedPaths = true
      ..withOptionFilesForContext = true;

    var packageRootPath = '/home/test';
    newPubspecYamlFile(packageRootPath, r'''
name: test
''');
    newSinglePackageConfigJsonFile(packagePath: packageRootPath, name: 'test');

    var fooPath = '$packageRootPath/lib/foo';
    newAnalysisOptionsYamlFile(fooPath, '');
    var fooA = newFile('$fooPath/a.dart', '');
    var fooB = newFile('$fooPath/b.dart', '');
    newFile('$fooPath/not_included.dart', '');

    var barPath = '$packageRootPath/lib/bar';
    newAnalysisOptionsYamlFile(barPath, '');
    var barC = newFile('$barPath/c.dart', '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [fooA.path, fooB.path, barC.path],
      withFineDependencies: true,
    );

    _assertCollectionText(collection, r'''
contexts
  /home/test/lib/foo
    includedPaths
      /home/test/lib/foo/a.dart
      /home/test/lib/foo/b.dart
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/lib/foo/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/foo/a.dart
        uri: package:test/foo/a.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/test/lib/foo/b.dart
        uri: package:test/foo/b.dart
        analysisOptions_0
        workspacePackage_0_0
  /home/test/lib/bar
    includedPaths
      /home/test/lib/bar/c.dart
    packagesFile: /home/test/.dart_tool/package_config.json
    optionsFile: /home/test/lib/bar/analysis_options.yaml
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/bar/c.dart
        uri: package:test/bar/c.dart
        analysisOptions_1
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/test/lib/foo/analysis_options.yaml
  analysisOptions_1: /home/test/lib/bar/analysis_options.yaml
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
      /home/test/pubspec.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        workspacePackage_0_0
  /home/test/nested
    packagesFile: /home/test/nested/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/test/nested/pubspec.yaml
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
      /home/test/pubspec.yaml
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
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
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
      /home/test/pubspec.yaml
      /home/test/analysis_options.yaml
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
      /home/test/analysis_options.yaml
      /home/test/pubspec.yaml
      /home/test/lib/a.dart
        uri: package:test/a.dart
        analysisOptions_0
        workspacePackage_0_0
  /home/test/nested
    packagesFile: /home/test/nested/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/test/nested/pubspec.yaml
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

  test_resolutionWorkspace_noRoot_1of2Packages() async {
    var workspaceRootPath = '/home';
    var package1RootPath = '$workspaceRootPath/package1';
    var package2RootPath = '$workspaceRootPath/package2';

    // See https://dart.dev/tools/pub/workspaces
    newPubspecYamlFile(workspaceRootPath, r'''
name: _
publish_to: none
environment:
  sdk: ^3.6.0
workspace:
  - package1
  - package2
''');

    newPubspecYamlFile(package1RootPath, r'''
name: package1
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPubspecYamlFile(package2RootPath, r'''
name: package2
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPackageConfigJsonFileFromBuilder(
      workspaceRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'package1', rootFolder: getFolder(package1RootPath))
        ..add(name: 'package2', rootFolder: getFolder(package2RootPath)),
    );

    newFile('$package1RootPath/lib/library1.dart', '');
    newFile('$package2RootPath/lib/library2.dart', '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [getFolder(package1RootPath).path],
      withFineDependencies: true,
    );

    _assertCollectionText(collection, r'''
contexts
  /home
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/package1/pubspec.yaml
      /home/package1/lib/library1.dart
        uri: package:package1/library1.dart
        workspacePackage_0_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/package1
        sdkVersionConstraint: ^3.6.0
''');
  }

  test_resolutionWorkspace_noRoot_2of2Packages() async {
    var workspaceRootPath = '/home';
    var package1RootPath = '$workspaceRootPath/package1';
    var package2RootPath = '$workspaceRootPath/package2';

    // See https://dart.dev/tools/pub/workspaces
    newPubspecYamlFile(workspaceRootPath, r'''
name: _
publish_to: none
environment:
  sdk: ^3.6.0
workspace:
  - package1
  - package2
''');

    newPubspecYamlFile(package1RootPath, r'''
name: package1
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPubspecYamlFile(package2RootPath, r'''
name: package2
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPackageConfigJsonFileFromBuilder(
      workspaceRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'package1', rootFolder: getFolder(package1RootPath))
        ..add(name: 'package2', rootFolder: getFolder(package2RootPath)),
    );

    newFile('$package1RootPath/lib/library1.dart', '');
    newFile('$package2RootPath/lib/library2.dart', '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(package1RootPath).path,
        getFolder(package2RootPath).path,
      ],
      withFineDependencies: true,
    );

    _assertCollectionText(collection, r'''
contexts
  /home
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/package1/pubspec.yaml
      /home/package1/lib/library1.dart
        uri: package:package1/library1.dart
        workspacePackage_0_0
      /home/package2/pubspec.yaml
      /home/package2/lib/library2.dart
        uri: package:package2/library2.dart
        workspacePackage_0_1
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/package1
        sdkVersionConstraint: ^3.6.0
      workspacePackage_0_1: PubPackage
        root: /home/package2
        sdkVersionConstraint: ^3.6.0
''');
  }

  test_resolutionWorkspace_noRoot_2of3Packages() async {
    var workspaceRootPath = '/home';
    var package1RootPath = '$workspaceRootPath/package1';
    var package2RootPath = '$workspaceRootPath/package2';
    var package3RootPath = '$workspaceRootPath/package3';

    // See https://dart.dev/tools/pub/workspaces
    newPubspecYamlFile(workspaceRootPath, r'''
name: _
publish_to: none
environment:
  sdk: ^3.6.0
workspace:
  - package1
  - package2
  - package3
''');

    newPubspecYamlFile(package1RootPath, r'''
name: package1
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPubspecYamlFile(package2RootPath, r'''
name: package2
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPubspecYamlFile(package3RootPath, r'''
name: package3
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPackageConfigJsonFileFromBuilder(
      workspaceRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'package1', rootFolder: getFolder(package1RootPath))
        ..add(name: 'package2', rootFolder: getFolder(package2RootPath))
        ..add(name: 'package3', rootFolder: getFolder(package3RootPath)),
    );

    newFile('$package1RootPath/lib/library1.dart', '');
    newFile('$package2RootPath/lib/library2.dart', '');
    newFile('$package3RootPath/lib/library3.dart', '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(package1RootPath).path,
        getFolder(package2RootPath).path,
      ],
      withFineDependencies: true,
    );

    _assertCollectionText(collection, r'''
contexts
  /home
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/package1/pubspec.yaml
      /home/package1/lib/library1.dart
        uri: package:package1/library1.dart
        workspacePackage_0_0
      /home/package2/pubspec.yaml
      /home/package2/lib/library2.dart
        uri: package:package2/library2.dart
        workspacePackage_0_1
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/package1
        sdkVersionConstraint: ^3.6.0
      workspacePackage_0_1: PubPackage
        root: /home/package2
        sdkVersionConstraint: ^3.6.0
''');
  }

  test_resolutionWorkspace_root() async {
    var workspaceRootPath = '/home';
    var package1RootPath = '$workspaceRootPath/package1';
    var package2RootPath = '$workspaceRootPath/package2';

    // See https://dart.dev/tools/pub/workspaces
    newPubspecYamlFile(workspaceRootPath, r'''
name: _
publish_to: none
environment:
  sdk: ^3.6.0
workspace:
  - package1
  - package2
''');

    newPubspecYamlFile(package1RootPath, r'''
name: package1
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPubspecYamlFile(package2RootPath, r'''
name: package2
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPackageConfigJsonFileFromBuilder(
      workspaceRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'package1', rootFolder: getFolder(package1RootPath))
        ..add(name: 'package2', rootFolder: getFolder(package2RootPath)),
    );

    newAnalysisOptionsYamlFile(workspaceRootPath, '');
    newAnalysisOptionsYamlFile(package1RootPath, '');

    newFile('$package1RootPath/lib/library1.dart', '');
    newFile('$package2RootPath/lib/library2.dart', '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [getFolder(workspaceRootPath).path],
      withFineDependencies: true,
    );

    _assertCollectionText(collection, r'''
contexts
  /home
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/pubspec.yaml
      /home/package1/pubspec.yaml
      /home/package1/analysis_options.yaml
      /home/package1/lib/library1.dart
        uri: package:package1/library1.dart
        analysisOptions_0
        workspacePackage_0_0
      /home/package2/pubspec.yaml
      /home/package2/lib/library2.dart
        uri: package:package2/library2.dart
        analysisOptions_1
        workspacePackage_0_1
      /home/analysis_options.yaml
analysisOptions
  analysisOptions_0: /home/package1/analysis_options.yaml
  analysisOptions_1: /home/analysis_options.yaml
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/package1
        sdkVersionConstraint: ^3.6.0
      workspacePackage_0_1: PubPackage
        root: /home/package2
        sdkVersionConstraint: ^3.6.0
''');
  }

  test_resolutionWorkspace_root_1of2Packages() async {
    var workspaceRootPath = '/home';
    var package1RootPath = '$workspaceRootPath/package1';
    var package2RootPath = '$workspaceRootPath/package2';

    // See https://dart.dev/tools/pub/workspaces
    newPubspecYamlFile(workspaceRootPath, r'''
name: _
publish_to: none
environment:
  sdk: ^3.6.0
workspace:
  - package1
  - package2
''');

    newPubspecYamlFile(package1RootPath, r'''
name: package1
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPubspecYamlFile(package2RootPath, r'''
name: package2
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPackageConfigJsonFileFromBuilder(
      workspaceRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'package1', rootFolder: getFolder(package1RootPath))
        ..add(name: 'package2', rootFolder: getFolder(package2RootPath)),
    );

    newFile('$package1RootPath/lib/library1.dart', '');
    newFile('$package2RootPath/lib/library2.dart', '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(workspaceRootPath).path,
        getFolder(package1RootPath).path,
      ],
      withFineDependencies: true,
    );

    _assertCollectionText(collection, r'''
contexts
  /home
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/pubspec.yaml
      /home/package1/pubspec.yaml
      /home/package1/lib/library1.dart
        uri: package:package1/library1.dart
        workspacePackage_0_0
      /home/package2/pubspec.yaml
      /home/package2/lib/library2.dart
        uri: package:package2/library2.dart
        workspacePackage_0_1
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/package1
        sdkVersionConstraint: ^3.6.0
      workspacePackage_0_1: PubPackage
        root: /home/package2
        sdkVersionConstraint: ^3.6.0
''');
  }

  test_resolutionWorkspace_root_2of2Packages() async {
    var workspaceRootPath = '/home';
    var package1RootPath = '$workspaceRootPath/package1';
    var package2RootPath = '$workspaceRootPath/package2';

    // See https://dart.dev/tools/pub/workspaces
    newPubspecYamlFile(workspaceRootPath, r'''
name: _
publish_to: none
environment:
  sdk: ^3.6.0
workspace:
  - package1
  - package2
''');

    newPubspecYamlFile(package1RootPath, r'''
name: package1
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPubspecYamlFile(package2RootPath, r'''
name: package2
environment:
  sdk: ^3.6.0
resolution: workspace
''');

    newPackageConfigJsonFileFromBuilder(
      workspaceRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'package1', rootFolder: getFolder(package1RootPath))
        ..add(name: 'package2', rootFolder: getFolder(package2RootPath)),
    );

    newFile('$package1RootPath/lib/library1.dart', '');
    newFile('$package2RootPath/lib/library2.dart', '');

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(workspaceRootPath).path,
        getFolder(package1RootPath).path,
        getFolder(package2RootPath).path,
      ],
      withFineDependencies: true,
    );

    _assertCollectionText(collection, r'''
contexts
  /home
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/pubspec.yaml
      /home/package1/pubspec.yaml
      /home/package1/lib/library1.dart
        uri: package:package1/library1.dart
        workspacePackage_0_0
      /home/package2/pubspec.yaml
      /home/package2/lib/library2.dart
        uri: package:package2/library2.dart
        workspacePackage_0_1
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/package1
        sdkVersionConstraint: ^3.6.0
      workspacePackage_0_1: PubPackage
        root: /home/package2
        sdkVersionConstraint: ^3.6.0
''');
  }

  test_resolutionWorkspace_singlePackage_analysisOptions_intermediate() async {
    var workspaceRootPath = '/home';
    var package1RootPath = '$workspaceRootPath/packages/package1';

    newPubspecYamlFile(workspaceRootPath, r'''
name: root_package
environment:
  sdk: ^3.6.0
workspace:
  - packages/package1
''');
    newAnalysisOptionsYamlFile('$workspaceRootPath/packages', r'''
linter:
  rules:
    - prefer_final_locals
''');
    newFile('$workspaceRootPath/lib/main.dart', '');

    newPubspecYamlFile(package1RootPath, r'''
name: package1
environment:
  sdk: ^3.6.0
resolution: workspace
''');
    newFile('$package1RootPath/lib/package1.dart', '');

    newPackageConfigJsonFileFromBuilder(
      workspaceRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'root_package', rootFolder: getFolder(workspaceRootPath))
        ..add(name: 'package1', rootFolder: getFolder(package1RootPath)),
    );

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [getFolder(package1RootPath).path],
      withFineDependencies: true,
    );

    configuration.withLintRules = true;
    _assertCollectionText(collection, r'''
contexts
  /home
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/packages/package1/pubspec.yaml
      /home/packages/package1/lib/package1.dart
        uri: package:package1/package1.dart
        analysisOptions_0
        workspacePackage_0_0
analysisOptions
  analysisOptions_0: /home/packages/analysis_options.yaml
    lintRules
      prefer_final_locals
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/packages/package1
        sdkVersionConstraint: ^3.6.0
''');
  }

  test_resolutionWorkspace_singlePackage_nestedInLib() async {
    var workspaceRootPath = '/home';
    var package1RootPath = '$workspaceRootPath/lib/package1';

    newPubspecYamlFile(workspaceRootPath, r'''
name: root_package
environment:
  sdk: ^3.6.0
workspace:
  - lib/package1
''');
    newFile('$workspaceRootPath/lib/main.dart', '');

    newPubspecYamlFile(package1RootPath, r'''
name: package1
environment:
  sdk: ^3.6.0
resolution: workspace
''');
    newFile('$package1RootPath/lib/package1.dart', '');

    newPackageConfigJsonFileFromBuilder(
      workspaceRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'root_package', rootFolder: getFolder(workspaceRootPath))
        ..add(name: 'package1', rootFolder: getFolder(package1RootPath)),
    );

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [getFolder(package1RootPath).path],
      withFineDependencies: true,
    );

    // Note: `package:package1/package1.dart` URI.
    _assertCollectionText(collection, r'''
contexts
  /home
    packagesFile: /home/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/lib/package1/pubspec.yaml
      /home/lib/package1/lib/package1.dart
        uri: package:package1/package1.dart
        workspacePackage_0_0
workspaces
  workspace_0: PackageConfigWorkspace
    root: /home
    pubPackages
      workspacePackage_0_0: PubPackage
        root: /home/lib/package1
        sdkVersionConstraint: ^3.6.0
''');
  }

  void _assertCollectionText(
    AnalysisContextCollectionImpl collection,
    String expected,
  ) {
    _assertIsAnalyzedConsistent(collection);

    var actual = _getContextCollectionText(collection);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  /// Asserts a collection created from context-root discovery inputs.
  void _assertContextRootsText({
    required List<Resource> included,
    File? optionsFile,
    File? packageConfigFile,
    required String expected,
  }) {
    configuration
      ..withEmptyContextRoots = true
      ..withExcludedGlobs = true
      ..withExcludedPaths = true
      ..withIncludedPaths = true
      ..withOptionFilesForContext = true;

    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: included.map((resource) => resource.path).toList(),
      optionsFile: optionsFile?.path,
      packageConfigFile: packageConfigFile?.path,
      withFineDependencies: true,
    );

    _assertCollectionText(collection, expected);
  }

  /// Verifies that [ContextRoot.isAnalyzed] agrees with
  /// [ContextRoot.analyzedFiles] for every existing file and every path
  /// returned by [ContextRoot.analyzedFiles]. The latter may include logical
  /// paths through links or explicitly included files that do not exist.
  void _assertIsAnalyzedConsistent(AnalysisContextCollectionImpl collection) {
    var existingFiles = <File>[];

    void addExistingFiles(Folder folder, Set<Folder> activeCanonicalFolders) {
      if (folder.exists) {
        var canonicalFolder = folder.resolveSymbolicLinksSync() as Folder;
        if (activeCanonicalFolders.add(canonicalFolder)) {
          try {
            for (var child in folder.getChildren()) {
              if (child is File) {
                if (child.exists) {
                  existingFiles.add(child);
                }
              } else if (child is Folder) {
                addExistingFiles(child, activeCanonicalFolders);
              } else {
                fail('Unexpected resource: ${child.runtimeType}');
              }
            }
          } finally {
            activeCanonicalFolders.remove(canonicalFolder);
          }
        }
      }
    }

    addExistingFiles(getFolder('/'), {});

    for (var context in collection.contexts) {
      var contextRoot = context.contextRoot;
      var analyzedFiles = contextRoot.analyzedFiles().toSet();
      var pathsToProbe = {
        for (var file in existingFiles) file.path,
        ...analyzedFiles,
      };
      for (var path in pathsToProbe) {
        expect(
          contextRoot.isAnalyzed(path),
          analyzedFiles.contains(path),
          reason: 'context root: ${contextRoot.root.path}\npath: $path',
        );
      }
    }
  }

  /// Asserts the text of a context collection created for a single included
  /// workspace path, without any excludes.
  void _assertWorkspaceCollectionText(
    String workspaceRootPath,
    String expected, {
    File? optionsFile,
    void Function({required AnalysisOptionsBuilder analysisOptionsBuilder})?
    configureAnalysisOptionsBuilder,
  }) {
    if (optionsFile != null) {
      expect(optionsFile.exists, isTrue);
    }
    var collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [getFolder(workspaceRootPath).path],
      optionsFile: optionsFile?.path,
      configureAnalysisOptionsBuilder: configureAnalysisOptionsBuilder,
      withFineDependencies: true,
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
  final Map<Workspace, Map<WorkspacePackageImpl, String>> _workspacePackages =
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

  String _idOfWorkspacePackage(WorkspacePackageImpl package) {
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
      if (configuration.withIncludedPaths) {
        sink.writeElements(
          'includedPaths',
          contextRoot.includedPaths.toList(),
          (String path) {
            var resource = resourceProvider.getResource(path);
            sink.writelnWithIndent(resource.posixPath);
          },
        );
      }
      if (configuration.withExcludedPaths) {
        sink.writeElements(
          'excludedPaths',
          contextRoot.excludedPaths.toList(),
          (String path) {
            var resource = resourceProvider.getResource(path);
            sink.writelnWithIndent(resource.posixPath);
          },
        );
      }
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
        } else {
          sink.writelnWithIndent(file.posixPath);
        }
      });
      if (configuration.withExcludedGlobs) {
        sink.writeElements('excludedGlobs', contextRoot.excludedGlobs, (glob) {
          sink.writelnWithIndent(
            '${glob.glob.pattern} in ${glob.parent.posixPath}',
          );
        });
      }
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
          sink.writeElements('lintRules', analysisOptions.lintRules, (
            lintRule,
          ) {
            sink.writelnWithIndent(lintRule.name);
          });
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

  void _writeReferencedWorkspacePackages(Workspace workspace) {
    var packages = _workspacePackages[workspace]?.keys.toList() ?? const [];
    sink.writeElements('workspacePackages', packages, _writeWorkspacePackage);
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
      case BlazeWorkspace():
        sink.writelnWithIndent('$id: BlazeWorkspace');
        sink.withIndent(() {
          var root = resourceProvider.getFolder(workspace.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
          _writeReferencedWorkspacePackages(workspace);
        });
      case GnWorkspace():
        sink.writelnWithIndent('$id: GnWorkspace');
        sink.withIndent(() {
          var root = resourceProvider.getFolder(workspace.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
          _writeNamedFile('buildGnFile', workspace.buildGnFile);
          _writeReferencedWorkspacePackages(workspace);
        });

      default:
        throw UnimplementedError('${workspace.runtimeType}');
    }
  }

  void _writeWorkspacePackage(WorkspacePackageImpl package) {
    var id = _idOfWorkspacePackage(package);
    switch (package) {
      case BasicWorkspacePackage():
        sink.writelnWithIndent('$id: BasicWorkspacePackage');
        sink.withIndent(() {
          sink.writelnWithIndent('root: ${package.root.posixPath}');
        });
      case PubPackage():
        sink.writelnWithIndent('$id: PubPackage');
        sink.withIndent(() {
          sink.writelnWithIndent('root: ${package.root.posixPath}');
          var sdkVersionConstraint = package.sdkVersionConstraint;
          if (sdkVersionConstraint != null) {
            sink.writelnWithIndent(
              'sdkVersionConstraint: $sdkVersionConstraint',
            );
          }
        });
      case BlazeWorkspacePackage():
        sink.writelnWithIndent('$id: BlazeWorkspacePackage');
        sink.withIndent(() {
          sink.writelnWithIndent('root: ${package.root.posixPath}');
        });
      case GnWorkspacePackage():
        sink.writelnWithIndent('$id: GnWorkspacePackage');
        sink.withIndent(() {
          sink.writelnWithIndent('root: ${package.root.posixPath}');
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
  bool withExcludedPaths = false;
  bool withLintRules = false;
  bool withIncludedPaths = false;
  bool withOptionFilesForContext = false;
  bool withExcludedGlobs = false;
}
