// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import 'package:expect/expect.dart';

// async* desugaring uses `Completer<bool>` values to suspend the async*
// function until the last emitted value is consumed. Check that the desugared
// code distinguishes user-written `Completer<bool>` values from the values
// used by the desugared code.
Stream<Completer<bool>> test() async* {
  yield Completer<bool>();
  yield Completer<bool>();
  yield Completer<bool>();
}

void main() async {
  final values = await test().toList();
  Expect.equals(values.length, 3);
  for (final completer in values) {
    Expect.isFalse(completer.isCompleted);
  }
}
