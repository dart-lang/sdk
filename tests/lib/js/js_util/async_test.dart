// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_util_async_test;

import 'dart:async';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:async_helper/async_helper.dart';

@JS()
external void eval(String code);

@JS()
abstract class Promise<T> {}

@JS()
external Promise getResolvedPromise();

@JS()
external Promise getRejectedPromise();

main() {
  eval(r"""
    function getResolvedPromise() {
      return new Promise(resolve => resolve('resolved'));
    }
    function getRejectedPromise() {
      return new Promise((resolve, reject) => reject('rejected'));
    }
    """);

  Future<void> testResolvedPromise() async {
    final String result = await js_util.promiseToFuture(getResolvedPromise());
    expect(result, equals('resolved'));
  }

  Future<void> testRejectedPromise() async {
    final String error = await asyncExpectThrows<String>(
        js_util.promiseToFuture(getRejectedPromise()));
    expect(error, equals('rejected'));
  }

  asyncTest(() async {
    await testResolvedPromise();
    await testRejectedPromise();
  });
}
