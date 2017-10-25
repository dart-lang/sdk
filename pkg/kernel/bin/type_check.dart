#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:kernel/naive_type_checker.dart';

void main(List<String> args) {
  final binary = loadProgramFromBinary(args[0]);

  final checker = new TypeChecker(binary)..checkProgram(binary);
  if (checker.fails > 0) {
    print('------- Reported ${checker.fails} errors -------');
    exit(-1);
  }
}
