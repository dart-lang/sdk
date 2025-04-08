// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertIntoGetter extends ResolvedCorrectionProducer {
  String _memberName = '';

  ConvertIntoGetter({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String>? get assistArguments => [_memberName];

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_GETTER;

  @override
  List<String>? get fixArguments => assistArguments;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_INTO_GETTER;

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
    // The field must have only one variable.
    var fieldList = fieldDeclaration.fields;
    if (fieldList.variables.length != 1) {
      return;
    }
    var field = fieldList.variables.first;
    _memberName = field.name.lexeme;
    if (_memberName.isEmpty) {
      return;
    }
    // Prepare the initializer.
    var initializer = field.initializer;
    // Add proposal.
    var code = '';
    var typeAnnotation = fieldList.type;
    if (typeAnnotation != null) {
      code += '${utils.getNodeText(typeAnnotation)} ';
    }
    code += 'get';
    code += ' ${field.name.lexeme}';
    code += ' => ';

    var startingKeyword =
        fieldList.lateKeyword ??
        fieldList.keyword ??
        fieldList.type ??
        field.name;

    var replacementRange = range.startEnd(startingKeyword, fieldDeclaration);
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(replacementRange, (builder) {
        builder.write(code);
        if (initializer == null) {
          builder.addSimpleLinkedEdit('initializer', 'null');
          builder.write(';');
        } else {
          builder.write('${utils.getNodeText(initializer)};');
        }
      });
    });
  }
}
