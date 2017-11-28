#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/error_formatter.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/naive_type_checker.dart';

void main(List<String> args) {
  final binary = loadProgramFromBinary(args[0]);
  ErrorFormatter errorFormatter = new ErrorFormatter();
  new StrongModeTypeChecker(errorFormatter, binary)..checkProgram(binary);
  if (errorFormatter.numberOfFailures > 0) {
    errorFormatter.failures.forEach(print);
    print('------- Found ${errorFormatter.numberOfFailures} errors -------');
    exit(-1);
  }
}
