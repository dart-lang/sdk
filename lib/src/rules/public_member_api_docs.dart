// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Document all public members.';

const _details = r'''

**DO** document all public members.

All non-overriding public members should be documented with `///` doc-style
comments.

**GOOD:**
```
/// A good thing.
abstract class Good {
  /// Start doing your thing.
  void start() => _start();

  _start();
}
```

**BAD:**
```
class Bad {
  void meh() { }
}
```

In case a public member overrides a member it is up to the declaring member
to provide documentation.  For example, in the following, `Sub` needn't
document `init` (though it certainly may, if there's need).

**GOOD:**
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

Note that consistent with `dartdoc`, an exception to the rule is made when
documented getters have corresponding undocumented setters.  In this case the
setters inherit the docs from the getters.

''';

// TODO(devoncarew): This lint is very slow - we should profile and optimize it.

// TODO(devoncarew): Longer term, this lint could benefit from being more aware
// of the actual API surface area of a package - including that defined by
// exports - and linting against that.

class PublicMemberApiDocs extends LintRule implements NodeLintRule {
  PublicMemberApiDocs()
      : super(
            name: 'public_member_api_docs',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
    registry.addCompilationUnit(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
    registry.addEnumConstantDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionDeclaration(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    // todo (pq): add mixins
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final LinterContext context;

  bool isInLibFolder;

  _Visitor(this.rule, this.context);

  bool check(Declaration node) {
    if (node.documentationComment == null && !isOverridingMember(node)) {
      rule.reportLint(getNodeToAnnotate(node));
      return true;
    }
    return false;
  }

  Element getOverriddenMember(Element member) {
    if (member == null) {
      return null;
    }

    final classElement = member.thisOrAncestorOfType<ClassElement>();
    if (classElement == null) {
      return null;
    }
    final libraryUri = classElement.library.source.uri;
    return context.inheritanceManager.getInherited(
      classElement.thisType,
      Name(libraryUri, member.name),
    );
  }

  bool isOverridingMember(Declaration node) =>
      getOverriddenMember(node.declaredElement) != null;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!isInLibFolder) return;

    if (isPrivate(node.name)) return;

    check(node);

    // Check methods

    final getters = <String, MethodDeclaration>{};
    final setters = <MethodDeclaration>[];

    // Non-getters/setters.
    final methods = <MethodDeclaration>[];

    // Identify getter/setter pairs.
    for (var member in node.members) {
      if (member is MethodDeclaration && !isPrivate(member.name)) {
        if (member.isGetter) {
          getters[member.name.name] = member;
        } else if (member.isSetter) {
          setters.add(member);
        } else {
          methods.add(member);
        }
      }
    }

    // Check all getters, and collect offenders along the way.
    final missingDocs = <MethodDeclaration>{};
    for (var getter in getters.values) {
      if (check(getter)) {
        missingDocs.add(getter);
      }
    }

    // But only setters whose getter is missing a doc.
    for (var setter in setters) {
      final getter = getters[setter.name.name];
      if (getter == null) {
        final libraryUri = node.declaredElement.library.source.uri;
        // Look for an inherited getter.
        Element getter = context.inheritanceManager.getMember(
          node.declaredElement.thisType,
          Name(libraryUri, setter.name.name),
        );
        if (getter is PropertyAccessorElement) {
          if (getter.documentationComment != null) {
            continue;
          }
        }
        check(setter);
      } else if (missingDocs.contains(getter)) {
        check(setter);
      }
    }

    // Check remaining methods.
    methods.forEach(check);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    if (!isInLibFolder) return;

    if (!isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // Ignore this compilation unit if it's not in the lib/ folder.
    isInLibFolder = isInLibDir(node, context.package);
    if (!isInLibFolder) return;

    final getters = <String, FunctionDeclaration>{};
    final setters = <FunctionDeclaration>[];

    // Check functions.

    // Non-getters/setters.
    final functions = <FunctionDeclaration>[];

    // Identify getter/setter pairs.
    for (var member in node.declarations) {
      if (member is FunctionDeclaration) {
        var name = member.name;
        if (!isPrivate(name) && name.name != 'main') {
          if (member.isGetter) {
            getters[member.name.name] = member;
          } else if (member.isSetter) {
            setters.add(member);
          } else {
            functions.add(member);
          }
        }
      }
    }

    // Check all getters, and collect offenders along the way.
    final missingDocs = <FunctionDeclaration>{};
    for (var getter in getters.values) {
      if (check(getter)) {
        missingDocs.add(getter);
      }
    }

    // But only setters whose getter is missing a doc.
    for (var setter in setters) {
      final getter = getters[setter.name.name];
      if (getter != null && missingDocs.contains(getter)) {
        check(setter);
      }
    }

    // Check remaining functions.
    functions.forEach(check);

    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!isInLibFolder) return;

    if (!inPrivateMember(node) && !isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (!isInLibFolder) return;

    if (!inPrivateMember(node) && !isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (!isInLibFolder) return;

    if (!isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    if (!isInLibFolder) return;

    if (node.name == null || isPrivate(node.name)) {
      return;
    }

    check(node);

    // Check methods

    final getters = <String, MethodDeclaration>{};
    final setters = <MethodDeclaration>[];

    // Non-getters/setters.
    final methods = <MethodDeclaration>[];

    // Identify getter/setter pairs.
    for (var member in node.members) {
      if (member is MethodDeclaration && !isPrivate(member.name)) {
        if (member.isGetter) {
          getters[member.name.name] = member;
        } else if (member.isSetter) {
          setters.add(member);
        } else {
          methods.add(member);
        }
      }
    }

    // Check all getters, and collect offenders along the way.
    final missingDocs = <MethodDeclaration>{};
    for (var getter in getters.values) {
      if (check(getter)) {
        missingDocs.add(getter);
      }
    }

    // But only setters whose getter is missing a doc.
    for (var setter in setters) {
      final getter = getters[setter.name.name];
      if (getter != null && missingDocs.contains(getter)) {
        check(setter);
      }
    }

    // Check remaining methods.
    methods.forEach(check);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!isInLibFolder) return;

    if (!inPrivateMember(node)) {
      for (var field in node.fields.variables) {
        if (!isPrivate(field.name)) {
          check(field);
        }
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!isInLibFolder) return;

    if (!isPrivate(node.name)) {
      check(node);
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (!isInLibFolder) return;

    for (var decl in node.variables.variables) {
      if (!isPrivate(decl.name)) {
        check(decl);
      }
    }
  }
}
