// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.public_member_api_docs;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/linter.dart';

const desc = r'Document all public members';

const details = r'''
**DO** document all public members.

All non-overriding public members should be documented with `///` doc-style
comments.

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
  void meh() { }
}
```

In case a public member overrides a member it is up to the declaring member
to provide documentation.  For example, in the following, `Sub` needn't
document `init` (though it certainly may, if there's need).

**Good:**
```
/// Base of all things.
abstract class Base {
  /// Initialize the base.
  void init();
}

/// A sub base.
class Sub extends Base {
  @override
  void init() { ... }
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
  InheritanceManager manager;

  final LintRule rule;
  Visitor(this.rule);

  void check(Declaration node) {
    if (node.documentationComment == null && !isOverridingMember(node)) {
      rule.reportLint(getNodeToAnnotate(node));
    }
  }

  ExecutableElement getOverriddenMember(Element member) {
    if (member == null || manager == null) {
      return null;
    }

    ClassElement classElement =
        member.getAncestor((element) => element is ClassElement);
    if (classElement == null) {
      return null;
    }
    return manager.lookupInheritance(classElement, member.name);
  }

  bool isOverridingMember(Declaration node) =>
      getOverriddenMember(node.element) != null;

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
  visitCompilationUnit(CompilationUnit node) {
    LibraryElement library = node?.element?.library;
    manager = library == null ? null : new InheritanceManager(library);
    super.visitCompilationUnit(node);
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
