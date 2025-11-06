// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class MakeReturnTypeNullable extends ResolvedCorrectionProducer {
  MakeReturnTypeNullable({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.MAKE_RETURN_TYPE_NULLABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! Expression) {
      return;
    }
    if (node is SimpleIdentifier && node.isSynthetic) {
      return;
    }

    var type = node.staticType;
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

    if (node is! NullLiteral &&
        !typeSystem.isAssignableTo(
          type,
          returnType.typeOrThrow.withNullability(NullabilitySuffix.question),
          strictCasts: analysisOptions.strictCasts,
        )) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(returnType.end, '?');
    });
  }

  static TypeAnnotation? _getReturnTypeNode(FunctionBody body) {
    var function = body.parent;
    if (function is FunctionExpression) {
      function = function.parent;
    }
    TypeAnnotation? returnType;
    if (function is MethodDeclaration) {
      returnType = function.returnType;
    } else if (function is FunctionDeclaration) {
      returnType = function.returnType;
    } else {
      return null;
    }

    if (body.isAsynchronous || body.isGenerator) {
      if (returnType is! NamedType) {
        return null;
      }
      var typeArguments = returnType.typeArguments;
      if (typeArguments == null) {
        return null;
      }
      var arguments = typeArguments.arguments;
      if (arguments.length != 1) {
        return null;
      }
      returnType = arguments.single;
    }
    return returnType;
  }
}
