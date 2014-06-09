// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'test returning future using scheduleMicrotask';

var testFunction = (_) {
  test("successful", () {
    return _defer(() {
      scheduleMicrotask(() {
        expect(true, true);
      });
    });
  });
  test("fail1", () {
    var callback = expectAsync(() {});
    return _defer(() {
      scheduleMicrotask(() {
        expect(true, false);
        callback();
      });
    });
  });
  test('error1', () {
    var callback = expectAsync(() {});
    var excesscallback = expectAsync(() {});
    return _defer(() {
      scheduleMicrotask(() {
        excesscallback();
        excesscallback();
        callback();
      });
    });
  });
  test("fail2", () {
    var callback = expectAsync(() {});
    return _defer(() {
      scheduleMicrotask(() {
        fail('failure');
        callback();
      });
    });
  });
  test('error2', () {
    var callback = expectAsync(() {});
    var excesscallback = expectAsync(() {});
    return _defer(() {
      scheduleMicrotask(() {
        excesscallback();
        excesscallback();
        excesscallback();
        callback();
      });
    });
  });
  test('foo6', () {
  });
};

final expected = buildStatusString(2, 4, 0,
    'successful::'
    'fail1:Expected: <false> Actual: <true>:'
    'error1:Callback called more times than expected (1).:'
    'fail2:failure:'
    'error2:Callback called more times than expected (1).:'
    'foo6');
