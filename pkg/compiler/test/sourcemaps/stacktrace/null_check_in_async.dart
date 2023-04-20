// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  test();
}

test() async {
  final a = await foo(null);
  doSomething();
  a /*1:test*/ !;
  doSomething();
  await foo(a);
}

Future<String?> foo(String? value) {
  return Future.value(value);
}

@pragma('dart2js:never-inline')
void doSomething() {}
