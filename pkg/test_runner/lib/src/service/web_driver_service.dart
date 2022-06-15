// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:smith/smith.dart';

import '../test_progress.dart';

const safariDriverPort = 7055;

class WebDriverService extends EventListener {
  static final _instances = <Runtime, WebDriverService>{};
  static final supportedRuntimes = <Runtime>{
    Runtime.safari,
  };

  bool _running = false;
  Process _process;

  final int port;

  WebDriverService._(this.port, this._process) {
    _process.exitCode.then((exitCode) {
      if (_running) {
        print('WebDriverService stopped unexpectedly: $exitCode');
        _running = false;
      }
    });
  }

  @override
  void allDone() {
    _process.kill();
    _running = false;
  }

  static Future<WebDriverService> startServiceForRuntime(
      Runtime runtime) async {
    var service = _instances[runtime];
    String driverExecutable;
    List<String> driverArguments;
    int port;
    if (service != null) {
      return service;
    }
    switch (runtime) {
      case Runtime.safari:
        driverExecutable = '/usr/bin/safaridriver';
        driverArguments = const [];
        port = safariDriverPort;
        break;
      default:
        throw ArgumentError.value(runtime, 'runtime', 'Unsupported runtime');
    }
    try {
      var process = await Process.start(
          driverExecutable, ['--port', '$port', ...driverArguments]);
      print('Started WebDriverService on port $port');
      return _instances[runtime] =
          WebDriverService._(safariDriverPort, process);
    } catch (error) {
      print('Failed to start $runtime web driver service: $error');
      rethrow;
    }
  }

  factory WebDriverService.fromRuntime(Runtime runtime) {
    return _instances[runtime] ??
        (throw ArgumentError.value(runtime, 'runtime', 'Service unavailable'));
  }
}
