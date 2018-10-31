// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Directory, Platform, exit;

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:path/path.dart' as path;

Completer serverConnected;
Completer analysisComplete;
Server server;
int errorCount;

/// A simple application that uses the analysis server to analyze a package.
main(List<String> args) async {
  String target = await parseArgs(args);
  print('Analyzing $target');

  // Launch the server
  server = new Server();
  await server.start();

  // Connect to the server
  serverConnected = new Completer();
  server.listenToOutput(notificationProcessor: handleEvent);
  const connectTimeout = const Duration(seconds: 15);
  await serverConnected.future.timeout(connectTimeout, onTimeout: () {
    print('Failed to connect to server');
    exit(1);
  });

  // Request analysis
  errorCount = 0;
  analysisComplete = new Completer();
  await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS,
      new ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
  await server.send(ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
      new AnalysisSetAnalysisRootsParams([target], const []).toJson());

  // Wait for analysis to complete
  await analysisComplete.future;
  if (errorCount == 0) {
    print('No issues found.');
  } else {
    print('Found $errorCount errors/warnings/hints');
  }

  await stopServer();
}

void handleEvent(String event, Map<String, dynamic> params) {
  ResponseDecoder decoder = new ResponseDecoder(null);
  switch (event) {
    case ANALYSIS_NOTIFICATION_ERRORS:
      final analysisErrorsParams =
          new AnalysisErrorsParams.fromJson(decoder, 'params', params);
      List<AnalysisError> errors = analysisErrorsParams.errors;
      bool first = true;
      for (AnalysisError error in errors) {
        if (error.type.name == 'TODO') {
          // Ignore these types of "errors"
          continue;
        }
        if (first) {
          first = false;
          print('${analysisErrorsParams.file}:');
        }
        Location loc = error.location;
        print('  ${error.message} • ${loc.startLine}:${loc.startColumn}');
        ++errorCount;
      }
      break;

    case SERVER_NOTIFICATION_CONNECTED:
      serverConnected.complete();
      break;

    case SERVER_NOTIFICATION_ERROR:
      final serverErrorParams =
          new ServerErrorParams.fromJson(decoder, 'params', params);
      final message = new StringBuffer('Server Error: ')
        ..writeln(serverErrorParams.message);
      if (serverErrorParams.stackTrace != null) {
        message.writeln(serverErrorParams.stackTrace);
      }
      print(message.toString());
      stopServer(exitCode: 15);
      break;

    case SERVER_NOTIFICATION_STATUS:
      final statusParams =
          new ServerStatusParams.fromJson(decoder, 'params', params);
      if (statusParams.analysis != null && !statusParams.analysis.isAnalyzing) {
        analysisComplete?.complete();
      }
      break;
  }
}

Future<String> parseArgs(List<String> args) async {
  if (args.length != 1) {
    printUsageAndExit('Expected exactly one directory');
  }
  final dir = new Directory(path.normalize(path.absolute(args[0])));
  if (!(await dir.exists())) {
    printUsageAndExit('Could not find directory ${dir.path}');
  }
  return dir.path;
}

void printUsageAndExit(String errorMessage) {
  print(errorMessage);
  print('');
  var appName = path.basename(Platform.script.toFilePath());
  print('Usage: $appName <directory path>');
  print('  Analyze the *.dart source files in <directory path>');
  exit(1);
}

Future stopServer({int exitCode}) async {
  const timeout = const Duration(seconds: 5);
  await server.send(SERVER_REQUEST_SHUTDOWN, null).timeout(timeout,
      onTimeout: () {
    // fall through to wait for exit.
  });
  await server.exitCode.timeout(timeout, onTimeout: () {
    return server.kill('server failed to exit');
  });
  if (exitCode != null) {
    exit(exitCode);
  }
}
