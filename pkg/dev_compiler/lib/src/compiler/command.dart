// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JSON;
import 'dart:io';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummarySource;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:args/command_runner.dart' show UsageException;
import 'package:path/path.dart' as path;

import 'compiler.dart'
    show BuildUnit, CompilerOptions, JSModuleFile, ModuleCompiler;
import '../analyzer/context.dart' show AnalyzerOptions;

final ArgParser _argParser = () {
  var argParser = new ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Display this message.')
    ..addOption('out', abbr: 'o', help: 'Output file (required).')
    ..addOption('module-root',
        help: 'Root module directory.\n'
            'Generated module paths are relative to this root.')
    ..addOption('library-root',
        help: 'Root of source files.\n'
            'Generated library names are relative to this root.')
    ..addOption('build-root',
        help: 'Deprecated in favor of --library-root', hide: true);
  AnalyzerOptions.addArguments(argParser);
  CompilerOptions.addArguments(argParser);
  return argParser;
}();

/// Runs a single compile for dartdevc.
///
/// This handles argument parsing, usage, error handling.
/// See bin/dartdevc.dart for the actual entry point, which includes Bazel
/// worker support.
int compile(List<String> args, {void printFn(Object obj)}) {
  printFn ??= print;
  ArgResults argResults;
  try {
    argResults = _argParser.parse(args);
  } on FormatException catch (error) {
    printFn('$error\n\n$_usageMessage');
    return 64;
  }
  try {
    _compile(argResults, printFn);
    return 0;
  } on UsageException catch (error) {
    // Incorrect usage, input file not found, etc.
    printFn(error);
    return 64;
  } on CompileErrorException catch (error) {
    // Code has error(s) and failed to compile.
    printFn(error);
    return 1;
  } catch (error, stackTrace) {
    // Anything else is likely a compiler bug.
    //
    // --unsafe-force-compile is a bit of a grey area, but it's nice not to
    // crash while compiling
    // (of course, output code may crash, if it had errors).
    //
    printFn('''
We're sorry, you've found a bug in our compiler.
You can report this bug at:
    https://github.com/dart-lang/dev_compiler/issues
Please include the information below in your report, along with
any other information that may help us track it down. Thanks!
    dartdevc arguments: ${args.join(' ')}
    dart --version: ${Platform.version}
```
$error
$stackTrace
```''');
    return 70;
  }
}

void _compile(ArgResults argResults, void printFn(Object obj)) {
  var compiler =
      new ModuleCompiler(new AnalyzerOptions.fromArguments(argResults));
  var compilerOpts = new CompilerOptions.fromArguments(argResults);
  if (argResults['help']) {
    printFn(_usageMessage);
    return;
  }
  var outPath = argResults['out'];

  if (outPath == null) {
    _usageException('Please include the output file location. For example:\n'
        '    -o PATH/TO/OUTPUT_FILE.js');
  }

  var libraryRoot = argResults['library-root'] as String;
  libraryRoot ??= argResults['build-root'] as String;
  if (libraryRoot != null) {
    libraryRoot = path.absolute(libraryRoot);
  } else {
    libraryRoot = Directory.current.path;
  }
  var moduleRoot = argResults['module-root'] as String;
  String modulePath;
  if (moduleRoot != null) {
    moduleRoot = path.absolute(moduleRoot);
    if (!path.isWithin(moduleRoot, outPath)) {
      _usageException('Output file $outPath must be within the module root '
          'directory $moduleRoot');
    }
    modulePath =
        path.withoutExtension(path.relative(outPath, from: moduleRoot));
  } else {
    moduleRoot = path.dirname(outPath);
    modulePath = path.basenameWithoutExtension(outPath);
  }

  var unit = new BuildUnit(modulePath, libraryRoot, argResults.rest,
      (source) => _moduleForLibrary(moduleRoot, source, compilerOpts));

  JSModuleFile module = compiler.compile(unit, compilerOpts);
  module.errors.forEach(printFn);

  if (!module.isValid) throw new CompileErrorException();

  // Write JS file, as well as source map and summary (if requested).
  new File(outPath).writeAsStringSync(module.code);
  if (module.sourceMap != null) {
    var mapPath = outPath + '.map';
    new File(mapPath)
        .writeAsStringSync(JSON.encode(module.placeSourceMap(mapPath)));
  }
  if (module.summaryBytes != null) {
    var summaryPath =
        path.withoutExtension(outPath) + '.${compilerOpts.summaryExtension}';
    new File(summaryPath).writeAsBytesSync(module.summaryBytes);
  }
}

String _moduleForLibrary(
    String moduleRoot, Source source, CompilerOptions compilerOpts) {
  if (source is InSummarySource) {
    var summaryPath = source.summaryPath;
    var ext = '.${compilerOpts.summaryExtension}';
    if (path.isWithin(moduleRoot, summaryPath) && summaryPath.endsWith(ext)) {
      var buildUnitPath =
          summaryPath.substring(0, summaryPath.length - ext.length);
      return path.relative(buildUnitPath, from: moduleRoot);
    }

    _usageException('Imported file ${source.uri} is not within the module root '
        'directory $moduleRoot');
  }

  _usageException(
      'Imported file "${source.uri}" was not found as a summary or source '
      'file. Please pass in either the summary or the source file '
      'for this import.');
  return null; // unreachable
}

final _usageMessage =
    'Dart Development Compiler compiles Dart into a JavaScript module.'
    '\n\n${_argParser.usage}';

void _usageException(String message) {
  throw new UsageException(message, _usageMessage);
}

/// Thrown when the input source code has errors.
class CompileErrorException implements Exception {
  toString() => '\nPlease fix all errors before compiling (warnings are okay).';
}
