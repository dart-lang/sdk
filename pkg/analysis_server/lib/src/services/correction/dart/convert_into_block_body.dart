// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../fix.dart';

class ConvertIntoBlockBody extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_BLOCK_BODY;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_INTO_BLOCK_BODY;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final body = getEnclosingFunctionBody();
    if (body == null || body.isGenerator) return;

    List<String>? codeLines;

    if (body is ExpressionFunctionBody) {
      codeLines = _getCodeForFunctionBody(body);
    } else if (body is EmptyFunctionBody) {
      codeLines = _getCodeForEmptyBody(body);
    }
    if (codeLines == null) return;

    // prepare prefix
    var prefix = utils.getNodePrefix(body.parent!);
    var indent = utils.getIndent(1);
    var sourceRange = range.endEnd(body.beginToken.previous!, body);

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(sourceRange, (builder) {
        builder.write(' ');
        if (body.isAsynchronous) {
          builder.write('async ');
        }
        builder.write('{');
        for (var line in codeLines!) {
          builder.write('$eol$prefix$indent');
          builder.write(line);
        }
        builder.selectHere();
        builder.write('$eol$prefix}');
      });
    });
  }

  List<String>? _getCodeForEmptyBody(EmptyFunctionBody body) {
    var functionElement = _getFunctionElement(body.parent);
    if (functionElement == null) return null;

    var lines = ['// TODO: implement ${functionElement.displayName}'];

    var returnValueType = functionElement.returnType2;
    if (returnValueType is! VoidType) {
      lines.add('throw UnimplementedError();');
    }
    return lines;
  }

  List<String>? _getCodeForFunctionBody(ExpressionFunctionBody body) {
    var returnValue = body.expression;

    // Return expressions can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in the function body.
    if (selectionOffset >= returnValue.offset) {
      return null;
    }

    var functionElement = _getFunctionElement(body.parent);
    if (functionElement == null) return null;

    var returnValueType = returnValue.typeOrThrow;
    var returnValueCode = utils.getNodeText(returnValue);
    var returnCode = '';
    if (returnValueType is! VoidType &&
        !returnValueType.isBottom &&
        functionElement.returnType2 is! VoidType) {
      returnCode = 'return ';
    }
    returnCode += '$returnValueCode;';
    return [returnCode];
  }

  ExecutableElement? _getFunctionElement(AstNode? node) {
    if (node is MethodDeclaration) {
      return node.declaredElement;
    } else if (node is ConstructorDeclaration) {
      return node.declaredElement;
    } else if (node is FunctionExpression) {
      return node.declaredElement;
    }
    return null;
  }
}
