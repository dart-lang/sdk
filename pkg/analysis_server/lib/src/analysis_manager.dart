// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/**
 * [AnalysisManager] is used to launch and manage an analysis server
 * running in a separate process using the static [start] method.
 */
class AnalysisManager {
  // TODO dynamically allocate port and/or allow client to specify port
  static const int PORT = 3333;

  /**
   * The analysis server process being managed.
   */
  final Process process;

  /**
   * The websocket used to communicate with the analysis server.
   */
  final WebSocket socket;

  /**
   * Launch analysis server in a separate process and return a
   * [Future<AnalysisManager>] for managing that analysis server.
   */
  static Future<AnalysisManager> start(String pathToServer) {
    // TODO dynamically allocate port and/or allow client to specify port
    return Process.start(Platform.executable, [pathToServer, "--port",
        PORT.toString()]).then(_connect);
  }

  /**
   * Open a connection to the analysis server.
   */
  static Future<AnalysisManager> _connect(Process process) {
    var url = 'ws://${InternetAddress.LOOPBACK_IP_V4.address}:$PORT/';
    process.stderr.pipe(stderr);
    Stream out = process.stdout.transform(UTF8.decoder).asBroadcastStream();
    out.listen((line) {
      print(line);
    });
    return out
        .any((String line) => line.startsWith("Listening on port"))
        .then((bool listening) {
          if (!listening) {
            throw "Expected analysis server to listen on a port";
          }
        })
        .then((_) => WebSocket.connect(url))
        .then((WebSocket socket) => new AnalysisManager(process, socket))
        .catchError((error) {
          process.kill();
          throw error;
        });
  }

  /**
   * Create a new instance that manages the specified analysis server process.
   */
  AnalysisManager(this.process, this.socket);

  /**
   * Stop the analysis server.
   *
   * Returns [:true:] if the signal is successfully sent and process is killed.
   * Otherwise the signal could not be sent, usually meaning that the process
   * is already dead.
   */
  bool stop() => process.kill();
}
