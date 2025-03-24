// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../language_server_benchmark.dart';

RunDetails copyData(Uri tmp, int numFiles, CodeType copyType) {
  Uri filesUri = Platform.script.resolve('files/');
  Uri libDirUri = tmp.resolve('lib/');
  Directory.fromUri(libDirUri).createSync();
  Directory files = Directory.fromUri(filesUri);
  for (var file in files.listSync()) {
    if (file is! File) continue;
    String filename = file.uri.pathSegments.last;
    file.copySync(libDirUri.resolve(filename).toFilePath());
  }
  File copyMe = File.fromUri(filesUri.resolve('copy_me/copy_me.dart'));
  String copyMeData = copyMe.readAsStringSync();
  Uri copyToDir = libDirUri.resolve('copies/');
  Directory.fromUri(copyToDir).createSync(recursive: true);

  List<FileContentPair> orderedFileCopies = [];
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
    var content = '''
$import
$export

$copyMeData

$fooMethod

String get$i() {
  return "$i";
}

''';
    var copyUri = copyToDir.resolve(getFilenameFor(i));
    File.fromUri(copyUri).writeAsStringSync(content);
    orderedFileCopies.add(FileContentPair(copyUri, content));
  }

  var mainFileUri = copyToDir.resolve('main.dart');
  var mainFileContent = """
import '${getFilenameFor(1)}';

void main(List<String> arguments) {

}
""";
  File.fromUri(mainFileUri).writeAsStringSync(mainFileContent);
  var typing = '  ge';
  var mainFileTypingContent = """
import '${getFilenameFor(1)}';

void main(List<String> arguments) {
$typing
}
""";
  var typingAtOffset = mainFileTypingContent.indexOf(typing) + typing.length;

  return RunDetails(
    libDirUri: libDirUri,
    mainFile: FileContentPair(mainFileUri, mainFileContent),
    mainFileTypingContent: mainFileTypingContent,
    typingAtOffset: typingAtOffset,
    orderedFileCopies: orderedFileCopies,
    numFiles: numFiles,
  );
}

String formatDuration(Duration duration) {
  int seconds = duration.inSeconds;
  int ms = duration.inMicroseconds - seconds * Duration.microsecondsPerSecond;
  return '$seconds.${ms.toString().padLeft(6, '0')}';
}

String formatKb(int kb) {
  if (kb > 1024) {
    return '${kb ~/ 1024} MB';
  } else {
    return '$kb KB';
  }
}

String getFilenameFor(int i) {
  return "file${i.toString().padLeft(5, '0')}.dart";
}

Future<void> runHelper(
  DartLanguageServerBenchmark Function(
    Uri rootUri,
    Uri cacheFolder,
    RunDetails runDetails,
  )
  benchmarkCreator, {
  required bool runAsLsp,
  List<int> numberOfFileOptions = const [16, 32, 64, 128, 256, 512, 1024],
}) async {
  StringBuffer sb = StringBuffer();
  for (CodeType codeType in CodeType.values) {
    for (int numFiles in numberOfFileOptions) {
      Directory tmpDir = Directory.systemTemp.createTempSync('lsp_benchmark');
      try {
        Directory cacheDir = Directory.fromUri(tmpDir.uri.resolve('cache/'))
          ..createSync(recursive: true);
        Directory dartDir = Directory.fromUri(tmpDir.uri.resolve('dart/'))
          ..createSync(recursive: true);
        var runDetails = copyData(dartDir.uri, numFiles, codeType);
        var benchmark = benchmarkCreator(dartDir.uri, cacheDir.uri, runDetails);
        try {
          await benchmark.run();
        } finally {
          benchmark.exit();
        }

        print('====================');
        print('$numFiles files / $codeType:');
        sb.writeln('$numFiles files / $codeType:');
        for (var durationInfo in benchmark.durationInfo) {
          print(
            '${durationInfo.name}: '
            '${formatDuration(durationInfo.duration)}',
          );
          sb.writeln(
            '${durationInfo.name}: '
            '${formatDuration(durationInfo.duration)}',
          );
        }
        for (var memoryInfo in benchmark.memoryInfo) {
          print(
            '${memoryInfo.name}: '
            '${formatKb(memoryInfo.kb)}',
          );
          sb.writeln(
            '${memoryInfo.name}: '
            '${formatKb(memoryInfo.kb)}',
          );
        }
        print('====================');
        sb.writeln();
      } finally {
        try {
          tmpDir.deleteSync(recursive: true);
        } catch (e) {
          // Wait a little and retry.
          sleep(const Duration(milliseconds: 42));
          try {
            tmpDir.deleteSync(recursive: true);
          } catch (e) {
            print('Warning: $e');
          }
        }
      }
    }
  }

  print('==================================');
  print(sb.toString().trim());
  print('==================================');
}

enum CodeType {
  ImportCycle,
  ImportChain,
  ImportExportCycle,
  ImportExportChain,
  ImportCycleExportChain,
}

class FileContentPair {
  final Uri uri;
  final String content;

  FileContentPair(this.uri, this.content);
}

class RunDetails {
  final Uri libDirUri;
  final FileContentPair mainFile;
  final String mainFileTypingContent;
  final int typingAtOffset;
  final List<FileContentPair> orderedFileCopies;
  final int numFiles;

  RunDetails({
    required this.libDirUri,
    required this.mainFile,
    required this.mainFileTypingContent,
    required this.typingAtOffset,
    required this.orderedFileCopies,
    required this.numFiles,
  });
}
