// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveOnClause extends ResolvedCorrectionProducer {
  RemoveOnClause({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_ON_CLAUSE;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_ON_CLAUSE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var extensionDeclaration =
        node.thisOrAncestorOfType<ExtensionDeclaration>();
    if (extensionDeclaration == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(
          extensionDeclaration.onClause!, extensionDeclaration.leftBracket));
    });
  }
}
