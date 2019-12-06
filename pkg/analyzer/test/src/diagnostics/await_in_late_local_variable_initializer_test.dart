// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitInLateLocalVariableInitializerTest);
  });
}

@reflectiveTest
class AwaitInLateLocalVariableInitializerTest extends DriverResolutionTest {
  static const _errorCode =
      CompileTimeErrorCode.AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER;

  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);

  test_closure_late_await() async {
    await assertErrorsInCode('''
main() {
  var v = () async {
    late v2 = await 42;
    print(v2);
  };
  print(v);
}
''', [
      error(_errorCode, 44, 5),
    ]);
  }

  test_late_await() async {
    await assertErrorsInCode('''
main() async {
  late v = await 42;
  print(v);
}
''', [
      error(_errorCode, 26, 5),
    ]);
  }

  test_late_await_inClosure_blockBody() async {
    await assertNoErrorsInCode('''
main() async {
  late v = () async {
    await 42;
  };
  print(v);
}
''');
  }

  test_late_await_inClosure_expressionBody() async {
    await assertNoErrorsInCode('''
main() async {
  late v = () async => await 42;
  print(v);
}
''');
  }

  test_no_await() async {
    await assertNoErrorsInCode('''
main() async {
  late v = 42;
  print(v);
}
''');
  }

  test_not_late() async {
    await assertNoErrorsInCode('''
main() async {
  var v = await 42;
  print(v);
}
''');
  }
}
