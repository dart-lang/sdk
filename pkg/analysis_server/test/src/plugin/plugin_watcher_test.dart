// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginWatcherTest);
  });
}

@reflectiveTest
class PluginWatcherTest extends AbstractContextTest {
  late TestPluginManager manager;
  late PluginWatcher watcher;

  @override
  void setUp() {
    super.setUp();
    manager = TestPluginManager(resourceProvider);
    watcher = PluginWatcher(resourceProvider, manager, pluginsAreEnabled: true);
  }

  Future<void> test_addedDriver() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile(
      join(
        '/foo',
        PluginLocator.toolsFolderName,
        PluginLocator.defaultPluginFolderName,
        'bin',
        'plugin.dart',
      ),
      '',
    );
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
analyzer:
  plugins:
    - foo
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);

    expect(manager.contextRootPlugins, isEmpty);
    watcher.addedDriver(driver);

    await _waitForEvents();
    expect(manager.contextRootPlugins, hasLength(1));
  }

  Future<void> test_addedDriver_missingPackage() async {
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
analyzer:
  plugins:
    - no_such_package
''');
    var driver = driverFor(testFile);

    watcher.addedDriver(driver);
    expect(manager.contextRootPlugins, isEmpty);

    await _waitForEvents();
    expect(manager.contextRootPlugins, isEmpty);
  }

  Future<void> test_addedDriver_multiple_plugins_conflicting() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');

    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');

    var innerFolderPath = join(testPackageRootPath, 'inner');
    newFile(join(innerFolderPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^2.0.0
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);

    // Manually add the inner options to the driver's options map to simulate
    // them being in the same context (e.g. in a Blaze workspace).
    var innerFolder = getFolder(innerFolderPath);
    var builder = AnalysisOptionsBuilder(
      file: innerFolder.getFile('analysis_options.yaml'),
    );
    builder.pluginsOptions = PluginsOptions(
      configurations: [
        PluginConfiguration(
          name: 'foo',
          source: VersionedPluginSource(constraint: '^2.0.0'),
        ),
      ],
      dependencyOverrides: null,
    );
    driver.analysisOptionsMap[innerFolder] = builder.build();

    watcher.addedDriver(driver);

    await _waitForEvents();
    expect(manager.contextRootPlugins.values.first, hasLength(2));

    expect(manager.pluginIsolates, hasLength(2));

    var isolate0 = manager.pluginIsolates.firstWhere(
      (e) => !e.pluginId.contains('_group_1'),
    ) as TestPluginIsolate;
    var isolate1 = manager.pluginIsolates.firstWhere(
      (e) => e.pluginId.contains('_group_1'),
    ) as TestPluginIsolate;

    var setConfigurations0 =
        isolate0.requests.first as protocol.AnalysisSetConfigurationsParams;
    var config0 = setConfigurations0.configurations;

    var setConfigurations1 =
        isolate1.requests.first as protocol.AnalysisSetConfigurationsParams;
    var config1 = setConfigurations1.configurations;

    var rootPath = convertPath(testPackageRootPath);
    var innerPath = innerFolder.path;

    expect(config0[rootPath], isEmpty);
    expect(config0[innerPath]!['foo']!.enabled, isTrue);

    expect(config1[rootPath]!['foo']!.enabled, isTrue);
    expect(config1[innerPath], isEmpty);
  }

  Future<void> test_addedDriver_multiple_plugins_conflictingOverrides() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');

    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');

    var innerFolderPath = join(testPackageRootPath, 'inner');
    newFile(join(innerFolderPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);

    // Root has override for 'dep' to path '/override1'
    var rootFolder = getFolder(testPackageRootPath);
    var rootBuilder = AnalysisOptionsBuilder(
      file: rootFolder.getFile('analysis_options.yaml'),
    );
    rootBuilder.pluginsOptions = PluginsOptions(
      configurations: [
        PluginConfiguration(
          name: 'foo',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
      ],
      dependencyOverrides: {'dep': PathPluginSource(path: '/override1')},
    );
    driver.analysisOptionsMap[rootFolder] = rootBuilder.build();

    // Inner has override for 'dep' to path '/override2'
    var innerFolder = getFolder(innerFolderPath);
    var innerBuilder = AnalysisOptionsBuilder(
      file: innerFolder.getFile('analysis_options.yaml'),
    );
    innerBuilder.pluginsOptions = PluginsOptions(
      configurations: [
        PluginConfiguration(
          name: 'foo',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
      ],
      dependencyOverrides: {'dep': PathPluginSource(path: '/override2')},
    );
    driver.analysisOptionsMap[innerFolder] = innerBuilder.build();

    watcher.addedDriver(driver);

    await _waitForEvents();
    expect(manager.contextRootPlugins.values.first, hasLength(2));

    var pluginFolder1 = getFolder(manager.contextRootPlugins.values.first[0]);
    var pubspecFile1 = pluginFolder1.getFile('pubspec.yaml');
    var pubspecContent1 = pubspecFile1.readAsStringSync();

    var pluginFolder2 = getFolder(manager.contextRootPlugins.values.first[1]);
    var pubspecFile2 = pluginFolder2.getFile('pubspec.yaml');
    var pubspecContent2 = pubspecFile2.readAsStringSync();

    var paths = [
      if (pubspecContent1.contains('/override1')) 1,
      if (pubspecContent1.contains('/override2')) 2,
      if (pubspecContent2.contains('/override1')) 1,
      if (pubspecContent2.contains('/override2')) 2,
    ];
    expect(paths, unorderedEquals([1, 2]));
  }

  Future<void> test_addedDriver_multiple_plugins_grouped() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');
    newPubspecYamlFile('/bar', 'name: bar');
    newFile('/bar/tools/analyzer_plugin/bin/plugin.dart', '');

    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');

    var innerFolderPath = join(testPackageRootPath, 'inner');
    newFile(join(innerFolderPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
  bar: ^1.0.0
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo'))
        ..add(name: 'bar', rootFolder: getFolder('/bar')),
    );

    var driver = driverFor(testFile);

    // Manually add the inner options to the driver's options map to simulate
    // them being in the same context (e.g. in a Blaze workspace).
    var innerFolder = getFolder(innerFolderPath);
    var builder = AnalysisOptionsBuilder(
      file: innerFolder.getFile('analysis_options.yaml'),
    );
    builder.pluginsOptions = PluginsOptions(
      configurations: [
        PluginConfiguration(
          name: 'foo',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
        PluginConfiguration(
          name: 'bar',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
      ],
      dependencyOverrides: null,
    );
    driver.analysisOptionsMap[innerFolder] = builder.build();

    watcher.addedDriver(driver);

    await _waitForEvents();
    expect(manager.contextRootPlugins.values.first, hasLength(1));

    var pluginFolder = getFolder(manager.contextRootPlugins.values.first.first);
    var pubspecFile = pluginFolder.getFile('pubspec.yaml');
    var pubspecContent = pubspecFile.readAsStringSync();
    // The 'foo' dependency should only appear once in the pubspec.
    expect(' foo:'.allMatches(pubspecContent), hasLength(1));

    var entrypointFile = pluginFolder.getFolder('bin').getFile('plugin.dart');
    var entrypointContent = entrypointFile.readAsStringSync();
    // The 'foo' import should only appear once in the pubspec.
    expect(
      "import 'package:foo/main.dart'".allMatches(entrypointContent),
      hasLength(1),
    );
    // 'foo' should only appear once in the entrypoint.
    expect("'foo': foo.plugin".allMatches(entrypointContent), hasLength(1));
  }

  Future<void> test_addedDriver_pluginsInInnerOnly() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');

    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
analyzer:
''');

    var innerFolderPath = join(testPackageRootPath, 'inner');
    newFile(join(innerFolderPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);

    var innerFolder = getFolder(innerFolderPath);
    var builder = AnalysisOptionsBuilder(
      file: innerFolder.getFile('analysis_options.yaml'),
    );
    builder.pluginsOptions = PluginsOptions(
      configurations: [
        PluginConfiguration(
          name: 'foo',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
      ],
      dependencyOverrides: null,
    );
    driver.analysisOptionsMap[innerFolder] = builder.build();

    expect(manager.contextRootPlugins, isEmpty);
    watcher.addedDriver(driver);

    await _waitForEvents();
    expect(manager.contextRootPlugins, hasLength(1));
  }

  Future<void> test_addedDriver_pluginsInRoot_emptyInInner() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');

    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');

    var innerFolderPath = join(testPackageRootPath, 'inner');
    newFile(join(innerFolderPath, 'analysis_options.yaml'), '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);

    // Manually add the empty inner options to the driver's options map.
    var innerFolder = getFolder(innerFolderPath);
    var builder = AnalysisOptionsBuilder(
      file: innerFolder.getFile('analysis_options.yaml'),
    );
    builder.pluginsOptions = PluginsOptions(
      configurations: [],
      dependencyOverrides: null,
    );
    driver.analysisOptionsMap[innerFolder] = builder.build();

    watcher.addedDriver(driver);

    await _waitForEvents();
    expect(manager.contextRootPlugins.values.first, hasLength(1));

    expect(manager.pluginIsolates, hasLength(1));
    var isolate = manager.pluginIsolates.first as TestPluginIsolate;

    var setConfigurations =
        isolate.requests.first as protocol.AnalysisSetConfigurationsParams;
    var config = setConfigurations.configurations;

    var rootPath = convertPath(testPackageRootPath);
    var innerPath = innerFolder.path;

    expect(config[rootPath]!['foo']!.enabled, isTrue);
    expect(config[innerPath], isEmpty);
  }

  void test_creation() {
    expect(watcher.resourceProvider, resourceProvider);
    expect(watcher.manager, manager);
  }

  void test_removedDriver() {
    var driver = driverFor(testFile);
    watcher.addedDriver(driver);
    watcher.removedDriver(driver);
    expect(manager.contextRootPlugins, isEmpty);
  }

  /// Wait until the timer associated with the driver's FileSystemState is
  /// guaranteed to have expired and the list of changed files will have been
  /// delivered.
  Future<void> _waitForEvents() async {
    await Future.delayed(Duration(seconds: 1));
  }
}
