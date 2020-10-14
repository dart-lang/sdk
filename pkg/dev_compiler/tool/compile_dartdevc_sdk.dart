#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Tool that consumes the .dill file of an entire dart-sdk and produces the
/// corresponding Javascript module.

import 'dart:io';
import 'package:dev_compiler/src/kernel/command.dart';

void main(List<String> args) async {
  var result = await compileSdkFromDill(args);
  exitCode = result.exitCode;
}
