// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeFinal extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.MAKE_FINAL;

  @override
  FixKind get multiFixKind => DartFixKind.MAKE_FINAL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    var parent = node.parent;
    var grandParent = parent?.parent;

    if (node is SimpleIdentifier &&
        parent is DeclaredIdentifier &&
        grandParent is ForEachPartsWithDeclaration) {
      await builder.addDartFileEdit(file, (builder) {
        var keyword = parent.keyword;
        if (keyword != null && keyword.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), 'final');
        } else if (keyword == null) {
          builder.addSimpleInsertion(parent.offset, 'final ');
        }
      });
      return;
    }

    final AstNode normalParameter;
    if (node is DefaultFormalParameter) {
      normalParameter = node.parameter;
    } else {
      normalParameter = node;
    }

    if (normalParameter is SimpleFormalParameter) {
      final simpleNode = normalParameter;
      await builder.addDartFileEdit(file, (builder) {
        final keyword = simpleNode.keyword;
        if (keyword != null && keyword.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), 'final');
        } else {
          final type = simpleNode.type;
          if (type != null) {
            builder.addSimpleInsertion(type.offset, 'final ');
            return;
          }
          final identifier = simpleNode.identifier;
          if (identifier != null) {
            builder.addSimpleInsertion(identifier.offset, 'final ');
          } else {
            builder.addSimpleInsertion(simpleNode.offset, 'final ');
          }
        }
      });
      return;
    }

    if (node is SimpleIdentifier && parent is SimpleFormalParameter) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(node.offset, 'final ');
      });
      return;
    }

    VariableDeclarationList list;
    if (node is SimpleIdentifier &&
        parent is VariableDeclaration &&
        grandParent is VariableDeclarationList) {
      list = grandParent;
    } else if (node is VariableDeclaration &&
        parent is VariableDeclarationList) {
      list = parent;
    } else {
      return;
    }

    if (list.variables.length == 1) {
      await builder.addDartFileEdit(file, (builder) {
        var keyword = list.keyword;
        var lateKeyword = list.lateKeyword;
        if (keyword != null && keyword.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), 'final');
        } else if (lateKeyword != null) {
          builder.addSimpleInsertion(lateKeyword.end, ' final');
        } else if (keyword == null) {
          builder.addSimpleInsertion(list.offset, 'final ');
        }
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeFinal newInstance() => MakeFinal();
}
