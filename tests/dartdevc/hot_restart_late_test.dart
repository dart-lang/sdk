// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that late fields are properly reset after hot restarts.

// Requirements=nnbd

import 'dart:_runtime' as dart show hotRestart, resetFields;

import 'package:expect/expect.dart';

late String noInitializer;
late int withInitializer = 1;

class Lates {
  static late String noInitializer;
  static late int withInitializer = 2;
}

class LatesGeneric<T> {
  static late String noInitializer;
  static late int withInitializer = 3;
}

main() {
  // Read this static field first to avoid interference with other reset counts.
  var weakNullSafety = hasUnsoundNullSafety;

  // TODO(42495) `Expect.throws` contains the use of a const that triggers an
  // extra field reset but consts are not correctly reset on hot restart so the
  // extra reset only appears once. Perform an initial Expect.throws here to
  // avoid confusion with the reset counts later.
  Expect.throws(() => throw 'foo');

  var resetFieldCount = dart.resetFields.length;

  // Set uninitialized static late fields. Avoid calling getters for these
  // statics to ensure they are reset even if they are never accessed.
  noInitializer = 'set via setter';
  Lates.noInitializer = 'Lates set via setter';
  LatesGeneric.noInitializer = 'LatesGeneric set via setter';

  // Initialized statics should contain their values.
  Expect.equals(1, withInitializer);
  Expect.equals(2, Lates.withInitializer);
  Expect.equals(3, LatesGeneric.withInitializer);

  // In weak null safety the late field lowering introduces a second static
  // field that tracks if late field has been initialized thus doubling the
  // number of expected resets.
  //
  // In sound null safety non-nullable fields don't require the extra static to
  // track initialization because null is used as a sentinel value.
  //
  // Weak Null Safety - 12 total field resets
  //  - 3 isSet write/resets for uninitialized field writes.
  //  - 3 write/resets for the actual uninitialized field writes.
  //  - 3 isSet reads/resets for initialized field reads.
  //  - 3 reads/resets for the actual initialized field reads.
  //
  // Sound Null Safety - 6 total field resets:
  //  - 3 write/resets for the actual uninitialized field writes.
  //  - 3 reads/resets for the actual initialized field reads.
  var expectedResets =
      weakNullSafety ? resetFieldCount + 12 : resetFieldCount + 6;
  Expect.equals(expectedResets, dart.resetFields.length);

  dart.hotRestart();
  resetFieldCount = dart.resetFields.length;

  // Late statics should throw on get when not initialized.
  Expect.throws(() => noInitializer);
  Expect.throws(() => Lates.noInitializer);
  Expect.throws(() => LatesGeneric.noInitializer);

  // Set uninitialized static late fields again.
  noInitializer = 'set via setter';
  Lates.noInitializer = 'Lates set via setter';
  LatesGeneric.noInitializer = 'LatesGeneric set via setter';

  // All statics should contain their set values.
  Expect.equals('set via setter', noInitializer);
  Expect.equals('Lates set via setter', Lates.noInitializer);
  Expect.equals('LatesGeneric set via setter', LatesGeneric.noInitializer);
  Expect.equals(1, withInitializer);
  Expect.equals(2, Lates.withInitializer);
  Expect.equals(3, LatesGeneric.withInitializer);

  // Weak Null Safety - 12 total field resets
  //  - 3 isSet write/resets for uninitialized field writes.
  //  - 3 write/resets for the actual uninitialized field writes.
  //  - 3 isSet reads/resets for initialized field reads.
  //  - 3 reads/resets for the actual initialized field reads.
  // Sound Null Safety - 6 total field resets:
  //  - 3 write/resets for the actual uninitialized field writes.
  //  - 3 reads/resets for the actual initialized field reads.
  expectedResets = weakNullSafety ? resetFieldCount + 12 : resetFieldCount + 6;
  Expect.equals(expectedResets, dart.resetFields.length);

  dart.hotRestart();
  dart.hotRestart();
  resetFieldCount = dart.resetFields.length;

  // Late statics should throw on get when not initialized.
  Expect.throws(() => noInitializer);
  Expect.throws(() => Lates.noInitializer);
  Expect.throws(() => LatesGeneric.noInitializer);

  // Initialized statics should contain their values.
  Expect.equals(1, withInitializer);
  Expect.equals(2, Lates.withInitializer);
  Expect.equals(3, LatesGeneric.withInitializer);

  // Weak Null Safety - 9 total field resets:
  //  - 3 isSet reads/resets for uninitialized field reads.
  //  - 3 isSet reads/resets for initialized field reads.
  //  - 3 reads/resets for the actual initialized field reads.
  //
  // Sound Null Safety - 6 total field resets:
  //  - 3 reads/resets for actual uninitialized field reads.
  //  - 3 reads/resets for the actual initialized field reads.
  expectedResets = weakNullSafety ? resetFieldCount + 9 : resetFieldCount + 6;
  Expect.equals(expectedResets, dart.resetFields.length);
}
