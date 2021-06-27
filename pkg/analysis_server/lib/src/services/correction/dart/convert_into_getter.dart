// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertIntoGetter extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_GETTER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find the enclosing field declaration.
    FieldDeclaration? fieldDeclaration;
    for (var n in node.withParents) {
      if (n is FieldDeclaration) {
        fieldDeclaration = n;
        break;
      }
      if (n is SimpleIdentifier ||
          n is VariableDeclaration ||
          n is VariableDeclarationList ||
          n is TypeAnnotation ||
          n is TypeArgumentList) {
        continue;
      }
      break;
    }
    if (fieldDeclaration == null) {
      return;
    }
    // The field must be final and has only one variable.
    var fieldList = fieldDeclaration.fields;
    var finalKeyword = fieldList.keyword;
    if (finalKeyword == null || fieldList.variables.length != 1) {
      return;
    }
    var field = fieldList.variables.first;
    // Prepare the initializer.
    var initializer = field.initializer;
    if (initializer == null) {
      return;
    }
    // Add proposal.
    var code = '';
    var typeAnnotation = fieldList.type;
    if (typeAnnotation != null) {
      code += utils.getNodeText(typeAnnotation) + ' ';
    }
    code += 'get';
    code += ' ' + utils.getNodeText(field.name);
    code += ' => ' + utils.getNodeText(initializer);
    code += ';';
    var replacementRange = range.startEnd(finalKeyword, fieldDeclaration);
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(replacementRange, code);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertIntoGetter newInstance() => ConvertIntoGetter();
}
