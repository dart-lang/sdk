#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/error_formatter.dart';
import 'package:kernel/naive_type_checker.dart';

import 'util.dart';

void usage() {
  print("Type checker that can be used to find strong mode");
  print("violations in the Kernel files.");
  print("");
  print("Usage: dart <script> dillFile.dill");
  print("The given argument should be an existing file");
  print("that is valid to load as a dill file.");
  exit(1);
}

void main(List<String> args) {
  CommandLineHelper.requireExactlyOneArgument(true, args, usage);
  final binary = CommandLineHelper.tryLoadDill(args[0], usage);
  ErrorFormatter errorFormatter = new ErrorFormatter();
  new StrongModeTypeChecker(errorFormatter, binary)..checkComponent(binary);
  if (errorFormatter.numberOfFailures > 0) {
    errorFormatter.failures.forEach(print);
    print('------- Found ${errorFormatter.numberOfFailures} errors -------');
    exit(-1);
  }
}
