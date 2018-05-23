// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A tool that invokes the CFE to compute kernel summary files.
///
/// This script can be used as a command-line command or a persistent server.
/// The server is implemented using the bazel worker protocol, so it can be used
/// within bazel as is. Other tools (like pub-build and package-build) also
/// use this persistent worker via the same protocol.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:front_end/src/api_unstable/summary_worker.dart' as fe;
import 'package:kernel/ast.dart' show Component, Library;
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
  ..addFlag('help', negatable: false)
  ..addFlag('exclude-non-sources',
      negatable: false,
      help: 'Whether source files loaded implicitly should be included as '
          'part of the summary.')
  ..addOption('dart-sdk-summary')
  ..addOption('input-summary', allowMultiple: true)
  ..addOption('multi-root', allowMultiple: true)
  ..addOption('multi-root-scheme', defaultsTo: 'org-dartlang-multi-root')
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

  if (parsedArgs['help']) {
    print(summaryArgsParser.usage);
    exit(0);
  }

  // Bazel creates an overlay file system where some files may be located in the
  // source tree, some in a gendir, and some in a bindir. The multi-root file
  // system hides this from the front end.
  var multiRoots = parsedArgs['multi-root'].map(Uri.base.resolve).toList();
  if (multiRoots.isEmpty) multiRoots.add(Uri.base);
  var fileSystem = new MultiRootFileSystem(parsedArgs['multi-root-scheme'],
      multiRoots, fe.StandardFileSystem.instance);
  var sources = parsedArgs['source'].map(Uri.parse).toList();
  var state = await fe.initializeCompiler(
      // TODO(sigmund): pass an old state once we can make use of it.
      null,
      Uri.base.resolve(parsedArgs['dart-sdk-summary']),
      Uri.base.resolve(parsedArgs['packages-file']),
      parsedArgs['input-summary'].map(Uri.base.resolve).toList(),
      new SummaryTarget(sources, parsedArgs['exclude-non-sources'],
          new TargetFlags(strongMode: true)),
      fileSystem);

  void onProblem(fe.FormattedMessage message, severity,
      List<fe.FormattedMessage> context) {
    dynamic out = outputBuffer ?? stderr;
    out.println(message.formatted);
    for (fe.FormattedMessage message in context) {
      out.println(message.formatted);
    }
    if (severity != fe.Severity.nit) {
      succeeded = false;
    }
  }

  var summary = await fe.compile(state, sources, onProblem);

  if (summary != null) {
    var outputFile = new File(parsedArgs['output']);
    outputFile.createSync(recursive: true);
    outputFile.writeAsBytesSync(summary);
  } else {
    assert(!succeeded);
  }

  return succeeded;
}

/// A target that transforms outlines to meet the requirements of summaries in
/// bazel and package-build.
///
/// Build systems like package-build may provide the same input file twice to
/// the summary worker, but only intends to have it in one output summary.  The
/// convention is that if it is listed as a source, it is intended to be part of
/// the output, if the source file was loaded as a dependency, then it was
/// already included in a different summary.  The transformation below ensures
/// that the output summary doesn't include those implicit inputs.
///
/// Note: this transformation is destructive and is only intended to be used
/// when generating summaries.
class SummaryTarget extends NoneTarget {
  final List<Uri> sources;
  final bool excludeNonSources;

  SummaryTarget(this.sources, this.excludeNonSources, TargetFlags flags)
      : super(flags);

  @override
  void performOutlineTransformations(Component component) {
    if (!excludeNonSources) return;

    List<Library> libraries = new List.from(component.libraries);
    component.libraries.clear();
    Set<Uri> include = sources.toSet();
    for (var lib in libraries) {
      if (include.contains(lib.importUri)) {
        component.libraries.add(lib);
      } else {
        // Excluding the library also means that their canonical names will not
        // be computed as part of serialization, so we need to do that
        // preemtively here to avoid errors when serializing references to
        // elements of these libraries.
        component.root.getChildFromUri(lib.importUri).bindTo(lib.reference);
        lib.computeCanonicalNames();
      }
    }
  }
}
