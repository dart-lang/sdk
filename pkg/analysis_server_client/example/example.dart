// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Directory, Platform, ProcessSignal, exit;

import 'package:analysis_server_client/handler/connection_handler.dart';
import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

/// A simple application that uses the analysis server to analyze a package.
void main(List<String> args) async {
  var target = await parseArgs(args);
  print('Analyzing $target');

  // Launch the server
  var server = Server();
  await server.start();

  // Connect to the server
  var handler = _Handler(server);
  server.listenToOutput(notificationProcessor: handler.handleEvent);
  if (!await handler.serverConnected(timeLimit: const Duration(seconds: 15))) {
    exit(1);
  }

  // Request analysis
  await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS,
      ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
  await server.send(ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
      AnalysisSetAnalysisRootsParams([target], const []).toJson());

  // Continue to watch for analysis until the user presses Ctrl-C
  StreamSubscription<ProcessSignal> subscription;
  subscription = ProcessSignal.sigint.watch().listen((_) async {
    print('Exiting...');
    // ignore: unawaited_futures
    subscription.cancel();
    await server.stop();
  });
}

Future<String> parseArgs(List<String> args) async {
  if (args.length != 1) {
    printUsageAndExit('Expected exactly one directory');
  }
  final dir = Directory(path.normalize(path.absolute(args[0])));
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

class _Handler with NotificationHandler, ConnectionHandler {
  @override
  final Server server;
  int errorCount = 0;

  _Handler(this.server);

  @override
  void onAnalysisErrors(AnalysisErrorsParams params) {
    var errors = params.errors;
    var first = true;
    for (var error in errors) {
      if (error.type.name == 'TODO') {
        // Ignore these types of "errors"
        continue;
      }
      if (first) {
        first = false;
        print('${params.file}:');
      }
      var loc = error.location;
      print('  ${error.message} • ${loc.startLine}:${loc.startColumn}');
      ++errorCount;
    }
  }

  @override
  void onFailedToConnect() {
    print('Failed to connect to server');
  }

  @override
  void onProtocolNotSupported(Version version) {
    print('Expected protocol version $PROTOCOL_VERSION, but found $version');
  }

  @override
  void onServerError(ServerErrorParams params) {
    if (params.isFatal) {
      print('Fatal Server Error: ${params.message}');
    } else {
      print('Server Error: ${params.message}');
    }
    if (params.stackTrace != null) {
      print(params.stackTrace);
    }
    super.onServerError(params);
  }

  @override
  void onServerStatus(ServerStatusParams params) {
    if (!params.analysis.isAnalyzing) {
      // Whenever the server stops analyzing,
      // print a brief summary of what issues have been found.
      if (errorCount == 0) {
        print('No issues found.');
      } else {
        print('Found $errorCount errors/warnings/hints');
      }
      errorCount = 0;
      print('--------- ctrl-c to exit ---------');
    }
  }
}
