// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests ThreadLocal.
//
// VMOptions=--experimental-shared-data

import 'dart:isolate';
import 'dart:_vm' show ThreadLocal;

import 'package:expect/expect.dart';
import 'package:expect/async_helper.dart';

@pragma('vm:shared')
final ThreadLocal<String> threadLocal = ThreadLocal<String>();

void main() async {
  asyncStart();
  // Make sure that threadLocal retains its value even if underlying
  // dart::Thread gets reclaimed and recreated.
  final results = await List.generate(
    64,
    (_) => Isolate.run(() async {
      threadLocal.value = "ok";
      await Future.delayed(const Duration(milliseconds: 10));
      return threadLocal.hasValue ? threadLocal.value : "fail";
    }),
  ).wait;
  Expect.listEquals(['ok'], results.toSet().toList());
  asyncEnd();
}
