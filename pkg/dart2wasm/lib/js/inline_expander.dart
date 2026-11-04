// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import 'util.dart';

/// Expands inline JS calls to trampolines that call functions in the JS
/// runtime.
class InlineExpander {
  final StatefulStaticTypeContext _staticTypeContext;
  final CoreTypesUtil _util;
  static int _counter = 0;

  InlineExpander(this._staticTypeContext, this._util);

  /// Calls to the `JS` helper are replaced by a static invocation to an
  /// external stub method that imports the JS function.
  Expression expand(StaticInvocation node) {
    Arguments arguments = node.arguments;
    ExpressionList originalArguments = arguments.positional.skip(1);
    List<PositionalParameter> dartPositionalParameters = [];
    for (int j = 0; j < originalArguments.length; j++) {
      Expression originalArgument = originalArguments[j];
      String parameterString = 'x$j';
      DartType type = originalArgument.getStaticType(_staticTypeContext);
      dartPositionalParameters.add(
        PositionalParameter(
          parameterName: parameterString,
          type: type,
          isSynthesized: true,
        ),
      );
    }

    Expression templateArgument = arguments.positional.first;
    String codeTemplate;
    if (templateArgument is StringLiteral) {
      codeTemplate = templateArgument.value;
    } else {
      assert(
        templateArgument is ConstantExpression,
        "Code template must be a StringLiteral or a ConstantExpression",
      );
      templateArgument as ConstantExpression;
      Constant constant = templateArgument.constant;
      assert(
        constant is StringConstant,
        "Constant code template must be a StringConstant",
      );
      constant as StringConstant;
      codeTemplate = constant.value;
    }
    Procedure dartProcedure;
    Expression result;
    DartType resultType = arguments.types.single;
    dartProcedure = makeInteropProcedure(
      _staticTypeContext.enclosingLibrary,
      '_JS_Inline_${_counter++}',
      node.location!.file,
      FunctionNode(
        null,
        positionalParameters: PositionalParameterList.from(
          dartPositionalParameters,
        ),
        returnType: resultType,
      ),
      isExternal: true,
    );
    result = StaticInvocation(dartProcedure, Arguments(originalArguments));
    JsCodeData(codeTemplate).applyToMember(dartProcedure, _util.coreTypes);
    return _util.castInvocationForReturn(
      result,
      resultType,
      onlyHandleNull: true,
    );
  }
}
