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

// 'compile' and 'recompile' instructions output the following on completion:
//   result <boundary-key>
//   <compiler output>
//   <boundary-key> [<output.dill>]
class HotReloadFrontendServerController {
  final List<String> frontendServerArgs;

  /// Used to send commands to the Frontend Server.
  final StreamController<List<int>> input;

  /// Contains output messages from the Frontend Server.
  final StreamController<List<int>> output;

  /// Contains one event per completed Frontend Server 'compile' or 'recompile'
  /// command.
  final StreamController<String> compileCommandOutputChannel;

  /// An iterator over `compileCommandOutputChannel`.
  /// Should be awaited after every 'compile' or 'recompile' command.
  final StreamIterator<String> synchronizer;

  bool started = false;
  String? _boundaryKey;
  late Future<int> frontendServerExitCode;

  HotReloadFrontendServerController._(this.frontendServerArgs, this.input,
      this.output, this.compileCommandOutputChannel, this.synchronizer);

  factory HotReloadFrontendServerController(List<String> frontendServerArgs) {
    var input = StreamController<List<int>>();
    var output = StreamController<List<int>>();
    var compileCommandOutputChannel = StreamController<String>();
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
      if (_boundaryKey == null) {
        if (s.startsWith(frontEndResponsePrefix)) {
          _boundaryKey = s.substring(frontEndResponsePrefix.length);
        }
      } else {
        if (s.startsWith(_boundaryKey!)) {
          compileCommandOutputChannel.add(_boundaryKey!);
          _boundaryKey = null;
        }
      }
    });

    frontendServerExitCode = starter(
      frontendServerArgs,
      input: input.stream,
      output: IOSink(output.sink),
    );

    started = true;
  }

  Future<void> sendCompile(String dartSourcePath) async {
    if (!started) {
      throw Exception('Frontend Server has not been started yet.');
    }
    final command = 'compile $dartSourcePath\n';
    if (debug) {
      print('Sending instruction to Frontend Server:\n$command');
    }
    input.add(command.codeUnits);
    await synchronizer.moveNext();
  }

  Future<void> sendCompileAndAccept(String dartSourcePath) async {
    await sendCompile(dartSourcePath);
    sendAccept();
  }

  Future<void> sendRecompile(String entrypointPath,
      {List<String> invalidatedFiles = const [],
      String boundaryKey = fakeBoundaryKey}) async {
    if (!started) {
      throw Exception('Frontend Server has not been started yet.');
    }
    final command = 'recompile $entrypointPath $boundaryKey\n'
        '${invalidatedFiles.join('\n')}\n$boundaryKey\n';
    if (debug) {
      print('Sending instruction to Frontend Server:\n$command');
    }
    input.add(command.codeUnits);
    await synchronizer.moveNext();
  }

  Future<void> sendRecompileAndAccept(String entrypointPath,
      {List<String> invalidatedFiles = const [],
      String boundaryKey = fakeBoundaryKey}) async {
    await sendRecompile(entrypointPath,
        invalidatedFiles: invalidatedFiles, boundaryKey: boundaryKey);
    sendAccept();
  }

  void sendAccept() {
    if (!started) {
      throw Exception('Frontend Server has not been started yet.');
    }
    final command = 'accept\n';
    // TODO(markzipan): We should reject certain invalid compiles (e.g., those
    // with unimplemented or invalid nodes).
    if (debug) {
      print('Sending instruction to Frontend Server:\n$command');
    }
    input.add(command.codeUnits);
  }

  void _sendQuit() {
    if (!started) {
      throw Exception('Frontend Server has not been started yet.');
    }
    final command = 'quit\n';
    if (debug) {
      print('Sending instruction to Frontend Server:\n$command');
    }
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
