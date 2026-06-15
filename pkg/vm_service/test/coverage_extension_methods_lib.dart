// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class Bar {}

/* OFFSET_GET_FROM */ extension Foo on Bar {
  /* OFFSET_BAZ_START */ void baz() {
    /* OFFSET_PRINT */ print('hello'); /* OFFSET_BAZ_END */
  } /* OFFSET_GET_TO */
}

void testFunction() {
  debugger();
  final bar = Bar();
  bar.baz();
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
