// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/utils.dart';

const desc = r'Type annotate public APIs.';

const details = r'''
From [effective dart](https://www.dartlang.org/effective-dart/design/#do-type-annotate-public-apis):

**DO** type annotate public APIs.

Type annotations are important documentation for how a library should be used.
Annotating the parameter and return types of public methods and functions helps
users understand what the API expects and what it provides.

Note that if a public API accepts a range of values that Dart's type system
cannot express, then it is acceptable to leave that untyped. In that case, the
implicit `dynamic` is the correct type for the API.

For code internal to a library (either private, or things like nested functions)
annotate where you feel it helps, but don't feel that you *must* provide them.

**BAD:**
```
install(id, destination) {
  // ...
}
```

Here, it's unclear what `id` is. A string? And what is `destination`? A string
or a `File` object? Is this method synchronous or asynchronous?


**GOOD:**

```
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
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  _VisitorHelper v;
  final LintRule rule;
  Visitor(this.rule) {
    v = new _VisitorHelper(rule);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    if (node.fields.type == null) {
      node.fields.accept(v);
    }
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (!isPrivate(node.name)) {
      if (node.returnType == null && !node.isSetter) {
        rule.reportLint(node.name);
      } else {
        node.functionExpression.parameters?.accept(v);
      }
    }
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!isPrivate(node.name)) {
      if (node.returnType == null) {
        rule.reportLint(node.name);
      } else {
        node.parameters.accept(v);
      }
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (!isPrivate(node.name)) {
      if (node.returnType == null && !node.isSetter) {
        rule.reportLint(node.name);
      } else {
        node.parameters?.accept(v);
      }
    }
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.variables.type == null) {
      node.variables.accept(v);
    }
  }
}

class _VisitorHelper extends RecursiveAstVisitor {
  final LintRule rule;
  _VisitorHelper(this.rule);

  @override
  visitSimpleFormalParameter(SimpleFormalParameter param) {
    if (param.type == null && !isJustUnderscores(param.identifier.name)) {
      rule.reportLint(param);
    }
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (!isPrivate(node.name)) {
      rule.reportLint(node.name);
    }
  }
}
