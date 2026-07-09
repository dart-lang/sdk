// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic getNull() => null;
Future<dynamic> getFutureNull() async {
  return null;
}

Future<bool> getFutureBool() async {
  return true;
}

Future<bool> test1() async => await getNull(); // ok
Future<bool> test2() => getNull(); // ok
bool test3() => getNull(); // ok
Future<bool> test4() async => await getFutureNull(); // ok
Future<bool> test5() => getFutureNull(); // error
Future<bool> test6() => getFutureBool(); // ok
Future<bool> test7() async => getFutureBool(); // ok

test() async {
  Future<bool> test1() async => await getNull(); // ok
  Future<bool> test2() => getNull(); // ok
  bool test3() => getNull(); // ok
  Future<bool> test4() async => await getFutureNull(); // ok
  Future<bool> test5() => getFutureNull(); // error
  Future<bool> test6() => getFutureBool(); // ok
  Future<bool> test7() async => getFutureBool(); // ok

  Future<bool> var1 = (() async => await getNull())(); // error
  Future<bool> var2 = (() => getNull())(); // ok
  bool var3 = (() => getNull())(); // ok
  Future<bool> var4 = (() async => await getFutureNull())(); // error
  Future<bool> var5 = (() => getFutureNull())(); // error
  Future<bool> var6 = (() => getFutureBool())(); // ok
  Future<bool> var7 = (() async => getFutureBool())(); // ok
}

main() {}
