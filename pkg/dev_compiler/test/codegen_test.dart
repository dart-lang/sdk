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
import 'package:dev_compiler/src/compiler.dart' show defaultRuntimeFiles;
import 'package:dev_compiler/src/options.dart';

import 'testing.dart' show realSdkContext, testDirectory;
import 'multitest.dart';

final ArgParser argParser = new ArgParser()
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null);

final inputDir = path.join(testDirectory, 'codegen');

Iterable<String> _findTests(String dir, RegExp filePattern) {
  var files = new Directory(dir)
      .listSync()
      .where((f) => f is File)
      .map((f) => f.path)
      .where((p) => p.endsWith('.dart') && filePattern.hasMatch(p));
  if (dir != inputDir) {
    files = files
        .where((p) => p.endsWith('_test.dart') || p.endsWith('_multi.dart'));
  }
  return files;
}

main(arguments) {
  if (arguments == null) arguments = [];
  ArgResults args = argParser.parse(arguments);
  var filePattern = new RegExp(args.rest.length > 0 ? args.rest[0] : '.');
  var compilerMessages = new StringBuffer();
  var loggerSub;

  bool codeCoverage = Platform.environment.containsKey('COVERALLS_TOKEN');

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

  var expectDir = path.join(inputDir, 'expect');

  BatchCompiler createCompiler(AnalysisContext context,
      {bool checkSdk: false,
      bool sourceMaps: false,
      bool destructureNamedParams: false,
      bool closure: false,
      ModuleFormat moduleFormat: ModuleFormat.legacy}) {
    // TODO(jmesserly): add a way to specify flags in the test file, so
    // they're more self-contained.
    var runtimeDir = path.join(path.dirname(testDirectory), 'lib', 'runtime');
    var options = new CompilerOptions(
        codegenOptions: new CodegenOptions(
            outputDir: expectDir,
            emitSourceMaps: sourceMaps,
            closure: closure,
            destructureNamedParams: destructureNamedParams,
            forceCompile: checkSdk,
            moduleFormat: moduleFormat),
        useColors: false,
        checkSdk: checkSdk,
        runtimeDir: runtimeDir,
        inputBaseDir: inputDir);
    var reporter = createErrorReporter(context, options);
    return new BatchCompiler(context, options, reporter: reporter);
  }

  bool compile(BatchCompiler compiler, String filePath) {
    compiler.compileFromUriString(filePath, (String url) {
      // Write compiler messages to disk.
      var messagePath = '${path.withoutExtension(url)}.txt';
      var file = new File(messagePath);
      var message = '''
// Messages from compiling ${path.basenameWithoutExtension(url)}.dart
$compilerMessages''';
      var dir = file.parent;
      if (!dir.existsSync()) dir.createSync(recursive: true);
      file.writeAsStringSync(message);
      compilerMessages.clear();
    });
    return !compiler.failure;
  }

  var testDirs = <String>['language', path.join('lib', 'typed_data')];

  var multitests = new Set<String>();
  {
    // Expand wacky multitests into a bunch of test files.
    // We'll compile each one as if it was an input.
    for (var testDir in testDirs) {
      var fullDir = path.join(inputDir, testDir);
      var testFiles = _findTests(fullDir, filePattern);

      for (var filePath in testFiles) {
        if (filePath.endsWith('_multi.dart')) continue;

        var contents = new File(filePath).readAsStringSync();
        if (isMultiTest(contents)) {
          multitests.add(filePath);

          var tests = new Map<String, String>();
          var outcomes = new Map<String, Set<String>>();
          extractTestsFromMultitest(filePath, contents, tests, outcomes);

          var filename = path.basenameWithoutExtension(filePath);
          tests.forEach((name, contents) {
            new File(path.join(fullDir, '${filename}_${name}_multi.dart'))
                .writeAsStringSync(contents);
          });
        }
      }
    }
  }

  var batchCompiler = createCompiler(realSdkContext);

  var allDirs = [null];
  allDirs.addAll(testDirs);
  for (var dir in allDirs) {
    if (codeCoverage && dir != null) continue;

    group('dartdevc ' + path.join('test', 'codegen', dir), () {
      var outDir = new Directory(path.join(expectDir, dir));
      if (!outDir.existsSync()) outDir.createSync(recursive: true);

      var testFiles = _findTests(path.join(inputDir, dir), filePattern);
      for (var filePath in testFiles) {
        if (multitests.contains(filePath)) continue;

        var filename = path.basenameWithoutExtension(filePath);

        test('$filename.dart', () {
          // TODO(jmesserly): this was added to get some coverage of source maps
          // and closure annotations.
          // We need a more comprehensive strategy to test them.
          var sourceMaps = filename == 'map_keys';
          var closure = filename == 'closure';
          var destructureNamedParams = filename == 'destructuring' || closure;
          var moduleFormat = filename == 'es6_modules' || closure
              ? ModuleFormat.es6
              : filename == 'node_modules'
                  ? ModuleFormat.node
                  : ModuleFormat.legacy;
          var success;
          // TODO(vsm): Is it okay to reuse the same context here?  If there is
          // overlap between test files, we may need separate ones for each
          // compiler.
          var compiler = (sourceMaps ||
                  closure ||
                  destructureNamedParams ||
                  moduleFormat != ModuleFormat.legacy)
              ? createCompiler(realSdkContext,
                  sourceMaps: sourceMaps,
                  destructureNamedParams: destructureNamedParams,
                  closure: closure,
                  moduleFormat: moduleFormat)
              : batchCompiler;
          success = compile(compiler, filePath);

          var outFile = new File(path.join(outDir.path, '$filename.js'));
          expect(!success || outFile.existsSync(), true,
              reason: '${outFile.path} was created if compilation succeeds');
        });
      }
    });
  }

  if (codeCoverage) {
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
            new SourceResolverOptions(
                dartSdkPath:
                    path.join(testDirectory, '..', 'tool', 'generated_sdk')));

        // Get the test SDK. We use a checked in copy so test expectations can
        // be generated against a specific SDK version.
        var compiler = createCompiler(testSdkContext, checkSdk: true);
        compile(compiler, 'dart:core');
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
    var success = compile(batchCompiler, filePath);

    var expectedFiles = ['sunflower.html', 'sunflower.js',];

    for (var filepath in expectedFiles) {
      var outFile = new File(path.join(expectDir, 'sunflower', filepath));
      expect(outFile.existsSync(), success,
          reason: '${outFile.path} was created iff compilation succeeds');
    }
  });

  test('devc jscodegen html_input.html', () {
    var filePath = path.join(inputDir, 'html_input.html');
    var success = compile(batchCompiler, filePath);

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

  void logInformation(String message, [CaughtException exception]) {}
  void logInformation2(String message, Object exception) {}
}
