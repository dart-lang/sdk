#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:kernel/interpreter/interpreter.dart';

import 'util.dart';

void usage() {
  print("Interpreter for a dill file.");
  print("");
  print("Usage: dart <script> dillFile.dill");
  print("The given argument should be an existing file");
  print("that is valid to load as a dill file.");
  exit(1);
}

main(List<String> args) {
  CommandLineHelper.requireExactlyOneArgument(true, args, usage);
  Component component = CommandLineHelper.tryLoadDill(args[0], usage);
  new Interpreter(component).run();
}
