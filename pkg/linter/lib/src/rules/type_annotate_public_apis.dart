// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/ascii_utils.dart';

const _desc = r'Type annotate public APIs.';

class TypeAnnotatePublicApis extends LintRule {
  TypeAnnotatePublicApis()
      : super(
          name: LintNames.type_annotate_public_apis,
          description: _desc,
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

class _VisitorHelper extends RecursiveAstVisitor<void> {
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
