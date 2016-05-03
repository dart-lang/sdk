// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests code generation.
/// Runs Dart Dev Compiler on all input in the `codegen` directory and checks
/// that the output is what we expected.
library dev_compiler.test.codegen_test;

import 'dart:convert' show JSON;
import 'dart:io' show Directory, File, Platform;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:path/path.dart' as path;
import 'package:test/test.dart' show group, test;

import 'package:analyzer/analyzer.dart'
    show
        ExportDirective,
        ImportDirective,
        StringLiteral,
        UriBasedDirective,
        parseDirectives;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:dev_compiler/src/analyzer/context.dart' show AnalyzerOptions;
import 'package:dev_compiler/src/compiler/compiler.dart'
    show BuildUnit, CompilerOptions, ModuleCompiler;
import 'testing.dart' show testDirectory;
import 'multitest.dart' show extractTestsFromMultitest, isMultiTest;
import '../tool/build_sdk.dart' as build_sdk;
import 'package:dev_compiler/src/compiler/compiler.dart';

final ArgParser argParser = new ArgParser()
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null);

main(arguments) {
  if (arguments == null) arguments = [];
  ArgResults args = argParser.parse(arguments);
  var filePattern = new RegExp(args.rest.length > 0 ? args.rest[0] : '.');

  var expectDir = path.join(inputDir, 'expect');
  var testDirs = [
    'language',
    path.join('lib', 'typed_data'),
    path.join('lib', 'html')
  ];

  var multitests = expandMultiTests(testDirs, filePattern);

  // Build packages tests depend on
  var compiler = new ModuleCompiler(
      new AnalyzerOptions(customUrlMappings: packageUrlMappings));

  group('dartdevc package', () {
    _buildPackages(compiler, expectDir);

    test('matcher', () {
      _buildMatcher(compiler, expectDir);
    });
  });

  test('dartdevc sunflower', () {
    _buildSunflower(compiler, expectDir);
  });

  // Our default compiler options. Individual tests can override these.
  var defaultOptions = ['--no-source-map', '--no-summarize'];
  var compilerArgParser = CompilerOptions.addArguments(new ArgParser());

  var allDirs = [null];
  allDirs.addAll(testDirs);
  for (var dir in allDirs) {
    if (codeCoverage && dir != null) continue;

    group('dartdevc ' + path.join('test', 'codegen', dir), () {
      var outDir = new Directory(path.join(expectDir, dir));
      if (!outDir.existsSync()) outDir.createSync(recursive: true);

      var baseDir = path.join(inputDir, dir);
      var testFiles = _findTests(baseDir, filePattern);
      for (var filePath in testFiles) {
        if (multitests.contains(filePath)) continue;

        var filename = path.basenameWithoutExtension(filePath);

        test('$filename.dart', () {
          // Check if we need to use special compile options.
          var contents = new File(filePath).readAsStringSync();
          var match =
              new RegExp(r'// compile options: (.*)').matchAsPrefix(contents);

          var args = new List.from(defaultOptions);
          if (match != null) {
            args.addAll(match.group(1).split(' '));
          }
          var options =
              new CompilerOptions.fromArguments(compilerArgParser.parse(args));

          // Collect any other files we've imported.
          var files = new Set<String>();
          _collectTransitiveImports(contents, files, from: filePath);
          var moduleName =
              path.withoutExtension(path.relative(filePath, from: inputDir));
          var unit = new BuildUnit(
              moduleName, baseDir, files.toList(), _moduleForLibrary);
          var module = compiler.compile(unit, options);
          _writeModule(path.join(outDir.path, filename), module);
        });
      }
    });
  }

  if (codeCoverage) {
    test('build_sdk code coverage', () {
      var generatedSdkDir =
          path.join(testDirectory, '..', 'tool', 'generated_sdk');
      return build_sdk.main(['--dart-sdk', generatedSdkDir, '-o', expectDir]);
    });
  }
}

void _writeModule(String outPath, JSModuleFile result) {
  new Directory(path.dirname(outPath)).createSync(recursive: true);

  result.errors.add(''); // for trailing newline
  new File(outPath + '.txt').writeAsStringSync(result.errors.join('\n'));

  if (result.isValid) {
    new File(outPath + '.js').writeAsStringSync(result.code);
    if (result.sourceMap != null) {
      var mapPath = outPath + '.js.map';
      new File(mapPath)
          .writeAsStringSync(JSON.encode(result.placeSourceMap(mapPath)));
    }
  }
}

void _buildSunflower(ModuleCompiler compiler, String expectDir) {
  var baseDir = path.join(inputDir, 'sunflower');
  var files = ['sunflower', 'circle', 'painter']
      .map((f) => path.join(baseDir, '$f.dart'))
      .toList();
  var input = new BuildUnit('sunflower', baseDir, files, _moduleForLibrary);
  var options = new CompilerOptions(summarizeApi: false);

  var built = compiler.compile(input, options);
  _writeModule(path.join(expectDir, 'sunflower', 'sunflower'), built);
}

void _buildPackages(ModuleCompiler compiler, String expectDir) {
  // Note: we don't summarize these, as we're going to rely on our in-memory
  // shared analysis context for caching, and `_moduleForLibrary` below
  // understands these are from other modules.
  var options = new CompilerOptions(sourceMap: false, summarizeApi: false);

  for (var uri in packageUrlMappings.keys) {
    assert(uri.startsWith('package:'));
    var uriPath = uri.substring('package:'.length);
    var name = path.basenameWithoutExtension(uriPath);
    test(name, () {
      var input = new BuildUnit(name, inputDir, [uri], _moduleForLibrary);
      var built = compiler.compile(input, options);

      var outPath = path.join(expectDir, path.withoutExtension(uriPath));
      _writeModule(outPath, built);
    });
  }
}

void _buildMatcher(ModuleCompiler compiler, String expectDir) {
  var options = new CompilerOptions(sourceMap: false, summarizeApi: false);

  var packageRoot = path.join(inputDir, 'packages');
  var filePath = path.join(packageRoot, 'matcher', 'matcher.dart');
  var contents = new File(filePath).readAsStringSync();

  // Collect any other files we've imported.
  var files = new Set<String>();
  _collectTransitiveImports(contents, files,
      packageRoot: packageRoot, from: filePath);

  var unit =
      new BuildUnit('matcher', inputDir, files.toList(), _moduleForLibrary);
  var module = compiler.compile(unit, options);

  var outPath = path.join(expectDir, 'matcher', 'matcher');
  _writeModule(outPath, module);
}

String _moduleForLibrary(Source source) {
  var scheme = source.uri.scheme;
  if (scheme == 'package') {
    return source.uri.pathSegments.first;
  }
  throw new Exception('Module not found for library "${source.fullName}"');
}

/// Expands wacky multitests into a bunch of test files.
///
/// We'll compile each one as if it was an input.
/// NOTE: this will write the individual test files to disk.
Set<String> expandMultiTests(List testDirs, RegExp filePattern) {
  var multitests = new Set<String>();

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
  return multitests;
}

// TODO(jmesserly): switch this to a .packages file.
final packageUrlMappings = {
  'package:expect/expect.dart': path.join(inputDir, 'expect.dart'),
  'package:async_helper/async_helper.dart':
      path.join(inputDir, 'async_helper.dart'),
  'package:unittest/unittest.dart': path.join(inputDir, 'unittest.dart'),
  'package:unittest/html_config.dart': path.join(inputDir, 'html_config.dart'),
  'package:js/js.dart': path.join(inputDir, 'packages', 'js', 'js.dart')
};

final codeCoverage = Platform.environment.containsKey('COVERALLS_TOKEN');

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
  return directive.validate() == null ? uriContent : null;
}
