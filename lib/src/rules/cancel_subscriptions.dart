// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/leak_detector_visitor.dart';

const _desc = r'Cancel instances of dart.async.StreamSubscription.';

const _details = r'''
**DO** invoke `cancel` on instances of `dart.async.StreamSubscription`.

Cancelling instances of StreamSubscription prevents memory leaks and unexpected
behavior.

**BAD:**
```dart
class A {
  StreamSubscription _subscriptionA; // LINT
  void init(Stream stream) {
    _subscriptionA = stream.listen((_) {});
  }
}
```

**BAD:**
```dart
void someFunction() {
  StreamSubscription _subscriptionF; // LINT
}
```

**GOOD:**
```dart
class B {
  StreamSubscription _subscriptionB; // OK
  void init(Stream stream) {
    _subscriptionB = stream.listen((_) {});
  }

  void dispose(filename) {
    _subscriptionB.cancel();
  }
}
```

**GOOD:**
```dart
void someFunctionOK() {
  StreamSubscription _subscriptionB; // OK
  _subscriptionB.cancel();
}
```

''';

bool _isSubscription(DartType type) =>
    type.implementsInterface('StreamSubscription', 'dart.async');

class CancelSubscriptions extends LintRule {
  static const LintCode code = LintCode(
      'cancel_subscriptions', "Uncancelled instance of 'StreamSubscription'.",
      correctionMessage: "Try invoking 'cancel' in the function in which the "
          "'StreamSubscription' was created.");

  CancelSubscriptions()
      : super(
            name: 'cancel_subscriptions',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends LeakDetectorProcessors {
  static const _cancelMethodName = 'cancel';

  @override
  Map<DartTypePredicate, String> predicates = {
    _isSubscription: _cancelMethodName
  };

  _Visitor(super.rule);
}
