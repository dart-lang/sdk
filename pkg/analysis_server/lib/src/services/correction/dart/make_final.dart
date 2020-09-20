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
  FixKind get fixKind => DartFixKind.MAKE_FINAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SimpleIdentifier &&
        node.parent is DeclaredIdentifier &&
        node.parent.parent is ForEachPartsWithDeclaration) {
      var declaration = node.parent as DeclaredIdentifier;
      await builder.addDartFileEdit(file, (builder) {
        if (declaration.keyword?.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(
              range.token(declaration.keyword), 'final');
        } else if (declaration.keyword == null) {
          builder.addSimpleInsertion(declaration.offset, 'final ');
        }
      });
      return;
    }
    VariableDeclarationList list;
    if (node is SimpleIdentifier &&
        node.parent is VariableDeclaration &&
        node.parent.parent is VariableDeclarationList) {
      list = node.parent.parent;
    } else if (node is VariableDeclaration &&
        node.parent is VariableDeclarationList) {
      list = node.parent;
    }
    if (list != null) {
      if (list.variables.length == 1) {
        await builder.addDartFileEdit(file, (builder) {
          if (list.keyword?.keyword == Keyword.VAR) {
            builder.addSimpleReplacement(range.token(list.keyword), 'final');
          } else if (list.lateKeyword != null) {
            builder.addSimpleInsertion(list.lateKeyword.end, ' final');
          } else if (list.keyword == null) {
            builder.addSimpleInsertion(list.offset, 'final ');
          }
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeFinal newInstance() => MakeFinal();
}
