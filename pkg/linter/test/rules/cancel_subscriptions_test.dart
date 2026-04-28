// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CancelSubscriptionsTest);
  });
}

@reflectiveTest
class CancelSubscriptionsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.cancel_subscriptions;

  test_extensionType_implementsStreamSubscription_canceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(Stream stream) {
  E e = E(stream.listen((_) {}));
  e.cancel();
}
extension type E(StreamSubscription _s) implements StreamSubscription {}
''');
  }

  test_extensionType_implementsStreamSubscription_notCanceled() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
void f(Stream stream) {
  E e = E(stream.listen((_) {}));
}
extension type E(StreamSubscription _s) implements StreamSubscription {}
''',
      [lint(49, 28)],
    );
  }

  test_extensionType_representation_notCanceled() async {
    await assertNoDiagnostics(r'''
  import 'dart:async';
  extension type E(StreamSubscription _s) {}
  ''');
  }

  test_localVariable_canceled_cascade() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(Stream stream) {
  var s = stream.listen((_) {})..cancel();
}
''');
  }

  test_localVariable_canceled_inMethodInvocation() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(Stream stream) {
  StreamSubscription s = stream.listen((_) {});
  unawaited(s.cancel());
}
''');
  }

  test_localVariable_canceled_nullAware() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
StreamSubscription? f(StreamSubscription? s) {
  StreamSubscription? s2 = s;
  s2?.cancel();
  return s2;
}
''');
  }

  test_localVariable_canceled_tearOff() async {
    // This may not be the desired behavior, counting a tear-off as a valid call
    // to `cancel`. But it is the current behavior.
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(Stream stream) {
  StreamSubscription s = stream.listen((_) {});
  s.cancel;
}
''');
  }

  test_localVariable_notCanceled() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
void f(Stream stream) {
  StreamSubscription s = stream.listen((_) {});
}
''',
      [lint(66, 25)],
    );
  }

  test_parameter_notCanceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(StreamSubscription s) {}
''');
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
        'presumably the intention of the previous test.',
  )
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

  test_privateField_canceled_withNullCheck() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
class C<T> {
  StreamSubscription<T>? subscription;
  void unsubscribe() {
    if (subscription != null) {
      subscription!.cancel();
      subscription = null;
    }
  }
}
''');
  }

  test_privateField_initializedInConstructorInitializer_notCanceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
class A {
  StreamSubscription _subscription;
  A(StreamSubscription subscription) : _subscription = subscription;
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
}
''');
  }

  test_privateField_initializedInConstructorInitializer_primaryConstructorBody_notCanceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
class A(StreamSubscription subscription) {
  StreamSubscription _subscription;
  this : _subscription = subscription;
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
}
''');
  }

  test_privateField_initializedInFieldFormalParameter_notCanceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
class A {
  StreamSubscription _subscription;
  A(this._subscription);
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
}
''');
  }

  test_privateField_notCanceled() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
class A {
  late StreamSubscription _subscription;
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
}
''',
      [lint(57, 13)],
    );
  }

  test_privateField_originPrimaryConstructor_canceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
class A(var StreamSubscription _subscription) {
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
  void g() {
    _subscription.cancel();
  }
}
''');
  }

  test_privateField_originPrimaryConstructor_notCanceled() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
// ignore: unused_field_from_primary_constructor
class A(var StreamSubscription _subscription) {
  void f(Stream stream) {
    _subscription = stream.listen((_) {});
  }
}
''',
      [lint(78, 36)],
    );
  }

  test_publicField_notCanceled() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
class A {
  late StreamSubscription subscription;
  void f(Stream stream) {
    subscription = stream.listen((_) {});
  }
}
''',
      [lint(57, 12)],
    );
  }

  test_topLevelVariable_notCanceled() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
late StreamSubscription subscription;
void f(Stream stream) {
  subscription = stream.listen((_) {});
}
''');
  }
}
