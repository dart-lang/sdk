// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = r'Document all public members.';

// TODO(devoncarew): Longer term, this lint could benefit from being more aware
// of the actual API surface area of a package - including that defined by
// exports - and linting against that.

class PublicMemberApiDocs extends AnalysisRule {
  PublicMemberApiDocs()
    : super(name: LintNames.public_member_api_docs, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.publicMemberApiDocs;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
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

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  bool check(Declaration node) {
    if (node.isInternal) return false;

    if (node.documentationComment == null && !isOverridingMember(node)) {
      var errorNode = getNodeToAnnotate(node);
      rule.reportAtSourceRange(errorNode.sourceRange);
      return true;
    }
    return false;
  }

  void checkMethods(List<ClassMember> members) {
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
      node.declaredFragment?.element.overriddenMember != null;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.declaredFragment?.element == null) return;
    if (node.body case BlockClassBody body) {
      _visitMembers(node, node.namePart.typeName, body.members);
    }
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
    functions.forEach(check);

    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.inPrivateMember || node.name.isPrivate) return;
    var parent = node.parent?.parent;
    if (parent is EnumDeclaration) return;
    if (parent != null && parent.isEffectivelyPrivate) return;

    check(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (!node.inPrivateMember && !node.name.isPrivate) {
      check(node);
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (node.namePart.typeName.isPrivate) return;

    check(node);
    checkMethods(node.body.members);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    if (node.name == null || node.name.isPrivate) return;
    if (node.isInternal) return;

    check(node);
    checkMethods(node.body.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.declaredFragment?.element == null) return;
    if (node.body case BlockClassBody body) {
      _visitMembers(node, node.primaryConstructor.typeName, body.members);
    }
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
    _visitMembers(node, node.name, node.body.members);
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
    if (node.isInternal) return;

    check(node);
    checkMethods(members);
  }
}
