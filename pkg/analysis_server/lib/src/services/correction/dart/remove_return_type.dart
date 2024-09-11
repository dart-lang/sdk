// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveReturnType extends ResolvedCorrectionProducer {
  RemoveReturnType({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.REMOVE_RETURN_TYPE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Token? insertBeforeEntity;
    TypeAnnotation? returnType;
    var executable = node;
    if (executable is MethodDeclaration && executable.name == token) {
      if (executable.returnType == null) {
        return;
      }
      if (executable.isSetter) {
        return;
      }
      insertBeforeEntity = executable.operatorKeyword ??
          executable.propertyKeyword ??
          executable.name;
      returnType = executable.returnType;
    } else if (executable is FunctionDeclaration && executable.name == token) {
      if (executable.returnType == null) {
        return;
      }
      insertBeforeEntity = executable.propertyKeyword ?? executable.name;
      returnType = executable.returnType;
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
}
