// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveTypeAnnotation extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.REMOVE_TYPE_ANNOTATION;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_TYPE_ANNOTATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    for (var node = this.node; node != null; node = node.parent) {
      if (node is DeclaredIdentifier) {
        return _removeFromDeclaredIdentifier(builder, node);
      }
      if (node is SimpleFormalParameter) {
        return _removeTypeAnnotation(builder, node.type);
      }
      if (node is TypeAnnotation && diagnostic != null) {
        return _removeTypeAnnotation(builder, node);
      }
      if (node is VariableDeclarationList) {
        return _removeFromDeclarationList(builder, node);
      }
    }
  }

  Future<void> _removeFromDeclarationList(
      ChangeBuilder builder, VariableDeclarationList declarationList) async {
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
    await builder.addDartFileEdit(file, (builder) {
      var typeRange = range.startStart(typeNode, firstVariable);
      if (keyword != null && keyword.lexeme != 'var') {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, 'var ');
      }
    });
  }

  Future<void> _removeFromDeclaredIdentifier(
      ChangeBuilder builder, DeclaredIdentifier declaration) async {
    var typeNode = declaration.type;
    if (typeNode == null) {
      return;
    }
    var keyword = declaration.keyword;
    var variableName = declaration.identifier;
    await builder.addDartFileEdit(file, (builder) {
      var typeRange = range.startStart(typeNode, variableName);
      if (keyword != null && keyword.lexeme != 'var') {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, 'var ');
      }
    });
  }

  Future<void> _removeTypeAnnotation(
      ChangeBuilder builder, TypeAnnotation type) async {
    if (type == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(type, type.endToken.next));
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveTypeAnnotation newInstance() => RemoveTypeAnnotation();
}
