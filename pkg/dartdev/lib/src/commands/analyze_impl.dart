// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';

/// A class to provide an API wrapper around an analysis server process.
class AnalysisServer {
  AnalysisServer(this.sdkPath, this.directories);

  final Directory sdkPath;
  final List<Directory> directories;

  Process _process;
  final StreamController<bool> _analyzingController =
      StreamController<bool>.broadcast();
  final StreamController<FileAnalysisErrors> _errorsController =
      StreamController<FileAnalysisErrors>.broadcast();
  bool _didServerErrorOccur = false;

  int _id = 0;

  bool get didServerErrorOccur => _didServerErrorOccur;

  Stream<bool> get onAnalyzing => _analyzingController.stream;

  Stream<FileAnalysisErrors> get onErrors => _errorsController.stream;

  Future<int> get onExit => _process.exitCode;

  Future<void> start() async {
    final List<String> command = <String>[
      sdk.analysisServerSnapshot,
      '--disable-server-feature-completion',
      '--disable-server-feature-search',
      '--sdk',
      sdkPath.path,
    ];

    _process = await startProcess(sdk.dart, command);
    // This callback hookup can't throw.
    //ignore: unawaited_futures
    _process.exitCode.whenComplete(() => _process = null);

    final Stream<String> errorStream = _process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter());
    errorStream.listen(log.stderr);

    final Stream<String> inStream = _process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter());
    inStream.listen(_handleServerResponse);

    _sendCommand('server.setSubscriptions', <String, dynamic>{
      'subscriptions': <String>['STATUS'],
    });

    // Reference and trim off any trailing slash, the Dart Analysis Server
    // protocol throws an error (INVALID_FILE_PATH_FORMAT) if there is a
    // trailing slash.
    //
    // The call to absolute.resolveSymbolicLinksSync() canonicalizes the path
    // to be passed to the analysis server.
    var dirPath = trimEnd(
      directories.single.absolute.resolveSymbolicLinksSync(),
      path.context.separator,
    );

    _sendCommand('analysis.setAnalysisRoots', <String, dynamic>{
      'included': [dirPath],
      'excluded': <String>[]
    });
  }

  void _sendCommand(String method, Map<String, dynamic> params) {
    final String message = json.encode(<String, dynamic>{
      'id': (++_id).toString(),
      'method': method,
      'params': params,
    });
    _process.stdin.writeln(message);
    log.trace('==> $message');
  }

  void _handleServerResponse(String line) {
    log.trace('<== $line');

    final dynamic response = json.decode(line);

    if (response is Map<String, dynamic>) {
      if (response['event'] != null) {
        final String event = response['event'] as String;
        final dynamic params = response['params'];

        if (params is Map<String, dynamic>) {
          if (event == 'server.status') {
            _handleStatus(castStringKeyedMap(response['params']));
          } else if (event == 'analysis.errors') {
            _handleAnalysisIssues(castStringKeyedMap(response['params']));
          } else if (event == 'server.error') {
            _handleServerError(castStringKeyedMap(response['params']));
          }
        }
      } else if (response['error'] != null) {
        // Fields are 'code', 'message', and 'stackTrace'.
        final Map<String, dynamic> error =
            castStringKeyedMap(response['error']);
        log.stderr(
          'Error response from the server: '
          '${error['code']} ${error['message']}',
        );
        if (error['stackTrace'] != null) {
          log.stderr(error['stackTrace'] as String);
        }
        // Dispose of the process at this point so the process doesn't hang.
        dispose();
      }
    }
  }

  void _handleStatus(Map<String, dynamic> statusInfo) {
    // {"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
    if (statusInfo['analysis'] != null && !_analyzingController.isClosed) {
      final bool isAnalyzing = statusInfo['analysis']['isAnalyzing'] as bool;
      _analyzingController.add(isAnalyzing);
    }
  }

  void _handleServerError(Map<String, dynamic> error) {
    // Fields are 'isFatal', 'message', and 'stackTrace'.
    log.stderr('Error from the analysis server: ${error['message']}');
    if (error['stackTrace'] != null) {
      log.stderr(error['stackTrace'] as String);
    }
    _didServerErrorOccur = true;
  }

  void _handleAnalysisIssues(Map<String, dynamic> issueInfo) {
    // {"event":"analysis.errors","params":{"file":"/Users/.../lib/main.dart","errors":[]}}
    final String file = issueInfo['file'] as String;
    final List<dynamic> errorsList = issueInfo['errors'] as List<dynamic>;
    final List<AnalysisError> errors = errorsList
        .map<Map<String, dynamic>>(castStringKeyedMap)
        .map<AnalysisError>((Map<String, dynamic> json) => AnalysisError(json))
        .toList();
    if (!_errorsController.isClosed) {
      _errorsController.add(FileAnalysisErrors(file, errors));
    }
  }

  Future<bool> dispose() async {
    await _analyzingController.close();
    await _errorsController.close();
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

  String get messageSentenceFragment => trimEnd(message, '.');

  String get url => json['url'] as String;

  List<DiagnosticMessage> get contextMessages {
    var messages = json['contextMessages'] as List<dynamic>;
    return messages.map((message) => DiagnosticMessage(message)).toList();
  }

  // TODO(jwren) add some tests to verify that the results are what we are
  //  expecting, 'other' is not always on the RHS of the subtraction in the
  //  implementation.
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
