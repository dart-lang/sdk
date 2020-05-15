#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:analyzer_cli/starter.dart';

/// The entry point for the command-line analyzer.
///
/// [sendPort] may be passed in when started in an isolate. If provided, it is
/// used for bazel worker communication instead of stdin/stdout.
void main(List<String> args, [SendPort sendPort]) async {
  var starter = CommandLineStarter();

  // Wait for the starter to complete.
  await starter.start(args, sendPort: sendPort);
}
