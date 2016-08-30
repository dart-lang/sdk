#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'batch_util.dart';

import 'package:analyzer/src/generated/engine.dart';
import 'package:args/args.dart';
import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/checks.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/log.dart';
import 'package:kernel/target/targets.dart';
import 'package:path/path.dart' as path;

// Returns the path to the current sdk based on `Platform.resolvedExecutable`.
String currentSdk() {
  // The dart executable should be inside dart-sdk/bin/dart.
  return path.dirname(path.dirname(path.absolute(Platform.resolvedExecutable)));
}

ArgParser parser = new ArgParser(allowTrailingOptions: true)
  ..addOption('format',
      abbr: 'f',
      allowed: ['text', 'bin'],
      help: 'Output format.\n'
          '(defaults to "text" unless output file ends with ".dill")')
  ..addOption('out',
      abbr: 'o',
      help: 'Output file.\n'
          '(defaults to "out.dill" if format is "bin", otherwise stdout)')
  ..addOption('sdk', defaultsTo: currentSdk(), help: 'Path to the Dart SDK.')
  ..addOption('package-root',
      abbr: 'p',
      help: 'Path to the packages folder.\n'
          'The .packages file is not yet supported.')
  ..addOption('target',
      abbr: 't',
      help: 'Tailor the IR to the given target.',
      allowed: targetNames,
      defaultsTo: 'vm')
  ..addFlag('strong',
      help: 'Load .dart files in strong mode.\n'
          'Does not affect loading of binary files. Strong mode support is very\n'
          'unstable and not well integrated yet.')
  ..addFlag('link', abbr: 'l', help: 'Link the whole program into one file.')
  ..addFlag('no-output', negatable: false, help: 'Do not output any files.')
  ..addFlag('verbose',
      abbr: 'v',
      negatable: false,
      help: 'Print internal warnings and diagnostics to stderr.')
  ..addFlag('print-metrics',
      negatable: false, help: 'Print performance metrics.')
  ..addOption('write-dependencies',
      help: 'Write all the .dart that were loaded to the given file.')
  ..addFlag('sanity-check', help: 'Perform slow internal correctness checks.')
  ..addFlag('tolerant',
      help: 'Generate kernel even if there are compile-time errors.',
      defaultsTo: false);

String getUsage() => """
Usage: dartk [options] FILE

Convert .dart or .dill files to kernel's IR and print out its textual
or binary form.

Examples:
    dartk foo.dart            # print text IR for foo.dart
    dartk foo.dart -ofoo.dill # write binary IR for foo.dart to foo.dill
    dartk foo.dill            # print text IR for binary file foo.dill

Options:
${parser.usage}
""";

dynamic fail(String message) {
  stderr.writeln(message);
  exit(1);
  return null;
}

ArgResults options;

String defaultFormat() {
  if (options['out'] != null && options['out'].endsWith('.dill')) {
    return 'bin';
  }
  return 'text';
}

String defaultOutput() {
  if (options['format'] == 'bin') {
    return 'out.dill';
  }
  return null;
}

void checkIsDirectoryOrNull(String path, String option) {
  if (path == null) return;
  var stat = new File(path).statSync();
  switch (stat.type) {
    case FileSystemEntityType.DIRECTORY:
    case FileSystemEntityType.LINK:
      return;
    case FileSystemEntityType.NOT_FOUND:
      throw fail('$option not found: $path');
    default:
      if (path.endsWith('.packages')) {
        throw fail('The .packages file is not supported yet.');
      }
      throw fail('$option is not a directory: $path');
  }
}

void checkIsFile(String path, {String option}) {
  var stat = new File(path).statSync();
  switch (stat.type) {
    case FileSystemEntityType.DIRECTORY:
      throw fail('$option is a directory: $path');

    case FileSystemEntityType.NOT_FOUND:
      throw fail('$option not found: $path');
  }
}

int getTotalSourceSize(List<String> files) {
  int size = 0;
  for (var filename in files) {
    size += new File(filename).statSync().size;
  }
  return size;
}

bool get shouldReportMetrics => options['print-metrics'];

void dumpString(String value, [String filename]) {
  if (filename == null) {
    print(value);
  } else {
    new File(filename).writeAsStringSync(value);
  }
}

/// Maintains state that should be shared between batched executions when
/// running in batch mode (for testing purposes).
///
/// Currently all shared state is disabled, as it causes flakiness when
/// two different test cases share the same 'part' file.
class BatchModeState {
  AnalysisContext getContext(
      String sdk_, String packageRoot_, bool strongMode_) {
    return createContext(sdk_, packageRoot_, strongMode_);
  }
}

main(List<String> args) async {
  if (args.isNotEmpty && args[0] == '--batch') {
    if (args.length != 1) {
      return fail('--batch cannot be used with other arguments');
    }
    var batchModeState = new BatchModeState();
    await runBatch((args) => batchMain(args, batchModeState));
  } else {
    CompilerOutcome outcome = await batchMain(args, new BatchModeState());
    exit(outcome == CompilerOutcome.Ok ? 0 : 1);
  }
}

bool isSupportedArgument(String arg) {
  if (arg.startsWith('--')) {
    int equals = arg.indexOf('=');
    var name = equals != -1 ? arg.substring(2, equals) : arg.substring(2);
    return parser.options.containsKey(name);
  }
  if (arg.startsWith('-')) {
    return parser.findByAbbreviation(arg.substring(1)) != null;
  }
  return true;
}

Future<CompilerOutcome> batchMain(
    List<String> args, BatchModeState batchModeState) async {
  if (args.contains('--ignore-unrecognized-flags')) {
    args = args.where(isSupportedArgument).toList();
  }

  if (args.isEmpty) {
    return fail(getUsage());
  }

  try {
    options = parser.parse(args);
  } on FormatException catch (e) {
    return fail(e.message); // Don't puke stack traces.
  }

  checkIsDirectoryOrNull(options['sdk'], 'Dart SDK');
  checkIsDirectoryOrNull(options['package-root'], 'Package root');

  // Set up logging.
  if (options['verbose']) {
    log.onRecord.listen((LogRecord rec) {
      stderr.writeln(rec.message);
    });
  }

  if (options.rest.length != 1) {
    return fail('Exactly one FILE should be given.');
  }

  var file = options.rest.single;

  checkIsFile(file, option: 'Input file');

  String format = options['format'] ?? defaultFormat();
  String outputFile = options['out'] ?? defaultOutput();
  bool strongMode = options['strong'];

  var repository =
      new Repository(sdk: options['sdk'], packageRoot: options['package-root']);

  Library library;
  Program program;

  var watch = new Stopwatch()..start();
  List<String> loadedFiles;
  Function getLoadedFiles;
  List errors = const [];
  Target target =
      options['target'] != null ? getTargetByName(options['target']) : null;

  if (file.endsWith('.dill')) {
    var node = loadProgramOrLibraryFromBinary(file, repository);
    library = node is Library ? node : null;
    program = node is Program ? node : null;
    getLoadedFiles = () => [file];
  } else {
    AnalysisContext context = batchModeState.getContext(
        repository.sdk, repository.packageRoot, strongMode);
    AnalyzerLoader loader = new AnalyzerLoader(repository, context: context);
    if (options['link']) {
      program = loader.loadProgram(file);
    } else {
      library = loader.loadLibrary(file);
      loader.loadEverything();
    }
    errors = loader.errors;
    if (errors.isNotEmpty) {
      stderr.writeln(errors.take(10).join('\n'));
    }
    getLoadedFiles = () => loadedFiles ??= loader.getLoadedFileNames();
  }

  bool canContinueCompilation = errors.isEmpty || options['tolerant'];

  int loadTime = watch.elapsedMilliseconds;
  if (shouldReportMetrics) {
    print('loader.time = $loadTime ms');
  }

  void sanityCheck() {
    if (options['sanity-check']) {
      CheckParentPointers.check(program ?? library);
    }
  }

  sanityCheck();

  String outputDependencies = options['write-dependencies'];
  if (outputDependencies != null) {
    new File(outputDependencies).writeAsStringSync(getLoadedFiles().join('\n'));
  }

  assert(program != null || library != null);
  assert(library == null ||
      program == null ||
      program.libraries.contains(library));

  // Apply target-specific transformations.
  if (target != null && program != null && canContinueCompilation) {
    target.transformProgram(program);
    sanityCheck();
  }

  if (options['no-output']) {
    return CompilerOutcome.Ok;
  }

  watch.reset();

  Future ioFuture;
  if (canContinueCompilation) {
    switch (format) {
      case 'text':
        if (program != null) {
          writeProgramToText(program, outputFile);
        } else {
          writeLibraryToText(library, outputFile);
        }
        break;
      case 'bin':
        if (program != null) {
          ioFuture = writeProgramToBinary(program, outputFile);
        } else {
          ioFuture = writeLibraryToBinary(library, outputFile);
        }
        break;
    }
  }

  int time = watch.elapsedMilliseconds;
  if (shouldReportMetrics) {
    print('writer.time = $time ms');
  }

  await ioFuture;

  if (shouldReportMetrics) {
    int flushTime = watch.elapsedMilliseconds - time;
    print('writer.flush_time = $flushTime ms');
  }

  return errors.length > 0 ? CompilerOutcome.Fail : CompilerOutcome.Ok;
}
