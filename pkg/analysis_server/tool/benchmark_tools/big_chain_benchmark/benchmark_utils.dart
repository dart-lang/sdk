// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../utils.dart';

RunDetails copyData(
  Uri packageDirUri,
  Uri outerDirForAdditionalData,
  int numFiles,
  CodeType? copyType,
  List<String> args, {
  required ({bool includePlugin})? extraInformation,
}) {
  bool includePlugin = extraInformation?.includePlugin ?? false;
  if (copyType == null) throw 'Unsupported.';
  Uri filesUri = Platform.script.resolve('files/');
  Uri libDirUri = packageDirUri.resolve('lib/');
  Directory.fromUri(libDirUri).createSync();
  Directory files = Directory.fromUri(filesUri);
  for (var file in files.listSync()) {
    if (file is! File) continue;
    String filename = file.uri.pathSegments.last;
    if (filename == 'analysis_options.yaml') {
      // Written below at the right place instead.
      continue;
    }
    file.copySync(libDirUri.resolve(filename).toFilePath());
  }

  // Write analysis_options.
  File.fromUri(
    packageDirUri.resolve('analysis_options.yaml'),
  ).writeAsStringSync('''
analyzer:
  errors:
    todo: ignore
''');

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
    var content =
        '''
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
  var mainFileContent =
      """
import '${getFilenameFor(1)}';

void main(List<String> arguments) {

}
""";
  File.fromUri(mainFileUri).writeAsStringSync(mainFileContent);
  var typing = '  ge';
  var mainFileTypingContent =
      """
import '${getFilenameFor(1)}';

void main(List<String> arguments) {
$typing
}
""";
  var typingAtOffset = mainFileTypingContent.indexOf(typing) + typing.length;

  var typingError = 'getFooBarBaz';
  var mainFileTypingErrorContent =
      """
import '${getFilenameFor(1)}';

void main(List<String> arguments) {
  arguments.$typingError();
}
""";
  var typingErrorAtOffset =
      mainFileTypingErrorContent.indexOf(typingError) + typingError.length;

  if (includePlugin) {
    String executableToUse = extractDartParamOrDefault(args);
    void pubGetIn(String dir) {
      if (Process.runSync(executableToUse, [
            'pub',
            'get',
          ], workingDirectory: dir).exitCode !=
          0) {
        print('WARNING: Got non 0 exit-code from dart pub get call.');
      }
    }

    // Plugin package pubspec.yaml
    var pluginDir = Directory.fromUri(
      outerDirForAdditionalData.resolve('plugin/'),
    )..createSync(recursive: true);
    File.fromUri(pluginDir.uri.resolve('pubspec.yaml')).writeAsStringSync('''
name: benchmark_helper_plugin
environment:
  sdk: '>=3.3.0 <5.0.0'
''');
    pubGetIn(pluginDir.path);

    // Plugin package lib/<package_name>.dart
    var pluginLibDir = Directory.fromUri(
      outerDirForAdditionalData.resolve('plugin/lib/'),
    )..createSync(recursive: true);
    File.fromUri(
      pluginLibDir.uri.resolve('benchmark_helper_plugin.dart'),
    ).writeAsStringSync('');

    // tools/analyzer_plugin/bin/plugin.dart
    var dir = Directory.fromUri(
      pluginDir.uri.resolve('tools/analyzer_plugin/bin/'),
    )..createSync(recursive: true);
    File copyMe = File.fromUri(filesUri.resolve('copy_me/plugin.dart'));
    copyMe.copySync(dir.uri.resolve('plugin.dart').toFilePath());

    // tools/analyzer_plugin/pubspec.yaml
    dir = Directory.fromUri(pluginDir.uri.resolve('tools/analyzer_plugin/'));
    File.fromUri(dir.uri.resolve('pubspec.yaml')).writeAsStringSync('''
name: benchmark_helper_plugin_helper
environment:
  sdk: '>=3.3.0 <5.0.0'
''');
    pubGetIn(dir.path);

    // pubspec.yaml in package that is analyzed, depending on the plugin
    File.fromUri(packageDirUri.resolve('pubspec.yaml')).writeAsStringSync('''
name: benchmark_project
environment:
  sdk: '>=3.3.0 <5.0.0'
dependencies:
  benchmark_helper_plugin:
    path: ${pluginDir.path}
''');
    pubGetIn(packageDirUri.path);

    // Write analysis_options enabling the plugin.
    File.fromUri(
      packageDirUri.resolve('analysis_options.yaml'),
    ).writeAsStringSync('''
analyzer:
  errors:
    todo: ignore
  plugins:
    - benchmark_helper_plugin
''');
  }

  return RunDetails(
    libDirUri: libDirUri,
    mainFile: FileContentPair(mainFileUri, mainFileContent),
    mainFileTypingContent: mainFileTypingContent,
    typingAtOffset: typingAtOffset,
    mainFileTypingErrorContent: mainFileTypingErrorContent,
    typingErrorAtOffset: typingErrorAtOffset,
    orderedFileCopies: orderedFileCopies,
    numFiles: numFiles,
  );
}

List<CodeType?> getExtraIterations(List<String> args) {
  var codeTypes = CodeType.values;
  for (String arg in args) {
    if (arg.startsWith('--types=')) {
      codeTypes = [];
      for (var type in arg.substring('--types='.length).split(',')) {
        type = type.toLowerCase();
        for (var value in CodeType.values) {
          if (value.name.toLowerCase().contains(type)) {
            codeTypes.add(value);
          }
        }
      }
    }
  }
  return codeTypes;
}

String getFilenameFor(int i) {
  return "file${i.toString().padLeft(5, '0')}.dart";
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
  final String mainFileTypingErrorContent;
  final int typingErrorAtOffset;
  final List<FileContentPair> orderedFileCopies;
  final int numFiles;

  RunDetails({
    required this.libDirUri,
    required this.mainFile,
    required this.mainFileTypingContent,
    required this.typingAtOffset,
    required this.mainFileTypingErrorContent,
    required this.typingErrorAtOffset,
    required this.orderedFileCopies,
    required this.numFiles,
  });
}
