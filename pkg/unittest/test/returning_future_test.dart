// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'test returning future';

var testFunction = (_) {
  test("successful", () {
    return _defer(() {
      expect(true, true);
    });
  });
  // We repeat the fail and error tests, because during development
  // I had a situation where either worked fine on their own, and
  // error/fail worked, but fail/error would time out.
  test("error1", () {
    var callback = expectAsync(() {});
    var excesscallback = expectAsync(() {});
    return _defer(() {
      excesscallback();
      excesscallback();
      excesscallback();
      callback();
    });
  });
  test("fail1", () {
    return _defer(() {
      expect(true, false);
    });
  });
  test("error2", () {
    var callback = expectAsync(() {});
    var excesscallback = expectAsync(() {});
    return _defer(() {
      excesscallback();
      excesscallback();
      callback();
    });
  });
  test("fail2", () {
    return _defer(() {
      fail('failure');
    });
  });
  test('foo5', () {
  });
};

var expected = buildStatusString(2, 4, 0,
    'successful::'
    'error1:Callback called more times than expected (1).:'
    'fail1:Expected: <false> Actual: <true>:'
    'error2:Callback called more times than expected (1).:'
    'fail2:failure:'
    'foo5');
