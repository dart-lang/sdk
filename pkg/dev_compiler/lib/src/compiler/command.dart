// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:analyzer/src/command_line/arguments.dart'
    show defineAnalysisArguments, ignoreUnrecognizedFlagsFlag;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show ConflictingSummaryException, InSummarySource;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:args/command_runner.dart' show UsageException;
import 'package:path/path.dart' as path;

import '../analyzer/context.dart' show AnalyzerOptions;
import 'compiler.dart' show BuildUnit, CompilerOptions, ModuleCompiler;
import 'module_builder.dart';

const _binaryName = 'dartdevc';

bool _verbose = false;

/// Runs a single compile for dartdevc.
///
/// This handles argument parsing, usage, error handling.
/// See bin/dartdevc.dart for the actual entry point, which includes Bazel
/// worker support.
int compile(List<String> args, {void printFn(Object obj)}) {
  printFn ??= print;

  ArgResults argResults;
  AnalyzerOptions analyzerOptions;
  try {
    var parser = ddcArgParser();
    if (args.contains('--$ignoreUnrecognizedFlagsFlag')) {
      args = filterUnknownArguments(args, parser);
    }
    argResults = parser.parse(args);
    analyzerOptions = new AnalyzerOptions.fromArguments(argResults);
  } on FormatException catch (error) {
    printFn('$error\n\n$_usageMessage');
    return 64;
  }

  _verbose = argResults['verbose'];
  if (argResults['help'] || args.isEmpty) {
    printFn(_usageMessage);
    return 0;
  }

  if (argResults['version']) {
    printFn('$_binaryName version ${_getVersion()}');
    return 0;
  }

  try {
    _compile(argResults, analyzerOptions, printFn);
    return 0;
  } on UsageException catch (error) {
    // Incorrect usage, input file not found, etc.
    printFn(error);
    return 64;
  } on ConflictingSummaryException catch (error) {
    // Same input file appears in multiple provided summaries.
    printFn(error);
    return 65;
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
    $_binaryName arguments: ${args.join(' ')}
    dart --version: ${Platform.version}
```
$error
$stackTrace
```''');
    return 70;
  }
}

ArgParser ddcArgParser({bool hide: true}) {
  var argParser = new ArgParser(allowTrailingOptions: true)
    ..addFlag('help',
        abbr: 'h',
        help: 'Display this message. Add --verbose to show hidden options.',
        negatable: false)
    ..addFlag('verbose', abbr: 'v', help: 'Verbose output.')
    ..addFlag('version',
        negatable: false, help: 'Print the $_binaryName version.')
    ..addFlag(ignoreUnrecognizedFlagsFlag,
        help: 'Ignore unrecognized command line flags.',
        defaultsTo: false,
        negatable: false)
    ..addOption('out',
        abbr: 'o', allowMultiple: true, help: 'Output file (required).')
    ..addOption('module-root',
        help: 'Root module directory. '
            'Generated module paths are relative to this root.')
    ..addOption('library-root',
        help: 'Root of source files. '
            'Generated library names are relative to this root.');
  defineAnalysisArguments(argParser, hide: hide, ddc: true);
  addModuleFormatOptions(argParser, allowMultiple: true, hide: hide);
  AnalyzerOptions.addArguments(argParser, hide: hide);
  CompilerOptions.addArguments(argParser, hide: hide);
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

void _compile(ArgResults argResults, AnalyzerOptions analyzerOptions,
    void printFn(Object obj)) {
  var compiler = new ModuleCompiler(analyzerOptions);
  var compilerOpts = new CompilerOptions.fromArguments(argResults);
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

  var unit = new BuildUnit(
      modulePath,
      libraryRoot,
      argResults.rest,
      (source) =>
          _moduleForLibrary(moduleRoot, source, analyzerOptions, compilerOpts));

  var module = compiler.compile(unit, compilerOpts);
  module.errors.forEach(printFn);

  if (!module.isValid) {
    throw compilerOpts.unsafeForceCompile
        ? new ForceCompileErrorException()
        : new CompileErrorException();
  }

  // Write JS file, as well as source map and summary (if requested).
  for (var i = 0; i < outPaths.length; i++) {
    module.writeCodeSync(moduleFormats[i], outPaths[i],
        singleOutFile: singleOutFile);
  }
  if (module.summaryBytes != null) {
    var summaryPaths = compilerOpts.summaryOutPath != null
        ? [compilerOpts.summaryOutPath]
        : outPaths.map((p) =>
            '${path.withoutExtension(p)}.${compilerOpts.summaryExtension}');

    // place next to every compiled module
    for (var summaryPath in summaryPaths) {
      // Only overwrite if summary changed.  This plays better with timestamp
      // based build systems.
      var file = new File(summaryPath);
      if (!file.existsSync() ||
          _changed(file.readAsBytesSync(), module.summaryBytes)) {
        if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
        file.writeAsBytesSync(module.summaryBytes);
      }
    }
  }
}

String _moduleForLibrary(String moduleRoot, Source source,
    AnalyzerOptions analyzerOptions, CompilerOptions compilerOpts) {
  if (source is InSummarySource) {
    var summaryPath = source.summaryPath;

    if (analyzerOptions.customSummaryModules.containsKey(summaryPath)) {
      return analyzerOptions.customSummaryModules[summaryPath];
    }

    var ext = '.${compilerOpts.summaryExtension}';
    if (path.isWithin(moduleRoot, summaryPath) && summaryPath.endsWith(ext)) {
      var buildUnitPath =
          summaryPath.substring(0, summaryPath.length - ext.length);
      return path.url
          .joinAll(path.split(path.relative(buildUnitPath, from: moduleRoot)));
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

String get _usageMessage =>
    'The Dart Development Compiler compiles Dart sources into a JavaScript '
    'module.\n\n'
    'Usage: $_binaryName [options...] <sources...>\n\n'
    '${ddcArgParser(hide: !_verbose).usage}';

String _getVersion() {
  try {
    // This is relative to bin/snapshot, so ../..
    String versionPath = Platform.script.resolve('../../version').toFilePath();
    File versionFile = new File(versionPath);
    return versionFile.readAsStringSync().trim();
  } catch (_) {
    // This happens when the script is not running in the context of an SDK.
    return "<unknown>";
  }
}

void _usageException(String message) {
  throw new UsageException(message, _usageMessage);
}

/// Thrown when the input source code has errors.
class CompileErrorException implements Exception {
  toString() => '\nPlease fix all errors before compiling (warnings are okay).';
}

/// Thrown when force compilation failed (probably due to static errors).
class ForceCompileErrorException extends CompileErrorException {
  toString() =>
      '\nForce-compilation not successful. Please check static errors.';
}

// TODO(jmesserly): fix this function in analyzer
List<String> filterUnknownArguments(List<String> args, ArgParser parser) {
  Set<String> knownOptions = new Set<String>();
  Set<String> knownAbbreviations = new Set<String>();
  parser.options.forEach((String name, option) {
    knownOptions.add(name);
    String abbreviation = option.abbreviation;
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
