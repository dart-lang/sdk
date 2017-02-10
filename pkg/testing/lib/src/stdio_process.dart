// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.stdio_process;

import 'dart:async' show
    Future,
    Timer;

import 'dart:convert' show
    UTF8;

import 'dart:io' show
    Process,
    ProcessSignal;

import 'chain.dart' show
    Result;

class StdioProcess {
  final int exitCode;

  final String output;

  StdioProcess(this.exitCode, this.output);

  Result<int> toResult({int expected: 0}) {
    if (exitCode == expected) {
      return new Result<int>.pass(exitCode);
    } else {
      return new Result<int>.fail(exitCode, output);
    }
  }

  static Future<StdioProcess> run(
      String executable, List<String> arguments,
      {String input, Duration timeout: const Duration(seconds: 60)}) async {
    Process process = await Process.start(executable, arguments);
    Timer timer;
    StringBuffer sb = new StringBuffer();
    timer = new Timer(timeout, () {
      sb.write("Process timed out: ");
      sb.write(executable);
      sb.write(" ");
      sb.writeAll(arguments, " ");
      sb.writeln();
      sb.writeln("Sending SIGTERM to process");
      process.kill();
      timer = new Timer(const Duration(seconds: 10), () {
        sb.writeln("Sending SIGKILL to process");
        process.kill(ProcessSignal.SIGKILL);
      });
    });
    if (input != null) {
      process.stdin.write(input);
      await process.stdin.flush();
    }
    Future closeFuture = process.stdin.close();
    Future<List<String>> stdoutFuture =
        process.stdout.transform(UTF8.decoder).toList();
    Future<List<String>> stderrFuture =
        process.stderr.transform(UTF8.decoder).toList();
    int exitCode = await process.exitCode;
    timer.cancel();
    sb.writeAll(await stdoutFuture);
    sb.writeAll(await stderrFuture);
    await closeFuture;
    return new StdioProcess(exitCode, "$sb");
  }
}
