// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:analysis_server/src/analysis_manager.dart';

/**
 * Start analysis server as a separate process and use the websocket protocol
 * to analyze the application specified on the command line.
 */
void main(List<String> args) {
  _DartDependencyAnalyzer analyzer = new _DartDependencyAnalyzer();
  analyzer.start(args);
}

/**
 * Instances of [_DartDependencyAnalyzer] launch an analysis server and use
 * that server to analyze the dependencies of an application.
 */
class _DartDependencyAnalyzer {
  /**
   * The name of the application that is used to start the analyzer.
   */
  static const BINARY_NAME = 'dartdeps';

  /**
   * The name of the option used to print usage information.
   */
  static const String HELP_OPTION = "help";

  /**
   * The name of the option used to specify an already running server.
   */
  static const String SERVER_OPTION = "server";

  /**
   * Parse the command line arguments to determine the application to be
   * analyzed, then launch and manage an analysis server to do the work.
   * If there is a problem with the given arguments, then return a non zero
   * value, otherwise return zero.
   */
  void start(List<String> args) {
    var parser = new ArgParser();
    parser.addFlag(HELP_OPTION,
        help: "print this help message without starting analysis",
        defaultsTo: false,
        negatable: false);
    parser.addOption(
        SERVER_OPTION,
        help: "[serverUrl] use an analysis server thats already running");

    // Parse arguments
    ArgResults results;
    try {
      results = parser.parse(args);
    } on FormatException catch(e) {
      print(e.message);
      print('');
      printUsage(parser);
      exitCode = 1;
      return;
    }
    if (results[HELP_OPTION]) {
      printUsage(parser);
      return;
    }
    if (results.rest.length == 0) {
      printUsage(parser);
      exitCode = 1;
      return;
    }
    Directory appDir = new Directory(results.rest[0]);
    if (!appDir.existsSync()) {
      print('Specified application directory does not exist: $appDir');
      print('');
      printUsage(parser);
      exitCode = 1;
      return;
    }
    if (results.rest.length > 1) {
      print('Unexpected arguments after $appDir');
      print('');
      printUsage(parser);
      exitCode = 1;
      return;
    }

    Future<AnalysisManager> future;
    String serverUrl = results[SERVER_OPTION];
    if (serverUrl != null) {
      // Connect to an already running analysis server
      future = AnalysisManager.connect(serverUrl);

    } else {
      // Launch and connect to a new analysis server
      // Assume that the analysis server entry point is in the same directory
      StringBuffer path = new StringBuffer();
      path.write(FileSystemEntity.parentOf(Platform.script.toFilePath()));
      path.write(Platform.pathSeparator);
      path.write("server.dart");
      future = AnalysisManager.start(path.toString());
    }
    future.then(analyze);
  }

  void analyze(AnalysisManager mgr) {
    print("Analyzing...");
    new Timer(new Duration(seconds: 5), () {
      if (mgr.stop()) {
        print("stopped");
      } else {
        print("already stopped");
      }
    });
  }

  /**
   * Print information about how to use the server.
   */
  void printUsage(ArgParser parser) {
    print('Usage: $BINARY_NAME [flags] <application_directory>');
    print('');
    print('Supported flags are:');
    print(parser.getUsage());
  }
}
