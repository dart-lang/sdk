// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeVariableNotFinal extends CorrectionProducer {
  String _variableName = '';

  @override
  List<Object> get fixArguments => [_variableName];

  @override
  FixKind get fixKind => DartFixKind.MAKE_VARIABLE_NOT_FINAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! SimpleIdentifier) {
      return;
    }

    var variable = node.staticElement;
    if (variable is! LocalVariableElement) {
      return;
    }

    var id = NodeLocator(variable.nameOffset).searchWithin(unit);
    var declaration = id?.parent;
    var declarationList = declaration?.parent;

    if (declaration is VariableDeclaration &&
        declarationList is VariableDeclarationList) {
      var keywordToken = declarationList.keyword;
      if (declarationList.variables.length == 1 &&
          keywordToken != null &&
          keywordToken.keyword == Keyword.FINAL) {
        await builder.addDartFileEdit(file, (builder) {
          var typeAnnotation = declarationList.type;
          if (typeAnnotation != null) {
            builder.addDeletion(
              range.startStart(keywordToken, typeAnnotation),
            );
          } else {
            builder.addSimpleReplacement(range.token(keywordToken), 'var');
          }
        });
        _variableName = variable.name;
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeVariableNotFinal newInstance() => MakeVariableNotFinal();
}
