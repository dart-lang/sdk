// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddLate extends ResolvedCorrectionProducer {
  AddLate({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.ADD_LATE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is VariableDeclaration) {
      var variableList = node.parent;
      if (variableList is VariableDeclarationList) {
        if (!variableList.isLate) {
          if (variableList.type == null) {
            var keyword = variableList.keyword;
            if (keyword == null) {
              await _insertAt(builder, variableList.variables[0].offset);
              // TODO(brianwilkerson): Consider converting this into an assist and
              //  expand it to support converting `var` to `late` as well as
              //  working anywhere a non-late local variableElement or field is selected.
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
      var getter = node.writeOrReadElement2;
      if (getter is GetterElement &&
          getter.isSynthetic &&
          getter.enclosingElement2 is InterfaceElement2) {
        var variableElement = getter.variable3;
        if (variableElement != null &&
            !variableElement.isSynthetic &&
            !variableElement.isLate &&
            variableElement.setter2 == null) {
          var variableFragment = variableElement.firstFragment;
          var declarationResult = await sessionHelper.getElementDeclaration2(
            variableFragment,
          );
          if (declarationResult == null) {
            return;
          }
          var variableNode = declarationResult.node;
          var variableList = variableNode.parent;
          if (variableNode is VariableDeclaration &&
              variableList is VariableDeclarationList &&
              variableList.parent is FieldDeclaration) {
            var keywordToken = variableList.keyword;
            if (variableList.variables.length == 1 &&
                keywordToken != null &&
                keywordToken.keyword == Keyword.FINAL) {
              await _insertAt(
                builder,
                keywordToken.offset,
                source: variableFragment.libraryFragment.source,
              );
            }
          }
        }
      }
    }
  }

  Future<void> _insertAt(
    ChangeBuilder builder,
    int offset, {
    Source? source,
  }) async {
    await builder.addDartFileEdit(source?.fullName ?? file, (builder) {
      builder.addSimpleInsertion(offset, 'late ');
    });
  }
}
