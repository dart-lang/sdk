// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Tests that static fields are properly reset after hot restarts.

import 'dart:_runtime' as dart show hotRestart, resetFields;

import 'package:expect/expect.dart';

String noInitializer;
int withInitializer = 1;

class Statics {
  static String noInitializer;
  static int withInitializer = 2;
}

class StaticsGeneric<T> {
  static String noInitializer;
  static int withInitializer = 3;
}

main() {
  var resetFieldCount = dart.resetFields.length;

  // Set static fields without explicit initializers. Avoid calling getters for
  // these statics to ensure they are reset even if they are never accessed.
  noInitializer = 'set via setter';
  Statics.noInitializer = 'Statics set via setter';
  StaticsGeneric.noInitializer = 'StaticsGeneric set via setter';

  // Initialized statics should contain their values.
  Expect.equals(1, withInitializer);
  Expect.equals(2, Statics.withInitializer);
  Expect.equals(3, StaticsGeneric.withInitializer);

  // Six new field resets from 3 setter calls and 3 getter calls.
  var expectedResets = resetFieldCount + 6;
  Expect.equals(expectedResets, dart.resetFields.length);

  dart.hotRestart();
  resetFieldCount = dart.resetFields.length;

  // Uninitialized statics have been reset to their implicit null initial state.
  Expect.equals(null, noInitializer);
  Expect.equals(null, Statics.noInitializer);
  Expect.equals(null, StaticsGeneric.noInitializer);

  noInitializer = 'set via setter';
  Statics.noInitializer = 'Statics set via setter';
  StaticsGeneric.noInitializer = 'StaticsGeneric set via setter';

  // All statics should contain their set values.
  Expect.equals('set via setter', noInitializer);
  Expect.equals('Statics set via setter', Statics.noInitializer);
  Expect.equals('StaticsGeneric set via setter', StaticsGeneric.noInitializer);
  Expect.equals(1, withInitializer);
  Expect.equals(2, Statics.withInitializer);
  Expect.equals(3, StaticsGeneric.withInitializer);

  // Six total new field resets despite getter and setter calls on the same
  // static fields.
  expectedResets = resetFieldCount + 6;
  Expect.equals(expectedResets, dart.resetFields.length);

  dart.hotRestart();
  dart.hotRestart();
  resetFieldCount = dart.resetFields.length;

  // All statics should contain their initial values.
  Expect.equals(null, noInitializer);
  Expect.equals(null, Statics.noInitializer);
  Expect.equals(null, StaticsGeneric.noInitializer);
  Expect.equals(1, withInitializer);
  Expect.equals(2, Statics.withInitializer);
  Expect.equals(3, StaticsGeneric.withInitializer);

  // Six new field resets from 6 getter calls.
  expectedResets = resetFieldCount + 6;
  Expect.equals(expectedResets, dart.resetFields.length);
}
