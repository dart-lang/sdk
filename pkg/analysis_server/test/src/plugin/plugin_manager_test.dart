// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/context_root.dart';
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

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInPluginInfoTest);
    defineReflectiveTests(DiscoveredPluginInfoTest);
    defineReflectiveTests(PluginManagerTest);
    defineReflectiveTests(PluginManagerFromDiskTest);
    defineReflectiveTests(PluginSessionTest);
    defineReflectiveTests(PluginSessionFromDiskTest);
  });
}

ContextRoot _newContextRoot(String root, {List<String> exclude = const []}) {
  return ContextRoot(root, exclude, pathContext: path.context);
}

@reflectiveTest
class BuiltInPluginInfoTest {
  TestNotificationManager notificationManager;
  BuiltInPluginInfo plugin;

  void setUp() {
    notificationManager = TestNotificationManager();
    plugin = BuiltInPluginInfo(null, 'test plugin', notificationManager,
        InstrumentationService.NULL_SERVICE);
  }

  void test_addContextRoot() {
    var contextRoot1 = _newContextRoot('/pkg1');
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
  }

  void test_creation() {
    expect(plugin.pluginId, 'test plugin');
    expect(plugin.notificationManager, notificationManager);
    expect(plugin.contextRoots, isEmpty);
    expect(plugin.currentSession, isNull);
  }

  void test_removeContextRoot() {
    var contextRoot1 = _newContextRoot('/pkg1');
    var contextRoot2 = _newContextRoot('/pkg2');
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
  Future<void> test_start_notRunning() {
    fail('Not tested');
  }

  Future<void> test_start_running() async {
    plugin.currentSession = PluginSession(plugin);
    try {
      await plugin.start('', '');
      fail('Expected a StateError');
    } on StateError {
      // Expected.
    }
  }

  void test_stop_notRunning() {
    expect(() => plugin.stop(), throwsStateError);
  }

  Future<void> test_stop_running() async {
    var session = PluginSession(plugin);
    var channel = TestServerCommunicationChannel(session);
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
    notificationManager = TestNotificationManager();
    plugin = DiscoveredPluginInfo(pluginPath, executionPath, packagesPath,
        notificationManager, InstrumentationService.NULL_SERVICE);
  }

  void test_addContextRoot() {
    var optionsFilePath = '/pkg1/analysis_options.yaml';
    var contextRoot1 = _newContextRoot('/pkg1');
    contextRoot1.optionsFilePath = optionsFilePath;
    var session = PluginSession(plugin);
    var channel = TestServerCommunicationChannel(session);
    plugin.currentSession = session;
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
    var sentRequests = channel.sentRequests;
    expect(sentRequests, hasLength(1));
    List<Map> roots = sentRequests[0].params['roots'];
    expect(roots[0]['optionsFile'], optionsFilePath);
  }

  void test_creation() {
    expect(plugin.path, pluginPath);
    expect(plugin.executionPath, executionPath);
    expect(plugin.notificationManager, notificationManager);
    expect(plugin.contextRoots, isEmpty);
    expect(plugin.currentSession, isNull);
  }

  void test_removeContextRoot() {
    var contextRoot1 = _newContextRoot('/pkg1');
    var contextRoot2 = _newContextRoot('/pkg2');
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
  Future<void> test_start_notRunning() {
    fail('Not tested');
  }

  Future<void> test_start_running() async {
    plugin.currentSession = PluginSession(plugin);
    try {
      await plugin.start('', '');
      fail('Expected a StateError');
    } on StateError {
      // Expected.
    }
  }

  void test_stop_notRunning() {
    expect(() => plugin.stop(), throwsStateError);
  }

  Future<void> test_stop_running() async {
    var session = PluginSession(plugin);
    var channel = TestServerCommunicationChannel(session);
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

  @override
  void setUp() {
    super.setUp();
    manager = PluginManager(resourceProvider, byteStorePath, '',
        notificationManager, InstrumentationService.NULL_SERVICE);
  }

  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_addPluginToContextRoot() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(test: (String pluginPath) async {
      var contextRoot = _newContextRoot(pkgPath);
      await manager.addPluginToContextRoot(contextRoot, pluginPath);
      await manager.stopAll();
    });
    pkg1Dir.deleteSync(recursive: true);
  }

  @failingTest
  Future<void> test_addPluginToContextRoot_pubspec() async {
    // We can't successfully run pub until after the analyzer_plugin package has
    // been published.
    fail('Cannot run pub');
//    io.Directory pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
//    String pkgPath = pkg1Dir.resolveSymbolicLinksSync();
//    await withPubspecPlugin(test: (String pluginPath) async {
//      ContextRoot contextRoot = _newContextRoot(pkgPath);
//      await manager.addPluginToContextRoot(contextRoot, pluginPath);
//      String packagesPath =
//          resourceProvider.pathContext.join(pluginPath, '.packages');
//      File packagesFile = resourceProvider.getFile(packagesPath);
//      bool exists = packagesFile.exists;
//      await manager.stopAll();
//      expect(exists, isTrue, reason: '.packages file was not created');
//    });
//    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_broadcastRequest_many() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          await withPlugin(
              pluginName: 'plugin2',
              test: (String plugin2Path) async {
                var contextRoot = _newContextRoot(pkgPath);
                await manager.addPluginToContextRoot(contextRoot, plugin1Path);
                await manager.addPluginToContextRoot(contextRoot, plugin2Path);

                var responses = manager.broadcastRequest(
                    CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100),
                    contextRoot: contextRoot);
                expect(responses, hasLength(2));

                await manager.stopAll();
              });
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_broadcastRequest_many_noContextRoot() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          await withPlugin(
              pluginName: 'plugin2',
              test: (String plugin2Path) async {
                var contextRoot = _newContextRoot(pkgPath);
                await manager.addPluginToContextRoot(contextRoot, plugin1Path);
                await manager.addPluginToContextRoot(contextRoot, plugin2Path);

                var responses = manager.broadcastRequest(
                    CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100));
                expect(responses, hasLength(2));

                await manager.stopAll();
              });
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_broadcastRequest_noCurrentSession() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        content: '(invalid content here)',
        test: (String plugin1Path) async {
          var contextRoot = _newContextRoot(pkgPath);
          await manager.addPluginToContextRoot(contextRoot, plugin1Path);

          var responses = manager.broadcastRequest(
              CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100),
              contextRoot: contextRoot);
          expect(responses, hasLength(0));

          await manager.stopAll();
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_broadcastWatchEvent() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          var contextRoot = _newContextRoot(pkgPath);
          await manager.addPluginToContextRoot(contextRoot, plugin1Path);
          var plugins = manager.pluginsForContextRoot(contextRoot);
          expect(plugins, hasLength(1));
          var watchEvent = watcher.WatchEvent(
              watcher.ChangeType.MODIFY, path.join(pkgPath, 'lib', 'lib.dart'));
          var responses = await manager.broadcastWatchEvent(watchEvent);
          expect(responses, hasLength(1));
          var response = await responses[0];
          expect(response, isNotNull);
          expect(response.error, isNull);
          await manager.stopAll();
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_pluginsForContextRoot_multiple() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          await withPlugin(
              pluginName: 'plugin2',
              test: (String plugin2Path) async {
                var contextRoot = _newContextRoot(pkgPath);
                await manager.addPluginToContextRoot(contextRoot, plugin1Path);
                await manager.addPluginToContextRoot(contextRoot, plugin2Path);

                var plugins = manager.pluginsForContextRoot(contextRoot);
                expect(plugins, hasLength(2));
                var paths = plugins
                    .map((PluginInfo plugin) => plugin.pluginId)
                    .toList();
                expect(paths, unorderedEquals([plugin1Path, plugin2Path]));

                await manager.stopAll();
              });
        });
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_pluginsForContextRoot_one() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(test: (String pluginPath) async {
      var contextRoot = _newContextRoot(pkgPath);
      await manager.addPluginToContextRoot(contextRoot, pluginPath);

      var plugins = manager.pluginsForContextRoot(contextRoot);
      expect(plugins, hasLength(1));
      expect(plugins[0].pluginId, pluginPath);

      await manager.stopAll();
    });
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_removedContextRoot() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(test: (String pluginPath) async {
      var contextRoot = _newContextRoot(pkgPath);
      await manager.addPluginToContextRoot(contextRoot, pluginPath);

      manager.removedContextRoot(contextRoot);

      await manager.stopAll();
    });
    pkg1Dir.deleteSync(recursive: true);
  }

  @TestTimeout(Timeout.factor(4))
  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_restartPlugins() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkg1Path = pkg1Dir.resolveSymbolicLinksSync();
    var pkg2Dir = io.Directory.systemTemp.createTempSync('pkg2');
    var pkg2Path = pkg2Dir.resolveSymbolicLinksSync();
    await withPlugin(
        pluginName: 'plugin1',
        test: (String plugin1Path) async {
          await withPlugin(
              pluginName: 'plugin2',
              test: (String plugin2Path) async {
                var contextRoot1 = _newContextRoot(pkg1Path);
                var contextRoot2 = _newContextRoot(pkg2Path);
                await manager.addPluginToContextRoot(contextRoot1, plugin1Path);
                await manager.addPluginToContextRoot(contextRoot1, plugin2Path);
                await manager.addPluginToContextRoot(contextRoot2, plugin1Path);

                await manager.restartPlugins();
                var plugins = manager.plugins;
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
class PluginManagerTest with ResourceProviderMixin {
  String byteStorePath;
  String sdkPath;
  TestNotificationManager notificationManager;
  PluginManager manager;

  void setUp() {
    byteStorePath = resourceProvider.convertPath('/byteStore');
    sdkPath = resourceProvider.convertPath('/sdk');
    notificationManager = TestNotificationManager();
    manager = PluginManager(resourceProvider, byteStorePath, sdkPath,
        notificationManager, InstrumentationService.NULL_SERVICE);
  }

  void test_broadcastRequest_none() {
    var contextRoot = _newContextRoot('/pkg1');
    var responses = manager.broadcastRequest(
        CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100),
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
    var pluginDirPath = newFolder('/plugin').path;
    var pluginFilePath = newFile('/plugin/bin/plugin.dart').path;
    var packagesFilePath = newFile('/plugin/.packages').path;
    //
    // Test path computation.
    //
    var paths = manager.pathsFor(pluginDirPath);
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
      var packageRoot =
          newFolder('/workspaceRoot/third_party/dart/$packageName').path;
      newFile('$packageRoot/lib/$packageName.dart');
      var buffer = StringBuffer();
      if (dependencies != null) {
        buffer.writeln('dependencies:');
        for (var dependency in dependencies) {
          buffer.writeln('  $dependency: any');
        }
      }
      newFile('$packageRoot/pubspec.yaml', content: buffer.toString());
      return packageRoot;
    }

    var pluginDirPath = newPackage('plugin', ['b', 'c']);
    newPackage('b', ['d']);
    newPackage('c', ['d']);
    newPackage('d');
    var pluginFilePath = newFile('$pluginDirPath/bin/plugin.dart').path;
    //
    // Test path computation.
    //
    var paths = manager.pathsFor(pluginDirPath);
    expect(paths, hasLength(2));
    expect(paths[0], pluginFilePath);
    var packagesFile = getFile(paths[1]);
    expect(packagesFile.exists, isTrue);
    var content = packagesFile.readAsStringSync();
    var lines = content.split('\n');
    String asFileUri(String input) => Uri.file(convertPath(input)).toString();
    expect(
        lines,
        unorderedEquals([
          'plugin:${asFileUri('/workspaceRoot/third_party/dart/plugin/lib')}',
          'b:${asFileUri('/workspaceRoot/third_party/dart/b/lib')}',
          'c:${asFileUri('/workspaceRoot/third_party/dart/c/lib')}',
          'd:${asFileUri('/workspaceRoot/third_party/dart/d/lib')}',
          ''
        ]));
  }

  void test_pluginsForContextRoot_none() {
    var contextRoot = _newContextRoot('/pkg1');
    expect(manager.pluginsForContextRoot(contextRoot), isEmpty);
  }

  void test_stopAll_none() {
    manager.stopAll();
  }
}

@reflectiveTest
class PluginSessionFromDiskTest extends PluginTestSupport {
  @SkippedTest(
      reason: 'flaky timeouts',
      issue: 'https://github.com/dart-lang/sdk/issues/38629')
  Future<void> test_start_notRunning() async {
    await withPlugin(test: (String pluginPath) async {
      var packagesPath = path.join(pluginPath, '.packages');
      var mainPath = path.join(pluginPath, 'bin', 'plugin.dart');
      var byteStorePath = path.join(pluginPath, 'byteStore');
      io.Directory(byteStorePath).createSync();
      PluginInfo plugin = DiscoveredPluginInfo(
          pluginPath,
          mainPath,
          packagesPath,
          notificationManager,
          InstrumentationService.NULL_SERVICE);
      var session = PluginSession(plugin);
      plugin.currentSession = session;
      expect(await session.start(byteStorePath, ''), isTrue);
      await session.stop();
    });
  }
}

@reflectiveTest
class PluginSessionTest with ResourceProviderMixin {
  TestNotificationManager notificationManager;
  String pluginPath;
  String executionPath;
  String packagesPath;
  String sdkPath;
  PluginInfo plugin;
  PluginSession session;

  void setUp() {
    notificationManager = TestNotificationManager();
    pluginPath = resourceProvider.convertPath('/pluginDir');
    executionPath = resourceProvider.convertPath('/pluginDir/bin/plugin.dart');
    packagesPath = resourceProvider.convertPath('/pluginDir/.packages');
    sdkPath = resourceProvider.convertPath('/sdk');
    plugin = DiscoveredPluginInfo(pluginPath, executionPath, packagesPath,
        notificationManager, InstrumentationService.NULL_SERVICE);
    session = PluginSession(plugin);
  }

  void test_handleNotification() {
    var notification =
        AnalysisErrorsParams('/test.dart', <AnalysisError>[]).toNotification();
    expect(notificationManager.notifications, hasLength(0));
    session.handleNotification(notification);
    expect(notificationManager.notifications, hasLength(1));
    expect(notificationManager.notifications[0], notification);
  }

  void test_handleOnDone() {
    var channel = TestServerCommunicationChannel(session);
    session.handleOnDone();
    expect(channel.closeCount, 1);
    expect(session.pluginStoppedCompleter.isCompleted, isTrue);
  }

  @failingTest
  void test_handleOnError() {
    session.handleOnError(<String>['message', 'trace']);
    fail('The method handleOnError is not implemented');
  }

  Future<void> test_handleResponse() async {
    TestServerCommunicationChannel(session);
    var response = PluginVersionCheckResult(true, 'name', 'version', <String>[],
            contactInfo: 'contactInfo')
        .toResponse('0', 1);
    var future = session.sendRequest(PluginVersionCheckParams('', '', ''));
    expect(session.pendingRequests, hasLength(1));
    session.handleResponse(response);
    expect(session.pendingRequests, hasLength(0));
    var result = await future;
    expect(result, same(response));
  }

  void test_nextRequestId() {
    expect(session.requestId, 0);
    expect(session.nextRequestId, '0');
    expect(session.requestId, 1);
  }

  void test_sendRequest() {
    var channel = TestServerCommunicationChannel(session);
    session.sendRequest(PluginVersionCheckParams('', '', ''));
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.versionCheck');
  }

  Future<void> test_start_notCompatible() async {
    session.isCompatible = false;
    expect(await session.start(path.join(pluginPath, 'byteStore'), sdkPath),
        isFalse);
  }

  Future<void> test_start_running() async {
    TestServerCommunicationChannel(session);
    try {
      await session.start(null, '');
      fail('Expected a StateError to be thrown');
    } on StateError {
      // Expected behavior
    }
  }

  void test_stop_notRunning() {
    expect(() => session.stop(), throwsStateError);
  }

  Future<void> test_stop_running() async {
    var channel = TestServerCommunicationChannel(session);
    await session.stop();
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.shutdown');
  }
}

/// A class designed to be used as a superclass for test classes that define
/// tests that require plugins to be created on disk.
abstract class PluginTestSupport {
  PhysicalResourceProvider resourceProvider;
  TestNotificationManager notificationManager;

  /// The content to be used for the '.packages' file, or `null` if the content
  /// has not yet been computed.
  String _packagesFileContent;

  void setUp() {
    resourceProvider = PhysicalResourceProvider.INSTANCE;
    notificationManager = TestNotificationManager();
  }

  /// Create a directory structure representing a plugin on disk, run the given
  /// [test] function, and then remove the directory. The directory will have
  /// the following structure:
  /// ```
  /// pluginDirectory
  ///   .packages
  ///   bin
  ///     plugin.dart
  /// ```
  /// The name of the plugin directory will be the [pluginName], if one is
  /// provided (in order to allow more than one plugin to be created by a single
  /// test). The 'plugin.dart' file will contain the given [content], or default
  /// content that implements a minimal plugin if the contents are not given.
  /// The [test] function will be passed the path of the directory that was
  /// created.
  Future<void> withPlugin(
      {String content,
      String pluginName,
      Future<void> Function(String) test}) async {
    var tempDirectory =
        io.Directory.systemTemp.createTempSync(pluginName ?? 'test_plugin');
    try {
      var pluginPath = tempDirectory.resolveSymbolicLinksSync();
      //
      // Create a .packages file.
      //
      var packagesFile = io.File(path.join(pluginPath, '.packages'));
      packagesFile.writeAsStringSync(_getPackagesFileContent());
      //
      // Create the 'bin' directory.
      //
      var binPath = path.join(pluginPath, 'bin');
      io.Directory(binPath).createSync();
      //
      // Create the 'plugin.dart' file.
      //
      var pluginFile = io.File(path.join(binPath, 'plugin.dart'));
      pluginFile.writeAsStringSync(content ?? _defaultPluginContent());
      //
      // Run the actual test code.
      //
      await test(pluginPath);
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  /// Create a directory structure representing a plugin on disk, run the given
  /// [test] function, and then remove the directory. The directory will have
  /// the following structure:
  /// ```
  /// pluginDirectory
  ///   pubspec.yaml
  ///   bin
  ///     plugin.dart
  /// ```
  /// The name of the plugin directory will be the [pluginName], if one is
  /// provided (in order to allow more than one plugin to be created by a single
  /// test). The 'plugin.dart' file will contain the given [content], or default
  /// content that implements a minimal plugin if the contents are not given.
  /// The [test] function will be passed the path of the directory that was
  /// created.
  Future<void> withPubspecPlugin(
      {String content,
      String pluginName,
      Future<void> Function(String) test}) async {
    var tempDirectory =
        io.Directory.systemTemp.createTempSync(pluginName ?? 'test_plugin');
    try {
      var pluginPath = tempDirectory.resolveSymbolicLinksSync();
      //
      // Create a pubspec.yaml file.
      //
      var pubspecFile = io.File(path.join(pluginPath, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync(_getPubspecFileContent());
      //
      // Create the 'bin' directory.
      //
      var binPath = path.join(pluginPath, 'bin');
      io.Directory(binPath).createSync();
      //
      // Create the 'plugin.dart' file.
      //
      var pluginFile = io.File(path.join(binPath, 'plugin.dart'));
      pluginFile.writeAsStringSync(content ?? _defaultPluginContent());
      //
      // Run the actual test code.
      //
      await test(pluginPath);
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  /// Convert the [sdkPackageMap] into a plugin-specific map by applying the
  /// given relative path [delta] to each line.
  String _convertPackageMap(String sdkDirPath, List<String> sdkPackageMap) {
    var buffer = StringBuffer();
    for (var line in sdkPackageMap) {
      if (!line.startsWith('#')) {
        var index = line.indexOf(':');
        var packageName = line.substring(0, index + 1);
        var relativePath = line.substring(index + 1);
        var absolutePath = path.join(sdkDirPath, relativePath);
        // Convert to file:/// URI since that's how absolute paths in
        // .packages must be for windows
        absolutePath = Uri.file(absolutePath).toString();
        buffer.write(packageName);
        buffer.writeln(absolutePath);
      }
    }
    return buffer.toString();
  }

  /// The default content of the plugin. This is a minimal plugin that will only
  /// respond correctly to version checks and to shutdown requests.
  String _defaultPluginContent() {
    return r'''
import 'dart:async';
import 'dart:isolate';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
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
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot) => null;

  @override
  Future<AnalysisHandleWatchEventsResult> handleAnalysisHandleWatchEvents(
      AnalysisHandleWatchEventsParams parameters) async =>
    new AnalysisHandleWatchEventsResult();

  @override
  bool isCompatibleWith(Version serverVersion) => true;
}
''';
  }

  /// Return the content to be used for the '.packages' file.
  String _getPackagesFileContent() {
    if (_packagesFileContent == null) {
      var sdkPackagesFile = io.File(_sdkPackagesPath());
      var sdkPackageMap = sdkPackagesFile.readAsLinesSync();
      _packagesFileContent =
          _convertPackageMap(path.dirname(sdkPackagesFile.path), sdkPackageMap);
    }
    return _packagesFileContent;
  }

  /// Return the content to be used for the 'pubspec.yaml' file.
  String _getPubspecFileContent() {
    return '''
name: 'test'
dependencies:
  analyzer: any
  analyzer_plugin: any
''';
  }

  /// Return the path to the '.packages' file in the root of the SDK checkout.
  String _sdkPackagesPath() {
    var packagesPath = io.Platform.script.toFilePath();
    while (packagesPath.isNotEmpty &&
        path.basename(packagesPath) != 'analysis_server') {
      packagesPath = path.dirname(packagesPath);
    }
    packagesPath = path.dirname(packagesPath);
    packagesPath = path.dirname(packagesPath);
    return path.join(packagesPath, '.packages');
  }
}

class TestNotificationManager implements AbstractNotificationManager {
  List<Notification> notifications = <Notification>[];

  Map<String, Map<String, List<AnalysisError>>> recordedErrors =
      <String, Map<String, List<AnalysisError>>>{};

  @override
  void handlePluginNotification(String pluginId, Notification notification) {
    notifications.add(notification);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
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

  @override
  void kill() {
    fail('Unexpected invocation of kill');
  }

  @override
  void listen(void Function(Response) onResponse,
      void Function(Notification) onNotification,
      {void Function(dynamic) onError, void Function() onDone}) {
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
