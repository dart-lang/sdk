// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

class S {}

mixin class M {
  static String? foo;
  void bar() {
    foo = 'theExpectedValue';
  }
}

// MA -> S&M -> S -> Object
class MA extends S with M {}

late final MA global;
void testeeMain() {
  global = MA()..bar();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
