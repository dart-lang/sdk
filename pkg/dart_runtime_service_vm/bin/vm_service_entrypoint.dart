// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dart_runtime_service_vm/dart_runtime_service_vm.dart';

// ignore: unreachable_from_main
const entrypoint = pragma(
  'vm:entry-point',
  !bool.fromEnvironment('dart.vm.product'),
);

// The TCP IP that DDS listens on.
@entrypoint
// ignore: unused_element
String _ddsIP = '';

// The TCP port that DDS listens on.
@entrypoint
// ignore: unused_element
int _ddsPort = 0;

// The TCP port that the HTTP server listens on.
@entrypoint
int _port = 0;

// The TCP IP that the HTTP server listens on.
@entrypoint
// ignore: unused_element
String _ip = '';

// Should the HTTP server auto start?
@entrypoint
bool _autoStart = false;

// Should the HTTP server require an auth code?
@entrypoint
bool _authCodesDisabled = false;

// Should the HTTP server run in devmode?
@entrypoint
// ignore: unused_element
bool _originCheckDisabled = false;

// Location of file to output VM service connection info.
@entrypoint
// ignore: unused_element
String? _serviceInfoFilename;

@entrypoint
// ignore: unused_element
bool _isWindows = false;

@entrypoint
// ignore: unused_element
bool _isFuchsia = false;

@entrypoint
Stream<ProcessSignal> Function(ProcessSignal signal)? _signalWatch;

@entrypoint
// ignore: unused_element
StreamSubscription<ProcessSignal>? _signalSubscription;

@entrypoint
// ignore: unused_element
bool _serveDevtools = true;

@entrypoint
// ignore: unused_element
bool _enableServicePortFallback = false;

@entrypoint
// ignore: unused_element
bool _waitForDdsToAdvertiseService = false;

@entrypoint
// ignore: unused_element
bool _printDtd = false;

// ignore: unused_element
File? _residentCompilerInfoFile;

@entrypoint
// ignore: unused_element
void _populateResidentCompilerInfoFile(
  /// If either `--resident-compiler-info-file` or `--resident-server-info-file`
  /// was supplied on the command line, the CLI argument should be forwarded as
  /// the argument to this parameter. If neither option was supplied, the
  /// argument to this parameter should be null.
  String? residentCompilerInfoFilePathArgumentFromCli,
) {
  // TODO(bkonyi): implement
}

Future<void> main([List<String> args = const []]) async {
  if (args case ['--help']) {
    return;
  }
  await DartRuntimeService.initialize(
    config: DartRuntimeServiceOptions(
      enableLogging: true,
      port: _port,
      disableAuthCodes: _authCodesDisabled,
      autoStart: _autoStart,
    ),
    backend: DartRuntimeServiceVMBackend(signalWatch: _signalWatch!),
  );
}
