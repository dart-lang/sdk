#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/interpreter/interpreter.dart';
import 'dart:io';

fail(String message) {
  stderr.writeln(message);
  exit(1);
}

main(List<String> args) {
  if (args.length == 1 && args[0].endsWith('.dill')) {
    var program = loadProgramFromBinary(args[0]);
    new Interpreter(program).run();
  } else {
    return fail('One input binary file should be specified.');
  }
}
