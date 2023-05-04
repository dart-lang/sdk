// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/server/driver.dart' show Driver;
import 'package:analysis_server_client/protocol.dart'
    show
        AddContentOverlay,
        AnalysisUpdateContentParams,
        EditBulkFixesResult,
        ResponseDecoder;
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'core.dart';
import 'experiments.dart';
import 'sdk.dart';
import 'utils.dart';

/// When set, this function is executed just before the Analysis Server starts.
void Function(String cmdName, List<FileSystemEntity> analysisRoots,
    ArgResults? argResults)? preAnalysisServerStart;

/// A class to provide an API wrapper around an analysis server process.
class AnalysisServer {
  AnalysisServer(
    this.packagesFile,
    this.sdkPath,
    this.analysisRoots, {
    this.cacheDirectoryPath,
    required this.commandName,
    required this.argResults,
    this.enabledExperiments = const [],
    this.suppressAnalytics = false,
  });

  final String? cacheDirectoryPath;
  final File? packagesFile;
  final Directory sdkPath;
  final List<FileSystemEntity> analysisRoots;
  final String commandName;
  final ArgResults? argResults;
  final List<String> enabledExperiments;
  final bool suppressAnalytics;

  Process? _process;

  /// When not null, this is a [Completer] which completes when analysis has
  /// finished, otherwise `null`.
  Completer<bool>? _analysisFinished;

  int _id = 0;

  bool _shutdownResponseReceived = false;

  Stream<bool> get onAnalyzing {
    // {"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
    return _streamController('server.status')
        .stream
        .where((event) => event!['analysis'] != null)
        .map((event) => (event!['analysis']['isAnalyzing']!) as bool);
  }

  /// This future completes when we next receive an analysis finished event
  /// (unless there's no current analysis and we've already received a complete
  /// event, in which case this future completes immediately).
  Future<bool>? get analysisFinished => _analysisFinished?.future;

  Stream<FileAnalysisErrors> get onErrors {
    // {"event":"analysis.errors","params":{"file":"/Users/.../lib/main.dart","errors":[]}}
    return _streamController('analysis.errors').stream.map((event) {
      final file = event!['file'] as String;
      final errorsList = event['errors'] as List<dynamic>;
      final errors = errorsList
          .map<Map<String, dynamic>>(castStringKeyedMap)
          .map<AnalysisError>(
              (Map<String, dynamic> json) => AnalysisError(json))
          .toList();
      return FileAnalysisErrors(file, errors);
    });
  }

  Future<int> get onExit => _process!.exitCode;

  final Map<String, StreamController<Map<String, dynamic>>> _streamControllers =
      {};

  /// Completes when an analysis server crash has been detected.
  Future<void> get onCrash => _onCrash.future;

  final _onCrash = Completer<void>();

  final Map<String, Completer<Map<String, dynamic>>> _requestCompleters = {};

  /// Starts the process and returns the pid for it.
  Future<int> start({bool setAnalysisRoots = true}) async {
    preAnalysisServerStart?.call(commandName, analysisRoots, argResults);
    final command = [
      sdk.analysisServerSnapshot,
      if (suppressAnalytics) '--${Driver.SUPPRESS_ANALYTICS_FLAG}',
      '--${Driver.CLIENT_ID}=dart-$commandName',
      '--disable-server-feature-completion',
      '--disable-server-feature-search',
      '--sdk',
      sdkPath.path,
      if (cacheDirectoryPath != null) '--cache=$cacheDirectoryPath',
      if (packagesFile != null) '--packages=${packagesFile!.path}',
      if (enabledExperiments.isNotEmpty)
        '--$experimentFlagName=${enabledExperiments.join(',')}'
    ];

    final process = await startDartProcess(sdk, command);
    _process = process;
    _shutdownResponseReceived = false;
    // This callback hookup can't throw.
    process.exitCode.whenComplete(() {
      _process = null;

      if (!_shutdownResponseReceived) {
        // The process exited unexpectedly. Report the crash.
        // If `server.error` reported an error, that has been logged by
        // `_handleServerError`.

        final error = StateError('The analysis server crashed unexpectedly');

        final analysisFinished = _analysisFinished;
        if (analysisFinished != null && !analysisFinished.isCompleted) {
          // Complete this completer in order to unstick the process.
          analysisFinished.completeError(error);
        }

        // Complete these completers in order to unstick the process.
        for (final completer in _requestCompleters.values) {
          completer.completeError(error);
        }

        _onCrash.complete();
      }
    });

    final errorStream = process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter());
    errorStream.listen(log.stderr);

    final inStream = process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter());
    inStream.listen(_handleServerResponse);

    _streamController('server.error').stream.listen(_handleServerError);

    _sendCommand('server.setSubscriptions', params: <String, dynamic>{
      'subscriptions': <String>['STATUS'],
    });

    // Reference and trim off any trailing slash, the Dart Analysis Server
    // protocol throws an error (INVALID_FILE_PATH_FORMAT) if there is a
    // trailing slash.
    //
    // The call to `absolute.resolveSymbolicLinksSync()` canonicalizes the path
    // to be passed to the analysis server.
    final analysisRootPaths = [
      for (final root in analysisRoots)
        trimEnd(
            root.absolute.resolveSymbolicLinksSync(), path.context.separator),
    ];

    onAnalyzing.listen((isAnalyzing) {
      final analysisFinished = _analysisFinished;
      if (isAnalyzing && (analysisFinished?.isCompleted ?? true)) {
        // Start a new completer, to be completed when we receive the
        // corresponding analysis complete event.
        _analysisFinished = Completer();
      } else if (!isAnalyzing &&
          analysisFinished != null &&
          !analysisFinished.isCompleted) {
        analysisFinished.complete(true);
      }
    });

    if (setAnalysisRoots) {
      await _sendCommand('analysis.setAnalysisRoots', params: {
        'included': analysisRootPaths,
        'excluded': [],
      });
    }

    return process.pid;
  }

  Future<String> getVersion() {
    return _sendCommand('server.getVersion')
        .then((response) => response['version']);
  }

  Future<EditBulkFixesResult> requestBulkFixes(
      String filePath, bool inTestMode, List<String> codes) {
    return _sendCommand('edit.bulkFixes', params: <String, dynamic>{
      'included': [path.canonicalize(filePath)],
      'inTestMode': inTestMode,
      if (codes.isNotEmpty) 'codes': codes,
    }).then((result) {
      return EditBulkFixesResult.fromJson(
          ResponseDecoder(null), 'result', result);
    });
  }

  Future<void> shutdown({Duration? timeout}) async {
    // Request shutdown.
    final Future<void> future = _sendCommand('server.shutdown').then((Map<String, dynamic> value) {
      _shutdownResponseReceived = true;
      return;
    });
    await (timeout != null ? future.timeout(timeout, onTimeout: () {
      log.stderr('The analysis server timed out while shutting down.');
    }) : future).whenComplete(dispose);
  }

  /// Send an `analysis.updateContent` request with the given [files].
  Future<void> updateContent(Map<String, AddContentOverlay> files) async {
    await _sendCommand('analysis.updateContent',
        params: AnalysisUpdateContentParams(files).toJson());
  }

  Future<Map<String, dynamic>> _sendCommand(String method,
      {Map<String, dynamic>? params}) {
    final String id = (++_id).toString();
    final String message = json.encode(<String, dynamic>{
      'id': id,
      'method': method,
      'params': params,
    });

    final Completer<Map<String, dynamic>> completer = Completer();

    _requestCompleters[id] = completer;
    _process!.stdin.writeln(message);

    log.trace('==> $message');

    return completer.future;
  }

  void _handleServerResponse(String line) {
    log.trace('<== $line');

    final dynamic response = json.decode(line);

    if (response is Map<String, dynamic>) {
      if (response['event'] != null) {
        final event = response['event'] as String;
        final dynamic params = response['params'];

        if (params is Map<String, dynamic>) {
          _streamController(event).add(castStringKeyedMap(params));
        }
      } else if (response['id'] != null) {
        final id = response['id'];

        if (response['error'] != null) {
          final error = castStringKeyedMap(response['error']);
          _requestCompleters
              .remove(id)
              ?.completeError(RequestError.parse(error));
        } else {
          _requestCompleters.remove(id)?.complete(response['result'] ?? {});
        }
      }
    }
  }

  void _handleServerError(Map<String, dynamic>? error) {
    final err = error!;
    // Fields are 'isFatal', 'message', and 'stackTrace'.
    log.stderr('Error from the analysis server: ${err['message']}');
    if (err['stackTrace'] != null) {
      log.stderr(err['stackTrace'] as String);
    }
  }

  StreamController<Map<String, dynamic>?> _streamController(String streamId) {
    return _streamControllers.putIfAbsent(
        streamId, () => StreamController<Map<String, dynamic>>.broadcast());
  }

  Future<bool> dispose() async {
    return _process?.kill() ?? true;
  }
}

enum _AnalysisSeverity {
  error,
  warning,
  info,
  none,
}

class AnalysisError implements Comparable<AnalysisError> {
  AnalysisError(this.json);

  static final Map<String, _AnalysisSeverity> _severityMap =
      <String, _AnalysisSeverity>{
    'INFO': _AnalysisSeverity.info,
    'WARNING': _AnalysisSeverity.warning,
    'ERROR': _AnalysisSeverity.error,
  };

  // "severity":"INFO","type":"TODO","location":{
  //   "file":"/Users/.../lib/test.dart","offset":362,"length":72,"startLine":15,"startColumn":4
  // },"message":"...","hasFix":false}
  Map<String, dynamic> json;

  String? get severity => json['severity'] as String?;

  _AnalysisSeverity get _severityLevel =>
      _severityMap[severity!] ?? _AnalysisSeverity.none;

  bool get isInfo => _severityLevel == _AnalysisSeverity.info;

  bool get isWarning => _severityLevel == _AnalysisSeverity.warning;

  bool get isError => _severityLevel == _AnalysisSeverity.error;

  String get type => json['type'] as String;

  String get message => json['message'] as String;

  String get code => json['code'] as String;

  String? get correction => json['correction'] as String?;

  int? get endColumn => json['location']['endColumn'] as int?;

  int? get endLine => json['location']['endLine'] as int?;

  String get file => json['location']['file'] as String;

  int? get startLine => json['location']['startLine'] as int?;

  int? get startColumn => json['location']['startColumn'] as int?;

  int get offset => json['location']['offset'] as int;

  int get length => json['location']['length'] as int;

  String? get url => json['url'] as String?;

  List<DiagnosticMessage> get contextMessages {
    var messages = json['contextMessages'] as List<dynamic>?;
    if (messages == null) {
      // The field is optional, so we return an empty list as a default value.
      return [];
    }
    return messages.map((message) => DiagnosticMessage(message)).toList();
  }

  @override
  int compareTo(AnalysisError other) {
    // Sort in order of severity, file path, error location, and message.
    final int diff = _severityLevel.index - other._severityLevel.index;
    if (diff != 0) {
      return diff;
    }

    if (file != other.file) {
      return file.compareTo(other.file);
    }

    if (offset != other.offset) {
      return offset - other.offset;
    }

    return message.compareTo(other.message);
  }

  @override
  String toString() => '${severity!.toLowerCase()} • '
      '$message • $file:$startLine:$startColumn • '
      '($code)';
}

class DiagnosticMessage {
  final Map<String, dynamic> json;

  DiagnosticMessage(this.json);

  int? get column => json['location']['startColumn'] as int?;

  int? get endColumn => json['location']['endColumn'] as int?;

  int? get endLine => json['location']['endLine'] as int?;

  String get filePath => json['location']['file'] as String;

  int get length => json['location']['length'] as int;

  int get line => json['location']['startLine'] as int;

  String get message => json['message'] as String;

  int get offset => json['location']['offset'] as int;
}

class FileAnalysisErrors {
  final String file;
  final List<AnalysisError> errors;

  FileAnalysisErrors(this.file, this.errors);
}

class RequestError {
  static RequestError parse(dynamic error) {
    return RequestError(
      error['code'],
      error['message'],
      stackTrace: error['stackTrace'],
    );
  }

  final String code;
  final String message;
  final String stackTrace;

  RequestError(this.code, this.message, {required this.stackTrace});

  @override
  String toString() => '[RequestError code: $code, message: $message]';
}
