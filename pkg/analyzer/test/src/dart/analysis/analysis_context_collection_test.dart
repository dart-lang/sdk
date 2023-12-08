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
        workspacePackage_0_0
  /home/test/lib/nested
    optionsFile: /home/test/lib/nested/analysis_options.yaml
    packagesFile: /home/test/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/test/lib/nested/b.dart
        workspacePackage_1_0
workspaces
  workspace_0: PubWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubWorkspacePackage
        root: /home/test
  workspace_1: PubWorkspace
    root: /home/test
    pubPackages
      workspacePackage_1_0: PubWorkspacePackage
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

    final nestedPackageRootPath = '$testPackageRootPath/nested';
    newPubspecYamlFile(nestedPackageRootPath, r'''
name: nested
''');
    newSinglePackageConfigJsonFile(
      packagePath: nestedPackageRootPath,
      name: 'nested',
    );
    newFile('$nestedPackageRootPath/lib/b.dart', '');

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
        workspacePackage_0_0
  /home/test/nested
    packagesFile: /home/test/nested/.dart_tool/package_config.json
    workspace: workspace_1
    analyzedFiles
      /home/test/nested/lib/b.dart
        workspacePackage_1_0
workspaces
  workspace_0: PubWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubWorkspacePackage
        root: /home/test
  workspace_1: PubWorkspace
    root: /home/test/nested
    pubPackages
      workspacePackage_1_0: PubWorkspacePackage
        root: /home/test/nested
''');
  }

  test_pubWorkspace_sdkVersionConstraint() async {
    final workspaceRootPath = '/home';
    final testPackageRootPath = '$workspaceRootPath/test';

    newPubspecYamlFile(testPackageRootPath, r'''
environment:
  sdk: ^3.0.0
''');

    newSinglePackageConfigJsonFile(
      packagePath: testPackageRootPath,
      name: 'test',
    );

    newFile('$testPackageRootPath/lib/a.dart', '');

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
        workspacePackage_0_0
workspaces
  workspace_0: PubWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubWorkspacePackage
        root: /home/test
        sdkVersionConstraint: ^3.0.0
''');
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
        workspacePackage_0_0
workspaces
  workspace_0: PubWorkspace
    root: /home/test
    pubPackages
      workspacePackage_0_0: PubWorkspacePackage
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

    sink.writeElements(
      'workspaces',
      _workspaces.keys.toList(),
      _writeWorkspace,
    );
  }

  String _idOfWorkspace(Workspace workspace) {
    return _indexIdOfWorkspace(workspace).$2;
  }

  String _idOfWorkspacePackage(WorkspacePackage package) {
    final workspace = package.workspace;
    final packages = _workspacePackages[workspace] ??= Map.identity();
    if (packages[package] case final id?) {
      return id;
    } else {
      final workspaceIndex = _indexIdOfWorkspace(workspace).$1;
      final id = 'workspacePackage_${workspaceIndex}_${packages.length}';
      return packages[package] ??= id;
    }
  }

  (int, String) _indexIdOfWorkspace(Workspace workspace) {
    if (_workspaces[workspace] case final existing?) {
      return existing;
    }

    final index = _workspaces.length;
    final id = 'workspace_$index';
    return _workspaces[workspace] = (index, id);
  }

  bool _isDartFile(File file) {
    return file_paths.isDart(resourceProvider.pathContext, file.path);
  }

  void _writeAnalysisContext(AnalysisContext analysisContext) {
    final contextRoot = analysisContext.contextRoot;
    final workspace = contextRoot.workspace;

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
        if (_isDartFile(file)) {
          sink.writelnWithIndent(file.posixPath);
          sink.withIndent(() {
            final workspacePackage = workspace.findPackageFor(path);
            if (workspacePackage != null) {
              final id = _idOfWorkspacePackage(workspacePackage);
              sink.writelnWithIndent(id);
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
            'pubPackages',
            workspace.pubPackages.toList(),
            _writeWorkspacePackage,
          );
        });

      default:
        throw UnimplementedError('${workspace.runtimeType}');
    }
  }

  void _writeWorkspacePackage(WorkspacePackage package) {
    final id = _idOfWorkspacePackage(package);
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
          final sdkVersionConstraint = package.sdkVersionConstraint;
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
  bool withEmptyContextRoots = false;
}
