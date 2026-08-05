// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/lsp/constants.dart' show CustomMethods;
import 'package:analysis_server/src/lsp/lsp_packet_transformer.dart';
import 'package:analysis_server/src/server/driver.dart' show Driver;
import 'package:args/args.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:language_server_protocol/protocol_special.dart';
import 'package:path/path.dart' as path;

import 'core.dart';
import 'experiments.dart';
import 'sdk.dart';

typedef ProcessFactory =
    Future<Process> Function(
      String executable,
      List<String> arguments,
    );

typedef _Id = Either2<int, String>;

/// A class to provide an API wrapper around an LSP analysis server process.
class LspAnalysisServer {
  LspAnalysisServer(
    this._packagesFile,
    this._sdkPath,
    this._analysisRoots, {
    this.cacheDirectoryPath,
    required this.commandName,
    required this.argResults,
    required this._usePlugins,
    this.enabledExperiments = const [],
    this.suppressAnalytics = false,
    this._useAotSnapshot = false,
    ProcessFactory? processFactory,
  }) : _processFactory =
           processFactory ??
           ((executable, arguments) => Process.start(executable, arguments));

  final ProcessFactory _processFactory;
  final String? cacheDirectoryPath;
  final File? _packagesFile;
  final Directory _sdkPath;
  final List<FileSystemEntity> _analysisRoots;
  final String commandName;
  final ArgResults? argResults;
  final List<String> enabledExperiments;
  final bool suppressAnalytics;
  final bool _useAotSnapshot;
  final bool _usePlugins;

  Process? _process;

  final StreamController<String> _outgoingMessages = StreamController<String>(
    sync: true,
  );

  int _id = 0;

  bool _shutdownResponseReceived = false;

  bool _serverErrorReceived = false;

  /// Whether any server error occurred that could mean analysis was not
  /// performed correctly.
  bool get serverErrorReceived => _serverErrorReceived;

  /// Waits for any in-progress initialization or analysis to complete.
  ///
  /// If the server shuts down unexpectedly, the returned future will complete
  /// with an error.
  Future<void> workspaceAnalysisComplete() {
    return _sendRequest(CustomMethods.workspaceAnalysisComplete);
  }

  Stream<PublishDiagnosticsParams> get onErrors {
    return _stream(
      Method.textDocument_publishDiagnostics,
      PublishDiagnosticsParams.fromJson,
    );
  }

  Future<int> _onExit = Future.value(0);

  /// A future that completes when the last spawned process exits with its exit
  /// code.
  ///
  /// If no process has been spawned, will return a completed Future with the
  /// value 0.
  Future<int> get onExit => _onExit;

  final Map<Method, StreamController<NotificationMessage>> _streamControllers =
      {};

  /// Whether the process has crashed.
  bool get hasCrashed => _onCrash.isCompleted;

  /// Completes when an analysis server crash has been detected.
  Future<void> get onCrash => _onCrash.future;

  final _onCrash = Completer<void>();

  /// Completers that will resolve with the responses for outbound
  /// client-to-server requests.
  final Map<_Id, Completer<ResponseMessage>> _requestCompleters = {};

  /// Starts the process, performs LSP initialization and returns the pid for it.
  Future<int> start({bool setAnalysisRoots = true}) async {
    if (_process != null) {
      throw StateError('Server process is already running');
    }

    final process = await _startProcess();
    _process = process;
    _onExit = process.exitCode;

    _outgoingMessages.stream
        .transform(LspPacketEncoder())
        .listen(process.stdin.add);

    _shutdownResponseReceived = false;
    // This callback hookup can't throw.
    process.exitCode.whenComplete(() {
      _process = null;

      if (!_shutdownResponseReceived) {
        // The process exited unexpectedly. Report the crash.
        // If `server.error` reported an error, that has been logged by
        // `_handleServerError`.

        final error = StateError('The analysis server crashed unexpectedly');

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

    final inStream = process.stdout.transform(LspPacketTransformer());
    inStream.listen(_handleServerMessage);

    _stream(
      Method.window_logMessage,
      LogMessageParams.fromJson,
    ).listen(_handleLogMessage);
    _stream(
      Method.window_showMessage,
      ShowMessageParams.fromJson,
    ).listen(_handleShowMessage);

    // The call to `absolute.resolveSymbolicLinksSync()` canonicalizes the path
    // to be passed to the analysis server.
    List<WorkspaceFolder> workspaceFolders = setAnalysisRoots
        ? _analysisRoots
              .map((root) => root.absolute.resolveSymbolicLinksSync())
              .map(
                (rootPath) => WorkspaceFolder(
                  name: path.basename(rootPath),
                  uri: Uri.file(
                    rootPath,
                  ),
                ),
              )
              .toList()
        : [];

    var initializeResult = await _expectSuccessfulResponse(
      Method.initialize,
      InitializeParams(
        capabilities: ClientCapabilities(
          textDocument: TextDocumentClientCapabilities(
            publishDiagnostics: PublishDiagnosticsClientCapabilities(
              // Allows us to get URLs in diagnostic codes.
              codeDescriptionSupport: true,
            ),
          ),
          experimental: {
            // Request the server includes fields like offset, length, type,
            // correctionMessage in Diagnostic.data. These fields are used in
            // the machine/JSON outputs of 'dart analyze' and we want to avoid
            // breaking potential consumers.
            'includeAdditionalDiagnosticData': true,
          },
        ),
        workspaceFolders: workspaceFolders,
      ),
      InitializeResult.fromJson,
    );
    var serverCapabilities = initializeResult.capabilities;
    var experimentalCapabilities = serverCapabilities.experimental;
    // TODO(dantup): This should never occur unless the server we have spawned
    //  is somehow older than this code change. Is it possible? How should we
    //  handle it?
    assert(experimentalCapabilities is Map<String, Object?>);
    assert(
      (experimentalCapabilities as Map<String, Object?>).containsKey(
        'workspaceAnalysisComplete',
      ),
    );

    _sendNotification(
      Method.initialized,
      InitializedParams(),
    );

    return process.pid;
  }

  Future<Process> _startProcess() {
    final executable = _useAotSnapshot ? sdk.dartAotRuntime : sdk.dart;
    final arguments = [
      if (_useAotSnapshot)
        sdk.analysisServerAotSnapshot
      else
        sdk.analysisServerSnapshot,
      if (suppressAnalytics) '--${Driver.suppressAnalyticsFlag}',
      '--${Driver.clientIdOption}=dart-$commandName',
      '--disable-server-feature-completion',
      '--disable-server-feature-search',
      '--disable-silent-analysis-exceptions',
      '--sdk',
      _sdkPath.path,
      if (cacheDirectoryPath != null) '--cache=$cacheDirectoryPath',
      if (_packagesFile != null) '--packages=${_packagesFile.path}',
      if (enabledExperiments.isNotEmpty)
        '--$experimentFlagName=${enabledExperiments.join(',')}',
      if (!_usePlugins) '--no-plugins',
      '--protocol=lsp',
    ];

    log.trace('$executable ${arguments.join(' ')}');
    return _processFactory(executable, arguments);
  }

  /// Sends a hover request.
  Future<Hover?> getHover(Uri uri, Position pos) {
    return _expectSuccessfulResponse(
      Method.textDocument_hover,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
      Hover.fromJson,
    );
  }

  /// Sends a migrate request.
  Future<DartMigrateResult?> migrate(
    List<Uri> uris, {
    bool? apply,
    List<MigrationStep>? steps,
  }) {
    return _expectSuccessfulResponse(
      CustomMethods.migrate,
      DartMigrateParams(
        uris: uris,
        apply: apply,
        steps: steps,
      ),
      DartMigrateResult.fromJson,
    );
  }

  Future<void> shutdown({Duration? timeout}) async {
    // Request shutdown.
    var future = _gracefulShutdown();
    if (timeout != null) {
      future = future.timeout(
        timeout,
        onTimeout: () {
          log.stderr('The analysis server timed out while shutting down.');
        },
      );
    }
    await future.whenComplete(dispose);
  }

  /// Attempt a graceful shutdown and wait for the process to exit.
  Future<void> _gracefulShutdown() async {
    try {
      await _sendRequest(Method.shutdown);
      _shutdownResponseReceived = true;
    } catch (_) {}
    try {
      _sendNotification(Method.exit);
    } catch (_) {}
    await _process?.exitCode;
  }

  void _sendLsp(Message message) {
    final json = jsonEncode(message.toJson());
    log.trace('==> $json');
    _outgoingMessages.add(json);
  }

  void _sendNotification(Method method, [Object? params]) {
    final message = NotificationMessage(
      method: method,
      params: params is ToJsonable ? params.toJson() : params,
      jsonrpc: jsonRpcVersion,
    );

    _sendLsp(message);
  }

  Future<ResponseMessage> _sendRequest(Method method, [Object? params]) {
    final id = _Id.t1(++_id);
    final message = RequestMessage(
      id: id,
      method: method,
      params: params is ToJsonable ? params.toJson() : params,
      jsonrpc: jsonRpcVersion,
    );

    final completer = _requestCompleters[id] = Completer<ResponseMessage>();

    _sendLsp(message);

    return completer.future;
  }

  void _handleLogMessage(LogMessageParams message) {
    if (message.type == MessageType.Error) {
      _handleServerError(message.message);
    }
  }

  void _handleServerMessage(String line) {
    log.trace('<== $line');

    final response = json.decode(line) as Object?;

    if (response is Map<String, Object?>) {
      var message = Message.fromJson(response);
      switch (message) {
        case NotificationMessage():
          _streamControllers[message.method]?.add(message);
          break;
        case RequestMessage():
          // We don't expect reverse-requests from the server in this mode.
          break;
        case ResponseMessage():
          _requestCompleters.remove(message.id)?.complete(message);
          break;
      }
    }
  }

  void _handleServerError(String message, [String? stackTrace]) {
    _serverErrorReceived = true;
    log.stderr('An unexpected error was encountered by the Analysis Server.');
    log.stderr(
      'Please file an issue at '
      'https://github.com/dart-lang/sdk/issues/new/choose with the following '
      'details:\n',
    );
    log.stderr(message);
    if (stackTrace case String(isNotEmpty: true)) {
      log.stderr(stackTrace);
    }
  }

  void _handleShowMessage(ShowMessageParams message) {
    if (message.type == MessageType.Error) {
      _handleServerError(message.message);
    }
  }

  Stream<T> _stream<T, R>(Method method, T Function(R) converter) {
    final controller = _streamControllers.putIfAbsent(
      method,
      () => StreamController<NotificationMessage>.broadcast(),
    );
    return controller.stream
        .map((message) => message.params)
        .cast<R>()
        .map(converter);
  }

  bool dispose() {
    return _process?.kill() ?? true;
  }

  Future<T> _expectSuccessfulResponse<T, R>(
    Method method,
    Object? params,
    T Function(R) converter,
  ) async {
    var response = await _sendRequest(method, params);

    if (response.error case var error?) {
      throw _RequestError(error);
    }

    return converter(response.result as R);
  }
}

class _RequestError implements Exception {
  final ResponseError error;

  _RequestError(this.error);

  @override
  String toString() => 'LspException: ${error.code}: ${error.message}';
}
