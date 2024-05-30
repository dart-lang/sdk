// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class ImportAddShow extends ResolvedCorrectionProducer {
  ImportAddShow({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.IMPORT_ADD_SHOW;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare ImportDirective
    var importDirective = node.thisOrAncestorOfType<ImportDirective>();
    if (importDirective == null) {
      return;
    }
    // there should be no existing combinators
    if (importDirective.combinators.isNotEmpty) {
      return;
    }
    // prepare whole import namespace
    var importElement = importDirective.element;
    if (importElement == null) {
      return;
    }
    var namespace = getImportNamespace(importElement);
    // prepare names of referenced elements (from this import)
    var visitor = _ReferenceFinder(namespace);
    unit.accept(visitor);
    var referencedNames = visitor.referencedNames;
    // ignore if unused
    if (referencedNames.isEmpty) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      var showCombinator = ' show ${referencedNames.join(', ')}';
      builder.addSimpleInsertion(importDirective.end - 1, showCombinator);
    });
  }
}

class _ReferenceFinder extends RecursiveAstVisitor<void> {
  final Map<String, Element> namespace;

  Set<String> referencedNames = SplayTreeSet<String>();

  _ReferenceFinder(this.namespace);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _addImplicitExtensionName(node.readElement?.enclosingElement);
    _addImplicitExtensionName(node.writeElement?.enclosingElement);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _addImplicitExtensionName(node.staticElement?.enclosingElement);
    super.visitBinaryExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _addImplicitExtensionName(node.staticElement?.enclosingElement);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _addImplicitExtensionName(node.staticElement?.enclosingElement);
    super.visitIndexExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _addImplicitExtensionName(node.methodName.staticElement?.enclosingElement);
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _addName(node.name2, node.element);
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _addImplicitExtensionName(node.element?.enclosingElement);
    super.visitPatternField(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _addImplicitExtensionName(node.staticElement?.enclosingElement);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _addImplicitExtensionName(node.staticElement?.enclosingElement);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _addImplicitExtensionName(
        node.propertyName.staticElement?.enclosingElement);
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    _addName(node.token, element);
  }

  void _addImplicitExtensionName(Element? enclosingElement) {
    if (enclosingElement is ExtensionElement) {
      if (namespace[enclosingElement.name] == enclosingElement) {
        referencedNames.add(enclosingElement.displayName);
      }
    }
  }

  void _addName(Token nameToken, Element? element) {
    if (element != null) {
      var name = nameToken.lexeme;
      if (namespace[name] == element ||
          (name != element.name && namespace[element.name] == element)) {
        referencedNames.add(element.displayName);
      }
    }
  }
}
