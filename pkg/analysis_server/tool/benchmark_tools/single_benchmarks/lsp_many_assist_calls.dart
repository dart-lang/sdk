// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';

/// In a big file ask for assists many times (simulating the user using the
/// arrow keys to go back and forth on a line) and record the total time to do
/// it.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LspManyAssistCalls.new,
    createData,
    sizeOptions: [2000, 4000, 8000],
    extraIterations: getExtraIterations,
    runAsLsp: true,
  );
}

RunDetails createData(
  Uri packageDirUri,
  Uri outerDirForAdditionalData,
  int size,
  LineEndings? lineEnding,
  List<String> args, {
  // unused
  required dynamic extraInformation,
}) {
  Uri libDirUri = packageDirUri.resolve('lib/');
  Directory.fromUri(libDirUri).createSync();

  var uri = libDirUri.resolve('main.dart');
  var content = <String>[];
  for (int i = 0; i < size; i++) {
    var className = 'Class$i';
    content.add('class $className {');
    content.add('  final int foo;');
    content.add('  $className(this.foo) {');
    content.add('    print("Hello from class $className");');
    content.add('    print("$className.foo = \$foo");');
    content.add('  }');
    content.add('}');
  }
  var lineEndingString = lineEnding == LineEndings.Windows ? '\r\n' : '\n';
  var contentString = content.join(lineEndingString);
  File.fromUri(uri).writeAsStringSync(contentString);
  return RunDetails(
    mainFile: FileContentPair(uri, contentString),
    lineEnding: lineEndingString,
  );
}

List<LineEndings> getExtraIterations(List<String> args) {
  var lineEndings = LineEndings.values;
  for (String arg in args) {
    if (arg.startsWith('--types=')) {
      lineEndings = [];
      for (var type in arg.substring('--types='.length).split(',')) {
        type = type.toLowerCase();
        for (var value in LineEndings.values) {
          if (value.name.toLowerCase().contains(type)) {
            lineEndings.add(value);
          }
        }
      }
    }
  }
  return lineEndings;
}

class FileContentPair {
  final Uri uri;
  final String content;

  FileContentPair(this.uri, this.content);
}

enum LineEndings { Windows, Unix }

class LspManyAssistCalls extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LspManyAssistCalls(
    super.args,
    this.rootUri,
    this.cacheFolder,
    this.runDetails,
  ) : super(useLspProtocol: true);

  @override
  LaunchFrom get launchFrom => LaunchFrom.Dart;

  @override
  Future<void> afterInitialization() async {
    var lines = runDetails.mainFile.content.split(runDetails.lineEnding);
    await send(
      LspMessages.open(runDetails.mainFile.uri, 1, runDetails.mainFile.content),
    );

    Future<Duration> timeAssist(int lineNumber, int column) async {
      var codeActionStopwatch = Stopwatch()..start();
      var codeActionFuture = (await send(
        LspMessages.codeAction(
          largestIdSeen + 1,
          runDetails.mainFile.uri,
          line: lineNumber,
          character: column,
        ),
      ))!.completer.future.then((result) {
        codeActionStopwatch.stop();
        return result;
      });
      await codeActionFuture;
      return codeActionStopwatch.elapsed;
    }

    const lineNumber = 4;
    String line = lines[lineNumber];
    if (line != r'    print("Class0.foo = $foo");') {
      throw 'Unexpected change in benchmark.';
    }

    // Warmup.
    for (int i = 0; i < 100; i++) {
      await timeAssist(lineNumber, 0);
    }

    // Time 1,000 assist calls.
    int calls = 0;
    const int numCalls = 1000;
    Duration sum = Duration.zero;
    while (true) {
      for (int column = 0; column < line.length; column++) {
        var duration = await timeAssist(lineNumber, column);
        sum += duration;
        if (calls++ >= numCalls) break;
      }
      if (calls++ >= numCalls) break;
    }

    durationInfo.add(DurationInfo('$numCalls assist calls', sum));
  }
}

class RunDetails {
  final String lineEnding;
  final FileContentPair mainFile;

  RunDetails({required this.mainFile, required this.lineEnding});
}
