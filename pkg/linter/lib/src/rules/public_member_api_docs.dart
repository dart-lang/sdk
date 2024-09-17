// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'Document all public members.';

const _details = r'''
**DO** document all public members.

All non-overriding public members should be documented with `///` doc-style
comments.

**BAD:**
```dart
class Bad {
  void meh() { }
}
```

**GOOD:**
```dart
/// A good thing.
abstract class Good {
  /// Start doing your thing.
  void start() => _start();

  _start();
}
```

In case a public member overrides a member it is up to the declaring member
to provide documentation.  For example, in the following, `Sub` needn't
document `init` (though it certainly may, if there's need).

**GOOD:**
```dart
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

Note that consistent with `dart doc`, an exception to the rule is made when
documented getters have corresponding undocumented setters.  In this case the
setters inherit the docs from the getters.

''';

// TODO(devoncarew): Longer term, this lint could benefit from being more aware
// of the actual API surface area of a package - including that defined by
// exports - and linting against that.

class PublicMemberApiDocs extends LintRule {
  PublicMemberApiDocs()
      : super(
          name: 'public_member_api_docs',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.public_member_api_docs;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var package = context.package;
    if (package != null && !package.canHavePublicApi) {
      return;
    }
    if (!context.isInLibDir) return;

    var visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
    registry.addCompilationUnit(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
    registry.addEnumConstantDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addGenericTypeAlias(this, visitor);
    registry.addMixinDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  bool check(Declaration node) {
    if (node.documentationComment == null && !isOverridingMember(node)) {
      var errorNode = getNodeToAnnotate(node);
      rule.reportLintForOffset(errorNode.offset, errorNode.length);
      return true;
    }
    return false;
  }

  void checkMethods(List<ClassMember> members) {
    // Check methods

    var getters = <String, MethodDeclaration>{};
    var setters = <MethodDeclaration>[];

    // Non-getters/setters.
    var methods = <MethodDeclaration>[];

    // Identify getter/setter pairs.
    for (var member in members) {
      if (member is MethodDeclaration && !member.name.isPrivate) {
        if (member.isGetter) {
          getters[member.name.lexeme] = member;
        } else if (member.isSetter) {
          setters.add(member);
        } else {
          methods.add(member);
        }
      }
    }

    // Check all getters, and collect offenders along the way.
    var missingDocs = <MethodDeclaration>{};
    for (var getter in getters.values) {
      if (check(getter)) {
        missingDocs.add(getter);
      }
    }

    // But only setters whose getter is missing a doc.
    for (var setter in setters) {
      var getter = getters[setter.name.lexeme];
      if (getter != null && missingDocs.contains(getter)) {
        check(setter);
      }
    }

    // Check remaining methods.
    methods.forEach(check);
  }

  /// Whether [node] overrides some other member.
  bool isOverridingMember(Declaration node) =>
      context.inheritanceManager.overriddenMember(node.declaredElement) != null;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var element = node.declaredElement;
    if (element == null || element.hasInternal) return;
    _visitMembers(node, node.name, node.members);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    if (!node.name.isPrivate) {
      check(node);
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var getters = <String, FunctionDeclaration>{};
    var setters = <FunctionDeclaration>[];

    // Check functions.

    // Non-getters/setters.
    var functions = <FunctionDeclaration>[];

    // Identify getter/setter pairs.
    for (var member in node.declarations) {
      if (member is FunctionDeclaration) {
        var name = member.name;
        if (!name.isPrivate && name.lexeme != 'main') {
          if (member.isGetter) {
            getters[member.name.lexeme] = member;
          } else if (member.isSetter) {
            setters.add(member);
          } else {
            functions.add(member);
          }
        }
      }
    }

    // Check all getters, and collect offenders along the way.
    var missingDocs = <FunctionDeclaration>{};
    for (var getter in getters.values) {
      if (check(getter)) {
        missingDocs.add(getter);
      }
    }

    // But only setters whose getter is missing a doc.
    for (var setter in setters) {
      var getter = getters[setter.name.lexeme];
      if (getter != null && missingDocs.contains(getter)) {
        check(setter);
      }
    }

    // Check remaining functions.
    for (var function in functions) {
      if (!function.isEffectivelyPrivate) {
        check(function);
      }
    }

    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.inPrivateMember || node.name.isPrivate) return;
    var parent = node.parent;
    if (parent is EnumDeclaration) return;
    if (parent != null && parent.isEffectivelyPrivate) return;

    check(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    // TODO(pq): update this to be called from the parent (like with visitMembers)
    if (node.isInternal) return;

    if (!node.inPrivateMember && !node.name.isPrivate) {
      check(node);
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (node.name.isPrivate) return;
    if (node.isInternal) return;

    check(node);
    checkMethods(node.members);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    if (node.name == null || node.name.isPrivate) return;
    if (node.isInternal) return;

    check(node);
    checkMethods(node.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    var element = node.declaredElement;
    if (element == null || element.hasInternal) return;
    _visitMembers(node, node.name, node.members);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // TODO(pq): update this to be called from the parent (like with visitMembers)
    if (node.isInternal) return;
    if (node.inPrivateMember) return;
    if (node.isInvalidExtensionTypeField) return;

    for (var field in node.fields.variables) {
      if (!field.name.isPrivate) {
        check(field);
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!node.name.isPrivate) {
      check(node);
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (!node.name.isPrivate) {
      check(node);
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (node.isInternal) return;
    _visitMembers(node, node.name, node.members);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var variable in node.variables.variables) {
      if (!variable.name.isPrivate) {
        check(variable);
      }
    }
  }

  void _visitMembers(Declaration node, Token name, List<ClassMember> members) {
    if (name.isPrivate) return;

    check(node);
    checkMethods(members);
  }
}
