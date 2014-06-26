// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_io;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors';
import 'dart:vmservice';

part 'resources.dart';
part 'server.dart';

// The TCP ip/port that the HTTP server listens on.
int _port;
String _ip;
// Should the HTTP server auto start?
bool _autoStart;

bool _isWindows = false;

// HTTP servr.
Server server;
Future<Server> serverFuture;

// The VM service instance.
VMService service;

void _onSignal(ProcessSignal signal) {
  if (serverFuture != null) {
    // Still waiting.
    return;
  }
  // Toggle HTTP server.
  if (server.running) {
    serverFuture = server.shutdown(true).then((_) {
      serverFuture = null;
    });
  } else {
    serverFuture = server.startup().then((_) {
      serverFuture = null;
    });
  }
}

void registerSignalHandler() {
  if (_isWindows) {
    // Cannot register for signals on Windows.
    return;
  }
  bool useSIGQUIT = true;
  // Listen for SIGQUIT.
  if (useSIGQUIT) {
    var io = currentMirrorSystem().findLibrary(const Symbol('dart.io'));
    var c = MirrorSystem.getSymbol('_ProcessUtils', io);
    var m = MirrorSystem.getSymbol('_watchSignalInternal', io);
    var processUtils = io.declarations[c];
    processUtils.invoke(m, [ProcessSignal.SIGQUIT]).reflectee.listen(_onSignal);
  } else {
    ProcessSignal.SIGUSR1.watch().listen(_onSignal);
  }
}


main() {
  // Get VMService.
  service = new VMService();
  // Start HTTP server.
  server = new Server(service, _ip, _port);
  if (_autoStart) {
    server.startup();
  }

  registerSignalHandler();
}
