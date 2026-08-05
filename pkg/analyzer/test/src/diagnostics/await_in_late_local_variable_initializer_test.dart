// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitInLateLocalVariableInitializerTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AwaitInLateLocalVariableInitializerTest extends PubPackageResolutionTest {
  test_closure_late_await() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = () async {
    late var v2 = await 42;
//                ^^^^^
// [diag.awaitInLateLocalVariableInitializer] The 'await' expression can't be used in a 'late' local variable's initializer.
    print(v2);
  };
  print(v);
}
''');
  }

  test_late_await() async {
    await resolveTestCodeWithDiagnostics(r'''
main() async {
  late var v = await 42;
//             ^^^^^
// [diag.awaitInLateLocalVariableInitializer] The 'await' expression can't be used in a 'late' local variable's initializer.
  print(v);
}
''');
  }

  test_late_await_inClosure_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
main() async {
  late var v = () async {
    await 42;
  };
  print(v);
}
''');
  }

  test_late_await_inClosure_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
main() async {
  late var v = () async => await 42;
  print(v);
}
''');
  }

  test_no_await() async {
    await resolveTestCodeWithDiagnostics(r'''
main() async {
  late var v = 42;
  print(v);
}
''');
  }

  test_not_late() async {
    await resolveTestCodeWithDiagnostics(r'''
main() async {
  var v = await 42;
  print(v);
}
''');
  }
}
