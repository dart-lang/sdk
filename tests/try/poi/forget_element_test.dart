// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of Compiler.forgetElement.
library trydart.forget_element_test;

import 'package:compiler/implementation/elements/elements.dart' show
    LocalFunctionElement,
    MetadataAnnotation;

import 'package:compiler/implementation/js_backend/js_backend.dart' show
    JavaScriptBackend;

import 'compiler_test_case.dart';

class ForgetElementTestCase extends CompilerTestCase {
  final int expectedClosureCount;

  final int expectedMetadataCount;

  ForgetElementTestCase(
      String source,
      {int closureCount: 0,
       int metadataCount: 0})
      : this.expectedClosureCount = closureCount,
        this.expectedMetadataCount = metadataCount,
        super(source);

  Future run() => compile().then((LibraryElement library) {

    // Check that the compiler has recorded the expected number of closures.
    Expect.equals(
        expectedClosureCount, closuresInLibrary(library).length,
        'closure count');

    // Check that the compiler has recorded the expected number of metadata
    // annotations.
    Expect.equals(
        expectedMetadataCount, metadataInLibrary(library).length,
        'metadata count');

    // Forget about all elements.
    library.forEachLocalMember(compiler.forgetElement);

    // Check that all the closures were forgotten.
    Expect.isTrue(closuresInLibrary(library).isEmpty, 'closures');

    // Check that the metadata annotations were forgotten.
    Expect.isTrue(metadataInLibrary(library).isEmpty, 'metadata');
  });

  Iterable closuresInLibrary(LibraryElement library) {
    return compiler.enqueuer.resolution.universe.allClosures.where(
        (LocalFunctionElement closure) => closure.library == library);
  }

  Iterable metadataInLibrary(LibraryElement library) {
    JavaScriptBackend backend = compiler.backend;
    return backend.constants.metadataConstantMap.keys.where(
        (MetadataAnnotation metadata) {
          return metadata.annotatedElement.library == library;
        });
  }
}

const String CONSTANT_CLASS = 'class Constant { const Constant(); }';

void main() {
  runTests(
      [
          new ForgetElementTestCase(
              'main() {}'),

          new ForgetElementTestCase(
              'main() => null;'),

          new ForgetElementTestCase(
              'main() => (() => null)();',
              closureCount: 1),

          new ForgetElementTestCase(
              'main() => (() => (() => null)())();',
              closureCount: 2),

          new ForgetElementTestCase(
              'main() => (() => (() => (() => null)())())();',
              closureCount: 3),

          new ForgetElementTestCase(
              '@Constant() main() => null; $CONSTANT_CLASS',
              metadataCount: 1),

          new ForgetElementTestCase(
              'main() => ((@Constant() x) => x)(null); $CONSTANT_CLASS',
              closureCount: 1,
              metadataCount: 1),
      ]
  );
}
