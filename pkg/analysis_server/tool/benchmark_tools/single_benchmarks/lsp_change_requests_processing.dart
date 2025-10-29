// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/lsp/handlers/handler_text_document_changes.dart';

import '../language_server_benchmark.dart';
import '../lsp_messages.dart';
import '../run_utils.dart';

/// Changing the body of a big file; get stats on the actual change request
/// processing.
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
    // In the first line of the body of the middle class.
    addAtLine: 3 + (size ~/ 2) * 7,
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

    var diagnosticServer = await (await send(
      LspMessages.diagnosticServer(largestIdSeen + 1),
    ))!.completer.future;
    var diagnosticServerPort = diagnosticServer['result']['port'];

    // Get colors just to make sure everything is analyzed.
    await (await send(
      LspMessages.documentColor(runDetails.mainFile.uri, largestIdSeen + 1),
    ))!.completer.future;

    await Future.delayed(const Duration(milliseconds: 100));
    if (latestIsAnalyzing) {
      await waitWhileAnalyzing();
    }

    const requestCount = 25;

    for (int i = 0; i < requestCount; i++) {
      await send(
        LspMessages.didChange(
          runDetails.mainFile.uri,
          version: i + 2,
          insertAtLine: runDetails.addAtLine,
          insert: '\n    foo;',
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (latestIsAnalyzing) {
      await waitWhileAnalyzing();
    }

    var response = await (await HttpClient().getUrl(
      Uri.parse('http://127.0.0.1:$diagnosticServerPort/timing?asJson=true'),
    )).close();
    if (response.statusCode != 200) {
      throw 'Got status ${response.statusCode}';
    }
    var requestData =
        json.decode(await utf8.decodeStream(response.cast<List<int>>()))
            as List;
    List<int> didChangeElapsed = [];
    int sum = 0;
    for (var entry in requestData) {
      if (entry is Map && entry['operation'] == 'textDocument/didChange') {
        var performance = (entry['performance']['children'] as List)
            .singleWhere(
              (element) =>
                  element['name'] ==
                  textDocumentChangeHandlerPerformanceCaption,
            );

        var elapsedInMicroseconds = performance['elapsed'] as int;
        didChangeElapsed.add(elapsedInMicroseconds);
        sum += elapsedInMicroseconds;
      }
    }
    if (didChangeElapsed.length != requestCount) {
      throw "Didn't get $requestCount answers, got ${didChangeElapsed.length}";
    }
    durationInfo.add(
      DurationInfo(
        'Processing time for $requestCount change requests',
        Duration(microseconds: sum),
      ),
    );
  }
}

class RunDetails {
  final FileContentPair mainFile;
  final int addAtLine;

  RunDetails({required this.mainFile, required this.addAtLine});
}
