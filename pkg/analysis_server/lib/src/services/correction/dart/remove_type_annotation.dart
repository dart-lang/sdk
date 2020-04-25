// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveTypeAnnotation extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.REMOVE_TYPE_ANNOTATION;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_TYPE_ANNOTATION;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    // todo (pq): unify w/ fix (and then add a guard to not assist on lints:
    //  avoid_return_types_on_setters, type_init_formals)
    var declarationList = node.thisOrAncestorOfType<VariableDeclarationList>();
    if (declarationList == null) {
      await _removeFromDeclaredIdentifier(builder);
    } else {
      await _removeFromDeclarationList(builder, declarationList);
    }
  }

  Future<void> _removeFromDeclarationList(DartChangeBuilder builder,
      VariableDeclarationList declarationList) async {
    // we need a type
    var typeNode = declarationList.type;
    if (typeNode == null) {
      return;
    }
    // ignore if an incomplete variable declaration
    if (declarationList.variables.length == 1 &&
        declarationList.variables[0].name.isSynthetic) {
      return;
    }
    // must be not after the name of the variable
    var firstVariable = declarationList.variables[0];
    if (selectionOffset > firstVariable.name.end) {
      return;
    }
    // The variable must have an initializer, otherwise there is no other
    // source for its type.
    if (firstVariable.initializer == null) {
      return;
    }
    var keyword = declarationList.keyword;
    await builder.addFileEdit(file, (DartFileEditBuilder builder) {
      var typeRange = range.startStart(typeNode, firstVariable);
      if (keyword != null && keyword.lexeme != 'var') {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, 'var ');
      }
    });
  }

  Future<void> _removeFromDeclaredIdentifier(DartChangeBuilder builder) async {
    var declaration = node.thisOrAncestorOfType<DeclaredIdentifier>();
    if (declaration == null) {
      return;
    }
    var typeNode = declaration.type;
    if (typeNode == null) {
      return;
    }
    var keyword = declaration.keyword;
    var variableName = declaration.identifier;
    await builder.addFileEdit(file, (DartFileEditBuilder builder) {
      var typeRange = range.startStart(typeNode, variableName);
      if (keyword != null && keyword.lexeme != 'var') {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, 'var ');
      }
    });
  }
}
