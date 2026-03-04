// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';
import '../util/ascii_utils.dart';

const _desc = r'Type annotate public APIs.';

class TypeAnnotatePublicApis extends AnalysisRule {
  TypeAnnotatePublicApis()
    : super(name: LintNames.type_annotate_public_apis, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.typeAnnotatePublicApis;

  @override
  List<String> get incompatibleRules => const ['omit_obvious_property_types'];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final _VisitorHelper v;

  _Visitor(this.rule) : v = _VisitorHelper(rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.isAugmentation) return;

    if (node.declaredFragment?.element case var element?) {
      if (_isPublicConstructor(element)) {
        node.parameters.accept(v);
      }
    }
  }

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
        rule.reportAtToken(node.name);
      } else {
        node.functionExpression.parameters?.accept(v);
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!node.name.isPrivate) {
      if (node.returnType == null) {
        rule.reportAtToken(node.name);
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
        rule.reportAtToken(node.name);
      } else {
        node.parameters?.accept(v);
      }
    }
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    if (node.isAugmentation) return;
    if (node.declaredFragment?.element case var element?) {
      if (_isPublicConstructor(element)) {
        node.formalParameters.accept(v);
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

  bool _isPublicConstructor(ConstructorElement constructor) {
    var enclosingElement = constructor.enclosingElement;
    if (enclosingElement is EnumElement) return false;
    if (enclosingElement.isPrivate) return false;
    return !constructor.isPrivate;
  }
}

class _VisitorHelper extends RecursiveAstVisitor<void> {
  final AnalysisRule rule;

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
        rule.reportAtNode(param);
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (!node.name.isPrivate &&
        !node.isConst &&
        !(node.isFinal && hasInferredType(node))) {
      rule.reportAtToken(node.name);
    }
  }
}
