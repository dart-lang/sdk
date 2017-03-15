// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/bazel.dart';
import 'package:analyzer/src/generated/gn.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/channel/isolate_channel.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/**
 * Information about a single plugin.
 */
@visibleForTesting
class PluginInfo {
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
  Set<ContextRoot> contextRoots = new HashSet<ContextRoot>();

  /**
   * The current execution of the plugin, or `null` if the plugin is not
   * currently being executed.
   */
  PluginSession currentSession;

  /**
   * Initialize the newly created information about a plugin.
   */
  PluginInfo(this.path, this.executionPath, this.packagesPath,
      this.notificationManager, this.instrumentationService);

  /**
   * Add the given [contextRoot] to the set of context roots being analyzed by
   * this plugin.
   */
  void addContextRoot(ContextRoot contextRoot) {
    if (contextRoots.add(contextRoot)) {
      _updatePluginRoots();
    }
  }

  /**
   * Remove the given [contextRoot] from the set of context roots being analyzed
   * by this plugin.
   */
  void removeContextRoot(ContextRoot contextRoot) {
    if (contextRoots.remove(contextRoot)) {
      _updatePluginRoots();
    }
  }

  /**
   * Start a new isolate that is running the plugin. Return the state object
   * used to interact with the plugin.
   */
  Future<PluginSession> start(String byteStorePath) async {
    if (currentSession != null) {
      throw new StateError('Cannot start a plugin that is already running.');
    }
    currentSession = new PluginSession(this);
    await currentSession.start(byteStorePath);
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
   * Update the context roots that the plugin should be analyzing.
   */
  void _updatePluginRoots() {
    if (currentSession != null) {
      AnalysisSetContextRootsParams params =
          new AnalysisSetContextRootsParams(contextRoots.toList());
      currentSession.sendRequest(params);
    }
  }
}

/**
 * An object used to manage the currently running plugins.
 */
class PluginManager {
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
   * The object used to manage the receiving and sending of notifications.
   */
  final NotificationManager notificationManager;

  /**
   * The instrumentation service that is being used by the analysis server.
   */
  final InstrumentationService instrumentationService;

  /**
   * A table mapping the paths of plugins to information about those plugins.
   */
  Map<String, PluginInfo> _pluginMap = <String, PluginInfo>{};

  /**
   * Initialize a newly created plugin manager. The notifications from the
   * running plugins will be handled by the given [notificationManager].
   */
  PluginManager(this.resourceProvider, this.byteStorePath,
      this.notificationManager, this.instrumentationService);

  /**
   * Add the plugin with the given [path] to the list of plugins that should be
   * used when analyzing code for the given [contextRoot]. If the plugin had not
   * yet been started, then it will be started by this method.
   */
  Future<Null> addPluginToContextRoot(
      ContextRoot contextRoot, String path) async {
    PluginInfo plugin = _pluginMap[path];
    if (plugin == null) {
      List<String> pluginPaths = _pathsFor(path);
      plugin = new PluginInfo(path, pluginPaths[0], pluginPaths[1],
          notificationManager, instrumentationService);
      _pluginMap[path] = plugin;
      if (pluginPaths[0] != null) {
        PluginSession session = await plugin.start(byteStorePath);
        session.onDone.then((_) {
          _pluginMap.remove(path);
        });
      }
    }
    plugin.addContextRoot(contextRoot);
  }

  /**
   * Broadcast a request built from the given [params] to all of the plugins
   * that are currently associated with the given [contextRoot]. Return a list
   * containing futures that will complete when each of the plugins have sent a
   * response.
   */
  List<Future<Response>> broadcast(
      ContextRoot contextRoot, RequestParams params) {
    List<PluginInfo> plugins = pluginsForContextRoot(contextRoot);
    return plugins
        .map((PluginInfo plugin) => plugin.currentSession?.sendRequest(params))
        .toList();
  }

  /**
   * Return a list of all of the plugins that are currently associated with the
   * given [contextRoot].
   */
  @visibleForTesting
  List<PluginInfo> pluginsForContextRoot(ContextRoot contextRoot) {
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
  void removedContextRoot(ContextRoot contextRoot) {
    List<PluginInfo> plugins = _pluginMap.values.toList();
    for (PluginInfo plugin in plugins) {
      plugin.removeContextRoot(contextRoot);
      if (plugin.contextRoots.isEmpty) {
        _pluginMap.remove(plugin.path);
        plugin.stop();
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
        }
        packagesFile = null;
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
}

/**
 * Information about the execution a single plugin.
 */
@visibleForTesting
class PluginSession {
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
  Map<String, Completer<Response>> pendingRequests =
      <String, Completer<Response>>{};

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
    info.notificationManager.handlePluginNotification(info.path, notification);
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
//    String message = errorPair[0];
//    String stackTrace = errorPair[1];
//    print('PluginSession.handleOnError');
//    print('  plugin = ${info.executionPath}');
//    print('  $message');
//    print('  ${new StackTrace.fromString(stackTrace)}');
//    pluginStoppedCompleter.completeError(message, new StackTrace.fromString(stackTrace));
  }

  /**
   * Handle a [response] from the plugin by completing the future that was
   * created when the request was sent.
   */
  void handleResponse(Response response) {
    Completer<Response> completer = pendingRequests.remove(response.id);
    if (completer != null) {
      completer.complete(response);
    }
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
    pendingRequests[id] = completer;
    channel.sendRequest(parameters.toRequest(id));
    return completer.future;
  }

  /**
   * Start a new isolate that is running this plugin. The plugin will be sent
   * the given [byteStorePath]. Return `true` if the plugin is compatible and
   * running.
   */
  Future<bool> start(String byteStorePath) async {
    if (channel != null) {
      throw new StateError('Cannot start a plugin that is already running.');
    }
    if (byteStorePath == null || byteStorePath.isEmpty) {
      throw new StateError('Missing byte store path');
    }
    if (!isCompatible) {
      return false;
    }
    channel = new ServerIsolateChannel(
        new Uri.file(info.executionPath, windows: Platform.isWindows),
        new Uri.file(info.packagesPath, windows: Platform.isWindows),
        info.instrumentationService);
    await channel.listen(handleResponse, handleNotification,
        onDone: handleOnDone, onError: handleOnError);
    Response response = await sendRequest(
        new PluginVersionCheckParams(byteStorePath ?? '', '1.0.0-alpha.0'));
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
    // TODO(brianwilkerson) Ensure that the isolate is killed if it does not
    // terminate normally.
    sendRequest(new PluginShutdownParams());
    return pluginStoppedCompleter.future;
  }
}
