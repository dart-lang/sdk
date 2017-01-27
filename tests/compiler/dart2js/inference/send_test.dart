// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'inference_test_helper.dart';

const List<String> TESTS = const <String>[
  '''
class Super {
  var field = 42;
}
class Sub extends Super {
  method() {
   var a = super.field = new Sub();
   return a.@{[exact=Sub]}method;
  }
}
main() {
  new Sub().@{[exact=Sub]}method();
}
''',
];

main() {
  asyncTest(() async {
    for (String annotatedCode in TESTS) {
      await checkCode(annotatedCode);
    }
  });
}
