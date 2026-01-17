// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToNormalParameter extends ResolvedCorrectionProducer {
  ConvertToNormalParameter({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.convertToNormalParameter;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameter = node;
    if (parameter is! FieldFormalParameter) return;

    var parameterList = parameter.parent;
    if (parameterList is! FormalParameterList) return;

    var constructor = parameterList.parent;
    if (constructor is! ConstructorDeclaration) return;

    var fragment = parameter.declaredFragment!;
    var parameterElement = fragment.element;
    var field = parameterElement.field;
    var type = parameterElement.type;

    var declaredName = parameter.name.lexeme;
    var parameterName = declaredName;
    var fieldName = field?.name ?? declaredName;

    if (parameter.isNamed &&
        isEnabled(Feature.private_named_parameters) &&
        fragment.privateName != null) {
      parameterName = parameterElement.name;
    }

    await builder.addDartFileEdit(file, (builder) {
      if (type is DynamicType) {
        builder.addSimpleReplacement(range.node(parameter), parameterName);
      } else {
        builder.addReplacement(range.node(parameter), (builder) {
          builder.writeType(type);
          builder.write(' ');
          builder.write(parameterName);
        });
      }

      List<ConstructorInitializer> initializers = constructor.initializers;
      if (initializers.isEmpty) {
        builder.addSimpleInsertion(
          parameterList.end,
          ' : $fieldName = $parameterName',
        );
      } else {
        builder.addSimpleInsertion(
          initializers.last.end,
          ', $fieldName = $parameterName',
        );
      }
    });
  }
}
