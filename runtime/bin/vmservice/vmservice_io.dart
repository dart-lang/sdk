// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_io;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:vmservice';

part 'loader.dart';
part 'resources.dart';
part 'server.dart';

// The TCP ip/port that the HTTP server listens on.
int _port;
String _ip;
// Should the HTTP server auto start?
bool _autoStart;

bool _isWindows = false;

var _signalWatch;

// HTTP servr.
Server server;
Future<Server> serverFuture;

void _bootServer() {
  // Load resources.
  _triggerResourceLoad();
  // Lazily create service.
  var service = new VMService();
  // Lazily create server.
  server = new Server(service, _ip, _port);
}

void _clearFuture(_) {
  serverFuture = null;
}

void _onSignal(ProcessSignal signal) {
  if (serverFuture != null) {
    // Still waiting.
    return;
  }
  if (server == null) {
    _bootServer();
  }
  // Toggle HTTP server.
  if (server.running) {
    serverFuture = server.shutdown(true).then(_clearFuture);
  } else {
    serverFuture = server.startup().then(_clearFuture);
  }
}

void _registerSignalHandler() {
  if (_isWindows) {
    // Cannot register for signals on Windows.
    return;
  }
  _signalWatch(ProcessSignal.SIGQUIT).listen(_onSignal);
}

const _shortDelay = const Duration(milliseconds: 10);

main() {
  if (_autoStart) {
    _bootServer();
    server.startup();
    // It's just here to push an event on the event loop so that we invoke the
    // scheduled microtasks.
    Timer.run(() {});
  }
  scriptLoadPort.handler = _processLoadRequest;
  // Register signal handler after a small delay to avoid stalling main
  // isolate startup.
  new Timer(_shortDelay, _registerSignalHandler);
  return scriptLoadPort;
}
