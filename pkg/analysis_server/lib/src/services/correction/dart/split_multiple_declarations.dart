// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SplitMultipleDeclarations extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.SPLIT_MULTIPLE_DECLARATIONS;

  @override
  FixKind get multiFixKind => DartFixKind.SPLIT_MULTIPLE_DECLARATIONS_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaredVariable = node;
    if (declaredVariable is! VariableDeclaration) {
      return;
    }

    var variableList = node.parent;
    if (variableList is! VariableDeclarationList) {
      return;
    }

    // We don't support comments.
    if (variableList.beginToken.precedingComments != null) {
      return;
    }

    var declaration = variableList.parent;
    if (declaration == null) {
      return;
    }

    // We don't support metadata.
    switch (declaration) {
      case FieldDeclaration(:var metadata):
      case TopLevelVariableDeclaration(:var metadata):
        if (metadata.isNotEmpty) {
          return;
        }
    }

    var variables = variableList.variables;
    if (variables.length < 2) {
      return;
    }

    var modifiersTypeLast = variables.first.name.previous;
    if (modifiersTypeLast == null) {
      return;
    }

    var modifiersType = utils.getRangeText(
      range.startEnd(declaration, modifiersTypeLast),
    );

    var spacesBefore = utils.getLinePrefix(declaration.offset);

    await builder.addDartFileEdit(file, (builder) {
      var endOfLine = utils.endOfLine;
      var previous = variables[0];
      for (var i = 1; i < variables.length; i++) {
        var current = variables[i];
        var sourceRange = range.endStart(previous, current);
        var replacement = ';$endOfLine$spacesBefore$modifiersType ';
        builder.addSimpleReplacement(sourceRange, replacement);
        previous = current;
      }
    });
  }
}
