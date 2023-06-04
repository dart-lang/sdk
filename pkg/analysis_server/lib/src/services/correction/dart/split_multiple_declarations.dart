// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SplitMultipleDeclarations extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.SPLIT_MULTIPLE_DECLARATIONS;

  @override
  FixKind get multiFixKind => DartFixKind.SPLIT_MULTIPLE_DECLARATIONS_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final variableList = node.thisOrAncestorOfType<VariableDeclarationList>();
    if (variableList == null) {
      return;
    }

    final hasComments = variableList.beginToken.precedingComments != null;
    final hasMetadata = variableList.metadata.isNotEmpty;

    final parent = variableList.parent;
    final hasParentMetadata =
        (parent is TopLevelVariableDeclaration) && parent.metadata.isNotEmpty;

    // we don't offer a fix if there are metadatas or comments
    if (hasComments || hasMetadata || hasParentMetadata) {
      return;
    }

    final variables = variableList.variables;
    if (variables.length <= 1) {
      return;
    }

    final entities = variableList.childEntities
        .where((e) => e is KeywordToken || e is NamedType);
    final entitiesRange = range.startEnd(entities.first, entities.last);
    final keywordsAndType = utils.getRangeText(entitiesRange);

    final spacesBefore = utils.getLinePrefix(variableList.offset);

    await builder.addDartFileEdit(file, (builder) {
      final endOfLine = utils.endOfLine;
      for (var i = 1; i < variables.length; i++) {
        final variable = variables[i];
        final prev = variables[i - 1];

        final sourceRange =
            range.startStart(prev.endToken.next!, variable.beginToken);

        final replacement = ';$endOfLine$spacesBefore$keywordsAndType ';

        builder.addSimpleReplacement(sourceRange, replacement);
      }
    });
  }
}
