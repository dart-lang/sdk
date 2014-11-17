// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:matcher/matcher.dart';
import 'package:path/path.dart' as path;

import 'fuzz/server_manager.dart';

/**
 * Start analysis server as a separate process and use the stdio to communicate
 * with the server.
 */
void main(List<String> args) {
  new _FuzzTest().run(args);
}

/**
 * Instances of [_FuzzTest] launch and test an analysis server.
 * You must specify the location of the Dart SDK and the directory
 * containing sources to be analyzed.
 */
class _FuzzTest {
  /**
   * The name of the application that is used to start the fuzz tester.
   */
  static const BINARY_NAME = 'fuzz';

  //TODO (danrubel) extract common behavior for use in multiple test scenarios
  //TODO (danrubel) cleanup test to use async/await for better readability
  // VM flag --enable_async

  static const String DART_SDK_OPTION = 'dart-sdk';
  static const String HELP_OPTION = 'help';

  File serverSnapshot;
  Directory appDir;

  /// Parse the arguments and initialize the receiver
  /// Return `true` if proper arguments were provided
  bool parseArgs(List<String> args) {
    ArgParser parser = new ArgParser();

    void error(String errMsg) {
      stderr.writeln(errMsg);
      print('');
      _printUsage(parser);
      exitCode = 11;
    }

    parser.addOption(DART_SDK_OPTION, help: '[sdkPath] path to Dart SDK');
    parser.addFlag(
        HELP_OPTION,
        help: 'print this help message without starting analysis',
        defaultsTo: false,
        negatable: false);

    ArgResults results;
    try {
      results = parser.parse(args);
    } on FormatException catch (e) {
      error(e.message);
      return false;
    }
    if (results[HELP_OPTION]) {
      _printUsage(parser);
      return false;
    }
    String sdkPath = results[DART_SDK_OPTION];
    if (sdkPath is! String) {
      error('Missing path to Dart SDK');
      return false;
    }
    Directory sdkDir = new Directory(sdkPath);
    if (!sdkDir.existsSync()) {
      error('Specified Dart SDK does not exist: $sdkPath');
      return false;
    }
    if (results.rest.length == 0) {
      error('Expected directory to analyze');
      return false;
    }
    appDir = new Directory(results.rest[0]);
    if (!appDir.existsSync()) {
      error('Specified application directory does not exist: $appDir');
      return false;
    }
    if (results.rest.length > 1) {
      error('Unexpected arguments after $appDir');
      return false;
    }
    serverSnapshot = new File(
        path.join(sdkDir.path, 'bin', 'snapshots', 'analysis_server.dart.snapshot'));
    if (!serverSnapshot.existsSync()) {
      error('Analysis Server snapshot not found: $serverSnapshot');
      return false;
    }
    return true;
  }

  /// Main entry point for launching, testing, and shutting down the server
  void run(List<String> args) {
    if (!parseArgs(args)) return;
    ServerManager.start(serverSnapshot.path).then((ServerManager manager) {
      runZoned(() {
        test(manager).then(manager.stop).then((_) {
          expect(manager.errorOccurred, isFalse);
          print('Test completed successfully');
        });
      }, onError: (error, stack) {
        stderr.writeln(error);
        print(stack);
        exitCode = 12;
        manager.stop();
      });
    });
  }

  /// Use manager to exercise the analysis server
  Future test(ServerManager manager) {

    // perform initial analysis
    return manager.analyze(appDir).then((AnalysisResults analysisResults) {
      print(
          'Found ${analysisResults.errorCount} errors,'
              ' ${analysisResults.warningCount} warnings,'
              ' and ${analysisResults.hintCount} hints in ${analysisResults.elapsed}');

      // edit a method body
      return manager.openFileNamed(
          'domain_completion.dart').then((Editor editor) {
        return editor.moveAfter('Response processRequest(Request request) {');
      }).then((Editor editor) {
        return editor.replace(0, '\nOb');
      }).then((Editor editor) {

        // request code completion and assert results
        return editor.getSuggestions().then((List<CompletionResults> list) {
          expect(list, isNotNull);
          expect(list.length, equals(0));
          list.forEach((CompletionResults results) {
            print('${results.elapsed} received ${results.suggestionCount} suggestions');
          });
          return editor;
        });

      }).then((Editor editor) {
        print('tests complete');
      });
    });
  }

//  void _printAnalysisSummary(AnalysisResults results) {
//    print(
//        'Found ${results.errorCount} errors, ${results.warningCount} warnings,'
//            ' and ${results.hintCount} hints in $results.elapsed');
//  }

  /// Print information about how to use the server.
  void _printUsage(ArgParser parser) {
    print('Usage: $BINARY_NAME [flags] <application_directory>');
    print('');
    print('Supported flags are:');
    print(parser.usage);
  }
}
