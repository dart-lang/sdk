// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

extension type MyList<T>(List<T> it) implements List<T> {}

extension type MyStream<T>(Stream<T> it) implements Stream<T> {}

method1(MyList<int> list, MyStream<int> stream) async {
  for (var a in list) {}
  await for (var a in stream) {}
}

method2(MyList<(int, String)> list, MyStream<(int, String)> stream) async {
  for (var (a, b) in list) {}
  await for (var (a, b) in stream) {}
}
