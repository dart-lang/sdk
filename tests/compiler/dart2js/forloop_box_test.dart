// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

String TEST = r'''
main() {
  var a;
  for (var i=0; i<10; i++) {
    a = () => i;
  }
  print(a());
}
''';

String NEGATIVE_TEST = r'''
run(f) => f();
main() {
  var a;
  for (var i=0; i<10; run(() => i++)) {
    a = () => i;
  }
  print(a());
}
''';

main() {
  asyncTest(() => compileAll(TEST).then((generated) {
        Expect.isTrue(generated.contains('main_closure(i)'),
            'for-loop variable was boxed');
      }));
  asyncTest(() => compileAll(NEGATIVE_TEST).then((generated) {
        Expect.isFalse(generated.contains('main_closure(i)'),
            'for-loop variable was not boxed');
      }));
}
