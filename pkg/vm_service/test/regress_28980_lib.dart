// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'common/test_helper.dart';

late A _lock;
bool _lockEnabled = true;

String flutterRoot = 'abc';

A foo(String a, String b, String c, String d) {
  return A(); // LINE_A
}

class A {
  Future lock() => Future.microtask(() => print('lock'));
  final path = 'path';
}

class FileSystemException {}

Future<void> testCode() async {
  if (!_lockEnabled) return;
  _lock = foo(flutterRoot, 'bin', 'cache', 'lockfile');
  bool locked = false;
  bool printed = false;
  while (!locked) {
    try {
      await _lock.lock();
      locked = true; // LINE_B
    } on FileSystemException {
      if (!printed) {
        print('Print path: ${_lock.path}');
        print('Just another line...');
        printed = true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testCode);
}
