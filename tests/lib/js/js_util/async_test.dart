// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_util_async_test;

import 'dart:async';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';
import 'package:async_helper/async_helper.dart';

@JS()
external void eval(String code);

@JS()
abstract class Promise<T> {}

@JS()
external Promise get resolvedPromise;

@JS()
external Promise get rejectedPromise;

@JS()
external Promise getResolvedPromise();

main() {
  eval(r"""
    var rejectedPromise = new Promise((resolve, reject) => reject('rejected'));
    var resolvedPromise = new Promise(resolve => resolve('resolved'));
    function getResolvedPromise() {
      return resolvedPromise;
    }
    """);

  Future<void> testResolvedPromise() async {
    final String result = await js_util.promiseToFuture(resolvedPromise);
    expect(result, equals('resolved'));
  }

  Future<void> testRejectedPromise() async {
    final String error = await asyncExpectThrows<String>(
        js_util.promiseToFuture(rejectedPromise));
    expect(error, equals('rejected'));
  }

  Future<void> testReturnResolvedPromise() async {
    final String result = await js_util.promiseToFuture(getResolvedPromise());
    expect(result, equals('resolved'));
  }

  asyncTest(() async {
    await testResolvedPromise();
    await testRejectedPromise();
    await testReturnResolvedPromise();
  });
}
