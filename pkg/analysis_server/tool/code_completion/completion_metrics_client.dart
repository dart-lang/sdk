// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/server/driver.dart';
import 'package:analysis_server/src/services/completion/dart/documentation_cache.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'completion_metrics_base.dart';
import 'metrics_util.dart';
import 'output_utilities.dart';
import 'relevance_table_generator.dart';
import 'visitors.dart';

Future<void> main(List<String> args) async {
  var parser = _createArgParser();
  var result = parser.parse(args);

  if (!_validArguments(parser, result)) {
    return;
  }

  var rootPath = result.rest[0];
  final targets = <Directory>[];
  if (Directory(rootPath).existsSync()) {
    targets.add(Directory(rootPath));
  } else {
    throw "Directory doesn't exist: $rootPath";
  }

  var options = CompletionMetricsOptions(result);
  var stopwatch = Stopwatch()..start();
  var client = _AnalysisServerClient(Directory(_sdk.sdkPath), targets);
  _CompletionClientMetricsComputer(rootPath, options, client).computeMetrics();
  stopwatch.stop();

  var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
  print('');
  print('Metrics computed in $duration');
}

final _Sdk _sdk = _Sdk._instance;

/// Given a data structure which is a Map of String to dynamic values, returns
/// the same structure (`Map<String, dynamic>`) with the correct runtime types.
Map<String, dynamic> _castStringKeyedMap(dynamic untyped) {
  final Map<dynamic, dynamic> map = untyped! as Map<dynamic, dynamic>;
  return map.cast<String, dynamic>();
}

/// Creates a parser that can be used to parse the command-line arguments.
ArgParser _createArgParser() {
  return ArgParser(
      usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : 80)
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Print this help message.',
    )
    ..addOption(
      CompletionMetricsOptions.OVERLAY,
      allowed: [
        OverlayMode.none.flag,
        OverlayMode.removeRestOfFile.flag,
        OverlayMode.removeToken.flag,
      ],
      defaultsTo: OverlayMode.none.flag,
      help: 'Before attempting a completion at the location of each token, the '
          'token can be removed, or the rest of the file can be removed to '
          'test code completion with diverse methods. The default mode is to '
          'complete at the start of the token without modifying the file.',
    )
    ..addOption(
      CompletionMetricsOptions.PREFIX_LENGTH,
      defaultsTo: '0',
      help: 'The number of characters to include in the prefix. Each '
          'completion will be requested this many characters in from the '
          'start of the token being completed.',
    )
    ..addFlag(
      CompletionMetricsOptions.PRINT_SLOWEST_RESULTS,
      defaultsTo: false,
      help: 'Print information about the completion requests that were the '
          'slowest to return suggestions.',
      negatable: false,
    );
}

/// Prints usage information for this tool.
void _printUsage(ArgParser parser, {String? error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print('usage: dart completion_metrics_client.dart [options] packagePath');
  print('');
  print('Compute code completion health metrics.');
  print('');
  print(parser.usage);
}

/// Trims [suffix] from the end of [text].
String _trimEnd(String text, String suffix) {
  if (text.endsWith(suffix)) {
    return text.substring(0, text.length - suffix.length);
  }
  return text;
}

/// Returns `true` if the command-line arguments (represented by the [result]
/// and parsed by the [parser]) are valid.
bool _validArguments(ArgParser parser, ArgResults result) {
  if (result.wasParsed('help')) {
    _printUsage(parser);
    return false;
  } else if (result.rest.length != 1) {
    _printUsage(parser, error: 'No package path specified.');
    return false;
  }
  return validateDir(parser, result.rest[0]);
}

class CompletionMetrics {
  /// A percentile computer which tracks the total time to create and send a
  /// completion request, and receive and decode a completion response, using
  /// 2.000 seconds as the max value to use in percentile calculations.
  final PercentileComputer totalPercentileComputer =
      PercentileComputer('ms for total duration', valueLimit: 2000);

  /// A percentile computer which tracks the time to send a completion request,
  /// and receive a completion response, not including any time to encode or
  /// decode, using 2.000 seconds as the max value to use in percentile
  /// calculations.
  final PercentileComputer requestResponsePercentileComputer =
      PercentileComputer('ms for request/response duration', valueLimit: 2000);

  /// A percentile computer which tracks the time to decode each completion
  /// response into JSON, using 2.000 seconds as the max value to use in
  /// percentile calculations.
  final PercentileComputer decodePercentileComputer =
      PercentileComputer('ms for decode duration', valueLimit: 2000);

  /// A percentile computer which tracks the time to deserialize each completion
  /// response JSON into Dart objects, using 2.000 seconds as the max value to
  /// use in percentile calculations.
  final PercentileComputer deserializePercentileComputer =
      PercentileComputer('ms for deserialize duration', valueLimit: 2000);
}

/// A client for communicating with the analysis server over stdin/stdout.
class _AnalysisServerClient {
  // This class is copied from package:dartdev/src/analysis_server.dart and
  // stripped.

  final Directory sdkPath;
  final List<FileSystemEntity> analysisRoots;

  Process? _process;

  /// When not null, this is a [Completer] which completes when analysis has
  /// finished, otherwise `null`.
  Completer<bool>? _analysisFinished;

  int _id = 0;

  bool _shutdownResponseReceived = false;

  final Map<String, StreamController<Map<String, dynamic>>> _streamControllers =
      {};

  final _onCrash = Completer<void>();

  final Map<String, Completer<Map<String, dynamic>>> _requestCompleters = {};

  final Map<String, _RequestMetadata> _requestMetadata = {};

  _AnalysisServerClient(this.sdkPath, this.analysisRoots);

  /// Completes when we next receive an analysis finished event (unless there's
  /// no current analysis and we've already received a complete event, in which
  /// case this future completes immediately).
  Future<bool>? get analysisFinished => _analysisFinished?.future;

  Stream<bool> get onAnalyzing {
    // {"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
    return _streamController('server.status')
        .stream
        .where((event) => event!['analysis'] != null)
        .map((event) => event!['analysis']['isAnalyzing']! as bool);
  }

  /// Completes when an analysis server crash has been detected.
  Future<void> get onCrash => _onCrash.future;

  Future<int> get onExit => _process!.exitCode;

  Future<AnalysisUpdateContentResult> addOverlay(
      String file, String content) async {
    final response = await _sendCommand(
      'analysis.updateContent',
      params: {
        'files': {
          file: {'type': 'add', 'content': content},
        }
      },
    );
    final result = response['result'] as Map<String, dynamic>;

    return AnalysisUpdateContentResult.fromJson(
      ResponseDecoder(null),
      'result',
      result,
    );
  }

  Future<bool> dispose() async {
    return _process?.kill() ?? true;
  }

  Future<AnalysisUpdateContentResult> removeOverlay(String file) async {
    final response = await _sendCommand(
      'analysis.updateContent',
      params: {
        'files': {
          file: {'type': 'remove'},
        }
      },
    );
    final result = response['result'] as Map<String, dynamic>;

    return AnalysisUpdateContentResult.fromJson(
      ResponseDecoder(null),
      'result',
      result,
    );
  }

  /// Requests a completion for [file] at [offset].
  Future<_SuggestionsData> requestCompletion(
      String file, int offset, int maxResults) async {
    final response = await _sendCommand('completion.getSuggestions2', params: {
      'file': file,
      'offset': offset,
      'maxResults': maxResults,
    });
    final result = response['result'] as Map<String, dynamic>;
    final metadata = _requestMetadata[response['id']]!;

    final deserializeStopwatch = Stopwatch()..start();
    final suggestionsResult = CompletionGetSuggestions2Result.fromJson(
      ResponseDecoder(null),
      'result',
      result,
    );
    deserializeStopwatch.stop();
    metadata.deserializeDuration = deserializeStopwatch.elapsedMilliseconds;

    return _SuggestionsData(suggestionsResult, metadata);
  }

  Future<void> shutdown({Duration timeout = const Duration(seconds: 5)}) async {
    // Request shutdown.
    await _sendCommand('server.shutdown').then((value) {
      _shutdownResponseReceived = true;
      return null;
    }).timeout(timeout, onTimeout: () async {
      logger.stderr('The analysis server timed out while shutting down.');
      await dispose();
    }).then((value) async {
      await dispose();
    });
  }

  Future<void> start({bool setAnalysisRoots = true}) async {
    final process = await _startDartProcess(_sdk, [
      _sdk.analysisServerSnapshot,
      '--${Driver.SUPPRESS_ANALYTICS_FLAG}',
      '--${Driver.CLIENT_ID}=completion-metrics-client',
      '--sdk',
      sdkPath.path,
    ]);
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
    errorStream.listen(logger.stderr);

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
        _trimEnd(
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
  }

  void _handleServerError(Map<String, dynamic>? error) {
    final err = error!;
    // Fields are 'isFatal', 'message', and 'stackTrace'.
    logger.stderr('Error from the analysis server: ${err['message']}');
    if (err['stackTrace'] != null) {
      logger.stderr(err['stackTrace'] as String);
    }
  }

  void _handleServerResponse(String line) {
    logger.trace('<== $line');

    var responseTime = DateTime.now().millisecondsSinceEpoch;

    final decodeStopwatch = Stopwatch()..start();
    final dynamic response = json.decode(line);
    decodeStopwatch.stop();
    var decodeDuration = decodeStopwatch.elapsedMilliseconds;

    if (response is Map<String, dynamic>) {
      if (response['event'] != null) {
        final event = response['event'] as String;
        final dynamic params = response['params'];

        if (params is Map<String, dynamic>) {
          _streamController(event).add(_castStringKeyedMap(params));
        }
      } else if (response['id'] != null) {
        final id = response['id'];
        final metadata = _requestMetadata[id]!;
        metadata.responseMilliseconds = responseTime;
        metadata.decodeDuration = decodeDuration;

        if (response['error'] != null) {
          final error = _castStringKeyedMap(response['error']);
          _requestCompleters
              .remove(id)
              ?.completeError(_RequestError.parse(error));
        } else {
          _requestCompleters.remove(id)?.complete(response);
        }
      }
    }
  }

  Future<Map<String, dynamic>> _sendCommand(String method,
      {Map<String, dynamic>? params}) {
    final String id = (++_id).toString();
    final String message = json.encode({
      'id': id,
      'method': method,
      'params': params,
    });
    _requestMetadata[id] =
        _RequestMetadata(DateTime.now().millisecondsSinceEpoch);
    _requestCompleters[id] = Completer();
    _process!.stdin.writeln(message);
    logger.trace('==> $message');
    return _requestCompleters[id]!.future;
  }

  /// A utility method to start a Dart VM instance with the given arguments and an
  /// optional current working directory.
  ///
  /// [arguments] should contain the snapshot path.
  Future<Process> _startDartProcess(
    _Sdk sdk,
    List<String> arguments, {
    String? cwd,
  }) {
    logger.trace('${sdk.dart} ${arguments.join(' ')}');
    return Process.start(sdk.dart, arguments, workingDirectory: cwd);
  }

  StreamController<Map<String, dynamic>?> _streamController(String streamId) {
    return _streamControllers.putIfAbsent(
        streamId, () => StreamController<Map<String, dynamic>>.broadcast());
  }
}

class _CompletionClientMetricsComputer extends CompletionMetricsComputer {
  final _AnalysisServerClient client;

  final CompletionMetrics targetMetric = CompletionMetrics();

  final metrics = CompletionMetrics();

  _CompletionClientMetricsComputer(super.rootPath, super.options, this.client);

  @override
  Future<void> applyOverlay(
    AnalysisContext context,
    String filePath,
    ExpectedCompletion expectedCompletion,
  ) async {
    if (options.overlay != OverlayMode.none) {
      final overlayContent = CompletionMetricsComputer.getOverlayContent(
        resolvedUnitResult.content,
        expectedCompletion,
        options.overlay,
        options.prefixLength,
      );

      provider.setOverlay(
        filePath,
        content: overlayContent,
        modificationStamp: overlayModificationStamp++,
      );
      await client.addOverlay(filePath, overlayContent);
    }
  }

  @override
  Future<void> computeMetrics() async {
    await client.start();
    await super.computeMetrics();
    await client.shutdown();

    // A row containing the name, median, p90, and p95 scores in [computer].
    List<String> m9095Row(PercentileComputer computer) => [
          computer.name,
          computer.median.toString(),
          computer.p90.toString(),
          computer.p95.toString(),
        ];

    var table = [
      ['', 'median', 'p90', 'p95'],
      m9095Row(metrics.totalPercentileComputer),
      m9095Row(metrics.requestResponsePercentileComputer),
      m9095Row(metrics.decodePercentileComputer),
      m9095Row(metrics.deserializePercentileComputer),
    ];

    rightJustifyColumns(table, range(1, table[0].length));
    printTable(table);
  }

  @override
  Future<void> computeSuggestionsAndMetrics(
    ExpectedCompletion expectedCompletion,
    AnalysisContext context,
    DocumentationCache documentationCache,
  ) async {
    var stopwatch = Stopwatch()..start();
    var suggestionsData = await client.requestCompletion(
        expectedCompletion.filePath, expectedCompletion.offset, 1000);
    stopwatch.stop();
    var metadata = suggestionsData.metadata;

    metrics.totalPercentileComputer.addValue(stopwatch.elapsedMilliseconds);
    metrics.requestResponsePercentileComputer
        .addValue(metadata.requestResponseDuration);
    metrics.decodePercentileComputer.addValue(metadata.decodeDuration);
    metrics.deserializePercentileComputer
        .addValue(metadata.deserializeDuration);
  }

  @override
  Future<void> removeOverlay(String filePath) async {
    if (options.overlay != OverlayMode.none) {
      await client.removeOverlay(filePath);
    }
  }

  @override
  void setupForResolution(AnalysisContext context) {}
}

class _RequestError {
  // This is copied from package:dartdev/src/analysis_server.dart.

  final String code;

  final String message;
  final String stackTrace;
  _RequestError(this.code, this.message, {required this.stackTrace});

  @override
  String toString() => '[RequestError code: $code, message: $message]';

  static _RequestError parse(dynamic error) {
    return _RequestError(
      error['code'] as String,
      error['message'] as String,
      stackTrace: error['stackTrace'] as String,
    );
  }
}

class _RequestMetadata {
  /// The timestamp of when a request was started, in milliseconds.
  ///
  /// This does not include the time it takes to encode the request into JSON.
  final int startMilliseconds;

  /// The timestamp of when a response was received, in milliseconds.
  late final int responseMilliseconds;

  /// The duration of decoding a response, in milliseconds.
  late final int decodeDuration;

  /// The duration of deserializing a response, in milliseconds.
  late final int deserializeDuration;

  _RequestMetadata(this.startMilliseconds);

  /// The duration of time between sending a completion request and receiving a
  /// completion response, not including the time to decode the response.
  int get requestResponseDuration => responseMilliseconds - startMilliseconds;
}

/// A utility class for finding and referencing paths within the Dart SDK.
class _Sdk {
  // This is copied from package:dartdev/src/sdk.dart and stripped.

  static final _Sdk _instance = _createSingleton();

  /// Path to SDK directory.
  final String sdkPath;

  factory _Sdk() => _instance;

  _Sdk._(this.sdkPath);

  String get analysisServerSnapshot => path.absolute(
        sdkPath,
        'bin',
        'snapshots',
        'analysis_server.dart.snapshot',
      );

  // Assume that we want to use the same Dart executable that we used to spawn
  // DartDev. We should be able to run programs with out/ReleaseX64/dart even
  // if the SDK isn't completely built.
  String get dart => Platform.resolvedExecutable;

  static _Sdk _createSingleton() {
    // Find SDK path.

    // The common case, and how cli_util.dart computes the Dart SDK directory,
    // [path.dirname] called twice on Platform.resolvedExecutable. We confirm by
    // asserting that the directory `./bin/snapshots/` exists in this directory:
    var sdkPath =
        path.absolute(path.dirname(path.dirname(Platform.resolvedExecutable)));
    var snapshotsDir = path.join(sdkPath, 'bin', 'snapshots');
    if (!Directory(snapshotsDir).existsSync()) {
      // This is the less common case where the user is in
      // the checked out Dart SDK, and is executing `dart` via:
      // ./out/ReleaseX64/dart ...
      // We confirm in a similar manner with the snapshot directory existence
      // and then return the correct sdk path:
      var altPath =
          path.absolute(path.dirname(Platform.resolvedExecutable), 'dart-sdk');
      var snapshotsDir = path.join(altPath, 'bin', 'snapshots');
      if (Directory(snapshotsDir).existsSync()) {
        sdkPath = altPath;
      }
      // If that snapshot dir does not exist either,
      // we use the first guess anyway.
    }

    return _Sdk._(sdkPath);
  }
}

/// A container which pairs a [CompletionGetSuggestions2Result] with the
/// [_RequestMetadata] which is associated with the result's completion request
/// and response.
class _SuggestionsData {
  final CompletionGetSuggestions2Result result;
  final _RequestMetadata metadata;

  _SuggestionsData(this.result, this.metadata);
}
