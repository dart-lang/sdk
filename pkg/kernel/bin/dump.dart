#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

main(args) {
  var binary = loadProgramFromBinary(args[0]);
  writeProgramToText(binary,
      path: args[1], showOffsets: const bool.fromEnvironment("showOffsets"));
}
