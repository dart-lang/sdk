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
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SimpleIdentifier) {
      node = node.parent;
    }
    if (node is ConstructorDeclaration) {
      await builder.addDartFileEdit(file, (builder) {
        final offset = (node as ConstructorDeclaration)
            .firstTokenAfterCommentAndMetadata
            .offset;
        builder.addSimpleInsertion(offset, 'const ');
      });
      return;
    }
    if (node is TypeName) {
      node = node.parent;
    }
    if (node is ConstructorName) {
      node = node.parent;
    }
    if (node is InstanceCreationExpression) {
      if ((node as InstanceCreationExpression).keyword == null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(node.offset, 'const ');
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddConst newInstance() => AddConst();
}
