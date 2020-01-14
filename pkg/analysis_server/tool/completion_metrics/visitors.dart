// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class CompletionMetricVisitor extends RecursiveAstVisitor {
  // TODO(jwren) implement missing visit* methods

  final List<SyntacticEntity> entities;

  CompletionMetricVisitor() : entities = <SyntacticEntity>[];

  safelyRecordEntity(SyntacticEntity entity) {
    if (entity != null && entity.offset > 0 && entity.length > 0) {
      entities.add(entity);
    }
  }

  @override
  visitDoStatement(DoStatement node) {
    safelyRecordEntity(node.doKeyword);
    return super.visitDoStatement(node);
  }

  @override
  visitIfStatement(IfStatement node) {
    safelyRecordEntity(node.ifKeyword);
    return super.visitIfStatement(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    safelyRecordEntity(node.keyword);
    safelyRecordEntity(node.asKeyword);
    return super.visitImportDirective(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      safelyRecordEntity(node);
    }
    return super.visitSimpleIdentifier(node);
  }
}
