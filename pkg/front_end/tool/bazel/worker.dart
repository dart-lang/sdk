// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:front_end/front_end.dart' hide FileSystemException;
import 'package:front_end/src/fasta/command_line_reporting.dart';
import 'package:kernel/target/targets.dart';

main(List<String> args) async {
  args = preprocessArgs(args);

  if (args.contains('--persistent_worker')) {
    if (args.length != 1) {
      throw new StateError(
          "unexpected args, expected only --persistent-worker but got: $args");
    }
    await new SummaryWorker().run();
  } else {
    var succeeded = await computeSummary(args);
    if (!succeeded) {
      exitCode = 15;
    }
  }
}

/// A bazel worker loop that can compute summaries.
class SummaryWorker extends AsyncWorkerLoop {
  Future<WorkResponse> performRequest(WorkRequest request) async {
    var outputBuffer = new StringBuffer();
    var response = new WorkResponse()..exitCode = 0;
    try {
      var succeeded = await computeSummary(request.arguments,
          isWorker: true, outputBuffer: outputBuffer);
      if (!succeeded) {
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

/// If the last arg starts with `@`, this reads the file it points to and treats
/// each line as an additional arg.
///
/// This is how individual work request args are differentiated from startup
/// args in bazel (inidividual work request args go in that file).
List<String> preprocessArgs(List<String> args) {
  args = new List.from(args);
  if (args.isEmpty) {
    return args;
  }
  String lastArg = args.last;
  if (lastArg.startsWith('@')) {
    File argsFile = new File(lastArg.substring(1));
    try {
      args.removeLast();
      args.addAll(argsFile.readAsLinesSync());
    } on FileSystemException catch (e) {
      throw new Exception('Failed to read file specified by $lastArg : $e');
    }
  }
  return args;
}

/// An [ArgParser] for generating kernel summaries.
final summaryArgsParser = new ArgParser()
  ..addOption('dart-sdk-summary')
  ..addOption('input-summary', allowMultiple: true)
  ..addOption('multi-root', allowMultiple: true)
  ..addOption('packages-file')
  ..addOption('source', allowMultiple: true)
  ..addOption('output');

/// Computes a kernel summary based on [args].
///
/// If [isWorker] is true then exit codes will not be set on failure.
///
/// If [outputBuffer] is provided then messages will be written to that buffer
/// instead of printed to the console.
///
/// Returns whether or not the summary was successfully output.
Future<bool> computeSummary(List<String> args,
    {bool isWorker: false, StringBuffer outputBuffer}) async {
  bool succeeded = true;
  var parsedArgs = summaryArgsParser.parse(args);
  var options = new CompilerOptions()
    ..packagesFileUri = Uri.parse(parsedArgs['packages-file'])
    ..inputSummaries = parsedArgs['input-summary'].map(Uri.parse).toList()
    ..sdkSummary = Uri.parse(parsedArgs['dart-sdk-summary'])
    ..multiRoots = parsedArgs['multi-root'].map(Uri.parse).toList()
    ..target = new NoneTarget(new TargetFlags());

  options.onError = (CompilationMessage error) {
    var message = new StringBuffer()
      ..write(severityName(error.severity, capitalized: true))
      ..write(': ');
    if (error.span != null) {
      message.writeln(error.span.message(error.message));
    } else {
      message.writeln(error.message);
    }
    if (error.tip != null) {
      message.writeln(error.tip);
    }
    if (outputBuffer != null) {
      outputBuffer.writeln(message);
    } else {
      print(message);
    }
    if (error.severity != Severity.nit) {
      succeeded = false;
    }
  };

  var sources = parsedArgs['source'].map(Uri.parse).toList();
  var program = await summaryFor(sources, options);

  var outputFile = new File(parsedArgs['output']);
  outputFile.createSync(recursive: true);
  outputFile.writeAsBytesSync(program);

  return succeeded;
}
