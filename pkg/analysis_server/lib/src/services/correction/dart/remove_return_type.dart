// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveReturnType extends ResolvedCorrectionProducer {
  RemoveReturnType({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.REMOVE_RETURN_TYPE;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_RETURN_TYPE;

  @override
  FixKind? get multiFixKind => DartFixKind.REMOVE_RETURN_TYPE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Token? insertBeforeEntity;
    TypeAnnotation? returnType;
    AstNode? executable;
    if (_isExecutableNode(node)) {
      executable = node;
    } else if (node is NamedType && _isExecutableNode(node.parent)) {
      executable = node.parent!;
      returnType = node as NamedType;
    }

    if (executable == null) {
      return;
    }

    if ((executable is MethodDeclaration) &&
        ((executable.name == token) || (returnType != null))) {
      if (executable.returnType == null) {
        return;
      }
      insertBeforeEntity = executable.operatorKeyword ??
          executable.propertyKeyword ??
          executable.name;
      returnType ??= executable.returnType;
    } else if ((executable is FunctionDeclaration) &&
        ((executable.name == token) || (returnType != null))) {
      if (executable.returnType == null) {
        return;
      }
      insertBeforeEntity = executable.propertyKeyword ?? executable.name;
      returnType ??= executable.returnType;
    } else {
      return;
    }

    if (returnType == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startOffsetEndOffset(
        returnType!.offset,
        insertBeforeEntity!.offset,
      ));
    });
  }

  // Helper function to check if the node is a method or function declaration
  bool _isExecutableNode(AstNode? node) {
    return node is MethodDeclaration || node is FunctionDeclaration;
  }
}
