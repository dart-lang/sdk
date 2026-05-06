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
    List<Expression> originalArguments = arguments.positional.sublist(1);
    List<VariableDeclaration> dartPositionalParameters = [];
    for (int j = 0; j < originalArguments.length; j++) {
      Expression originalArgument = originalArguments[j];
      String parameterString = 'x$j';
      DartType type = originalArgument.getStaticType(_staticTypeContext);
      dartPositionalParameters.add(
        VariableDeclaration(
          parameterString,
          type: _toExternalType(type),
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
    if (resultType is VoidType) {
      resultType = InterfaceType(_util.wasmVoidClass, Nullability.nonNullable);
    }
    dartProcedure = makeInteropProcedure(
      _staticTypeContext.enclosingLibrary,
      '_JS_Inline_${_counter++}',
      node.location!.file,
      FunctionNode(
        null,
        positionalParameters: dartPositionalParameters,
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
