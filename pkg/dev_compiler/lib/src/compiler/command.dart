// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JSON;
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummarySource;
import 'package:bazel_worker/bazel_worker.dart';
import 'compiler.dart'
    show BuildUnit, CompilerOptions, JSModuleFile, ModuleCompiler;
import '../analyzer/context.dart' show AnalyzerOptions;
import 'package:path/path.dart' as path;

/// The command for invoking the modular compiler.
class CompileCommand extends Command {
  get name => 'compile';
  get description => 'Compile a set of Dart files into a JavaScript module.';

  CompileCommand() {
    argParser.addOption('out', abbr: 'o', help: 'Output file (required)');
    argParser.addFlag('persistent_worker',
        help: 'Run in a persistent Bazel worker (http://bazel.io/)\n',
        defaultsTo: false,
        hide: true);
    CompilerOptions.addArguments(argParser);
    AnalyzerOptions.addArguments(argParser);
  }

  @override
  void run() {
    var analyzerOptions = new AnalyzerOptions.fromArguments(argResults);
    if (argResults['persistent_worker']) {
      new _CompilerWorker(analyzerOptions, this).run();
    } else {
      compile(
          new ModuleCompiler(analyzerOptions),
          new CompilerOptions.fromArguments(argResults),
          argResults['out'],
          argResults.rest);
    }
  }

  void compile(ModuleCompiler compiler, CompilerOptions compilerOptions,
      String outPath, List<String> extraArgs,
      {void forEachError(String error): print}) {
    if (outPath == null) {
      usageException('Please include the output file location. For example:\n'
          '    -o PATH/TO/OUTPUT_FILE.js');
    }
    var unit = new BuildUnit(
        path.basenameWithoutExtension(outPath), extraArgs, _moduleForLibrary);

    JSModuleFile module = compiler.compile(unit, compilerOptions);
    module.errors.forEach(forEachError);

    if (!module.isValid) throw new CompileErrorException();

    // Write JS file, as well as source map and summary (if requested).
    new File(outPath).writeAsStringSync(module.code);
    if (module.sourceMap != null) {
      var mapPath = outPath + '.map';
      new File(mapPath)
          .writeAsStringSync(JSON.encode(module.placeSourceMap(mapPath)));
    }
    if (module.summaryBytes != null) {
      var summaryPath = path.withoutExtension(outPath) + '.sum';
      new File(summaryPath).writeAsBytesSync(module.summaryBytes);
    }
  }

  String _moduleForLibrary(Source source) {
    if (source is InSummarySource) {
      return path.basenameWithoutExtension(source.summaryPath);
    }

    throw usageException(
        'Imported file "${source.uri}" was not found as a summary or source '
        'file. Please pass in either the summary or the source file '
        'for this import.');
  }
}

/// Handles [error] in a uniform fashion. Returns the proper exit code and calls
/// [messageHandler] with messages.
int handleError(dynamic error, dynamic stackTrace, List<String> args,
    {void messageHandler(Object message): print}) {
  if (error is UsageException) {
    // Incorrect usage, input file not found, etc.
    messageHandler(error);
    return 64;
  } else if (error is CompileErrorException) {
    // Code has error(s) and failed to compile.
    messageHandler(error);
    return 1;
  } else {
    // Anything else is likely a compiler bug.
    //
    // --unsafe-force-compile is a bit of a grey area, but it's nice not to
    // crash while compiling
    // (of course, output code may crash, if it had errors).
    //
    messageHandler("");
    messageHandler("We're sorry, you've found a bug in our compiler.");
    messageHandler("You can report this bug at:");
    messageHandler("    https://github.com/dart-lang/dev_compiler/issues");
    messageHandler("");
    messageHandler(
        "Please include the information below in your report, along with");
    messageHandler(
        "any other information that may help us track it down. Thanks!");
    messageHandler("");
    messageHandler("    dartdevc arguments: " + args.join(' '));
    messageHandler("    dart --version: ${Platform.version}");
    messageHandler("");
    messageHandler("```");
    messageHandler(error);
    messageHandler(stackTrace);
    messageHandler("```");
    return 1;
  }
}

/// Thrown when the input source code has errors.
class CompileErrorException implements Exception {
  toString() => '\nPlease fix all errors before compiling (warnings are okay).';
}

/// Runs the compiler worker loop.
class _CompilerWorker extends SyncWorkerLoop {
  final AnalyzerOptions analyzerOptions;
  final CompileCommand compileCommand;

  _CompilerWorker(this.analyzerOptions, this.compileCommand) : super();

  WorkResponse performRequest(WorkRequest request) {
    var arguments = new List.from(request.arguments)
      ..addAll(compileCommand.argResults.rest);
    var argResults = compileCommand.argParser.parse(arguments);

    var output = new StringBuffer();
    try {
      compileCommand.compile(
          new ModuleCompiler(analyzerOptions),
          new CompilerOptions.fromArguments(argResults),
          argResults['out'],
          argResults.rest,
          forEachError: output.writeln);
      return new WorkResponse()
        ..exitCode = EXIT_CODE_OK
        ..output = output.toString();
    } catch (e, s) {
      var response = new WorkResponse();
      var output = new StringBuffer();
      response.exitCode =
          handleError(e, s, request.arguments, messageHandler: output.writeln);
      response.output = output.toString();
      return response;
    }
  }
}
