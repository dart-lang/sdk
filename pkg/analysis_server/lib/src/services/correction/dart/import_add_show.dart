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
  AssistKind get assistKind => DartAssistKind.importAddShow;

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
    var importElement = importDirective.libraryImport;
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
    _addImplicitExtensionName(node.readElement2?.enclosingElement);
    _addImplicitExtensionName(node.writeElement2?.enclosingElement);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _addImplicitExtensionName(node.element?.enclosingElement);
    super.visitBinaryExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _addImplicitExtensionName(node.element?.enclosingElement);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _addImplicitExtensionName(node.element?.enclosingElement);
    super.visitIndexExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _addImplicitExtensionName(node.methodName.element?.enclosingElement);
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _addName(node.name, node.element2);
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _addImplicitExtensionName(node.element2?.enclosingElement);
    super.visitPatternField(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _addImplicitExtensionName(node.element?.enclosingElement);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _addImplicitExtensionName(node.element?.enclosingElement);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _addImplicitExtensionName(node.propertyName.element?.enclosingElement);
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.writeOrReadElement2;
    _addName(node.token, element);
  }

  void _addImplicitExtensionName(Element? enclosingElement) {
    if (enclosingElement is ExtensionElement) {
      if (namespace[enclosingElement.name3] == enclosingElement) {
        referencedNames.add(enclosingElement.displayName);
      }
    }
  }

  void _addName(Token nameToken, Element? element) {
    if (element != null) {
      var name = nameToken.lexeme;
      if (namespace[name] == element || namespace['$name='] == element) {
        referencedNames.add(element.displayName);
      }
    }
  }
}
