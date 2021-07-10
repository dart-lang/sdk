// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddConst extends CorrectionProducer {
  @override
  bool canBeAppliedInBulk;

  @override
  bool canBeAppliedToFile;

  AddConst(this.canBeAppliedInBulk, this.canBeAppliedToFile);

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

    Future<void> insertAtOffset(Expression targetNode) async {
      var finder = _ConstRangeFinder();
      targetNode.accept(finder);
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(targetNode.offset, 'const ');
        for (var range in finder.ranges) {
          builder.addDeletion(range);
        }
      });
    }

    if (targetNode is ListLiteral) {
      await insertAtOffset(targetNode);
      return;
    }
    if (targetNode is SetOrMapLiteral) {
      await insertAtOffset(targetNode);
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
        await insertAtOffset(targetNode);
        return;
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddConst toDeclaration() => AddConst(true, true);

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  // TODO(brianwilkerson) This fix can produce changes that are inconsistent
  //  with the `unnecessary_const` lint. Fix it and then enable it for both
  //  uses.
  static AddConst toInvocation() => AddConst(false, false);

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddConst toLiteral() => AddConst(true, true);
}

class _ConstRangeFinder extends RecursiveAstVisitor<void> {
  final List<SourceRange> ranges = [];

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Stop visiting when we get to a closure.
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _removeKeyword(node.keyword);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _removeKeyword(node.constKeyword);
    super.visitListLiteral(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _removeKeyword(node.constKeyword);
    super.visitSetOrMapLiteral(node);
  }

  void _removeKeyword(Token? keyword) {
    if (keyword != null && keyword.type == Keyword.CONST) {
      ranges.add(range.startStart(keyword, keyword.next!));
    }
  }
}
