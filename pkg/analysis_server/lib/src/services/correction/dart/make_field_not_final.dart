// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeFieldNotFinal extends CorrectionProducer {
  String _fieldName;

  @override
  List<Object> get fixArguments => [_fieldName];

  @override
  FixKind get fixKind => DartFixKind.MAKE_FIELD_NOT_FINAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SimpleIdentifier &&
        node.writeOrReadElement is PropertyAccessorElement) {
      PropertyAccessorElement getter = node.writeOrReadElement;
      if (getter.isGetter &&
          getter.isSynthetic &&
          !getter.variable.isSynthetic &&
          getter.variable.setter == null &&
          getter.enclosingElement is ClassElement) {
        var declarationResult =
            await sessionHelper.getElementDeclaration(getter.variable);
        var variable = declarationResult.node;
        if (variable is VariableDeclaration &&
            variable.parent is VariableDeclarationList &&
            variable.parent.parent is FieldDeclaration) {
          VariableDeclarationList declarationList = variable.parent;
          var keywordToken = declarationList.keyword;
          if (declarationList.variables.length == 1 &&
              keywordToken.keyword == Keyword.FINAL) {
            await builder.addDartFileEdit(file, (builder) {
              if (declarationList.type != null) {
                builder.addDeletion(
                    range.startStart(keywordToken, declarationList.type));
              } else {
                builder.addReplacement(range.startStart(keywordToken, variable),
                    (builder) {
                  builder.write('var ');
                });
              }
            });
            _fieldName = getter.variable.displayName;
          }
        }
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeFieldNotFinal newInstance() => MakeFieldNotFinal();
}
