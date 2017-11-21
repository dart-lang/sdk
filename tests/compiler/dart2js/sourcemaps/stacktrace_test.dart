// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart' as entry;

import 'helpers/stacktrace_helper.dart';

void main(List<String> args) {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('write-js', defaultsTo: false);
  argParser.addFlag('print-js', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('continued', abbr: 'c', defaultsTo: false);
  ArgResults argResults = argParser.parse(args);
  Directory dataDir =
      new Directory.fromUri(Platform.script.resolve('stacktrace'));
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
          verbose: argResults['verbose'],
          printJs: argResults['print-js'],
          writeJs: argResults['write-js']);
      if (argResults['continued']) {
        continuing = true;
      }
    }
  });
}

const String astMarker = 'ast.';
const String kernelMarker = 'kernel.';

Future testAnnotatedCode(String code,
    {bool printJs: false, bool writeJs: false, bool verbose: false}) async {
  Test test = processTestCode(code, [astMarker, kernelMarker]);
  print(test.code);
  print('---from ast---------------------------------------------------------');
  await runTest(test, astMarker,
      printJs: printJs, writeJs: writeJs, verbose: verbose);
  print('---from kernel------------------------------------------------------');
  await runTest(test, kernelMarker,
      printJs: printJs, writeJs: writeJs, verbose: verbose);
}

Future runTest(Test test, String config,
    {bool printJs: false,
    bool writeJs: false,
    bool verbose: false,
    List<String> options: const <String>[]}) async {
  List<LineException> testAfterExceptions = <LineException>[];
  if (config == kernelMarker) {
    for (LineException exception in afterExceptions) {
      if (exception.fileName == 'async_patch.dart') {
        testAfterExceptions
            .add(new LineException(exception.methodName, 'async.dart'));
        continue;
      }
      testAfterExceptions.add(exception);
    }
  } else {
    testAfterExceptions = afterExceptions;
  }
  return testStackTrace(test, config, (String input, String output) async {
    List<String> arguments = [
      '-o$output',
      '--library-root=sdk',
      '--packages=${Platform.packageConfig}',
      Flags.useNewSourceInfo,
      input,
    ]..addAll(options);
    if (config == kernelMarker) {
      arguments.add(Flags.useKernel);
    }
    print("Compiling dart2js ${arguments.join(' ')}");
    CompilationResult compilationResult = await entry.internalMain(arguments);
    return compilationResult.isSuccess;
  },
      jsPreambles: ['sdk/lib/_internal/js_runtime/lib/preambles/d8.js'],
      afterExceptions: testAfterExceptions,
      beforeExceptions: beforeExceptions);
}

/// Lines allowed before the intended stack trace. Typically from helper
/// methods.
const List<LineException> beforeExceptions = const [
  const LineException('wrapException', 'js_helper.dart'),
];

/// Lines allowed after the intended stack trace. Typically from the event
/// queue.
const List<LineException> afterExceptions = const [
  const LineException('_wrapJsFunctionForAsync', 'async_patch.dart'),
  const LineException(
      '_wrapJsFunctionForAsync.<anonymous function>', 'async_patch.dart'),
  const LineException(
      '_awaitOnObject.<anonymous function>', 'async_patch.dart'),
  const LineException('_asyncAwait.<anonymous function>', 'async_patch.dart'),
  const LineException('_asyncStart.<anonymous function>', 'async_patch.dart'),
  const LineException('_RootZone.runUnary', 'zone.dart'),
  const LineException('_FutureListener.handleValue', 'future_impl.dart'),
  const LineException('_Future._completeWithValue', 'future_impl.dart'),
  const LineException(
      '_Future._propagateToListeners.handleValueCallback', 'future_impl.dart'),
  const LineException('_Future._propagateToListeners', 'future_impl.dart'),
  const LineException(
      '_Future._addListener.<anonymous function>', 'future_impl.dart'),
];
