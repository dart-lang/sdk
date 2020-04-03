// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
import 'dart:core';
import 'dart:core' as core;

void f() {}

main() {
  // The grammar for types does not allow multiple successive ? operators on a
  // type.  Note: we test both with and without a space between `?`s because the
  // scanner treats `??` as a single token.
  int?? x1 = 0; //# 01: syntax error
  core.int?? x2 = 0; //# 02: syntax error
  List<int>?? x3 = <int>[]; //# 03: syntax error
  void Function()?? x4 = f; //# 04: syntax error
  int? ? x5 = 0; //# 05: syntax error
  core.int? ? x6 = 0; //# 06: syntax error
  List<int>? ? x7 = <int>[]; //# 07: syntax error
  void Function()? ? x4 = f; //# 08: syntax error
}
