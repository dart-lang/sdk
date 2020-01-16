// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/completion/dart/keyword_contributor.dart';
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
    // Only record if this entity is not null, has a length, etc.
    if (entity != null && entity.offset > 0 && entity.length > 0) {
      // Some special cases in the if and if-else blocks, 'import' from the
      // DAS is "import '';" which we want to be sure to match.
      if (entity.toString() == 'async') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, ASYNC_STAR, kind, elementKind));
      } else if (entity.toString() == 'default') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, DEFAULT_COLON, kind, elementKind));
      } else if (entity.toString() == 'deferred') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, DEFERRED_AS, kind, elementKind));
      } else if (entity.toString() == 'export') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, EXPORT_STATEMENT, kind, elementKind));
      } else if (entity.toString() == 'import') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, IMPORT_STATEMENT, kind, elementKind));
      } else if (entity.toString() == 'part') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, PART_STATEMENT, kind, elementKind));
      } else if (entity.toString() == 'sync') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, SYNC_STAR, kind, elementKind));
      } else if (entity.toString() == 'yield') {
        expectedCompletions.add(ExpectedCompletion.specialCompletionString(
            entity, YIELD_STAR, kind, elementKind));
      } else {
        expectedCompletions.add(ExpectedCompletion(entity, kind, elementKind));
      }
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

  /// Some completions are special cased from the DAS "import" for instance is
  /// suggested as a completion "import '';", the completion string here in this
  /// instance would have the value "import '';".
  final String _completionString;

  final protocol.CompletionSuggestionKind _kind;

  final protocol.ElementKind _elementKind;

  ExpectedCompletion(this._entity, this._kind, this._elementKind)
      : _completionString = null;

  ExpectedCompletion.specialCompletionString(
      this._entity, this._completionString, this._kind, this._elementKind);

  SyntacticEntity get syntacticEntity => _entity;

  String get completion => _completionString ?? _entity.toString();

  int get offset => _entity.offset;

  protocol.CompletionSuggestionKind get kind => _kind;

  protocol.ElementKind get elementKind => _elementKind;

  bool matches(protocol.CompletionSuggestion completionSuggestion) {
    if (completionSuggestion.completion == completion) {
      if (kind != null && completionSuggestion.kind != kind) {
        return false;
      }
      if (elementKind != null &&
          completionSuggestion.element?.kind != elementKind) {
        return false;
      }
      return true;
    }
    return false;
  }
}
