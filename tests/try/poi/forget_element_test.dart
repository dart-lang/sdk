// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of Compiler.forgetElement.
library trydart.forget_element_test;

import 'package:compiler/implementation/elements/elements.dart' show
    LocalFunctionElement;

import 'compiler_test_case.dart';

class ForgetElementTestCase extends CompilerTestCase {
  final int expectedClosureCount;

  ForgetElementTestCase(String source, {int closureCount})
      : this.expectedClosureCount = closureCount,
        super(source);

  Future run() => compile().then((LibraryElement library) {

    // Check that the compiler has recorded the expected number of closures.
    Expect.equals(expectedClosureCount, closuresInLibrary(library).length);

    // Forget about all elements.
    library.forEachLocalMember(compiler.forgetElement);

    // Check that all the closures were forgotten.
    Expect.isTrue(closuresInLibrary(library).isEmpty);
  });

  Iterable closuresInLibrary(LibraryElement library) {
    return compiler.enqueuer.resolution.universe.allClosures.where(
        (LocalFunctionElement closure) => closure.library == library);
  }
}

void main() {
  runTests(
      [
          new ForgetElementTestCase(
              'main() {}',
              closureCount: 0),

          new ForgetElementTestCase(
              'main() => null;',
              closureCount: 0),

          new ForgetElementTestCase(
              'main() => (() => null)();',
              closureCount: 1),

          new ForgetElementTestCase(
              'main() => (() => (() => null)())();',
              closureCount: 2),

          new ForgetElementTestCase(
              'main() => (() => (() => (() => null)())())();',
              closureCount: 3),
      ]
  );
}
