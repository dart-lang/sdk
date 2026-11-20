// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

void helper() {
  print('before');
  debugger(); // LINE_A
  print('after'); // LINE_B
}

void code() {
  helper();
  helper();
  helper();
}

Future<void> main([List<String> args = const <String>[]]) async => code();
