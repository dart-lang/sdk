// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.public_member_api_docs;

import 'package:analyzer/src/generated/ast.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/linter.dart';

const desc = r'Document all public memmbers';

const details = r'''
**DO** document all public members.

All public members should be documented with `///` doc-style comments.

**Good:**
```
/// A good thing.
abstract class Good {
  /// Start doing your thing.
  void start() => _start();

  _start();
}
```

**Bad:**
```
class Bad {
  void meh();
}
```
''';

class PublicMemberApiDocs extends LintRule {
  PublicMemberApiDocs()
      : super(
            name: 'public_member_api_docs',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends GeneralizingAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  void check(Declaration node) {
    if (node.documentationComment == null && !hasOverrideAnnotation(node)) {
      rule.reportLint(getNodeToAnnotate(node));
    }
  }

  bool hasOverrideAnnotation(Declaration node) =>
      node.metadata.map((Annotation a) => a.name.name).contains('override');

  bool inPrivateMember(AstNode node) {
    AstNode parent = node.parent;
    if (parent is NamedCompilationUnitMember) {
      return isPrivate(parent.name);
    }
    return false;
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (!isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    if (!isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!inPrivateMember(node) && !isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (!inPrivateMember(node) && !isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    if (!isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    if (!inPrivateMember(node)) {
      for (VariableDeclaration field in node.fields.variables) {
        if (!isPrivate(field.name)) {
          check(field);
        }
      }
    }
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! CompilationUnit) {
      return; // Skip inner functions.
    }
    if (!isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (!inPrivateMember(node) && !isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (VariableDeclaration decl in node.variables.variables) {
      if (!isPrivate(decl.name)) {
        check(decl);
      }
    }
  }
}
