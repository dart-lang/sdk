// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''
main (x, y) {
  if (x != null) {
    if (y != null) {
      // Forces x and y to be int-checked.
      int a = x;
      int b = y;
      // Now we must be able to do a direct "+" operation in JS.
      return x + y;
    }
  }
}
''',
};

main() {
  var compiler = compilerFor(MEMORY_SOURCE_FILES,
                             options: ['--enable-checked-mode']);
  asyncTest(() => compiler.runCompiler(Uri.parse('memory:main.dart')).then((_) {
    var element = compiler.mainApp.findExported('main');
    var code = compiler.backend.assembleCode(element);
    Expect.isTrue(code.contains('+'), code);
  }));
}
