// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

Future<void> main() async {
  asyncStart();
  List<Object Function()> callbacks = [];
  List<int> expectedHashCodes = [];

  void save(Object o) {
    expectedHashCodes.add(o.hashCode);
  }

  void check(Object o, int i) {
    Expect.equals(expectedHashCodes[i], o.hashCode);
  }

  for (int i = 0; i < 3; i++) {
    late Object o = Object();
    o;
    Object record() => o;
    callbacks.add(record);
    save(record());
  }

  for (int i = callbacks.length - 1; i >= 0; i--) {
    check(callbacks[i](), i);
  }
  asyncEnd();
}
