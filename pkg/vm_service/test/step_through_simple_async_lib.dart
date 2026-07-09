// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'common/test_helper.dart';

Future<void> code() // LINE_A
async {
  final f = File(Platform.script.toFilePath());
  final modified = await f.lastModified();
  final exists = await f.exists();
  print('Modified: $modified; exists: $exists');
  foo();
}

void foo() {
  print('Hello from Foo!');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
