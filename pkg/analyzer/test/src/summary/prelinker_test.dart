// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.prelinker_test;

import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'summarize_ast_test.dart';
import 'summary_common.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrelinkerTest);
  });
}

/**
 * Override of [SummaryTest] which verifies the correctness of the prelinker by
 * creating summaries from the element model, discarding their prelinked
 * information, and then recreating it using the prelinker.
 */
@reflectiveTest
class PrelinkerTest extends LinkedSummarizeAstTest {
  @override
  bool get skipFullyLinkedData => true;

  @override
  bool get strongMode => false;

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    super.serializeLibraryText(text, allowErrors: allowErrors);

    UnlinkedUnit getPart(String absoluteUri) {
      return linkerInputs.getUnit(absoluteUri);
    }

    UnlinkedPublicNamespace getImport(String absoluteUri) {
      return getPart(absoluteUri)?.publicNamespace;
    }

    linked = new LinkedLibrary.fromBuffer(prelink(
        linkerInputs.testDartUri.toString(),
        linkerInputs.unlinkedDefiningUnit,
        getPart,
        getImport,
        (String declaredVariable) => null).toBuffer());
    validateLinkedLibrary(linked);
  }
}
