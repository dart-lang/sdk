// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:expect/expect.dart';

void main() {
  final a = <int>[];
  final b = <int>[];
  for (int i = 0; i < 10; ++i) {
    // Several pointers for same call site.
    a.add(
        Pointer.fromFunction<Int Function()>(nativeToDartCallback, 0).address);
    b.add(
        Pointer.fromFunction<Int Function()>(nativeToDartCallback, 1).address);
  }

  ensureEqualEntries(a);
  ensureEqualEntries(b);

  // The two functions have different exceptional return and should have
  // therefore a different ffi trampoline.
  Expect.notEquals(a.first, b.first);
}

void ensureEqualEntries(List<int> entries) {
  final first = entries.first;
  for (int i = 1; i < entries.length; ++i) {
    Expect.equals(first, entries[i]);
  }
}

int nativeToDartCallback() => 42;
