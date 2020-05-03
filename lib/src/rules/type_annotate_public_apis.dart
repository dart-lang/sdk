// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../utils.dart';

const _desc = r'Type annotate public APIs.';

const _details = r'''

From [effective dart](https://dart.dev/guides/language/effective-dart/design#prefer-type-annotating-public-fields-and-top-level-variables-if-the-type-isnt-obvious):

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
```
install(id, destination) {
  // ...
}
```

Here, it's unclear what `id` is.  A string? And what is `destination`? A string
or a `File` object? Is this method synchronous or asynchronous?

**GOOD:**
```
Future<bool> install(PackageId id, String destination) {
  // ...
}
```

With types, all of this is clarified.

''';

class TypeAnnotatePublicApis extends LintRule implements NodeLintRule {
  TypeAnnotatePublicApis()
      : super(
            name: 'type_annotate_public_apis',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
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
    if (node.fields.type == null) {
      node.fields.accept(v);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!isPrivate(node.name) &&
        // Only report on top-level functions, not those declared within the
        // scope of another function.
        node.parent is CompilationUnit) {
      if (node.returnType == null && !node.isSetter) {
        rule.reportLint(node.name);
      } else {
        node.functionExpression.parameters?.accept(v);
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!isPrivate(node.name)) {
      if (node.returnType == null) {
        rule.reportLint(node.name);
      } else {
        node.parameters.accept(v);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!isPrivate(node.name)) {
      if (node.returnType == null && !node.isSetter) {
        rule.reportLint(node.name);
      } else {
        node.parameters?.accept(v);
      }
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
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
        !staticType.isDynamic &&
        !staticType.isDartCoreNull;
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter param) {
    if (param.type == null && !isJustUnderscores(param.identifier.name)) {
      rule.reportLint(param);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (!isPrivate(node.name) &&
        !node.isConst &&
        !(node.isFinal && hasInferredType(node))) {
      rule.reportLint(node.name);
    }
  }
}
