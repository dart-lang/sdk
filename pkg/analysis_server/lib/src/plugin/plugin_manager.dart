// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analyzer/context/context_root.dart' as analyzer;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/bazel.dart';
import 'package:analyzer/src/generated/gn.dart';
import 'package:analyzer/src/util/glob.dart';
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

/**
 * Information about a plugin that is built-in.
 */
class BuiltInPluginInfo extends PluginInfo {
  /**
   * The entry point function that will be executed in the plugin's isolate.
   */
  final EntryPoint entryPoint;

  @override
  final String pluginId;

  /**
   * Initialize a newly created built-in plugin.
   */
  BuiltInPluginInfo(
      this.entryPoint,
      this.pluginId,
      NotificationManager notificationManager,
      InstrumentationService instrumentationService)
      : super(notificationManager, instrumentationService);

  @override
  ServerCommunicationChannel _createChannel() {
    return new ServerIsolateChannel.builtIn(
        entryPoint, pluginId, instrumentationService);
  }
}

/**
 * Information about a plugin that was discovered.
 */
class DiscoveredPluginInfo extends PluginInfo {
  /**
   * The path to the root directory of the definition of the plugin on disk (the
   * directory containing the 'pubspec.yaml' file and the 'bin' directory).
   */
  final String path;

  /**
   * The path to the 'plugin.dart' file that will be executed in an isolate.
   */
  final String executionPath;

  /**
   * The path to the '.packages' file used to control the resolution of
   * 'package:' URIs.
   */
  final String packagesPath;

  /**
   * Initialize the newly created information about a plugin.
   */
  DiscoveredPluginInfo(
      this.path,
      this.executionPath,
      this.packagesPath,
      NotificationManager notificationManager,
      InstrumentationService instrumentationService)
      : super(notificationManager, instrumentationService);

  @override
  String get pluginId => path;

  @override
  ServerCommunicationChannel _createChannel() {
    return new ServerIsolateChannel.discovered(
        new Uri.file(executionPath, windows: Platform.isWindows),
        new Uri.file(packagesPath, windows: Platform.isWindows),
        instrumentationService);
  }
}

/**
 * Information about a single plugin.
 */
abstract class PluginInfo {
  /**
   * The object used to manage the receiving and sending of notifications.
   */
  final NotificationManager notificationManager;

  /**
   * The instrumentation service that is being used by the analysis server.
   */
  final InstrumentationService instrumentationService;

  /**
   * The context roots that are currently using the results produced by the
   * plugin.
   */
  Set<analyzer.ContextRoot> contextRoots = new HashSet<analyzer.ContextRoot>();

  /**
   * The current execution of the plugin, or `null` if the plugin is not
   * currently being executed.
   */
  PluginSession currentSession;

  /**
   * Initialize the newly created information about a plugin.
   */
  PluginInfo(this.notificationManager, this.instrumentationService);

  /**
   * Return the data known about this plugin.
   */
  PluginData get data =>
      new PluginData(pluginId, currentSession?.name, currentSession?.version);

  /**
   * Return the id of this plugin, used to identify the plugin to users.
   */
  String get pluginId;

  /**
   * Add the given [contextRoot] to the set of context roots being analyzed by
   * this plugin.
   */
  void addContextRoot(analyzer.ContextRoot contextRoot) {
    if (contextRoots.add(contextRoot)) {
      _updatePluginRoots();
    }
  }

  /**
   * Return `true` if at least one of the context roots being analyzed contains
   * the file with the given [filePath].
   */
  bool isAnalyzing(String filePath) {
    for (var contextRoot in contextRoots) {
      if (contextRoot.containsFile(filePath)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Remove the given [contextRoot] from the set of context roots being analyzed
   * by this plugin.
   */
  void removeContextRoot(analyzer.ContextRoot contextRoot) {
    if (contextRoots.remove(contextRoot)) {
      _updatePluginRoots();
    }
  }

  /**
   * If the plugin is currently running, send a request based on the given
   * [params] to the plugin. If the plugin is not running, the request will
   * silently be dropped.
   */
  void sendRequest(RequestParams params) {
    currentSession?.sendRequest(params);
  }

  /**
   * Start a new isolate that is running the plugin. Return the state object
   * used to interact with the plugin, or `null` if the plugin could not be run.
   */
  Future<PluginSession> start(String byteStorePath, String sdkPath) async {
    if (currentSession != null) {
      throw new StateError('Cannot start a plugin that is already running.');
    }
    currentSession = new PluginSession(this);
    bool isRunning = await currentSession.start(byteStorePath, sdkPath);
    if (!isRunning) {
      currentSession = null;
    }
    return currentSession;
  }

  /**
   * Request that the plugin shutdown.
   */
  Future<Null> stop() {
    if (currentSession == null) {
      throw new StateError('Cannot stop a plugin that is not running.');
    }
    Future<Null> doneFuture = currentSession.stop();
    currentSession = null;
    return doneFuture;
  }

  /**
   * Create the channel used to communicate with the server.
   */
  ServerCommunicationChannel _createChannel();

  /**
   * Update the context roots that the plugin should be analyzing.
   */
  void _updatePluginRoots() {
    if (currentSession != null) {
      AnalysisSetContextRootsParams params = new AnalysisSetContextRootsParams(
          contextRoots
              .map((analyzer.ContextRoot contextRoot) => new ContextRoot(
                  contextRoot.root, contextRoot.exclude,
                  optionsFile: contextRoot.optionsFilePath))
              .toList());
      currentSession.sendRequest(params);
    }
  }
}

/**
 * An object used to manage the currently running plugins.
 */
class PluginManager {
  /**
   * A table, keyed by both a plugin and a request method, to a list of the
   * times that it took the plugin to return a response to requests with the
   * method.
   */
  static Map<PluginInfo, Map<String, List<int>>> pluginResponseTimes =
      <PluginInfo, Map<String, List<int>>>{};

  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * The absolute path of the directory containing the on-disk byte store, or
   * `null` if there is no on-disk store.
   */
  final String byteStorePath;

  /**
   * The absolute path of the directory containing the SDK.
   */
  final String sdkPath;

  /**
   * The object used to manage the receiving and sending of notifications.
   */
  final NotificationManager notificationManager;

  /**
   * The instrumentation service that is being used by the analysis server.
   */
  final InstrumentationService instrumentationService;

  /**
   * The list of globs used to match plugin paths that have been whitelisted.
   */
  List<Glob> _whitelistGlobs;

  /**
   * A table mapping the paths of plugins to information about those plugins.
   */
  Map<String, PluginInfo> _pluginMap = <String, PluginInfo>{};

  /**
   * The parameters for the last 'analysis.setPriorityFiles' request that was
   * received from the client. Because plugins are lazily discovered, this needs
   * to be retained so that it can be sent after a plugin has been started.
   */
  AnalysisSetPriorityFilesParams _analysisSetPriorityFilesParams;

  /**
   * The parameters for the last 'analysis.setSubscriptions' request that was
   * received from the client. Because plugins are lazily discovered, this needs
   * to be retained so that it can be sent after a plugin has been started.
   */
  AnalysisSetSubscriptionsParams _analysisSetSubscriptionsParams;

  /**
   * The current state of content overlays. Because plugins are lazily
   * discovered, the state needs to be retained so that it can be sent after a
   * plugin has been started.
   */
  Map<String, dynamic> _overlayState = <String, dynamic>{};

  /**
   * Initialize a newly created plugin manager. The notifications from the
   * running plugins will be handled by the given [notificationManager].
   */
  PluginManager(this.resourceProvider, this.byteStorePath, this.sdkPath,
      this.notificationManager, this.instrumentationService) {
    // TODO(brianwilkerson) Figure out the right list of plugin paths.
    _whitelistGlobs = <Glob>[
      new Glob(resourceProvider.pathContext.separator,
          '**/analyze_angular/tools/analysis_plugin')
    ];
  }

  /**
   * Return a list of all of the plugins that are currently known.
   */
  @visibleForTesting
  List<PluginInfo> get plugins => _pluginMap.values.toList();

  /**
   * Add the plugin with the given [path] to the list of plugins that should be
   * used when analyzing code for the given [contextRoot]. If the plugin had not
   * yet been started, then it will be started by this method.
   */
  Future<Null> addPluginToContextRoot(
      analyzer.ContextRoot contextRoot, String path) async {
    if (!_isWhitelisted(path)) {
      return;
    }
    PluginInfo plugin = _pluginMap[path];
    bool isNew = plugin == null;
    if (isNew) {
      List<String> pluginPaths = _pathsFor(path);
      if (pluginPaths == null) {
        return;
      }
      plugin = new DiscoveredPluginInfo(path, pluginPaths[0], pluginPaths[1],
          notificationManager, instrumentationService);
      _pluginMap[path] = plugin;
      if (pluginPaths[0] != null) {
        PluginSession session = await plugin.start(byteStorePath, sdkPath);
        session?.onDone?.then((_) {
          _pluginMap.remove(path);
        });
      }
    }
    plugin.addContextRoot(contextRoot);
    if (isNew) {
      if (_analysisSetSubscriptionsParams != null) {
        plugin.sendRequest(_analysisSetSubscriptionsParams);
      }
      if (_overlayState.isNotEmpty) {
        plugin.sendRequest(new AnalysisUpdateContentParams(_overlayState));
      }
      if (_analysisSetPriorityFilesParams != null) {
        plugin.sendRequest(_analysisSetPriorityFilesParams);
      }
    }
  }

  /**
   * Broadcast a request built from the given [params] to all of the plugins
   * that are currently associated with the given [contextRoot]. Return a list
   * containing futures that will complete when each of the plugins have sent a
   * response.
   */
  Map<PluginInfo, Future<Response>> broadcastRequest(RequestParams params,
      {analyzer.ContextRoot contextRoot}) {
    List<PluginInfo> plugins = pluginsForContextRoot(contextRoot);
    Map<PluginInfo, Future<Response>> responseMap =
        <PluginInfo, Future<Response>>{};
    for (PluginInfo plugin in plugins) {
      responseMap[plugin] = plugin.currentSession?.sendRequest(params);
    }
    return responseMap;
  }

  /**
   * Broadcast the given [watchEvent] to all of the plugins that are analyzing
   * in contexts containing the file associated with the event. Return a list
   * containing futures that will complete when each of the plugins have sent a
   * response.
   */
  Future<List<Future<Response>>> broadcastWatchEvent(
      watcher.WatchEvent watchEvent) async {
    String filePath = watchEvent.path;

    /**
     * Return `true` if the given glob [pattern] matches the file being watched.
     */
    bool matches(String pattern) =>
        new Glob(resourceProvider.pathContext.separator, pattern)
            .matches(filePath);

    WatchEvent event = null;
    List<Future<Response>> responses = <Future<Response>>[];
    for (PluginInfo plugin in _pluginMap.values) {
      PluginSession session = plugin.currentSession;
      if (session != null &&
          plugin.isAnalyzing(filePath) &&
          session.interestingFiles.any(matches)) {
        event ??= _convertWatchEvent(watchEvent);
        AnalysisHandleWatchEventsParams params =
            new AnalysisHandleWatchEventsParams([event]);
        responses.add(session.sendRequest(params));
      }
    }
    return responses;
  }

  /**
   * Return a list of all of the plugins that are currently associated with the
   * given [contextRoot].
   */
  @visibleForTesting
  List<PluginInfo> pluginsForContextRoot(analyzer.ContextRoot contextRoot) {
    if (contextRoot == null) {
      return _pluginMap.values.toList();
    }
    List<PluginInfo> plugins = <PluginInfo>[];
    for (PluginInfo plugin in _pluginMap.values) {
      if (plugin.contextRoots.contains(contextRoot)) {
        plugins.add(plugin);
      }
    }
    return plugins;
  }

  /**
   * The given [contextRoot] is no longer being analyzed.
   */
  void removedContextRoot(analyzer.ContextRoot contextRoot) {
    List<PluginInfo> plugins = _pluginMap.values.toList();
    for (PluginInfo plugin in plugins) {
      plugin.removeContextRoot(contextRoot);
      if (plugin is DiscoveredPluginInfo && plugin.contextRoots.isEmpty) {
        _pluginMap.remove(plugin.path);
        plugin.stop();
      }
    }
  }

  /**
   * Send a request based on the given [params] to existing plugins to set the
   * priority files to those specified by the [params]. As a side-effect, record
   * the parameters so that they can be sent to any newly started plugins.
   */
  void setAnalysisSetPriorityFilesParams(
      AnalysisSetPriorityFilesParams params) {
    for (PluginInfo plugin in _pluginMap.values) {
      plugin.sendRequest(params);
    }
    _analysisSetPriorityFilesParams = params;
  }

  /**
   * Send a request based on the given [params] to existing plugins to set the
   * subscriptions to those specified by the [params]. As a side-effect, record
   * the parameters so that they can be sent to any newly started plugins.
   */
  void setAnalysisSetSubscriptionsParams(
      AnalysisSetSubscriptionsParams params) {
    for (PluginInfo plugin in _pluginMap.values) {
      plugin.sendRequest(params);
    }
    _analysisSetSubscriptionsParams = params;
  }

  /**
   * Send a request based on the given [params] to existing plugins to set the
   * content overlays to those specified by the [params]. As a side-effect,
   * update the overlay state so that it can be sent to any newly started
   * plugins.
   */
  void setAnalysisUpdateContentParams(AnalysisUpdateContentParams params) {
    for (PluginInfo plugin in _pluginMap.values) {
      plugin.sendRequest(params);
    }
    Map<String, dynamic> files = params.files;
    for (String file in files.keys) {
      Object overlay = files[file];
      if (overlay is RemoveContentOverlay) {
        _overlayState.remove(file);
      } else if (overlay is AddContentOverlay) {
        _overlayState[file] = overlay;
      } else if (overlay is ChangeContentOverlay) {
        AddContentOverlay previousOverlay = _overlayState[file];
        String newContent =
            SourceEdit.applySequence(previousOverlay.content, overlay.edits);
        _overlayState[file] = new AddContentOverlay(newContent);
      } else {
        throw new ArgumentError(
            'Invalid class of overlay: ${overlay.runtimeType}');
      }
    }
  }

  /**
   * Stop all of the plugins that are currently running.
   */
  Future<List<Null>> stopAll() {
    return Future.wait(_pluginMap.values.map((PluginInfo info) => info.stop()));
  }

  /**
   * Whitelist all plugins.
   */
  @visibleForTesting
  void whitelistEverything() {
    _whitelistGlobs = <Glob>[
      new Glob(resourceProvider.pathContext.separator, '**/*')
    ];
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
        throw new StateError('Unknown change type: $type');
    }
  }

  WatchEvent _convertWatchEvent(watcher.WatchEvent watchEvent) {
    return new WatchEvent(_convertChangeType(watchEvent.type), watchEvent.path);
  }

  /**
   * Return `true` if the plugin with the given [path] has been whitelisted.
   */
  bool _isWhitelisted(String path) {
    for (Glob glob in _whitelistGlobs) {
      if (glob.matches(path)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return the execution path and .packages path associated with the plugin at
   * the given [path], or `null` if there is a problem that prevents us from
   * executing the plugin.
   */
  List<String> _pathsFor(String pluginPath) {
    /**
     * Return `true` if the plugin in the give [folder] needs to be copied to a
     * temporary location so that 'pub' can be run to resolve dependencies. We
     * need to run `pub` if the plugin contains a `pubspec.yaml` file and is not
     * in a workspace.
     */
    bool needToCopy(Folder folder) {
      File pubspecFile = folder.getChildAssumingFile('pubspec.yaml');
      if (!pubspecFile.exists) {
        return false;
      }
      return BazelWorkspace.find(resourceProvider, folder.path) == null &&
          GnWorkspace.find(resourceProvider, folder.path) == null;
    }

    /**
     * Compute the paths to be returned by the enclosing method given that the
     * plugin should exist in the given [pluginFolder].
     */
    List<String> computePaths(Folder pluginFolder, {bool runPub: false}) {
      File pluginFile = pluginFolder
          .getChildAssumingFolder('bin')
          .getChildAssumingFile('plugin.dart');
      if (!pluginFile.exists) {
        return null;
      }
      File packagesFile = pluginFolder.getChildAssumingFile('.packages');
      if (!packagesFile.exists) {
        if (runPub) {
          // TODO(brianwilkerson) Run pub in the pluginFolder.
          if (!packagesFile.exists) {
            packagesFile = null;
          }
        } else {
          packagesFile = null;
        }
      }
      return <String>[pluginFile.path, packagesFile?.path];
    }

    Folder pluginFolder = resourceProvider.getFolder(pluginPath);
    if (!needToCopy(pluginFolder)) {
      return computePaths(pluginFolder);
    }
    //
    // Copy the plugin directory to a unique subdirectory of the plugin
    // manager's state location. The subdirectory's name is selected such that
    // it will be invariant across sessions, reducing the number of times the
    // plugin will need to be copied and pub will need to be run.
    //
    Folder stateFolder = resourceProvider.getStateLocation('.plugin_manager');
    String stateName = _uniqueDirectoryName(pluginPath);
    Folder parentFolder = stateFolder.getChildAssumingFolder(stateName);
    if (parentFolder.exists) {
      Folder executionFolder =
          parentFolder.getChildAssumingFolder(pluginFolder.shortName);
      return computePaths(executionFolder);
    }
    Folder executionFolder = pluginFolder.copyTo(parentFolder);
    return computePaths(executionFolder, runPub: true);
  }

  /**
   * Return a hex-encoded MD5 signature of the given file [path].
   */
  String _uniqueDirectoryName(String path) {
    List<int> bytes = md5.convert(path.codeUnits).bytes;
    return hex.encode(bytes);
  }

  /**
   * Record the fact that the given [plugin] responded to a request with the
   * given [method] in the given [time].
   */
  static void recordResponseTime(PluginInfo plugin, String method, int time) {
    pluginResponseTimes
        .putIfAbsent(plugin, () => <String, List<int>>{})
        .putIfAbsent(method, () => <int>[])
        .add(time);
  }
}

/**
 * Information about the execution a single plugin.
 */
@visibleForTesting
class PluginSession {
  /**
   * The maximum number of milliseconds that server should wait for a response
   * from a plugin before deciding that the plugin is hung.
   */
  static const Duration MAXIMUM_RESPONSE_TIME = const Duration(minutes: 2);

  /**
   * The length of time to wait after sending a 'plugin.shutdown' request before
   * a failure to terminate will cause the isolate to be killed.
   */
  static const Duration WAIT_FOR_SHUTDOWN_DURATION =
      const Duration(seconds: 10);

  /**
   * The information about the plugin being executed.
   */
  final PluginInfo info;

  /**
   * The completer used to signal when the plugin has stopped.
   */
  Completer<Null> pluginStoppedCompleter = new Completer<Null>();

  /**
   * The channel used to communicate with the plugin.
   */
  ServerCommunicationChannel channel;

  /**
   * The index of the next request to be sent to the plugin.
   */
  int requestId = 0;

  /**
   * A table mapping the id's of requests to the functions used to handle the
   * response to those requests.
   */
  Map<String, _PendingRequest> pendingRequests = <String, _PendingRequest>{};

  /**
   * A boolean indicating whether the plugin is compatible with the version of
   * the plugin API being used by this server.
   */
  bool isCompatible = true;

  /**
   * The contact information to include when reporting problems related to the
   * plugin.
   */
  String contactInfo;

  /**
   * The glob patterns of files that the plugin is interested in knowing about.
   */
  List<String> interestingFiles;

  /**
   * The name to be used when reporting problems related to the plugin.
   */
  String name;

  /**
   * The version number to be used when reporting problems related to the
   * plugin.
   */
  String version;

  /**
   * Initialize the newly created information about the execution of a plugin.
   */
  PluginSession(this.info);

  /**
   * Return the next request id, encoded as a string and increment the id so
   * that a different result will be returned on each invocation.
   */
  String get nextRequestId => (requestId++).toString();

  /**
   * Return a future that will complete when the plugin has stopped.
   */
  Future<Null> get onDone => pluginStoppedCompleter.future;

  /**
   * Handle the given [notification].
   */
  void handleNotification(Notification notification) {
    if (notification.event == PLUGIN_NOTIFICATION_ERROR) {
      PluginErrorParams params =
          new PluginErrorParams.fromNotification(notification);
      if (params.isFatal) {
        info.stop();
        stop();
      }
    }
    info.notificationManager
        .handlePluginNotification(info.pluginId, notification);
  }

  /**
   * Handle the fact that the plugin has stopped.
   */
  void handleOnDone() {
    channel.close();
    channel = null;
    pluginStoppedCompleter.complete(null);
  }

  /**
   * Handle the fact that an unhandled error has occurred in the plugin.
   */
  void handleOnError(List<String> errorPair) {
    // TODO(brianwilkerson) Decide how we want to handle errors.
    info.instrumentationService.logPluginException(
        info.data, errorPair[0], new StackTrace.fromString(errorPair[1]));
  }

  /**
   * Handle a [response] from the plugin by completing the future that was
   * created when the request was sent.
   */
  void handleResponse(Response response) {
    _PendingRequest requestData = pendingRequests.remove(response.id);
    int responseTime = new DateTime.now().millisecondsSinceEpoch;
    int duration = responseTime - requestData.requestTime;
    PluginManager.recordResponseTime(info, requestData.method, duration);
    Completer<Response> completer = requestData.completer;
    if (completer != null) {
      completer.complete(response);
    }
  }

  /**
   * Return `true` if there are any requests that have not been responded to
   * within the maximum allowed amount of time.
   */
  bool isNonResponsive() {
    // TODO(brianwilkerson) Figure out when to invoke this method in order to
    // identify non-responsive plugins and kill them.
    int cutOffTime = new DateTime.now().millisecondsSinceEpoch -
        MAXIMUM_RESPONSE_TIME.inMilliseconds;
    for (var requestData in pendingRequests.values) {
      if (requestData.requestTime < cutOffTime) {
        return true;
      }
    }
    return false;
  }

  /**
   * Send a request, based on the given [parameters]. Return a future that will
   * complete when a response is received.
   */
  Future<Response> sendRequest(RequestParams parameters) {
    if (channel == null) {
      throw new StateError(
          'Cannot send a request to a plugin that has stopped.');
    }
    String id = nextRequestId;
    Completer<Response> completer = new Completer();
    int requestTime = new DateTime.now().millisecondsSinceEpoch;
    Request request = parameters.toRequest(id);
    pendingRequests[id] =
        new _PendingRequest(request.method, requestTime, completer);
    channel.sendRequest(request);
    return completer.future;
  }

  /**
   * Start a new isolate that is running this plugin. The plugin will be sent
   * the given [byteStorePath]. Return `true` if the plugin is compatible and
   * running.
   */
  Future<bool> start(String byteStorePath, String sdkPath) async {
    if (channel != null) {
      throw new StateError('Cannot start a plugin that is already running.');
    }
    if (byteStorePath == null || byteStorePath.isEmpty) {
      throw new StateError('Missing byte store path');
    }
    if (!isCompatible) {
      return false;
    }
    channel = info._createChannel();
    await channel.listen(handleResponse, handleNotification,
        onDone: handleOnDone, onError: handleOnError);
    if (channel == null) {
      // If there is an error when starting the isolate, the channel will invoke
      // handleOnDone, which will cause `channel` to be set to `null`.
      return false;
    }
    Response response = await sendRequest(new PluginVersionCheckParams(
        byteStorePath ?? '', sdkPath, '1.0.0-alpha.0'));
    PluginVersionCheckResult result =
        new PluginVersionCheckResult.fromResponse(response);
    isCompatible = result.isCompatible;
    contactInfo = result.contactInfo;
    interestingFiles = result.interestingFiles;
    name = result.name;
    version = result.version;
    if (!isCompatible) {
      sendRequest(new PluginShutdownParams());
      return false;
    }
    return true;
  }

  /**
   * Request that the plugin shutdown.
   */
  Future<Null> stop() {
    if (channel == null) {
      throw new StateError('Cannot stop a plugin that is not running.');
    }
    sendRequest(new PluginShutdownParams());
    new Future.delayed(WAIT_FOR_SHUTDOWN_DURATION, () {
      if (channel != null) {
        channel.kill();
        channel = null;
      }
    });
    return pluginStoppedCompleter.future;
  }
}

/**
 * Information about a request that has been sent but for which a response has
 * not yet been received.
 */
class _PendingRequest {
  /**
   * The method of the request.
   */
  final String method;

  /**
   * The time at which the request was sent to the plugin.
   */
  final int requestTime;

  /**
   * The completer that will be used to complete the future when the response is
   * received from the plugin.
   */
  final Completer<Response> completer;

  /**
   * Initialize a pending request.
   */
  _PendingRequest(this.method, this.requestTime, this.completer);
}
