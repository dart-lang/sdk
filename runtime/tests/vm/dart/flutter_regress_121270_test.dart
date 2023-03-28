// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that vm doesn't crash when regrexp optimizing compiler runs
// twice as it fails to generate code with near-jumps, retries with far jumps.
// See https://github.com/flutter/flutter/issues/121270

void main() async {
  final RegExp _dateTimeFULLExp = RegExp(
      r'([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?(Z|(\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00)))?)?)?');

  String a = "2023-01-07T16:51:24.868498+01:00";

  print(_dateTimeFULLExp.hasMatch(a));
  print(_dateTimeFULLExp.hasMatch(a));
  print("finish");
}
