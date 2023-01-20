// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveQuestionMark extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_QUESTION_MARK;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_QUESTION_MARK_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? targetNode = node;
    if (targetNode is VariableDeclaration) {
      var parent = targetNode.parent;
      if (parent is VariableDeclarationList) {
        targetNode = parent.type;
      } else {
        return;
      }
    }
    if (targetNode is NamedType) {
      var questionMark = targetNode.question;
      if (questionMark == null) {
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.token(questionMark));
      });
    }
    if (targetNode is NullCheckPattern) {
      var questionMark = targetNode.operator;
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.token(questionMark));
      });
    }
  }
}
