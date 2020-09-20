// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform, Process;

import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/context_root.dart' as analyzer;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/workspace.dart';
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
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart' as watcher;
import 'package:yaml/yaml.dart';

/// Information about a plugin that is built-in.
class BuiltInPluginInfo extends PluginInfo {
  /// The entry point function that will be executed in the plugin's isolate.
  final EntryPoint entryPoint;

  @override
  final String pluginId;

  /// Initialize a newly created built-in plugin.
  BuiltInPluginInfo(
      this.entryPoint,
      this.pluginId,
      AbstractNotificationManager notificationManager,
      InstrumentationService instrumentationService)
      : super(notificationManager, instrumentationService);

  @override
  ServerCommunicationChannel _createChannel() {
    return ServerIsolateChannel.builtIn(
        entryPoint, pluginId, instrumentationService);
  }
}

/// Information about a plugin that was discovered.
class DiscoveredPluginInfo extends PluginInfo {
  /// The path to the root directory of the definition of the plugin on disk
  /// (the directory containing the 'pubspec.yaml' file and the 'bin'
  /// directory).
  final String path;

  /// The path to the 'plugin.dart' file that will be executed in an isolate.
  final String executionPath;

  /// The path to the '.packages' file used to control the resolution of
  /// 'package:' URIs.
  final String packagesPath;

  /// Initialize the newly created information about a plugin.
  DiscoveredPluginInfo(
      this.path,
      this.executionPath,
      this.packagesPath,
      AbstractNotificationManager notificationManager,
      InstrumentationService instrumentationService)
      : super(notificationManager, instrumentationService);

  @override
  bool get canBeStarted => executionPath != null;

  @override
  String get pluginId => path;

  @override
  ServerCommunicationChannel _createChannel() {
    return ServerIsolateChannel.discovered(
        Uri.file(executionPath, windows: Platform.isWindows),
        Uri.file(packagesPath, windows: Platform.isWindows),
        instrumentationService);
  }
}

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

/// Information about a single plugin.
abstract class PluginInfo {
  /// The object used to manage the receiving and sending of notifications.
  final AbstractNotificationManager notificationManager;

  /// The instrumentation service that is being used by the analysis server.
  final InstrumentationService instrumentationService;

  /// The context roots that are currently using the results produced by the
  /// plugin.
  Set<analyzer.ContextRoot> contextRoots = HashSet<analyzer.ContextRoot>();

  /// The current execution of the plugin, or `null` if the plugin is not
  /// currently being executed.
  PluginSession currentSession;

  CaughtException _exception;

  /// Initialize the newly created information about a plugin.
  PluginInfo(this.notificationManager, this.instrumentationService);

  /// Return `true` if this plugin can be started, or `false` if there is a
  /// reason why it cannot be started. For example, a plugin cannot be started
  /// if there was an error with a previous attempt to start running it or if
  /// the plugin is not correctly configured.
  bool get canBeStarted => true;

  /// Return the data known about this plugin.
  PluginData get data =>
      PluginData(pluginId, currentSession?.name, currentSession?.version);

  /// The exception that occurred that prevented the plugin from being started,
  /// or `null` if there was no exception (possibly because no attempt has yet
  /// been made to start the plugin).
  CaughtException get exception => _exception;

  /// Return the id of this plugin, used to identify the plugin to users.
  String get pluginId;

  /// Add the given [contextRoot] to the set of context roots being analyzed by
  /// this plugin.
  void addContextRoot(analyzer.ContextRoot contextRoot) {
    if (contextRoots.add(contextRoot)) {
      _updatePluginRoots();
    }
  }

  /// Add the given context [roots] to the set of context roots being analyzed
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

  /// Return `true` if at least one of the context roots being analyzed contains
  /// the file with the given [filePath].
  bool isAnalyzing(String filePath) {
    for (var contextRoot in contextRoots) {
      if (contextRoot.containsFile(filePath)) {
        return true;
      }
    }
    return false;
  }

  /// Remove the given [contextRoot] from the set of context roots being
  /// analyzed by this plugin.
  void removeContextRoot(analyzer.ContextRoot contextRoot) {
    if (contextRoots.remove(contextRoot)) {
      _updatePluginRoots();
    }
  }

  void reportException(CaughtException exception) {
    _exception = exception;
    instrumentationService.logPluginException(
        data, exception.exception, exception.stackTrace);
  }

  /// If the plugin is currently running, send a request based on the given
  /// [params] to the plugin. If the plugin is not running, the request will
  /// silently be dropped.
  void sendRequest(RequestParams params) {
    currentSession?.sendRequest(params);
  }

  /// Start a new isolate that is running the plugin. Return the state object
  /// used to interact with the plugin, or `null` if the plugin could not be
  /// run.
  Future<PluginSession> start(String byteStorePath, String sdkPath) async {
    if (currentSession != null) {
      throw StateError('Cannot start a plugin that is already running.');
    }
    currentSession = PluginSession(this);
    var isRunning = await currentSession.start(byteStorePath, sdkPath);
    if (!isRunning) {
      currentSession = null;
    }
    return currentSession;
  }

  /// Request that the plugin shutdown.
  Future<void> stop() {
    if (currentSession == null) {
      if (_exception != null) {
        // Plugin crashed, nothing to do.
        return Future<void>.value(null);
      }
      throw StateError('Cannot stop a plugin that is not running.');
    }
    var doneFuture = currentSession.stop();
    currentSession = null;
    return doneFuture;
  }

  /// Create and return the channel used to communicate with the server.
  ServerCommunicationChannel _createChannel();

  /// Update the context roots that the plugin should be analyzing.
  void _updatePluginRoots() {
    if (currentSession != null) {
      var params = AnalysisSetContextRootsParams(contextRoots
          .map((analyzer.ContextRoot contextRoot) => ContextRoot(
              contextRoot.root, contextRoot.exclude,
              optionsFile: contextRoot.optionsFilePath))
          .toList());
      currentSession.sendRequest(params);
    }
  }
}

/// An object used to manage the currently running plugins.
class PluginManager {
  /// A table, keyed by both a plugin and a request method, to a list of the
  /// times that it took the plugin to return a response to requests with the
  /// method.
  static Map<PluginInfo, Map<String, List<int>>> pluginResponseTimes =
      <PluginInfo, Map<String, List<int>>>{};

  /// The console environment key used by the pub tool.
  static const String _pubEnvironmentKey = 'PUB_ENVIRONMENT';

  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The absolute path of the directory containing the on-disk byte store, or
  /// `null` if there is no on-disk store.
  final String byteStorePath;

  /// The absolute path of the directory containing the SDK.
  final String sdkPath;

  /// The object used to manage the receiving and sending of notifications.
  final AbstractNotificationManager notificationManager;

  /// The instrumentation service that is being used by the analysis server.
  final InstrumentationService instrumentationService;

  /// A table mapping the paths of plugins to information about those plugins.
  final Map<String, PluginInfo> _pluginMap = <String, PluginInfo>{};

  /// The parameters for the last 'analysis.setPriorityFiles' request that was
  /// received from the client. Because plugins are lazily discovered, this
  /// needs to be retained so that it can be sent after a plugin has been
  /// started.
  AnalysisSetPriorityFilesParams _analysisSetPriorityFilesParams;

  /// The parameters for the last 'analysis.setSubscriptions' request that was
  /// received from the client. Because plugins are lazily discovered, this
  /// needs to be retained so that it can be sent after a plugin has been
  /// started.
  AnalysisSetSubscriptionsParams _analysisSetSubscriptionsParams;

  /// The current state of content overlays. Because plugins are lazily
  /// discovered, the state needs to be retained so that it can be sent after a
  /// plugin has been started.
  final Map<String, dynamic> _overlayState = <String, dynamic>{};

  final StreamController<void> _pluginsChanged = StreamController.broadcast();

  /// Initialize a newly created plugin manager. The notifications from the
  /// running plugins will be handled by the given [notificationManager].
  PluginManager(this.resourceProvider, this.byteStorePath, this.sdkPath,
      this.notificationManager, this.instrumentationService);

  /// Return a list of all of the plugins that are currently known.
  List<PluginInfo> get plugins => _pluginMap.values.toList();

  /// Stream emitting an event when known [plugins] change.
  Stream<void> get pluginsChanged => _pluginsChanged.stream;

  /// Add the plugin with the given [path] to the list of plugins that should be
  /// used when analyzing code for the given [contextRoot]. If the plugin had
  /// not yet been started, then it will be started by this method.
  Future<void> addPluginToContextRoot(
      analyzer.ContextRoot contextRoot, String path) async {
    var plugin = _pluginMap[path];
    var isNew = plugin == null;
    if (isNew) {
      List<String> pluginPaths;
      try {
        pluginPaths = pathsFor(path);
      } catch (exception, stackTrace) {
        plugin = DiscoveredPluginInfo(
            path, null, null, notificationManager, instrumentationService);
        plugin.reportException(CaughtException(exception, stackTrace));
        _pluginMap[path] = plugin;
        return;
      }
      plugin = DiscoveredPluginInfo(path, pluginPaths[0], pluginPaths[1],
          notificationManager, instrumentationService);
      _pluginMap[path] = plugin;
      if (pluginPaths[0] != null) {
        try {
          var session = await plugin.start(byteStorePath, sdkPath);
          session?.onDone?.then((_) {
            _pluginMap.remove(path);
            _notifyPluginsChanged();
          });
        } catch (exception, stackTrace) {
          // Record the exception (for debugging purposes) and record the fact
          // that we should not try to communicate with the plugin.
          plugin.reportException(CaughtException(exception, stackTrace));
          isNew = false;
        }
      }

      _notifyPluginsChanged();
    }
    plugin.addContextRoot(contextRoot);
    if (isNew) {
      if (_analysisSetSubscriptionsParams != null) {
        plugin.sendRequest(_analysisSetSubscriptionsParams);
      }
      if (_overlayState.isNotEmpty) {
        plugin.sendRequest(AnalysisUpdateContentParams(_overlayState));
      }
      if (_analysisSetPriorityFilesParams != null) {
        plugin.sendRequest(_analysisSetPriorityFilesParams);
      }
    }
  }

  /// Broadcast a request built from the given [params] to all of the plugins
  /// that are currently associated with the given [contextRoot]. Return a list
  /// containing futures that will complete when each of the plugins have sent a
  /// response.
  Map<PluginInfo, Future<Response>> broadcastRequest(RequestParams params,
      {analyzer.ContextRoot contextRoot}) {
    var plugins = pluginsForContextRoot(contextRoot);
    var responseMap = <PluginInfo, Future<Response>>{};
    for (var plugin in plugins) {
      final request = plugin.currentSession?.sendRequest(params);
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
      watcher.WatchEvent watchEvent) async {
    var filePath = watchEvent.path;

    /// Return `true` if the given glob [pattern] matches the file being
    /// watched.
    bool matches(String pattern) =>
        Glob(resourceProvider.pathContext.separator, pattern).matches(filePath);

    WatchEvent event;
    var responses = <Future<Response>>[];
    for (var plugin in _pluginMap.values) {
      var session = plugin.currentSession;
      if (session != null &&
          plugin.isAnalyzing(filePath) &&
          session.interestingFiles != null &&
          session.interestingFiles.any(matches)) {
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

  /// Return the execution path and .packages path associated with the plugin at
  /// the given [path]. Throw a [PluginException] if there is a problem that
  /// prevents the plugin from being executing.
  @visibleForTesting
  List<String> pathsFor(String pluginPath) {
    var pluginFolder = resourceProvider.getFolder(pluginPath);
    var pubspecFile = pluginFolder.getChildAssumingFile('pubspec.yaml');
    if (!pubspecFile.exists) {
      // If there's no pubspec file, then we don't need to copy the package
      // because we won't be running pub.
      return _computePaths(pluginFolder);
    }
    var workspace = BazelWorkspace.find(resourceProvider, pluginFolder.path) ??
        GnWorkspace.find(resourceProvider, pluginFolder.path);
    if (workspace != null) {
      // Similarly, we won't be running pub if we're in a workspace because
      // there is exactly one version of each package.
      return _computePaths(pluginFolder, workspace: workspace);
    }
    //
    // Copy the plugin directory to a unique subdirectory of the plugin
    // manager's state location. The subdirectory's name is selected such that
    // it will be invariant across sessions, reducing the number of times the
    // plugin will need to be copied and pub will need to be run.
    //
    var stateFolder = resourceProvider.getStateLocation('.plugin_manager');
    var stateName = _uniqueDirectoryName(pluginPath);
    var parentFolder = stateFolder.getChildAssumingFolder(stateName);
    if (parentFolder.exists) {
      var executionFolder =
          parentFolder.getChildAssumingFolder(pluginFolder.shortName);
      return _computePaths(executionFolder, pubCommand: 'upgrade');
    }
    var executionFolder = pluginFolder.copyTo(parentFolder);
    return _computePaths(executionFolder, pubCommand: 'get');
  }

  /// Return a list of all of the plugins that are currently associated with the
  /// given [contextRoot].
  @visibleForTesting
  List<PluginInfo> pluginsForContextRoot(analyzer.ContextRoot contextRoot) {
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

  /// Record a failure to run the plugin associated with the host package with
  /// the given [hostPackageName]. The failure is described by the [message],
  /// and is expected to have occurred before a path could be computed, and
  /// hence before [addPluginToContextRoot] could be invoked.
  void recordPluginFailure(String hostPackageName, String message) {
    try {
      throw PluginException(message);
    } catch (exception, stackTrace) {
      var pluginPath = path.join(hostPackageName, 'tools', 'analyzer_plugin');
      var plugin = DiscoveredPluginInfo(
          pluginPath, null, null, notificationManager, instrumentationService);
      plugin.reportException(CaughtException(exception, stackTrace));
      _pluginMap[pluginPath] = plugin;
    }
  }

  /// The given [contextRoot] is no longer being analyzed.
  void removedContextRoot(analyzer.ContextRoot contextRoot) {
    var plugins = _pluginMap.values.toList();
    for (var plugin in plugins) {
      plugin.removeContextRoot(contextRoot);
      if (plugin is DiscoveredPluginInfo && plugin.contextRoots.isEmpty) {
        _pluginMap.remove(plugin.path);
        _notifyPluginsChanged();
        try {
          plugin.stop();
        } catch (e, st) {
          AnalysisEngine.instance.instrumentationService
              .logException(SilentException('Issue stopping a plugin', e, st));
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
        var session = await plugin.start(byteStorePath, sdkPath);
        session?.onDone?.then((_) {
          _pluginMap.remove(path);
        });
        //
        // Re-initialize the plugin.
        //
        plugin.addContextRoots(contextRoots);
        if (_analysisSetSubscriptionsParams != null) {
          plugin.sendRequest(_analysisSetSubscriptionsParams);
        }
        if (_overlayState.isNotEmpty) {
          plugin.sendRequest(AnalysisUpdateContentParams(_overlayState));
        }
        if (_analysisSetPriorityFilesParams != null) {
          plugin.sendRequest(_analysisSetPriorityFilesParams);
        }
      }
    }
  }

  /// Send a request based on the given [params] to existing plugins to set the
  /// priority files to those specified by the [params]. As a side-effect,
  /// record the parameters so that they can be sent to any newly started
  /// plugins.
  void setAnalysisSetPriorityFilesParams(
      AnalysisSetPriorityFilesParams params) {
    for (var plugin in _pluginMap.values) {
      plugin.sendRequest(params);
    }
    _analysisSetPriorityFilesParams = params;
  }

  /// Send a request based on the given [params] to existing plugins to set the
  /// subscriptions to those specified by the [params]. As a side-effect, record
  /// the parameters so that they can be sent to any newly started plugins.
  void setAnalysisSetSubscriptionsParams(
      AnalysisSetSubscriptionsParams params) {
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
      Object overlay = files[file];
      if (overlay is RemoveContentOverlay) {
        _overlayState.remove(file);
      } else if (overlay is AddContentOverlay) {
        _overlayState[file] = overlay;
      } else if (overlay is ChangeContentOverlay) {
        AddContentOverlay previousOverlay = _overlayState[file];
        var newContent =
            SourceEdit.applySequence(previousOverlay.content, overlay.edits);
        _overlayState[file] = AddContentOverlay(newContent);
      } else {
        throw ArgumentError('Invalid class of overlay: ${overlay.runtimeType}');
      }
    }
  }

  /// Stop all of the plugins that are currently running.
  Future<List<void>> stopAll() {
    return Future.wait(_pluginMap.values.map((PluginInfo info) async {
      try {
        await info.stop();
      } catch (e, st) {
        AnalysisEngine.instance.instrumentationService.logException(e, st);
      }
    }));
  }

  /// Compute the paths to be returned by the enclosing method given that the
  /// plugin should exist in the given [pluginFolder].
  ///
  /// Runs pub if [pubCommand] is provided and not null.
  List<String> _computePaths(Folder pluginFolder,
      {String pubCommand, Workspace workspace}) {
    var pluginFile = pluginFolder
        .getChildAssumingFolder('bin')
        .getChildAssumingFile('plugin.dart');
    if (!pluginFile.exists) {
      throw PluginException('File "${pluginFile.path}" does not exist.');
    }
    String reason;
    var packagesFile = pluginFolder.getChildAssumingFile('.packages');
    if (pubCommand != null) {
      var vmPath = Platform.executable;
      var pubPath = path.join(path.dirname(vmPath), 'pub');
      if (Platform.isWindows) {
        // Process.run requires the `.bat` suffix on Windows
        pubPath = '$pubPath.bat';
      }
      var result = Process.runSync(pubPath, <String>[pubCommand],
          stderrEncoding: utf8,
          stdoutEncoding: utf8,
          workingDirectory: pluginFolder.path,
          environment: {_pubEnvironmentKey: _getPubEnvironmentValue()});
      if (result.exitCode != 0) {
        var buffer = StringBuffer();
        buffer.writeln('Failed to run pub $pubCommand');
        buffer.writeln('  pluginFolder = ${pluginFolder.path}');
        buffer.writeln('  exitCode = ${result.exitCode}');
        buffer.writeln('  stdout = ${result.stdout}');
        buffer.writeln('  stderr = ${result.stderr}');
        reason = buffer.toString();
        instrumentationService.logError(reason);
      }
      if (!packagesFile.exists) {
        reason ??= 'File "${packagesFile.path}" does not exist.';
        packagesFile = null;
      }
    } else if (!packagesFile.exists) {
      if (workspace != null) {
        packagesFile =
            _createPackagesFile(pluginFolder, workspace.packageUriResolver);
        if (packagesFile == null) {
          reason = 'Could not create .packages file in workspace $workspace.';
        }
      } else {
        reason = 'Could not create "${packagesFile.path}".';
        packagesFile = null;
      }
    }
    if (packagesFile == null) {
      throw PluginException(reason);
    }
    return <String>[pluginFile.path, packagesFile.path];
  }

  WatchEventType _convertChangeType(watcher.ChangeType type) {
    switch (type) {
      case watcher.ChangeType.ADD:
        return WatchEventType.ADD;
      case watcher.ChangeType.MODIFY:
        return WatchEventType.MODIFY;
      case watcher.ChangeType.REMOVE:
        return WatchEventType.REMOVE;
      default:
        throw StateError('Unknown change type: $type');
    }
  }

  WatchEvent _convertWatchEvent(watcher.WatchEvent watchEvent) {
    return WatchEvent(_convertChangeType(watchEvent.type), watchEvent.path);
  }

  /// Return a temporary `.packages` file that is appropriate for the plugin in
  /// the given [pluginFolder]. The [packageUriResolver] is used to determine
  /// the location of the packages that need to be included in the packages
  /// file.
  File _createPackagesFile(
      Folder pluginFolder, UriResolver packageUriResolver) {
    var pluginPath = pluginFolder.path;
    var stateFolder = resourceProvider.getStateLocation('.plugin_manager');
    var stateName = _uniqueDirectoryName(pluginPath) + '.packages';
    var packagesFile = stateFolder.getChildAssumingFile(stateName);
    if (!packagesFile.exists) {
      var pluginPubspec = pluginFolder.getChildAssumingFile('pubspec.yaml');
      if (!pluginPubspec.exists) {
        return null;
      }

      try {
        var visitedPackages = <String, String>{};
        var context = resourceProvider.pathContext;
        visitedPackages[context.basename(pluginPath)] =
            context.join(pluginFolder.path, 'lib');
        var pubspecFiles = <File>[];
        pubspecFiles.add(pluginPubspec);
        while (pubspecFiles.isNotEmpty) {
          var pubspecFile = pubspecFiles.removeLast();
          for (var packageName in _readDependecies(pubspecFile)) {
            if (!visitedPackages.containsKey(packageName)) {
              var uri = Uri.parse('package:$packageName/$packageName.dart');
              var packageSource = packageUriResolver.resolveAbsolute(uri);
              var libDirPath = context.dirname(packageSource.fullName);
              visitedPackages[packageName] = libDirPath;
              var pubspecPath =
                  context.join(context.dirname(libDirPath), 'pubspec.yaml');
              pubspecFiles.add(resourceProvider.getFile(pubspecPath));
            }
          }
        }

        var buffer = StringBuffer();
        visitedPackages.forEach((String name, String path) {
          buffer.write(name);
          buffer.write(':');
          buffer.writeln(Uri.file(path));
        });
        packagesFile.writeAsStringSync(buffer.toString());
      } catch (exception) {
        // If we are not able to produce a .packages file, return null so that
        // callers will not try to load the plugin.
        return null;
      }
    }
    return packagesFile;
  }

  void _notifyPluginsChanged() => _pluginsChanged.add(null);

  /// Return the names of packages that are listed as dependencies in the given
  /// [pubspecFile].
  Iterable<String> _readDependecies(File pubspecFile) {
    var document = loadYamlDocument(pubspecFile.readAsStringSync(),
        sourceUrl: pubspecFile.toUri());
    var contents = document.contents;
    if (contents is YamlMap) {
      YamlNode dependencies = contents['dependencies'];
      if (dependencies is YamlMap) {
        return dependencies.keys.cast<String>();
      }
    }
    return const <String>[];
  }

  /// Return a hex-encoded MD5 signature of the given file [path].
  String _uniqueDirectoryName(String path) {
    var bytes = md5.convert(path.codeUnits).bytes;
    return hex.encode(bytes);
  }

  /// Record the fact that the given [plugin] responded to a request with the
  /// given [method] in the given [time].
  static void recordResponseTime(PluginInfo plugin, String method, int time) {
    pluginResponseTimes
        .putIfAbsent(plugin, () => <String, List<int>>{})
        .putIfAbsent(method, () => <int>[])
        .add(time);
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

/// Information about the execution a single plugin.
@visibleForTesting
class PluginSession {
  /// The maximum number of milliseconds that server should wait for a response
  /// from a plugin before deciding that the plugin is hung.
  static const Duration MAXIMUM_RESPONSE_TIME = Duration(minutes: 2);

  /// The length of time to wait after sending a 'plugin.shutdown' request
  /// before a failure to terminate will cause the isolate to be killed.
  static const Duration WAIT_FOR_SHUTDOWN_DURATION = Duration(seconds: 10);

  /// The information about the plugin being executed.
  final PluginInfo info;

  /// The completer used to signal when the plugin has stopped.
  Completer<void> pluginStoppedCompleter = Completer<void>();

  /// The channel used to communicate with the plugin.
  ServerCommunicationChannel channel;

  /// The index of the next request to be sent to the plugin.
  int requestId = 0;

  /// A table mapping the id's of requests to the functions used to handle the
  /// response to those requests.
  Map<String, _PendingRequest> pendingRequests = <String, _PendingRequest>{};

  /// A boolean indicating whether the plugin is compatible with the version of
  /// the plugin API being used by this server.
  bool isCompatible = true;

  /// The contact information to include when reporting problems related to the
  /// plugin.
  String contactInfo;

  /// The glob patterns of files that the plugin is interested in knowing about.
  List<String> interestingFiles;

  /// The name to be used when reporting problems related to the plugin.
  String name;

  /// The version number to be used when reporting problems related to the
  /// plugin.
  String version;

  /// Initialize the newly created information about the execution of a plugin.
  PluginSession(this.info);

  /// Return the next request id, encoded as a string and increment the id so
  /// that a different result will be returned on each invocation.
  String get nextRequestId => (requestId++).toString();

  /// Return a future that will complete when the plugin has stopped.
  Future<void> get onDone => pluginStoppedCompleter.future;

  /// Handle the given [notification].
  void handleNotification(Notification notification) {
    if (notification.event == PLUGIN_NOTIFICATION_ERROR) {
      var params = PluginErrorParams.fromNotification(notification);
      if (params.isFatal) {
        info.stop();
        stop();
      }
    }
    info.notificationManager
        .handlePluginNotification(info.pluginId, notification);
  }

  /// Handle the fact that the plugin has stopped.
  void handleOnDone() {
    if (channel != null) {
      channel.close();
      channel = null;
    }
    pluginStoppedCompleter.complete(null);
  }

  /// Handle the fact that an unhandled error has occurred in the plugin.
  void handleOnError(dynamic error) {
    var errorPair = (error as List).cast<String>();
    var stackTrace = StackTrace.fromString(errorPair[1]);
    info.reportException(
        CaughtException(PluginException(errorPair[0]), stackTrace));
  }

  /// Handle a [response] from the plugin by completing the future that was
  /// created when the request was sent.
  void handleResponse(Response response) {
    var requestData = pendingRequests.remove(response.id);
    var responseTime = DateTime.now().millisecondsSinceEpoch;
    var duration = responseTime - requestData.requestTime;
    PluginManager.recordResponseTime(info, requestData.method, duration);
    var completer = requestData.completer;
    if (completer != null) {
      completer.complete(response);
    }
  }

  /// Return `true` if there are any requests that have not been responded to
  /// within the maximum allowed amount of time.
  bool isNonResponsive() {
    // TODO(brianwilkerson) Figure out when to invoke this method in order to
    // identify non-responsive plugins and kill them.
    var cutOffTime = DateTime.now().millisecondsSinceEpoch -
        MAXIMUM_RESPONSE_TIME.inMilliseconds;
    for (var requestData in pendingRequests.values) {
      if (requestData.requestTime < cutOffTime) {
        return true;
      }
    }
    return false;
  }

  /// Send a request, based on the given [parameters]. Return a future that will
  /// complete when a response is received.
  Future<Response> sendRequest(RequestParams parameters) {
    if (channel == null) {
      throw StateError('Cannot send a request to a plugin that has stopped.');
    }
    var id = nextRequestId;
    var completer = Completer<Response>();
    var requestTime = DateTime.now().millisecondsSinceEpoch;
    var request = parameters.toRequest(id);
    pendingRequests[id] =
        _PendingRequest(request.method, requestTime, completer);
    channel.sendRequest(request);
    return completer.future;
  }

  /// Start a new isolate that is running this plugin. The plugin will be sent
  /// the given [byteStorePath]. Return `true` if the plugin is compatible and
  /// running.
  Future<bool> start(String byteStorePath, String sdkPath) async {
    if (channel != null) {
      throw StateError('Cannot start a plugin that is already running.');
    }
    if (byteStorePath == null || byteStorePath.isEmpty) {
      throw StateError('Missing byte store path');
    }
    if (!isCompatible) {
      info.reportException(
          CaughtException(PluginException('Plugin is not compatible.'), null));
      return false;
    }
    if (!info.canBeStarted) {
      info.reportException(
          CaughtException(PluginException('Plugin cannot be started.'), null));
      return false;
    }
    channel = info._createChannel();
    // TODO(brianwilkerson) Determine if await is necessary, if so, change the
    // return type of `channel.listen` to `Future<void>`.
    await (channel.listen(handleResponse, handleNotification,
        onDone: handleOnDone, onError: handleOnError) as dynamic);
    if (channel == null) {
      // If there is an error when starting the isolate, the channel will invoke
      // handleOnDone, which will cause `channel` to be set to `null`.
      info.reportException(CaughtException(
          PluginException('Unrecorded error while starting the plugin.'),
          null));
      return false;
    }
    var response = await sendRequest(PluginVersionCheckParams(
        byteStorePath ?? '', sdkPath, '1.0.0-alpha.0'));
    var result = PluginVersionCheckResult.fromResponse(response);
    isCompatible = result.isCompatible;
    contactInfo = result.contactInfo;
    interestingFiles = result.interestingFiles;
    name = result.name;
    version = result.version;
    if (!isCompatible) {
      sendRequest(PluginShutdownParams());
      info.reportException(
          CaughtException(PluginException('Plugin is not compatible.'), null));
      return false;
    }
    return true;
  }

  /// Request that the plugin shutdown.
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
