// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const desc = r'Document all public members.';

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

Note that consistent with `dartdoc`, an exception to the rule is made when
documented getters have corresponding undocumented setters. In this case the
setters inherit the docs from the getters.
''';

// TODO(devoncarew): This lint is very slow - we should profile and optimize it.

class PublicMemberApiDocs extends LintRule {
  PublicMemberApiDocs()
      : super(
            name: 'public_member_api_docs',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new _Visitor(this);
}

class _Visitor extends GeneralizingAstVisitor {
  InheritanceManager manager;

  final LintRule rule;

  _Visitor(this.rule);

  bool check(Declaration node) {
    if (node.documentationComment == null && !isOverridingMember(node)) {
      rule.reportLint(getNodeToAnnotate(node));
      return true;
    }
    return false;
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

  /// Return true if the given node is declared in a compilation unit that is in
  /// a `lib/` folder.
  bool isDefinedInLib(AstNode node) {
    CompilationUnit compilationUnit = node is CompilationUnit
        ? node
        : node.getAncestor((node) => node is CompilationUnit);
    Uri uri = compilationUnit?.element?.source?.uri;

    // TODO(devoncarew): This will have false positives.
    return uri != null && uri.pathSegments.contains('lib');
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (isPrivate(node.name) || !isDefinedInLib(node)) {
      return;
    }

    check(node);

    // Check methods

    Map<String, MethodDeclaration> getters = <String, MethodDeclaration>{};
    Map<String, MethodDeclaration> setters = <String, MethodDeclaration>{};

    // Non-getters/setters.
    List<MethodDeclaration> methods = <MethodDeclaration>[];

    // Identify getter/setter pairs.
    for (ClassMember member in node.members) {
      if (member is MethodDeclaration && !isPrivate(member.name)) {
        if (member.isGetter) {
          getters[member.name.name] = member;
        } else if (member.isSetter) {
          setters[member.name.name] = member;
        } else {
          methods.add(member);
        }
      }
    }

    // Check all getters, and collect offenders along the way.
    List<MethodDeclaration> missingDocs = <MethodDeclaration>[];
    for (MethodDeclaration getter in getters.values) {
      if (check(getter)) {
        missingDocs.add(getter);
      }
    }

    // But only setters whose getter is missing a doc.
    for (MethodDeclaration setter in setters.values) {
      MethodDeclaration getter = getters[setter.name.name];
      if (getter == null) {
        // Look for an inherited getter.
        ExecutableElement getter =
            manager.lookupMember(node.element, setter.name.name);
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
  visitClassTypeAlias(ClassTypeAlias node) {
    if (!isPrivate(node.name) && isDefinedInLib(node)) {
      check(node);
    }
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    // Ignore this compilation unit if its not in the lib/ folder.
    if (!isDefinedInLib(node)) return;

    LibraryElement library = node == null
        ? null
        : resolutionMap.elementDeclaredByCompilationUnit(node)?.library;
    manager = library == null ? null : new InheritanceManager(library);

    Map<String, FunctionDeclaration> getters = <String, FunctionDeclaration>{};
    Map<String, FunctionDeclaration> setters = <String, FunctionDeclaration>{};

    // Check functions.

    // Non-getters/setters.
    List<FunctionDeclaration> functions = <FunctionDeclaration>[];

    // Identify getter/setter pairs.
    for (CompilationUnitMember member in node.declarations) {
      if (member is FunctionDeclaration) {
        Identifier name = member.name;
        if (!isPrivate(name) && name.name != 'main') {
          if (member.isGetter) {
            getters[member.name.name] = member;
          } else if (member.isSetter) {
            setters[member.name.name] = member;
          } else {
            functions.add(member);
          }
        }
      }
    }

    // Check all getters, and collect offenders along the way.
    List<FunctionDeclaration> missingDocs = <FunctionDeclaration>[];
    for (FunctionDeclaration getter in getters.values) {
      if (check(getter)) {
        missingDocs.add(getter);
      }
    }

    // But only setters whose getter is missing a doc.
    for (FunctionDeclaration setter in setters.values) {
      FunctionDeclaration getter = getters[setter.name.name];
      if (getter != null && missingDocs.contains(getter)) {
        check(setter);
      }
    }

    // Check remaining functions.
    functions.forEach(check);

    super.visitCompilationUnit(node);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!inPrivateMember(node) &&
        !isPrivate(node.name) &&
        isDefinedInLib(node)) {
      check(node);
    }
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (!inPrivateMember(node) &&
        !isPrivate(node.name) &&
        isDefinedInLib(node)) {
      check(node);
    }
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    if (!isPrivate(node.name) && isDefinedInLib(node)) {
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
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!isPrivate(node.name) && isDefinedInLib(node)) {
      check(node);
    }
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (isDefinedInLib(node)) {
      for (VariableDeclaration decl in node.variables.variables) {
        if (!isPrivate(decl.name)) {
          check(decl);
        }
      }
    }
  }
}
