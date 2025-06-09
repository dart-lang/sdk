// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddReturnType extends ResolvedCorrectionProducer {
  AddReturnType({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.addReturnType;

  @override
  FixKind get fixKind => DartFixKind.ADD_RETURN_TYPE;

  @override
  FixKind? get multiFixKind => DartFixKind.ADD_RETURN_TYPE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node
        case MethodDeclaration(:var name, :var returnType, :var isSetter) ||
            FunctionDeclaration(:var name, :var returnType, :var isSetter)) {
      if (name != token) {
        return;
      }
      if (returnType != null) {
        return;
      }
      if (isSetter) {
        return;
      }
    }

    Token insertBeforeEntity;
    FunctionBody body;
    if (node case MethodDeclaration method) {
      insertBeforeEntity =
          method.operatorKeyword ?? method.propertyKeyword ?? method.name;
      body = method.body;
    } else if (node case FunctionDeclaration method) {
      insertBeforeEntity = method.propertyKeyword ?? method.name;
      body = method.functionExpression.body;
    } else {
      return;
    }

    var returnType = _inferReturnType(body);
    if (returnType == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      if (returnType is DynamicType || builder.canWriteType(returnType)) {
        builder.addInsertion(insertBeforeEntity.offset, (builder) {
          if (returnType is DynamicType) {
            builder.write('dynamic');
          } else {
            builder.writeType(returnType);
          }
          builder.write(' ');
        });
      }
    });
  }

  /// Returns the type of value returned by the function [body], or `null` if a
  /// type can't be inferred.
  DartType? _inferReturnType(FunctionBody body) {
    DartType baseType;
    switch (body) {
      case BlockFunctionBody():
        var computer = ReturnTypeComputer(
          unitResult.typeSystem,
          isGenerator: body.isGenerator,
        );
        body.block.accept(computer);
        baseType = computer.returnType ?? typeProvider.voidType;
      case ExpressionFunctionBody():
        baseType = body.expression.typeOrThrow;
      case EmptyFunctionBody():
      case NativeFunctionBody():
        return null;
    }

    if (body.isAsynchronous) {
      if (body.isGenerator) {
        return typeProvider.streamElement2.instantiate(
          typeArguments: [baseType],
          nullabilitySuffix: baseType.nullabilitySuffix,
        );
      } else {
        return typeProvider.futureElement2.instantiate(
          typeArguments: [baseType],
          nullabilitySuffix: baseType.nullabilitySuffix,
        );
      }
    } else if (body.isGenerator) {
      return typeProvider.iterableElement2.instantiate(
        typeArguments: [baseType],
        nullabilitySuffix: baseType.nullabilitySuffix,
      );
    }
    return baseType;
  }
}
