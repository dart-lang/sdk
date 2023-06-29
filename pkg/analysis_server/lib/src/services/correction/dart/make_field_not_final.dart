// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeFieldNotFinal extends ResolvedCorrectionProducer {
  String _fieldName = '';

  @override
  List<Object> get fixArguments => [_fieldName];

  @override
  FixKind get fixKind => DartFixKind.MAKE_FIELD_NOT_FINAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! SimpleIdentifier) {
      return;
    }

    var getter = node.writeOrReadElement;
    if (getter is! PropertyAccessorElement) {
      return;
    }

    // The accessor must be a getter, and it must be synthetic.
    if (!(getter.isGetter && getter.isSynthetic)) {
      return;
    }

    // The variable must be not synthetic, and have no setter yet.
    var variable = getter.variable;
    if (variable.isSynthetic || variable.setter != null) {
      return;
    }

    // It must be a field declaration.
    if (getter.enclosingElement2 is! ClassElement) {
      return;
    }

    var declaration = await sessionHelper.getElementDeclaration(variable);
    var variableNode = declaration?.node;
    if (variableNode is! VariableDeclaration) {
      return;
    }

    // The declaration list must have exactly one variable.
    var declarationList = variableNode.parent;
    if (declarationList is! VariableDeclarationList) {
      return;
    }
    if (declarationList.variables.length != 1) {
      return;
    }

    // It must be a field declaration.
    if (declarationList.parent is! FieldDeclaration) {
      return;
    }

    var finalKeyword = declarationList.finalKeyword;
    if (finalKeyword == null) {
      return;
    }

    _fieldName = variable.displayName;
    await builder.addDartFileEdit(file, (builder) {
      var typeAnnotation = declarationList.type;
      if (typeAnnotation != null) {
        builder.addDeletion(
          range.startStart(finalKeyword, typeAnnotation),
        );
      } else {
        builder.addReplacement(
          range.startStart(finalKeyword, variableNode),
          (builder) {
            builder.write('var ');
          },
        );
      }
    });
  }
}
