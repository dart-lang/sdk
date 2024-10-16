// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddFieldFormalParameters extends ResolvedCorrectionProducer {
  AddFieldFormalParameters({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

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

    var superType = classNode.declaredFragment!.element.supertype;
    if (superType == null) {
      return;
    }

    // Compute uninitialized final fields.
    var fields = ErrorVerifier.computeNotInitializedFields2(constructor);
    fields.retainWhere((FieldElement2 field) => field.isFinal);
    fields.sort(
        (a, b) => a.firstFragment!.nameOffset! - b.firstFragment!.nameOffset!);

    // Specialize for Flutter widgets.
    if (superType.isExactlyStatelessWidgetType ||
        superType.isExactlyStatefulWidgetType) {
      if (parameters.isNotEmpty && parameters.last.isNamed) {
        String parameterForField(FieldElement2 field) {
          var prefix = '';
          if (typeSystem.isPotentiallyNonNullable(field.type)) {
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
}
