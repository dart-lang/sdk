// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';

/// Request "semanticTokens/full" in a big file.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LspRequestSemanticTokenFull.new,
    createData,
    sizeOptions: [1000, 2000, 4000, 8000, 16000],
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

  var mainFileUri = libDirUri.resolve('main.dart');
  var mainFileContent = StringBuffer();
  for (int i = 0; i < size; i++) {
    var className = 'Class$i';
    mainFileContent.write('''
class $className { // line 0 (in the first class)
  final int foo; // line 1 (in the first class)
  $className(this.foo) { // line 2 (in the first class)
    print("Hello from class $className"); // line 3 (in the first class)
    print("$className.foo = \$foo");
  }
}
''');
  }
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

class LspRequestSemanticTokenFull extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LspRequestSemanticTokenFull(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: true);

  @override
  LaunchFrom get launchFrom => LaunchFrom.Dart;

  @override
  Future<void> afterInitialization() async {
    await send(
      LspMessages.open(runDetails.mainFile.uri, 1, runDetails.mainFile.content),
    );

    // Get colors just to make sure everything is analyzed.
    await (await send(
      LspMessages.documentColor(runDetails.mainFile.uri, largestIdSeen + 1),
    ))!.completer.future;

    for (int i = 0; i < 5; i++) {
      // The below is a replay of a recorded actual IDE interaction.
      var allStopwatch = Stopwatch()..start();

      // Send semanticTokens/full request.
      await (await send(
        LspMessages.semanticTokensFull(
          runDetails.mainFile.uri,
          largestIdSeen + 1,
        ),
      ))!.completer.future;

      var elapsedWholeThing = allStopwatch.elapsed;

      if (latestIsAnalyzing) {
        await waitWhileAnalyzing();
        elapsedWholeThing = allStopwatch.elapsed;
      }
      durationInfo.add(
        DurationInfo('Semantics tokens full request ($i)', elapsedWholeThing),
      );
    }
  }
}

class RunDetails {
  final FileContentPair mainFile;

  RunDetails({required this.mainFile});
}
