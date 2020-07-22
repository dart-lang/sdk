// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interactive_test;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_minitest.dart';
import 'package:async_helper/async_helper.dart';

main() async {
  bool thenEstimateBefore = false;
  bool thenEstimateAfter = false;
  bool thenEstimateDone = false;
  late Map thenEstimate;
  test('Basic Promise Test', () async {
    try {
      thenEstimateBefore = true;
      window.navigator.storage!.estimate().then((value) {
        thenEstimate = value!;
        thenEstimateDone = true;
      });
      thenEstimateAfter = true;
    } catch (msg) {
      fail("StorageManger failed: $msg");
    }

    Map estimate = await window.navigator.storage!.estimate() as Map;

    expect(thenEstimate['usage'] >= 0, true);
    expect(thenEstimate['quota'] > 1, true);
    expect(thenEstimate['usage'], estimate['usage']);
    expect(thenEstimate['quota'], estimate['quota']);

    expect(thenEstimateBefore, true);
    expect(thenEstimateAfter, true);
    expect(thenEstimateDone, true);
  });
}
