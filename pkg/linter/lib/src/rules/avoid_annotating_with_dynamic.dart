// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'Avoid annotating with `dynamic` when not required.';

const _details = r'''
**AVOID** annotating with `dynamic` when not required.

As `dynamic` is the assumed return value of a function or method, it is usually
not necessary to annotate it.

**BAD:**
```dart
dynamic lookUpOrDefault(String name, Map map, dynamic defaultValue) {
  var value = map[name];
  if (value != null) return value;
  return defaultValue;
}
```

**GOOD:**
```dart
lookUpOrDefault(String name, Map map, defaultValue) {
  var value = map[name];
  if (value != null) return value;
  return defaultValue;
}
```

''';

class AvoidAnnotatingWithDynamic extends LintRule {
  AvoidAnnotatingWithDynamic()
      : super(
          name: 'avoid_annotating_with_dynamic',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_annotating_with_dynamic;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldFormalParameter(this, visitor);
    registry.addSimpleFormalParameter(this, visitor);
    registry.addSuperFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _checkNode(node, node.type);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _checkNode(node, node.type);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _checkNode(node, node.type);
  }

  void _checkNode(NormalFormalParameter node, TypeAnnotation? type) {
    if (node.inAugmentation) return;

    if (type is NamedType && type.type is DynamicType) {
      rule.reportLint(node);
    }
  }
}

extension on AstNode {
  bool get inAugmentation {
    AstNode? target = this;
    while (target != null) {
      if (target.isAugmentation) return true;
      if (target is Block) return false;
      if (target is Declaration) return false;
      target = target.parent;
    }
    return false;
  }
}
