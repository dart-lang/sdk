#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';

import 'util.dart';

void usage() {
  print("Prints a dill file as a textual format.");
  print("");
  print("Usage: dart <script> dillFile.dill [output]");
  print("");
  print("The first given argument should be an existing file");
  print("that is valid to load as a dill file.");
  print("");
  print("The second argument is optional.");
  print("If given, output will be written to this file.");
  print("If not given, output will be written to standard out.");
  exit(1);
}

main(List<String> args) {
  CommandLineHelper.requireVariableArgumentCount([1, 2], args, usage);
  CommandLineHelper.requireFileExists(args[0], usage);
  var binary = CommandLineHelper.tryLoadDill(args[0], usage);
  writeComponentToText(binary,
      path: args.length > 1 ? args[1] : null,
      showOffsets: const bool.fromEnvironment("showOffsets"));
}
