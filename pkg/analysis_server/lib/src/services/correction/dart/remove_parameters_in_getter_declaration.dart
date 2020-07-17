// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveParametersInGetterDeclaration extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is MethodDeclaration) {
      // Support for the analyzer error.
      var method = node as MethodDeclaration;
      var name = method.name;
      var body = method.body;
      if (name != null && body != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.endStart(name, body), ' ');
        });
      }
    } else if (node is FormalParameterList) {
      // Support for the fasta error.
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.node(node));
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveParametersInGetterDeclaration newInstance() =>
      RemoveParametersInGetterDeclaration();
}
