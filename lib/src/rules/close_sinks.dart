// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';
import 'package:linter/src/util/leak_detector_visitor.dart';

const _desc = r'Close instances of `dart.core.Sink`.';

const _details = r'''

**DO** invoke `close` on instances of `dart.core.Sink`.

Closing instances of Sink prevents memory leaks and unexpected behavior.

**BAD:**
```
class A {
  IOSink _sinkA;
  void init(filename) {
    _sinkA = new File(filename).openWrite(); // LINT
  }
}
```

**BAD:**
```
void someFunction() {
  IOSink _sinkF; // LINT
}
```

**GOOD:**
```
class B {
  IOSink _sinkB;
  void init(filename) {
    _sinkB = new File(filename).openWrite(); // OK
  }

  void dispose(filename) {
    _sinkB.close();
  }
}
```

**GOOD:**
```
void someFunctionOK() {
  IOSink _sinkFOK; // OK
  _sinkFOK.close();
}
```

''';

bool _isSink(DartType type) =>
    DartTypeUtilities.implementsInterface(type, 'Sink', 'dart.core');

bool _isSocket(DartType type) =>
    DartTypeUtilities.implementsInterface(type, 'Socket', 'dart.io');

class CloseSinks extends LintRule {
  _Visitor _visitor;

  CloseSinks()
      : super(
            name: 'close_sinks',
            description: _desc,
            details: _details,
            group: Group.errors) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends LeakDetectorVisitor {
  static const _closeMethodName = 'close';
  static const _destroyMethodName = 'destroy';

  @override
  Map<DartTypePredicate, String> predicates = {
    _isSink: _closeMethodName,
    _isSocket: _destroyMethodName
  };

  _Visitor(LintRule rule) : super(rule);
}
