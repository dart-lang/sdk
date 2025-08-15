// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server_plugin/src/plugin_server.dart';
/// @docImport 'package:analysis_server/src/plugin/plugin_watcher.dart';
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform, Process, ProcessResult;

import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
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
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/channel/isolate_channel.dart';
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

/// Information about a single plugin.
class PluginInfo {
  /// The path to the root directory of the definition of the plugin on disk
  /// (the directory containing the 'pubspec.yaml' file and the 'bin'
  /// directory).
  final String _path;

  /// The path to the 'plugin.dart' file that will be executed in an isolate.
  final String executionPath;

  /// The path to the '.packages' file used to control the resolution of
  /// 'package:' URIs.
  final String packagesPath;

  /// The object used to manage the receiving and sending of notifications.
  final AbstractNotificationManager _notificationManager;

  /// The instrumentation service that is being used by the analysis server.
  final InstrumentationService _instrumentationService;

  /// The context roots that are currently using the results produced by the
  /// plugin.
  Set<analyzer.ContextRoot> contextRoots = HashSet<analyzer.ContextRoot>();

  /// The current execution of the plugin, or `null` if the plugin is not
  /// currently being executed.
  PluginSession? currentSession;

  CaughtException? _exception;

  PluginInfo(
    this._path,
    this.executionPath,
    this.packagesPath,
    this._notificationManager,
    this._instrumentationService,
  );

  /// The data known about this plugin, for instrumentation and exception
  /// purposes.
  PluginData get data =>
      PluginData(pluginId, currentSession?._name, currentSession?._version);

  /// The exception that occurred that prevented the plugin from being started,
  /// or `null` if there was no exception (possibly because no attempt has yet
  /// been made to start the plugin).
  CaughtException? get exception => _exception;

  /// The ID of this plugin, used to identify the plugin to users.
  String get pluginId => _path;

  /// Whether this plugin can be started, or `false` if there is a reason that
  /// it cannot be started.
  ///
  /// For example, a plugin cannot be started if there was an error with a
  /// previous attempt to start running it or if the plugin is not correctly
  /// configured.
  bool get _canBeStarted => executionPath.isNotEmpty;

  /// Adds the given [contextRoot] to the set of context roots being analyzed by
  /// this plugin.
  void addContextRoot(analyzer.ContextRoot contextRoot) {
    if (contextRoots.add(contextRoot)) {
      _updatePluginRoots();
    }
  }

  /// Adds the given context [roots] to the set of context roots being analyzed
  /// by this plugin.
  void addContextRoots(Iterable<analyzer.ContextRoot> roots) {
    var changed = false;
    for (var contextRoot in roots) {
      if (contextRoots.add(contextRoot)) {
        changed = true;
      }
    }
    if (changed) {
      _updatePluginRoots();
    }
  }

  /// Whether at least one of the context roots being analyzed contains the file
  /// with the given [filePath].
  bool isAnalyzing(String filePath) {
    for (var contextRoot in contextRoots) {
      if (contextRoot.isAnalyzed(filePath)) {
        return true;
      }
    }
    return false;
  }

  /// Removes the given [contextRoot] from the set of context roots being
  /// analyzed by this plugin.
  void removeContextRoot(analyzer.ContextRoot contextRoot) {
    if (contextRoots.remove(contextRoot)) {
      _updatePluginRoots();
    }
  }

  void reportException(CaughtException exception) {
    // If a previous exception has been reported, do not replace it here; the
    // first should have more "root cause" information.
    _exception ??= exception;
    _instrumentationService.logPluginException(
      data,
      exception.exception,
      exception.stackTrace,
    );
    var message =
        'An error occurred while executing an analyzer plugin: '
        // Sometimes the message is the primary information; sometimes the
        // exception is.
        '${exception.message ?? exception.exception}\n'
        '${exception.stackTrace}';
    _notificationManager.handlePluginError(message);
  }

  /// If the plugin is currently running, sends a request based on the given
  /// [params] to the plugin.
  ///
  /// If the plugin is not running, the request will silently be dropped.
  void sendRequest(RequestParams params) {
    currentSession?.sendRequest(params);
  }

  /// Starts a new isolate that is running the plugin.
  ///
  /// Returns the [PluginSession] used to interact with the plugin, or `null` if
  /// the plugin could not be run.
  Future<PluginSession?> start(String? byteStorePath, String sdkPath) async {
    if (currentSession != null) {
      throw StateError('Cannot start a plugin that is already running.');
    }
    currentSession = PluginSession(this);
    var isRunning = await currentSession!.start(byteStorePath, sdkPath);
    if (!isRunning) {
      currentSession = null;
    }
    return currentSession;
  }

  /// Requests that the plugin shut down.
  Future<void> stop() {
    if (currentSession == null) {
      if (_exception != null) {
        // Plugin crashed, nothing to do.
        return Future<void>.value();
      }
      throw StateError('Cannot stop a plugin that is not running.');
    }
    var doneFuture = currentSession!.stop();
    currentSession = null;
    return doneFuture;
  }

  /// Creates and returns the channel used to communicate with the server.
  ServerCommunicationChannel _createChannel() {
    return ServerIsolateChannel.discovered(
      Uri.file(executionPath, windows: Platform.isWindows),
      Uri.file(packagesPath, windows: Platform.isWindows),
      _instrumentationService,
    );
  }

  /// Updates the context roots that the plugin should be analyzing.
  void _updatePluginRoots() {
    var currentSession = this.currentSession;
    if (currentSession != null) {
      var params = AnalysisSetContextRootsParams(
        contextRoots
            .map(
              (analyzer.ContextRoot contextRoot) => ContextRoot(
                contextRoot.root.path,
                contextRoot.excludedPaths.toList(),
                optionsFile: contextRoot.optionsFile?.path,
              ),
            )
            .toList(),
      );
      currentSession.sendRequest(params);
    }
  }
}

/// An object used to manage the currently running plugins.
class PluginManager {
  /// A table, keyed by both a plugin and a request method, to a list of the
  /// times that it took the plugin to return a response to requests with the
  /// method.
  static Map<PluginInfo, Map<String, PercentileCalculator>>
  pluginResponseTimes = <PluginInfo, Map<String, PercentileCalculator>>{};

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
  final Map<String, PluginInfo> _pluginMap = <String, PluginInfo>{};

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

  /// Return a list of all of the plugins that are currently known.
  List<PluginInfo> get plugins => _pluginMap.values.toList();

  /// Stream emitting an event when known [plugins] change.
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
    var plugin = _pluginMap[path];
    var isNew = false;
    if (plugin == null) {
      isNew = true;
      PluginFiles pluginFiles;
      try {
        pluginFiles = filesFor(path, isLegacyPlugin: isLegacyPlugin);
      } catch (exception, stackTrace) {
        plugin = PluginInfo(
          path,
          '',
          '',
          _notificationManager,
          instrumentationService,
        );
        plugin.reportException(CaughtException(exception, stackTrace));
        _pluginMap[path] = plugin;
        return;
      }
      plugin = PluginInfo(
        path,
        pluginFiles.execution.path,
        pluginFiles.packageConfig.path,
        _notificationManager,
        instrumentationService,
      );
      _pluginMap[path] = plugin;
      try {
        instrumentationService.logInfo('Starting plugin "$plugin"');
        var session = await plugin.start(_byteStorePath, _sdkPath);
        unawaited(
          session?._onDone.then((_) {
            if (_pluginMap[path] == plugin) {
              _pluginMap.remove(path);
              _notifyPluginsChanged();
            }
          }),
        );
      } catch (exception, stackTrace) {
        // Record the exception (for debugging purposes) and record the fact
        // that we should not try to communicate with the plugin.
        plugin.reportException(CaughtException(exception, stackTrace));
        isNew = false;
      }

      _notifyPluginsChanged();
    }
    plugin.addContextRoot(contextRoot);
    if (isNew) {
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

  /// Broadcast a request built from the given [params] to all of the plugins
  /// that are currently associated with the given [contextRoot]. Return a list
  /// containing futures that will complete when each of the plugins have sent a
  /// response.
  Map<PluginInfo, Future<Response>> broadcastRequest(
    RequestParams params, {
    analyzer.ContextRoot? contextRoot,
  }) {
    var plugins = pluginsForContextRoot(contextRoot);
    var responseMap = <PluginInfo, Future<Response>>{};
    for (var plugin in plugins) {
      var request = plugin.currentSession?.sendRequest(params);
      // Only add an entry to the map if we have sent a request.
      if (request != null) {
        responseMap[plugin] = request;
      }
    }
    return responseMap;
  }

  /// Broadcast the given [watchEvent] to all of the plugins that are analyzing
  /// in contexts containing the file associated with the event. Return a list
  /// containing futures that will complete when each of the plugins have sent a
  /// response.
  Future<List<Future<Response>>> broadcastWatchEvent(
    watcher.WatchEvent watchEvent,
  ) async {
    var filePath = watchEvent.path;

    /// Return `true` if the given glob [pattern] matches the file being
    /// watched.
    bool matches(String pattern) => Glob(
      _resourceProvider.pathContext.separator,
      pattern,
    ).matches(filePath);

    WatchEvent? event;
    var responses = <Future<Response>>[];
    for (var plugin in _pluginMap.values) {
      var session = plugin.currentSession;
      var interestingFiles = session?.interestingFiles;
      if (session != null &&
          plugin.isAnalyzing(filePath) &&
          interestingFiles != null &&
          interestingFiles.any(matches)) {
        // The list of interesting file globs is `null` if the plugin has not
        // yet responded to the plugin.versionCheck request. If that happens
        // then the plugin hasn't had a chance to analyze anything yet, and
        // hence it does not needed to get watch events.
        event ??= _convertWatchEvent(watchEvent);
        var params = AnalysisHandleWatchEventsParams([event]);
        responses.add(session.sendRequest(params));
      }
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

  /// Return a list of all of the plugins that are currently associated with the
  /// given [contextRoot].
  @visibleForTesting
  List<PluginInfo> pluginsForContextRoot(analyzer.ContextRoot? contextRoot) {
    if (contextRoot == null) {
      return _pluginMap.values.toList();
    }
    var plugins = <PluginInfo>[];
    for (var plugin in _pluginMap.values) {
      if (plugin.contextRoots.contains(contextRoot)) {
        plugins.add(plugin);
      }
    }
    return plugins;
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
        _pluginMap.remove(plugin._path);
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
          session?._onDone.then((_) {
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

  /// Stop all of the plugins that are currently running.
  Future<List<void>> stopAll() {
    return Future.wait(
      _pluginMap.values.map((PluginInfo info) async {
        try {
          await info.stop();
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
        exceptionReason = buffer.toString();
        instrumentationService.logError(exceptionReason);
        _notificationManager.handlePluginError(exceptionReason);
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
                var packageRoot =
                    _resourceProvider
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

  /// Record the fact that the given [plugin] responded to a request with the
  /// given [method] in the given [time].
  static void recordResponseTime(PluginInfo plugin, String method, int time) {
    pluginResponseTimes
        .putIfAbsent(plugin, () => <String, PercentileCalculator>{})
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

/// Information about the execution of a single plugin.
@visibleForTesting
class PluginSession {
  /// The maximum number of milliseconds that server should wait for a response
  /// from a plugin before deciding that the plugin is hung.
  static const Duration MAXIMUM_RESPONSE_TIME = Duration(minutes: 2);

  /// The length of time to wait after sending a 'plugin.shutdown' request
  /// before a failure to terminate will cause the isolate to be killed.
  static const Duration WAIT_FOR_SHUTDOWN_DURATION = Duration(seconds: 10);

  /// The information about the plugin being executed.
  final PluginInfo _info;

  /// The completer used to signal when the plugin has stopped.
  Completer<void> pluginStoppedCompleter = Completer<void>();

  /// The channel used to communicate with the plugin.
  ServerCommunicationChannel? channel;

  /// The index of the next request to be sent to the plugin.
  int requestId = 0;

  /// A table mapping the id's of requests to the functions used to handle the
  /// response to those requests.
  @visibleForTesting
  // ignore: library_private_types_in_public_api
  Map<String, _PendingRequest> pendingRequests = <String, _PendingRequest>{};

  /// A boolean indicating whether the plugin is compatible with the version of
  /// the plugin API being used by this server.
  bool isCompatible = true;

  /// The glob patterns of files that the plugin is interested in knowing about.
  List<String>? interestingFiles;

  /// The name to be used when reporting problems related to the plugin.
  String? _name;

  /// The version number to be used when reporting problems related to the
  /// plugin.
  String? _version;

  PluginSession(this._info);

  /// The next request ID, encoded as a string.
  ///
  /// This increments the ID so that a different result will be returned on each
  /// invocation.
  String get nextRequestId => (requestId++).toString();

  /// A future that will complete when the plugin has stopped.
  Future<void> get _onDone => pluginStoppedCompleter.future;

  /// Handles the given [notification] from [PluginServer].
  void handleNotification(Notification notification) {
    if (notification.event == PLUGIN_NOTIFICATION_ERROR) {
      var params = PluginErrorParams.fromNotification(notification);
      if (params.isFatal) {
        _info.stop();
        stop();
      }
    }
    _info._notificationManager.handlePluginNotification(
      _info.pluginId,
      notification,
    );
  }

  /// Handles the fact that the plugin has stopped.
  void handleOnDone() {
    if (channel != null) {
      channel!.close();
      channel = null;
    }
    pluginStoppedCompleter.complete(null);
  }

  /// Handles the fact that an unhandled error has occurred in the plugin.
  void handleOnError(Object? error) {
    if (error case [String message, String stackTraceString]) {
      var stackTrace = StackTrace.fromString(stackTraceString);
      var exception = PluginException(message);
      _info.reportException(
        CaughtException.withMessage(message, exception, stackTrace),
      );
    } else {
      throw ArgumentError.value(
        error,
        'error',
        'expected to be a two-element List of Strings.',
      );
    }
  }

  /// Handles a [response] from the plugin by completing the future that was
  /// created when the request was sent.
  void handleResponse(Response response) {
    var requestData = pendingRequests.remove(response.id);
    if (requestData != null) {
      var responseTime = DateTime.now().millisecondsSinceEpoch;
      var duration = responseTime - requestData.requestTime;
      PluginManager.recordResponseTime(_info, requestData.method, duration);
      var completer = requestData.completer;
      completer.complete(response);
    }
  }

  /// Whether there are any requests that have not been responded to within the
  /// maximum allowed amount of time.
  bool isNonResponsive() {
    // TODO(brianwilkerson): Figure out when to invoke this method in order to
    // identify non-responsive plugins and kill them.
    var cutOffTime =
        DateTime.now().millisecondsSinceEpoch -
        MAXIMUM_RESPONSE_TIME.inMilliseconds;
    for (var requestData in pendingRequests.values) {
      if (requestData.requestTime < cutOffTime) {
        return true;
      }
    }
    return false;
  }

  /// Sends a request, based on the given [parameters].
  ///
  /// Returns a future that will complete when a response is received.
  Future<Response> sendRequest(RequestParams parameters) {
    var channel = this.channel;
    if (channel == null) {
      throw StateError('Cannot send a request to a plugin that has stopped.');
    }
    var id = nextRequestId;
    var completer = Completer<Response>();
    var requestTime = DateTime.now().millisecondsSinceEpoch;
    var request = parameters.toRequest(id);
    pendingRequests[id] = _PendingRequest(
      request.method,
      requestTime,
      completer,
    );
    channel.sendRequest(request);
    completer.future.then((response) {
      // If a RequestError is returned in the response, report this as an
      // exception.
      if (response.error case var error?) {
        if (error.code == RequestErrorCode.UNKNOWN_REQUEST) {
          // The plugin doesn't support this request. It may just be using an
          // older version of the `analysis_server_plugin` package.
          _info._instrumentationService.logInfo(
            "Plugin cannot handle request '${request.method}' with parameters: "
            '$parameters.',
          );
          return;
        }
        var stackTrace = StackTrace.fromString(error.stackTrace!);
        var exception = PluginException(error.message);
        _info.reportException(
          CaughtException.withMessage(error.message, exception, stackTrace),
        );
      }
    });
    return completer.future;
  }

  /// Starts a new isolate that is running this plugin.
  ///
  /// The plugin will be sent the given [byteStorePath]. Returns whether the
  /// plugin is compatible and running.
  Future<bool> start(String? byteStorePath, String sdkPath) async {
    if (channel != null) {
      throw StateError('Cannot start a plugin that is already running.');
    }
    if (byteStorePath == null || byteStorePath.isEmpty) {
      throw StateError('Missing byte store path');
    }
    if (!isCompatible) {
      _info.reportException(
        CaughtException(
          PluginException('Plugin is not compatible.'),
          StackTrace.current,
        ),
      );
      return false;
    }
    if (!_info._canBeStarted) {
      _info.reportException(
        CaughtException(
          PluginException('Plugin cannot be started.'),
          StackTrace.current,
        ),
      );
      return false;
    }
    channel = _info._createChannel();
    // TODO(brianwilkerson): Determine if await is necessary, if so, change the
    // return type of `channel.listen` to `Future<void>`.
    await (channel!.listen(
          handleResponse,
          handleNotification,
          onDone: handleOnDone,
          onError: handleOnError,
        )
        as dynamic);
    if (channel == null) {
      // If there is an error when starting the isolate, the channel will invoke
      // `handleOnDone`, which will cause `channel` to be set to `null`.
      _info.reportException(
        CaughtException(
          PluginException('Unrecorded error while starting the plugin.'),
          StackTrace.current,
        ),
      );
      return false;
    }
    var response = await sendRequest(
      PluginVersionCheckParams(byteStorePath, sdkPath, '1.0.0-alpha.0'),
    );
    var result = PluginVersionCheckResult.fromResponse(response);
    isCompatible = result.isCompatible;
    interestingFiles = result.interestingFiles;
    _name = result.name;
    _version = result.version;
    if (!isCompatible) {
      unawaited(sendRequest(PluginShutdownParams()));
      _info.reportException(
        CaughtException(
          PluginException('Plugin is not compatible.'),
          StackTrace.current,
        ),
      );
      return false;
    }
    return true;
  }

  /// Requests that the plugin shutdown.
  Future<void> stop() {
    if (channel == null) {
      throw StateError('Cannot stop a plugin that is not running.');
    }
    sendRequest(PluginShutdownParams());
    Future.delayed(WAIT_FOR_SHUTDOWN_DURATION, () {
      if (channel != null) {
        channel?.kill();
        channel = null;
      }
    });
    return pluginStoppedCompleter.future;
  }
}

class _Package {
  final String name;
  final Folder root;

  _Package(this.name, this.root);
}

/// Information about a request that has been sent but for which a response has
/// not yet been received.
class _PendingRequest {
  /// The method of the request.
  final String method;

  /// The time at which the request was sent to the plugin.
  final int requestTime;

  /// The completer that will be used to complete the future when the response
  /// is received from the plugin.
  final Completer<Response> completer;

  /// Initialize a pending request.
  _PendingRequest(this.method, this.requestTime, this.completer);
}
