// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ReplaceWithFilled extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_FILLED;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var typeName = node is SimpleIdentifier ? node.parent : node;
    var creation = typeName?.parent?.parent;
    if (typeName is TypeName && creation is InstanceCreationExpression) {
      var elementType = (typeName.type as InterfaceType).typeArguments[0];
      if (typeSystem.isNullable(elementType)) {
        var argumentList = creation.argumentList;
        if (argumentList.arguments.length == 1) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleInsertion(argumentList.offset, '.filled');
            builder.addSimpleInsertion(
                argumentList.arguments[0].end, ', null, growable: false');
          });
        }
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithFilled newInstance() => ReplaceWithFilled();
}
