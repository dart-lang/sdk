// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error if the type `T` in the on-catch clause `on T catch`
// is potentially nullable.
import 'package:expect/expect.dart';
import 'dart:core';
import 'dart:core' as core;

main() {
  try {} catch (e) {}
  try {} on A catch (e) {}
  try {} on A? {} //# 01: compile-time error
}

class A {}

class B<C> {
  m() {
    try {} on C {} //# 02: compile-time error
  }
}

class D<E extends Object> {
  m() {
    try {} on E {}
  }
}