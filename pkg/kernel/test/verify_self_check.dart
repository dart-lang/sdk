// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/verifier.dart';

import 'self_check_util.dart';

main(List<String> args) {
  runSelfCheck(args, (String filename) {
    verifyProgram(loadProgramFromBinary(filename));
  });
}
