// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi Pointer subtypes.
//
// VMOptions=--verbose-gc

library FfiTest;

import 'dart:ffi' as ffi;

import "package:expect/expect.dart";

import 'gc_helper.dart';
import 'cstring.dart';

void main() async {
  testAllocate();
  testSizeOf();
  await testGC();
}

class X {
  X(this.i);
  int i;
}

dynamic foo;
dynamic bar;

void testAllocate() {
  CString cs = CString.toUtf8("hello world!");
  Expect.equals("hello world!", cs.fromUtf8());
  cs.free();
}

Future<void> testGC() async {
  CString cs = ffi.fromAddress<CString>(11);
  bar = cs;
  foo = "";
  final watcher = GCWatcher.ifAvailable();
  int counts = await watcher.size();
  for (int i = 0; i < 1000000; ++i) {
    foo = new X(i);
  }
  Expect.isTrue(await watcher.size() > counts);
}

void testSizeOf() {
  Expect.equals(true, 4 == ffi.sizeOf<CString>() || 8 == ffi.sizeOf<CString>());
}
