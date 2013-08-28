// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Common logic to make it easy to create a `build.dart` for your project.
 *
 * The `build.dart` script is invoked automatically by the Editor whenever a
 * file in the project changes. It must be placed in the root of a project
 * (where pubspec.yaml lives) and should be named exactly 'build.dart'.
 *
 * A common `build.dart` would look as follows:
 *
 *     import 'dart:io';
 *     import 'package:polymer/component_build.dart';
 *
 *     main() => build(new Options().arguments, ['web/index.html']);
 */
library build_utils;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

import 'dwc.dart' as dwc;
import 'src/utils.dart';
import 'src/compiler_options.dart';

/**
 * Set up 'build.dart' to compile with the dart web components compiler every
 * [entryPoints] listed. On clean commands, the directory where [entryPoints]
 * live will be scanned for generated files to delete them.
 */
// TODO(jmesserly): we need a better way to automatically detect input files
Future<List<dwc.CompilerResult>> build(List<String> arguments,
    List<String> entryPoints,
    {bool printTime: true, bool shouldPrint: true}) {
  bool useColors = stdioType(stdout) == StdioType.TERMINAL;
  return asyncTime('Total time', () {
    var args = _processArgs(arguments);
    var tasks = new FutureGroup();
    var lastTask = new Future.value(null);
    tasks.add(lastTask);

    var changedFiles = args["changed"];
    var removedFiles = args["removed"];
    var cleanBuild = args["clean"];
    var machineFormat = args["machine"];
    // Also trigger a full build if the script was run from the command line
    // with no arguments
    var fullBuild = args["full"] || (!machineFormat && changedFiles.isEmpty &&
        removedFiles.isEmpty && !cleanBuild);

    var options = CompilerOptions.parse(args.rest, checkUsage: false);

    // [outputOnlyDirs] contains directories known to only have output files.
    // When outputDir is not specified, we create a new directory which only
    // contains output files. If options.outputDir is specified, we don't know
    // if the output directory may also have input files. In which case,
    // [_handleCleanCommand] and [_isInputFile] are more conservative.
    //
    // TODO(sigmund): get rid of this. Instead, use the compiler to understand
    // which files are input or output files.
    var outputOnlyDirs = options.outputDir == null ? []
        : entryPoints.map((e) => _outDir(e)).toList();

    if (cleanBuild) {
      _handleCleanCommand(outputOnlyDirs);
    } else if (fullBuild
        || changedFiles.any((f) => _isInputFile(f, outputOnlyDirs))
        || removedFiles.any((f) => _isInputFile(f, outputOnlyDirs))) {
      for (var file in entryPoints) {
        var dwcArgs = new List.from(args.rest);
        if (machineFormat) dwcArgs.add('--json_format');
        if (!useColors) dwcArgs.add('--no-colors');
        // We'll set 'out/' as the out folder, unless an output directory was
        // already specified in the command line.
        if (options.outputDir == null) dwcArgs.addAll(['-o', _outDir(file)]);
        dwcArgs.add(file);
        // Chain tasks to that we run one at a time.
        lastTask = lastTask.then((_) => dwc.run(dwcArgs, printTime: printTime,
            shouldPrint: shouldPrint));
        if (machineFormat) {
          lastTask = lastTask.then((res) {
            appendMessage(Map jsonMessage) {
              var message = JSON.encode([jsonMessage]);
              if (shouldPrint) print(message);
              res.messages.add(message);
            }
            // Print for the Editor messages about mappings and generated files
            res.outputs.forEach((out, input) {
              if (out.endsWith(".html") && input != null) {
                appendMessage({
                  "method": "mapping",
                  "params": {"from": input, "to": out},
                });
              }
              appendMessage({"method": "generated", "params": {"file": out}});
            });
            return res;
          });
        }
        tasks.add(lastTask);
      }
    }
    return tasks.future.then((r) => r.where((v) => v != null));
  }, printTime: printTime, useColors: useColors);
}

String _outDir(String file) => path.join(path.dirname(file), 'out');

/** Tell whether [filePath] is a generated file. */
bool _isGeneratedFile(String filePath, List<String> outputOnlyDirs) {
  var dirPrefix = path.dirname(filePath);
  for (var outDir in outputOnlyDirs) {
    if (dirPrefix.startsWith(outDir)) return true;
  }
  return path.basename(filePath).startsWith('_');
}

/** Tell whether [filePath] is an input file. */
bool _isInputFile(String filePath, List<String> outputOnlyDirs) {
  var ext = path.extension(filePath);
  return (ext == '.dart' || ext == '.html') &&
      !_isGeneratedFile(filePath, outputOnlyDirs);
}

/**
 * Delete all generated files. Currently we only delete files under directories
 * that are known to contain only generated code.
 */
void _handleCleanCommand(List<String> outputOnlyDirs) {
  for (var dirPath in outputOnlyDirs) {
    var dir = new Directory(dirPath);
    if (!dir.existsSync()) continue;
    for (var f in dir.listSync(recursive: false)) {
      if (f is File && _isGeneratedFile(f.path, outputOnlyDirs)) f.deleteSync();
    }
  }
}

/** Process the command-line arguments. */
ArgResults _processArgs(List<String> arguments) {
  var parser = new ArgParser()
    ..addOption("changed", help: "the file has changed since the last build",
        allowMultiple: true)
    ..addOption("removed", help: "the file was removed since the last build",
        allowMultiple: true)
    ..addFlag("clean", negatable: false, help: "remove any build artifacts")
    ..addFlag("full", negatable: false, help: "perform a full build")
    ..addFlag("machine", negatable: false,
        help: "produce warnings in a machine parseable format")
    ..addFlag("help", abbr: 'h',
        negatable: false, help: "displays this help and exit");
  var args = parser.parse(arguments);
  if (args["help"]) {
    print('A build script that invokes the web-ui compiler (dwc).');
    print('Usage: dart build.dart [options] [-- [dwc-options]]');
    print('\nThese are valid options expected by build.dart:');
    print(parser.getUsage());
    print('\nThese are valid options expected by dwc:');
    dwc.run(['-h']).then((_) => exit(0));
  }
  return args;
}
