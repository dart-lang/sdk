// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dwds/data/connect_request.dart';
import 'package:dwds/data/hot_restart_request.dart';
import 'package:dwds/data/run_request.dart';
import 'package:dwds/src/handlers/socket_connections.dart';
import 'package:dwds/src/utilities/shared.dart';

/// A connection between the application loaded in the browser and DWDS.
class AppConnection {
  /// The initial connection request sent from the application in the browser.
  final ConnectRequest request;
  final _startedCompleter = Completer<void>();
  final _doneCompleter = Completer<void>();
  final SocketConnection _connection;
  final Future<void> _readyToRunMain;

  bool get hasStarted => _startedCompleter.isCompleted;

  AppConnection(this.request, this._connection, this._readyToRunMain) {
    safeUnawaited(_connection.sink.done.then((v) => _doneCompleter.complete()));
  }

  bool get isInKeepAlivePeriod => _connection.isInKeepAlivePeriod;
  void shutDown() => _connection.shutdown();
  bool get isStarted => _startedCompleter.isCompleted;
  Future<void> get onStart => _startedCompleter.future;
  bool get isDone => _doneCompleter.isCompleted;
  Future<void> get onDone => _doneCompleter.future;

  void runMain() {
    if (_startedCompleter.isCompleted) {
      throw StateError('Main has already started.');
    }

    safeUnawaited(_runMain());
  }

  Future<void> _runMain() async {
    await _readyToRunMain;
    _connection.sink.add(jsonEncode(['RunRequest', RunRequest().toJson()]));
    _startedCompleter.complete();
  }

  /// The request to restart when no debugger attached.
  ///
  /// In this case, there's no need to block main execution until the debugger
  /// resends breakpoints.
  void hotRestart(HotRestartRequest request) =>
      _connection.sink.add(jsonEncode(['HotRestartRequest', request.toJson()]));
}
