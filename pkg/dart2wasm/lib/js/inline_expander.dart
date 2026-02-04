// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import 'method_collector.dart';
import 'util.dart';

/// Expands inline JS calls to trampolines that call functions in the JS
/// runtime.
class InlineExpander {
  final StatefulStaticTypeContext _staticTypeContext;
  final CoreTypesUtil _util;
  final MethodCollector _methodCollector;
  late String _inlineJSImportName;
  bool _replaceProcedureWithInlineJS = false;

  InlineExpander(this._staticTypeContext, this._util, this._methodCollector);

  void enterProcedure() {
    // Under very restricted circumstances, we will make a procedure
    // external and clear it's body. See the description on
    // [expand] for more details.
    _replaceProcedureWithInlineJS = false;
  }

  void exitProcedure(Procedure node) {
    if (_replaceProcedureWithInlineJS) {
      node.isStatic = true;
      node.isExternal = true;
      node.function.body = null;
      _util.annotateProcedure(node, _inlineJSImportName, AnnotationType.import);
      _replaceProcedureWithInlineJS = false;
    }
  }

  Procedure? _tryGetEnclosingProcedure(TreeNode? node) {
    while (node is! Procedure) {
      node = node?.parent;
      if (node == null) {
        return null;
      }
    }
    return node;
  }

  /// We will replace the enclosing procedure if:
  ///   1) The enclosing procedure is static.
  ///   2) The enclosing procedure has a body with a single statement, and that
  ///      statement is just a [StaticInvocation] of the inline JS helper.
  ///   3) All of the arguments to `inlineJS` are [VariableGet]s. (this is
  ///      checked by [_expandInlineJS]).
  bool _shouldReplaceEnclosingProcedure(StaticInvocation node) {
    Procedure? enclosingProcedure = _tryGetEnclosingProcedure(node);
    if (enclosingProcedure == null) {
      return false;
    }
    Statement enclosingBody = enclosingProcedure.function.body!;
    Expression? expression;
    if (enclosingBody is ReturnStatement) {
      expression = enclosingBody.expression;
    } else if (enclosingBody is Block && enclosingBody.statements.length == 1) {
      Statement statement = enclosingBody.statements.single;
      if (statement is ExpressionStatement) {
        expression = statement.expression;
      } else if (statement is ReturnStatement) {
        expression = statement.expression;
      }
    }
    return expression == node;
  }

  /// Calls to the `JS` helper are replaced in one of two ways:
  ///   1) By a static invocation to an external stub method that imports
  ///      the JS function.
  ///   2) Under restricted circumstances the entire enclosing procedure will be
  ///      replaced by an external stub method that imports the JS function. See
  ///      [_shouldReplaceEnclosingProcedure] for more details.
  Expression expand(StaticInvocation node) {
    Arguments arguments = node.arguments;
    List<Expression> originalArguments = arguments.positional.sublist(1);
    List<VariableDeclaration> dartPositionalParameters = [];
    bool allArgumentsAreGet = true;
    for (int j = 0; j < originalArguments.length; j++) {
      Expression originalArgument = originalArguments[j];
      String parameterString = 'x$j';
      DartType type = originalArgument.getStaticType(_staticTypeContext);
      dartPositionalParameters.add(VariableDeclaration(parameterString,
          type: _toExternalType(type), isSynthesized: true));
      if (originalArgument is! VariableGet) {
        allArgumentsAreGet = false;
      }
    }

    Expression templateArgument = arguments.positional.first;
    String codeTemplate;
    if (templateArgument is StringLiteral) {
      codeTemplate = templateArgument.value;
    } else {
      assert(templateArgument is ConstantExpression,
          "Code template must be a StringLiteral or a ConstantExpression");
      templateArgument as ConstantExpression;
      Constant constant = templateArgument.constant;
      assert(constant is StringConstant,
          "Constant code template must be a StringConstant");
      constant as StringConstant;
      codeTemplate = constant.value;
    }
    String jsMethodName = _methodCollector.generateMethodName();
    _inlineJSImportName = 'dart2wasm.$jsMethodName';
    _replaceProcedureWithInlineJS =
        allArgumentsAreGet && _shouldReplaceEnclosingProcedure(node);
    Procedure dartProcedure;
    Expression result;
    if (_replaceProcedureWithInlineJS) {
      dartProcedure = _tryGetEnclosingProcedure(node)!;
      result = InvalidExpression("Unreachable");
    } else {
      dartProcedure = _methodCollector.addInteropProcedure(
          '|$jsMethodName',
          _inlineJSImportName,
          FunctionNode(null,
              positionalParameters: dartPositionalParameters,
              returnType: arguments.types.single),
          _util.inlineJSTarget.fileUri,
          AnnotationType.import,
          isExternal: true);
      result = StaticInvocation(dartProcedure, Arguments(originalArguments));
    }
    _methodCollector.addMethod(dartProcedure, jsMethodName, codeTemplate);
    return result;
  }

  // The `JS<foo>("...some js code ...", arg0, arg1)` expressions will produce
  // wasm imports. We want to only use types in those wasm imports that binaryen
  // allows under closed world assumptions (and not blindly use `arg<N>`s static
  // type).
  //
  // For now we special case `WasmArray<>` which we turn into a generic `array`
  // type (super type of all wasm arrays).
  DartType _toExternalType(DartType type) {
    if (type is InterfaceType && type.classNode == _util.wasmArrayClass) {
      return InterfaceType(_util.wasmArrayRefClass, type.declaredNullability);
    }
    return type;
  }
}
