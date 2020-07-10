// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/dartdev.dart';
import 'package:pedantic/pedantic.dart' show unawaited;

/// The entry point for dartdev.
Future<void> main(List<String> args) async {
  // Ignore SIGINT to ensure DartDev doesn't exit before any of its
  // spawned children. Draining the stream returned by watch() effectively
  // sends the signals to the void.
  //
  // See https://github.com/dart-lang/sdk/issues/42092 for context.
  unawaited(ProcessSignal.sigint.watch().drain());
  await runDartdev(args);
}
