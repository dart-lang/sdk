// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Future<bool> f(int i) async => i.isEven;
Future<int> getInt() async => 42;
Future<String> getString() async => "hello";

Future<bool> testOr(int n) async {
  bool v = false;
  for (int i = 0; i < n; i++) {
    v |= await f(i);
  }
  return v;
}

Future<bool> testXorRight(int n) async {
  bool v = false;
  for (int i = 0; i < n; i++) {
    v = await f(i) ^ v;
  }
  return v;
}

Future<int> testReuse(bool cond) async {
  return cond ? (await getInt()).abs() : (await getString()).length;
}

void main() async {
  await testOr(4);
  await testXorRight(4);
  await testReuse(true);
  await testReuse(false);
}
