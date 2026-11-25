// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:args/args.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:sourcemap_testing/src/stepping_helper.dart';

import 'package:compiler/src/util/memory_compiler.dart';

void main(List<String> args) {
  ArgParser argParser = ArgParser(allowTrailingOptions: true);
  argParser.addFlag('debug', abbr: 'd', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('continued', abbr: 'c', defaultsTo: false);
  ArgResults argResults = argParser.parse(args);
  Directory dataDir = Directory.fromUri(Platform.script.resolve('stepping'));
  asyncTest(() async {
    bool continuing = false;
    await for (FileSystemEntity entity in dataDir.list()) {
      String name = entity.uri.pathSegments.last;
      if (argResults.rest.isNotEmpty &&
          !argResults.rest.contains(name) &&
          !continuing) {
        continue;
      }
      print('----------------------------------------------------------------');
      print('Checking ${entity.uri}');
      print('----------------------------------------------------------------');
      String annotatedCode = await File.fromUri(entity.uri).readAsString();
      await testAnnotatedCode(
        annotatedCode,
        verbose: argResults['verbose'],
        debug: argResults['debug'],
      );
      if (argResults['continued']) {
        continuing = true;
      }
    }
  });
}

const String kernelMarker = 'kernel.';

Future testAnnotatedCode(
  String code, {
  bool debug = false,
  bool verbose = false,
}) async {
  AnnotatedCode annotatedCode = AnnotatedCode.fromText(
    code,
    commentStart,
    commentEnd,
  );
  print(annotatedCode.sourceCode);
  Map<String, AnnotatedCode> split = splitByPrefixes(annotatedCode, [
    kernelMarker,
  ]);
  print('---from kernel------------------------------------------------------');
  await runTest(
    split[kernelMarker]!,
    kernelMarker,
    debug: debug,
    verbose: verbose,
  );
}

Future runTest(
  AnnotatedCode annotatedCode,
  String config, {
  bool debug = false,
  bool verbose = false,
  List<String> options = const <String>[],
}) async {
  Directory dir = Directory.systemTemp.createTempSync('stepping_test');
  String testFileName = 'test.dart';
  String path = dir.path;
  String inputFile = '$path/$testFileName';
  File(inputFile).writeAsStringSync(annotatedCode.sourceCode);
  String outputFile = '$path/$jsFileName';
  List<String> arguments = <String>[
    '--out=$outputFile',
    inputFile,
    Flags.disableInlining,
  ];
  CompilationResult compilationResult = await entry.internalMain(arguments);
  Expect.isTrue(compilationResult.isSuccess);
  File('$path/bootstrap.html').writeAsStringSync(bootstrapHtml);
  List<String> output = await runChromeAndStep(
    dir.path,
    testFileName,
    annotatedCode,
  );
  if (verbose) {
    output.forEach(print);
  }
  checkSteps(dir.path, output, annotatedCode, debug: debug);
  dir.deleteSync(recursive: true);
}

/// The page `runChromeAndStep` loads to run `js.js`.
///
/// dart2js output calls `main` as soon as it loads unless a `dartMainRunner`
/// hook is defined, so the hook holds `main` back until `runChromeAndStep` has
/// set its breakpoints and calls `scheduleMain`.
const String bootstrapHtml =
    '''
<!DOCTYPE html>
<html>
  <head>
    <title>dart2js step test</title>
    <script>
      var scheduleMain;
      self.dartMainRunner = function(main, args) {
        scheduleMain = function() {
          main(args);
        };
      };
    </script>
    <script src="$jsFileName"></script>
  </head>
  <body></body>
</html>
''';
