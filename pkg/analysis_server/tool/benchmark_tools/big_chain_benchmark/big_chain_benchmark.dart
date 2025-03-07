// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../lsp_benchmark.dart';
import '../messages.dart';

Future<void> main() async {
  StringBuffer sb = StringBuffer();
  for (CodeType codeType in CodeType.values) {
    for (int numFiles in [16, 32, 64, 128, 256, 512, 1024]) {
      Directory tmpDir = Directory.systemTemp.createTempSync('lsp_benchmark');
      try {
        Directory cacheDir = Directory.fromUri(tmpDir.uri.resolve('cache/'))
          ..createSync(recursive: true);
        Directory dartDir = Directory.fromUri(tmpDir.uri.resolve('dart/'))
          ..createSync(recursive: true);
        copyData(dartDir.uri, numFiles, codeType);
        BigChainBenchmark benchmark = BigChainBenchmark(
          dartDir.uri,
          cacheDir.uri,
          numFiles: numFiles,
        );
        try {
          await benchmark.run();
        } finally {
          benchmark.exit();
        }

        print('====================');
        print('$numFiles files / $codeType:');
        print(
          'Initial: '
          '${formatDuration(benchmark.firstAnalyzingDuration)}',
        );
        print(
          'Completion after change: '
          '${formatDuration(benchmark.completionAfterChange)}',
        );
        print(
          'Fully done after change: '
          '${formatDuration(benchmark.doneAfterChange)}',
        );
        print('====================');
        sb.writeln('$numFiles files / $codeType:');
        sb.writeln(
          'Initial: '
          '${formatDuration(benchmark.firstAnalyzingDuration)}',
        );
        sb.writeln(
          'Completion after change: '
          '${formatDuration(benchmark.completionAfterChange)}',
        );
        sb.writeln(
          'Fully done after change: '
          '${formatDuration(benchmark.doneAfterChange)}',
        );
        sb.writeln();
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    }
  }

  print('==================================');
  print(sb.toString().trim());
  print('==================================');
}

void copyData(Uri tmp, int numFiles, CodeType copyType) {
  Uri filesUri = Platform.script.resolve('files/');
  Uri tmpLib = tmp.resolve('lib/');
  Directory.fromUri(tmpLib).createSync();
  Directory files = Directory.fromUri(filesUri);
  for (var file in files.listSync()) {
    if (file is! File) continue;
    String filename = file.uri.pathSegments.last;
    file.copySync(tmpLib.resolve(filename).toFilePath());
  }
  File copyMe = File.fromUri(filesUri.resolve('copy_me/copy_me.dart'));
  String copyMeData = copyMe.readAsStringSync();
  Uri copyToDir = tmpLib.resolve('copies/');
  Directory.fromUri(copyToDir).createSync(recursive: true);

  for (int i = 1; i <= numFiles; i++) {
    String nextFile = getFilenameFor(i == numFiles ? 1 : i + 1);
    String import = "import '$nextFile' as nextFile;";
    String export = "export '$nextFile';";
    switch (copyType) {
      case CodeType.ImportCycle:
        export = '';
      case CodeType.ImportChain:
        export = '';
        if (i == numFiles) {
          import = '';
        }
      case CodeType.ImportExportChain:
        if (i == numFiles) {
          import = '';
          export = '';
        }
      case CodeType.ImportCycleExportChain:
        if (i == numFiles) {
          export = '';
        }
      case CodeType.ImportExportCycle:
      // As default values.
    }

    String fooMethod;
    if (import.isEmpty) {
      fooMethod = '''
String foo(int i) {
  if (i == 0) return "foo";
  return "bar";
}''';
    } else {
      fooMethod = '''
String foo(int i) {
  if (i == 0) return "foo";
  return nextFile.foo(i-1);
}''';
    }
    File.fromUri(copyToDir.resolve(getFilenameFor(i))).writeAsStringSync('''
$import
$export

$copyMeData

$fooMethod

String get$i() {
  return "$i";
}

''');
  }

  File.fromUri(copyToDir.resolve('main.dart')).writeAsStringSync("""
import '${getFilenameFor(1)}';

void main(List<String> arguments) {
  
}
""");
}

String formatDuration(Duration? duration) {
  if (duration == null) return 'N/A';
  int seconds = duration.inSeconds;
  int ms = duration.inMicroseconds - seconds * Duration.microsecondsPerSecond;
  return '$seconds.${ms.toString().padLeft(6, '0')}';
}

String getFilenameFor(int i) {
  return "file${i.toString().padLeft(5, '0')}.dart";
}

class BigChainBenchmark extends LspBenchmark {
  @override
  final Uri rootUri;
  @override
  final Uri cacheFolder;

  Duration? completionAfterChange;
  Duration? doneAfterChange;

  int numFiles;

  BigChainBenchmark(this.rootUri, this.cacheFolder, {required this.numFiles});

  @override
  LaunchFrom get launchFrom => LaunchFrom.Dart;

  @override
  Future<void> afterInitialization() async {
    Uri tmpLib = rootUri.resolve('lib/');
    Uri lastFileUri = tmpLib.resolve('copies/${getFilenameFor(numFiles)}');
    Uri mainFileUri = tmpLib.resolve('copies/main.dart');
    var mainFileContent = File.fromUri(mainFileUri).readAsStringSync();
    var lastFileContent = File.fromUri(lastFileUri).readAsStringSync();
    var lastFileContentLines = lastFileContent.split('\n');

    Future<void> openFile(Uri uri, String content) async {
      await send(Messages.open(uri, 1, content));
      await (await send(
        Messages.documentColor(uri, largestIdSeen + 1),
      ))?.completer.future;
      await (await send(
        Messages.documentSymbol(lastFileUri, largestIdSeen + 1),
      ))?.completer.future;

      // TODO(jensj): Possibly send this - as the IDE does - too?
      // textDocument/semanticTokens/full
      // textDocument/codeAction
      // textDocument/documentLink
      // textDocument/codeAction
      // textDocument/semanticTokens/range
      // textDocument/inlayHint
      // textDocument/foldingRange
      // textDocument/codeAction
      // textDocument/documentHighlight
      // textDocument/codeAction
      // textDocument/codeLens
      // textDocument/codeAction
    }

    // Open main file.
    await openFile(mainFileUri, mainFileContent);

    // Open last file.
    await openFile(lastFileUri, lastFileContent);

    // Change last file: Add a top-level method.
    await send(
      Messages.didChange(
        lastFileUri,
        version: 2,
        insertAtLine: lastFileContentLines.length - 1 /* line 0-indexed */,
        insert: '\nString bar() {\n  return "bar";\n}',
      ),
    );

    // Request the symbols (although we will ignore the response which we won't
    // await).
    await send(Messages.documentSymbol(lastFileUri, largestIdSeen + 1));

    // Start typing in the main file and request auto-completion.
    await send(
      Messages.didChange(
        mainFileUri,
        version: 2,
        insertAtLine: 3 /* line 0-indexed; at blank line inside main */,
        insertAtCharacter: 2,
        insert: 'ge',
      ),
    );
    Future<Map<String, dynamic>> completionFuture =
        (await send(
          Messages.completion(
            mainFileUri,
            largestIdSeen + 1,
            line: 3,
            character: 4 /* after the 'ge' just typed */,
          ),
        ))!.completer.future;

    Stopwatch stopwatch = Stopwatch()..start();
    var completionResponse = await completionFuture;
    List<dynamic> completionItems =
        completionResponse['result']['items'] as List;
    completionAfterChange = stopwatch.elapsed;
    print(
      'Got ${completionItems.length} completion items '
      'in $completionAfterChange',
    );
    await waitWhileAnalyzing();
    stopwatch.stop();
    doneAfterChange = stopwatch.elapsed;
    print('Fully done after $doneAfterChange');
  }
}

enum CodeType {
  ImportCycle,
  ImportChain,
  ImportExportCycle,
  ImportExportChain,
  ImportCycleExportChain,
}
