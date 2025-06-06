// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertIntoGetter extends ResolvedCorrectionProducer {
  String _memberName = '';
  final _Type _type;

  ConvertIntoGetter({required super.context}) : _type = _Type.base;
  ConvertIntoGetter.implicitThis({required super.context})
    : _type = _Type.implicitThis;

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): not necessarily the right thing to do.
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
    if (_type == _Type.implicitThis) {
      fieldDeclaration = node.thisOrAncestorOfType();
    } else {
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
    var code = 'get';
    code += ' ${field.name.lexeme}';
    code += ' => ';

    var startingKeyword =
        fieldList.lateKeyword ??
        fieldList.keyword ??
        fieldList.type ??
        field.name;

    var writeType = getCodeStyleOptions(unitResult.file).specifyReturnTypes;
    var replacementRange = range.startEnd(startingKeyword, fieldDeclaration);
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(replacementRange, (builder) {
        if (fieldList.type?.type case var type) {
          if (type == null || type is DynamicType) {
            type = initializer?.staticType;
          }
          if (type is InvalidType) {
            type = typeProvider.dynamicType;
          }
          if ((type != null && type is! DynamicType) || writeType) {
            builder.writeType(
              type,
              shouldWriteDynamic: writeType,
              required: writeType,
            );
            builder.write(' ');
          }
        }
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

enum _Type { base, implicitThis }
