// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r"Don't explicitly initialize variables to null.";

const _details = r'''

From [effective dart](https://dart.dev/guides/language/effective-dart/usage#dont-explicitly-initialize-variables-to-null):

**DON'T** explicitly initialize variables to null.

In Dart, a variable or field that is not explicitly initialized automatically
gets initialized to null.  This is reliably specified by the language.  There's
no concept of "uninitialized memory" in Dart.  Adding `= null` is redundant and
unneeded.

**GOOD:**
```
int _nextId;

class LazyId {
  int _id;

  int get id {
    if (_nextId == null) _nextId = 0;
    if (_id == null) _id = _nextId++;

    return _id;
  }
}
```

**BAD:**
```
int _nextId = null;

class LazyId {
  int _id = null;

  int get id {
    if (_nextId == null) _nextId = 0;
    if (_id == null) _id = _nextId++;

    return _id;
  }
}
```

''';

class AvoidInitToNull extends LintRule implements NodeLintRule {
  AvoidInitToNull()
      : super(
            name: 'avoid_init_to_null',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.addVariableDeclaration(this, visitor);
    registry.addDefaultFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  bool nnbdEnabled = false;
  _Visitor(this.rule, this.context);

  bool isNullable(DartType type) =>
      !nnbdEnabled || (type != null && context.typeSystem.isNullable(type));

  @override
  void visitCompilationUnit(CompilationUnit node) {
    nnbdEnabled = node.featureSet.isEnabled(Feature.non_nullable);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (DartTypeUtilities.isNullLiteral(node.defaultValue) &&
        isNullable(node.declaredElement.type)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (!node.isConst &&
        !node.isFinal &&
        DartTypeUtilities.isNullLiteral(node.initializer) &&
        isNullable(node.declaredElement.type)) {
      rule.reportLint(node);
    }
  }
}
