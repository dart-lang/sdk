// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

void testFunction() {
  final set = {for (var i = 0; i < 4; i++) (i, foo: 42.42, bar: 'x-')};
  print(takesSetOfRecord(set));
}

String takesSetOfRecord(Set<(int, {double foo, String bar})> set) {
  debugger();
  return helper(set);
}

String helper(Set<(int, {double foo, String bar})> set) {
  final int i = set.fold(0, (a, b) => a + b.$1);
  final double foo = set.fold(0, (a, b) => a + b.foo);
  final String bar = set.fold('', (a, b) => a + b.bar);
  return (i, foo: foo, bar: bar).toString();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
