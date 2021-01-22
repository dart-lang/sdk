// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

bool caughtInMethod1 = false;
bool caughtInMethod2 = false;
bool caughtInMain = false;

Future<Object> f() {
  return new Future<Future<Object>>.value(new Future<Object>.delayed(
      const Duration(seconds: 1), () => throw 'foo'));
}

Future<Object> method1() async {
  try {
    return await f();
  } catch (e) {
    print('caught in method1: $e');
    caughtInMethod1 = true;
  }
  return new Object();
}

Future<Object> method2() async {
  try {
    return method1();
  } catch (e) {
    print('caught in method2: $e');
    caughtInMethod2 = true;
  }
  return new Object();
}

void main() async {
  try {
    print(await method2());
    print('Done');
  } catch (e) {
    print('caught in main: $e');
    caughtInMain = true;
  }
  Expect.isTrue(caughtInMethod1, "Exception should be caught in 'method1'.");
  Expect.isFalse(
      caughtInMethod2, "Exception should not be caught in 'method2'.");
  Expect.isFalse(caughtInMain, "Exception should not be caught in 'main'.");
}
