// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class CompletionMetricVisitor extends RecursiveAstVisitor {
  // TODO(jwren) implement missing visit* methods

  final List<ExpectedCompletion> expectedCompletions;

  CompletionMetricVisitor() : expectedCompletions = <ExpectedCompletion>[];

  safelyRecordKeywordCompletion(SyntacticEntity entity) {
    safelyRecordEntity(entity, kind: protocol.CompletionSuggestionKind.KEYWORD);
  }

  safelyRecordEntity(SyntacticEntity entity,
      {protocol.CompletionSuggestionKind kind,
      protocol.ElementKind elementKind}) {
    if (entity != null && entity.offset > 0 && entity.length > 0) {
      expectedCompletions.add(ExpectedCompletion(entity, kind, elementKind));
    }
  }

  @override
  visitDoStatement(DoStatement node) {
    safelyRecordKeywordCompletion(node.doKeyword);
    return super.visitDoStatement(node);
  }

  @override
  visitIfStatement(IfStatement node) {
    safelyRecordKeywordCompletion(node.ifKeyword);
    return super.visitIfStatement(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    safelyRecordKeywordCompletion(node.keyword);
    safelyRecordKeywordCompletion(node.asKeyword);
    return super.visitImportDirective(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.isSynthetic && !node.inDeclarationContext()) {
      var elementKind;
      if (node.staticElement?.kind != null) {
        elementKind = protocol.convertElementKind(node.staticElement?.kind);
      }
      safelyRecordEntity(node, elementKind: elementKind);
    }
    return super.visitSimpleIdentifier(node);
  }
}

class ExpectedCompletion {
  final SyntacticEntity _entity;
  final protocol.CompletionSuggestionKind _kind;
  final protocol.ElementKind _elementKind;

  ExpectedCompletion(this._entity, this._kind, this._elementKind);

  SyntacticEntity get syntacticEntity => _entity;

  String get completion => _entity.toString();

  int get offset => _entity.offset;

  protocol.CompletionSuggestionKind get kind => _kind;

  protocol.ElementKind get elementKind => _elementKind;
}
