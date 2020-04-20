// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToListLiteral extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_LIST_LITERAL;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_LIST_LITERAL;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    //
    // Ensure that this is the default constructor defined on `List`.
    //
    var creation = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null ||
        node.offset > creation.argumentList.offset ||
        creation.staticType.element != typeProvider.listElement ||
        creation.constructorName.name != null ||
        creation.argumentList.arguments.isNotEmpty) {
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    var constructorTypeArguments = creation.constructorName.type.typeArguments;
    //
    // Build the edit.
    //
    await builder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(creation), (DartEditBuilder builder) {
        if (constructorTypeArguments != null) {
          builder.write(utils.getNodeText(constructorTypeArguments));
        }
        builder.write('[]');
      });
    });
  }
}
