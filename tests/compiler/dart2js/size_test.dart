// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import "compiler_helper.dart";

const String TEST = "main() => [];";

const String DEFAULT_CORELIB_WITH_LIST = r'''
  class Object {
    Object();
  }
  class bool {}
  abstract class List {}
  class num {}
  class int {}
  class double {}
  class String {}
  class Function {}
  class Type {}
  class Map {}
  class StackTrace {}
  identical(a, b) => true;
  const proxy = 0;
''';

main() {
  asyncTest(() => compileAll(TEST, coreSource: DEFAULT_CORELIB_WITH_LIST).
      then((generated) {
    return MockCompiler.create((MockCompiler compiler) {
      var backend = compiler.backend;

      // Make sure no class is emitted.
      Expect.isFalse(generated.contains(backend.emitter.finishClassesName));
    });
  }));
}
