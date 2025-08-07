// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToFunctionDeclaration extends ResolvedCorrectionProducer {
  ConvertToFunctionDeclaration({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_FUNCTION_DECLARATION;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_FUNCTION_DECLARATION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! VariableDeclaration) return;
    var equals = node.equals;
    if (equals == null) return;
    var initializer = node.initializer;

    var parent = node.parent;
    if (parent is! VariableDeclarationList) return;
    var keyword = parent.keyword;
    var type = parent.type;

    var variables = parent.variables;

    var grandParent = parent.parent;
    if (grandParent is! VariableDeclarationStatement) return;

    var previous = _previous(variables, node);
    var next = _next(variables, node);

    await builder.addDartFileEdit(file, (builder) {
      void replaceWithNewLine(
        SourceRange range, {
        String? before,
        String? after,
      }) {
        builder.addReplacement(range, (builder) {
          if (before != null) {
            builder.write(before);
          }
          builder.writeln();
          builder.write(utils.getLinePrefix(range.offset));
          if (after != null) {
            builder.write(after);
          }
        });
      }

      if (previous == null) {
        if (keyword != null) {
          builder.addDeletion(range.startStart(keyword, keyword.next!));
        }
        if (type != null) {
          builder.addDeletion(range.startStart(type, type.endToken.next!));
        }
      } else if (previous.initializer is! FunctionExpression) {
        var r = range.endStart(
          previous.endToken,
          previous.endToken.next!.next!,
        );
        replaceWithNewLine(r, before: ';');
      }

      DartType? returnType;
      List<FormalParameterElement?>? parameterList;
      if (type case NamedType(
        element: TypeAliasElement(:FunctionType aliasedType),
      )) {
        returnType = aliasedType.returnType;
        parameterList = aliasedType.formalParameters;
      } else if (type is GenericFunctionType) {
        returnType = type.returnType?.type;
        parameterList =
            type.parameters.parameters
                .map((node) => node.declaredFragment!.element)
                .toList();
      } else if (initializer case FunctionExpression(
        declaredFragment: ExecutableFragment(:var element),
        :var body,
      )) {
        returnType = element.returnType;
        var visitor = _ReturnVisitor();
        body.accept(visitor);
        if (visitor.noReturnFounds) {
          if (typeProvider.nullType == element.returnType) {
            returnType = typeProvider.voidType;
          } else if (typeProvider.futureNullType == element.returnType) {
            returnType = typeProvider.futureType(typeProvider.voidType);
          }
        }
      }

      if (builder.canWriteType(returnType)) {
        builder.addInsertion(node.offset, (builder) {
          builder.writeType(returnType);
          builder.write(' ');
        });
      }

      builder.addDeletion(range.endStart(equals.previous!, equals.next!));

      if (parameterList != null) {
        var staticParameters = parameterList;
        if (initializer case FunctionExpression(:var parameters?)) {
          for (var (index, parameter) in parameters.parameters.indexed) {
            if (parameter.isExplicitlyTyped) {
              continue;
            }
            var staticParameterType = staticParameters[index]?.type;
            if (!builder.canWriteType(staticParameterType)) {
              continue;
            }
            builder.addInsertion(parameter.offset, (builder) {
              builder.writeType(staticParameterType);
              builder.write(' ');
            });
          }
        }
      }

      if (next != null) {
        var r = range.endStart(node.endToken, node.endToken.next!.next!);
        if (next.initializer is FunctionExpression) {
          replaceWithNewLine(r);
        } else {
          var replacement = '';
          if (keyword != null) {
            replacement += '$keyword ';
          }
          if (type != null) {
            replacement += '${utils.getNodeText(type)} ';
          }
          replaceWithNewLine(r, after: replacement);
        }
      } else if (initializer is FunctionExpression &&
          initializer.body is BlockFunctionBody) {
        builder.addDeletion(range.token(grandParent.semicolon));
      }
    });
  }

  VariableDeclaration? _next(
    NodeList<VariableDeclaration> variables,
    VariableDeclaration variable,
  ) {
    var i = variables.indexOf(variable);
    return i < variables.length - 1 ? variables[i + 1] : null;
  }

  VariableDeclaration? _previous(
    NodeList<VariableDeclaration> variables,
    VariableDeclaration variable,
  ) {
    var i = variables.indexOf(variable);
    return i > 0 ? variables[i - 1] : null;
  }
}

class _ReturnVisitor extends RecursiveAstVisitor<void> {
  int _count = 0;

  bool get noReturnFounds => _count == 0;

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _count++;
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Inner function expressions are not counted.
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _count++;
    super.visitReturnStatement(node);
  }
}
