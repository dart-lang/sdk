// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

/// Contains methods used to communicate DartDev results back to the VM.
abstract class VmInteropHandler {
  /// Initializes [VmInteropHandler] to utilize [port] to communicate with the
  /// VM.
  static void initialize(SendPort port) => _port = port;

  /// Notifies the VM to run [script] with [args] upon DartDev exit.
  static void run(String script, List<String> args) {
    assert(_port != null);
    if (_port == null) return;
    final message = List<dynamic>.filled(3, null)
      ..[0] = _kResultRun
      ..[1] = script
      // Copy the list so it doesn't get GC'd underneath us.
      ..[2] = args.toList();
    _port.send(message);
  }

  /// Notifies the VM that DartDev has completed running. If provided a
  /// non-zero [exitCode], the VM will terminate with the given exit code.
  static void exit(int exitCode) {
    assert(_port != null);
    if (_port == null) return;
    final message = List<dynamic>.filled(2, null)
      ..[0] = _kResultExit
      ..[1] = exitCode;
    _port.send(message);
  }

  // Note: keep in sync with runtime/bin/dartdev_isolate.h
  static const int _kResultRun = 1;
  static const int _kResultExit = 2;

  static SendPort _port;
}
