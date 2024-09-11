// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';
import '../util/leak_detector_visitor.dart';

const _desc = r'Cancel instances of `dart:async` `StreamSubscription`.';

const _details = r'''
**DO** invoke `cancel` on instances of `dart:async` `StreamSubscription`.

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

**Known limitations**

This rule does not track all patterns of StreamSubscription instantiations and
cancellations. See [linter#317](https://github.com/dart-lang/linter/issues/317)
for more information.

''';

class CancelSubscriptions extends LintRule {
  CancelSubscriptions()
      : super(
          name: 'cancel_subscriptions',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.cancel_subscriptions;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends LeakDetectorProcessors {
  static final _predicates = {
    _isSubscription: 'cancel',
  };

  _Visitor(super.rule);

  @override
  Map<DartTypePredicate, String> get predicates => _predicates;

  static bool _isSubscription(DartType type) =>
      type.implementsInterface('StreamSubscription', 'dart.async');
}
