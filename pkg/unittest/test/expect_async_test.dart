// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testFunction = (TestConfiguration testConfig) {
  test('expectAsync zero params', () {
    _defer(expectAsync(() {
      ++testConfig.count;
    }));
  });

  test('expectAsync 1 param', () {
    var func = expectAsync((arg) {
      expect(arg, 0);
      ++testConfig.count;
    });
    _defer(() => func(0));
  });

  test('expectAsync 2 param', () {
    var func = expectAsync((arg0, arg1) {
      expect(arg0, 0);
      expect(arg1, 1);
      ++testConfig.count;
    });
    _defer(() => func(0, 1));
  });

  test('single arg to Future.catchError', () {
    var func = expectAsync((error) {
      expect(error, isStateError);
      ++testConfig.count;
    });

    new Future(() {
      throw new StateError('test');
    }).catchError(func);
  });

  test('2 args to Future.catchError', () {
    var func = expectAsync((error, stack) {
      expect(error, isStateError);
      expect(stack is StackTrace, isTrue);
      ++testConfig.count;
    });

    new Future(() {
      throw new StateError('test');
    }).catchError(func);
  });

  test('zero of two optional positional args', () {
    var func = expectAsync(([arg0 = true, arg1 = true]) {
      expect(arg0, isTrue);
      expect(arg1, isTrue);
      ++testConfig.count;
    });

    _defer(() => func());
  });

  test('one of two optional positional args', () {
    var func = expectAsync(([arg0 = true, arg1 = true]) {
      expect(arg0, isFalse);
      expect(arg1, isTrue);
      ++testConfig.count;
    });

    _defer(() => func(false));
  });

  test('two of two optional positional args', () {
    var func = expectAsync(([arg0 = true, arg1 = true]) {
      expect(arg0, isFalse);
      expect(arg1, isNull);
      ++testConfig.count;
    });

    _defer(() => func(false, null));
  });
};

final expected = '8:0:0:8:8:::null:expectAsync zero params:'
    ':expectAsync 1 param::expectAsync 2 param:'
    ':single arg to Future.catchError::2 args to Future.catchError:'
    ':zero of two optional positional args:'
    ':one of two optional positional args:'
    ':two of two optional positional args:';
