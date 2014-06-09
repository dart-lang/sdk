// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testFunction = (_) {
  test('protectAsync0', () {
    var protected = () {
      throw new StateError('error during protectAsync0');
    };
    new Future(protected);
  });

  test('protectAsync1', () {
    var protected = (arg) {
      throw new StateError('error during protectAsync1: $arg');
    };
    new Future(() => protected('one arg'));
  });

  test('protectAsync2', () {
    var protected = (arg1, arg2) {
      throw new StateError('error during protectAsync2: $arg1, $arg2');
    };
    new Future(() => protected('arg1', 'arg2'));
  });

  test('throw away 1', () {
    return new Future(() {});
  });
};

var expected = '1:0:3:4:0:::null:'
  'protectAsync0:Caught Bad state: error during protectAsync0:'
  'protectAsync1:Caught Bad state: error during protectAsync1: one arg:'
  'protectAsync2:Caught Bad state: error during protectAsync2: arg1, arg2:'
  'throw away 1:';
