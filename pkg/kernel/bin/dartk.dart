#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:kernel/checks.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/log.dart';

ArgParser parser = new ArgParser()
  ..addOption('format',
      abbr: 'f',
      allowed: ['text', 'bin'],
      help: 'Output format.\n'
          '(defaults to "text" unless output file ends with ".bart")')
  ..addOption('out',
      abbr: 'o',
      help: 'Output file.\n'
          '(defaults to "out.bart" if format is "bin", otherwise stdout)')
  ..addOption('sdk',
      defaultsTo: '/usr/lib/dart', // TODO: Locate the SDK more intelligently.
      help: 'Path to the Dart SDK.')
  ..addOption('package-root',
      abbr: 'p',
      help: 'Path to the packages folder.\n'
          'The .packages file is not yet supported.')
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
  ..addFlag('sanity-check',
      help: 'Perform slow internal correctness checks.');

String getUsage() => """
Usage: dartk [options] FILE

Convert .dart or .bart files to kernel's IR and print out its textual
or binary form.

Examples:
    dartk foo.dart            # print text IR for foo.dart
    dartk foo.dart -ofoo.bart # write binary IR for foo.dart to foo.bart
    dartk foo.bart            # print text IR for binary file foo.bart

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
  if (options['out'] != null && options['out'].endsWith('.bart')) {
    return 'bin';
  }
  return 'text';
}

String defaultOutput() {
  if (options['format'] == 'bin') {
    return 'out.bart';
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

main(List<String> args) {
  if (args.isEmpty) {
    return fail(getUsage());
  }

  // The args package requires all options before the FILE, so reorder the
  // arguments so the options are first.
  var optionArgs = args.where((x) => x.startsWith('-')).toList();
  var otherArgs = args.where((x) => !x.startsWith('-')).toList();
  if (otherArgs.length != 1) {
    if (optionArgs.any((x) => x.startsWith('--') && !x.contains('='))) {
      return fail('Exactly one FILE should be given. '
          'Note that options are passed on form --option=VALUE.');
    }
    return fail('Exactly one FILE should be given.');
  }
  args = <List<String>>[optionArgs, otherArgs].expand((x) => x).toList();

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

  var file = options.rest.single;

  checkIsFile(file, option: 'Input file');

  String format = options['format'] ?? defaultFormat();
  String outputFile = options['out'] ?? defaultOutput();

  var repository = new AnalyzerRepository(
      sdk: options['sdk'],
      packageRoot: options['package-root'],
      strongMode: options['strong']);

  Library library;
  Program program;

  var watch = new Stopwatch()..start();
  List<String> loadedFiles;
  Function getLoadedFiles;

  if (file.endsWith('.bart')) {
    var node = loadProgramOrLibraryFromBinary(file, repository);
    library = node is Library ? node : null;
    program = node is Program ? node : null;
    if (options['link'] && program == null) {
      loadEverythingFromBinary(repository);
      program = new Program(repository.libraries);
    }
    getLoadedFiles = () => [file];
  } else {
    if (options['link']) {
      program = loadProgramFromDart(file, repository);
    } else {
      library = loadLibraryFromDart(file, repository);
      loadEverythingFromDart(repository);
    }
    getLoadedFiles = () => loadedFiles ??= repository.getAnalyzerLoader().getLoadedFileNames();
  }

  int loadTime = watch.elapsedMilliseconds;
  if (shouldReportMetrics) {
    print('loader.time = $loadTime ms');
  }

  if (options['sanity-check']) {
    CheckParentPointers.check(program ?? library);
  }

  String outputDependencies = options['write-dependencies'];
  if (outputDependencies != null) {
    new File(outputDependencies).writeAsStringSync(getLoadedFiles().join('\n'));
  }

  assert(program != null || library != null);
  assert(library == null ||
      program == null ||
      program.libraries.contains(library));

  if (options['no-output']) {
    return null;
  }

  watch.reset();

  Future ioFuture;
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

  if (shouldReportMetrics) {
    int time = watch.elapsedMilliseconds;
    print('writer.time = $time ms');
    ioFuture?.then((_) {
      time = watch.elapsedMilliseconds - time;
      print('writer.flush_time = $time ms');
    });
  }
}
