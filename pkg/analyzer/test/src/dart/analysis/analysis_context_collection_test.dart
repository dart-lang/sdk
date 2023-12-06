// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/tree_string_sink.dart';
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
    newPackageConfigJsonFile(
      rootFolder.path,
      packageConfigFileBuilder.toContent(toUriStr: toUriStr),
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

    var innerFolder = newFolder('/test/outer/inner');
    newAnalysisOptionsYamlFile('/test/outer/inner', '');
    newFile('/test/outer/inner/inner.dart', '');

    var collection = _newCollection(includedPaths: [outerFolder.path]);

    expect(collection.contexts, hasLength(2));

    var outerContext = collection.contexts
        .singleWhere((c) => c.contextRoot.root == outerFolder);
    var innerContext = collection.contexts
        .singleWhere((c) => c.contextRoot.root == innerFolder);
    expect(innerContext, isNot(same(outerContext)));

    // Outer and inner contexts own corresponding files.
    expect(collection.contextFor(convertPath('/test/outer/lib/outer.dart')),
        same(outerContext));
    expect(collection.contextFor(convertPath('/test/outer/inner/inner.dart')),
        same(innerContext));

    // The file does not have to exist, during creation, or at all.
    expect(collection.contextFor(convertPath('/test/outer/lib/outer2.dart')),
        same(outerContext));
    expect(collection.contextFor(convertPath('/test/outer/inner/inner2.dart')),
        same(innerContext));
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

  File newPackageConfigJsonFileFromBuilder(
    String directoryPath,
    PackageConfigFileBuilder builder,
  ) {
    final content = builder.toContent(toUriStr: toUriStr);
    return newPackageConfigJsonFile(directoryPath, content);
  }

  void newSinglePackageConfigJsonFile({
    required String packagePath,
    required String name,
  }) {
    final builder = PackageConfigFileBuilder()
      ..add(name: name, rootPath: packagePath);
    newPackageConfigJsonFileFromBuilder(packagePath, builder);
  }

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    registerLintRules();
  }

  test_pubWorkspace_multipleAnalysisOptions() async {
    final workspaceRootPath = '/home';
    final testPackageRootPath = '$workspaceRootPath/test';
    final testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newAnalysisOptionsYamlFile(testPackageRootPath, '');
    newFile('$testPackageLibPath/a.dart', '');

    final nestedPath = '$testPackageLibPath/nested';
    newAnalysisOptionsYamlFile(nestedPath, '');
    newFile('$nestedPath/b.dart', '');

    final contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(workspaceRootPath).path,
      ],
    );

    _assertContextCollectionText(contextCollection, r'''
contexts
  /home/test
    optionsFile: /home/test/analysis_options.yaml
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage: workspace_0_package_0
  /home/test/lib/nested
    optionsFile: /home/test/lib/nested/analysis_options.yaml
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/test/lib/nested/b.dart
        workspacePackage: workspace_1_package_0
workspaces
  workspace_0: PubWorkspace
    root: /home/test
    packages
      package_0: PubWorkspacePackage
        root: /home/test
  workspace_1: PubWorkspace
    root: /home/test
    packages
      package_0: PubWorkspacePackage
        root: /home/test
''');
  }

  test_pubWorkspace_multiplePackageConfigs() async {
    final workspaceRootPath = '/home';
    final testPackageRootPath = '$workspaceRootPath/test';
    final testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newFile('$testPackageLibPath/a.dart', '');

    final nestedPath = '$testPackageRootPath/nested';
    newFile('$nestedPath/b.dart', '');
    newSinglePackageConfigJsonFile(
      packagePath: nestedPath,
      name: 'nested',
    );
    newPubspecYamlFile(nestedPath, r'''
name: nested
''');

    final contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(workspaceRootPath).path,
      ],
    );

    _assertContextCollectionText(contextCollection, r'''
contexts
  /home/test
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage: workspace_0_package_0
  /home/test/nested
    packagesFile: /home/test/nested/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/test/nested/b.dart
        workspacePackage: workspace_1_package_0
workspaces
  workspace_0: PubWorkspace
    root: /home/test
    packages
      package_0: PubWorkspacePackage
        root: /home/test
  workspace_1: PubWorkspace
    root: /home/test/nested
    packages
      package_0: PubWorkspacePackage
        root: /home/test/nested
''');
  }

  // TODO(pq): update to using the golden format when packages are enumerated.
  // See: https://dart-review.googlesource.com/c/sdk/+/339781
  test_pubWorkspace_sdkConstraint() async {
    final workspaceRootPath = '/home';
    final testPackageRootPath = '$workspaceRootPath/test';
    final testFilePath = '$testPackageRootPath/a.dart';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
environment:
  sdk: ^3.0.0
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newFile(testFilePath, '');

    final contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(workspaceRootPath).path,
      ],
    );

    final context = contextCollection.contextFor(testFilePath);
    final package = context.contextRoot.workspace.findPackageFor(testFilePath)
        as PubWorkspacePackage;
    expect(package.sdkVersionConstraint.toString(), '^3.0.0');
  }

  test_pubWorkspace_singleAnalysisOptions() async {
    final workspaceRootPath = '/home';
    final testPackageRootPath = '$workspaceRootPath/test';
    final testPackageLibPath = '$testPackageRootPath/lib';

    newPubspecYamlFile(testPackageRootPath, r'''
name: test
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newAnalysisOptionsYamlFile(testPackageRootPath, '');

    newFile('$testPackageLibPath/a.dart', '');

    final contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      includedPaths: [
        getFolder(workspaceRootPath).path,
      ],
    );

    _assertContextCollectionText(contextCollection, r'''
contexts
  /home/test
    optionsFile: /home/test/analysis_options.yaml
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_0
    analyzedFiles
      /home/test/lib/a.dart
        workspacePackage: workspace_0_package_0
workspaces
  workspace_0: PubWorkspace
    root: /home/test
    packages
      package_0: PubWorkspacePackage
        root: /home/test
''');
  }

  void _assertContextCollectionText(
    AnalysisContextCollectionImpl contextCollection,
    String expected,
  ) {
    final actual = _getContextCollectionText(contextCollection);
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  String _getContextCollectionText(
    AnalysisContextCollectionImpl contextCollection,
  ) {
    final buffer = StringBuffer();
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

  final Map<Workspace, String> _workspaces = Map.identity();
  final Map<Workspace, Map<WorkspacePackage, String>> workspacePackages =
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

    sink.writeElements(
      'workspaces',
      _workspaces.keys.toList(),
      _writeWorkspace,
    );
  }

  String _idOfPackage(WorkspacePackage package) {
    final packages = workspacePackages[package.workspace] ??= Map.identity();
    return packages[package] ??= 'package_${packages.length}';
  }

  String _idOfWorkspace(Workspace workspace) {
    return _workspaces[workspace] ??= 'workspace_${_workspaces.length}';
  }

  bool _isDartFile(File file) {
    return file_paths.isDart(resourceProvider.pathContext, file.path);
  }

  void _writeAnalysisContext(AnalysisContext analysisContext) {
    final contextRoot = analysisContext.contextRoot;

    final analyzedFiles = contextRoot.analyzedFiles().toList();
    if (!configuration.withEmptyContextRoots && analyzedFiles.isEmpty) {
      return;
    }

    sink.writelnWithIndent(contextRoot.root.posixPath);
    sink.withIndent(() {
      _writeNamedFile('optionsFile', contextRoot.optionsFile);
      _writeNamedFile('packagesFile', contextRoot.packagesFile);
      sink.writelnWithIndent(
        'workspace: ${_idOfWorkspace(contextRoot.workspace)}',
      );
      sink.writeElements('analyzedFiles', analyzedFiles, (path) {
        final file = resourceProvider.getFile(path);
        final workspace = contextRoot.workspace;
        if (_isDartFile(file)) {
          sink.writelnWithIndent(file.posixPath);
          sink.withIndent(() {
            final package = workspace.findPackageFor(path);
            if (package != null) {
              sink.writelnWithIndent(
                  'workspacePackage: ${_idOfWorkspace(workspace)}_${_idOfPackage(package)}');
            }
          });
        }
      });
    });
  }

  void _writeNamedFile(String name, File? file) {
    if (file != null) {
      sink.writelnWithIndent('$name: ${file.posixPath}');
    }
  }

  void _writePackage(WorkspacePackage package) {
    final id = _idOfPackage(package);
    switch (package) {
      case BasicWorkspacePackage():
        sink.writelnWithIndent('$id: BasicWorkspacePackage');
        sink.withIndent(() {
          final root = resourceProvider.getFolder(package.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
        });
      case PubWorkspacePackage():
        sink.writelnWithIndent('$id: PubWorkspacePackage');
        sink.withIndent(() {
          final root = resourceProvider.getFolder(package.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
        });
      default:
        throw UnimplementedError('${package.runtimeType}');
    }
  }

  void _writeWorkspace(Workspace workspace) {
    final id = _idOfWorkspace(workspace);
    switch (workspace) {
      case BasicWorkspace():
        sink.writelnWithIndent('$id: BasicWorkspace');
        sink.withIndent(() {
          final root = resourceProvider.getFolder(workspace.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
        });
      case PubWorkspace():
        sink.writelnWithIndent('$id: PubWorkspace');
        sink.withIndent(() {
          final root = resourceProvider.getFolder(workspace.root);
          sink.writelnWithIndent('root: ${root.posixPath}');
          sink.writeElements(
            'packages',
            workspace.pubPackages.toList(),
            _writePackage,
          );
        });

      default:
        throw UnimplementedError('${workspace.runtimeType}');
    }
  }
}

class _AnalysisContextCollectionPrinterConfiguration {
  bool withEmptyContextRoots = false;
}
