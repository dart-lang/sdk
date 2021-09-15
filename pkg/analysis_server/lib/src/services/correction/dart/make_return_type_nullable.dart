// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class MakeReturnTypeNullable extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.MAKE_RETURN_TYPE_NULLABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!unit.featureSet.isEnabled(Feature.non_nullable)) {
      return;
    }

    final node = this.node;
    if (node is! Expression) {
      return;
    }

    final type = node.staticType;
    if (type == null) {
      return;
    }

    var body = node.thisOrAncestorOfType<FunctionBody>();
    if (body == null) {
      return;
    }

    var returnType = _getReturnTypeNode(body);
    if (returnType == null) {
      return;
    }

    if (body.isAsynchronous || body.isGenerator) {
      if (returnType is! NamedType) {
        return;
      }
      var typeArguments = returnType.typeArguments;
      if (typeArguments == null) {
        return;
      }
      var arguments = typeArguments.arguments;
      if (arguments.length != 1) {
        return;
      }
      returnType = arguments[0];
    }

    if (node is! NullLiteral &&
        !typeSystem.isAssignableTo(
            returnType.typeOrThrow, typeSystem.promoteToNonNull(type))) {
      return;
    }

    final returnType_final = returnType;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(returnType_final.end, '?');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeReturnTypeNullable newInstance() => MakeReturnTypeNullable();

  static TypeAnnotation? _getReturnTypeNode(FunctionBody body) {
    var function = body.parent;
    if (function is FunctionExpression) {
      function = function.parent;
    }
    if (function is MethodDeclaration) {
      return function.returnType;
    } else if (function is FunctionDeclaration) {
      return function.returnType;
    }
    return null;
  }
}
