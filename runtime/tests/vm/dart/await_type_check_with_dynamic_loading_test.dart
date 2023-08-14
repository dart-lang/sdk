// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that optimized code is correctly deoptimized
// when a new implementation of Future is dynamically loaded and
// existing classes now have a new subtype which is a Future.

// VMOptions=--optimization-counter-threshold=100 --deterministic

import 'dart:async';
import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {}

class B implements A {}

class C implements A {}

Future<A> test1(Object expected, A x) async {
  Expect.identical(expected, await x);
  return x;
}

Future<void> test2(Object expected, A x) async {
  Expect.identical(expected, await test1(expected, x));
}

void main() async {
  for (int i = 0; i < 120; ++i) {
    final obj1 = B();
    await test2(obj1, obj1);
    final obj2 = C();
    await test2(obj2, obj2);
  }

  final isolate = currentMirrorSystem().isolate;
  final library = await isolate
      .loadUri(Uri.parse("await_type_check_with_dynamic_loading_lib.dart"));
  final (Object expected, A x) = library.invoke(#makeNewFuture, []).reflectee;
  await test2(expected, x);
}
