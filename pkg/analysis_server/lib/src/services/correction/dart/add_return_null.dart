// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddReturnNull extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.ADD_RETURN_NULL;

  @override
  FixKind? get multiFixKind => DartFixKind.ADD_RETURN_NULL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Block block;

    var node = this.node;
    if (node is Block) {
      block = node;
    } else if (node is FunctionDeclaration) {
      var body = node.functionExpression.body;
      if (body is BlockFunctionBody) {
        block = body.block;
      } else {
        return;
      }
    } else if (node is MethodDeclaration) {
      var body = node.body;
      if (body is BlockFunctionBody) {
        block = body.block;
      } else {
        return;
      }
    } else {
      return;
    }
    int position;
    String returnStatement;
    if (block.statements.isEmpty) {
      position = block.offset + 1;
      var prefix = utils.getLinePrefix(block.offset);
      returnStatement = '$eol$prefix${utils.oneIndent}return null;$eol$prefix';
    } else {
      var lastStatement = block.statements.last;
      position = lastStatement.offset + lastStatement.length;
      var prefix = utils.getNodePrefix(lastStatement);
      returnStatement = '$eol${prefix}return null;';
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(position, (builder) {
        builder.write(returnStatement);
      });
    });
  }
}
