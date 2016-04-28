// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JSON;
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummarySource;
import 'compiler.dart'
    show BuildUnit, CompilerOptions, JSModuleFile, ModuleCompiler;
import '../analyzer/context.dart' show AnalyzerOptions;
import 'package:path/path.dart' as path;

typedef void MessageHandler(Object message);

/// The command for invoking the modular compiler.
class CompileCommand extends Command {
  get name => 'compile';
  get description => 'Compile a set of Dart files into a JavaScript module.';
  final MessageHandler messageHandler;

  CompileCommand({MessageHandler messageHandler})
      : this.messageHandler = messageHandler ?? print {
    argParser.addOption('out', abbr: 'o', help: 'Output file (required)');
    argParser.addOption('build-root',
        help: '''
Root of source files.  Generated library names are relative to this root.
''');
    CompilerOptions.addArguments(argParser);
    AnalyzerOptions.addArguments(argParser);
  }

  @override
  void run() {
    var compiler =
        new ModuleCompiler(new AnalyzerOptions.fromArguments(argResults));
    var compilerOptions = new CompilerOptions.fromArguments(argResults);
    var outPath = argResults['out'];

    if (outPath == null) {
      usageException('Please include the output file location. For example:\n'
          '    -o PATH/TO/OUTPUT_FILE.js');
    }

    var buildRoot = argResults['build-root'] as String;
    if (buildRoot != null) {
      buildRoot = path.absolute(buildRoot);
    } else {
      buildRoot = Directory.current.path;
    }
    var unit = new BuildUnit(path.basenameWithoutExtension(outPath), buildRoot,
        argResults.rest, _moduleForLibrary);

    JSModuleFile module = compiler.compile(unit, compilerOptions);
    module.errors.forEach(messageHandler);

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

/// Thrown when the input source code has errors.
class CompileErrorException implements Exception {
  toString() => '\nPlease fix all errors before compiling (warnings are okay).';
}
