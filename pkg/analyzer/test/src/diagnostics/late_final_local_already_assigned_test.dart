// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LateFinalLocalAlreadyAssignedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LateFinalLocalAlreadyAssignedTest extends PubPackageResolutionTest {
  test_assignmentExpression_compound() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  late final int v;
  v = 0;
  v += 1;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
  v;
}
''');
  }

  test_assignmentExpression_simple() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  late final int v;
  v = 0;
  v = 1;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
  v;
}
''');
  }

  test_assignmentExpression_simple_initialized() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  late final int v = 0;
  v = 1;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
  v;
}
''');
  }

  test_localVariable() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  late final int a;
  a = 1;
  a;
}
''');
  }

  test_localVariable_forEach() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  late final int i;
  for (i in [1, 2, 3]) {
//     ^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
    print(i);
  }
}
''');
  }

  test_postfixExpression_inc() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  late final int v = 0;
  v++;
//^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
  v;
}
''');
  }

  test_postfixExpression_nullCheck() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  late final int v = 0;
  v!;
// ^
// [diag.unnecessaryNonNullAssertion] The '!' will have no effect because the receiver can't be null.
  v;
}
''');
  }

  test_prefixExpression_inc() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  late final int v = 0;
  ++v;
//  ^
// [diag.lateFinalLocalAlreadyAssigned] The late final local variable is already assigned.
  v;
}
''');
  }

  test_prefixExpression_negation() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  late final bool v = true;
  !v;
  v;
}
''');
  }
}
