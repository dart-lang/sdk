// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertIntoForIndex extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_FOR_INDEX;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // find enclosing ForEachStatement
    var forStatement = node.thisOrAncestorOfType<ForStatement>();
    if (forStatement is! ForStatement) {
      return;
    }

    var forEachParts = forStatement.forLoopParts;
    if (forEachParts is! ForEachParts) {
      return;
    }

    if (selectionOffset < forStatement.offset ||
        forStatement.rightParenthesis.end < selectionOffset) {
      return;
    }
    // loop should declare variable
    var loopVariable = forEachParts is ForEachPartsWithDeclaration
        ? forEachParts.loopVariable
        : null;
    if (loopVariable == null) {
      return;
    }
    // iterable should be VariableElement
    String listName;
    var iterable = forEachParts.iterable;
    if (iterable is SimpleIdentifier &&
        iterable.staticElement is VariableElement) {
      listName = iterable.name;
    } else {
      return;
    }
    // iterable should be List
    {
      var iterableType = iterable.staticType;
      if (iterableType is! InterfaceType ||
          iterableType.element != typeProvider.listElement) {
        return;
      }
    }
    // body should be Block
    var body = forStatement.body;
    if (body is! Block) {
      return;
    }
    // prepare a name for the index variable
    String indexName;
    {
      var conflicts =
          utils.findPossibleLocalVariableConflicts(forStatement.offset);
      if (!conflicts.contains('i')) {
        indexName = 'i';
      } else if (!conflicts.contains('j')) {
        indexName = 'j';
      } else if (!conflicts.contains('k')) {
        indexName = 'k';
      } else {
        return;
      }
    }
    // prepare environment
    var prefix = utils.getNodePrefix(forStatement);
    var indent = utils.getIndent(1);
    var firstBlockLine = utils.getLineContentEnd(body.leftBracket.end);
    // add change
    await builder.addDartFileEdit(file, (builder) {
      // TODO(brianwilkerson) Create linked positions for the loop variable.
      builder.addSimpleReplacement(
          range.startEnd(forStatement, forStatement.rightParenthesis),
          'for (int $indexName = 0; $indexName < $listName.length; $indexName++)');
      builder.addSimpleInsertion(firstBlockLine,
          '$prefix$indent$loopVariable = $listName[$indexName];$eol');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertIntoForIndex newInstance() => ConvertIntoForIndex();
}
