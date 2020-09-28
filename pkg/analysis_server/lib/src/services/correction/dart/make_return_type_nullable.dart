// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
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
    if (node is! Expression) {
      return;
    }
    var body = node.thisOrAncestorOfType<FunctionBody>();
    TypeAnnotation returnType;
    var function = body.parent;
    if (function is FunctionExpression) {
      function = function.parent;
    }
    if (function is MethodDeclaration) {
      returnType = function.returnType;
    } else if (function is FunctionDeclaration) {
      returnType = function.returnType;
    } else {
      return;
    }
    if (body.isAsynchronous || body.isGenerator) {
      if (returnType is! NamedType) {
        return null;
      }
      var typeArguments = (returnType as NamedType).typeArguments;
      if (typeArguments == null) {
        return null;
      }
      var arguments = typeArguments.arguments;
      if (arguments.length != 1) {
        return null;
      }
      returnType = arguments[0];
    }
    if (node is! NullLiteral &&
        !typeSystem.isAssignableTo(returnType.type,
            typeSystem.promoteToNonNull((node as Expression).staticType))) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(returnType.end, '?');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeReturnTypeNullable newInstance() => MakeReturnTypeNullable();
}
