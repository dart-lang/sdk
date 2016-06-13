// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.cancel_subscriptions;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/util/dart_type_utilities.dart';
import 'package:linter/src/util/leak_detector_visitor.dart';

const _desc = r'Cancel instances of dart.async.StreamSubscription.';

const _details = r'''

**DO** Invoke `cancel` on instances of `dart.async.StreamSubscription` to avoid
memory leaks and unexpected behaviors.

**BAD:**
```
class A {
  StreamSubscription _subscriptionA; // LINT
  void init(Stream stream) {
    _subscriptionA = stream.listen((_) {});
  }
}
```

**BAD:**
```
void someFunction() {
  StreamSubscription _subscriptionF; // LINT
}
```

**GOOD:**
```
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
```
void someFunctionOK() {
  StreamSubscription _subscriptionB; // OK
  _subscriptionB.cancel();
}
```
''';

class CancelSubscriptions extends LintRule {
  _Visitor _visitor;

  CancelSubscriptions() : super(
      name: 'cancel_subscriptions',
      description: _desc,
      details: _details,
      group: Group.errors,
      maturity: Maturity.experimental) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends LeakDetectorVisitor {
  static const _cancelMethodName = 'cancel';

  _Visitor(LintRule rule) : super(rule);

  @override
  String get methodName => _cancelMethodName;

  @override
  DartTypePredicate get predicate => _isSubscription;
}

bool _isSubscription(DartType type) =>
    DartTypeUtilities.implementsInterface(type, 'StreamSubscription', 'dart.async');
