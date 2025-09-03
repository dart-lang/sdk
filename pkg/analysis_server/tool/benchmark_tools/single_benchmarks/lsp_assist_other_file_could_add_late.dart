// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';

/// Small file imports big file. Asking for assists in possitions in the small
/// file should not be expensive (i.e. should not require loading more of the
/// big file).
/// Previously the "add late" assist would load the big file and make this slow.
Future<void> main(List<String> args) async {
  await runHelper(
    args,
    LspAssistLate.new,
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

  {
    var libUri = libDirUri.resolve('lib.dart');
    var libContent = StringBuffer();
    for (int i = 0; i < size; i++) {
      var className = 'Class$i';
      libContent.write('''
class $className {
  final int foo;
  $className(this.foo) {
    print("Hello from class $className");
    print("$className.foo = \$foo");
  }
}
''');
    }
    var libContentString = libContent.toString();
    File.fromUri(libUri).writeAsStringSync(libContentString);
  }

  var mainFileUri = libDirUri.resolve('main.dart');
  var mainFileContentString = '''
import 'lib.dart';

void main() {
  var c1 = Class1(42);
  print(c1.foo);
}
''';
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

class LspAssistLate extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  final RunDetails runDetails;

  LspAssistLate(super.args, this.rootUri, this.cacheFolder, this.runDetails)
    : super(useLspProtocol: true);

  @override
  LaunchFrom get launchFrom => LaunchFrom.Dart;

  @override
  Future<void> afterInitialization() async {
    var lines = runDetails.mainFile.content.split('\n');
    await send(
      LspMessages.open(runDetails.mainFile.uri, 1, runDetails.mainFile.content),
    );

    Future<Duration> timeAssist(int lineNumber, int column) async {
      var codeActionStopwatch = Stopwatch()..start();
      var codeActionFuture =
          (await send(
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
    if (line != '  print(c1.foo);') {
      throw 'Unexpected change in benchmark.';
    }

    // Warmup.
    for (int i = 0; i < 10; i++) {
      await timeAssist(lineNumber, 0);
    }

    for (int column = 11; column < 14; column++) {
      var duration = await timeAssist(lineNumber, column);
      durationInfo.add(
        DurationInfo('Action call on $lineNumber:$column ', duration),
      );
    }
  }
}

class RunDetails {
  final FileContentPair mainFile;

  RunDetails({required this.mainFile});
}
