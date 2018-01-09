// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart'
    hide ContextRoot;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart' as watcher;

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInPluginInfoTest);
    defineReflectiveTests(DiscoveredPluginInfoTest);
    defineReflectiveTests(PluginManagerTest);
    defineReflectiveTests(PluginManagerFromDiskTest);
    defineReflectiveTests(PluginSessionTest);
    defineReflectiveTests(PluginSessionFromDiskTest);
  });
}

@reflectiveTest
class BuiltInPluginInfoTest {
  TestNotificationManager notificationManager;
  BuiltInPluginInfo plugin;

  void setUp() {
    notificationManager = new TestNotificationManager();
    plugin = new BuiltInPluginInfo(null, 'test plugin', notificationManager,
        InstrumentationService.NULL_SERVICE);
  }

  test_addContextRoot() {
    ContextRoot contextRoot1 = new ContextRoot('/pkg1', []);
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
  }

  test_creation() {
    expect(plugin.pluginId, 'test plugin');
    expect(plugin.notificationManager, notificationManager);
    expect(plugin.contextRoots, isEmpty);
    expect(plugin.currentSession, isNull);
  }

  test_removeContextRoot() {
    ContextRoot contextRoot1 = new ContextRoot('/pkg1', []);
    ContextRoot contextRoot2 = new ContextRoot('/pkg2', []);
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, unorderedEquals([contextRoot1]));
    plugin.addContextRoot(contextRoot2);
    expect(plugin.contextRoots, unorderedEquals([contextRoot1, contextRoot2]));
    plugin.removeContextRoot(contextRoot1);
    expect(plugin.contextRoots, unorderedEquals([contextRoot2]));
    plugin.removeContextRoot(contextRoot2);
    expect(plugin.contextRoots, isEmpty);
  }

  @failingTest
  test_start_notRunning() {
    fail('Not tested');
  }

  test_start_running() async {
    plugin.currentSession = new PluginSession(plugin);
    try {
      await plugin.start('', '');
      fail('Expected a StateError');
    } on StateError {
      // Expected.
    }
  }

  test_stop_notRunning() {
    expect(() => plugin.stop(), throwsStateError);
  }

  test_stop_running() async {
    PluginSession session = new PluginSession(plugin);
    TestServerCommunicationChannel channel =
        new TestServerCommunicationChannel(session);
    plugin.currentSession = session;
    await plugin.stop();
    expect(plugin.currentSession, isNull);
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.shutdown');
  }
}

@reflectiveTest
class DiscoveredPluginInfoTest {
  TestNotificationManager notificationManager;
  String pluginPath = '/pluginDir';
  String executionPath = '/pluginDir/bin/plugin.dart';
  String packagesPath = '/pluginDir/.packages';
  DiscoveredPluginInfo plugin;

  void setUp() {
    notificationManager = new TestNotificationManager();
    plugin = new DiscoveredPluginInfo(pluginPath, executionPath, packagesPath,
        notificationManager, InstrumentationService.NULL_SERVICE);
  }

  test_addContextRoot() {
    String optionsFilePath = '/pkg1/analysis_options.yaml';
    ContextRoot contextRoot1 = new ContextRoot('/pkg1', []);
    contextRoot1.optionsFilePath = optionsFilePath;
    PluginSession session = new PluginSession(plugin);
    TestServerCommunicationChannel channel =
        new TestServerCommunicationChannel(session);
    plugin.currentSession = session;
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
    List<Request> sentRequests = channel.sentRequests;
    expect(sentRequests, hasLength(1));
    List<Map> roots = sentRequests[0].params['roots'];
    expect(roots[0]['optionsFile'], optionsFilePath);
  }

  test_creation() {
    expect(plugin.path, pluginPath);
    expect(plugin.executionPath, executionPath);
    expect(plugin.notificationManager, notificationManager);
    expect(plugin.contextRoots, isEmpty);
    expect(plugin.currentSession, isNull);
  }

  test_removeContextRoot() {
    ContextRoot contextRoot1 = new ContextRoot('/pkg1', []);
    ContextRoot contextRoot2 = new ContextRoot('/pkg2', []);
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, unorderedEquals([contextRoot1]));
    plugin.addContextRoot(contextRoot2);
    expect(plugin.contextRoots, unorderedEquals([contextRoot1, contextRoot2]));
    plugin.removeContextRoot(contextRoot1);
    expect(plugin.contextRoots, unorderedEquals([contextRoot2]));
    plugin.removeContextRoot(contextRoot2);
    expect(plugin.contextRoots, isEmpty);
  }

  @failingTest
  test_start_notRunning() {
    fail('Not tested');
  }

  test_start_running() async {
    plugin.currentSession = new PluginSession(plugin);
    try {
      await plugin.start('', '');
      fail('Expected a StateError');
    } on StateError {
      // Expected.
    }
  }

  test_stop_notRunning() {
    expect(() => plugin.stop(), throwsStateError);
  }

  test_stop_running() async {
    PluginSession session = new PluginSession(plugin);
    TestServerCommunicationChannel channel =
        new TestServerCommunicationChannel(session);
    plugin.currentSession = session;
    await plugin.stop();
    expect(plugin.currentSession, isNull);
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.shutdown');
  }
}

@reflectiveTest
class PluginManagerFromDiskTest extends PluginTestSupport {
  String byteStorePath = '/byteStore';
  PluginManager manager;

  void setUp() {
    super.setUp();
    manager = new PluginManager(resourceProvider, byteStorePath, '',
        notificationManager, InstrumentationService.NULL_SERVICE);
  }

  test_addPluginToContextRoot() async {
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(test: (String pluginPath) async {
      ContextRoot contextRoot = new ContextRoot(pkgPath, []);
      await manager.addPluginToContextRoot(contextRoot, pluginPath);
      await manager.stopAll();
    });
    pkg1Dir.deleteSync(recursive: true);
  }

  @failingTest
  test_addPluginToContextRoot_pubspec() async {
    // We can't successfully run pub until after the analyzer_plugin package has
    // been published.
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPubspecPlugin(test: (String pluginPath) async {
      ContextRoot contextRoot = new ContextRoot(pkgPath, []);
      await manager.addPluginToContextRoot(contextRoot, pluginPath);
      String packagesPath =
          resourceProvider.pathContext.join(pluginPath, '.packages');
      File packagesFile = resourceProvider.getFile(packagesPath);
      bool exists = packagesFile.exists;
      await manager.stopAll();
      expect(exists, isTrue, reason: '.packages file was not created');
    });
    pkg1Dir.deleteSync(recursive: true);
  }

  test_broadcastRequest_many() async {
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          await withPlugin(
              pluginName: 'plugin2',
              test: (String plugin2Path) async {
                ContextRoot contextRoot = new ContextRoot(pkgPath, []);
                await manager.addPluginToContextRoot(contextRoot, plugin1Path);
                await manager.addPluginToContextRoot(contextRoot, plugin2Path);

                Map<PluginInfo, Future<Response>> responses =
                    manager.broadcastRequest(
                        new CompletionGetSuggestionsParams(
                            '/pkg1/lib/pkg1.dart', 100),
                        contextRoot: contextRoot);
                expect(responses, hasLength(2));

                await manager.stopAll();
              });
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  test_broadcastRequest_many_noContextRoot() async {
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          await withPlugin(
              pluginName: 'plugin2',
              test: (String plugin2Path) async {
                ContextRoot contextRoot = new ContextRoot(pkgPath, []);
                await manager.addPluginToContextRoot(contextRoot, plugin1Path);
                await manager.addPluginToContextRoot(contextRoot, plugin2Path);

                Map<PluginInfo, Future<Response>> responses =
                    manager.broadcastRequest(new CompletionGetSuggestionsParams(
                        '/pkg1/lib/pkg1.dart', 100));
                expect(responses, hasLength(2));

                await manager.stopAll();
              });
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  test_broadcastWatchEvent() async {
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          ContextRoot contextRoot = new ContextRoot(pkgPath, []);
          await manager.addPluginToContextRoot(contextRoot, plugin1Path);
          List<PluginInfo> plugins = manager.pluginsForContextRoot(contextRoot);
          expect(plugins, hasLength(1));
          watcher.WatchEvent watchEvent = new watcher.WatchEvent(
              watcher.ChangeType.MODIFY, path.join(pkgPath, 'lib', 'lib.dart'));
          List<Future<Response>> responses =
              await manager.broadcastWatchEvent(watchEvent);
          expect(responses, hasLength(1));
          Response response = await responses[0];
          expect(response, isNotNull);
          expect(response.error, isNull);
          await manager.stopAll();
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  test_pluginsForContextRoot_multiple() async {
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          await withPlugin(
              pluginName: 'plugin2',
              test: (String plugin2Path) async {
                ContextRoot contextRoot = new ContextRoot(pkgPath, []);
                await manager.addPluginToContextRoot(contextRoot, plugin1Path);
                await manager.addPluginToContextRoot(contextRoot, plugin2Path);

                List<PluginInfo> plugins =
                    manager.pluginsForContextRoot(contextRoot);
                expect(plugins, hasLength(2));
                List<String> paths = plugins
                    .map((PluginInfo plugin) => plugin.pluginId)
                    .toList();
                expect(paths, unorderedEquals([plugin1Path, plugin2Path]));

                await manager.stopAll();
              });
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  test_pluginsForContextRoot_one() async {
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(test: (String pluginPath) async {
      ContextRoot contextRoot = new ContextRoot(pkgPath, []);
      await manager.addPluginToContextRoot(contextRoot, pluginPath);

      List<PluginInfo> plugins = manager.pluginsForContextRoot(contextRoot);
      expect(plugins, hasLength(1));
      expect(plugins[0].pluginId, pluginPath);

      await manager.stopAll();
    });
    pkg1Dir.deleteSync(recursive: true);
  }

  test_removedContextRoot() async {
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(test: (String pluginPath) async {
      ContextRoot contextRoot = new ContextRoot(pkgPath, []);
      await manager.addPluginToContextRoot(contextRoot, pluginPath);

      manager.removedContextRoot(contextRoot);

      await manager.stopAll();
    });
    pkg1Dir.deleteSync(recursive: true);
  }

  test_restartPlugins() async {
    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    String pkg1Path = pkg1Dir.resolveSymbolicLinksSync();
    io.Directory pkg2Dir = io.Directory.systemTemp.createTempSync('pkg2');
    String pkg2Path = pkg2Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          await withPlugin(
              pluginName: 'plugin2',
              test: (String plugin2Path) async {
                ContextRoot contextRoot1 = new ContextRoot(pkg1Path, []);
                ContextRoot contextRoot2 = new ContextRoot(pkg2Path, []);
                await manager.addPluginToContextRoot(contextRoot1, plugin1Path);
                await manager.addPluginToContextRoot(contextRoot1, plugin2Path);
                await manager.addPluginToContextRoot(contextRoot2, plugin1Path);

                await manager.restartPlugins();
                List<PluginInfo> plugins = manager.plugins;
                expect(plugins, hasLength(2));
                expect(plugins[0].currentSession, isNotNull);
                expect(plugins[1].currentSession, isNotNull);
                if (plugins[0].pluginId.contains('plugin1')) {
                  expect(plugins[0].contextRoots,
                      unorderedEquals([contextRoot1, contextRoot2]));
                  expect(
                      plugins[1].contextRoots, unorderedEquals([contextRoot1]));
                } else {
                  expect(
                      plugins[0].contextRoots, unorderedEquals([contextRoot1]));
                  expect(plugins[1].contextRoots,
                      unorderedEquals([contextRoot1, contextRoot2]));
                }
                await manager.stopAll();
              });
        });
    pkg1Dir.deleteSync(recursive: true);
  }
}

@reflectiveTest
class PluginManagerTest extends Object with ResourceProviderMixin {
  String byteStorePath;
  String sdkPath;
  TestNotificationManager notificationManager;
  PluginManager manager;

  void setUp() {
    byteStorePath = resourceProvider.convertPath('/byteStore');
    sdkPath = resourceProvider.convertPath('/sdk');
    notificationManager = new TestNotificationManager();
    manager = new PluginManager(resourceProvider, byteStorePath, sdkPath,
        notificationManager, InstrumentationService.NULL_SERVICE);
  }

  void test_broadcastRequest_none() {
    ContextRoot contextRoot = new ContextRoot('/pkg1', []);
    Map<PluginInfo, Future<Response>> responses = manager.broadcastRequest(
        new CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100),
        contextRoot: contextRoot);
    expect(responses, hasLength(0));
  }

  void test_creation() {
    expect(manager.resourceProvider, resourceProvider);
    expect(manager.byteStorePath, byteStorePath);
    expect(manager.sdkPath, sdkPath);
    expect(manager.notificationManager, notificationManager);
  }

  void test_pathsFor_withPackagesFile() {
    //
    // Build the minimal directory structure for a plugin package that includes
    // a .packages file.
    //
    String pluginDirPath = newFolder('/plugin').path;
    String pluginFilePath = newFile('/plugin/bin/plugin.dart').path;
    String packagesFilePath = newFile('/plugin/.packages').path;
    //
    // Test path computation.
    //
    List<String> paths = manager.pathsFor(pluginDirPath);
    expect(paths, hasLength(2));
    expect(paths[0], pluginFilePath);
    expect(paths[1], packagesFilePath);
  }

  void test_pathsFor_withPubspec_inBazelWorkspace() {
    //
    // Build a Bazel workspace containing four packages, including the plugin.
    //
    newFile('/workspaceRoot/WORKSPACE');
    newFolder('/workspaceRoot/bazel-bin');
    newFolder('/workspaceRoot/bazel-genfiles');

    String newPackage(String packageName, [List<String> dependencies]) {
      String packageRoot =
          newFolder('/workspaceRoot/third_party/dart/$packageName').path;
      newFile('$packageRoot/lib/$packageName.dart');
      StringBuffer buffer = new StringBuffer();
      if (dependencies != null) {
        buffer.writeln('dependencies:');
        for (String dependency in dependencies) {
          buffer.writeln('  $dependency: any');
        }
      }
      newFile('$packageRoot/pubspec.yaml', content: buffer.toString());
      return packageRoot;
    }

    String pluginDirPath = newPackage('plugin', ['b', 'c']);
    newPackage('b', ['d']);
    newPackage('c', ['d']);
    newPackage('d');
    String pluginFilePath = newFile('$pluginDirPath/bin/plugin.dart').path;
    //
    // Test path computation.
    //
    List<String> paths = manager.pathsFor(pluginDirPath);
    expect(paths, hasLength(2));
    expect(paths[0], pluginFilePath);
    File packagesFile = getFile(paths[1]);
    expect(packagesFile.exists, isTrue);
    String content = packagesFile.readAsStringSync();
    List<String> lines = content.split('\n');
    expect(
        lines,
        unorderedEquals([
          'plugin:file:///workspaceRoot/third_party/dart/plugin/lib',
          'b:file:///workspaceRoot/third_party/dart/b/lib',
          'c:file:///workspaceRoot/third_party/dart/c/lib',
          'd:file:///workspaceRoot/third_party/dart/d/lib',
          ''
        ]));
  }

  void test_pluginsForContextRoot_none() {
    ContextRoot contextRoot = new ContextRoot('/pkg1', []);
    expect(manager.pluginsForContextRoot(contextRoot), isEmpty);
  }

  void test_stopAll_none() {
    manager.stopAll();
  }
}

@reflectiveTest
class PluginSessionFromDiskTest extends PluginTestSupport {
  test_start_notRunning() async {
    await withPlugin(test: (String pluginPath) async {
      String packagesPath = path.join(pluginPath, '.packages');
      String mainPath = path.join(pluginPath, 'bin', 'plugin.dart');
      String byteStorePath = path.join(pluginPath, 'byteStore');
      new io.Directory(byteStorePath).createSync();
      PluginInfo plugin = new DiscoveredPluginInfo(
          pluginPath,
          mainPath,
          packagesPath,
          notificationManager,
          InstrumentationService.NULL_SERVICE);
      PluginSession session = new PluginSession(plugin);
      plugin.currentSession = session;
      expect(await session.start(byteStorePath, ''), isTrue);
      await session.stop();
    });
  }
}

@reflectiveTest
class PluginSessionTest extends Object with ResourceProviderMixin {
  TestNotificationManager notificationManager;
  String pluginPath;
  String executionPath;
  String packagesPath;
  String sdkPath;
  PluginInfo plugin;
  PluginSession session;

  void setUp() {
    notificationManager = new TestNotificationManager();
    pluginPath = resourceProvider.convertPath('/pluginDir');
    executionPath = resourceProvider.convertPath('/pluginDir/bin/plugin.dart');
    packagesPath = resourceProvider.convertPath('/pluginDir/.packages');
    sdkPath = resourceProvider.convertPath('/sdk');
    plugin = new DiscoveredPluginInfo(pluginPath, executionPath, packagesPath,
        notificationManager, InstrumentationService.NULL_SERVICE);
    session = new PluginSession(plugin);
  }

  void test_handleNotification() {
    Notification notification =
        new AnalysisErrorsParams('/test.dart', <AnalysisError>[])
            .toNotification();
    expect(notificationManager.notifications, hasLength(0));
    session.handleNotification(notification);
    expect(notificationManager.notifications, hasLength(1));
    expect(notificationManager.notifications[0], notification);
  }

  void test_handleOnDone() {
    TestServerCommunicationChannel channel =
        new TestServerCommunicationChannel(session);
    session.handleOnDone();
    expect(channel.closeCount, 1);
    expect(session.pluginStoppedCompleter.isCompleted, isTrue);
  }

  @failingTest
  void test_handleOnError() {
    session.handleOnError(<String>['message', 'trace']);
    fail('The method handleOnError is not implemented');
  }

  test_handleResponse() async {
    new TestServerCommunicationChannel(session);
    Response response = new PluginVersionCheckResult(
            true, 'name', 'version', <String>[],
            contactInfo: 'contactInfo')
        .toResponse('0', 1);
    Future<Response> future =
        session.sendRequest(new PluginVersionCheckParams('', '', ''));
    expect(session.pendingRequests, hasLength(1));
    session.handleResponse(response);
    expect(session.pendingRequests, hasLength(0));
    Response result = await future;
    expect(result, same(response));
  }

  void test_nextRequestId() {
    expect(session.requestId, 0);
    expect(session.nextRequestId, '0');
    expect(session.requestId, 1);
  }

  void test_sendRequest() {
    TestServerCommunicationChannel channel =
        new TestServerCommunicationChannel(session);
    session.sendRequest(new PluginVersionCheckParams('', '', ''));
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.versionCheck');
  }

  test_start_notCompatible() async {
    session.isCompatible = false;
    expect(await session.start(path.join(pluginPath, 'byteStore'), sdkPath),
        isFalse);
  }

  test_start_running() async {
    new TestServerCommunicationChannel(session);
    try {
      await session.start(null, '');
      fail('Expected a StateError to be thrown');
    } on StateError {
      // Expected behavior
    }
  }

  test_stop_notRunning() {
    expect(() => session.stop(), throwsStateError);
  }

  test_stop_running() async {
    TestServerCommunicationChannel channel =
        new TestServerCommunicationChannel(session);
    await session.stop();
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.shutdown');
  }
}

/**
 * A class designed to be used as a superclass for test classes that define
 * tests that require plugins to be created on disk.
 */
abstract class PluginTestSupport {
  PhysicalResourceProvider resourceProvider;
  TestNotificationManager notificationManager;

  /**
   * The content to be used for the '.packages' file, or `null` if the content
   * has not yet been computed.
   */
  String _packagesFileContent;

  void setUp() {
    resourceProvider = PhysicalResourceProvider.INSTANCE;
    notificationManager = new TestNotificationManager();
  }

  /**
   * Create a directory structure representing a plugin on disk, run the given
   * [test] function, and then remove the directory. The directory will have the
   * following structure:
   * ```
   * pluginDirectory
   *   .packages
   *   bin
   *     plugin.dart
   * ```
   * The name of the plugin directory will be the [pluginName], if one is
   * provided (in order to allow more than one plugin to be created by a single
   * test). The 'plugin.dart' file will contain the given [content], or default
   * content that implements a minimal plugin if the contents are not given. The
   * [test] function will be passed the path of the directory that was created.
   */
  Future<Null> withPlugin(
      {String content,
      String pluginName,
      Future<Null> test(String pluginPath)}) async {
    io.Directory tempDirectory =
        io.Directory.systemTemp.createTempSync(pluginName ?? 'test_plugin');
    try {
      String pluginPath = tempDirectory.resolveSymbolicLinksSync();
      //
      // Create a .packages file.
      //
      io.File packagesFile = new io.File(path.join(pluginPath, '.packages'));
      packagesFile.writeAsStringSync(_getPackagesFileContent());
      //
      // Create the 'bin' directory.
      //
      String binPath = path.join(pluginPath, 'bin');
      new io.Directory(binPath).createSync();
      //
      // Create the 'plugin.dart' file.
      //
      io.File pluginFile = new io.File(path.join(binPath, 'plugin.dart'));
      pluginFile.writeAsStringSync(content ?? _defaultPluginContent());
      //
      // Run the actual test code.
      //
      await test(pluginPath);
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  /**
   * Create a directory structure representing a plugin on disk, run the given
   * [test] function, and then remove the directory. The directory will have the
   * following structure:
   * ```
   * pluginDirectory
   *   pubspec.yaml
   *   bin
   *     plugin.dart
   * ```
   * The name of the plugin directory will be the [pluginName], if one is
   * provided (in order to allow more than one plugin to be created by a single
   * test). The 'plugin.dart' file will contain the given [content], or default
   * content that implements a minimal plugin if the contents are not given. The
   * [test] function will be passed the path of the directory that was created.
   */
  Future<Null> withPubspecPlugin(
      {String content,
      String pluginName,
      Future<Null> test(String pluginPath)}) async {
    io.Directory tempDirectory =
        io.Directory.systemTemp.createTempSync(pluginName ?? 'test_plugin');
    try {
      String pluginPath = tempDirectory.resolveSymbolicLinksSync();
      //
      // Create a pubspec.yaml file.
      //
      io.File pubspecFile = new io.File(path.join(pluginPath, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync(_getPubspecFileContent());
      //
      // Create the 'bin' directory.
      //
      String binPath = path.join(pluginPath, 'bin');
      new io.Directory(binPath).createSync();
      //
      // Create the 'plugin.dart' file.
      //
      io.File pluginFile = new io.File(path.join(binPath, 'plugin.dart'));
      pluginFile.writeAsStringSync(content ?? _defaultPluginContent());
      //
      // Run the actual test code.
      //
      await test(pluginPath);
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  /**
   * Convert the [sdkPackageMap] into a plugin-specific map by applying the
   * given relative path [delta] to each line.
   */
  String _convertPackageMap(String sdkDirPath, List<String> sdkPackageMap) {
    StringBuffer buffer = new StringBuffer();
    for (String line in sdkPackageMap) {
      if (!line.startsWith('#')) {
        int index = line.indexOf(':');
        String packageName = line.substring(0, index + 1);
        String relativePath = line.substring(index + 1);
        String absolutePath = path.join(sdkDirPath, relativePath);
        buffer.write(packageName);
        buffer.writeln(absolutePath);
      }
    }
    return buffer.toString();
  }

  /**
   * The default content of the plugin. This is a minimal plugin that will only
   * respond correctly to version checks and to shutdown requests.
   */
  String _defaultPluginContent() {
    return r'''
import 'dart:isolate';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:pub_semver/pub_semver.dart';

void main(List<String> args, SendPort sendPort) {
  MinimalPlugin plugin = new MinimalPlugin(PhysicalResourceProvider.INSTANCE);
  new ServerPluginStarter(plugin).start(sendPort);
}

class MinimalPlugin extends ServerPlugin {
  MinimalPlugin(ResourceProvider provider) : super(provider);

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'minimal';

  @override
  String get version => '0.0.1';

  @override
  AnalysisHandleWatchEventsResult handleAnalysisHandleWatchEvents(
          AnalysisHandleWatchEventsParams parameters) =>
    new AnalysisHandleWatchEventsResult();

  @override
  bool isCompatibleWith(Version serverVersion) => true;
}
''';
  }

  /**
   * Return the content to be used for the '.packages' file.
   */
  String _getPackagesFileContent() {
    if (_packagesFileContent == null) {
      io.File sdkPackagesFile = new io.File(_sdkPackagesPath());
      List<String> sdkPackageMap = sdkPackagesFile.readAsLinesSync();
      _packagesFileContent =
          _convertPackageMap(path.dirname(sdkPackagesFile.path), sdkPackageMap);
    }
    return _packagesFileContent;
  }

  /**
   * Return the content to be used for the 'pubspec.yaml' file.
   */
  String _getPubspecFileContent() {
    return '''
name: 'test'
dependencies:
  analyzer: any
  analyzer_plugin: any
''';
  }

  /**
   * Return the path to the '.packages' file in the root of the SDK checkout.
   */
  String _sdkPackagesPath() {
    String packagesPath = io.Platform.script.toFilePath();
    while (packagesPath.isNotEmpty &&
        path.basename(packagesPath) != 'analysis_server') {
      packagesPath = path.dirname(packagesPath);
    }
    packagesPath = path.dirname(packagesPath);
    packagesPath = path.dirname(packagesPath);
    return path.join(packagesPath, '.packages');
  }
}

class TestNotificationManager implements NotificationManager {
  List<Notification> notifications = <Notification>[];

  Map<String, Map<String, List<AnalysisError>>> recordedErrors =
      <String, Map<String, List<AnalysisError>>>{};

  @override
  void handlePluginNotification(String pluginId, Notification notification) {
    notifications.add(notification);
  }

  @override
  noSuchMethod(Invocation invocation) {
    fail('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  void recordAnalysisErrors(
      String pluginId, String filePath, List<AnalysisError> errorData) {
    recordedErrors.putIfAbsent(
        pluginId, () => <String, List<AnalysisError>>{})[filePath] = errorData;
  }
}

class TestServerCommunicationChannel implements ServerCommunicationChannel {
  final PluginSession session;
  int closeCount = 0;
  List<Request> sentRequests = <Request>[];

  TestServerCommunicationChannel(this.session) {
    session.channel = this;
  }

  @override
  void close() {
    closeCount++;
  }

  void kill() {
    fail('Unexpected invocation of kill');
  }

  @override
  void listen(void onResponse(Response response),
      void onNotification(Notification notification),
      {Function onError, void onDone()}) {
    fail('Unexpected invocation of listen');
  }

  @override
  void sendRequest(Request request) {
    sentRequests.add(request);
    if (request.method == 'plugin.shutdown') {
      session.handleOnDone();
    }
  }
}
