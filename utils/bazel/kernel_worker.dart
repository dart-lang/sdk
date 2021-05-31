// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.8

/// A tool that invokes the CFE to compute kernel summary files.
///
/// This script can be used as a command-line command or a persistent server.
/// The server is implemented using the bazel worker protocol, so it can be used
/// within bazel as is. Other tools (like pub-build and package-build) also
/// use this persistent worker via the same protocol.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:front_end/src/api_unstable/bazel_worker.dart' as fe;
import 'package:frontend_server/compute_kernel.dart';

/// [sendPort] may be passed in when started in an isolate. If provided, it is
/// used for bazel worker communication instead of stdin/stdout.
main(List<String> args, SendPort sendPort) async {
  args = preprocessArgs(args);

  if (args.contains('--persistent_worker')) {
    if (args.length != 1) {
      throw new StateError(
          "unexpected args, expected only --persistent-worker but got: $args");
    }
    await new KernelWorker(sendPort: sendPort).run();
  } else {
    var result = await computeKernel(args);
    if (!result.succeeded) {
      exitCode = 15;
    }
  }
}

/// A bazel worker loop that can compute full or summary kernel files.
class KernelWorker extends AsyncWorkerLoop {
  fe.InitializedCompilerState previousState;

  /// If [sendPort] is provided it is used for bazel worker communication
  /// instead of stdin/stdout.
  KernelWorker({SendPort sendPort})
      : super(
            connection: sendPort == null
                ? null
                : SendPortAsyncWorkerConnection(sendPort));

  Future<WorkResponse> performRequest(WorkRequest request) async {
    var outputBuffer = new StringBuffer();
    var response = new WorkResponse()..exitCode = 0;
    try {
      fe.InitializedCompilerState previousStateToPass;
      if (request.arguments.contains("--reuse-compiler-result")) {
        previousStateToPass = previousState;
      } else {
        previousState = null;
      }

      /// Build a map of uris to digests.
      final inputDigests = <Uri, List<int>>{};
      for (var input in request.inputs) {
        inputDigests[toUri(input.path)] = input.digest;
      }

      var result = await computeKernel(request.arguments,
          isWorker: true,
          outputBuffer: outputBuffer,
          inputDigests: inputDigests,
          previousState: previousStateToPass);
      previousState = result.previousState;
      if (!result.succeeded) {
        response.exitCode = 15;
      }
    } catch (e, s) {
      outputBuffer.writeln(e);
      outputBuffer.writeln(s);
      response.exitCode = 15;
    }
    response.output = outputBuffer.toString();
    return response;
  }
}
