// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MoveTypeArgumentsToClass extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.MOVE_TYPE_ARGUMENTS_TO_CLASS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (coveredNode is TypeArgumentList) {
      TypeArgumentList typeArguments = coveredNode;
      if (typeArguments.parent is! InstanceCreationExpression) {
        return;
      }
      InstanceCreationExpression creation = typeArguments.parent;
      var typeName = creation.constructorName.type;
      if (typeName.typeArguments != null) {
        return;
      }
      var element = typeName.type.element;
      if (element is ClassElement &&
          element.typeParameters != null &&
          element.typeParameters.length == typeArguments.arguments.length) {
        await builder.addDartFileEdit(file, (builder) {
          var argumentText = utils.getNodeText(typeArguments);
          builder.addSimpleInsertion(typeName.end, argumentText);
          builder.addDeletion(range.node(typeArguments));
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MoveTypeArgumentsToClass newInstance() => MoveTypeArgumentsToClass();
}
