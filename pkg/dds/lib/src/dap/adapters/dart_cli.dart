// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pedantic/pedantic.dart';

import '../logging.dart';
import '../protocol_generated.dart';
import '../protocol_stream.dart';
import 'dart.dart';

/// A DAP Debug Adapter for running and debugging Dart CLI scripts.
class DartCliDebugAdapter extends DartDebugAdapter<DartLaunchRequestArguments> {
  Process? _process;

  @override
  final parseLaunchArgs = DartLaunchRequestArguments.fromJson;

  DartCliDebugAdapter(ByteStreamServerChannel channel, [Logger? logger])
      : super(channel, logger);

  /// Called by [disconnectRequest] to request that we forcefully shut down the
  /// app being run (or in the case of an attach, disconnect).
  FutureOr<void> disconnectImpl() {
    // TODO(dantup): In Dart-Code DAP, we first try again with SIGINT and wait
    // for a few seconds before sending sigkill.
    _process?.kill(ProcessSignal.sigkill);
  }

  /// Called by [launchRequest] to request that we actually start the app to be
  /// run/debugged.
  ///
  /// For debugging, this should start paused, connect to the VM Service, set
  /// breakpoints, and resume.
  Future<void> launchImpl() async {
    final vmPath = Platform.resolvedExecutable;
    final vmArgs = <String>[]; // TODO(dantup): enable-asserts, debug, etc.

    final processArgs = [
      ...vmArgs,
      args.program,
      ...?args.args,
    ];

    logger?.call('Spawning $vmPath with $processArgs in ${args.cwd}');
    final process = await Process.start(
      vmPath,
      processArgs,
      workingDirectory: args.cwd,
    );
    _process = process;

    process.stdout.listen(_handleStdout);
    process.stderr.listen(_handleStderr);
    unawaited(process.exitCode.then(_handleExitCode));
  }

  /// Called by [terminateRequest] to request that we gracefully shut down the
  /// app being run (or in the case of an attach, disconnect).
  FutureOr<void> terminateImpl() async {
    _process?.kill(ProcessSignal.sigint);
    await _process?.exitCode;
  }

  void _handleExitCode(int code) {
    final codeSuffix = code == 0 ? '' : ' ($code)';
    logger?.call('Process exited ($code)');
    // Always add a leading newline since the last written text might not have
    // had one.
    sendOutput('console', '\nExited$codeSuffix.');
    sendEvent(TerminatedEventBody());
  }

  void _handleStderr(List<int> data) {
    sendOutput('stderr', utf8.decode(data));
  }

  void _handleStdout(List<int> data) {
    sendOutput('stdout', utf8.decode(data));
  }
}
