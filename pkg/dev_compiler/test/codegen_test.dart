// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests code generation.
///
/// Runs Dart Dev Compiler on all input in the `codegen` directory and checks
/// that the output is what we expected.
library dev_compiler.test.codegen_test;

// TODO(rnystrom): This doesn't actually run any tests any more. It just
// compiles stuff. This should be changed to not use unittest and just be a
// regular program that outputs files.

import 'dart:io' show Directory, File, Platform;
import 'package:analyzer/analyzer.dart'
    show
        ExportDirective,
        ImportDirective,
        StringLiteral,
        UriBasedDirective,
        parseDirectives;
import 'package:analyzer/src/command_line/arguments.dart'
    show defineAnalysisArguments;
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:dev_compiler/src/analyzer/context.dart';
import 'package:dev_compiler/src/compiler/compiler.dart'
    show BuildUnit, CompilerOptions, JSModuleFile, ModuleCompiler;
import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat, addModuleFormatOptions, parseModuleFormatOption;
import 'package:path/path.dart' as path;
import 'package:test/test.dart' show expect, isFalse, isTrue, test;

import '../tool/build_sdk.dart' as build_sdk;
import 'compile_error_tests.dart';
import 'multitest.dart' show extractTestsFromMultitest, isMultiTest;
import 'testing.dart' show repoDirectory, testDirectory;

final ArgParser argParser = new ArgParser()
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null);

/// The `test/codegen` directory.
final codegenDir = path.join(testDirectory, 'codegen');

/// The `test/codegen/expect` directory.
final codegenExpectDir = path.join(testDirectory, 'codegen_expected');

/// The generated directory where tests, expanded multitests, and other test
/// support libraries are copied to.
///
/// The tests sometimes import utility libraries using a relative path.
/// Likewise, the multitests do too, and one multitest even imports its own
/// non-expanded form (!). To make that simpler, we copy the entire test tree
/// to a generated directory and expand that multitests in there too.
final codegenTestDir = path.join(repoDirectory, 'gen', 'codegen_tests');

/// The generated directory where tests and packages compiled to JS are
/// output.
final codegenOutputDir = path.join(repoDirectory, 'gen', 'codegen_output');

final codeCoverage = Platform.environment.containsKey('COVERALLS_TOKEN');

RegExp filePattern;

main(List<String> arguments) {
  if (arguments == null) arguments = [];
  ArgResults args = argParser.parse(arguments);
  filePattern = new RegExp(args.rest.length > 0 ? args.rest[0] : '.');

  var sdkDir = path.join(repoDirectory, 'gen', 'patched_sdk');
  var sdkSummaryFile =
      path.join(testDirectory, '..', 'lib', 'sdk', 'ddc_sdk.sum');

  var summaryPaths = new Directory(path.join(codegenOutputDir, 'pkg'))
      .listSync()
      .map((e) => e.path)
      .where((p) => p.endsWith('.sum'))
      .toList();

  var sharedCompiler = new ModuleCompiler(new AnalyzerOptions.basic(
      dartSdkSummaryPath: sdkSummaryFile, summaryPaths: summaryPaths));

  var testDirs = [
    'language',
    'corelib',
    path.join('lib', 'async'),
    path.join('lib', 'collection'),
    path.join('lib', 'convert'),
    path.join('lib', 'html'),
    path.join('lib', 'math'),
    path.join('lib', 'mirrors'),
    path.join('lib', 'typed_data'),
  ];

  // Copy all of the test files and expanded multitest files to
  // gen/codegen_tests. We'll compile from there.
  var testFiles = _setUpTests(testDirs);

  // Our default compiler options. Individual tests can override these.
  var defaultOptions = ['--no-source-map', '--no-summarize'];
  var compileArgParser = new ArgParser();
  defineAnalysisArguments(compileArgParser, ddc: true);
  AnalyzerOptions.addArguments(compileArgParser);
  CompilerOptions.addArguments(compileArgParser);
  addModuleFormatOptions(compileArgParser);

  var testFileOptionsMatcher =
      new RegExp(r'// (compile options: |SharedOptions=)(.*)', multiLine: true);

  // Ignore dart2js options that we don't support in DDC.
  var ignoreOptions = [
    '--enable-enum',
    '--experimental-trust-js-interop-type-annotations',
    '--trust-type-annotations',
    '--supermixin'
  ];

  // Compile each test file to JS and put the result in gen/codegen_output.
  for (var testFile in testFiles) {
    var relativePath = path.relative(testFile, from: codegenTestDir);

    // Only compile the top-level files for generating coverage.
    bool isTopLevelTest = path.dirname(relativePath) == ".";
    if (codeCoverage && !isTopLevelTest) continue;

    var name = path.withoutExtension(relativePath);
    test('dartdevc $name', () {
      // Check if we need to use special compile options.
      var contents = new File(testFile).readAsStringSync();
      var match = testFileOptionsMatcher.firstMatch(contents);

      var args = defaultOptions.toList();
      if (match != null) {
        var matchedArgs = match.group(2).split(' ');
        args.addAll(matchedArgs.where((s) => !ignoreOptions.contains(s)));
      }

      ArgResults argResults = compileArgParser.parse(args);
      var analyzerOptions = new AnalyzerOptions.fromArguments(argResults,
          dartSdkSummaryPath: sdkSummaryFile, summaryPaths: summaryPaths);

      var options = new CompilerOptions.fromArguments(argResults);

      var moduleFormat = parseModuleFormatOption(argResults).first;

      // Collect any other files we've imported.
      var files = new Set<String>();
      _collectTransitiveImports(contents, files, from: testFile);
      var unit = new BuildUnit(
          name, path.dirname(testFile), files.toList(), _moduleForLibrary);

      var compiler = sharedCompiler;
      if (analyzerOptions.declaredVariables.isNotEmpty) {
        compiler = new ModuleCompiler(analyzerOptions);
      }
      JSModuleFile module = null;
      var exception, stackTrace;
      try {
        module = compiler.compile(unit, options);
      } catch (e, st) {
        exception = e;
        stackTrace = st;
      }

      // This covers tests where the intent of the test is to validate that
      // some static error is produced.
      var intentionalCompileError = contents.contains(': compile-time error') ||
          contents.contains('/*@compile-error=');

      // This covers tests that should not produce a static error but that
      // currently do due to issues in our implementation.
      var knownCompileError = compileErrorTests.contains(name);

      var crashing = _crashingTests.contains(name);
      var inconsistent = _inconsistentTests.contains(name);

      if (module == null) {
        expect(crashing, isTrue,
            reason: "test $name crashes during compilation.\n"
                "$exception\n$stackTrace");
        return;
      }

      // Write out JavaScript and/or compilation errors/warnings.
      _writeModule(
          path.join(codegenOutputDir, name),
          isTopLevelTest ? path.join(codegenExpectDir, name) : null,
          moduleFormat,
          module);

      expect(crashing, isFalse, reason: "test $name no longer crashes.");

      if (inconsistent) {
        // An inconsistent test will only compile on some platforms (see
        // comment below). It should not crash however.
      } else if (module.isValid) {
        // TODO(vsm): We don't seem to trip on non-strong errors?
        // expect(expectedCompileTimeError, isFalse,
        //    reason: "test $name expected compilation errors, but compiled.");
        expect(knownCompileError, isFalse,
            reason: "test $name expected static errors, but compiled.");
      } else {
        var reason = intentionalCompileError ? "intended" : "unexpected";
        expect(intentionalCompileError || knownCompileError, isTrue,
            reason: "test $name failed to compile due to $reason errors:"
                "\n\n${module.errors.join('\n')}.");
      }
    });
  }

  if (filePattern.hasMatch('sunflower')) {
    test('sunflower', () {
      _buildSunflower(sharedCompiler, codegenOutputDir, codegenExpectDir);
    });
  }

  if (codeCoverage) {
    test('build_sdk code coverage', () {
      return build_sdk.main(['--dart-sdk', sdkDir, '-o', codegenOutputDir]);
    });
  }
}

void _writeModule(String outPath, String expectPath, ModuleFormat format,
    JSModuleFile result) {
  _ensureDirectory(path.dirname(outPath));

  String errors = result.errors.join('\n');
  if (errors.isNotEmpty && !errors.endsWith('\n')) errors += '\n';
  new File(outPath + '.txt').writeAsStringSync(errors);

  if (result.isValid) {
    result.writeCodeSync(format, outPath + '.js');
  }

  if (result.summaryBytes != null) {
    new File(outPath + '.sum').writeAsBytesSync(result.summaryBytes);
  }

  // Write the expectation file if needed.
  // Generally speaking we try to avoid these tests, but they are occasionally
  // useful.
  if (expectPath != null) {
    _ensureDirectory(path.dirname(expectPath));

    var expectFile = new File(expectPath + '.js');
    if (result.isValid) {
      result.writeCodeSync(format, expectFile.path);
    } else {
      expectFile.writeAsStringSync("//FAILED TO COMPILE");
    }
  }
}

void _buildSunflower(
    ModuleCompiler compiler, String outputDir, String expectDir) {
  var baseDir = path.join(codegenDir, 'sunflower');
  var files = ['sunflower', 'circle', 'painter']
      .map((f) => path.join(baseDir, '$f.dart'))
      .toList();
  var input = new BuildUnit('sunflower', baseDir, files, _moduleForLibrary);
  var options = new CompilerOptions(summarizeApi: false);

  var built = compiler.compile(input, options);
  _writeModule(path.join(outputDir, 'sunflower', 'sunflower'),
      path.join(expectDir, 'sunflower', 'sunflower'), ModuleFormat.amd, built);
}

String _moduleForLibrary(Source source) {
  var scheme = source.uri.scheme;
  if (scheme == 'package') {
    return source.uri.pathSegments.first;
  }
  throw new Exception('Module not found for library "${source.fullName}"');
}

List<String> _setUpTests(List<String> testDirs) {
  var testFiles = <String>[];

  for (var testDir in testDirs) {
    // TODO(rnystrom): Simplify this when the Dart 2.0 test migration is
    // complete (#30183).
    // Look for the tests in the "_strong" and "_2" directories in the SDK's
    // main "tests" directory.
    var dirParts = path.split(testDir);

    for (var suffix in const ["_2", "_strong"]) {
      var sdkTestDir =
          path.join(dirParts[0] + suffix, path.joinAll(dirParts.skip(1)));
      var inputPath =
          path.join(testDirectory, '..', '..', '..', 'tests', sdkTestDir);

      if (!new Directory(inputPath).existsSync()) continue;

      for (var file in _listFiles(inputPath, recursive: true)) {
        var relativePath = path.relative(file, from: inputPath);
        var outputPath = path.join(codegenTestDir, testDir, relativePath);

        _ensureDirectory(path.dirname(outputPath));

        if (file.endsWith("_test.dart")) {

          void _writeTest(String outputPath, String contents) {
            if (contents.contains('package:unittest/')) {
              // TODO(jmesserly): we could use directive parsing, but that
              // feels like overkill.
              // Alternatively, we could detect "unittest" use at runtime.
              // We really need a better solution for Karma+mocha+unittest
              // integration.
              contents += '\nfinal _usesUnittestPackage = true;\n';
            }
            new File(outputPath).writeAsStringSync(contents);
          }

          var contents = new File(file).readAsStringSync();
          if (isMultiTest(contents)) {
            // It's a multitest, so expand it and add all of the variants.
            var tests = <String, String>{};
            var outcomes = <String, Set<String>>{};
            extractTestsFromMultitest(file, contents, tests, outcomes);

            var fileName = path.basenameWithoutExtension(file);
            var outputDir = path.dirname(outputPath);
            tests.forEach((name, contents) {
              var multiFile =
                  path.join(outputDir, '${fileName}_${name}_multi.dart');
              testFiles.add(multiFile);

              _writeTest(multiFile, contents);
            });
          } else {
            // It's a single test suite.
            testFiles.add(outputPath);
          }

          // Write the test file.
          //
          // We do this even for multitests because import_self_test
          // is a multitest, yet imports its own unexpanded form (!).
          _writeTest(outputPath, contents);

        } else {
          // Copy the non-test file over, in case it is used as an import.
          new File(file).copySync(outputPath);
        }
      }
    }
  }

  // Also include the other special files that live at the top level directory.
  for (var file in _listFiles(codegenDir)) {
    var relativePath = path.relative(file, from: codegenDir);
    var outputPath = path.join(codegenTestDir, relativePath);

    new File(file).copySync(outputPath);
    if (file.endsWith(".dart")) {
      testFiles.add(outputPath);
    }
  }

  return testFiles;
}

/// Recursively creates [dir] if it doesn't exist.
void _ensureDirectory(String dir) {
  new Directory(dir).createSync(recursive: true);
}

/// Lists all of the files within [dir] that match [filePattern].
Iterable<String> _listFiles(String dir, {bool recursive: false}) {
  return new Directory(dir)
      .listSync(recursive: recursive, followLinks: false)
      .where((entry) {
    if (entry is! File) return false;

    var filePath = entry.path;
    if (!filePattern.hasMatch(filePath)) return false;

    return true;
  }).map((file) => file.path);
}

/// Parse directives from [contents] and find the complete set of transitive
/// imports, reading files as needed.
///
/// This will not include dart:* libraries, as those are implicitly available.
void _collectTransitiveImports(String contents, Set<String> libraries,
    {String packageRoot, String from}) {
  var uri = from;
  if (packageRoot != null && path.isWithin(packageRoot, from)) {
    uri = 'package:${path.relative(from, from: packageRoot)}';
  }
  if (!libraries.add(uri)) return;

  var unit = parseDirectives(contents, name: from, suppressErrors: true);
  for (var d in unit.directives) {
    if (d is ImportDirective || d is ExportDirective) {
      String uri = _resolveDirective(d);
      if (uri == null ||
          uri.startsWith('dart:') ||
          uri.startsWith('package:')) {
        continue;
      }

      var f = new File(path.join(path.dirname(from), uri));
      if (f.existsSync()) {
        _collectTransitiveImports(f.readAsStringSync(), libraries,
            packageRoot: packageRoot, from: f.path);
      }
    }
  }
}

/// Simplified from ParseDartTask.resolveDirective.
String _resolveDirective(UriBasedDirective directive) {
  StringLiteral uriLiteral = directive.uri;
  String uriContent = uriLiteral.stringValue;
  if (uriContent != null) {
    uriContent = uriContent.trim();
    directive.uriContent = uriContent;
  }
  return (directive as UriBasedDirectiveImpl).validate() == null
      ? uriContent
      : null;
}

/// Tests that, due to bugs, are strong-mode clean only on some platforms.
final _inconsistentTests = new Set<String>.from([
  // This test is clean on windows, but not linux/mac due to newline encoding.
  // See: https://github.com/dart-lang/sdk/issues/27224
  'language/multiline_newline_test_02_multi',
].map((p) => p.replaceAll('/', path.separator)));

final _crashingTests = new Set<String>.from([
  // TODO(vsm): Fix these - they import files from a different directory
  // - this triggers an invalid library root build error.
  'lib/html/custom/attribute_changed_callback_test',
  'lib/html/custom/constructor_calls_created_synchronously_test',
  'lib/html/custom/entered_left_view_test',
  'lib/html/custom/js_custom_test',
  'lib/html/custom/mirrors_test',
  'lib/html/custom/regress_194523002_test',
].map((p) => p.replaceAll('/', path.separator)));
