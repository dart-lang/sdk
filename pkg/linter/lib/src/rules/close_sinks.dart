// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';
import '../util/leak_detector_visitor.dart';

const _desc = r'Close instances of `dart:core` `Sink`.';

const _details = r'''
**DO** invoke `close` on instances of `dart:core` `Sink`.

Closing instances of Sink prevents memory leaks and unexpected behavior.

**BAD:**
```dart
class A {
  IOSink _sinkA;
  void init(filename) {
    _sinkA = File(filename).openWrite(); // LINT
  }
}
```

**BAD:**
```dart
void someFunction() {
  IOSink _sinkF; // LINT
}
```

**GOOD:**
```dart
class B {
  IOSink _sinkB;
  void init(filename) {
    _sinkB = File(filename).openWrite(); // OK
  }

  void dispose(filename) {
    _sinkB.close();
  }
}
```

**GOOD:**
```dart
void someFunctionOK() {
  IOSink _sinkFOK; // OK
  _sinkFOK.close();
}
```

**Known limitations**

This rule does not track all patterns of Sink instantiations and
closures. See [linter#1381](https://github.com/dart-lang/linter/issues/1381)
for more information.

''';

class CloseSinks extends LintRule {
  CloseSinks()
      : super(
          name: 'close_sinks',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.close_sinks;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends LeakDetectorProcessors {
  static final Map<DartTypePredicate, String> _predicates = {
    _isSink: 'close',
    _isSocket: 'destroy',
  };

  _Visitor(super.rule);

  @override
  Map<DartTypePredicate, String> get predicates => _predicates;

  static bool _isSink(DartType type) =>
      type.implementsInterface('Sink', 'dart.core');

  static bool _isSocket(DartType type) =>
      type.implementsInterface('Socket', 'dart.io');
}
