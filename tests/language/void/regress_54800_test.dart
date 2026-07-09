// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

void main() async {
  asyncStart();
  testVoid();
  await testFutureVoid();
  asyncEnd();
}

void testVoid() {
  void x = int.parse('42');
  Expect.equals(42, x as dynamic);
}

Future testFutureVoid() async {
  final controller = StreamController(onCancel: () async => int.parse('42'));
  final subscription = controller.stream.listen(null);
  Expect.equals(42, (await subscription.cancel()) as dynamic);
}
