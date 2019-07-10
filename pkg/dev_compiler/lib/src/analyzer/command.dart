// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:analyzer/src/command_line/arguments.dart'
    show defineAnalysisArguments, ignoreUnrecognizedFlagsFlag;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show ConflictingSummaryException;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:args/command_runner.dart' show UsageException;
import 'package:path/path.dart' as p;

import '../compiler/shared_command.dart' show CompilerResult;
import 'context.dart' show AnalyzerOptions;
import 'driver.dart';
import 'module_compiler.dart';

const _binaryName = 'dartdevc';

bool _verbose = false;

/// Runs a single compile for dartdevc.
///
/// This handles argument parsing, usage, error handling.
/// See bin/dartdevc.dart for the actual entry point, which includes Bazel
/// worker support.
CompilerResult compile(List<String> args,
    {CompilerAnalysisDriver compilerState}) {
  ArgResults argResults;
  AnalyzerOptions analyzerOptions;
  try {
    var parser = ddcArgParser();
    if (args.contains('--$ignoreUnrecognizedFlagsFlag')) {
      args = filterUnknownArguments(args, parser);
    }
    argResults = parser.parse(args);
    analyzerOptions = AnalyzerOptions.fromArguments(argResults);
  } on FormatException catch (error) {
    print('$error\n\n$_usageMessage');
    return CompilerResult(64);
  }

  _verbose = argResults['verbose'] as bool;
  if (argResults['help'] as bool || args.isEmpty) {
    print(_usageMessage);
    return CompilerResult(0);
  }

  if (argResults['version'] as bool) {
    print('$_binaryName version ${_getVersion()}');
    return CompilerResult(0);
  }

  try {
    var driver = _compile(argResults, analyzerOptions);
    return CompilerResult(0, analyzerState: driver);
  } on UsageException catch (error) {
    // Incorrect usage, input file not found, etc.
    print('${error.message}\n\n$_usageMessage');
    return CompilerResult(64);
  } on ConflictingSummaryException catch (error) {
    // Same input file appears in multiple provided summaries.
    print(error);
    return CompilerResult(65);
  } on CompileErrorException catch (error) {
    // Code has error(s) and failed to compile.
    print(error);
    return CompilerResult(1);
  } catch (error, stackTrace) {
    // Anything else is likely a compiler bug.
    //
    // --unsafe-force-compile is a bit of a grey area, but it's nice not to
    // crash while compiling
    // (of course, output code may crash, if it had errors).
    //
    print('''
We're sorry, you've found a bug in our compiler.
You can report this bug at:
    https://github.com/dart-lang/sdk/issues/labels/area-dev-compiler
Please include the information below in your report, along with
any other information that may help us track it down. Thanks!
    $_binaryName arguments: ${args.join(' ')}
    dart --version: ${Platform.version}
```
$error
$stackTrace
```''');
    return CompilerResult(70);
  }
}

ArgParser ddcArgParser(
    {bool hide = true, bool help = true, ArgParser argParser}) {
  argParser ??= ArgParser(allowTrailingOptions: true);
  if (help) {
    argParser.addFlag('help',
        abbr: 'h',
        help: 'Display this message. Add -v to show hidden options.',
        negatable: false);
  }
  argParser
    ..addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Verbose help output.', hide: hide)
    ..addFlag('version',
        negatable: false, help: 'Print the $_binaryName version.', hide: hide)
    ..addFlag(ignoreUnrecognizedFlagsFlag,
        help: 'Ignore unrecognized command line flags.',
        defaultsTo: false,
        hide: hide)
    ..addMultiOption('out', abbr: 'o', help: 'Output file (required).');
  CompilerOptions.addArguments(argParser, hide: hide);
  defineAnalysisArguments(argParser, hide: hide, ddc: true);
  AnalyzerOptions.addArguments(argParser, hide: hide);
  return argParser;
}

bool _changed(List<int> list1, List<int> list2) {
  var length = list1.length;
  if (length != list2.length) return true;
  for (var i = 0; i < length; ++i) {
    if (list1[i] != list2[i]) return true;
  }
  return false;
}

CompilerAnalysisDriver _compile(
    ArgResults argResults, AnalyzerOptions analyzerOptions,
    {CompilerAnalysisDriver compilerDriver}) {
  var compilerOpts = CompilerOptions.fromArguments(argResults);

  var summaryPaths = compilerOpts.summaryModules.keys.toList();
  if (compilerDriver == null ||
      !compilerDriver.isCompatibleWith(analyzerOptions, summaryPaths)) {
    compilerDriver = CompilerAnalysisDriver(analyzerOptions,
        summaryPaths: summaryPaths, experiments: compilerOpts.experiments);
  }
  var outPaths = argResults['out'] as List<String>;
  var moduleFormats = compilerOpts.moduleFormats;
  if (outPaths.isEmpty) {
    throw UsageException(
        'Please specify the output file location. For example:\n'
            '    -o PATH/TO/OUTPUT_FILE.js',
        '');
  } else if (outPaths.length != moduleFormats.length) {
    throw UsageException(
        'Number of output files (${outPaths.length}) must match '
            'number of module formats (${moduleFormats.length}).',
        '');
  }

  var module = compileWithAnalyzer(
    compilerDriver,
    argResults.rest,
    analyzerOptions,
    compilerOpts,
  );
  module.errors.forEach(print);

  if (!module.isValid) {
    throw compilerOpts.unsafeForceCompile
        ? ForceCompileErrorException()
        : CompileErrorException();
  }

  // Write JS file, as well as source map and summary (if requested).
  for (var i = 0; i < outPaths.length; i++) {
    module.writeCodeSync(moduleFormats[i], outPaths[i]);
  }
  if (compilerOpts.summarizeApi) {
    var summaryPaths = compilerOpts.summaryOutPath != null
        ? [compilerOpts.summaryOutPath]
        : outPaths.map((path) =>
            '${p.withoutExtension(path)}.${compilerOpts.summaryExtension}');

    // place next to every compiled module
    for (var summaryPath in summaryPaths) {
      // Only overwrite if summary changed.  This plays better with timestamp
      // based build systems.
      var file = File(summaryPath);
      if (!file.existsSync() ||
          _changed(file.readAsBytesSync(), module.summaryBytes)) {
        if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
        file.writeAsBytesSync(module.summaryBytes);
      }
    }
  }
  return compilerDriver;
}

String get _usageMessage =>
    'The Dart Development Compiler compiles Dart sources into a JavaScript '
    'module.\n\n'
    'Usage: $_binaryName [options...] <sources...>\n\n'
    '${ddcArgParser(hide: !_verbose).usage}';

String _getVersion() {
  try {
    // This is relative to bin/snapshot, so ../..
    String versionPath = Platform.script.resolve('../../version').toFilePath();
    File versionFile = File(versionPath);
    return versionFile.readAsStringSync().trim();
  } catch (_) {
    // This happens when the script is not running in the context of an SDK.
    return "<unknown>";
  }
}

/// Thrown when the input source code has errors.
class CompileErrorException implements Exception {
  @override
  toString() => '\nPlease fix all errors before compiling (warnings are okay).';
}

/// Thrown when force compilation failed (probably due to static errors).
class ForceCompileErrorException extends CompileErrorException {
  @override
  toString() =>
      '\nForce-compilation not successful. Please check static errors.';
}

// TODO(jmesserly): fix this function in analyzer
List<String> filterUnknownArguments(List<String> args, ArgParser parser) {
  Set<String> knownOptions = Set<String>();
  Set<String> knownAbbreviations = Set<String>();
  parser.options.forEach((String name, option) {
    knownOptions.add(name);
    String abbreviation = option.abbr;
    if (abbreviation != null) {
      knownAbbreviations.add(abbreviation);
    }
  });
  List<String> filtered = <String>[];
  for (int i = 0; i < args.length; i++) {
    String argument = args[i];
    if (argument.startsWith('--') && argument.length > 2) {
      int equalsOffset = argument.lastIndexOf('=');
      int end = equalsOffset < 0 ? argument.length : equalsOffset;
      if (knownOptions.contains(argument.substring(2, end))) {
        filtered.add(argument);
      }
    } else if (argument.startsWith('-') && argument.length > 1) {
      // TODO(jmesserly): fix this line in analyzer
      // It was discarding abbreviations such as -Da=b
      // Abbreviations must be 1-character (this is enforced by ArgParser),
      // so we don't need to use `optionName`
      if (knownAbbreviations.contains(argument[1])) {
        filtered.add(argument);
      }
    } else {
      filtered.add(argument);
    }
  }
  return filtered;
}
