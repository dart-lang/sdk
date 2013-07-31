// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;
import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';

part 'unittest_test_utils.dart';

var testName = 'test returning future using runAsync';

var testFunction = (_) {
  test("successful", () {
    return _defer(() {
      runAsync(() {
        guardAsync(() {
          expect(true, true);
        });
      });
    });
  });
  test("fail1", () {
    var callback = expectAsync0((){});
    return _defer(() {
      runAsync(() {
        guardAsync(() {
          expect(true, false);
          callback();
        });
      });
    });
  });
  test('error1', () {
    var callback = expectAsync0((){});
    var excesscallback = expectAsync0((){});
    return _defer(() {
      runAsync(() {
        guardAsync(() {
          excesscallback();
          excesscallback();
          callback();
        });
      });
    });
  });
  test("fail2", () {
    var callback = expectAsync0((){});
    return _defer(() {
      runAsync(() {
        guardAsync(() {
          fail('failure');
          callback();
        });
      });
    });
  });
  test('error2', () {
    var callback = expectAsync0((){});
    var excesscallback = expectAsync0((){});
    return _defer(() {
      runAsync(() {
        guardAsync(() {
          excesscallback();
          excesscallback();
          excesscallback();
          callback();
        });
      });
    });
  });
  test('foo6', () {
  });
};

var expected = buildStatusString(2, 4, 0,
    'successful::'
    'fail1:Expected: <false> Actual: <true>:'
    'error1:Callback called more times than expected (1).:'
    'fail2:failure:'
    'error2:Callback called more times than expected (1).:'
    'foo6');
