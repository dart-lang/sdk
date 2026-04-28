// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveTypeName extends ResolvedCorrectionProducer {
  RemoveTypeName({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeTypeName;

  @override
  FixKind? get multiFixKind => DartFixKind.removeTypeNameMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveringNode;
    if (node is! SimpleIdentifier) return;
    node = node.parent;
    if (node is ConstructorDeclaration) {
      var typeName = node.typeName;
      if (typeName == null) return;
      var name = node.name;
      var replacementRange = name == null
          ? range.node(typeName)
          : (name.lexeme == 'new'
                ? range.startEnd(typeName, name)
                : range.startStart(typeName, name));
      var replacement = '';
      if (node.newKeyword == null && node.factoryKeyword == null) {
        replacement = 'new ';
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(replacementRange, replacement);
      });
    }
  }
}
