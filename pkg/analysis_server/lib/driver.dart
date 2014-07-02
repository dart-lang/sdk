// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library driver;

import 'dart:io';

import 'package:analysis_server/http_server.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/stdio_server.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';

/**
 * The [Driver] class represents a single running instance of the analysis
 * server application.  It is responsible for parsing command line options
 * and starting the HTTP and/or stdio servers.
 */
class Driver {
  /**
   * The name of the application that is used to start a server.
   */
  static const BINARY_NAME = 'server';

  /**
   * The name of the option used to print usage information.
   */
  static const String HELP_OPTION = "help";

  /**
   * The name of the option used to specify the port to which the server will
   * connect.
   */
  static const String PORT_OPTION = "port";

  /**
   * The name of the option used to specify the log file.
   */
  static const String LOG_FILE_OPTION = "log";

  SocketServer socketServer = new SocketServer();

  HttpAnalysisServer httpServer;

  StdioAnalysisServer stdioServer;

  Driver() {
    httpServer = new HttpAnalysisServer(socketServer);
    stdioServer = new StdioAnalysisServer(socketServer);
  }

  /**
   * Use the given command-line arguments to start this server.
   */
  void start(List<String> args) {
    ArgParser parser = new ArgParser();
    parser.addFlag(HELP_OPTION, help:
        "print this help message without starting a server", defaultsTo: false,
        negatable: false);
    parser.addOption(PORT_OPTION, help:
        "[port] the port on which the server will listen");
    parser.addOption(LOG_FILE_OPTION, help:
        "[path] file to log debugging messages to");

    ArgResults results = parser.parse(args);
    if (results[HELP_OPTION]) {
      _printUsage(parser);
      return;
    }
    if (results[LOG_FILE_OPTION] != null) {
      try {
        File file = new File(results[LOG_FILE_OPTION]);
        IOSink sink = file.openWrite();
        Logger.root.onRecord.listen((LogRecord record) {
          sink.writeln(record);
        });
      } catch (exception) {
        print('Could not open log file: $exception');
        exitCode = 1;
        return;
      }
    }
    int port;
    bool serve_http = false;
    if (results[PORT_OPTION] != null) {
      serve_http = true;
      try {
        port = int.parse(results[PORT_OPTION]);
      } on FormatException {
        print('Invalid port number: ${results[PORT_OPTION]}');
        print('');
        _printUsage(parser);
        exitCode = 1;
        return;
      }
    }

    if (serve_http) {
      httpServer.serveHttp(port);
    }
    stdioServer.serveStdio().then((_) {
      if (serve_http) {
        httpServer.close();
      }
      exit(0);
    });
  }

  /**
   * Print information about how to use the server.
   */
  void _printUsage(ArgParser parser) {
    print('Usage: $BINARY_NAME [flags]');
    print('');
    print('Supported flags are:');
    print(parser.getUsage());
  }
}
