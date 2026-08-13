// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:developer';

import 'common/test_helper.dart';

int codeRuns = 0;

void code() {
  if (++codeRuns > 1) {
    print('Calling debugger!');
    debugger(); // LINE_A
  }
  final y = MySet();
  // ignore: avoid_function_literals_in_foreach_calls
  y.forEach((element) /* LINE_B */ {
    print(element);
  });
}

class MySet extends Object with SetMixin {
  @override
  bool add(value) => throw UnimplementedError();
  @override
  bool contains(Object? element) => false;
  @override
  Iterator get iterator => [].iterator;
  @override
  int get length => 0;
  @override
  Never lookup(Object? element) => throw UnimplementedError();
  @override
  bool remove(Object? value) => throw UnimplementedError();
  @override
  Set toSet() => throw UnimplementedError();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(
    testeeBefore: code,
    testeeConcurrent: code,
  );
}
