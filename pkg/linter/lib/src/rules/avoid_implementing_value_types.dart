// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r"Don't implement classes that override `==`.";

const _details = r'''
**DON'T** implement classes that override `==`.

The `==` operator is contractually required to be an equivalence relation;
that is, symmetrically for all objects `o1` and `o2`, `o1 == o2` and `o2 == o1`
must either both be true, or both be false.

> _NOTE_: Dart does not have true _value types_, so instead we consider a class
> that implements `==`  as a _proxy_ for identifying value types.

When using `implements`, you do not inherit the method body of `==`, making it
nearly impossible to follow the contract of `==`. Classes that override `==`
typically are usable directly in tests _without_ creating mocks or fakes as
well. For example, for a given class `Size`:

```dart
class Size {
  final int inBytes;
  const Size(this.inBytes);

  @override
  bool operator ==(Object other) => other is Size && other.inBytes == inBytes;

  @override
  int get hashCode => inBytes.hashCode;
}
```

**BAD:**
```dart
class CustomSize implements Size {
  final int inBytes;
  const CustomSize(this.inBytes);

  int get inKilobytes => inBytes ~/ 1000;
}
```

**BAD:**
```dart
import 'package:test/test.dart';
import 'size.dart';

class FakeSize implements Size {
  int inBytes = 0;
}

void main() {
  test('should not throw on a size >1Kb', () {
    expect(() => someFunction(FakeSize()..inBytes = 1001), returnsNormally);
  });
}
```

**GOOD:**
```dart
class ExtendedSize extends Size {
  ExtendedSize(int inBytes) : super(inBytes);

  int get inKilobytes => inBytes ~/ 1000;
}
```

**GOOD:**
```dart
import 'package:test/test.dart';
import 'size.dart';

void main() {
  test('should not throw on a size >1Kb', () {
    expect(() => someFunction(Size(1001)), returnsNormally);
  });
}
```

''';

class AvoidImplementingValueTypes extends LintRule {
  AvoidImplementingValueTypes()
      : super(
          name: 'avoid_implementing_value_types',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_implementing_value_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var implementsClause = node.implementsClause;
    if (implementsClause == null) {
      return;
    }
    for (var interface in implementsClause.interfaces) {
      var interfaceType = interface.type;
      if (interfaceType is InterfaceType &&
          _overridesEquals(interfaceType.element)) {
        rule.reportLint(interface);
      }
    }
  }

  static bool _overridesEquals(InterfaceElement element) {
    var method = element.lookUpConcreteMethod('==', element.library);
    var enclosing = method?.enclosingElement3;
    return enclosing is ClassElement && !enclosing.isDartCoreObject;
  }
}
