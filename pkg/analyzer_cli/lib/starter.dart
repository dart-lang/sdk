// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:analyzer_cli/src/driver.dart';

/// An object that can be used to start a command-line analysis. This class
/// exists so that clients can configure a command-line analyzer before starting
/// it.
///
/// Clients may not extend, implement or mix-in this class.
abstract class CommandLineStarter {
  /// Initialize a newly created starter to start up a command-line analysis.
  factory CommandLineStarter() = Driver;

  /// Use the given command-line [arguments] to start this analyzer.
  ///
  /// If [sendPort] is provided it is used for bazel worker communication
  /// instead of stdin/stdout.
  Future<void> start(List<String> arguments, {SendPort sendPort});
}
