// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/protocol.dart';

/**
 * [AnalysisManager] is used to launch and manage an analysis server
 * running in a separate process using either the [start] or [connect] methods.
 */
class AnalysisManager {
  // TODO dynamically allocate port and/or allow client to specify port
  static const int PORT = 3333;

  /**
   * The analysis server process being managed
   * or `null` if managing an analysis server that was already running.
   */
  Process process;

  /**
   * The channel used to communicate with the analysis server.
   */
  ClientCommunicationChannel channel;

  /**
   * Launch analysis server in a separate process
   * and return a future with a manager for that analysis server.
   */
  static Future<AnalysisManager> start(String serverPath) {
    return new AnalysisManager()._launchServer(serverPath);
  }

  /**
   * Open a connection to a running analysis server
   * and return a future with a manager for that analysis server.
   */
  static Future<AnalysisManager> connect(String serverUrl) {
    return new AnalysisManager()._openConnection(serverUrl);
  }

  /**
   * Launch an analysis server and open a connection to that server.
   */
  Future<AnalysisManager> _launchServer(String pathToServer) {
    // TODO dynamically allocate port and/or allow client to specify port
    List<String> serverArgs = [pathToServer, '--port', PORT.toString()];
    return Process.start(Platform.executable, serverArgs)
        .catchError((error) {
          exitCode = 1;
          throw 'Failed to launch analysis server: $error';
        })
        .then(_listenForPort);
  }

  /**
   * Listen for a port from the given analysis server process.
   */
  Future<AnalysisManager> _listenForPort(Process process) {
    this.process = process;

    // Echo stdout and stderr
    Stream out = process.stdout.transform(UTF8.decoder).asBroadcastStream();
    out.listen((line) => print(line));
    process.stderr.pipe(stderr);

    // Listen for port from server
    const String pattern = 'Listening on port ';
    return out.firstWhere((String line) => line.startsWith(pattern))
        .timeout(new Duration(seconds: 10))
        .catchError((error) {
          exitCode = 1;
          process.kill();
          throw 'Expected port from analysis server';
        })
        .then((String line) {
          String port = line.substring(pattern.length).trim();
          String url = 'ws://${InternetAddress.LOOPBACK_IP_V4.address}:$port/';
          return _openConnection(url);
        });
  }

  /**
   * Open a connection to the analysis server using the given URL.
   */
  Future<AnalysisManager> _openConnection(String serverUrl) {
    Function onError = (error) {
      exitCode = 1;
      if (process != null) {
        process.kill();
      }
      throw 'Failed to connect to analysis server at $serverUrl\n  $error';
    };
    try {
      return WebSocket.connect(serverUrl)
          .catchError(onError)
          .then((WebSocket socket) {
            this.channel = new WebSocketClientChannel(socket);
            return this;
          });
    } catch (error) {
      onError(error);
    }
  }

  /**
   * Stop the analysis server.
   *
   * Returns `true` if the signal is successfully sent and process terminates.
   * Otherwise there was no attached process or the signal could not be sent,
   * usually meaning that the process is already dead.
   */
  Future<bool> stop() {
    if (process == null) {
      return channel.close().then((_) => false);
    }
    return channel
        .sendRequest(new ServerShutdownParams().toRequest('0'))
        .timeout(new Duration(seconds: 2), onTimeout: () {
          print('Expected shutdown response');
        })
        .then((Response response) {
          return channel.close().then((_) => process.exitCode);
        })
        .timeout(new Duration(seconds: 2), onTimeout: () {
          print('Expected server to shutdown');
          process.kill();
        })
        .then((int result) {
          if (result != null && result != 0) {
            exitCode = result;
          }
          return true;
        });
  }
}
