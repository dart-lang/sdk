// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server_plugin/src/plugin_server.dart';
library;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/server_isolate_channel.dart';
import 'package:analysis_server/src/session_logger/session_logger.dart';
import 'package:analyzer/dart/analysis/context_root.dart' as analyzer;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/util/platform_info.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:meta/meta.dart';

/// An interface to a configured plugin isolate.
class PluginIsolate {
  /// The path to the root directory of the definition of the plugin on disk
  /// (the directory containing the 'pubspec.yaml' file and the 'bin'
  /// directory).
  final String _path;

  /// The path to the 'plugin.dart' file that will be executed in an isolate, or
  /// `null` if the isolate could not be started.
  final String? executionPath;

  /// The path to the package config file used to control the resolution of
  /// 'package:' URIs, or `null` if the isolate could not be started.
  final String? packageConfigPath;

  /// The object used to manage the receiving and sending of notifications.
  final AbstractNotificationManager _notificationManager;

  /// The instrumentation service that is being used by the analysis server.
  final InstrumentationService _instrumentationService;

  /// The session logger that is to be used by the isolate.
  final SessionLogger sessionLogger;

  /// The context roots that are currently using the results produced by the
  /// plugin.
  Set<analyzer.ContextRoot> contextRoots = HashSet<analyzer.ContextRoot>();

  /// The current execution of the plugin, or `null` if the plugin is not
  /// currently being executed.
  PluginSession? currentSession;

  CaughtException? _exception;

  bool isLegacy;

  PluginIsolate(
    this._path,
    this.executionPath,
    this.packageConfigPath,
    this._notificationManager,
    this._instrumentationService,
    this.sessionLogger, {
    required this.isLegacy,
  });

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
  bool get _canBeStarted => executionPath != null;

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

  /// Requests plugin details from the plugin isolate.
  Future<PluginDetailsResult?> requestDetails() async {
    if (currentSession case PluginSession currentSession) {
      Response response;
      try {
        response = await currentSession
            .sendRequest(PluginDetailsParams())
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // TODO(srawlins): Return a `PluginDetailsResult` with a specific error?
        return null;
      }
      if (response.error != null) throw response.error!;
      return PluginDetailsResult.fromResponse(response);
    } else {
      return null;
    }
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
    return ServerIsolateChannel(
      Uri.file(executionPath!, windows: platform.isWindows),
      Uri.file(packageConfigPath!, windows: platform.isWindows),
      _instrumentationService,
      sessionLogger,
    );
  }

  /// Updates the context roots that the plugin should be analyzing.
  void _updatePluginRoots() {
    sendRequest(
      AnalysisSetContextRootsParams(
        contextRoots
            .map(
              (analyzer.ContextRoot contextRoot) => ContextRoot(
                contextRoot.root.path,
                contextRoot.excludedPaths.toList(),
                optionsFile: contextRoot.optionsFile?.path,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Information about the execution of a single plugin.
@visibleForTesting
class PluginSession {
  /// The maximum number of milliseconds that server should wait for a response
  /// from a plugin before deciding that the plugin is hung.
  static const Duration _maximumResponseTime = Duration(minutes: 2);

  /// The length of time to wait after sending a 'plugin.shutdown' request
  /// before a failure to terminate will cause the isolate to be killed.
  static const Duration _waitForShutdownDuration = Duration(seconds: 10);

  /// The information about the plugin being executed.
  final PluginIsolate _isolate;

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
  List<String>? interestingFileGlobs;

  /// The name to be used when reporting problems related to the plugin.
  String? _name;

  /// The version number to be used when reporting problems related to the
  /// plugin.
  String? _version;

  PluginSession(this._isolate);

  /// The next request ID, encoded as a string.
  ///
  /// This increments the ID so that a different result will be returned on each
  /// invocation.
  String get nextRequestId => (requestId++).toString();

  /// A future that will complete when the plugin has stopped.
  Future<void> get onDone => pluginStoppedCompleter.future;

  /// Handles the given [notification] from [PluginServer].
  void handleNotification(Notification notification) {
    if (notification.event == PLUGIN_NOTIFICATION_ERROR) {
      var params = PluginErrorParams.fromNotification(notification);
      if (params.isFatal) {
        _isolate.stop();
        stop();
      }
    }
    _isolate._notificationManager.handlePluginNotification(
      _isolate.pluginId,
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
      _isolate.reportException(
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
      PluginManager.recordResponseTime(_isolate, requestData.method, duration);
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
        _maximumResponseTime.inMilliseconds;
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
          _isolate._instrumentationService.logInfo(
            "Plugin cannot handle request '${request.method}' with parameters: "
            '$parameters.',
          );
          return;
        }
        var stackTrace = StackTrace.fromString(error.stackTrace!);
        var exception = PluginException(error.message);
        _isolate.reportException(
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
      _isolate.reportException(
        CaughtException(
          PluginException('Plugin is not compatible.'),
          StackTrace.current,
        ),
      );
      return false;
    }
    if (!_isolate._canBeStarted) {
      _isolate.reportException(
        CaughtException(
          PluginException('Plugin cannot be started.'),
          StackTrace.current,
        ),
      );
      return false;
    }
    channel = _isolate._createChannel();
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
      _isolate.reportException(
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
    interestingFileGlobs = result.interestingFiles;
    _name = result.name;
    _version = result.version;
    if (!isCompatible) {
      unawaited(sendRequest(PluginShutdownParams()));
      _isolate.reportException(
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
    Future.delayed(_waitForShutdownDuration, () {
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
