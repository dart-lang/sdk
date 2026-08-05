// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LabelInOuterScopeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LabelInOuterScopeTest extends PubPackageResolutionTest {
  test_label_in_outer_scope() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void m(int i) {
    l: while (i > 0) {
      void f() {
//         ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
        break l;
//            ^
// [diag.labelInOuterScope] Can't reference label 'l' declared in an outer method.
      };
    }
  }
}
''');
  }
}
