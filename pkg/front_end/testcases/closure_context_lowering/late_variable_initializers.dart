// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(int directCapturedInLate) {
  late int first = directCapturedInLate++;
  late int second = directCapturedInLate++;
  return [first, second, directCapturedInLate];
}

test2(int assertCapturedAndDirectCapturedInLate) {
  assert((() => assertCapturedAndDirectCapturedInLate == 0)());
  late int variable = assertCapturedAndDirectCapturedInLate;
  return variable;
}
