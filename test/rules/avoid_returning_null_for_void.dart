// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_returning_null_for_void`

import 'dart:async';

void f1() {
  return null; // LINT
}

void f2() => null; //LINT

Future<void> f3() async {
  return null; // LINT
}

Future<void> f4() async => null; // LINT

class A {
  void m1() {
    return null; // LINT
  }

  void m2() => null; //LINT

  Future<void> m3() async {
    return null; // LINT
  }

  Future<void> m4() async => null; // LINT
}

local_functions() {
  void f1() {
    return null; // LINT
  }

  void f2() => null; //LINT

  Future<void> f3() async {
    return null; // LINT
  }

  Future<void> f4() async => null; // LINT
}
