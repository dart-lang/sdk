// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid private typedef functions.';

const _details = r'''
**AVOID** private typedef functions used only once. Prefer inline function
syntax.

**BAD:**
```dart
typedef void _F();
m(_F f);
```

**GOOD:**
```dart
m(void Function() f);
```

''';

class AvoidPrivateTypedefFunctions extends LintRule {
  static const LintCode code = LintCode('avoid_private_typedef_functions',
      'The typedef is unnecessary because it is only used in one place.',
      correctionMessage: 'Try inlining the type or using it in other places.');

  AvoidPrivateTypedefFunctions()
      : super(
            name: 'avoid_private_typedef_functions',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addGenericTypeAlias(this, visitor);
  }
}

class _CountVisitor extends RecursiveAstVisitor {
  final String type;
  int count = 0;
  _CountVisitor(this.type);

  @override
  void visitNamedType(NamedType node) {
    if (node.name2.lexeme == type) count++;
    super.visitNamedType(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _countAndReport(node.name);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (node.typeParameters != null) return;
    if (node.type is NamedType) return;
    if (node.type is RecordTypeAnnotation) return;

    _countAndReport(node.name);
  }

  void _countAndReport(Token identifier) {
    var name = identifier.lexeme;
    if (!Identifier.isPrivateName(name)) return;

    var visitor = _CountVisitor(name);
    for (var unit in context.allUnits) {
      unit.unit.accept(visitor);
    }
    if (visitor.count <= 1) {
      rule.reportLintForToken(identifier);
    }
  }
}
