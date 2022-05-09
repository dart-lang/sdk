// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddFieldFormalParameters extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_FIELD_FORMAL_PARAMETERS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructor = node.parent;
    if (node is! SimpleIdentifier || constructor is! ConstructorDeclaration) {
      return;
    }
    List<FormalParameter> parameters = constructor.parameters.parameters;

    var classNode = constructor.parent;
    if (classNode is! ClassDeclaration) {
      return;
    }

    var superType = classNode.declaredElement!.supertype;
    if (superType == null) {
      return;
    }

    // Compute uninitialized final fields.
    var fields = ErrorVerifier.computeNotInitializedFields(constructor);
    fields.retainWhere((FieldElement field) => field.isFinal);
    fields.sort((a, b) => a.nameOffset - b.nameOffset);

    // Specialize for Flutter widgets.
    if (flutter.isExactlyStatelessWidgetType(superType) ||
        flutter.isExactlyStatefulWidgetType(superType)) {
      if (parameters.isNotEmpty && parameters.last.isNamed) {
        var isNullSafe =
            libraryElement.featureSet.isEnabled(Feature.non_nullable);
        String parameterForField(FieldElement field) {
          var prefix = '';
          if (isNullSafe && typeSystem.isPotentiallyNonNullable(field.type)) {
            prefix = 'required ';
          }
          return '${prefix}this.${field.name}';
        }

        var fieldParametersCode = fields.map(parameterForField).join(', ');
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(
            parameters.last.end,
            ', $fieldParametersCode',
          );
        });
        return;
      }
    }

    // Prepare the last required parameter.
    FormalParameter? lastRequiredParameter;
    for (var parameter in parameters) {
      if (parameter.isRequiredPositional) {
        lastRequiredParameter = parameter;
      }
    }

    var fieldParametersCode =
        fields.map((field) => 'this.${field.name}').join(', ');
    await builder.addDartFileEdit(file, (builder) {
      if (lastRequiredParameter != null) {
        builder.addSimpleInsertion(
          lastRequiredParameter.end,
          ', $fieldParametersCode',
        );
      } else {
        var offset = constructor.parameters.leftParenthesis.end;
        if (parameters.isNotEmpty) {
          fieldParametersCode += ', ';
        }
        builder.addSimpleInsertion(offset, fieldParametersCode);
      }
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddFieldFormalParameters newInstance() => AddFieldFormalParameters();
}
