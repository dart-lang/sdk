// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests code generation.
/// Runs Dart Dev Compiler on all input in the `codegen` directory and checks
/// that the output is what we expected.
library dev_compiler.test.codegen_test;

import 'dart:io';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, Logger;
import 'package:analyzer/src/generated/java_engine.dart' show CaughtException;
import 'package:args/args.dart';
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:dev_compiler/devc.dart';
import 'package:dev_compiler/strong_mode.dart';
import 'package:dev_compiler/src/compiler.dart' show defaultRuntimeFiles;
import 'package:dev_compiler/src/options.dart';

import 'testing.dart' show realSdkContext, testDirectory;

final ArgParser argParser = new ArgParser()
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null);

main(arguments) {
  if (arguments == null) arguments = [];
  ArgResults args = argParser.parse(arguments);
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

  var inputDir = path.join(testDirectory, 'codegen');
  var expectDir = path.join(inputDir, 'expect');
  var paths = new Directory(inputDir)
      .listSync()
      .where((f) => f is File)
      .map((f) => f.path)
      .where((p) => p.endsWith('.dart') && filePattern.hasMatch(p));

  bool compile(String entryPoint, AnalysisContext context,
      {bool checkSdk: false, bool sourceMaps: false, String subDir}) {
    // TODO(jmesserly): add a way to specify flags in the test file, so
    // they're more self-contained.
    var runtimeDir = path.join(path.dirname(testDirectory), 'lib', 'runtime');
    var options = new CompilerOptions(
        codegenOptions: new CodegenOptions(
            outputDir: subDir == null
                ? expectDir
                : path.join(expectDir, subDir),
            emitSourceMaps: sourceMaps,
            forceCompile: checkSdk),
        useColors: false,
        checkSdk: checkSdk,
        runtimeDir: runtimeDir,
        inputs: [entryPoint]);
    var reporter = createErrorReporter(context, options);
    return new BatchCompiler(context, options, reporter: reporter).run();
  }

  // Remove old output, and `packages` symlinks which mess up the diff.
  var dir = new Directory(expectDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  var packagesDirs = new Directory(inputDir)
      .listSync(recursive: true)
      .where((d) => d is Directory && path.basename(d.path) == 'packages');
  packagesDirs.forEach((d) => d.deleteSync());

  for (var filePath in paths) {
    var filename = path.basenameWithoutExtension(filePath);

    test('devc $filename.dart', () {
      compilerMessages.writeln('// Messages from compiling $filename.dart');

      // TODO(jmesserly): this was added to get some coverage of source maps
      // We need a more comprehensive strategy to test them.
      var sourceMaps = filename == 'map_keys';
      var success = compile(filePath, realSdkContext, sourceMaps: sourceMaps);

      // Write compiler messages to disk.
      new File(path.join(expectDir, '$filename.txt'))
          .writeAsStringSync(compilerMessages.toString());

      var outFile = new File(path.join(expectDir, '$filename.js'));
      expect(outFile.existsSync(), success,
          reason: '${outFile.path} was created iff compilation succeeds');

      // TODO(jmesserly): ideally we'd diff the output here. For now it
      // happens in the containing shell script.
    });
  }

  if (Platform.environment.containsKey('COVERALLS_TOKEN')) {
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
        var testSdkContext = createAnalysisContextWithSources(
            new StrongModeOptions(), new SourceResolverOptions(
                dartSdkPath: path.join(
                    testDirectory, '..', 'tool', 'generated_sdk')));

        // Get the test SDK. We use a checked in copy so test expectations can
        // be generated against a specific SDK version.
        compile('dart:core', testSdkContext, checkSdk: true);
        var outFile = new File(path.join(expectDir, 'dart/core.js'));
        expect(outFile.existsSync(), true,
            reason: '${outFile.path} was created for dart:core');
      });
    });
  }

  var expectedRuntime =
      defaultRuntimeFiles.map((f) => 'dev_compiler/runtime/$f');

  test('devc jscodegen sunflower.html', () {
    var filePath = path.join(inputDir, 'sunflower', 'sunflower.html');
    compilerMessages.writeln('// Messages from compiling sunflower.html');

    var success = compile(filePath, realSdkContext, subDir: 'sunflower');

    // Write compiler messages to disk.
    new File(path.join(expectDir, 'sunflower', 'sunflower.txt'))
        .writeAsStringSync(compilerMessages.toString());

    var expectedFiles = [
      'sunflower.html',
      'sunflower.js',
    ]..addAll(expectedRuntime);

    for (var filepath in expectedFiles) {
      var outFile = new File(path.join(expectDir, 'sunflower', filepath));
      expect(outFile.existsSync(), success,
          reason: '${outFile.path} was created iff compilation succeeds');
    }
  });

  test('devc jscodegen html_input.html', () {
    var filePath = path.join(inputDir, 'html_input.html');
    compilerMessages.writeln('// Messages from compiling html_input.html');

    var success = compile(filePath, realSdkContext);

    // Write compiler messages to disk.
    new File(path.join(expectDir, 'html_input.txt'))
        .writeAsStringSync(compilerMessages.toString());

    var expectedFiles = [
      'html_input.html',
      'dir/html_input_a.js',
      'dir/html_input_b.js',
      'dir/html_input_c.js',
      'dir/html_input_d.js',
      'dir/html_input_e.js'
    ]..addAll(expectedRuntime);

    for (var filepath in expectedFiles) {
      var outFile = new File(path.join(expectDir, filepath));
      expect(outFile.existsSync(), success,
          reason: '${outFile.path} was created iff compilation succeeds');
    }
  });
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
