// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests code generation.
/// Runs Dart Dev Compiler on all input in the `codegen` directory and checks
/// that the output is what we expected.
library dev_compiler.test.codegen_test;

import 'dart:io';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine, Logger;
import 'package:analyzer/src/generated/java_engine.dart' show CaughtException;
import 'package:args/args.dart';
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import 'package:dev_compiler/devc.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/dependency_graph.dart'
    show defaultRuntimeFiles;
import 'package:dev_compiler/src/utils.dart'
    show computeHash, computeHashFromFile;
import 'package:html/parser.dart' as html;

final ArgParser argParser = new ArgParser()
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
  ..addFlag('dart-gen',
      abbr: 'd', help: 'Generate dart output', defaultsTo: false);

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

  compile(String entryPoint, String sdkPath, {bool checkSdk: false,
      bool serverMode: false, bool sourceMaps: false, String subDir}) {
    // TODO(jmesserly): add a way to specify flags in the test file, so
    // they're more self-contained.
    var runtimeDir = path.join(
        path.dirname(path.dirname(Platform.script.path)), 'lib', 'runtime');
    var options = new CompilerOptions(
        outputDir: subDir == null ? actualDir : path.join(actualDir, subDir),
        useColors: false,
        outputDart: dartGen,
        formatOutput: dartGen,
        emitSourceMaps: sourceMaps,
        forceCompile: checkSdk,
        cheapTestFormat: checkSdk,
        checkSdk: checkSdk,
        entryPointFile: entryPoint,
        dartSdkPath: sdkPath,
        runtimeDir: runtimeDir,
        serverMode: serverMode);
    return new Compiler(options).run();
  }
  var realSdk = getSdkDir(arguments).path;

  // Remove old output, and `packages` symlinks which mess up the diff.
  var dir = new Directory(actualDir);
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
      var result = compile(filePath, realSdk, sourceMaps: sourceMaps);
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

  if (dartGen || Platform.environment.containsKey('COVERALLS_TOKEN')) {
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
        // Get the test SDK. We use a checked in copy so test expectations can
        // be generated against a specific SDK version.
        var testSdk = dartGen
            ? path.join(testDir, '..', 'tool', 'input_sdk')
            : path.join(testDir, 'generated_sdk');
        var result = compile('dart:core', testSdk, checkSdk: true);
        var outputDir = new Directory(path.join(actualDir, 'core'));
        var outFile = new File(
            path.join(actualDir, dartGen ? 'core/core' : 'dart/core.js'));
        expect(outFile.existsSync(), true,
            reason: '${outFile.path} was created for dart:core');
      });
    });
  }

  var expectedRuntime =
      defaultRuntimeFiles.map((f) => 'dev_compiler/runtime/$f');

  if (!dartGen) {
    test('devc jscodegen sunflower.html', () {
      var filePath = path.join(inputDir, 'sunflower', 'sunflower.html');
      compilerMessages.writeln('// Messages from compiling sunflower.html');

      var result = compile(filePath, realSdk, subDir: 'sunflower');
      var success = !result.failure;

      // Write compiler messages to disk.
      new File(path.join(actualDir, 'sunflower', 'sunflower.txt'))
          .writeAsStringSync(compilerMessages.toString());

      var expectedFiles = [
        'sunflower.html',
        'sunflower.js',
        'sunflower.css',
        'math.png',
      ]..addAll(expectedRuntime);

      for (var filepath in expectedFiles) {
        var outFile = new File(path.join(actualDir, 'sunflower', filepath));
        expect(outFile.existsSync(), success,
            reason: '${outFile.path} was created iff compilation succeeds');
      }
    });

    test('devc jscodegen html_input.html', () {
      var filePath = path.join(inputDir, 'html_input.html');
      compilerMessages.writeln('// Messages from compiling html_input.html');

      var result = compile(filePath, realSdk);
      var success = !result.failure;

      // Write compiler messages to disk.
      new File(path.join(actualDir, 'html_input.txt'))
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
        var outFile = new File(path.join(actualDir, filepath));
        expect(outFile.existsSync(), success,
            reason: '${outFile.path} was created iff compilation succeeds');
      }

      var notExpectedFiles = [
        'dev_compiler/runtime/messages_widget.js',
        'dev_compiler/runtime/messages.css'
      ];
      for (var filepath in notExpectedFiles) {
        var outFile = new File(path.join(actualDir, filepath));
        expect(outFile.existsSync(), isFalse,
            reason: '${outFile.path} should only be generated in server mode');
      }
    });

    test('devc jscodegen html_input.html server mode', () {
      var filePath = path.join(inputDir, 'html_input.html');
      compilerMessages.writeln('// Messages from compiling html_input.html');

      var result =
          compile(filePath, realSdk, serverMode: true, subDir: 'server_mode');
      var success = !result.failure;

      // Write compiler messages to disk.
      new File(path.join(actualDir, 'server_mode', 'html_input.txt'))
          .writeAsStringSync(compilerMessages.toString());

      var expectedFiles = [
        'dir/html_input_a.js',
        'dir/html_input_b.js',
        'dir/html_input_c.js',
        'dir/html_input_d.js',
        'dir/html_input_e.js',
        'dev_compiler/runtime/messages_widget.js',
        'dev_compiler/runtime/messages.css'
      ]..addAll(expectedRuntime);

      // Parse the HTML file and verify its contents were expected.
      var htmlPath = path.join(actualDir, 'server_mode', 'html_input.html');
      var doc = html.parse(new File(htmlPath).readAsStringSync());

      for (var filepath in expectedFiles) {
        var outPath = path.join(actualDir, 'server_mode', filepath);
        expect(new File(outPath).existsSync(), success,
            reason: '$outPath was created iff compilation succeeds');

        var query;
        if (filepath.endsWith('js')) {
          var hash;
          if (filepath.startsWith('dev_compiler')) {
            hash = computeHashFromFile(outPath);
          } else {
            // TODO(jmesserly): see if we can get this to return the same
            // answer as computeHashFromFile.
            hash = computeHash(new File(outPath).readAsStringSync());
          }
          query = 'script[src="cached/$hash/$filepath"]';
        } else {
          var hash = computeHashFromFile(outPath);
          query = 'link[href="cached/$hash/$filepath"]';
        }
        expect(doc.querySelector(query), isNotNull,
            reason: "should find `$query` in $htmlPath for $outPath");
      }

      // Clean up the server mode folder, otherwise it causes diff churn.
      var dir = new Directory(path.join(actualDir, 'server_mode'));
      if (dir.existsSync()) dir.deleteSync(recursive: true);
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
