// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class InsertOnKeyword extends ResolvedCorrectionProducer {
  InsertOnKeyword({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // Supports single instance and in file corrections
          CorrectionApplicability
          .acrossSingleFile;

  @override
  FixKind get fixKind => DartFixKind.INSERT_ON_KEYWORD;

  @override
  FixKind get multiFixKind => DartFixKind.INSERT_ON_KEYWORD_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! ExtensionDeclaration) {
      if (node.parent case ExtensionDeclaration parent) {
        node = parent;
      } else {
        return;
      }
    }

    var onClause = node.onClause;
    if (onClause != null && onClause.onKeyword.isSynthetic) {
      var onOffset = onClause.onKeyword.offset;
      if (onClause.extendedType.length == 0) {
        onOffset = node.name?.offset ?? onOffset;
      }

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(onOffset, 'on ');
      });
    }
  }
}
