// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

import 'dart:_js_helper' show patch, NoReifyGeneric;
import 'dart:async';

@patch
class Isolate {
  // `current` must be a getter, not just a final field,
  // to match the external declaration.
  @patch
  static Isolate get current => _unsupported();

  @patch
  static Future<Uri> get packageRoot => _unsupported();

  @patch
  static Future<Uri> get packageConfig => _unsupported();

  static Uri _packageBase = Uri.base.resolve('packages/');

  @patch
  static Future<Uri> resolvePackageUri(Uri packageUri) async {
    if (packageUri.scheme != 'package') return packageUri;
    return _packageBase.resolveUri(packageUri.replace(scheme: ''));
  }

  @patch
  static Future<Isolate> spawn<T>(void entryPoint(T message), T message,
          {bool paused = false,
          bool errorsAreFatal,
          SendPort onExit,
          SendPort onError}) =>
      _unsupported();

  @patch
  static Future<Isolate> spawnUri(Uri uri, List<String> args, var message,
          {bool paused = false,
          SendPort onExit,
          SendPort onError,
          bool errorsAreFatal,
          bool checked,
          Map<String, String> environment,
          Uri packageRoot,
          Uri packageConfig,
          bool automaticPackageResolution = false}) =>
      _unsupported();

  @patch
  void _pause(Capability resumeCapability) => _unsupported();

  @patch
  void resume(Capability resumeCapability) => _unsupported();

  @patch
  void addOnExitListener(SendPort responsePort, {Object response}) =>
      _unsupported();

  @patch
  void removeOnExitListener(SendPort responsePort) => _unsupported();

  @patch
  void setErrorsFatal(bool errorsAreFatal) => _unsupported();

  @patch
  void kill({int priority = beforeNextEvent}) => _unsupported();
  @patch
  void ping(SendPort responsePort,
          {Object response, int priority = immediate}) =>
      _unsupported();

  @patch
  void addErrorListener(SendPort port) => _unsupported();

  @patch
  void removeErrorListener(SendPort port) => _unsupported();
}

/** Default factory for receive ports. */
@patch
class ReceivePort {
  @patch
  factory ReceivePort() = _ReceivePort;

  @patch
  factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) =>
      _unsupported();
}

/// ReceivePort is supported by dev_compiler because async test packages
/// (async_helper, unittest) create a dummy receive port to keep the Dart VM
/// alive.
class _ReceivePort extends Stream implements ReceivePort {
  close() {}

  get sendPort => _unsupported();

  listen(onData, {onError, onDone, cancelOnError}) => _unsupported();
}

@patch
class RawReceivePort {
  @patch
  factory RawReceivePort([void handler(event)]) => _unsupported();
}

@patch
class Capability {
  @patch
  factory Capability() => _unsupported();
}

@NoReifyGeneric()
T _unsupported<T>() {
  throw UnsupportedError('dart:isolate is not supported on dart4web');
}
