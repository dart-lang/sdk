// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/ascii_utils.dart';
import '../utils.dart';

const _desc = r'Name non-constant identifiers using lowerCamelCase.';

class NonConstantIdentifierNames extends LintRule {
  NonConstantIdentifierNames()
      : super(
          name: LintNames.non_constant_identifier_names,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.non_constant_identifier_names;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
    registry.addDeclaredVariablePattern(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
    registry.addForEachPartsWithDeclaration(this, visitor);
    registry.addFormalParameterList(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addPatternField(this, visitor);
    registry.addRecordLiteral(this, visitor);
    registry.addRecordTypeAnnotation(this, visitor);
    registry.addVariableDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkIdentifier(Token? id, {bool underscoresOk = false}) {
    if (id == null) {
      return;
    }
    var name = id.lexeme;
    if (underscoresOk && name.isJustUnderscores) {
      // For example, `___` is OK in a callback.
      return;
    }
    if (!isLowerCamelCase(name)) {
      rule.reportLintForToken(id, arguments: [name]);
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    checkIdentifier(node.exceptionParameter?.name, underscoresOk: true);
    checkIdentifier(node.stackTraceParameter?.name, underscoresOk: true);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.isAugmentation) return;
    // For rationale on accepting underscores, see:
    // https://github.com/dart-lang/linter/issues/1854
    checkIdentifier(node.name, underscoresOk: true);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.parent.isFieldNameShortcut) return;
    checkIdentifier(node.name);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    checkIdentifier(node.representation.constructorName?.name);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    checkIdentifier(node.loopVariable.name);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    var inAugmentation = node.parent?.isAugmentation ?? false;
    for (var p in node.parameters) {
      if (inAugmentation && p.isNamed) continue;
      if (p is! FieldFormalParameter) {
        checkIdentifier(p.name, underscoresOk: true);
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.isAugmentation) return;

    checkIdentifier(node.name);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isOperator && !node.isAugmentation) {
      checkIdentifier(node.name);
    }
  }

  @override
  void visitPatternField(PatternField node) {
    if (node.isFieldNameShortcut) return;
    var pattern = node.pattern;
    if (pattern is DeclaredVariablePattern) {
      checkIdentifier(pattern.name);
    }
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    for (var fieldExpression in node.fields) {
      if (fieldExpression is NamedExpression) {
        checkIdentifier(fieldExpression.name.label.token);
      }
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    var positionalFields = node.positionalFields;
    for (var field in positionalFields) {
      checkIdentifier(field.name);
    }

    var namedFields = node.namedFields;
    if (namedFields == null) return;
    for (var field in namedFields.fields) {
      checkIdentifier(field.name);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.isAugmentation) return;

    if (!node.isConst) {
      checkIdentifier(node.name);
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    for (var variable in node.variables.variables) {
      if (!variable.isConst) {
        checkIdentifier(variable.name);
      }
    }
  }
}
