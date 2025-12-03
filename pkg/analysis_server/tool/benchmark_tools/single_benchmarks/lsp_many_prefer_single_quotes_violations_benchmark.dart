// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';

/// Create a single file with a variable amount of double-quotes in it that will
/// violate the prefer_single_quites lint. Pretend to be a user in an IDE moving
/// the cursor a bit and then selecting everything.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LspManyPreferSingleQuotesViolationsBenchmark.new,
    createData,
    // Currently going higher is very slow.
    // For the select-all one I get:
    // * 50: 0.310976 seconds
    // * 100: 1.054733 seconds
    // * 200: 5.535353 seconds
    // * 400: 36.099675 seconds
    // * 800: 247.919461 seconds
    sizeOptions: [25, 50, 100, 200],
    extraIterations: (_) => [null],
    runAsLsp: true,
  );
}

RunDetails createData(
  Uri packageDirUri,
  Uri outerDirForAdditionalData,
  int size,
  dynamic unused,
  List<String> args, {
  // unused
  required dynamic extraInformation,
}) {
  Uri libDirUri = packageDirUri.resolve('lib/');
  Directory.fromUri(libDirUri).createSync();

  // Write analysis_options.
  File.fromUri(
    packageDirUri.resolve('analysis_options.yaml'),
  ).writeAsStringSync('''
linter:
  rules:
    - prefer_single_quotes
''');

  var mainFileUri = libDirUri.resolve('main.dart');
  var mainFileContent = StringBuffer();
  mainFileContent.writeln('Map<String, String> foo = {');
  for (int i = 0; i < size; i++) {
    mainFileContent.writeln('"$i": "$i",');
  }
  mainFileContent.writeln('};');
  var mainFileContentString = mainFileContent.toString();
  File.fromUri(mainFileUri).writeAsStringSync(mainFileContentString);

  return RunDetails(
    mainFile: FileContentPair(mainFileUri, mainFileContentString),
  );
}

class FileContentPair {
  final Uri uri;
  final String content;

  FileContentPair(this.uri, this.content);
}

class LspManyPreferSingleQuotesViolationsBenchmark
    extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LspManyPreferSingleQuotesViolationsBenchmark(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: true);

  @override
  LaunchFrom get launchFrom => LaunchFrom.dart;

  @override
  Future<void> afterInitialization() async {
    int lines = runDetails.mainFile.content.split('\n').length;
    await send(
      LspMessages.open(runDetails.mainFile.uri, 1, runDetails.mainFile.content),
    );

    // Send 'textDocument/codeAction'...
    var codeActionStopwatch = Stopwatch()..start();
    await (await send(
      LspMessages.codeAction(
        largestIdSeen + 1,
        runDetails.mainFile.uri,
        // Basically on the quote in `: "1"`
        line: 1,
        character: 7,
      ),
    ))!.completer.future;
    codeActionStopwatch.stop();
    durationInfo.add(
      DurationInfo('First code action call', codeActionStopwatch.elapsed),
    );

    for (int i = 1; i <= 2; i++) {
      var codeActionStopwatch = Stopwatch()..start();
      await (await send(
        LspMessages.codeAction(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          // Basically on the quote in `: "2"` (etc)
          line: 1 + i,
          character: 7,
        ),
      ))!.completer.future;
      codeActionStopwatch.stop();
      durationInfo.add(
        DurationInfo('Subsequent action call $i', codeActionStopwatch.elapsed),
      );
    }

    {
      var codeActionStopwatch = Stopwatch()..start();
      // The user seelects all (or, at lest a big chunk) and the IDE
      // sends a code action request for the selected range.
      await (await send(
        LspMessages.codeActionRange(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          lineFrom: 0,
          characterFrom: 0,
          lineTo: lines - 1,
          characterTo: 0,
        ),
      ))!.completer.future;
      codeActionStopwatch.stop();
      durationInfo.add(
        DurationInfo(
          'Select all code action call',
          codeActionStopwatch.elapsed,
        ),
      );
    }
  }
}

class RunDetails {
  final FileContentPair mainFile;

  RunDetails({required this.mainFile});
}
