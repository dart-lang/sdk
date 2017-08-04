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

import 'dart:convert';
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

  // Copy all of the test files and expanded multitest files to
  // gen/codegen_tests. We'll compile from there.
  var testFiles = _setUpTests();

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

      if (module == null) {
        expect(false, true,
            reason: "test $name crashes during compilation.\n"
                "$exception\n$stackTrace");
        return;
      }

      // Write out JavaScript and/or compilation errors/warnings.
      _writeModule(path.join(codegenOutputDir, name),
          path.join(codegenExpectDir, name), moduleFormat, module);

      expect(module.isValid, true,
          reason: "test $name failed to compile due to unexpected errors:"
              "\n\n${module.errors.join('\n')}.");
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

List<String> _setUpTests() {
  var testFiles = [];
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
      .where((e) => e is File && filePattern.hasMatch(e.path))
      .map((f) => f.path);
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
