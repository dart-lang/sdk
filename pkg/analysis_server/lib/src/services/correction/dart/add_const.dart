// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddConst extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_CONST;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_CONST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? targetNode = node;
    if (targetNode is SimpleIdentifier) {
      targetNode = targetNode.parent;
    }
    if (targetNode is ConstructorDeclaration) {
      var node_final = targetNode;
      await builder.addDartFileEdit(file, (builder) {
        final offset = node_final.firstTokenAfterCommentAndMetadata.offset;
        builder.addSimpleInsertion(offset, 'const ');
      });
      return;
    }
    if (targetNode is TypeName) {
      targetNode = targetNode.parent;
    }
    if (targetNode is ConstructorName) {
      targetNode = targetNode.parent;
    }
    if (targetNode is InstanceCreationExpression) {
      if (targetNode.keyword == null) {
        var node_final = targetNode;
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(node_final.offset, 'const ');
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddConst newInstance() => AddConst();
}
