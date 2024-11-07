// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MoveTypeArgumentsToClass extends ResolvedCorrectionProducer {
  MoveTypeArgumentsToClass({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.MOVE_TYPE_ARGUMENTS_TO_CLASS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var typeArguments = coveringNode;
    if (typeArguments is! TypeArgumentList) {
      return;
    }

    var creation = typeArguments.parent;
    if (creation is! InstanceCreationExpression) {
      return;
    }

    var namedType = creation.constructorName.type;
    if (namedType.typeArguments != null) {
      return;
    }

    var type = namedType.typeOrThrow;
    if (type is InterfaceType) {
      var element = type.element3;
      if (element.typeParameters2.length == typeArguments.arguments.length) {
        await builder.addDartFileEdit(file, (builder) {
          var argumentText = utils.getNodeText(typeArguments);
          builder.addSimpleInsertion(namedType.end, argumentText);
          builder.addDeletion(range.node(typeArguments));
        });
      }
    }
  }
}
