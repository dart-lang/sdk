// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

<foo<

int f1() {
  return null;
}

foo
Future<List<int>> f2() async => null;

Future<List<>> f3() async {
  return null;
}

main() async {
  print(f1());
  print(await f2());
  print(await f3());
}

