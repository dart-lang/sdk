// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummarySource;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:args/command_runner.dart' show UsageException;
import 'package:path/path.dart' as path;

import '../analyzer/context.dart' show AnalyzerOptions;
import 'compiler.dart' show BuildUnit, CompilerOptions, ModuleCompiler;
import 'module_builder.dart';

final ArgParser _argParser = () {
  var argParser = new ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Display this message.')
    ..addOption('out',
        abbr: 'o', allowMultiple: true, help: 'Output file (required).')
    ..addOption('module-root',
        help: 'Root module directory.\n'
            'Generated module paths are relative to this root.')
    ..addOption('library-root',
        help: 'Root of source files.\n'
            'Generated library names are relative to this root.')
    ..addOption('build-root',
        help: 'Deprecated in favor of --library-root', hide: true);
  addModuleFormatOptions(argParser, allowMultiple: true);
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
    https://github.com/dart-lang/sdk/issues/labels/area-dev-compiler
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

bool _changed(List<int> list1, List<int> list2) {
  var length = list1.length;
  if (length != list2.length) return true;
  for (var i = 0; i < length; ++i) {
    if (list1[i] != list2[i]) return true;
  }
  return false;
}

void _compile(ArgResults argResults, void printFn(Object obj)) {
  var compiler =
      new ModuleCompiler(new AnalyzerOptions.fromArguments(argResults));
  var compilerOpts = new CompilerOptions.fromArguments(argResults);
  if (argResults['help']) {
    printFn(_usageMessage);
    return;
  }
  var outPaths = argResults['out'] as List<String>;
  var moduleFormats = parseModuleFormatOption(argResults);
  bool singleOutFile = argResults['single-out-file'];
  if (singleOutFile) {
    for (var format in moduleFormats) {
      if (format != ModuleFormat.amd && format != ModuleFormat.legacy) {
        _usageException('Format $format cannot be combined with '
            'single-out-file. Only amd and legacy modes are supported.');
      }
    }
  }

  if (outPaths.isEmpty) {
    _usageException('Please include the output file location. For example:\n'
        '    -o PATH/TO/OUTPUT_FILE.js');
  } else if (outPaths.length != moduleFormats.length) {
    _usageException('Number of output files (${outPaths.length}) must match '
        'number of module formats (${moduleFormats.length}).');
  }

  // TODO(jmesserly): for now the first one is special. This will go away once
  // we've removed the "root" and "module name" variables.
  var firstOutPath = outPaths[0];

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
    if (!path.isWithin(moduleRoot, firstOutPath)) {
      _usageException('Output file $firstOutPath must be within the module '
          'root directory $moduleRoot');
    }
    modulePath =
        path.withoutExtension(path.relative(firstOutPath, from: moduleRoot));
  } else {
    moduleRoot = path.dirname(firstOutPath);
    modulePath = path.basenameWithoutExtension(firstOutPath);
  }

  var unit = new BuildUnit(modulePath, libraryRoot, argResults.rest,
      (source) => _moduleForLibrary(moduleRoot, source, compilerOpts));

  var module = compiler.compile(unit, compilerOpts);
  module.errors.forEach(printFn);

  if (!module.isValid) throw new CompileErrorException();

  // Write JS file, as well as source map and summary (if requested).
  for (var i = 0; i < outPaths.length; i++) {
    var outPath = outPaths[i];
    module.writeCodeSync(moduleFormats[i], singleOutFile, outPath);
    if (module.summaryBytes != null) {
      var summaryPath =
          path.withoutExtension(outPath) + '.${compilerOpts.summaryExtension}';
      // Only overwrite if summary changed.  This plays better with timestamp
      // based build systems.
      var file = new File(summaryPath);
      if (!file.existsSync() ||
          _changed(file.readAsBytesSync(), module.summaryBytes)) {
        file.writeAsBytesSync(module.summaryBytes);
      }
    }
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
