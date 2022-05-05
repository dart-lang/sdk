// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:smith/smith.dart';

import '../test_progress.dart';
import 'service.dart';

const safariDriverPort = 7055;

class WebDriverService extends EventListener {
  static final _instances = <Runtime, WebDriverService>{};
  static final supportedRuntimes = <Runtime>{
    Runtime.safari,
  };

  final String _driverExecutable;
  final List<String> _driverArguments;
  Future<void> _started;
  Process _process;

  ServiceState state = ServiceState.created;
  final int port;

  WebDriverService(this._driverExecutable, this._driverArguments, this.port);

  Future<void> start() {
    if (_started != null) {
      return _started;
    }
    return _started = () async {
      state = ServiceState.starting;
      try {
        _process = await Process.start(
            _driverExecutable, ['--port', '$port', ..._driverArguments]);
        _process.exitCode.then((exitCode) {
          if (state != ServiceState.stopped) {
            state = ServiceState.failed;
            print('$runtimeType stopped unexpectedly: $exitCode');
          }
        });
        state = ServiceState.running;
        print('Started $runtimeType on port $port');
      } catch (error) {
        state = ServiceState.failed;
        print('Failed to start $runtimeType: $error');
        rethrow;
      }
    }();
  }

  @override
  void allDone() {
    state = ServiceState.stopped;
    _process?.kill();
  }

  factory WebDriverService.fromRuntime(Runtime runtime) {
    return _instances.putIfAbsent(runtime, () {
      switch (runtime) {
        case Runtime.safari:
          return WebDriverService(
              '/usr/bin/safaridriver', [], safariDriverPort);
        default:
          throw ArgumentError.value(runtime, 'runtime', 'Unsupported runtime');
      }
    });
  }
}
