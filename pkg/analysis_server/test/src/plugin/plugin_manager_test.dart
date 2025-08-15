// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart'
    hide ContextRoot;
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart' as watcher;

import '../../support/sdk_paths.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiscoveredPluginInfoTest);
    defineReflectiveTests(PluginManagerTest);
    defineReflectiveTests(PluginManagerFromDiskTest);
    defineReflectiveTests(PluginSessionTest);
    defineReflectiveTests(PluginSessionFromDiskTest);
  });
}

@reflectiveTest
class DiscoveredPluginInfoTest with ResourceProviderMixin, _ContextRoot {
  late TestNotificationManager notificationManager;
  String pluginPath = '/pluginDir';
  String executionPath = '/pluginDir/bin/plugin.dart';
  String packagesPath = '/pluginDir/.packages';
  late PluginInfo plugin;

  void setUp() {
    notificationManager = TestNotificationManager();
    plugin = PluginInfo(
      pluginPath,
      executionPath,
      packagesPath,
      notificationManager,
      InstrumentationService.NULL_SERVICE,
    );
  }

  void test_addContextRoot() {
    var contextRoot1 = _newContextRoot('/pkg1');
    var optionsFile = getFile('/pkg1/analysis_options.yaml');
    contextRoot1.optionsFile = optionsFile;
    var session = PluginSession(plugin);
    var channel = TestServerCommunicationChannel(session);
    plugin.currentSession = session;
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
    plugin.addContextRoot(contextRoot1);
    expect(plugin.contextRoots, [contextRoot1]);
    var sentRequests = channel.sentRequests;
    expect(sentRequests, hasLength(1));
    var roots = sentRequests[0].params['roots'] as List<Map>;
    expect(roots[0]['optionsFile'], optionsFile.path);
  }

  void test_creation() {
    expect(plugin.executionPath, executionPath);
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
    expect(() => plugin.start('', ''), throwsStateError);
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
  late PluginManager manager;

  @override
  void setUp() {
    super.setUp();
    manager = PluginManager(
      resourceProvider,
      '/byteStore',
      '',
      notificationManager,
      InstrumentationService.NULL_SERVICE,
    );
  }

  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
  Future<void> test_addPluginToContextRoot() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
      test: (String pluginPath) async {
        var contextRoot = _newContextRoot(pkgPath);
        await manager.addPluginToContextRoot(
          contextRoot,
          pluginPath,
          isLegacyPlugin: true,
        );
        await manager.stopAll();
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
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
            await manager.addPluginToContextRoot(
              contextRoot,
              plugin1Path,
              isLegacyPlugin: true,
            );
            await manager.addPluginToContextRoot(
              contextRoot,
              plugin2Path,
              isLegacyPlugin: true,
            );

            var responses = manager.broadcastRequest(
              CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100),
              contextRoot: contextRoot,
            );
            expect(responses, hasLength(2));

            await manager.stopAll();
          },
        );
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
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
            await manager.addPluginToContextRoot(
              contextRoot,
              plugin1Path,
              isLegacyPlugin: true,
            );
            await manager.addPluginToContextRoot(
              contextRoot,
              plugin2Path,
              isLegacyPlugin: true,
            );

            var responses = manager.broadcastRequest(
              CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100),
            );
            expect(responses, hasLength(2));

            await manager.stopAll();
          },
        );
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  Future<void> test_broadcastRequest_noCurrentSession() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
      pluginName: 'plugin1',
      content: '(invalid content here)',
      test: (String plugin1Path) async {
        var contextRoot = _newContextRoot(pkgPath);
        await manager.addPluginToContextRoot(
          contextRoot,
          plugin1Path,
          isLegacyPlugin: true,
        );

        var responses = manager.broadcastRequest(
          CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100),
          contextRoot: contextRoot,
        );
        expect(responses, hasLength(0));

        await manager.stopAll();
        var exception = manager.plugins.first.exception;
        expect(exception, isNotNull);
        var innerException = exception!.exception;
        expect(
          innerException,
          isA<PluginException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Unable to spawn isolate'),
              contains('(invalid content here)'),
            ),
          ),
        );
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
  Future<void> test_broadcastWatchEvent() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
      pluginName: 'plugin1',
      test: (String plugin1Path) async {
        var contextRoot = _newContextRoot(pkgPath);
        await manager.addPluginToContextRoot(
          contextRoot,
          plugin1Path,
          isLegacyPlugin: true,
        );
        var plugins = manager.pluginsForContextRoot(contextRoot);
        expect(plugins, hasLength(1));
        var watchEvent = watcher.WatchEvent(
          watcher.ChangeType.MODIFY,
          path.join(pkgPath, 'lib', 'lib.dart'),
        );
        var responses = await manager.broadcastWatchEvent(watchEvent);
        expect(responses, hasLength(1));
        var response = await responses[0];
        expect(response, isNotNull);
        expect(response.error, isNull);
        await manager.stopAll();
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
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
            await manager.addPluginToContextRoot(
              contextRoot,
              plugin1Path,
              isLegacyPlugin: true,
            );
            await manager.addPluginToContextRoot(
              contextRoot,
              plugin2Path,
              isLegacyPlugin: true,
            );

            var plugins = manager.pluginsForContextRoot(contextRoot);
            expect(plugins, hasLength(2));
            var paths =
                plugins.map((PluginInfo plugin) => plugin.pluginId).toList();
            expect(paths, unorderedEquals([plugin1Path, plugin2Path]));

            await manager.stopAll();
          },
        );
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
  Future<void> test_pluginsForContextRoot_one() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
      test: (String pluginPath) async {
        var contextRoot = _newContextRoot(pkgPath);
        await manager.addPluginToContextRoot(
          contextRoot,
          pluginPath,
          isLegacyPlugin: true,
        );

        var plugins = manager.pluginsForContextRoot(contextRoot);
        expect(plugins, hasLength(1));
        expect(plugins[0].pluginId, pluginPath);

        await manager.stopAll();
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
  Future<void> test_removedContextRoot() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
      test: (String pluginPath) async {
        var contextRoot = _newContextRoot(pkgPath);
        await manager.addPluginToContextRoot(
          contextRoot,
          pluginPath,
          isLegacyPlugin: true,
        );

        manager.removedContextRoot(contextRoot);

        await manager.stopAll();
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  @TestTimeout(Timeout.factor(4))
  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
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
            await manager.addPluginToContextRoot(
              contextRoot1,
              plugin1Path,
              isLegacyPlugin: true,
            );
            await manager.addPluginToContextRoot(
              contextRoot1,
              plugin2Path,
              isLegacyPlugin: true,
            );
            await manager.addPluginToContextRoot(
              contextRoot2,
              plugin1Path,
              isLegacyPlugin: true,
            );

            await manager.restartPlugins();
            var plugins = manager.plugins;
            expect(plugins, hasLength(2));
            expect(plugins[0].currentSession, isNotNull);
            expect(plugins[1].currentSession, isNotNull);
            if (plugins[0].pluginId.contains('plugin1')) {
              expect(
                plugins[0].contextRoots,
                unorderedEquals([contextRoot1, contextRoot2]),
              );
              expect(plugins[1].contextRoots, unorderedEquals([contextRoot1]));
            } else {
              expect(plugins[0].contextRoots, unorderedEquals([contextRoot1]));
              expect(
                plugins[1].contextRoots,
                unorderedEquals([contextRoot1, contextRoot2]),
              );
            }
            await manager.stopAll();
          },
        );
      },
    );
    pkg1Dir.deleteSync(recursive: true);
  }

  ContextRootImpl _newContextRoot(String root) {
    root = resourceProvider.convertPath(root);
    return ContextRootImpl(
      resourceProvider,
      resourceProvider.getFolder(root),
      BasicWorkspace.find(resourceProvider, Packages.empty, root),
    );
  }
}

@reflectiveTest
class PluginManagerTest with ResourceProviderMixin, _ContextRoot {
  late String byteStorePath;
  late String sdkPath;
  late TestNotificationManager notificationManager;
  late PluginManager manager;

  void setUp() {
    byteStorePath = resourceProvider.convertPath('/byteStore');
    sdkPath = resourceProvider.convertPath('/sdk');
    notificationManager = TestNotificationManager();
    manager = PluginManager(
      resourceProvider,
      byteStorePath,
      sdkPath,
      notificationManager,
      InstrumentationService.NULL_SERVICE,
    );
  }

  void test_broadcastRequest_none() {
    var contextRoot = _newContextRoot('/pkg1');
    var responses = manager.broadcastRequest(
      CompletionGetSuggestionsParams('/pkg1/lib/pkg1.dart', 100),
      contextRoot: contextRoot,
    );
    expect(responses, hasLength(0));
  }

  void test_pathsFor_withPackageConfigJsonFile() {
    //
    // Build the minimal directory structure for a plugin package that includes
    // a '.dart_tool/package_config.json' file.
    //
    var pluginDirPath = newFolder('/plugin').path;
    var pluginFile = newFile('/plugin/bin/plugin.dart', '');
    var packageConfigFile = newPackageConfigJsonFile('/plugin', '');
    //
    // Test path computation.
    //
    var files = manager.filesFor(pluginDirPath, isLegacyPlugin: true);
    expect(files.execution, pluginFile);
    expect(files.packageConfig, packageConfigFile);
  }

  void test_pathsFor_withPubspec_inBlazeWorkspace() {
    //
    // Build a Blaze workspace containing four packages, including the plugin.
    //
    newFile('/workspaceRoot/${file_paths.blazeWorkspaceMarker}', '');
    newFolder('/workspaceRoot/blaze-bin');
    newFolder('/workspaceRoot/blaze-genfiles');

    String newPackage(String packageName, [List<String>? dependencies]) {
      var packageRoot =
          newFolder('/workspaceRoot/third_party/dart/$packageName').path;
      newFile('$packageRoot/lib/$packageName.dart', '');
      var buffer = StringBuffer();
      if (dependencies != null) {
        buffer.writeln('dependencies:');
        for (var dependency in dependencies) {
          buffer.writeln('  $dependency: any');
        }
      }
      newPubspecYamlFile(packageRoot, buffer.toString());
      return packageRoot;
    }

    var pluginDirPath = newPackage('plugin', ['b', 'c']);
    var bRootPath = newPackage('b', ['d']);
    var cRootPath = newPackage('c', ['d']);
    var dRootPath = newPackage('d');
    var pluginFile = newFile('$pluginDirPath/bin/plugin.dart', '');
    //
    // Test path computation.
    //
    var files = manager.filesFor(pluginDirPath, isLegacyPlugin: true);
    expect(files.execution, pluginFile);
    var packageConfigFile = files.packageConfig;
    expect(packageConfigFile.exists, isTrue);

    var content = packageConfigFile.readAsStringSync();
    expect(content, '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "b",
      "rootUri": "${toUriStr(bRootPath)}",
      "packageUri": "lib/"
    },
    {
      "name": "c",
      "rootUri": "${toUriStr(cRootPath)}",
      "packageUri": "lib/"
    },
    {
      "name": "d",
      "rootUri": "${toUriStr(dRootPath)}",
      "packageUri": "lib/"
    },
    {
      "name": "plugin",
      "rootUri": "${toUriStr(pluginDirPath)}",
      "packageUri": "lib/"
    }
  ]
}
''');
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
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
  Future<void> test_start_notRunning() async {
    await withPlugin(
      test: (String pluginPath) async {
        var packagesPath = path.join(pluginPath, '.packages');
        var mainPath = path.join(pluginPath, 'bin', 'plugin.dart');
        var byteStorePath = path.join(pluginPath, 'byteStore');
        io.Directory(byteStorePath).createSync();
        var plugin = PluginInfo(
          pluginPath,
          mainPath,
          packagesPath,
          notificationManager,
          InstrumentationService.NULL_SERVICE,
        );
        var session = PluginSession(plugin);
        plugin.currentSession = session;
        expect(await session.start(byteStorePath, ''), isTrue);
        await session.stop();
      },
    );
  }
}

@reflectiveTest
class PluginSessionTest with ResourceProviderMixin {
  late TestNotificationManager notificationManager;
  late String pluginPath;
  late String executionPath;
  late String packagesPath;
  late String sdkPath;
  late PluginInfo plugin;
  late PluginSession session;

  void setUp() {
    notificationManager = TestNotificationManager();
    pluginPath = resourceProvider.convertPath('/pluginDir');
    executionPath = resourceProvider.convertPath('/pluginDir/bin/plugin.dart');
    packagesPath = resourceProvider.convertPath('/pluginDir/.packages');
    sdkPath = resourceProvider.convertPath('/sdk');
    plugin = PluginInfo(
      pluginPath,
      executionPath,
      packagesPath,
      notificationManager,
      InstrumentationService.NULL_SERVICE,
    );
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

  void test_handleOnError() {
    session.handleOnError(<String>['message', 'trace']);
    expect(
      notificationManager.pluginErrors.first,
      'An error occurred while executing an analyzer plugin: message\ntrace',
    );
  }

  Future<void> test_handleResponse() async {
    TestServerCommunicationChannel(session);
    var response = PluginVersionCheckResult(
      true,
      'name',
      'version',
      <String>[],
      contactInfo: 'contactInfo',
    ).toResponse('0', 1);
    var future = session.sendRequest(PluginVersionCheckParams('', '', ''));
    expect(session.pendingRequests, hasLength(1));
    session.handleResponse(response);
    expect(session.pendingRequests, hasLength(0));
    var result = await future;
    expect(result, same(response));
  }

  Future<void> test_handleResponse_withError() async {
    TestServerCommunicationChannel(session);
    var response = Response(
      '0' /* id */,
      1 /* requestTime */,
      error: RequestError(
        RequestErrorCode.PLUGIN_ERROR,
        'exception',
        stackTrace: 'some stackTrace',
      ),
    );

    var responseFuture = session.sendRequest(
      PluginVersionCheckParams('', '', ''),
    );
    session.handleResponse(response);
    await responseFuture;
    expect(
      notificationManager.pluginErrors,
      equals([
        'An error occurred while executing an analyzer plugin: exception\n'
            'some stackTrace',
      ]),
    );
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
    expect(
      await session.start(path.join(pluginPath, 'byteStore'), sdkPath),
      isFalse,
    );
    expect(
      notificationManager.pluginErrors.first,
      startsWith(
        'An error occurred while executing an analyzer plugin: Plugin is not '
        'compatible.',
      ),
    );
  }

  Future<void> test_start_running() async {
    TestServerCommunicationChannel(session);
    expect(() => session.start('', ''), throwsStateError);
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

/// A superclass for test classes that define tests that require plugins to be
/// created on disk.
abstract class PluginTestSupport {
  /// The default content of the plugin. This is a minimal plugin that will only
  /// respond correctly to version checks and to shutdown requests.
  static const _defaultPluginContent = r'''
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

  late PhysicalResourceProvider resourceProvider;

  late TestNotificationManager notificationManager;

  void setUp() {
    resourceProvider = PhysicalResourceProvider.INSTANCE;
    notificationManager = TestNotificationManager();
  }

  /// Creates a directory structure representing a plugin on disk, runs the
  /// given [test] function, and then removes the directory.
  ///
  /// The directory will have the following structure:
  /// ```
  /// <pluginDirectory>
  ///   .dart_tool/
  ///     package_config.dart
  ///   bin/
  ///     plugin.dart
  /// ```
  /// The name of the plugin directory will be the [pluginName], if one is
  /// provided (in order to allow more than one plugin to be created by a single
  /// test). The 'plugin.dart' file will contain the given [content], or default
  /// content that implements a minimal plugin if the contents are not given.
  /// The [test] function will be passed the path of the directory that was
  /// created.
  Future<void> withPlugin({
    String content = _defaultPluginContent,
    String pluginName = 'test_plugin',
    required Future<void> Function(String) test,
  }) async {
    var tempDirectory = io.Directory.systemTemp.createTempSync(pluginName);
    try {
      var pluginPath = tempDirectory.resolveSymbolicLinksSync();
      // Create a package config file.
      var pluginDartToolPath = path.join(pluginPath, '.dart_tool');
      io.Directory(pluginDartToolPath).createSync();
      var packageConfigFile = io.File(
        path.join(pluginDartToolPath, 'package_config.json'),
      );
      packageConfigFile.writeAsStringSync(
        io.File(sdkPackageConfigPath).readAsStringSync(),
      );
      //
      // Create the 'bin' directory.
      //
      var binPath = path.join(pluginPath, 'bin');
      io.Directory(binPath).createSync();
      //
      // Create the 'plugin.dart' file.
      //
      var pluginFile = io.File(path.join(binPath, 'plugin.dart'));
      pluginFile.writeAsStringSync(content);
      //
      // Run the actual test code.
      //
      await test(pluginPath);
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

class TestNotificationManager implements AbstractNotificationManager {
  List<Notification> notifications = <Notification>[];

  Map<String, Map<String, List<AnalysisError>>> recordedErrors =
      <String, Map<String, List<AnalysisError>>>{};

  List<String> pluginErrors = [];

  @override
  void handlePluginError(String message) {
    pluginErrors.add(message);
  }

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
    String pluginId,
    String filePath,
    List<AnalysisError> errorData,
  ) {
    recordedErrors.putIfAbsent(
          pluginId,
          () => <String, List<AnalysisError>>{},
        )[filePath] =
        errorData;
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
  void listen(
    void Function(Response response) onResponse,
    void Function(Notification notification) onNotification, {
    void Function(dynamic error)? onError,
    void Function()? onDone,
  }) {
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

mixin _ContextRoot on ResourceProviderMixin {
  ContextRootImpl _newContextRoot(String rootPath) {
    rootPath = convertPath(rootPath);
    return ContextRootImpl(
      resourceProvider,
      resourceProvider.getFolder(rootPath),
      BasicWorkspace.find(resourceProvider, Packages.empty, rootPath),
    );
  }
}
