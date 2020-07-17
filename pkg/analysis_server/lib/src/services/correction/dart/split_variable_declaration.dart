// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SplitVariableDeclaration extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.SPLIT_VARIABLE_DECLARATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var variableList = node?.thisOrAncestorOfType<VariableDeclarationList>();

    // Must be a local variable declaration.
    if (variableList?.parent is! VariableDeclarationStatement) {
      return;
    }
    VariableDeclarationStatement statement = variableList.parent;

    // Cannot be `const` or `final`.
    var keywordKind = variableList.keyword?.keyword;
    if (keywordKind == Keyword.CONST || keywordKind == Keyword.FINAL) {
      return;
    }

    var variables = variableList.variables;
    if (variables.length != 1) {
      return;
    }

    // The caret must be between the type and the variable name.
    var variable = variables[0];
    if (!range.startEnd(statement, variable.name).contains(selectionOffset)) {
      return;
    }

    // The variable must have an initializer.
    if (variable.initializer == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      if (variableList.type == null) {
        final type = variable.declaredElement.type;
        if (!type.isDynamic) {
          builder.addReplacement(range.token(variableList.keyword), (builder) {
            builder.writeType(type);
          });
        }
      }

      var indent = utils.getNodePrefix(statement);
      var name = variable.name.name;
      builder.addSimpleInsertion(variable.name.end, ';' + eol + indent + name);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static SplitVariableDeclaration newInstance() => SplitVariableDeclaration();
}
