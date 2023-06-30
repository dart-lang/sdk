// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddLate extends ResolvedCorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_LATE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!libraryElement.isNonNullableByDefault) {
      return;
    }
    final node = this.node;
    if (node is VariableDeclaration) {
      var variableList = node.parent;
      if (variableList is VariableDeclarationList) {
        if (!variableList.isLate) {
          if (variableList.type == null) {
            var keyword = variableList.keyword;
            if (keyword == null) {
              await _insertAt(builder, variableList.variables[0].offset);
              // TODO(brianwilkerson) Consider converting this into an assist and
              //  expand it to support converting `var` to `late` as well as
              //  working anywhere a non-late local variable or field is selected.
//          } else if (keyword.type == Keyword.VAR) {
//            builder.addFileEdit(file, (builder) {
//              builder.addSimpleReplacement(range.token(keyword), 'late');
//            });
            } else if (keyword.type != Keyword.CONST) {
              await _insertAt(builder, variableList.variables[0].offset);
            }
          } else {
            var keyword = variableList.keyword;
            if (keyword != null) {
              await _insertAt(builder, keyword.offset);
            } else {
              var type = variableList.type;
              if (type != null) {
                await _insertAt(builder, type.offset);
              }
            }
          }
        }
      }
    } else if (node is SimpleIdentifier) {
      var getter = node.writeOrReadElement;
      if (getter is PropertyAccessorElement &&
          getter.isGetter &&
          getter.isSynthetic &&
          !getter.variable.isSynthetic &&
          getter.variable.setter == null &&
          getter.enclosingElement2 is InterfaceElement) {
        var declarationResult =
            await sessionHelper.getElementDeclaration(getter.variable);
        if (declarationResult == null) {
          return;
        }
        var variable = declarationResult.node;
        var variableList = variable.parent;
        if (variable is VariableDeclaration &&
            variableList is VariableDeclarationList &&
            variableList.parent is FieldDeclaration) {
          var keywordToken = variableList.keyword;
          if (variableList.variables.length == 1 &&
              keywordToken != null &&
              keywordToken.keyword == Keyword.FINAL) {
            await _insertAt(builder, keywordToken.offset,
                source: declarationResult.element.source);
          }
        }
      }
    }
  }

  Future<void> _insertAt(ChangeBuilder builder, int offset,
      {Source? source}) async {
    await builder.addDartFileEdit(source?.fullName ?? file, (builder) {
      builder.addSimpleInsertion(offset, 'late ');
    });
  }
}
