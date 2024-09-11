// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';
import '../util/ascii_utils.dart';

const _desc = r'Type annotate public APIs.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/design#do-type-annotate-fields-and-top-level-variables-if-the-type-isnt-obvious):

**PREFER** type annotating public APIs.

Type annotations are important documentation for how a library should be used.
Annotating the parameter and return types of public methods and functions helps
users understand what the API expects and what it provides.

Note that if a public API accepts a range of values that Dart's type system
cannot express, then it is acceptable to leave that untyped.  In that case, the
implicit `dynamic` is the correct type for the API.

For code internal to a library (either private, or things like nested functions)
annotate where you feel it helps, but don't feel that you *must* provide them.

**BAD:**
```dart
install(id, destination) {
  // ...
}
```

Here, it's unclear what `id` is.  A string? And what is `destination`? A string
or a `File` object? Is this method synchronous or asynchronous?

**GOOD:**
```dart
Future<bool> install(PackageId id, String destination) {
  // ...
}
```

With types, all of this is clarified.

''';

class TypeAnnotatePublicApis extends LintRule {
  TypeAnnotatePublicApis()
      : super(
          name: 'type_annotate_public_apis',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.type_annotate_public_apis;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final _VisitorHelper v;

  _Visitor(this.rule) : v = _VisitorHelper(rule);
  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isAugmentation) return;

    if (node.fields.type == null) {
      node.fields.accept(v);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.isAugmentation) return;

    if (!node.name.isPrivate &&
        // Only report on top-level functions, not those declared within the
        // scope of another function.
        node.parent is CompilationUnit) {
      if (node.returnType == null && !node.isSetter) {
        rule.reportLintForToken(node.name);
      } else {
        node.functionExpression.parameters?.accept(v);
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!node.name.isPrivate) {
      if (node.returnType == null) {
        rule.reportLintForToken(node.name);
      } else {
        node.parameters.accept(v);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isAugmentation) return;

    if (!node.name.isPrivate) {
      if (node.returnType == null && !node.isSetter) {
        rule.reportLintForToken(node.name);
      } else {
        node.parameters?.accept(v);
      }
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.isAugmentation) return;

    if (node.variables.type == null) {
      node.variables.accept(v);
    }
  }
}

class _VisitorHelper extends RecursiveAstVisitor {
  final LintRule rule;

  _VisitorHelper(this.rule);

  bool hasInferredType(VariableDeclaration node) {
    var staticType = node.initializer?.staticType;
    return staticType != null &&
        staticType is! DynamicType &&
        !staticType.isDartCoreNull;
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter param) {
    if (param.type == null) {
      var paramName = param.name?.lexeme;
      if (paramName != null && !paramName.isJustUnderscores) {
        rule.reportLint(param);
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (!node.name.isPrivate &&
        !node.isConst &&
        !(node.isFinal && hasInferredType(node))) {
      rule.reportLintForToken(node.name);
    }
  }
}
