// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

  expectTestFails("a top-leveled error should be converted to a schedule error",
      () {
    schedule(() {
      new Future.microtask(() => throw 'error');
      return pumpEventQueue();
    });
  }, (errors) {
    expect(errors.first.error, equals('error'));
  });
}
