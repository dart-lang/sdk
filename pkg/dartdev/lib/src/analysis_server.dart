// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/protocol.dart'
    show EditBulkFixesResult, ResponseDecoder;
import 'package:path/path.dart' as path;

import 'core.dart';
import 'sdk.dart';
import 'utils.dart';

/// A class to provide an API wrapper around an analysis server process.
class AnalysisServer {
  AnalysisServer(this.sdkPath, this.directory);

  final Directory sdkPath;
  final Directory directory;

  Process _process;

  Completer<bool> _analysisFinished = Completer();

  int _id = 0;

  Stream<bool> get onAnalyzing {
    // {"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
    return _streamController('server.status')
        .stream
        .where((event) => event['analysis'] != null)
        .map((event) => event['analysis']['isAnalyzing'] as bool);
  }

  /// This future completes when we next receive an analysis finished event
  /// (unless there's no current analysis and we've already received a complete
  /// event, in which case this future completes immediately).
  Future<bool> get analysisFinished => _analysisFinished.future;

  Stream<FileAnalysisErrors> get onErrors {
    // {"event":"analysis.errors","params":{"file":"/Users/.../lib/main.dart","errors":[]}}
    return _streamController('analysis.errors').stream.map((event) {
      final file = event['file'] as String;
      final errorsList = event['errors'] as List<dynamic>;
      final errors = errorsList
          .map<Map<String, dynamic>>(castStringKeyedMap)
          .map<AnalysisError>(
              (Map<String, dynamic> json) => AnalysisError(json))
          .toList();
      return FileAnalysisErrors(file, errors);
    });
  }

  Future<int> get onExit => _process.exitCode;

  final Map<String, StreamController<Map<String, dynamic>>> _streamControllers =
      {};

  final Map<String, Completer<Map<String, dynamic>>> _requestCompleters = {};

  Future<void> start() async {
    final List<String> command = <String>[
      sdk.analysisServerSnapshot,
      '--disable-server-feature-completion',
      '--disable-server-feature-search',
      '--sdk',
      sdkPath.path,
    ];

    _process = await startDartProcess(sdk, command);
    // This callback hookup can't throw.
    // ignore: unawaited_futures
    _process.exitCode.whenComplete(() => _process = null);

    final Stream<String> errorStream = _process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter());
    errorStream.listen(log.stderr);

    final Stream<String> inStream = _process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter());
    inStream.listen(_handleServerResponse);

    _streamController('server.error').stream.listen(_handleServerError);

    // ignore: unawaited_futures
    _sendCommand('server.setSubscriptions', params: <String, dynamic>{
      'subscriptions': <String>['STATUS'],
    });

    // Reference and trim off any trailing slash, the Dart Analysis Server
    // protocol throws an error (INVALID_FILE_PATH_FORMAT) if there is a
    // trailing slash.
    //
    // The call to absolute.resolveSymbolicLinksSync() canonicalizes the path to
    // be passed to the analysis server.
    var dirPath = trimEnd(
      directory.absolute.resolveSymbolicLinksSync(),
      path.context.separator,
    );

    onAnalyzing.listen((bool isAnalyzing) {
      if (isAnalyzing && _analysisFinished.isCompleted) {
        // Start a new completer, to be completed when we receive the
        // corresponding analysis complete event.
        _analysisFinished = Completer();
      } else if (!isAnalyzing && !_analysisFinished.isCompleted) {
        _analysisFinished.complete(true);
      }
    });

    // ignore: unawaited_futures
    _sendCommand('analysis.setAnalysisRoots', params: <String, dynamic>{
      'included': [dirPath],
      'excluded': <String>[]
    });
  }

  Future<String> getVersion() {
    return _sendCommand('server.getVersion')
        .then((response) => response['version']);
  }

  Future<EditBulkFixesResult> requestBulkFixes(String filePath) {
    return _sendCommand('edit.bulkFixes', params: <String, dynamic>{
      'included': [path.canonicalize(filePath)],
    }).then((result) {
      return EditBulkFixesResult.fromJson(
          ResponseDecoder(null), 'result', result);
    });
  }

  Future<void> shutdown({Duration timeout = const Duration(seconds: 5)}) async {
    // Request shutdown.
    await _sendCommand('server.shutdown').then((value) {
      return null;
    }).timeout(timeout, onTimeout: () async {
      await dispose();
    }).then((value) async {
      await dispose();
    });
  }

  Future<Map<String, dynamic>> _sendCommand(String method,
      {Map<String, dynamic> params}) {
    final String id = (++_id).toString();
    final String message = json.encode(<String, dynamic>{
      'id': id,
      'method': method,
      'params': params,
    });

    _requestCompleters[id] = Completer();
    _process.stdin.writeln(message);

    log.trace('==> $message');

    return _requestCompleters[id].future;
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
          _requestCompleters.remove(id)?.complete(response['result']);
        }
      }
    }
  }

  void _handleServerError(Map<String, dynamic> error) {
    // Fields are 'isFatal', 'message', and 'stackTrace'.
    log.stderr('Error from the analysis server: ${error['message']}');
    if (error['stackTrace'] != null) {
      log.stderr(error['stackTrace'] as String);
    }
  }

  StreamController<Map<String, dynamic>> _streamController(String streamId) {
    return _streamControllers.putIfAbsent(
        streamId, () => StreamController<Map<String, dynamic>>.broadcast());
  }

  Future<bool> dispose() async {
    return _process?.kill();
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

  String get severity => json['severity'] as String;

  _AnalysisSeverity get _severityLevel =>
      _severityMap[severity] ?? _AnalysisSeverity.none;

  bool get isInfo => _severityLevel == _AnalysisSeverity.info;

  bool get isWarning => _severityLevel == _AnalysisSeverity.warning;

  bool get isError => _severityLevel == _AnalysisSeverity.error;

  String get type => json['type'] as String;

  String get message => json['message'] as String;

  String get code => json['code'] as String;

  String get correction => json['correction'] as String;

  String get file => json['location']['file'] as String;

  int get startLine => json['location']['startLine'] as int;

  int get startColumn => json['location']['startColumn'] as int;

  int get offset => json['location']['offset'] as int;

  int get length => json['location']['length'] as int;

  String get messageSentenceFragment => trimEnd(message, '.');

  String get url => json['url'] as String;

  List<DiagnosticMessage> get contextMessages {
    var messages = json['contextMessages'] as List<dynamic>;
    if (messages == null) {
      // The field is optional, so we return an empty list as a default value.
      return [];
    }
    return messages.map((message) => DiagnosticMessage(message)).toList();
  }

  // TODO(jwren) add some tests to verify that the results are what we are
  // expecting, 'other' is not always on the RHS of the subtraction in the
  // implementation.
  @override
  int compareTo(AnalysisError other) {
    // Sort in order of file path, error location, severity, and message.
    if (file != other.file) {
      return file.compareTo(other.file);
    }

    if (offset != other.offset) {
      return offset - other.offset;
    }

    final int diff = other._severityLevel.index - _severityLevel.index;
    if (diff != 0) {
      return diff;
    }

    return message.compareTo(other.message);
  }

  @override
  String toString() => '${severity.toLowerCase()} • '
      '$messageSentenceFragment at $file:$startLine:$startColumn • '
      '($code)';
}

class DiagnosticMessage {
  final Map<String, dynamic> json;

  DiagnosticMessage(this.json);

  int get column => json['location']['startColumn'] as int;

  String get filePath => json['location']['file'] as String;

  int get line => json['location']['startLine'] as int;

  String get message => json['message'] as String;
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

  RequestError(this.code, this.message, {this.stackTrace});

  @override
  String toString() => '[RequestError code: $code, message: $message]';
}
