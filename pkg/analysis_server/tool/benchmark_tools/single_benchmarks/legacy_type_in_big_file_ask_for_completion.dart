// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../language_server_benchmark.dart';
import '../legacy_messages.dart';
import '../run_utils.dart';

/// Changing the body of a big file; ask for completion.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LegacyTypingInBigFileAskForCompletion.new,
    createData,
    sizeOptions: [1000, 2000, 4000, 8000, 16000],
    extraIterations: (_) => [null],
    runAsLsp: false,
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
  int? offset;
  for (int i = 0; i < size; i++) {
    var className = 'Class$i';
    mainFileContent.write('''
class $className { // line 0 (in the first class)
  final int foo; // line 1 (in the first class)
  $className(this.foo) { // line 2 (in the first class)
    ''');
    offset ??= mainFileContent.length;
    mainFileContent.write(
      '''print("Hello from class $className"); // line 3 (in the first class)
    print("$className.foo = \$foo");
  }
}
''',
    );
  }
  var mainFileContentString = mainFileContent.toString();
  File.fromUri(mainFileUri).writeAsStringSync(mainFileContentString);

  return RunDetails(
    mainFile: FileContentPair(mainFileUri, mainFileContentString),
    offset: offset!,
  );
}

class FileContentPair {
  final Uri uri;
  final String content;

  FileContentPair(this.uri, this.content);
}

class LegacyTypingInBigFileAskForCompletion
    extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LegacyTypingInBigFileAskForCompletion(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: false);

  @override
  LaunchFrom get launchFrom => LaunchFrom.dart;

  @override
  Future<void> afterInitialization() async {
    await send(
      LegacyMessages.setPriorityFiles(largestIdSeen + 1, [
        runDetails.mainFile.uri,
      ]),
    );
    await send(
      LegacyMessages.updateContent(
        largestIdSeen + 1,
        runDetails.mainFile.uri,
        runDetails.mainFile.content,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    if (latestIsAnalyzing) {
      await waitWhileAnalyzing();
    }

    int? offset;

    for (int i = 0; i < 5; i++) {
      var nextUpdate = StringBuffer(
        runDetails.mainFile.content.substring(0, runDetails.offset),
      );
      if (i != 0) nextUpdate.write('foo;\n    ' * i);
      nextUpdate.write('fo');
      offset = nextUpdate.length;
      nextUpdate.write('\n    ');
      nextUpdate.write(
        runDetails.mainFile.content.substring(runDetails.offset),
      );
      var nextUpdateString = nextUpdate.toString();

      await Future.delayed(const Duration(milliseconds: 100));
      if (latestIsAnalyzing) {
        await waitWhileAnalyzing();
      }
      sendNoFlush(
        LegacyMessages.updateContent(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          nextUpdateString,
        ),
      );

      // And ask for completion.
      var completionRequest = await send(
        LegacyMessages.getSuggestions2(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          offset,
        ),
      );
      var stopwatch = Stopwatch()..start();
      await completionRequest!.completer.future;
      stopwatch.stop();
      durationInfo.add(DurationInfo('Completion #${i + 1}', stopwatch.elapsed));
    }

    // Now just for completion without changing first.
    for (int i = 0; i < 5; i++) {
      var completionRequest = await send(
        LegacyMessages.getSuggestions2(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          offset!,
        ),
      );
      var stopwatch = Stopwatch()..start();
      await completionRequest!.completer.future;
      stopwatch.stop();
      durationInfo.add(
        DurationInfo('Completion without change #${i + 1}', stopwatch.elapsed),
      );
    }

    if (latestIsAnalyzing) {
      await waitWhileAnalyzing();
    }
  }
}

class RunDetails {
  final FileContentPair mainFile;
  final int offset;

  RunDetails({required this.mainFile, required this.offset});
}
