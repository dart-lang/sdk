// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'common/test_helper.dart';

Future<int?> code() async // LINE_A
{
  final f = File(Platform.script.toFilePath());
  final exists = await f.exists();
  if (exists) {
    return 42;
  }
  foo();
  return null;
}

void foo() {
  print('Hello from Foo!');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
