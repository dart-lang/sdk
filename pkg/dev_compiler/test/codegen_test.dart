// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests code generation.
/// Runs Dart Dev Compiler on all input in the `codegen` directory and checks
/// that the output is what we expected.
library ddc.test.codegen_test;

import 'dart:io';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine, Logger;
import 'package:analyzer/src/generated/java_engine.dart' show CaughtException;
import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:dev_compiler/devc.dart';
import 'package:dev_compiler/src/checker/resolver.dart' show TypeResolver;
import 'package:dev_compiler/src/options.dart';
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

final ArgParser argParser = new ArgParser()
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
  ..addFlag(
      'dart-gen', abbr: 'd', help: 'Generate dart output', defaultsTo: false);

main(arguments) {
  if (arguments == null) arguments = [];
  ArgResults args = argParser.parse(arguments);
  var script = Platform.script.path;
  var dartGen = args['dart-gen'];
  var filePattern = new RegExp(args.rest.length > 0 ? args.rest[0] : '.');
  var compilerMessages = new StringBuffer();
  var loggerSub;

  setUp(() {
    compilerMessages.clear();
    loggerSub = setupLogger(Level.CONFIG, compilerMessages.writeln);
  });

  tearDown(() {
    if (loggerSub != null) {
      loggerSub.cancel();
      loggerSub = null;
    }
  });

  var testDir = path.absolute(path.dirname(script));
  var inputDir = dartGen
      ? path.join(testDir, 'dart_codegen')
      : path.join(testDir, 'codegen');
  var actualDir = path.join(inputDir, 'actual');
  var paths = new Directory(inputDir)
      .listSync()
      .where((f) => f is File)
      .map((f) => f.path)
      .where((p) => p.endsWith('.dart') && filePattern.hasMatch(p));

  var options = new CompilerOptions(
      outputDir: actualDir,
      useColors: false,
      outputDart: dartGen,
      formatOutput: dartGen,
      emitSourceMaps: false);
  var realSdk = new TypeResolver.fromDir(getSdkDir(arguments).path, options);

  // Validate that old output is gone before running.
  // TODO(jmesserly): it'd be nice to do all cleanup here, including removing
  // pub's 'packages' symlinks which mess up the diff. That way this test
  // can be self contained instead of depending on a shell script.
  if (new Directory(actualDir).existsSync()) {
    throw 'Old compiler output should be cleaned up first. Use ./test/test.sh';
  }

  for (var filePath in paths) {
    var filename = path.basenameWithoutExtension(filePath);

    test('devc $filename.dart', () {
      compilerMessages.writeln('// Messages from compiling $filename.dart');

      var result = compile(filePath, realSdk, options);
      var success = !result.failure;

      // Write compiler messages to disk.
      new File(path.join(actualDir, '$filename.txt'))
          .writeAsStringSync(compilerMessages.toString());

      var outFile = dartGen
          ? new File(path.join(actualDir, '$filename/$filename.dart'))
          : new File(path.join(actualDir, '$filename.js'));
      expect(outFile.existsSync(), success,
          reason: '${outFile.path} was created iff compilation succeeds');

      // TODO(jmesserly): ideally we'd diff the output here. For now it
      // happens in the containing shell script.
    });
  }

  group('sdk', () {
    // The analyzer does not bubble exception messages for certain internal
    // dart:* library failures, such as failing to find
    // "_internal/libraries.dart". Instead it produces an opaque "failed to
    // instantiate dart:core" message. To remedy this we hook up an analysis
    // logger that prints these messages.
    var savedLogger;
    setUp(() {
      savedLogger = AnalysisEngine.instance.logger;
      AnalysisEngine.instance.logger = new PrintLogger();
    });
    tearDown(() {
      AnalysisEngine.instance.logger = savedLogger;
    });

    test('devc dart:core', () {
      // Get the test SDK. We use a checked in copy so test expectations can be
      // generated against a specific SDK version.
      // TODO(jmesserly): eventually we should track compiler messages.
      // For now we're just trying to get decent code generation.
      var options = new CompilerOptions(
          outputDir: actualDir,
          checkSdk: true,
          forceCompile: true,
          outputDart: dartGen,
          formatOutput: dartGen,
          cheapTestFormat: true,
          emitSourceMaps: false);
      var sdkPath = dartGen
          ? path.join(testDir, '..', 'tool', 'input_sdk')
          : path.join(testDir, 'generated_sdk');
      var testSdk = new TypeResolver.fromDir(sdkPath, options);
      compile('dart:core', testSdk, options);
      var outFile = dartGen
          ? new File(path.join(actualDir, 'core/core'))
          : new File(path.join(actualDir, 'dart/core.js'));
      expect(outFile.existsSync(), true,
          reason: '${outFile.path} was created for dart:core');
    });
  });

  if (!dartGen) {
    test('devc jscodegen html_input.html', () {
      var filePath = path.join(inputDir, 'html_input.html');
      compilerMessages.writeln('// Messages from compiling html_input.html');

      var result = compile(filePath, realSdk, options);
      var success = !result.failure;

      // Write compiler messages to disk.
      new File(path.join(actualDir, 'html_input.txt'))
          .writeAsStringSync(compilerMessages.toString());

      var outFile = new File(path.join(actualDir, 'html_input.html'));
      expect(outFile.existsSync(), success,
          reason: '${outFile.path} was created iff compilation succeeds');
    });
  }
}

/// An implementation of analysis engine's [Logger] that prints.
class PrintLogger implements Logger {
  @override void logError(String message, [CaughtException exception]) {
    print('[AnalysisEngine] error $message $exception');
  }

  @override void logError2(String message, Object exception) {
    print('[AnalysisEngine] error $message $exception');
  }

  void logInformation(String message, [CaughtException exception]) {}
  void logInformation2(String message, Object exception) {}
}
