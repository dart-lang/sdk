// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:expect/expect.dart';
import 'package:sourcemap_testing/src/stepping_helper.dart';

import '../helpers/memory_compiler.dart';

void main(List<String> args) {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('debug', abbr: 'd', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('continued', abbr: 'c', defaultsTo: false);
  ArgResults argResults = argParser.parse(args);
  Directory dataDir =
      new Directory.fromUri(Platform.script.resolve('stepping'));
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
      String annotatedCode = await new File.fromUri(entity.uri).readAsString();
      await testAnnotatedCode(annotatedCode,
          verbose: argResults['verbose'], debug: argResults['debug']);
      if (argResults['continued']) {
        continuing = true;
      }
    }
  });
}

const String kernelMarker = 'kernel.';

Future testAnnotatedCode(String code,
    {bool debug: false, bool verbose: false}) async {
  AnnotatedCode annotatedCode =
      new AnnotatedCode.fromText(code, commentStart, commentEnd);
  print(annotatedCode.sourceCode);
  Map<String, AnnotatedCode> split =
      splitByPrefixes(annotatedCode, [kernelMarker]);
  print('---from kernel------------------------------------------------------');
  await runTest(split[kernelMarker], kernelMarker,
      debug: debug, verbose: verbose);
}

Future runTest(AnnotatedCode annotatedCode, String config,
    {bool debug: false,
    bool verbose: false,
    List<String> options: const <String>[]}) async {
  Directory dir = Directory.systemTemp.createTempSync('stepping_test');
  String testFileName = 'test.dart';
  String path = dir.path;
  String inputFile = '$path/$testFileName';
  new File(inputFile).writeAsStringSync(annotatedCode.sourceCode);
  String outputFile = '$path/js.js';
  List<String> arguments = <String>[
    '--out=$outputFile',
    inputFile,
    Flags.disableInlining,
    '--libraries-spec=$sdkLibrariesSpecificationUri',
  ];
  CompilationResult compilationResult = await entry.internalMain(arguments);
  Expect.isTrue(compilationResult.isSuccess);
  List<String> scriptD8Command = [
    '$sdkPath/_internal/js_runtime/lib/preambles/d8.js',
    outputFile
  ];
  ProcessResult result =
      runD8AndStep(dir.path, testFileName, annotatedCode, scriptD8Command);
  List<String> d8output = result.stdout.split("\n");
  if (verbose) {
    d8output.forEach(print);
  }
  checkD8Steps(dir.path, d8output, annotatedCode, debug: debug);
  dir.deleteSync(recursive: true);
}
