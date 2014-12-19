// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.async_exception_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestsFail('async errors cause tests to fail', () {
    test('async', () {
      expectAsync(() {});
      new Future(() {
        throw "an error!";
      });
    });

    test('sync', () {
      expectAsync(() {});
      new Future(() {
        throw "an error!";
      });
    });
  });
}
