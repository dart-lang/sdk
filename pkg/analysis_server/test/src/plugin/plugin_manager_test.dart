// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/session_logger/session_logger.dart';
import 'package:analyzer/file_system/file_system.dart';
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
    defineReflectiveTests(PluginManagerFromDiskTest);
    defineReflectiveTests(PluginManagerLegacyTest);
    defineReflectiveTests(PluginManagerParseDepfileTest);
    defineReflectiveTests(PluginManagerTest);
  });
}

typedef RunSyncHandler = io.ProcessResult Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  Encoding? stderrEncoding,
  Encoding? stdoutEncoding,
});

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
      SessionLogger(),
    );
  }

  Future<void> test_addPluginToContextRoot() async {
    var pkg1Dir = io.Directory.systemTemp.createTempSync('pkg1');
    var pkgPath = pkg1Dir.resolveSymbolicLinksSync();
    await withPlugin(
      test: (pluginPath) async {
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
        var responses = manager.broadcastWatchEvent(watchEvent);
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
            var paths = pluginIsolates
                .map((isolate) => isolate.pluginId)
                .toList();
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
class PluginManagerLegacyTest with ResourceProviderMixin, _ContextRoot {
  late PluginManager manager;

  void setUp() {
    manager = PluginManager(
      resourceProvider,
      resourceProvider.convertPath('/byteStore'),
      resourceProvider.convertPath('/sdk'),
      TestNotificationManager(),
      InstrumentationService.NULL_SERVICE,
      SessionLogger(),
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

  void test_pathsFor_legacy_withPackageConfigJsonFile() {
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

  void test_pathsFor_legacy_withPubspec_inBlazeWorkspace() {
    //
    // Build a Blaze workspace containing four packages, including the plugin.
    //
    newFile('/workspaceRoot/${file_paths.blazeWorkspaceMarker}', '');
    newFolder('/workspaceRoot/blaze-bin');
    newFolder('/workspaceRoot/blaze-genfiles');

    String newPackage(String packageName, [List<String>? dependencies]) {
      var packageRoot = newFolder(
        '/workspaceRoot/third_party/dart/$packageName',
      ).path;
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
    var bRootUri = getFolder(bRootPath).toUri();
    var cRootUri = getFolder(cRootPath).toUri();
    var dRootUri = getFolder(dRootPath).toUri();
    var pluginRootUri = getFolder(pluginDirPath).toUri();
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
      "rootUri": "$bRootUri",
      "packageUri": "lib/"
    },
    {
      "name": "c",
      "rootUri": "$cRootUri",
      "packageUri": "lib/"
    },
    {
      "name": "d",
      "rootUri": "$dRootUri",
      "packageUri": "lib/"
    },
    {
      "name": "plugin",
      "rootUri": "$pluginRootUri",
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
class PluginManagerParseDepfileTest with ResourceProviderMixin {
  void test_driveLetters() {
    var content = r'c:\\target: c:\\dep1.dart c:\\dep2.dart';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, [r'c:\dep1.dart', r'c:\dep2.dart']);
  }

  void test_parseDepfile_backslashes() {
    var content = r'target: foo\\bar\ dep1.dart';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, [r'foo\bar dep1.dart']);
  }

  void test_parseDepfile_empty() {
    var content = 'target: ';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, isEmpty);
  }

  void test_parseDepfile_emptyDependencies() {
    var content = 'target:   ';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, isEmpty);
  }

  void test_parseDepfile_escapedSpace() {
    var content = r'target: /some/path\ with/space/a.dart';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, [r'/some/path with/space/a.dart']);
  }

  void test_parseDepfile_multipleDependencies() {
    var content = 'target: dep1.dart dep2.dart dep3.dart\n';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, ['dep1.dart', 'dep2.dart', 'dep3.dart']);
  }

  void test_parseDepfile_noColon() {
    var content = 'target dep1.dart';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, null);
  }

  void test_parseDepfile_singleDependency() {
    var content = 'target: dep1.dart';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, ['dep1.dart']);
  }

  void test_parseDepfile_trailingEscapedSpace() {
    var content = r'target: dep1.dart\  dep2.dart\ ';
    var dependencies = PluginManager.parseDepfile(content);
    expect(dependencies, ['dep1.dart ', 'dep2.dart ']);
  }
}

@reflectiveTest
class PluginManagerTest with ResourceProviderMixin {
  late MockProcessRunner processRunner;
  late PluginManager manager;

  late String pluginDirPath;
  late File pubspecFile;
  late File pluginScriptFile;
  late File twoFile;
  late File packageConfigFile;
  late File aotFile;
  late int aotFileModificationStampBefore;
  late File depfile;
  final temporaryPaths = <String>[];

  String get aotFilePath =>
      resourceProvider.convertPath('/plugin/bin/plugin.aot');

  /// A handler for [MockProcessRunner.runSyncHandler] that touches the final
  /// AOT snapshot, whatever the command is.
  ///
  /// This makes the snapshot newer than everything else as soon as `pub upgrade`
  /// has run, which is not how a real `dart compile` behaves.
  RunSyncHandler get touchAotSnapshotHandler {
    return simpleRunSyncHandler((_, arguments) {
      resourceProvider.getFile(aotFilePath).writeAsStringSync('');
    });
  }

  /// A handler for [MockProcessRunner.runSyncHandler] that writes the AOT
  /// snapshot to wherever `dart compile aot-snapshot` was told to put it, and
  /// ignores any other command, like `pub upgrade`.
  RunSyncHandler get writeAotSnapshotHandler {
    return simpleRunSyncHandler((_, arguments) {
      if (!arguments.contains('compile')) return;
      _recordTemporaryPaths(arguments);
      resourceProvider.getFile(_outputPath(arguments)).writeAsStringSync('');
    });
  }

  void expectAotSnapshotIsRewritten() => expect(
    aotFile.modificationStamp,
    greaterThan(aotFileModificationStampBefore),
  );

  /// Expects that all of the temporary files, recorded by compiles, are gone.
  void expectNoTemporaryFiles() {
    expect(temporaryPaths, isNotEmpty);
    for (var path in temporaryPaths) {
      expect(resourceProvider.getFile(path).exists, isFalse, reason: path);
    }
  }

  void setUp() {
    processRunner = MockProcessRunner();
    manager = PluginManager(
      resourceProvider,
      resourceProvider.convertPath('/byteStore'),
      resourceProvider.convertPath('/sdk'),
      TestNotificationManager(),
      InstrumentationService.NULL_SERVICE,
      SessionLogger(),
      processRunner: processRunner,
    );
  }

  /// Returns a simple handler for [MockProcessRunner.runSyncHandler], which
  /// just calls [fn], without consideration for the parameters.
  ///
  /// The handler also returns a simple [io.ProcessResult] with no stderr or
  /// stdout text, and an exit code of 1.
  ///
  /// As the signature for the handler is very long, this function just serves
  /// as a convenience function, for when the parameters are not used.
  RunSyncHandler simpleRunSyncHandler(
    void Function(String executable, List<String> arguments) fn,
  ) {
    return (
      executable,
      arguments, {
      environment,
      workingDirectory,
      stderrEncoding,
      stdoutEncoding,
    }) {
      fn(executable, arguments);
      return io.ProcessResult(
        1 /* pid */,
        0 /* exitCode */,
        '' /* stdout */,
        '' /* stderr */,
      );
    };
  }

  void test_pathsFor() {
    late File packageConfigFile;

    processRunner.runSyncHandler = simpleRunSyncHandler((_, _) {
      packageConfigFile = newPackageConfigJsonFile('/plugin', '');
    });

    writeAllFiles();

    var files = manager.filesFor(
      pluginDirPath,
      isLegacyPlugin: false,
      builtAsAot: true,
    );

    expect(files.execution, aotFile);
    expect(files.packageConfig, packageConfigFile);
  }

  void test_pathsFor_aotIsNewest() {
    processRunner.runSyncHandler = simpleRunSyncHandler((_, arguments) {
      // We should not be re-compiling in this case.
      expect(arguments, isNot(contains('compile')));
    });

    writeAllFiles();

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expect(aotFileModificationStampBefore, aotFile.modificationStamp);
  }

  void test_pathsFor_compile_deletesStaleTemporaryFiles() {
    processRunner.runSyncHandler = writeAotSnapshotHandler;

    writeAllFiles();
    pluginScriptFile.writeAsStringSync('// newer');
    // Files like these are left by compiles that were killed.
    var staleSnapshot = newFile('/plugin/bin/plugin.aot.123.456.tmp', 'x');
    var staleDepfile = newFile('/plugin/bin/depfile.txt.123.456.tmp', 'x');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expect(staleSnapshot.exists, isFalse);
    expect(staleDepfile.exists, isFalse);
  }

  void test_pathsFor_compile_doesNotDeleteExistingSnapshot() {
    // Another analysis server might have the existing snapshot mapped, so it
    // must stay in place, complete, until it is atomically replaced.
    late String contentDuringCompile;
    processRunner.runSyncHandler = simpleRunSyncHandler((_, arguments) {
      if (!arguments.contains('compile')) return;
      _recordTemporaryPaths(arguments);
      contentDuringCompile = aotFile.exists ? aotFile.readAsStringSync() : '';
      resourceProvider.getFile(_outputPath(arguments)).writeAsStringSync('new');
    });

    writeAllFiles();
    aotFile.writeAsStringSync('old');
    pluginScriptFile.writeAsStringSync('// newer');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expect(contentDuringCompile, 'old');
    expect(aotFile.readAsStringSync(), 'new');
  }

  void test_pathsFor_compile_failure_keepsExistingSnapshot() {
    processRunner.runSyncHandler =
        (
          executable,
          arguments, {
          environment,
          workingDirectory,
          stderrEncoding,
          stdoutEncoding,
        }) {
          if (!arguments.contains('compile')) {
            return io.ProcessResult(1, 0, '', '');
          }
          _recordTemporaryPaths(arguments);
          // A partially written output.
          resourceProvider
              .getFile(_outputPath(arguments))
              .writeAsStringSync('partial');
          return io.ProcessResult(1, 1, '', 'boom');
        };

    writeAllFiles();
    aotFile.writeAsStringSync('old');
    pluginScriptFile.writeAsStringSync('// newer');

    expect(
      () => manager.filesFor(
        pluginDirPath,
        isLegacyPlugin: false,
        builtAsAot: true,
      ),
      throwsA(isA<PluginException>()),
    );
    expect(aotFile.readAsStringSync(), 'old');
    expectNoTemporaryFiles();
  }

  void test_pathsFor_compile_keepsOtherFiles() {
    processRunner.runSyncHandler = writeAotSnapshotHandler;

    writeAllFiles();
    pluginScriptFile.writeAsStringSync('// newer');
    var other1 = newFile('/plugin/bin/plugin.aot.tmp', 'x');
    var other2 = newFile('/plugin/bin/other.123.456.tmp', 'x');
    var other3 = newFile('/plugin/bin/plugin.aot.123.456', 'x');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expect(other1.exists, isTrue);
    expect(other2.exists, isTrue);
    expect(other3.exists, isTrue);
    expect(twoFile.exists, isTrue);
  }

  void test_pathsFor_compile_publishesDepfile() {
    processRunner.runSyncHandler = simpleRunSyncHandler((_, arguments) {
      if (!arguments.contains('compile')) return;
      _recordTemporaryPaths(arguments);
      resourceProvider.getFile(_outputPath(arguments)).writeAsStringSync('');
      resourceProvider
          .getFile(_depfilePath(arguments))
          .writeAsStringSync('target: ${pluginScriptFile.path}');
    });

    writeAllFiles();
    depfile.writeAsStringSync('old: ${pluginScriptFile.path}');
    pluginScriptFile.writeAsStringSync('// newer');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expect(depfile.readAsStringSync(), 'target: ${pluginScriptFile.path}');
    expectNoTemporaryFiles();
  }

  void test_pathsFor_compile_replacesSnapshotByRename() {
    processRunner.runSyncHandler = simpleRunSyncHandler((_, arguments) {
      if (!arguments.contains('compile')) return;
      _recordTemporaryPaths(arguments);
      resourceProvider.getFile(_outputPath(arguments)).writeAsStringSync('new');
    });

    writeAllFiles();
    pluginScriptFile.writeAsStringSync('// newer');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expect(aotFile.readAsStringSync(), 'new');
    // No temporary files are left behind.
    expectNoTemporaryFiles();
  }

  void test_pathsFor_compile_writesToTemporaryFiles() {
    late List<String> compileArguments;
    processRunner.runSyncHandler = simpleRunSyncHandler((_, arguments) {
      if (!arguments.contains('compile')) return;
      _recordTemporaryPaths(arguments);
      compileArguments = arguments;
      resourceProvider.getFile(_outputPath(arguments)).writeAsStringSync('');
    });

    writeAllFiles();
    pluginScriptFile.writeAsStringSync('// newer');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);

    var binFolder = convertPath('/plugin/bin');
    // The compiler never writes straight to the files that other analysis
    // servers read.
    expect(_outputPath(compileArguments), isNot(aotFilePath));
    expect(_outputPath(compileArguments), startsWith(binFolder));
    expect(_depfilePath(compileArguments), isNot(depfile.path));
    expect(_depfilePath(compileArguments), startsWith(binFolder));
  }

  void test_pathsFor_dependencyIsNewer() {
    processRunner.runSyncHandler = writeAotSnapshotHandler;

    writeAllFiles();
    twoFile.writeAsStringSync('');
    depfile.writeAsStringSync('target: ${twoFile.path}');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expectAotSnapshotIsRewritten();
  }

  void test_pathsFor_depfileHasBadPath() {
    processRunner.runSyncHandler = writeAotSnapshotHandler;

    writeAllFiles();
    depfile.writeAsStringSync('target: not/absolute');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expectAotSnapshotIsRewritten();
  }

  void test_pathsFor_depfileIsMalformed() {
    processRunner.runSyncHandler = writeAotSnapshotHandler;

    writeAllFiles();
    depfile.writeAsStringSync('target');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expectAotSnapshotIsRewritten();
  }

  void test_pathsFor_depfileIsMissing() {
    processRunner.runSyncHandler = writeAotSnapshotHandler;

    writeAllFiles();
    depfile.delete();

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expectAotSnapshotIsRewritten();
  }

  void test_pathsFor_noAot() {
    processRunner.runSyncHandler = simpleRunSyncHandler((_, _) {
      newPackageConfigJsonFile('/plugin', '');
    });

    writeAllFiles();

    var files = manager.filesFor(pluginDirPath, isLegacyPlugin: false);
    expect(files.execution, pluginScriptFile);
    expect(files.packageConfig, packageConfigFile);
  }

  void test_pathsFor_packageConfigIsNewer() {
    // The snapshot is rewritten by the `pub upgrade` step of this fake, not
    // because the package config is a dependency of the snapshot.
    processRunner.runSyncHandler = touchAotSnapshotHandler;

    writeAllFiles();
    packageConfigFile.writeAsStringSync('');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expectAotSnapshotIsRewritten();
  }

  void test_pathsFor_pluginScriptIsNewer() {
    processRunner.runSyncHandler = writeAotSnapshotHandler;

    writeAllFiles();
    pluginScriptFile.writeAsStringSync('');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expectAotSnapshotIsRewritten();
  }

  void test_pathsFor_pubspecIsNewer() {
    processRunner.runSyncHandler = writeAotSnapshotHandler;

    writeAllFiles();
    pubspecFile.writeAsStringSync('');

    manager.filesFor(pluginDirPath, isLegacyPlugin: false, builtAsAot: true);
    expectAotSnapshotIsRewritten();
  }

  void test_pluginStateFolder_differsBetweenDartVersions() {
    var path = convertPath('/project');
    var folder1 = _managerWithDartVersion('3.11.1').pluginStateFolderPath(path);
    var folder2 = _managerWithDartVersion('3.11.3').pluginStateFolderPath(path);
    expect(folder1, isNot(folder2));
  }

  void test_pluginStateFolder_differsBetweenPaths() {
    var manager = _managerWithDartVersion('3.11.3');
    expect(
      manager.pluginStateFolderPath(convertPath('/project1')),
      isNot(manager.pluginStateFolderPath(convertPath('/project2'))),
    );
  }

  void test_pluginStateFolder_sameForSameDartVersion() {
    var path = convertPath('/project');
    var folder1 = _managerWithDartVersion('3.11.3').pluginStateFolderPath(path);
    var folder2 = _managerWithDartVersion('3.11.3').pluginStateFolderPath(path);
    expect(folder1, folder2);
  }

  // Builds the minimal directory structure for a plugin package.
  void writeAllFiles() {
    pluginDirPath = newFolder('/plugin').path;
    pluginScriptFile = newFile('/plugin/bin/plugin.dart', '''
import 'two.dart';
''');
    twoFile = newFile('/plugin/bin/two.dart', '');
    depfile = newFile(
      '/plugin/bin/depfile.txt',
      'target: ${pluginScriptFile.path}',
    );
    pubspecFile = newFile('/plugin/pubspec.yaml', '''
name: my_plugin
environment:
  sdk: ^3.10.0
''');
    packageConfigFile = newPackageConfigJsonFile('/plugin', '');
    aotFile = newFile('/plugin/bin/plugin.aot', '');
    aotFileModificationStampBefore = aotFile.modificationStamp;
  }

  /// The path passed to `dart compile aot-snapshot` with `--depfile`.
  String _depfilePath(List<String> arguments) {
    var index = arguments.indexOf('--depfile');
    expect(index, isNonNegative, reason: 'expected --depfile in $arguments');
    return arguments[index + 1];
  }

  PluginManager _managerWithDartVersion(String dartVersion) => PluginManager(
    resourceProvider,
    resourceProvider.convertPath('/byteStore'),
    resourceProvider.convertPath('/sdk'),
    TestNotificationManager(),
    InstrumentationService.NULL_SERVICE,
    SessionLogger(),
    processRunner: processRunner,
    dartVersion: dartVersion,
  );

  /// The path passed to `dart compile aot-snapshot` with `-o`.
  String _outputPath(List<String> arguments) {
    var index = arguments.indexOf('-o');
    expect(index, isNonNegative, reason: 'expected -o in $arguments');
    return arguments[index + 1];
  }

  /// Records the temporary files that a compile was told to write to.
  void _recordTemporaryPaths(List<String> arguments) {
    temporaryPaths.add(_outputPath(arguments));
    temporaryPaths.add(_depfilePath(arguments));
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
