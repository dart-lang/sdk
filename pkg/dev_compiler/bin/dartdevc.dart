#!/usr/bin/env dart
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line entry point for Dart Development Compiler (dartdevc), used to
/// compile a collection of dart libraries into a single JS module
library;

import 'dart:isolate';

import 'package:dev_compiler/ddc.dart' as ddc;

/// The entry point for the Dart Dev Compiler.
///
/// [sendPort] may be passed in when started in an isolate. If provided, it is
/// used for bazel worker communication instead of stdin/stdout.
Future main(List<String> args, [SendPort? sendPort]) async {
  return ddc.internalMain(args, sendPort);
}
