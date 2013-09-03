// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Helper library to run tests in content_shell
 */
library polymer.testing.end2end;

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:polymer/deploy.dart' as deploy;


/**
 * Compiles [testFile] with the web-ui compiler, and then runs the output as a
 * unit test in content_shell.
 */
void endToEndTests(String inputDir, String outDir, {List<String> arguments}) {
  _testHelper(new _TestOptions(inputDir, inputDir, null, outDir,
      arguments: arguments));
}

/**
 * Compiles [testFile] with the web-ui compiler, and then runs the output as a
 * render test in content_shell.
 */
void renderTests(String webDir, String inputDir, String expectedDir,
    String outDir, {List<String> arguments, String script, String pattern,
    bool deleteDir: true}) {
  _testHelper(new _TestOptions(webDir, inputDir, expectedDir, outDir,
      arguments: arguments, script: script, pattern: pattern,
      deleteDir: deleteDir));
}

void _testHelper(_TestOptions options) {
  expect(options, isNotNull);

  var paths = new Directory(options.inputDir).listSync()
      .where((f) => f is File).map((f) => f.path)
      .where((p) => p.endsWith('_test.html') && options.pattern.hasMatch(p));

  if (paths.isEmpty) return;

  // First clear the output folder. Otherwise we can miss bugs when we fail to
  // generate a file.
  var dir = new Directory(options.outDir);
  if (dir.existsSync() && options.deleteDir) {
    print('Cleaning old output for ${path.normalize(options.outDir)}');
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);

  for (var filePath in paths) {
    var filename = path.basename(filePath);
    test('compile $filename', () {
      return deploy.runForTest(options.webDir, options.outDir);
    });
  }

  var filenames = paths.map(path.basename).toList();
  // Sort files to match the order in which run.sh runs diff.
  filenames.sort();

  var finalOutDir = path.join(options.outDir, options.inputDir);
  var outBaseDir = path.join(options.outDir, options.webDir);

  runTests(String search) {
    var output;

    for (var filename in filenames) {
      test('content_shell run $filename$search', () {
        var lnArgs = ['-s', '$outBaseDir/packages', '$finalOutDir/packages'];
        return Process.run('ln', lnArgs).then((_) {
          var args = ['--dump-render-tree',
              'file://$finalOutDir/$filename$search'];
          var env = {'DART_FLAGS': '--checked'};
          return Process.run('content_shell', args, environment: env)
              .then((res) {
                expect(res.exitCode, 0, reason: 'content_shell exit code: '
                    '${res.exitCode}. Contents of stderr: \n${res.stderr}');
                var outs = res.stdout.split('#EOF\n')
                  .where((s) => !s.trim().isEmpty).toList();
                expect(outs.length, 1);
                output = outs.first;
              });
        });
      });

      test('verify $filename $search', () {
        expect(output, isNotNull, reason:
          'Output not available, maybe content_shell failed to run.');
        var outPath = path.join(options.outDir, '$filename.txt');
        new File(outPath).writeAsStringSync(output);
        if (options.isRenderTest) {
          var expectedPath = path.join(options.expectedDir, '$filename.txt');
          var expected = new File(expectedPath).readAsStringSync();
          expect(output, expected, reason: 'unexpected output for <$filename>');
        } else {
          bool passes = matches(
              new RegExp('All .* tests passed')).matches(output, {});
          expect(passes, true, reason: 'unit test failed:\n$output');
        }
      });
    }
  }

  bool compiled = false;
  ensureCompileToJs() {
    if (compiled) return;
    compiled = true;

    for (var filename in filenames) {
      test('dart2js $filename', () {
        // TODO(jmesserly): this depends on DWC's output scheme.
        // Alternatively we could use html5lib to find the script tag.
        var inPath = '${filename}_bootstrap.dart';
        var outPath = '${inPath}.js';

        inPath = path.join(finalOutDir, inPath);
        outPath = path.join(finalOutDir, outPath);

        expect(Process.run('dart2js', ['-o$outPath', inPath]).then((res) {
          expect(res.exitCode, 0, reason: 'dart2js exit code: '
            '${res.exitCode}. Contents of stderr: \n${res.stderr}. '
            'Contents of stdout: \n${res.stdout}.');
          expect(new File(outPath).existsSync(), true, reason: 'input file '
            '$inPath should have been compiled to $outPath.');
        }), completes);
      });
    }
  }

  if (options.runAsDart) {
    runTests('');
  }
  if (options.runAsJs) {
    ensureCompileToJs();
    runTests('?js=1');
  }
  if (options.forcePolyfillShadowDom) {
    ensureCompileToJs();
    runTests('?js=1&shadowdomjs=1');
  }
}

class _TestOptions {
  final String webDir;
  final String inputDir;

  final String expectedDir;
  bool get isRenderTest => expectedDir != null;

  final String outDir;
  final bool deleteDir;

  final bool runAsDart;
  final bool runAsJs;
  final bool forcePolyfillShadowDom;

  final List<String> compilerArgs;
  final RegExp pattern;

  factory _TestOptions(String webDir, String inputDir, String expectedDir,
      String outDir, {List<String> arguments, String script, String pattern,
      bool deleteDir: true}) {
    if (arguments == null) arguments = new Options().arguments;
    if (script == null) script = new Options().script;

    var args = _parseArgs(arguments, script);
    if (args == null) return null;
    var compilerArgs = args.rest;
    var filePattern;
    if (pattern != null) {
      filePattern = new RegExp(pattern);
    } else if (compilerArgs.length > 0) {
      filePattern = new RegExp(compilerArgs[0]);
      compilerArgs = compilerArgs.sublist(1);
    } else {
      filePattern = new RegExp('.');
    }

    var scriptDir = path.absolute(path.dirname(script));
    webDir = path.relative(path.join(scriptDir, webDir));
    inputDir = path.relative(path.join(scriptDir, inputDir));
    outDir = path.join(scriptDir, outDir);
    if (expectedDir != null) {
      expectedDir = path.join(scriptDir, expectedDir);
    }

    return new _TestOptions._(webDir, inputDir, expectedDir, outDir, deleteDir,
        args['dart'] == true, args['js'] == true, args['shadowdom'] == true,
        compilerArgs, filePattern);
  }

  _TestOptions._(this.webDir, this.inputDir, this.expectedDir, this.outDir,
      this.deleteDir, this.runAsDart, this.runAsJs,
      this.forcePolyfillShadowDom, this.compilerArgs, this.pattern);
}

ArgResults _parseArgs(List<String> arguments, String script) {
  var parser = new ArgParser()
    ..addFlag('dart', abbr: 'd', help: 'run on Dart VM', defaultsTo: true)
    ..addFlag('js', abbr: 'j', help: 'run compiled dart2js', defaultsTo: true)
    ..addFlag('shadowdom', abbr: 's',
        help: 'run dart2js and polyfilled ShadowDOM', defaultsTo: true)
    ..addFlag('help', abbr: 'h', help: 'Displays this help message',
        defaultsTo: false, negatable: false);

  showUsage() {
    print('Usage: $script [options...] [test_name_regexp]');
    print(parser.getUsage());
    return null;
  }

  try {
    var results = parser.parse(arguments);
    if (results['help']) return showUsage();
    return results;
  } on FormatException catch (e) {
    print(e.message);
    return showUsage();
  }
}
