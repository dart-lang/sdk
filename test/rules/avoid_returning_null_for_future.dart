// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_returning_null_for_future`

import 'dart:async';

Future f1() => null; // LINT
Future f2() {
  return null; // LINT
}

Future f3() async => null; // OK
Future f4() async {
  return null; // OK
}

int f5() => null; // OK
int f6() {
  return null; // OK
}

class C1 {
  Future f1() => null; // LINT
  Future f2() {
    return null; // LINT
  }

  Future f3() async => null; // OK
  Future f4() async {
    return null; // OK
  }

  int f5() => null; // OK
  int f6() {
    return null; // OK
  }
}
