// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that dart2js doesn't support metadata on local elements.
// Remove this file when dart2js support such features.
library trydart.forget_element_assertion;

import '../../compiler/dart2js/compiler_helper.dart' show
    compilerFor;

import 'compiler_test_case.dart';

class FailingTestCase extends CompilerTestCase {
  FailingTestCase.intermediate(String source, int errorCount, Uri scriptUri)
      : super.init(
          source, scriptUri,
          compilerFor(source, scriptUri, expectedErrors: errorCount));

  FailingTestCase(String source, int errorCount)
      : this.intermediate(source, errorCount, customUri('main.dart'));

  Future run() {
    return compile().then((_) {
      print("Failed as expected.");
    }).catchError((error, stackTrace) {
      print(
          "\n\n\n***\n\n\n"
          "The compiler didn't fail when compiling:\n $source\n\n"
          "Please adjust assumptions in "
          "tests/try/poi/forget_element_assertion.dart\n\n"
        );
      print("$error\n$stackTrace");
      throw "Please update assumptions in this file.";
    });
  }
}

List<FailingTestCase> assertUnimplementedLocalMetadata() {
  return <FailingTestCase>[

      // This tests that the compiler doesn't accept metadata on local
      // functions. If this feature is implemented, please convert this test to
      // a positive test in forget_element_test.dart. For example:
      //
      //    new ForgetElementTestCase(
      //       'main() { @Constant() foo() {}; return foo(); } $CONSTANT_CLASS',
      //       metadataCount: 1),
      new FailingTestCase(
          'main() { @Constant() foo() {}; return foo(); } $CONSTANT_CLASS',
          1),

      // This tests that the compiler doesn't accept metadata on local
      // variables. If this feature is implemented, please convert this test to
      // a positive test in forget_element_test.dart. For example:
      //
      //    new ForgetElementTestCase(
      //       'main() { @Constant() var x; return x; } $CONSTANT_CLASS',
      //       metadataCount: 1),
      new FailingTestCase(
          'main() { @Constant() var x; return x; } $CONSTANT_CLASS',
          1),
    ];
}
