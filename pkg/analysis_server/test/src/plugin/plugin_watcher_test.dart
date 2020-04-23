// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginWatcherTest);
  });
}

@reflectiveTest
class PluginWatcherTest with ResourceProviderMixin {
  TestPluginManager manager;
  PluginWatcher watcher;

  void setUp() {
    manager = TestPluginManager();
    watcher = PluginWatcher(resourceProvider, manager);
  }

  Future<void> test_addedDriver() async {
    var pkg1Path = newFolder('/pkg1').path;
    newFile('/pkg1/lib/test1.dart');
    newFile('/pkg2/lib/pkg2.dart');
    newFile('/pkg2/pubspec.yaml', content: 'name: pkg2');
    newFile(
        '/pkg2/${PluginLocator.toolsFolderName}/${PluginLocator.defaultPluginFolderName}/bin/plugin.dart');

    var contextRoot =
        ContextRoot(pkg1Path, [], pathContext: resourceProvider.pathContext);
    var driver = TestDriver(resourceProvider, contextRoot);
    driver.analysisOptions.enabledPluginNames = ['pkg2'];
    expect(manager.addedContextRoots, isEmpty);
    watcher.addedDriver(driver, contextRoot);
    //
    // Test to see whether the listener was configured correctly.
    //
    // Use a file in the package being analyzed.
    //
//    await driver.computeResult('package:pkg1/test1.dart');
//    expect(manager.addedContextRoots, isEmpty);
    //
    // Use a file that imports a package with a plugin.
    //
//    await driver.computeResult('package:pkg2/pk2.dart');
    //
    // Wait until the timer associated with the driver's FileSystemState is
    // guaranteed to have expired and the list of changed files will have been
    // delivered.
    //
    await Future.delayed(Duration(seconds: 1));
    expect(manager.addedContextRoots, hasLength(1));
  }

  Future<void> test_addedDriver_missingPackage() async {
    var pkg1Path = newFolder('/pkg1').path;
    newFile('/pkg1/lib/test1.dart');

    var contextRoot =
        ContextRoot(pkg1Path, [], pathContext: resourceProvider.pathContext);
    var driver = TestDriver(resourceProvider, contextRoot);
    driver.analysisOptions.enabledPluginNames = ['pkg3'];
    watcher.addedDriver(driver, contextRoot);
    expect(manager.addedContextRoots, isEmpty);
    //
    // Wait until the timer associated with the driver's FileSystemState is
    // guaranteed to have expired and the list of changed files will have been
    // delivered.
    //
    await Future.delayed(Duration(seconds: 1));
    expect(manager.addedContextRoots, isEmpty);
  }

  void test_creation() {
    expect(watcher.resourceProvider, resourceProvider);
    expect(watcher.manager, manager);
  }

  void test_removedDriver() {
    var pkg1Path = newFolder('/pkg1').path;
    var contextRoot =
        ContextRoot(pkg1Path, [], pathContext: resourceProvider.pathContext);
    var driver = TestDriver(resourceProvider, contextRoot);
    watcher.addedDriver(driver, contextRoot);
    watcher.removedDriver(driver);
    expect(manager.removedContextRoots, equals([contextRoot]));
  }
}

class TestDriver implements AnalysisDriver {
  @override
  final MemoryResourceProvider resourceProvider;

  @override
  SourceFactory sourceFactory;
  @override
  AnalysisSession currentSession;
  @override
  AnalysisOptionsImpl analysisOptions = AnalysisOptionsImpl();

  final _resultController = StreamController<ResolvedUnitResult>();

  TestDriver(this.resourceProvider, ContextRoot contextRoot) {
    var pathContext = resourceProvider.pathContext;
    var sdk = MockSdk(resourceProvider: resourceProvider);
    var packageName = pathContext.basename(contextRoot.root);
    var libPath = pathContext.join(contextRoot.root, 'lib');
    sourceFactory = SourceFactory([
      DartUriResolver(sdk),
      PackageMapUriResolver(resourceProvider, {
        packageName: [resourceProvider.getFolder(libPath)],
        'pkg2': [
          resourceProvider.getFolder(resourceProvider.convertPath('/pkg2/lib'))
        ]
      })
    ]);
    currentSession = AnalysisSessionImpl(this);
  }

  @override
  Stream<ResolvedUnitResult> get results => _resultController.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPluginManager implements PluginManager {
  List<ContextRoot> addedContextRoots = <ContextRoot>[];

  List<ContextRoot> removedContextRoots = <ContextRoot>[];

  @override
  Future<void> addPluginToContextRoot(
      ContextRoot contextRoot, String path) async {
    addedContextRoots.add(contextRoot);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void recordPluginFailure(String hostPackageName, String message) {}

  @override
  void removedContextRoot(ContextRoot contextRoot) {
    removedContextRoots.add(contextRoot);
  }
}
