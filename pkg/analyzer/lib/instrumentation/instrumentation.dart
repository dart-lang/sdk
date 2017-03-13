// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.instrumentation.instrumentation;

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/task/model.dart';

/**
 * A container with analysis performance constants.
 */
class AnalysisPerformanceKind {
  static const String FULL = 'analysis_full';
  static const String INCREMENTAL = 'analysis_incremental';
}

/**
 * The interface used by client code to communicate with an instrumentation
 * server.
 */
abstract class InstrumentationServer {
  /**
   * A user-friendly description of this instrumentation server.
   */
  String get describe;

  /**
   * Return the identifier used to identify the current session.
   */
  String get sessionId;

  /**
   * Pass the given [message] to the instrumentation server so that it will be
   * logged with other messages.
   *
   * This method should be used for most logging.
   */
  void log(String message);

  /**
   * Pass the given [message] to the instrumentation server so that it will be
   * logged with other messages.
   *
   * This method should only be used for logging high priority messages, such as
   * exceptions that cause the server to shutdown.
   */
  void logWithPriority(String message);

  /**
   * Signal that the client is done communicating with the instrumentation
   * server. This method should be invoked exactly one time and no other methods
   * should be invoked on this instance after this method has been invoked.
   */
  Future shutdown();
}

/**
 * The interface used by client code to communicate with an instrumentation
 * server by wrapping an [InstrumentationServer].
 */
class InstrumentationService {
  /**
   * An instrumentation service that will not log any instrumentation data.
   */
  static final InstrumentationService NULL_SERVICE =
      new InstrumentationService(null);

  static const String TAG_ANALYSIS_TASK = 'Task';
  static const String TAG_ERROR = 'Err';
  static const String TAG_EXCEPTION = 'Ex';
  static const String TAG_FILE_READ = 'Read';
  static const String TAG_LOG_ENTRY = 'Log';
  static const String TAG_NOTIFICATION = 'Noti';
  static const String TAG_PERFORMANCE = 'Perf';
  static const String TAG_PLUGIN_NOTIFICATION = 'PluginNoti';
  static const String TAG_PLUGIN_REQUEST = 'PluginReq';
  static const String TAG_PLUGIN_RESPONSE = 'PluginRes';
  static const String TAG_REQUEST = 'Req';
  static const String TAG_RESPONSE = 'Res';
  static const String TAG_SUBPROCESS_START = 'SPStart';
  static const String TAG_SUBPROCESS_RESULT = 'SPResult';
  static const String TAG_VERSION = 'Ver';
  static const String TAG_WATCH_EVENT = 'Watch';

  /**
   * The instrumentation server used to communicate with the server, or `null`
   * if instrumentation data should not be logged.
   */
  InstrumentationServer _instrumentationServer;

  /**
   * Counter used to generate unique ID's for [logSubprocessStart].
   */
  int _subprocessCounter = 0;

  /**
   * Initialize a newly created instrumentation service to communicate with the
   * given [_instrumentationServer].
   */
  InstrumentationService(this._instrumentationServer);

  InstrumentationServer get instrumentationServer => _instrumentationServer;

  /**
   * Return `true` if this [InstrumentationService] was initialized with a
   * non-`null` server (and hence instrumentation is active).
   */
  bool get isActive => _instrumentationServer != null;

  /**
   * Return the identifier used to identify the current session.
   */
  String get sessionId => _instrumentationServer?.sessionId ?? '';

  /**
   * The current time, expressed as a decimal encoded number of milliseconds.
   */
  String get _timestamp => new DateTime.now().millisecondsSinceEpoch.toString();

  /**
   * Log that the given analysis [task] is being performed in the given
   * [context].
   */
  void logAnalysisTask(String context, AnalysisTask task) {
    if (_instrumentationServer != null) {
      _instrumentationServer
          .log(_join([TAG_ANALYSIS_TASK, context, task.description]));
    }
  }

  /**
   * Log the fact that an error, described by the given [message], has occurred.
   */
  void logError(String message) {
    _log(TAG_ERROR, message);
  }

  /**
   * Log that the given non-priority [exception] was thrown, with the given
   * [stackTrace].
   */
  void logException(dynamic exception, StackTrace stackTrace) {
    if (_instrumentationServer != null) {
      String message = _toString(exception);
      String trace = _toString(stackTrace);
      _instrumentationServer.log(_join([TAG_EXCEPTION, message, trace]));
    }
  }

  /**
   * Log that the contents of the file with the given [path] were read. The file
   * had the given [content] and [modificationTime].
   */
  void logFileRead(String path, int modificationTime, String content) {
    if (_instrumentationServer != null) {
      String timeStamp = _toString(modificationTime);
      _instrumentationServer
          .log(_join([TAG_FILE_READ, path, timeStamp, content]));
    }
  }

  /**
   * Log that a log entry that was written to the analysis engine's log. The log
   * entry has the given [level] and [message], and was created at the given
   * [time].
   */
  void logLogEntry(String level, DateTime time, String message,
      Object exception, StackTrace stackTrace) {
    if (_instrumentationServer != null) {
      String timeStamp =
          time == null ? 'null' : time.millisecondsSinceEpoch.toString();
      String exceptionText = exception.toString();
      String stackTraceText = stackTrace.toString();
      _instrumentationServer.log(_join([
        TAG_LOG_ENTRY,
        level,
        timeStamp,
        message,
        exceptionText,
        stackTraceText
      ]));
    }
  }

  /**
   * Log that a notification has been sent to the client.
   */
  void logNotification(String notification) {
    _log(TAG_NOTIFICATION, notification);
  }

  /**
   * Log the given performance fact.
   */
  void logPerformance(String kind, Stopwatch sw, String message) {
    sw.stop();
    String elapsed = sw.elapsedMilliseconds.toString();
    if (_instrumentationServer != null) {
      _instrumentationServer
          .log(_join([TAG_PERFORMANCE, kind, elapsed, message]));
    }
  }

  void logPluginNotification(Uri pluginUri, String notification) {
    if (_instrumentationServer != null) {
      _instrumentationServer.log(
          _join([TAG_PLUGIN_NOTIFICATION, _toString(pluginUri), notification]));
    }
  }

  void logPluginRequest(Uri pluginUri, String request) {
    if (_instrumentationServer != null) {
      _instrumentationServer
          .log(_join([TAG_PLUGIN_REQUEST, _toString(pluginUri), request]));
    }
  }

  void logPluginResponse(Uri pluginUri, String response) {
    if (_instrumentationServer != null) {
      _instrumentationServer
          .log(_join([TAG_PLUGIN_RESPONSE, _toString(pluginUri), response]));
    }
  }

  /**
   * Log that the given priority [exception] was thrown, with the given
   * [stackTrace].
   */
  void logPriorityException(dynamic exception, StackTrace stackTrace) {
    if (_instrumentationServer != null) {
      String message = _toString(exception);
      String trace = _toString(stackTrace);
      _instrumentationServer
          .logWithPriority(_join([TAG_EXCEPTION, message, trace]));
    }
  }

  /**
   * Log that a request has been sent to the client.
   */
  void logRequest(String request) {
    _log(TAG_REQUEST, request);
  }

  /**
   * Log that a response has been sent to the client.
   */
  void logResponse(String response) {
    _log(TAG_RESPONSE, response);
  }

  /**
   * Log the result of executing a subprocess.  [subprocessId] should be the
   * unique ID returned by [logSubprocessStart].
   */
  void logSubprocessResult(
      int subprocessId, int exitCode, String stdout, String stderr) {
    if (_instrumentationServer != null) {
      _instrumentationServer.log(_join([
        TAG_SUBPROCESS_RESULT,
        subprocessId.toString(),
        exitCode.toString(),
        JSON.encode(stdout),
        JSON.encode(stderr)
      ]));
    }
  }

  /**
   * Log that the given subprocess is about to be executed.  Returns a unique
   * identifier that can be used to identify the subprocess for later log
   * entries.
   */
  int logSubprocessStart(
      String executablePath, List<String> arguments, String workingDirectory) {
    int subprocessId = _subprocessCounter++;
    if (_instrumentationServer != null) {
      _instrumentationServer.log(_join([
        TAG_SUBPROCESS_START,
        subprocessId.toString(),
        executablePath,
        workingDirectory,
        JSON.encode(arguments)
      ]));
    }
    return subprocessId;
  }

  /**
   * Signal that the client has started analysis server.
   * This method should be invoked exactly one time.
   */
  void logVersion(String uuid, String clientId, String clientVersion,
      String serverVersion, String sdkVersion) {
    String normalize(String value) =>
        value != null && value.length > 0 ? value : 'unknown';

    if (_instrumentationServer != null) {
      _instrumentationServer.logWithPriority(_join([
        TAG_VERSION,
        uuid,
        normalize(clientId),
        normalize(clientVersion),
        serverVersion,
        sdkVersion
      ]));
    }
  }

  /**
   * Log that the file system watcher sent an event. The [folderPath] is the
   * path to the folder containing the changed file, the [filePath] is the path
   * of the file that changed, and the [changeType] indicates what kind of
   * change occurred.
   */
  void logWatchEvent(String folderPath, String filePath, String changeType) {
    if (_instrumentationServer != null) {
      _instrumentationServer
          .log(_join([TAG_WATCH_EVENT, folderPath, filePath, changeType]));
    }
  }

  /**
   * Signal that the client is done communicating with the instrumentation
   * server. This method should be invoked exactly one time and no other methods
   * should be invoked on this instance after this method has been invoked.
   */
  Future shutdown() async {
    if (_instrumentationServer != null) {
      await _instrumentationServer.shutdown();
      _instrumentationServer = null;
    }
  }

  /**
   * Write an escaped version of the given [field] to the given [buffer].
   */
  void _escape(StringBuffer buffer, String field) {
    int index = field.indexOf(':');
    if (index < 0) {
      buffer.write(field);
      return;
    }
    int start = 0;
    while (index >= 0) {
      buffer.write(field.substring(start, index));
      buffer.write('::');
      start = index + 1;
      index = field.indexOf(':', start);
    }
    buffer.write(field.substring(start));
  }

  /**
   * Return the result of joining the values of the given fields, escaping the
   * separator character by doubling it.
   */
  String _join(List<String> fields) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(_timestamp);
    int length = fields.length;
    for (int i = 0; i < length; i++) {
      buffer.write(':');
      _escape(buffer, fields[i]);
    }
    return buffer.toString();
  }

  /**
   * Log the given message with the given tag.
   */
  void _log(String tag, String message) {
    if (_instrumentationServer != null) {
      _instrumentationServer.log(_join([tag, message]));
    }
  }

  /**
   * Convert the given [object] to a string.
   */
  String _toString(Object object) {
    if (object == null) {
      return 'null';
    }
    return object.toString();
  }
}

/**
 * An [InstrumentationServer] that sends messages to multiple instances.
 */
class MulticastInstrumentationServer implements InstrumentationServer {
  final List<InstrumentationServer> _servers;

  MulticastInstrumentationServer(this._servers);

  @override
  String get describe {
    return _servers
        .map((InstrumentationServer server) => server.describe)
        .join("\n");
  }

  @override
  String get sessionId => _servers[0].sessionId;

  @override
  void log(String message) {
    for (InstrumentationServer server in _servers) {
      server.log(message);
    }
  }

  @override
  void logWithPriority(String message) {
    for (InstrumentationServer server in _servers) {
      server.logWithPriority(message);
    }
  }

  @override
  Future shutdown() async {
    for (InstrumentationServer server in _servers) {
      await server.shutdown();
    }
  }
}
