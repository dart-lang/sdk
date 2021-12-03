// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToListLiteral extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_LIST_LITERAL;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_LIST_LITERAL;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_LIST_LITERAL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Ensure that this is the default constructor defined on `List`.
    //
    var creation = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null) {
      return;
    }

    var type = creation.staticType;
    if (node.offset > creation.argumentList.offset ||
        type is! InterfaceType ||
        type.element != typeProvider.listElement ||
        creation.constructorName.name != null ||
        creation.argumentList.arguments.isNotEmpty) {
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    var constructorTypeArguments = creation.constructorName.type2.typeArguments;
    //
    // Build the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(creation), (builder) {
        if (constructorTypeArguments != null) {
          builder.write(utils.getNodeText(constructorTypeArguments));
        }
        builder.write('[]');
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToListLiteral newInstance() => ConvertToListLiteral();
}
