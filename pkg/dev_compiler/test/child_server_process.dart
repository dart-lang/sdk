// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

class ChildServerProcess {
  /// [IOSink]s like [stdout] don't like to be piped more than one [Stream], but
  /// we want to pipe many of them (basically, every standard output and error
  /// of every child process we open), so we pipe to an accommodating consumer.
  static final _consoleOut = _MultipleStreamConsumer(stdout);

  final Process process;
  final String host;
  final int port;
  ChildServerProcess._(this.process, this.host, this.port);

  get httpUri => Uri.parse('http://$host:$port');

  static build(Future<Process> builder(String host, int port),
      {int defaultPort = 1024,
      int maxPort = 65535,
      String host = '0.0.0.0'}) async {
    var port = await _findUnusedPort(defaultPort, maxPort);
    var p = (await builder(host, port))
      ..stdout.pipe(_consoleOut)
      ..stderr.pipe(_consoleOut);
    await _waitForServer(host, port);
    return ChildServerProcess._(p, host, port);
  }

  static _waitForServer(String host, int port,
      {int attempts = 10,
      Duration retryDelay = const Duration(seconds: 1)}) async {
    var lastError;
    for (int i = 0; i < attempts; i++) {
      try {
        await (await Socket.connect(host, port)).close();
        return;
      } catch (e) {
        lastError = e;
        await Future.delayed(retryDelay);
      }
    }
    throw StateError(
        'Failed to connect to $host:$port after $attempts attempts; '
        'Last error:\n$lastError');
  }

  static Future<int> _findUnusedPort(int fromPort, int toPort) async {
    var lastError;
    for (int port = fromPort; port <= toPort; port++) {
      try {
        await (await ServerSocket.bind(InternetAddress.ANY_IP_V4, port))
            .close();
        return port;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError(
        'Failed to find an unused port between $fromPort and $toPort; '
        'Last error:\n$lastError');
  }
}

/// A consumer into which we can pipe as many streams as we want, that forwards
/// everything to an [IOSink] (such as [stdout]).
class _MultipleStreamConsumer extends StreamConsumer<List<int>> {
  final IOSink _sink;
  _MultipleStreamConsumer(this._sink);

  @override
  Future addStream(Stream<List<int>> stream) async {
    await for (var data in stream) {
      _sink.add(data);
    }
  }

  @override
  close() {}
}
