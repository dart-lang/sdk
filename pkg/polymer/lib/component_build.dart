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
Future<List<dwc.AnalysisResults>> build(List<String> arguments,
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

    if (fullBuild || !changedFiles.isEmpty || !removedFiles.isEmpty) {
      for (var file in entryPoints) {
        var dwcArgs = new List.from(args.rest);
        if (machineFormat) dwcArgs.add('--json_format');
        if (!useColors) dwcArgs.add('--no-colors');
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
            return res;
          });
        }
        tasks.add(lastTask);
      }
    }
    return tasks.future.then((r) => r.where((v) => v != null));
  }, printTime: printTime, useColors: useColors);
}

/** Process the command-line arguments. */
ArgResults _processArgs(List<String> arguments) {
  var parser = new ArgParser()
    ..addOption("changed", help: "the file has changed since the last build",
        allowMultiple: true)
    ..addOption("removed", help: "the file was removed since the last build",
        allowMultiple: true)
    ..addFlag("clean", negatable: false, help: "currently a noop, may be used "
        "in the future to remove any build artifacts")
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
