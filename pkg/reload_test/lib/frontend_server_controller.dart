// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend_server/starter.dart';

const frontEndResponsePrefix = 'result ';
const fakeBoundaryKey = '42';

final debug = false;

/// Represents the output of a FrontendServer's 'compile' or 'recompile'.
class CompilerOutput {
  CompilerOutput({
    required this.outputDillPath,
    required this.errorCount,
    this.sources = const [],
    this.outputText = '',
  });

  /// Output for a 'reject' response.
  factory CompilerOutput.rejectOutput() {
    return CompilerOutput(
      outputDillPath: '',
      errorCount: 0,
    );
  }

  final String outputDillPath;
  final int errorCount;
  final List<Uri> sources;
  final String outputText;
}

enum FrontendServerState {
  awaitingResult,
  awaitingKey,
  collectingResultSources,
  awaitingReject,
  awaitingRejectKey,
  finished,
}

/// Controls and synchronizes the Frontend Server during hot reloaad tests.
///
/// The Frontend Server accepts the following instructions:
/// > compile <input.dart>
///
/// > recompile [<input.dart>] <boundary-key>
///   <dart file>
///   <dart file>
///   ...
///   <boundary-key>
///
/// > accept
///
/// > quit
///
/// 'compile' and 'recompile' instructions output the following on completion:
///   result <boundary-key>
///   <boundary-key>
///   [<error text or modified files prefixed by '-' or '+'>]
///   <boundary-key> [<output.dill>] <error-count>
class HotReloadFrontendServerController {
  final List<String> frontendServerArgs;

  /// Used to send commands to the Frontend Server.
  final StreamController<List<int>> input;

  /// Contains output messages from the Frontend Server.
  final StreamController<List<int>> output;

  /// Contains one event per completed Frontend Server 'compile' or 'recompile'
  /// command.
  final StreamController<CompilerOutput> compileCommandOutputChannel;

  /// An iterator over `compileCommandOutputChannel`.
  /// Should be awaited after every 'compile' or 'recompile' command.
  final StreamIterator<CompilerOutput> synchronizer;

  /// Whether or not this controller has already been started.
  bool started = false;

  /// Initialize to an invalid string prior to the first result.
  String _boundaryKey = 'INVALID';

  late Future<int> frontendServerExitCode;

  /// Source file URIs reported by the Frontend Server.
  List<Uri> sources = [];

  List<String> accumulatedOutput = [];

  int totalErrors = 0;

  FrontendServerState _state = FrontendServerState.awaitingResult;

  HotReloadFrontendServerController._(this.frontendServerArgs, this.input,
      this.output, this.compileCommandOutputChannel, this.synchronizer);

  factory HotReloadFrontendServerController(List<String> frontendServerArgs) {
    var input = StreamController<List<int>>();
    var output = StreamController<List<int>>();
    var compileCommandOutputChannel = StreamController<CompilerOutput>();
    var synchronizer = StreamIterator(compileCommandOutputChannel.stream);
    return HotReloadFrontendServerController._(frontendServerArgs, input,
        output, compileCommandOutputChannel, synchronizer);
  }

  /// Runs the Frontend Server in-memory in incremental mode.
  /// Must be called once before interacting with the Frontend Server.
  void start() {
    if (started) {
      print('Frontend Server has already been started.');
      return;
    }

    output.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String s) {
      if (debug) print('Frontend Server Response: $s');
      switch (_state) {
        case FrontendServerState.awaitingReject:
          if (!s.startsWith(frontEndResponsePrefix)) {
            throw Exception('Unexpected Frontend Server response: $s');
          }
          _boundaryKey = s.substring(frontEndResponsePrefix.length);
          _state = FrontendServerState.awaitingRejectKey;
          break;
        case FrontendServerState.awaitingRejectKey:
          if (s != _boundaryKey) {
            throw Exception('Unexpected Frontend Server response for reject '
                '(expected just a key): $s');
          }
          _state = FrontendServerState.finished;
          compileCommandOutputChannel.add(CompilerOutput.rejectOutput());
          _clearState();
          break;
        case FrontendServerState.awaitingResult:
          if (!s.startsWith(frontEndResponsePrefix)) {
            throw Exception('Unexpected Frontend Server response: $s');
          }
          _boundaryKey = s.substring(frontEndResponsePrefix.length);
          _state = FrontendServerState.awaitingKey;
          break;
        case FrontendServerState.awaitingKey:
          // Advance to the next state when we encounter a lone boundary key.
          if (s == _boundaryKey) {
            _state = FrontendServerState.collectingResultSources;
          } else {
            accumulatedOutput.add(s);
          }
        case FrontendServerState.collectingResultSources:
          // Stop and record the result when we encounter a boundary key.
          if (s.startsWith(_boundaryKey)) {
            final compilationReportOutput = s.split(' ');
            final outputDillPath = compilationReportOutput[1];
            final errorCount = int.parse(compilationReportOutput[2]);
            // The FrontendServer accumulates all errors seen so far, so we
            // need to correct for errors from previous compilations.
            final actualErrorCount = errorCount - totalErrors;
            final compilerOutput = CompilerOutput(
              outputDillPath: outputDillPath,
              errorCount: actualErrorCount,
              sources: sources,
              outputText: accumulatedOutput.join('\n'),
            );
            totalErrors = errorCount;
            _state = FrontendServerState.finished;
            compileCommandOutputChannel.add(compilerOutput);
            _clearState();
          } else if (s.startsWith('+')) {
            sources.add(Uri.parse(s.substring(1)));
          } else if (s.startsWith('-')) {
            sources.remove(Uri.parse(s.substring(1)));
          } else {
            throw Exception("Unexpected Frontend Server response "
                "(expected '+' or '-')'): $s");
          }
          break;
        case FrontendServerState.finished:
          throw StateError('Frontend Server reached an unexpected state: $s');
      }
    });

    frontendServerExitCode = starter(
      frontendServerArgs,
      input: input.stream,
      output: IOSink(output.sink),
    );

    started = true;
  }

  /// Clears the controller's state between commands.
  ///
  /// Note: this does not reset the Frontend Server's state.
  void _clearState() {
    sources.clear();
    accumulatedOutput.clear();
    _boundaryKey = 'INVALID';
  }

  Future<CompilerOutput> sendCompile(String dartSourcePath) async {
    if (!started) throw Exception('Frontend Server has not been started yet.');
    _state = FrontendServerState.awaitingResult;
    final command = 'compile $dartSourcePath\n';
    if (debug) print('Sending instruction to Frontend Server:\n$command');
    input.add(command.codeUnits);
    await synchronizer.moveNext();
    return synchronizer.current;
  }

  Future<void> sendCompileAndAccept(String dartSourcePath) async {
    await sendCompile(dartSourcePath);
    sendAccept();
  }

  Future<CompilerOutput> sendRecompile(String entrypointPath,
      {List<String> invalidatedFiles = const [],
      String boundaryKey = fakeBoundaryKey}) async {
    if (!started) throw Exception('Frontend Server has not been started yet.');
    _state = FrontendServerState.awaitingResult;
    final command = 'recompile $entrypointPath $boundaryKey\n'
        '${invalidatedFiles.join('\n')}\n$boundaryKey\n';
    if (debug) print('Sending instruction to Frontend Server:\n$command');
    input.add(command.codeUnits);
    await synchronizer.moveNext();
    return synchronizer.current;
  }

  Future<void> sendRecompileAndAccept(String entrypointPath,
      {List<String> invalidatedFiles = const [],
      String boundaryKey = fakeBoundaryKey}) async {
    await sendRecompile(entrypointPath,
        invalidatedFiles: invalidatedFiles, boundaryKey: boundaryKey);
    sendAccept();
  }

  void sendAccept() {
    if (!started) throw Exception('Frontend Server has not been started yet.');
    final command = 'accept\n';
    if (debug) print('Sending instruction to Frontend Server:\n$command');
    input.add(command.codeUnits);
  }

  Future<void> sendReject() async {
    if (!started) throw Exception('Frontend Server has not been started yet.');
    _state = FrontendServerState.awaitingReject;
    final command = 'reject\n';
    if (debug) print('Sending instruction to Frontend Server:\n$command');
    input.add(command.codeUnits);
    await synchronizer.moveNext();
  }

  void _sendQuit() {
    if (!started) throw Exception('Frontend Server has not been started yet.');
    final command = 'quit\n';
    if (debug) print('Sending instruction to Frontend Server:\n$command');
    input.add(command.codeUnits);
  }

  /// Cleanly shuts down the Frontend Server.
  Future<void> stop() async {
    _sendQuit();
    var exitCode = await frontendServerExitCode;
    started = false;
    if (exitCode != 0) {
      print('Frontend Server exited with non-zero code: $exitCode');
      exit(exitCode);
    }
  }
}
