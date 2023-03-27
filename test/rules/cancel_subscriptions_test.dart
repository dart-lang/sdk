// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CancelSubscriptionsTest);

    // TODO(srawlins): Test more things:
    // * null-aware cancel (`?.cancel()`) and cascade cancel (`..cancel()`)
    // * StreamSubscription as a parameter
    // * StreamSubscription as a top-level variable
    // * public fields
    // * cancel tear-off (`.cancel;`)
    // * StreamSubscription subtypes
    // * field initialized in a field initializer and in a field formal
    //   parameter
    // * multiple declarations in a field declaration list and a variable
    //   declaration list
    // * StreamSubscription being passed into a function
    // * subscription canceled in a part
    // * subscription declared in a part
  });
}

@reflectiveTest
class CancelSubscriptionsTest extends LintRuleTest {
  @override
  String get lintRule => 'cancel_subscriptions';

  test_localVariable_canceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(Stream stream) {
  StreamSubscription s = stream.listen((_) {});
  s.cancel();
}
''');
  }

  test_localVariable_notCanceled() async {
    await assertDiagnostics(r'''
import 'dart:async';
void f(Stream stream) {
  StreamSubscription s = stream.listen((_) {});
}
''', [
      lint(66, 25),
    ]);
  }

  test_privateField_canceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
class A {
  late StreamSubscription _subscription;
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
  void g() {
    _subscription.cancel();
  }
}
''');
  }

  test_privateField_canceled_nullable() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
class A {
  StreamSubscription? _subscription;
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
  void g() {
    _subscription!.cancel();
  }
}
''');
  }

  @FailingTest(
      reason:
          'It seems this is not implemented. In the previous incarnation of '
          'this test, at `test_data/integration/cancel_subscriptions.dart`, an '
          'end-of-line comment (`// OK`) indicated that the subscription '
          'should be counted as canceled. However, that is not how an '
          'expectation is set in an integration test, and a Lint is indeed '
          'reported for this case. We have the test written here with what was '
          'presumably the intention of the previous test.')
  test_privateField_canceled_outsideTheClass() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
class A {
  late StreamSubscription _subscription;
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
}
class B {
  A a = A();
  B() {
    a._subscription.cancel();
  }
}
''');
  }

  test_privateField_notCanceled() async {
    await assertDiagnostics(r'''
import 'dart:async';
class A {
  late StreamSubscription _subscription;
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
}
''', [
      error(WarningCode.UNUSED_FIELD, 57, 13),
      lint(57, 13),
    ]);
  }
}
