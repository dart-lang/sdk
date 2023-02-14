// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveSetLiteral extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_SET_LITERAL;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_SET_LITERAL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SetOrMapLiteral) return;
    var leftToken = node.leftBracket;
    var rightBracket = node.rightBracket;
    var rightStart = rightBracket.offset;
    var rightEnd = rightBracket.next!.offset;

    var elements = node.elements;
    if (elements.isEmpty) return;
    var first = elements.first;

    var parent = node.parent?.parent?.parent;
    if (parent is FunctionDeclaration) {
      var nextToElement = first.endToken.next!;
      if (nextToElement.type == TokenType.COMMA) {
        rightStart = first.end;
      }
    } else {
      var nextToElement = first.endToken.next!;
      var nextToBracket = rightBracket.next!;
      if (nextToElement.type == TokenType.COMMA) {
        rightStart = nextToElement.end;
        rightEnd = nextToBracket.offset;
        if (nextToBracket.type == TokenType.COMMA) {
          rightEnd = nextToBracket.next!.offset;
        }
      } else if (nextToBracket.type == TokenType.COMMA) {
        rightStart = first.end;
        rightEnd = nextToBracket.offset;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(leftToken, leftToken.next!));
      builder.addDeletion(range.startOffsetEndOffset(rightStart, rightEnd));
    });
  }
}
