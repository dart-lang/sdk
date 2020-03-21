// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../helpers/compiler_helper.dart';

String SHOULD_NOT_BE_BOXED_TEST = r'''
main() {
  var a;
  for (var i=0; i<10; i++) {
    a = () => i;
  }
  print(a());
}
''';

String SHOULD_BE_BOXED_TEST = r'''
run(f) => f();
main() {
  var a;
  for (var i=0; i<10; run(() => i++)) {
    a = () => i;
  }
  print(a());
}
''';

String ONLY_UPDATE_LOOP_VAR_TEST = r'''
run(f) => f();
main() {
  var a;
  for (var i=0; i<10; run(() => i++)) {
    var b = 3;
    a = () => b = i;
  }
  print(a());
}
''';

main() {
  runTests() async {
    String generated1 = await compileAll(SHOULD_NOT_BE_BOXED_TEST);
    Expect.isTrue(generated1.contains('main_closure(i)'),
        'for-loop variable should not have been boxed');

    String generated2 = await compileAll(SHOULD_BE_BOXED_TEST);
    Expect.isFalse(generated2.contains('main_closure(i)'),
        'for-loop variable should have been boxed');

    String generated3 = await compileAll(ONLY_UPDATE_LOOP_VAR_TEST);
    Expect.isFalse(generated3.contains('main_closure(i)'),
        'for-loop variable should have been boxed');
    Expect.isFalse(generated3.contains(', _box_0.b = 3,'),
        'non for-loop captured variable should not be updated in loop');
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
