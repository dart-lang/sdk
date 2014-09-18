// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.completion_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestsPass('completion test', () {
    var count = 0;
    test('test', () {
      var _callback;
      _callback = expectAsyncUntil(() {
        if (++count < 10) {
          new Future.sync(_callback);
        }
      }, () => (count == 10));
      new Future.sync(_callback);
    });

    test('verify count', () {
      expect(count, 10);
    });
  });
}
