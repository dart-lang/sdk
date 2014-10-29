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
  new _DartDependencyAnalyzer(args).run()
      .catchError((error, stack) {
        print('Analysis failed: $error');
        if (stack != null) {
          print(stack);
        }
      });
}

/**
 * Instances of [_DartDependencyAnalyzer] launch an analysis server and use
 * that server to analyze the dependencies of an application.
 */
class _DartDependencyAnalyzer {
  /**
   * The name of the application that is used to start the dependency analyzer.
   */
  static const BINARY_NAME = 'dartdeps';

  /**
   * The name of the option used to specify the Dart SDK.
   */
  static const String DART_SDK_OPTION = 'dart-sdk';

  /**
   * The name of the option used to print usage information.
   */
  static const String HELP_OPTION = 'help';

  /**
   * The name of the option used to specify an already running server.
   */
  static const String SERVER_OPTION = 'server';

  /**
   * The command line arguments.
   */
  final List<String> args;

  /**
   * The path to the Dart SDK used during analysis.
   */
  String sdkPath;

  /**
   * The manager for the analysis server.
   */
  AnalysisManager manager;

  _DartDependencyAnalyzer(this.args);

  /**
   * Parse the command line arguments to determine the application to be
   * analyzed, then launch and manage an analysis server to do the work.
   */
  Future run() {
    return new Future(start).then(analyze).whenComplete(stop);
  }

  /**
   * Parse the command line arguments to determine the application to be
   * analyzed, then launch an analysis server.
   * Return `null` if the command line arguments are invalid.
   */
  Future<AnalysisManager> start() {
    ArgParser parser = new ArgParser();
    parser.addOption(
        DART_SDK_OPTION,
        help: '[sdkPath] path to Dart SDK');
    parser.addFlag(HELP_OPTION,
        help: 'print this help message without starting analysis',
        defaultsTo: false,
        negatable: false);
    parser.addOption(
        SERVER_OPTION,
        help: '[serverUrl] use an analysis server thats already running');

    // Parse arguments
    ArgResults results;
    try {
      results = parser.parse(args);
    } on FormatException catch(e) {
      print(e.message);
      print('');
      printUsage(parser);
      exitCode = 1;
      return null;
    }
    if (results[HELP_OPTION]) {
      printUsage(parser);
      return null;
    }
    sdkPath = results[DART_SDK_OPTION];
    if (sdkPath is! String) {
      print('Missing path to Dart SDK');
      printUsage(parser);
      return null;
    }
    Directory sdkDir = new Directory(sdkPath);
    if (!sdkDir.existsSync()) {
      print('Specified Dart SDK does not exist: $sdkPath');
      printUsage(parser);
      return null;
    }
    if (results.rest.length == 0) {
      printUsage(parser);
      exitCode = 1;
      return null;
    }
    Directory appDir = new Directory(results.rest[0]);
    if (!appDir.existsSync()) {
      print('Specified application directory does not exist: $appDir');
      print('');
      printUsage(parser);
      exitCode = 1;
      return null;
    }
    if (results.rest.length > 1) {
      print('Unexpected arguments after $appDir');
      print('');
      printUsage(parser);
      exitCode = 1;
      return null;
    }

    // Connect to an already running analysis server
    String serverUrl = results[SERVER_OPTION];
    if (serverUrl != null) {
      return AnalysisManager.connect(serverUrl);
    }

    // Launch and connect to a new analysis server
    // Assume that the analysis server entry point is in the same directory
    StringBuffer path = new StringBuffer();
    path.write(FileSystemEntity.parentOf(Platform.script.toFilePath()));
    path.write(Platform.pathSeparator);
    path.write('server.dart');
    return AnalysisManager.start(path.toString());
  }

  /**
   * Use the given manager to perform the analysis.
   */
  void analyze(AnalysisManager manager) {
    if (manager == null) {
      return;
    }
    this.manager = manager;
    print('Analyzing...');
  }

  /**
   * Stop the analysis server.
   */
  void stop() {
    if (manager != null) {
      manager.stop();
    }
  }

  /**
   * Print information about how to use the server.
   */
  void printUsage(ArgParser parser) {
    print('Usage: $BINARY_NAME [flags] <application_directory>');
    print('');
    print('Supported flags are:');
    print(parser.usage);
  }
}
