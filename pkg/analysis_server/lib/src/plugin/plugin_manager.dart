// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server_plugin/src/plugin_server.dart';
/// @docImport 'package:analysis_server/src/plugin/plugin_watcher.dart';
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, Process, ProcessResult;

import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_isolate.dart';
import 'package:analysis_server/src/utilities/sdk.dart';
import 'package:analyzer/dart/analysis/context_root.dart' as analyzer;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/glob.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart' as watcher;
import 'package:yaml/yaml.dart';

const _builtAsAot = bool.fromEnvironment('built_as_aot');

/// An indication of a problem with the execution of a plugin that occurs prior
/// to the execution of the plugin's entry point in an isolate.
class PluginException implements Exception {
  /// A message describing the problem.
  final String message;

  /// Initialize a newly created exception to have the given [message].
  PluginException(this.message);

  @override
  String toString() => message;
}

/// The necessary files that define an analyzer plugin on disk.
class PluginFiles {
  /// The plugin entry point.
  final File execution;

  /// The plugin package config file.
  final File packageConfig;

  PluginFiles(this.execution, this.packageConfig);
}

/// An object used to manage the currently running plugins.
class PluginManager {
  /// A table, keyed by both a plugin and a request method, to a list of the
  /// times that it took the plugin to return a response to requests with the
  /// method.
  static Map<PluginIsolate, Map<String, PercentileCalculator>>
  pluginResponseTimes = <PluginIsolate, Map<String, PercentileCalculator>>{};

  /// The console environment key used by the pub tool.
  static const String _pubEnvironmentKey = 'PUB_ENVIRONMENT';

  /// The resource provider used to access the file system.
  final ResourceProvider _resourceProvider;

  /// The absolute path of the directory containing the on-disk byte store, or
  /// `null` if there is no on-disk store.
  final String? _byteStorePath;

  /// The absolute path of the directory containing the SDK.
  final String _sdkPath;

  /// The object used to manage the receiving and sending of notifications.
  final AbstractNotificationManager _notificationManager;

  /// The instrumentation service that is being used by the analysis server.
  final InstrumentationService instrumentationService;

  /// A table mapping the paths of plugins to information about those plugins.
  final Map<String, PluginIsolate> _pluginMap = <String, PluginIsolate>{};

  /// The parameters for the last 'analysis.setPriorityFiles' request that was
  /// received from the client. Because plugins are lazily discovered, this
  /// needs to be retained so that it can be sent after a plugin has been
  /// started.
  AnalysisSetPriorityFilesParams? _analysisSetPriorityFilesParams;

  /// The parameters for the last 'analysis.setSubscriptions' request that was
  /// received from the client. Because plugins are lazily discovered, this
  /// needs to be retained so that it can be sent after a plugin has been
  /// started.
  AnalysisSetSubscriptionsParams? _analysisSetSubscriptionsParams;

  /// The current state of content overlays. Because plugins are lazily
  /// discovered, the state needs to be retained so that it can be sent after a
  /// plugin has been started.
  final Map<String, AddContentOverlay> _overlayState = {};

  final StreamController<void> _pluginsChanged = StreamController.broadcast();

  /// Whether plugins are "initialized."
  ///
  /// Plugins are declared to be initialized either (a) when the [PluginWatcher]
  /// has determined no plugins are configured to be run, or (b) when the
  /// plugins are configured and the first status notification is received by
  /// the analysis server.
  Completer<void> initializedCompleter = Completer();

  /// Initialize a newly created plugin manager. The notifications from the
  /// running plugins will be handled by the given [_notificationManager].
  PluginManager(
    this._resourceProvider,
    this._byteStorePath,
    this._sdkPath,
    this._notificationManager,
    this.instrumentationService,
  );

  /// All of the legacy plugins that are currently known.
  List<PluginIsolate> get legacyPluginIsolates =>
      pluginIsolates.where((p) => p.isLegacy).toList();

  /// All of the "new" plugins that are currently known.
  List<PluginIsolate> get newPluginIsolates =>
      pluginIsolates.where((p) => !p.isLegacy).toList();

  /// All of the plugins that are currently known.
  List<PluginIsolate> get pluginIsolates => _pluginMap.values.toList();

  /// Stream emitting an event when known [pluginIsolates] change.
  Stream<void> get pluginsChanged => _pluginsChanged.stream;

  /// Adds the plugin with the given [path] to the list of plugins that should
  /// be used when analyzing code for the given [contextRoot].
  ///
  /// If the plugin had not yet been started, then it will be started by this
  /// method.
  ///
  /// Specify whether this is a legacy plugin with [isLegacyPlugin].
  Future<void> addPluginToContextRoot(
    analyzer.ContextRoot contextRoot,
    String path, {
    required bool isLegacyPlugin,
  }) async {
    var pluginIsolate = _pluginMap[path];
    var isNew = false;
    if (pluginIsolate == null) {
      isNew = true;
      PluginFiles pluginFiles;
      try {
        pluginFiles = filesFor(path, isLegacyPlugin: isLegacyPlugin);
      } catch (exception, stackTrace) {
        pluginIsolate = PluginIsolate(
          path,
          null,
          null,
          _notificationManager,
          instrumentationService,
          isLegacy: isLegacyPlugin,
        );
        pluginIsolate.reportException(CaughtException(exception, stackTrace));
        _pluginMap[path] = pluginIsolate;
        return;
      }
      pluginIsolate = PluginIsolate(
        path,
        pluginFiles.execution.path,
        pluginFiles.packageConfig.path,
        _notificationManager,
        instrumentationService,
        isLegacy: isLegacyPlugin,
      );
      _pluginMap[path] = pluginIsolate;
      try {
        instrumentationService.logInfo('Starting plugin "$pluginIsolate"');
        var session = await pluginIsolate.start(_byteStorePath, _sdkPath);
        unawaited(
          session?.onDone.then((_) {
            if (_pluginMap[path] == pluginIsolate) {
              _pluginMap.remove(path);
              _notifyPluginsChanged();
            }
          }),
        );
      } catch (exception, stackTrace) {
        // Record the exception (for debugging purposes) and record the fact
        // that we should not try to communicate with the plugin.
        pluginIsolate.reportException(CaughtException(exception, stackTrace));
        isNew = false;
      }

      _notifyPluginsChanged();
    }
    pluginIsolate.addContextRoot(contextRoot);
    if (isNew) {
      var analysisSetSubscriptionsParams = _analysisSetSubscriptionsParams;
      if (analysisSetSubscriptionsParams != null) {
        pluginIsolate.sendRequest(analysisSetSubscriptionsParams);
      }
      if (_overlayState.isNotEmpty) {
        pluginIsolate.sendRequest(AnalysisUpdateContentParams(_overlayState));
      }
      var analysisSetPriorityFilesParams = _analysisSetPriorityFilesParams;
      if (analysisSetPriorityFilesParams != null) {
        pluginIsolate.sendRequest(analysisSetPriorityFilesParams);
      }
    }
  }

  /// Broadcast a request built from the given [params] to all of the plugins
  /// that are currently associated with the given [contextRoot]. Return a list
  /// containing futures that will complete when each of the plugins have sent a
  /// response.
  Map<PluginIsolate, Future<Response>> broadcastRequest(
    RequestParams params, {
    analyzer.ContextRoot? contextRoot,
  }) {
    var pluginIsolates = pluginsForContextRoot(contextRoot);
    var responseMap = <PluginIsolate, Future<Response>>{};
    for (var pluginIsolate in pluginIsolates) {
      var request = pluginIsolate.currentSession?.sendRequest(params);
      // Only add an entry to the map if we have sent a request.
      if (request != null) {
        responseMap[pluginIsolate] = request;
      }
    }
    return responseMap;
  }

  /// Broadcasts the given [watchEvent] to all of the plugins that are analyzing
  /// in contexts containing the file associated with the event.
  ///
  /// Returns a list containing futures that will complete when each of the
  /// plugins have sent a response.
  List<Future<Response>> broadcastWatchEvent(watcher.WatchEvent watchEvent) {
    var filePath = watchEvent.path;

    WatchEvent? event;
    var responses = <Future<Response>>[];
    var separator = _resourceProvider.pathContext.separator;
    for (var pluginIsolate in _pluginMap.values) {
      var session = pluginIsolate.currentSession;
      if (session == null) continue;
      if (!pluginIsolate.isAnalyzing(filePath)) continue;
      var interestingGlobs = session.interestingFileGlobs;

      // The list of interesting file globs is `null` if the isolate has not yet
      // responded to the 'plugin.versionCheck' request. If that happens, then
      // the isolate hasn't had a chance to analyze anything yet; hence, it
      // it does not need to get watch events, yet.
      if (interestingGlobs == null) continue;

      if (!interestingGlobs.any((g) => Glob(separator, g).matches(filePath))) {
        continue;
      }

      event ??= _convertWatchEvent(watchEvent);
      var params = AnalysisHandleWatchEventsParams([event]);
      responses.add(session.sendRequest(params));
    }
    return responses;
  }

  /// Returns the files associated with the plugin at the given [pluginPath].
  ///
  /// In some cases, the plugin's sources are copied to a special directory. If
  /// [pluginPath] does not include a `pubspec.yaml` file, we do not. If
  /// [pluginPath] exists in a [BlazeWorkspace], we do not.
  ///
  /// Throws a [PluginException] if there is a problem that prevents the plugin
  /// from being executing.
  @visibleForTesting
  PluginFiles filesFor(String pluginPath, {required bool isLegacyPlugin}) {
    var pluginFolder = _resourceProvider.getFolder(pluginPath);
    var pubspecFile = pluginFolder.getChildAssumingFile(file_paths.pubspecYaml);
    if (!pubspecFile.exists) {
      // If there's no pubspec file, then we don't need to copy the package
      // because we won't be running pub.
      return _computeFiles(pluginFolder);
    }
    var workspace = BlazeWorkspace.find(_resourceProvider, pluginFolder.path);
    if (workspace != null) {
      // Similarly, we won't be running pub if we're in a workspace because
      // there is exactly one version of each package.
      return _computeFiles(pluginFolder, workspace: workspace);
    }

    if (!isLegacyPlugin) {
      return _computeFiles(pluginFolder, pubCommand: 'upgrade');
    }

    // Copy the plugin directory to a unique subdirectory of the plugin
    // manager's state location. The subdirectory's name is selected such that
    // it will be invariant across sessions, reducing the number of times we
    // copy the plugin contents, and the number of times we run `pub`.

    var parentFolder = pluginStateFolder(pluginPath);
    if (parentFolder.exists) {
      var executionFolder = parentFolder.getChildAssumingFolder(
        pluginFolder.shortName,
      );
      return _computeFiles(executionFolder, pubCommand: 'upgrade');
    }
    var executionFolder = pluginFolder.copyTo(parentFolder);
    return _computeFiles(executionFolder, pubCommand: 'get');
  }

  /// Return a list of all of the plugin isolates that are currently associated
  /// with the given [contextRoot].
  @visibleForTesting
  List<PluginIsolate> pluginsForContextRoot(analyzer.ContextRoot? contextRoot) {
    if (contextRoot == null) {
      return _pluginMap.values.toList();
    }
    return [
      for (var pluginIsolate in _pluginMap.values)
        if (pluginIsolate.contextRoots.contains(contextRoot)) pluginIsolate,
    ];
  }

  /// Returns the "plugin state" folder for a plugin at [pluginPath].
  ///
  /// This is a directory under the state location for '.plugin_manager', named
  /// with a hash based on [pluginPath].
  Folder pluginStateFolder(String pluginPath) {
    var stateFolder = _resourceProvider.getStateLocation('.plugin_manager');
    if (stateFolder == null) {
      throw PluginException('No state location, so plugin could not be copied');
    }
    var stateName = _uniqueDirectoryName(pluginPath);
    return stateFolder.getChildAssumingFolder(stateName);
  }

  /// The given [contextRoot] is no longer being analyzed.
  void removedContextRoot(analyzer.ContextRoot contextRoot) {
    var plugins = _pluginMap.values.toList();
    for (var plugin in plugins) {
      plugin.removeContextRoot(contextRoot);
      if (plugin.contextRoots.isEmpty) {
        _pluginMap.remove(plugin.pluginId);
        _notifyPluginsChanged();
        try {
          plugin.stop();
        } catch (e, st) {
          instrumentationService.logException(
            SilentException('Issue stopping a plugin', e, st),
          );
        }
      }
    }
  }

  /// Restart all currently running plugins.
  Future<void> restartPlugins() async {
    for (var plugin in _pluginMap.values.toList()) {
      if (plugin.currentSession != null) {
        //
        // Capture needed state.
        //
        var contextRoots = plugin.contextRoots;
        var path = plugin.pluginId;
        //
        // Stop the plugin.
        //
        await plugin.stop();
        //
        // Restart the plugin.
        //
        _pluginMap[path] = plugin;
        var session = await plugin.start(_byteStorePath, _sdkPath);
        unawaited(
          session?.onDone.then((_) {
            _pluginMap.remove(path);
          }),
        );
        //
        // Re-initialize the plugin.
        //
        plugin.addContextRoots(contextRoots);
        var analysisSetSubscriptionsParams = _analysisSetSubscriptionsParams;
        if (analysisSetSubscriptionsParams != null) {
          plugin.sendRequest(analysisSetSubscriptionsParams);
        }
        if (_overlayState.isNotEmpty) {
          plugin.sendRequest(AnalysisUpdateContentParams(_overlayState));
        }
        var analysisSetPriorityFilesParams = _analysisSetPriorityFilesParams;
        if (analysisSetPriorityFilesParams != null) {
          plugin.sendRequest(analysisSetPriorityFilesParams);
        }
      }
    }
  }

  /// Send a request based on the given [params] to existing plugins to set the
  /// priority files to those specified by the [params]. As a side-effect,
  /// record the parameters so that they can be sent to any newly started
  /// plugins.
  void setAnalysisSetPriorityFilesParams(
    AnalysisSetPriorityFilesParams params,
  ) {
    for (var plugin in _pluginMap.values) {
      plugin.sendRequest(params);
    }
    _analysisSetPriorityFilesParams = params;
  }

  /// Send a request based on the given [params] to existing plugins to set the
  /// subscriptions to those specified by the [params]. As a side-effect, record
  /// the parameters so that they can be sent to any newly started plugins.
  void setAnalysisSetSubscriptionsParams(
    AnalysisSetSubscriptionsParams params,
  ) {
    for (var plugin in _pluginMap.values) {
      plugin.sendRequest(params);
    }
    _analysisSetSubscriptionsParams = params;
  }

  /// Send a request based on the given [params] to existing plugins to set the
  /// content overlays to those specified by the [params]. As a side-effect,
  /// update the overlay state so that it can be sent to any newly started
  /// plugins.
  void setAnalysisUpdateContentParams(AnalysisUpdateContentParams params) {
    for (var plugin in _pluginMap.values) {
      plugin.sendRequest(params);
    }
    var files = params.files;
    for (var file in files.keys) {
      var overlay = files[file];
      if (overlay is RemoveContentOverlay) {
        _overlayState.remove(file);
      } else if (overlay is AddContentOverlay) {
        _overlayState[file] = overlay;
      } else if (overlay is ChangeContentOverlay) {
        var previousOverlay = _overlayState[file]!;
        var newContent = SourceEdit.applySequence(
          previousOverlay.content,
          overlay.edits,
        );
        _overlayState[file] = AddContentOverlay(newContent);
      } else {
        throw ArgumentError('Invalid class of overlay: ${overlay.runtimeType}');
      }
    }
  }

  /// Stops all of the plugin isolates that are currently running.
  Future<List<void>> stopAll() {
    return Future.wait(
      _pluginMap.values.map((pluginIsolate) async {
        try {
          await pluginIsolate.stop();
        } catch (e, st) {
          instrumentationService.logException(e, st);
        }
      }),
    );
  }

  /// Compiles [entrypoint] to an AOT snapshot and records timing to the
  /// instrumentation log.
  ProcessResult _compileAotSnapshot(String entrypoint) {
    instrumentationService.logInfo(
      'Running "dart compile aot-snapshot $entrypoint".',
    );

    var stopwatch = Stopwatch()..start();
    var result = Process.runSync(
      sdk.dart,
      ['compile', 'aot-snapshot', entrypoint],
      stderrEncoding: utf8,
      stdoutEncoding: utf8,
    );
    stopwatch.stop();

    instrumentationService.logInfo(
      'Running "dart compile aot-snapshot" took ${stopwatch.elapsed}.',
    );

    return result;
  }

  /// Compiles [pluginFile], in [pluginFolder], to an AOT snapshot, and returns
  /// the [File] for the snapshot.
  File _compileAsAot({required File pluginFile, required Folder pluginFolder}) {
    // When the Dart Analysis Server is built as AOT, then all spawned
    // Isolates must also be built as AOT.
    var aotResult = _compileAotSnapshot(pluginFile.path);
    if (aotResult.exitCode != 0) {
      var buffer = StringBuffer();
      buffer.writeln(
        'Failed to compile "${pluginFile.path}" to an AOT snapshot.',
      );
      buffer.writeln('  pluginFolder = ${pluginFolder.path}');
      buffer.writeln('  exitCode = ${aotResult.exitCode}');
      buffer.writeln('  stdout = ${aotResult.stdout}');
      buffer.writeln('  stderr = ${aotResult.stderr}');
      var exceptionReason = buffer.toString();
      instrumentationService.logError(exceptionReason);
      throw PluginException(exceptionReason);
    }

    return pluginFolder
        .getChildAssumingFolder('bin')
        .getChildAssumingFile('plugin.aot');
  }

  /// Computes the plugin files, given that the plugin should exist in
  /// [pluginFolder].
  ///
  /// Runs `pub` if [pubCommand] is not `null`.
  PluginFiles _computeFiles(
    Folder pluginFolder, {
    String? pubCommand,
    Workspace? workspace,
  }) {
    var pluginFile = pluginFolder
        .getChildAssumingFolder('bin')
        .getChildAssumingFile('plugin.dart');
    if (!pluginFile.exists) {
      throw PluginException("File '${pluginFile.path}' does not exist.");
    }
    File? packageConfigFile = pluginFolder
        .getChildAssumingFolder(file_paths.dotDartTool)
        .getChildAssumingFile(file_paths.packageConfigJson);

    if (pubCommand != null) {
      var pubResult = _runPubCommand(pubCommand, pluginFolder);
      String? exceptionReason;
      if (pubResult.exitCode != 0) {
        var buffer = StringBuffer();
        buffer.writeln(
          'An error occurred while setting up the analyzer plugin package at '
          "'${pluginFolder.path}'. The `dart pub $pubCommand` command failed:",
        );
        buffer.writeln('  exitCode = ${pubResult.exitCode}');
        buffer.writeln('  stdout = ${pubResult.stdout}');
        buffer.writeln('  stderr = ${pubResult.stderr}');
        throw PluginException(buffer.toString());
      }
      if (!packageConfigFile.exists) {
        exceptionReason ??= 'File "${packageConfigFile.path}" does not exist.';
        throw PluginException(exceptionReason);
      }

      if (_builtAsAot) {
        // Update the entrypoint path to be the AOT-compiled file.
        pluginFile = _compileAsAot(
          pluginFile: pluginFile,
          pluginFolder: pluginFolder,
        );
      }

      return PluginFiles(pluginFile, packageConfigFile);
    }

    if (!packageConfigFile.exists) {
      if (workspace == null) {
        throw PluginException('Could not create "${packageConfigFile.path}".');
      }

      packageConfigFile = _createPackageConfigFile(
        pluginFolder,
        workspace.packageUriResolver,
      );
      if (packageConfigFile == null) {
        throw PluginException(
          "Could not create the '${file_paths.packageConfigJson}' file in "
          "the workspace at '$workspace'.",
        );
      }
    }

    if (_builtAsAot) {
      // Update the entrypoint path to be the AOT-compiled file.
      pluginFile = _compileAsAot(
        pluginFile: pluginFile,
        pluginFolder: pluginFolder,
      );
    }
    return PluginFiles(pluginFile, packageConfigFile);
  }

  WatchEventType _convertChangeType(watcher.ChangeType type) {
    return switch (type) {
      watcher.ChangeType.ADD => WatchEventType.ADD,
      watcher.ChangeType.MODIFY => WatchEventType.MODIFY,
      watcher.ChangeType.REMOVE => WatchEventType.REMOVE,
      _ => throw StateError('Unknown change type: $type'),
    };
  }

  WatchEvent _convertWatchEvent(watcher.WatchEvent watchEvent) {
    return WatchEvent(_convertChangeType(watchEvent.type), watchEvent.path);
  }

  /// Returns a temporary `package_config.json` file that is appropriate for
  /// the plugin in the given [pluginFolder].
  ///
  /// The [packageUriResolver] is used to determine the location of the
  /// packages that need to be included in the package config file.
  File? _createPackageConfigFile(
    Folder pluginFolder,
    UriResolver packageUriResolver,
  ) {
    var pluginPath = pluginFolder.path;
    var stateFolder = _resourceProvider.getStateLocation('.plugin_manager')!;
    var stateName = '${_uniqueDirectoryName(pluginPath)}.packages';
    var packageConfigFile = stateFolder.getChildAssumingFile(stateName);
    if (!packageConfigFile.exists) {
      var pluginPubspec = pluginFolder.getChildAssumingFile(
        file_paths.pubspecYaml,
      );
      if (!pluginPubspec.exists) {
        return null;
      }

      try {
        var visitedPackageNames = <String>{};
        var packages = <_Package>[];
        var context = _resourceProvider.pathContext;
        packages.add(_Package(context.basename(pluginPath), pluginFolder));
        var pubspecFiles = <File>[];
        pubspecFiles.add(pluginPubspec);
        while (pubspecFiles.isNotEmpty) {
          var pubspecFile = pubspecFiles.removeLast();
          for (var packageName in _readDependencies(pubspecFile)) {
            if (visitedPackageNames.add(packageName)) {
              var uri = Uri.parse('package:$packageName/$packageName.dart');
              var packageSource = packageUriResolver.resolveAbsolute(uri);
              if (packageSource != null) {
                var packageRoot = _resourceProvider
                    .getFile(packageSource.fullName)
                    .parent
                    .parent;
                packages.add(_Package(packageName, packageRoot));
                pubspecFiles.add(
                  packageRoot.getChildAssumingFile(file_paths.pubspecYaml),
                );
              }
            }
          }
        }

        packages.sort((a, b) => a.name.compareTo(b.name));

        var packageConfigBuilder = PackageConfigFileBuilder();
        for (var package in packages) {
          packageConfigBuilder.add(
            name: package.name,
            rootPath: package.root.path,
          );
        }
        packageConfigFile.writeAsStringSync(
          packageConfigBuilder.toContent(
            pathContext: _resourceProvider.pathContext,
          ),
        );
      } catch (exception) {
        // If we are not able to produce a package config file, return `null` so
        // that callers will not try to load the plugin.
        return null;
      }
    }
    return packageConfigFile;
  }

  void _notifyPluginsChanged() => _pluginsChanged.add(null);

  /// Return the names of packages that are listed as dependencies in the given
  /// [pubspecFile].
  Iterable<String> _readDependencies(File pubspecFile) {
    var document = loadYamlDocument(
      pubspecFile.readAsStringSync(),
      sourceUrl: pubspecFile.toUri(),
    );
    var contents = document.contents;
    if (contents is YamlMap) {
      var dependencies = contents['dependencies'] as YamlNode?;
      if (dependencies is YamlMap) {
        return dependencies.keys.cast<String>();
      }
    }
    return const <String>[];
  }

  /// Runs (and records timing to the instrumentation log) a Pub command
  /// [pubCommand] in [folder].
  ProcessResult _runPubCommand(String pubCommand, Folder folder) {
    instrumentationService.logInfo(
      'Running "pub $pubCommand" in "${folder.path}".',
    );

    var stopwatch = Stopwatch()..start();
    var result = Process.runSync(
      sdk.dart,
      ['pub', pubCommand],
      stderrEncoding: utf8,
      stdoutEncoding: utf8,
      workingDirectory: folder.path,
      environment: {_pubEnvironmentKey: _getPubEnvironmentValue()},
    );
    stopwatch.stop();

    instrumentationService.logInfo(
      'Running "pub $pubCommand" took ${stopwatch.elapsed}.',
    );

    return result;
  }

  /// Returns a hex-encoded MD5 signature of the given file [path].
  String _uniqueDirectoryName(String path) {
    var bytes = md5.convert(path.codeUnits).bytes;
    return hex.encode(bytes);
  }

  /// Record the fact that the given [pluginIsolate] responded to a request with
  /// the given [method] in the given [time].
  static void recordResponseTime(
    PluginIsolate pluginIsolate,
    String method,
    int time,
  ) {
    pluginResponseTimes
        .putIfAbsent(pluginIsolate, () => <String, PercentileCalculator>{})
        .putIfAbsent(method, () => PercentileCalculator())
        .addValue(time);
  }

  /// Returns the environment value that should be used when running pub.
  ///
  /// Includes any existing environment value, if one exists.
  static String _getPubEnvironmentValue() {
    // DO NOT update this function without contacting kevmoo.
    // We have server-side tooling that assumes the values are consistent.
    var values = <String>[];

    var existing = Platform.environment[_pubEnvironmentKey];

    // If there is an existing value for this var, make sure to include it.
    if ((existing != null) && existing.isNotEmpty) {
      values.add(existing);
    }

    values.add('analysis_server.plugin_manager');

    return values.join(':');
  }
}

class _Package {
  final String name;
  final Folder root;

  _Package(this.name, this.root);
}
