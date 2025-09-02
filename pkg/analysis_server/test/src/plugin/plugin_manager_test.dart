// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart'
    hide ContextRoot;
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart' as watcher;

import '../../mocks.dart';
import 'plugin_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginManagerTest);
    defineReflectiveTests(PluginManagerFromDiskTest);
  });
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
        var exception = manager.pluginIsolates.first.exception;
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
        var pluginIsolates = manager.pluginsForContextRoot(contextRoot);
        expect(pluginIsolates, hasLength(1));
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

            var pluginIsolates = manager.pluginsForContextRoot(contextRoot);
            expect(pluginIsolates, hasLength(2));
            var paths =
                pluginIsolates.map((isolate) => isolate.pluginId).toList();
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

        var pluginIsolates = manager.pluginsForContextRoot(contextRoot);
        expect(pluginIsolates, hasLength(1));
        expect(pluginIsolates[0].pluginId, pluginPath);

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
            var plugins = manager.pluginIsolates;
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
