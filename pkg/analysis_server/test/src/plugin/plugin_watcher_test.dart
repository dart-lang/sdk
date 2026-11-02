// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_trust.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/src/abstract_context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginWatcherTest);
  });
}

@reflectiveTest
class PluginWatcherTest extends AbstractContextTest {
  late TestPluginManager manager;
  late PluginWatcher watcher;

  /// Returns the existing analysis driver that should be used to analyze the
  /// given [file], or throw [StateError] if the [file] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisDriver driverFor(File file) {
    return contextFor2(file).driver;
  }

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

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);

    expect(manager.contextRootPlugins, isEmpty);
    watcher.addedDriver(driver);

    await pumpEventQueue();
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

    await pumpEventQueue();
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

    writeTestPackageConfig2(
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

    await pumpEventQueue();
    expect(manager.contextRootPlugins.values.first, hasLength(2));

    expect(manager.pluginIsolates, hasLength(2));

    var isolate0 = manager.pluginIsolates[0] as TestPluginIsolate;
    var isolate1 = manager.pluginIsolates[1] as TestPluginIsolate;
    expect(isolate0.pluginId, isNot(isolate1.pluginId));

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

    writeTestPackageConfig2(
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

    await pumpEventQueue();
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

  Future<void>
  test_addedDriver_multiple_plugins_conflictingOverridesOmission() async {
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

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);

    // Root options file has no overrides.
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
      dependencyOverrides: null,
    );
    driver.analysisOptionsMap[rootFolder] = rootBuilder.build();

    // Inner optinos file has override for 'dep' to path '/override'.
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
      dependencyOverrides: {'dep': PathPluginSource(path: '/override')},
    );
    driver.analysisOptionsMap[innerFolder] = innerBuilder.build();

    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins.values.first, hasLength(2));

    var pluginFolder1 = getFolder(manager.contextRootPlugins.values.first[0]);
    var pubspecFile1 = pluginFolder1.getFile('pubspec.yaml');
    var pubspecContent1 = pubspecFile1.readAsStringSync();

    var pluginFolder2 = getFolder(manager.contextRootPlugins.values.first[1]);
    var pubspecFile2 = pluginFolder2.getFile('pubspec.yaml');
    var pubspecContent2 = pubspecFile2.readAsStringSync();

    // One must have the override, and the other must not have
    // 'dependency_overrides'.
    expect(pubspecContent1, contains('dependency_overrides:'));
    expect(pubspecContent1, contains('/override'));
    expect(pubspecContent2, isNot(contains('dependency_overrides:')));
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

    writeTestPackageConfig2(
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

    await pumpEventQueue();
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

    writeTestPackageConfig2(
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

    await pumpEventQueue();
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

    writeTestPackageConfig2(
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

    await pumpEventQueue();
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

  Future<void>
  test_addedDriver_sameContextRoot_differentPluginConfigurations() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');

    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);
    watcher.addedDriver(driver);
    await pumpEventQueue();

    var pluginFolderPath1 = manager.contextRootPlugins.values.first.first;
    var pubspecFile1 = getFolder(pluginFolderPath1).getFile('pubspec.yaml');
    expect(pubspecFile1.readAsStringSync(), contains('^1.0.0'));

    // Simulate a second analysis (such as analyzing a different package in the
    // same Pub workspace root) with a different plugin configuration.
    watcher.removedDriver(driver);
    var rootFolder = getFolder(testPackageRootPath);
    var builder = AnalysisOptionsBuilder(
      file: rootFolder.getFile('analysis_options.yaml'),
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
    driver.analysisOptionsMap[rootFolder] = builder.build();

    watcher.addedDriver(driver);
    await pumpEventQueue();

    var pluginFolderPath2 = manager.contextRootPlugins.values.first.first;
    expect(pluginFolderPath2, isNot(pluginFolderPath1));
    // The first plugin state folder's pubspec was not overwritten.
    expect(pubspecFile1.readAsStringSync(), contains('^1.0.0'));
    var pubspecFile2 = getFolder(pluginFolderPath2).getFile('pubspec.yaml');
    expect(pubspecFile2.readAsStringSync(), contains('^2.0.0'));
  }

  void test_creation() {
    expect(watcher.resourceProvider, resourceProvider);
    expect(watcher.manager, manager);
  }

  Future<void>
  test_pluginTrust_contentTrusted_multiplePlugins_partialModification() async {
    newPubspecYamlFile('/p1', 'name: p1');
    newFile('/p1/lib/p1.dart', 'int v = 1;');
    newPubspecYamlFile('/p2', 'name: p2');
    newFile('/p2/lib/p2.dart', 'int v = 1;');
    newPubspecYamlFile('/p3', 'name: p3');
    newFile('/p3/lib/p3.dart', 'int v = 1;');

    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  p1: ^1.0.0
  p2: ^1.0.0
  p3: ^1.0.0
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'p1', rootFolder: getFolder('/p1'))
        ..add(name: 'p2', rootFolder: getFolder('/p2'))
        ..add(name: 'p3', rootFolder: getFolder('/p3')),
    );

    var driver = driverFor(testFile);
    var source = VersionedPluginSource(constraint: '^1.0.0');
    var pluginTrust = PluginTrust(resourceProvider)
      ..setContentTrust('p1', source, getFolder('/p1'))
      ..setContentTrust('p2', source, getFolder('/p2'))
      ..setContentTrust('p3', source, getFolder('/p3'));
    var notifications = <String>[];

    // Modify p2's contents while leaving p1 and p3 unchanged.
    newFile('/p2/lib/p2.dart', 'int v = 2;');

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins.values.first, hasLength(1));

    var pluginFolder = getFolder(manager.contextRootPlugins.values.first.first);
    var pubspecContent = pluginFolder
        .getFile('pubspec.yaml')
        .readAsStringSync();
    expect(pubspecContent, contains('p1:'));
    expect(pubspecContent, isNot(contains('p2:')));
    expect(pubspecContent, contains('p3:'));

    var rootPath = convertPath(testPackageRootPath);
    expect(notifications, [PluginWatcher.untrustedPluginsMessage(rootPath)]);
  }

  Future<void>
  test_pluginTrust_contentTrusted_resolvedFromPluginPackageConfig() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/lib/foo.dart', 'int x = 1;');
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');
    // Note: 'foo' is deliberately omitted from the analyzed package's
    // package_config.json so that resolution must read the synthetic plugin
    // package's package_config.json.
    writeTestPackageConfig2(config: PackageConfigFileBuilder());

    manager.onResolvePackageConfig = (pluginFolder) {
      writePackageConfig2(
        pluginFolder.path,
        config: PackageConfigFileBuilder()
          ..add(name: 'foo', rootFolder: getFolder('/foo')),
      );
      return pluginFolder
          .getFolder('.dart_tool')
          .getFile('package_config.json');
    };

    var driver = driverFor(testFile);
    var source = VersionedPluginSource(constraint: '^1.0.0');
    var pluginTrust = PluginTrust(resourceProvider)
      ..setContentTrust('foo', source, getFolder('/foo'));
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins, hasLength(1));
    expect(notifications, isEmpty);
  }

  Future<void>
  test_pluginTrust_contentTrusted_runsWhenUnchangedAndSkipsOnChange() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/lib/foo.dart', 'int x = 1;');
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);
    var source = VersionedPluginSource(constraint: '^1.0.0');
    var pluginTrust = PluginTrust(resourceProvider)
      ..setContentTrust('foo', source, getFolder('/foo'));
    var notifications = <String>[];

    // First run with unchanged plugin contents runs the plugin without notice.
    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins, hasLength(1));
    expect(notifications, isEmpty);

    // Modify the plugin's code contents; the next run should skip the plugin
    // and emit the untrusted notice.
    newFile('/foo/lib/foo.dart', 'int x = 2;');
    var manager2 = TestPluginManager(resourceProvider);
    var watcher2 = PluginWatcher(
      resourceProvider,
      manager2,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher2.addedDriver(driver);

    await pumpEventQueue();
    var rootPath = convertPath(testPackageRootPath);
    expect(manager2.contextRootPlugins, isEmpty);
    expect(notifications, [PluginWatcher.untrustedPluginsMessage(rootPath)]);
  }

  Future<void>
  test_pluginTrust_includedAnalysisOptions_checksTopLevelDirectoryOnly() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');
    newPubspecYamlFile('/other', 'name: other');
    newFile('/other/lib/options.yaml', '''
plugins:
  foo: ^1.0.0
''');
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
include: package:other/options.yaml
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo'))
        ..add(name: 'other', rootFolder: getFolder('/other')),
    );

    var driver = driverFor(testFile);
    var rootPath = convertPath(testPackageRootPath);

    // When the included plugin is unset, the notification references the
    // top-level package directory, not the included '/other' directory.
    var pluginTrust = PluginTrust(resourceProvider);
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins, isEmpty);
    expect(notifications, [PluginWatcher.untrustedPluginsMessage(rootPath)]);

    // Trusting the plugin resolved in the top-level options runs it.
    pluginTrust.setSourceTrust(
      'foo',
      VersionedPluginSource(constraint: '^1.0.0'),
      trusted: true,
    );
    var manager2 = TestPluginManager(resourceProvider);
    var watcher2 = PluginWatcher(
      resourceProvider,
      manager2,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher2.addedDriver(driver);

    await pumpEventQueue();
    expect(manager2.contextRootPlugins, hasLength(1));
    expect(notifications, hasLength(1));
  }

  Future<void> test_pluginTrust_legacyPlugin() async {
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
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);
    var rootPath = convertPath(testPackageRootPath);
    var pluginTrust = PluginTrust(resourceProvider);
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins, isEmpty);
    expect(notifications, [PluginWatcher.untrustedPluginsMessage(rootPath)]);

    var fooFolder = getFolder('/foo');
    pluginTrust.setContentTrust(
      'foo',
      PathPluginSource(path: fooFolder.path),
      fooFolder,
    );
    var manager2 = TestPluginManager(resourceProvider);
    var watcher2 = PluginWatcher(
      resourceProvider,
      manager2,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher2.addedDriver(driver);

    await pumpEventQueue();
    expect(manager2.contextRootPlugins, hasLength(1));
    expect(notifications, hasLength(1));
  }

  Future<void> test_pluginTrust_mixedTrustedUnsetAndUntrustedPlugins() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');
    newPubspecYamlFile('/bar', 'name: bar');
    newFile('/bar/tools/analyzer_plugin/bin/plugin.dart', '');
    newPubspecYamlFile('/baz', 'name: baz');
    newFile('/baz/tools/analyzer_plugin/bin/plugin.dart', '');

    // Root configures 'foo' (unset), 'bar' (trusted), and 'baz' (untrusted).
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
  bar: ^1.0.0
  baz: ^1.0.0
''');

    // 'trusted_inner' configures 'bar' (trusted).
    var trustedInnerPath = join(testPackageRootPath, 'trusted_inner');
    newFile(join(trustedInnerPath, 'analysis_options.yaml'), '''
plugins:
  bar: ^1.0.0
''');

    // 'untrusted_inner' configures 'baz' (explicitly untrusted).
    var untrustedInnerPath = join(testPackageRootPath, 'untrusted_inner');
    newFile(join(untrustedInnerPath, 'analysis_options.yaml'), '''
plugins:
  baz: ^1.0.0
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo'))
        ..add(name: 'bar', rootFolder: getFolder('/bar'))
        ..add(name: 'baz', rootFolder: getFolder('/baz')),
    );

    var driver = driverFor(testFile);

    var trustedInnerFolder = getFolder(trustedInnerPath);
    var trustedBuilder = AnalysisOptionsBuilder(
      file: trustedInnerFolder.getFile('analysis_options.yaml'),
    );
    trustedBuilder.pluginsOptions = PluginsOptions(
      configurations: [
        PluginConfiguration(
          name: 'bar',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
      ],
      dependencyOverrides: null,
    );
    driver.analysisOptionsMap[trustedInnerFolder] = trustedBuilder.build();

    var untrustedInnerFolder = getFolder(untrustedInnerPath);
    var untrustedBuilder = AnalysisOptionsBuilder(
      file: untrustedInnerFolder.getFile('analysis_options.yaml'),
    );
    untrustedBuilder.pluginsOptions = PluginsOptions(
      configurations: [
        PluginConfiguration(
          name: 'baz',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
      ],
      dependencyOverrides: null,
    );
    driver.analysisOptionsMap[untrustedInnerFolder] = untrustedBuilder.build();

    var pluginTrust = PluginTrust(resourceProvider)
      ..setSourceTrust(
        'bar',
        VersionedPluginSource(constraint: '^1.0.0'),
        trusted: true,
      )
      ..setSourceTrust(
        'baz',
        VersionedPluginSource(constraint: '^1.0.0'),
        trusted: false,
      );
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins.values.first, hasLength(1));

    var pluginFolder = getFolder(manager.contextRootPlugins.values.first.first);
    var pubspecContent = pluginFolder
        .getFile('pubspec.yaml')
        .readAsStringSync();
    expect(pubspecContent, contains('bar:'));
    expect(pubspecContent, isNot(contains('foo:')));
    expect(pubspecContent, isNot(contains('baz:')));

    var isolate = manager.pluginIsolates.single as TestPluginIsolate;
    var setConfigurations =
        isolate.requests.first as protocol.AnalysisSetConfigurationsParams;
    var config = setConfigurations.configurations;

    var rootPath = convertPath(testPackageRootPath);
    expect(config[rootPath]!.keys, ['bar']);
    expect(config[rootPath]!['bar']!.enabled, isTrue);
    expect(config[trustedInnerFolder.path]!['bar']!.enabled, isTrue);
    expect(config[untrustedInnerFolder.path], isEmpty);

    // Only the root directory (which has unset 'foo') should produce a
    // notification.
    expect(notifications, [PluginWatcher.untrustedPluginsMessage(rootPath)]);
  }

  Future<void>
  test_pluginTrust_nestedContextRoot_isolatesOptionsPerDriver() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/lib/foo.dart', 'int x = 1;');
    newPubspecYamlFile('/bar', 'name: bar');
    newFile('/bar/lib/bar.dart', 'int y = 1;');

    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');

    var nestedRootPath = join(testPackageRootPath, 'nested');
    newPubspecYamlFile(nestedRootPath, 'name: nested');
    newFile(join(nestedRootPath, 'analysis_options.yaml'), '''
plugins:
  bar: ^1.0.0
''');
    var nestedFile = newFile(join(nestedRootPath, 'lib', 'nested.dart'), '');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo'))
        ..add(name: 'bar', rootFolder: getFolder('/bar')),
    );
    writePackageConfig2(
      nestedRootPath,
      config: PackageConfigFileBuilder()
        ..add(name: 'nested', rootFolder: getFolder(nestedRootPath))
        ..add(name: 'bar', rootFolder: getFolder('/bar')),
    );

    var rootDriver = driverFor(testFile);
    var nestedDriver = driverFor(nestedFile);
    var nestedFolder = getFolder(nestedRootPath);

    var pluginTrust = PluginTrust(resourceProvider)
      ..setSourceTrust(
        'foo',
        VersionedPluginSource(constraint: '^1.0.0'),
        trusted: true,
      );
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(rootDriver);
    watcher.addedDriver(nestedDriver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins.keys, [
      rootDriver.analysisContext!.contextRoot,
    ]);
    expect(manager.contextRootsWithNoPlugins, {nestedFolder.path});
    expect(notifications, [
      PluginWatcher.untrustedPluginsMessage(nestedFolder.path),
    ]);
  }

  Future<void> test_pluginTrust_noPluginsOverride_skipsEvenWhenTrusted() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);
    var source = VersionedPluginSource(constraint: '^1.0.0');
    var pluginTrust = PluginTrust(resourceProvider)
      ..setSourceTrust('foo', source, trusted: true);

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: false,
      pluginTrust: pluginTrust,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins, isEmpty);
    expect(manager.initializedCompleter.isCompleted, isTrue);
    expect(pluginTrust.getTrust('foo', source), TrustSetting.trusted);
  }

  Future<void>
  test_pluginTrust_pluginsOverride_runsWithoutPersistingTrust() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);
    var pluginTrust = PluginTrust(resourceProvider);

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: true,
      pluginTrust: pluginTrust,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins, hasLength(1));
    expect(
      pluginTrust.getTrust('foo', VersionedPluginSource(constraint: '^1.0.0')),
      TrustSetting.unset,
    );
  }

  Future<void>
  test_pluginTrust_sourceTrusted_gitSource_ignoresRefChanges() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/lib/foo.dart', '');
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo:
    git:
      url: https://github.com/example/foo.git
      ref: v2.0.0
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);
    var pluginTrust = PluginTrust(resourceProvider)
      ..setSourceTrust(
        'foo',
        GitPluginSource(
          url: 'https://github.com/example/foo.git',
          ref: 'v1.0.0',
        ),
        trusted: true,
      );
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins, hasLength(1));
    expect(notifications, isEmpty);
  }

  Future<void> test_pluginTrust_sourceUntrusted_skipsSilently() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);
    var pluginTrust = PluginTrust(resourceProvider)
      ..setSourceTrust(
        'foo',
        VersionedPluginSource(constraint: '^1.0.0'),
        trusted: false,
      );
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    expect(manager.contextRootPlugins, isEmpty);
    expect(manager.initializedCompleter.isCompleted, isTrue);
    expect(notifications, isEmpty);
  }

  Future<void>
  test_pluginTrust_unseen_multipleDirectories_notifiesEachDirectory() async {
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

    writeTestPackageConfig2(
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

    var pluginTrust = PluginTrust(resourceProvider);
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    var rootPath = convertPath(testPackageRootPath);
    expect(manager.contextRootPlugins, isEmpty);
    expect(
      notifications,
      unorderedEquals([
        PluginWatcher.untrustedPluginsMessage(rootPath),
        PluginWatcher.untrustedPluginsMessage(innerFolder.path),
      ]),
    );
  }

  Future<void>
  test_pluginTrust_unseen_skipsPluginsAndNotifiesWithoutPersisting() async {
    newPubspecYamlFile('/foo', 'name: foo');
    newFile('/foo/tools/analyzer_plugin/bin/plugin.dart', '');
    newFile(join(testPackageRootPath, 'analysis_options.yaml'), '''
plugins:
  foo: ^1.0.0
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('/foo')),
    );

    var driver = driverFor(testFile);
    var pluginTrust = PluginTrust(resourceProvider);
    var notifications = <String>[];

    watcher = PluginWatcher(
      resourceProvider,
      manager,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher.addedDriver(driver);

    await pumpEventQueue();
    var rootPath = convertPath(testPackageRootPath);
    var source = VersionedPluginSource(constraint: '^1.0.0');
    expect(manager.contextRootPlugins, isEmpty);
    expect(manager.initializedCompleter.isCompleted, isTrue);
    expect(notifications, [PluginWatcher.untrustedPluginsMessage(rootPath)]);
    expect(pluginTrust.getTrust('foo', source), TrustSetting.unset);

    // Second run while still unseen should notify again.
    var manager2 = TestPluginManager(resourceProvider);
    var watcher2 = PluginWatcher(
      resourceProvider,
      manager2,
      pluginsAreEnabled: null,
      pluginTrust: pluginTrust,
      onUnseenUntrustedPluginDirectory: notifications.add,
    );
    watcher2.addedDriver(driver);

    await pumpEventQueue();
    expect(manager2.contextRootPlugins, isEmpty);
    expect(notifications, hasLength(2));
    expect(pluginTrust.getTrust('foo', source), TrustSetting.unset);
  }

  void test_removedDriver() {
    var driver = driverFor(testFile);
    watcher.addedDriver(driver);
    watcher.removedDriver(driver);
    expect(manager.contextRootPlugins, isEmpty);
  }
}
