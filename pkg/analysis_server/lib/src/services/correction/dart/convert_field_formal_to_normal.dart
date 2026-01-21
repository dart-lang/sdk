// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertFieldFormalToNormal extends ResolvedCorrectionProducer {
  ConvertFieldFormalToNormal({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // This isn't offered as a fix.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.convertFieldFormalToNormal;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameter = node;
    if (parameter is! FieldFormalParameter || parameter.parameters != null) {
      return;
    }
    var field = parameter.declaredFragment?.element.field;
    if (field == null) {
      return;
    }
    var constructor = parameter
        .thisOrAncestorOfType<FormalParameterList>()
        ?.parent;
    if (constructor is! ConstructorDeclaration) {
      return;
    }
    var initializers = constructor.initializers;
    await builder.addDartFileEdit(file, (builder) {
      var thisRange = range.startEnd(parameter.thisKeyword, parameter.period);

      var parameterName = parameter.name.lexeme;
      var fieldName = parameterName;

      // If the parameter is a private named parameter, then it should get the
      // corresponding public name while the field keeps the private name.
      if (parameter.isNamed) {
        if (correspondingPublicName(parameterName) case var publicName?) {
          builder.addSimpleReplacement(range.token(parameter.name), publicName);
          parameterName = publicName;
        }
      }

      var type = parameter.type;
      if (type == null) {
        // The type of the field needs to be added to the declaration.
        builder.addReplacement(thisRange, (builder) {
          builder.writeType(field.type);
          builder.write(' ');
        });
      } else {
        builder.addDeletion(thisRange);
      }

      int offset;
      String prefix;
      if (initializers.isEmpty) {
        offset = constructor.parameters.end;
        prefix = ' :';
      } else {
        offset = initializers.last.end;
        prefix = ',';
      }

      builder.addSimpleInsertion(offset, '$prefix $fieldName = $parameterName');
    });
  }
}
