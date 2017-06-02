#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../bin/batch_util.dart';
import '../bin/util.dart';

import 'package:args/args.dart';
import 'package:analyzer/src/kernel/loader.dart';
import 'package:kernel/application_root.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/verifier.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/log.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/transformations/treeshaker.dart';
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
  ..addOption('packages',
      abbr: 'p', help: 'Path to the .packages file or packages folder.')
  ..addOption('package-root', help: 'Deprecated alias for --packages')
  ..addOption('app-root',
      help: 'Store library paths relative to the given directory.\n'
          'If none is given, absolute paths are used.\n'
          'Application libraries not inside the application root are stored '
          'using absolute paths')
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
  ..addOption('url-mapping',
      allowMultiple: true,
      help: 'A custom url mapping of the form `<scheme>:<name>::<uri>`.')
  ..addOption('embedder-entry-points-manifest',
      allowMultiple: true,
      help: 'A path to a file describing entrypoints '
          '(lines of the form `<library>,<class>,<member>`).')
  ..addFlag('verbose',
      abbr: 'v',
      negatable: false,
      help: 'Print internal warnings and diagnostics to stderr.')
  ..addFlag('print-metrics',
      negatable: false, help: 'Print performance metrics.')
  ..addFlag('verify-ir', help: 'Perform slow internal correctness checks.')
  ..addFlag('tolerant',
      help: 'Generate kernel even if there are compile-time errors.',
      defaultsTo: false)
  ..addOption('D',
      abbr: 'D',
      allowMultiple: true,
      help: 'Define an environment variable.',
      hide: true)
  ..addFlag('show-external',
      help: 'When printing a library as text, also print its dependencies\n'
          'on external libraries.')
  ..addFlag('show-offsets',
      help: 'When printing a library as text, also print node offsets')
  ..addFlag('include-sdk',
      help: 'Include the SDK in the output. Implied by --link.')
  ..addFlag('tree-shake',
      defaultsTo: false, help: 'Enable tree-shaking if the target supports it');

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

    -D<name>=<value>        Define an environment variable.
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
      fail('$option is not a directory: $path');
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

void checkIsFileOrDirectoryOrNull(String path, String option) {
  if (path == null) return;
  var stat = new File(path).statSync();
  if (stat.type == FileSystemEntityType.NOT_FOUND) {
    fail('$option not found: $path');
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

Map<Uri, Uri> parseCustomUriMappings(List<String> mappings) {
  Map<Uri, Uri> customUriMappings = <Uri, Uri>{};

  fatal(String mapping) {
    fail('Invalid uri mapping "$mapping". Each mapping should have the '
        'form "<scheme>:<name>::<uri>".');
  }

  // Each mapping has the form <uri>::<uri>.
  for (var mapping in mappings) {
    List<String> parts = mapping.split('::');
    if (parts.length != 2) {
      fatal(mapping);
    }
    Uri fromUri = Uri.parse(parts[0]);
    if (fromUri.scheme == '' || fromUri.path.contains('/')) {
      fatal(mapping);
    }
    Uri toUri = Uri.parse(parts[1]);
    if (toUri.scheme == '') {
      toUri = new Uri.file(path.absolute(parts[1]));
    }
    customUriMappings[fromUri] = toUri;
  }

  return customUriMappings;
}

/// Maintains state that should be shared between batched executions when
/// running in batch mode (for testing purposes).
///
/// This reuses the analyzer's in-memory copy of the Dart SDK between runs.
class BatchModeState {
  bool isBatchMode = false;
  DartLoaderBatch batch = new DartLoaderBatch();
}

main(List<String> args) async {
  if (args.isNotEmpty && args[0] == '--batch') {
    if (args.length != 1) {
      return fail('--batch cannot be used with other arguments');
    }
    var batchModeState = new BatchModeState()..isBatchMode = true;
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

  String packagePath = options['packages'] ?? options['package-root'];
  checkIsFileOrDirectoryOrNull(packagePath, 'Package root or .packages');

  String applicationRootOption = options['app-root'];
  checkIsDirectoryOrNull(applicationRootOption, 'Application root');
  if (applicationRootOption != null) {
    applicationRootOption = new File(applicationRootOption).absolute.path;
  }
  var applicationRoot = new ApplicationRoot(applicationRootOption);

  // Set up logging.
  if (options['verbose']) {
    log.onRecord.listen((LogRecord rec) {
      stderr.writeln(rec.message);
    });
  }

  bool includeSdk = options['include-sdk'];

  List<String> inputFiles = options.rest;
  if (inputFiles.length < 1 && !includeSdk) {
    return fail('At least one file should be given.');
  }

  bool hasBinaryInput = false;
  bool hasDartInput = includeSdk;
  for (String file in inputFiles) {
    checkIsFile(file, option: 'Input file');
    if (file.endsWith('.dill')) {
      hasBinaryInput = true;
    } else if (file.endsWith('.dart')) {
      hasDartInput = true;
    } else {
      fail('Unrecognized file extension: $file');
    }
  }

  if (hasBinaryInput && hasDartInput) {
    fail('Mixed binary and dart input is not currently supported');
  }

  String format = options['format'] ?? defaultFormat();
  String outputFile = options['out'] ?? defaultOutput();

  List<String> urlMapping = options['url-mapping'] as List<String>;
  var customUriMappings = parseCustomUriMappings(urlMapping);

  List<String> embedderEntryPointManifests =
      options['embedder-entry-points-manifest'] as List<String>;
  List<ProgramRoot> programRoots =
      parseProgramRoots(embedderEntryPointManifests);

  var program = new Program();

  var watch = new Stopwatch()..start();
  List errors = const [];
  TargetFlags targetFlags = new TargetFlags(
      strongMode: options['strong'],
      treeShake: options['tree-shake'],
      kernelRuntime: Platform.script.resolve('../runtime/'),
      programRoots: programRoots);
  Target target = getTarget(options['target'], targetFlags);

  var declaredVariables = <String, String>{};
  declaredVariables.addAll(target.extraDeclaredVariables);
  for (String define in options['D']) {
    int separator = define.indexOf('=');
    if (separator == -1) {
      fail('Invalid define: -D$define. Format is -D<name>=<value>');
    }
    String name = define.substring(0, separator);
    String value = define.substring(separator + 1);
    declaredVariables[name] = value;
  }

  DartLoader loader;
  if (hasDartInput) {
    String packageDiscoveryPath =
        batchModeState.isBatchMode || inputFiles.isEmpty
            ? null
            : inputFiles.first;
    loader = await batchModeState.batch.getLoader(
        program,
        new DartOptions(
            strongMode: target.strongMode,
            strongModeSdk: target.strongModeSdk,
            sdk: options['sdk'],
            packagePath: packagePath,
            customUriMappings: customUriMappings,
            declaredVariables: declaredVariables,
            applicationRoot: applicationRoot),
        packageDiscoveryPath: packageDiscoveryPath);
    if (includeSdk) {
      for (var uri in batchModeState.batch.dartSdk.uris) {
        loader.loadLibrary(Uri.parse(uri));
      }
    }
    loader.loadSdkInterface(program, target);
  }

  for (String file in inputFiles) {
    Uri fileUri = Uri.base.resolve(file);

    if (file.endsWith('.dill')) {
      loadProgramFromBinary(file, program);
    } else {
      if (options['link']) {
        loader.loadProgram(fileUri, target: target);
      } else {
        var library = loader.loadLibrary(fileUri);
        program.mainMethod ??= library.procedures
            .firstWhere((p) => p.name.name == 'main', orElse: () => null);
      }
      errors = loader.errors;
      if (errors.isNotEmpty) {
        const int errorLimit = 100;
        stderr.writeln(errors.take(errorLimit).join('\n'));
        if (errors.length > errorLimit) {
          stderr.writeln(
              '[error] ${errors.length - errorLimit} errors not shown');
        }
      }
    }
  }

  bool canContinueCompilation = errors.isEmpty || options['tolerant'];

  int loadTime = watch.elapsedMilliseconds;
  if (shouldReportMetrics) {
    print('loader.time = $loadTime ms');
  }

  void runVerifier() {
    if (options['verify-ir']) {
      verifyProgram(program);
    }
  }

  if (canContinueCompilation) {
    runVerifier();
  }

  if (options['link'] && program.mainMethodName == null) {
    fail('[error] The program has no main method.');
  }

  // Apply target-specific transformations.
  if (target != null && canContinueCompilation) {
    CoreTypes coreTypes = new CoreTypes(program);
    ClassHierarchy hierarchy = new ClosedWorldClassHierarchy(program);
    target.performModularTransformationsOnProgram(
        coreTypes, hierarchy, program);
    runVerifier();
    if (options['link']) {
      target.performGlobalTransformations(coreTypes, program);
      runVerifier();
    }
  }

  if (options['no-output']) {
    return CompilerOutcome.Ok;
  }

  watch.reset();

  Future ioFuture;
  if (canContinueCompilation) {
    switch (format) {
      case 'text':
        writeProgramToText(program,
            path: outputFile,
            showExternal: options['show-external'],
            showOffsets: options['show-offsets']);
        break;
      case 'bin':
        ioFuture = writeProgramToBinary(program, outputFile);
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

  if (options['tolerant']) {
    return CompilerOutcome.Ok;
  }

  return errors.length > 0 ? CompilerOutcome.Fail : CompilerOutcome.Ok;
}
