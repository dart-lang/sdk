// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

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
  asyncTest(() => compileAll(SHOULD_NOT_BE_BOXED_TEST).then((generated) {
        Expect.isTrue(generated.contains('main_closure(i)'),
            'for-loop variable should not have been boxed');
      }));
  asyncTest(() => compileAll(SHOULD_BE_BOXED_TEST).then((generated) {
        Expect.isFalse(generated.contains('main_closure(i)'),
            'for-loop variable should have been boxed');
      }));
  asyncTest(() => compileAll(ONLY_UPDATE_LOOP_VAR_TEST).then((generated) {
        Expect.isFalse(generated.contains('main_closure(i)'),
            'for-loop variable was not boxed');
        Expect.isFalse(generated.contains(', _box_0.b = 3,'),
            'non for-loop captured variable should not be updated in loop');
      }));
}
