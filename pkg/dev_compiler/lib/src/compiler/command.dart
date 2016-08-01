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
  final MessageHandler messageHandler;
  CompilerOptions _compilerOptions;

  CompileCommand({MessageHandler messageHandler})
      : this.messageHandler = messageHandler ?? print {
    argParser.addOption('out', abbr: 'o', help: 'Output file (required)');
    argParser.addOption('module-root',
        help: 'Root module directory. '
            'Generated module paths are relative to this root.');
    argParser.addOption('library-root',
        help: 'Root of source files. '
            'Generated library names are relative to this root.');
    argParser.addOption('build-root',
        help: 'Deprecated in favor of --library-root');
    CompilerOptions.addArguments(argParser);
    AnalyzerOptions.addArguments(argParser);
  }

  get name => 'compile';
  get description => 'Compile a set of Dart files into a JavaScript module.';

  @override
  void run() {
    var compiler =
        new ModuleCompiler(new AnalyzerOptions.fromArguments(argResults));
    _compilerOptions = new CompilerOptions.fromArguments(argResults);
    var outPath = argResults['out'];

    if (outPath == null) {
      usageException('Please include the output file location. For example:\n'
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
        usageException('Output file $outPath must be within the module root '
            'directory $moduleRoot');
      }
      modulePath =
          path.withoutExtension(path.relative(outPath, from: moduleRoot));
    } else {
      moduleRoot = path.dirname(outPath);
      modulePath = path.basenameWithoutExtension(outPath);
    }

    if (argResults.rest.isEmpty) {
      usageException('Please pass at least one source file as an argument.');
    }

    var unit = new BuildUnit(modulePath, libraryRoot, argResults.rest,
        (source) => _moduleForLibrary(moduleRoot, source));

    JSModuleFile module = compiler.compile(unit, _compilerOptions);
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
      var summaryPath = path.withoutExtension(outPath) +
          '.${_compilerOptions.summaryExtension}';
      new File(summaryPath).writeAsBytesSync(module.summaryBytes);
    }
  }

  String _moduleForLibrary(String moduleRoot, Source source) {
    if (source is InSummarySource) {
      var summaryPath = source.summaryPath;
      var ext = '.${_compilerOptions.summaryExtension}';
      if (path.isWithin(moduleRoot, summaryPath) && summaryPath.endsWith(ext)) {
        var buildUnitPath =
            summaryPath.substring(0, summaryPath.length - ext.length);
        return path.relative(buildUnitPath, from: moduleRoot);
      }

      throw usageException(
          'Imported file ${source.uri} is not within the module root '
          'directory $moduleRoot');
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
