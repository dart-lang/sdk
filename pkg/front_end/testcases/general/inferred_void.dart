// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void method() {}

void v1 = method();
var v2 = method();
List<void> l1 = [method()];
var l2 = [method()];

test(Iterable<void> iterable, Stream<void> stream) async {
  void v1 = method();
  var v2 = method();
  for (var v3 in iterable) {}
  for (void v4 in iterable) {}
  await for (var v5 in stream) {}
  await for (void v6 in stream) {}
  List<void> l1 = [method()];
  var l2 = [method()];
}

main() {}
