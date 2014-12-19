// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.expect_async_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  var count = 0;

  expectTestsPass('expect async test', () {
    test('expectAsync zero params', () {
      new Future.sync(expectAsync(() {
        ++count;
      }));
    });

    test('expectAsync 1 param', () {
      var func = expectAsync((arg) {
        expect(arg, 0);
        ++count;
      });
      new Future.sync(() => func(0));
    });

    test('expectAsync 2 param', () {
      var func = expectAsync((arg0, arg1) {
        expect(arg0, 0);
        expect(arg1, 1);
        ++count;
      });
      new Future.sync(() => func(0, 1));
    });

    test('single arg to Future.catchError', () {
      var func = expectAsync((error) {
        expect(error, isStateError);
        ++count;
      });

      new Future(() {
        throw new StateError('test');
      }).catchError(func);
    });

    test('2 args to Future.catchError', () {
      var func = expectAsync((error, stack) {
        expect(error, isStateError);
        expect(stack is StackTrace, isTrue);
        ++count;
      });

      new Future(() {
        throw new StateError('test');
      }).catchError(func);
    });

    test('zero of two optional positional args', () {
      var func = expectAsync(([arg0 = true, arg1 = true]) {
        expect(arg0, isTrue);
        expect(arg1, isTrue);
        ++count;
      });

      new Future.sync(() => func());
    });

    test('one of two optional positional args', () {
      var func = expectAsync(([arg0 = true, arg1 = true]) {
        expect(arg0, isFalse);
        expect(arg1, isTrue);
        ++count;
      });

      new Future.sync(() => func(false));
    });

    test('two of two optional positional args', () {
      var func = expectAsync(([arg0 = true, arg1 = true]) {
        expect(arg0, isFalse);
        expect(arg1, isNull);
        ++count;
      });

      new Future.sync(() => func(false, null));
    });

    test('verify count', () {
      expect(count, 8);
    });
  });
}
