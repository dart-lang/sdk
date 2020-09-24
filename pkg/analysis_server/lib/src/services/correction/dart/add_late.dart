// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddLate extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_LATE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!libraryElement.isNonNullableByDefault) {
      return;
    }
    if (node is SimpleIdentifier &&
        node.parent is VariableDeclaration &&
        node.parent.parent is VariableDeclarationList) {
      var list = node.parent.parent as VariableDeclarationList;
      if (!list.isLate) {
        if (list.type == null) {
          var keyword = list.keyword;
          if (keyword == null) {
            await _insertAt(builder, list.variables[0].offset);
            // TODO(brianwilkerson) Consider converting this into an assist and
            //  expand it to support converting `var` to `late` as well as
            //  working anywhere a non-late local variable or field is selected.
//          } else if (keyword.type == Keyword.VAR) {
//            builder.addFileEdit(file, (builder) {
//              builder.addSimpleReplacement(range.token(keyword), 'late');
//            });
          } else if (keyword.type != Keyword.CONST) {
            await _insertAt(builder, list.variables[0].offset);
          }
        } else {
          await _insertAt(builder, list.type.offset);
        }
      }
    }
  }

  Future<void> _insertAt(ChangeBuilder builder, int offset) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(offset, 'late ');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddLate newInstance() => AddLate();
}
