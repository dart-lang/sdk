// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HorizontalInferenceEnabledTest);
    defineReflectiveTests(HorizontalInferenceDisabledTest);
  });
}

@reflectiveTest
class HorizontalInferenceDisabledTest extends PubPackageResolutionTest
    with HorizontalInferenceTestCases {
  @override
  String get testPackageLanguageVersion => '2.17';
}

@reflectiveTest
class HorizontalInferenceEnabledTest extends PubPackageResolutionTest
    with HorizontalInferenceTestCases {
  @override
  List<String> get experiments =>
      [...super.experiments, EnableString.inference_update_1];
}

mixin HorizontalInferenceTestCases on PubPackageResolutionTest {
  bool get _isEnabled => experiments.contains(EnableString.inference_update_1);

  test_closure_passed_to_identical() async {
    await assertNoErrorsInCode('''
test() => identical(() {}, () {});
''');
    // No further assertions; we just want to make sure the interaction between
    // flow analysis for `identical` and deferred analysis of closures doesn't
    // lead to a crash.
  }

  test_write_capture_deferred() async {
    await assertNoErrorsInCode('''
test(int? i) {
  if (i != null) {
    f(() { i = null; }, i); // (1)
    i; // (2)
  }
}
void f(void Function() g, Object? x) {}
''');
    // With the feature enabled, analysis of the closure is deferred until after
    // all the other arguments to `f`, so the `i` at (1) is not yet write
    // captured and retains its promoted value.  With the experiment disabled,
    // it is write captured immediately.
    assertType(findNode.simple('i); // (1)'), _isEnabled ? 'int' : 'int?');
    // At (2), after the call to `f`, the write capture has taken place
    // regardless of whether the experiment is enabled.
    assertType(findNode.simple('i; // (2)'), 'int?');
  }

  test_write_capture_deferred_named() async {
    await assertNoErrorsInCode('''
test(int? i) {
  if (i != null) {
    f(g: () { i = null; }, x: i); // (1)
    i; // (2)
  }
}
void f({required void Function() g, Object? x}) {}
''');
    // With the feature enabled, analysis of the closure is deferred until after
    // all the other arguments to `f`, so the `i` at (1) is not yet write
    // captured and retains its promoted value.  With the experiment disabled,
    // it is write captured immediately.
    assertType(findNode.simple('i); // (1)'), _isEnabled ? 'int' : 'int?');
    // At (2), after the call to `f`, the write capture has taken place
    // regardless of whether the experiment is enabled.
    assertType(findNode.simple('i; // (2)'), 'int?');
  }
}
