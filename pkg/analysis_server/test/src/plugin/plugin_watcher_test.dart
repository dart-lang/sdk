// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
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
    manager = TestPluginManager();
    watcher = PluginWatcher(resourceProvider, manager);
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
        ..add(name: 'foo', rootPath: convertPath('/foo')),
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
