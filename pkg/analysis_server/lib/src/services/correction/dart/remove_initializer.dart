// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveInitializer extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_INITIALIZER;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_INITIALIZER_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameter = node.thisOrAncestorOfType<DefaultFormalParameter>();
    if (parameter != null) {
      // Handle formal parameters with default values.
      var identifier = parameter.identifier;
      var defaultValue = parameter.defaultValue;
      if (identifier != null && defaultValue != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(
            range.endEnd(identifier, defaultValue),
          );
        });
      }
    } else {
      // Handle variable declarations with default values.
      var variable = node.thisOrAncestorOfType<VariableDeclaration>();
      var initializer = variable?.initializer;
      if (variable != null && initializer != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(
            range.endEnd(variable.name, initializer),
          );
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveInitializer newInstance() => RemoveInitializer();
}
