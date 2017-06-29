// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginWatcherTest);
  });
}

@reflectiveTest
class PluginWatcherTest {
  MemoryResourceProvider resourceProvider;
  TestPluginManager manager;
  PluginWatcher watcher;

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    manager = new TestPluginManager();
    watcher = new PluginWatcher(resourceProvider, manager);
  }

  test_addedDriver() async {
    String pkg1Path = resourceProvider.convertPath('/pkg1');
    ContextRoot contextRoot = new ContextRoot(pkg1Path, []);
    TestDriver driver = new TestDriver(resourceProvider, contextRoot);
    watcher.addedDriver(driver, contextRoot);
    expect(manager.addedContextRoots, isEmpty);
    //
    // Test to see whether the listener was configured correctly.
    //
    // Use a file in the package being analyzed.
    //
    resourceProvider.newFile(
        resourceProvider.convertPath('/pkg1/lib/test1.dart'), '');
    await driver.computeResult('package:pkg1/test1.dart');
    expect(manager.addedContextRoots, isEmpty);
    //
    // Use a file that imports a package with a plugin.
    //
    resourceProvider.newFile(
        resourceProvider.convertPath('/pkg2/lib/pkg2.dart'), '');
    resourceProvider.newFile(
        resourceProvider.convertPath('/pkg2/pubspec.yaml'), 'name: pkg2');
    resourceProvider.newFile(
        resourceProvider.convertPath(
            '/pkg2/${PluginLocator.toolsFolderName}/${PluginLocator.defaultPluginFolderName}/bin/plugin.dart'),
        '');
    await driver.computeResult('package:pkg2/pk2.dart');
    //
    // Wait until the timer associated with the driver's FileSystemState is
    // guaranteed to have expired and the list of changed files will have been
    // delivered.
    //
    await new Future.delayed(new Duration(seconds: 1));
    expect(manager.addedContextRoots, hasLength(1));
  }

  void test_creation() {
    expect(watcher.resourceProvider, resourceProvider);
    expect(watcher.manager, manager);
  }

  test_removedDriver() {
    String pkg1Path = resourceProvider.convertPath('/pkg1');
    ContextRoot contextRoot = new ContextRoot(pkg1Path, []);
    TestDriver driver = new TestDriver(resourceProvider, contextRoot);
    watcher.addedDriver(driver, contextRoot);
    watcher.removedDriver(driver);
    expect(manager.removedContextRoots, equals([contextRoot]));
  }
}

class TestDriver implements AnalysisDriver {
  final MemoryResourceProvider resourceProvider;

  SourceFactory sourceFactory;
  FileSystemState fsState;
  AnalysisSession currentSession;

  final _resultController = new StreamController<AnalysisResult>();

  TestDriver(this.resourceProvider, ContextRoot contextRoot) {
    path.Context pathContext = resourceProvider.pathContext;
    MockSdk sdk = new MockSdk(resourceProvider: resourceProvider);
    String packageName = pathContext.basename(contextRoot.root);
    String libPath = pathContext.join(contextRoot.root, 'lib');
    sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      new PackageMapUriResolver(resourceProvider, {
        packageName: [resourceProvider.getFolder(libPath)],
        'pkg2': [
          resourceProvider.getFolder(resourceProvider.convertPath('/pkg2/lib'))
        ]
      })
    ]);
    fsState = new FileSystemState(
        new PerformanceLog(null),
        new MemoryByteStore(),
        null,
        resourceProvider,
        sourceFactory,
        new AnalysisOptionsImpl(),
        new Uint32List(0));
    currentSession = new AnalysisSessionImpl(this);
  }

  Stream<AnalysisResult> get results => _resultController.stream;

  Future<Null> computeResult(String uri) {
    FileState file = fsState.getFileForUri(Uri.parse(uri));
    AnalysisResult result = new AnalysisResult(
        this, null, file.path, null, true, null, null, null, null, null, null);
    _resultController.add(result);
    return new Future.delayed(new Duration(milliseconds: 1));
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPluginManager implements PluginManager {
  List<ContextRoot> addedContextRoots = <ContextRoot>[];

  List<ContextRoot> removedContextRoots = <ContextRoot>[];

  @override
  Future<Null> addPluginToContextRoot(
      ContextRoot contextRoot, String path) async {
    addedContextRoots.add(contextRoot);
    return null;
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void removedContextRoot(ContextRoot contextRoot) {
    removedContextRoots.add(contextRoot);
  }
}
