// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToNormalParameter extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_NORMAL_PARAMETER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameter = node;
    if (parameter is! FieldFormalParameter) return;

    var parameterList = parameter.parent;
    if (parameterList is! FormalParameterList) return;

    var constructor = parameterList.parent;
    if (constructor is! ConstructorDeclaration) return;

    var parameterElement = parameter.declaredElement!;
    var name = parameter.name.lexeme;
    var type = parameterElement.type;

    await builder.addDartFileEdit(file, (builder) {
      // replace parameter
      if (type is DynamicType) {
        builder.addSimpleReplacement(range.node(parameter), name);
      } else {
        builder.addReplacement(range.node(parameter), (builder) {
          builder.writeType(type);
          builder.write(' ');
          builder.write(name);
        });
      }
      // add field initializer
      List<ConstructorInitializer> initializers = constructor.initializers;
      if (initializers.isEmpty) {
        builder.addSimpleInsertion(parameterList.end, ' : $name = $name');
      } else {
        builder.addSimpleInsertion(initializers.last.end, ', $name = $name');
      }
    });
  }
}
