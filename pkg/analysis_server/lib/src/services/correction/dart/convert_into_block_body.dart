// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertIntoBlockBody extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_BLOCK_BODY;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var body = getEnclosingFunctionBody();
    // prepare expression body
    if (body is! ExpressionFunctionBody || body.isGenerator) {
      return;
    }

    var returnValue = body.expression;

    // Return expressions can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in the function body.
    if (selectionOffset >= returnValue.offset) {
      return;
    }

    DartType? getFunctionReturnType() {
      var parent = body.parent;
      if (parent is MethodDeclaration) {
        return parent.declaredElement?.returnType;
      } else if (parent is ConstructorDeclaration) {
        return parent.declaredElement?.returnType;
      } else if (parent is FunctionExpression) {
        return parent.declaredElement?.returnType;
      }
      return null;
    }

    var functionReturnType = getFunctionReturnType();
    if (functionReturnType == null) {
      return;
    }
    var returnValueType = returnValue.typeOrThrow;
    var returnValueCode = utils.getNodeText(returnValue);
    // prepare prefix
    var prefix = utils.getNodePrefix(body.parent!);
    var indent = utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(body), (builder) {
        if (body.isAsynchronous) {
          builder.write('async ');
        }
        builder.write('{$eol$prefix$indent');
        if (!returnValueType.isVoid &&
            !returnValueType.isBottom &&
            !functionReturnType.isVoid) {
          builder.write('return ');
        }
        builder.write(returnValueCode);
        builder.write(';');
        builder.selectHere();
        builder.write('$eol$prefix}');
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertIntoBlockBody newInstance() => ConvertIntoBlockBody();
}
