// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';

/// Changing the body of a big file; ask for completion.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LspTypingInBigFileAskForCompletion.new,
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
    addAtLine: 3,
  );
}

class FileContentPair {
  final Uri uri;
  final String content;

  FileContentPair(this.uri, this.content);
}

class LspTypingInBigFileAskForCompletion extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LspTypingInBigFileAskForCompletion(
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

    await Future.delayed(const Duration(milliseconds: 100));
    if (latestIsAnalyzing) {
      await waitWhileAnalyzing();
    }

    // Start typing "foo" on a new line (only typing 'fo')
    var write = '    fo';
    var writeAdditionallyFront = '';
    var writeAdditionallyBack = '\n';
    int? line;
    int? column;
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (latestIsAnalyzing) {
        await waitWhileAnalyzing();
      }

      sendNoFlush(
        LspMessages.didChange(
          runDetails.mainFile.uri,
          version: i + 2,
          insertAtLine: runDetails.addAtLine + (i == 0 ? 0 : i - 1),
          insertAtCharacter: i == 0 ? 0 : write.length,
          insert: '$writeAdditionallyFront$write$writeAdditionallyBack',
        ),
      );

      line = runDetails.addAtLine + i;
      column = write.length;

      // And ask for completion.
      var completionRequest = await send(
        LspMessages.completion(
          runDetails.mainFile.uri,
          largestIdSeen + 1,
          line: line,
          character: column,
        ),
      );
      var stopwatch = Stopwatch()..start();
      await completionRequest!.completer.future;
      stopwatch.stop();
      durationInfo.add(DurationInfo('Completion #${i + 1}', stopwatch.elapsed));

      writeAdditionallyFront = 'o;\n';
      writeAdditionallyBack = '';
    }

    // Now just for completion without changing first.
    for (int i = 0; i < 5; i++) {
      var completionRequest = await send(
        LspMessages.completion(
          runDetails.mainFile.uri,
          largestIdSeen + 1,
          line: line!,
          character: column!,
        ),
      );
      var stopwatch = Stopwatch()..start();
      await completionRequest!.completer.future;
      stopwatch.stop();
      durationInfo.add(
        DurationInfo('Completion without change #${i + 1}', stopwatch.elapsed),
      );
    }
  }
}

class RunDetails {
  final FileContentPair mainFile;
  final int addAtLine;

  RunDetails({required this.mainFile, required this.addAtLine});
}
