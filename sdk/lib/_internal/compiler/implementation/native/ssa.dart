// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of native;

final RegExp nativeRedirectionRegExp = new RegExp(r'^[a-zA-Z][a-zA-Z_$0-9]*$');

void handleSsaNative(SsaBuilder builder, Expression nativeBody) {
  Compiler compiler = builder.compiler;
  FunctionElement element = builder.work.element;
  NativeEmitter nativeEmitter = builder.nativeEmitter;
  JavaScriptBackend backend = builder.backend;

  HInstruction convertDartClosure(ParameterElement  parameter,
                                  FunctionType type) {
    HInstruction local = builder.localsHandler.readLocal(parameter);
    Constant arityConstant =
        builder.constantSystem.createInt(type.computeArity());
    HInstruction arity = builder.graph.addConstant(arityConstant, compiler);
    // TODO(ngeoffray): For static methods, we could pass a method with a
    // defined arity.
    Element helper = backend.getClosureConverter();
    builder.pushInvokeStatic(nativeBody, helper, [local, arity]);
    HInstruction closure = builder.pop();
    return closure;
  }

  // Check which pattern this native method follows:
  // 1) foo() native;
  //      hasBody = false
  // 2) foo() native "bar";
  //      No longer supported, this is now done with @JSName('foo') and case 1.
  // 3) foo() native "return 42";
  //      hasBody = true
  bool hasBody = false;
  assert(element.isNative);
  String nativeMethodName = element.fixedBackendName;
  if (nativeBody != null) {
    LiteralString jsCode = nativeBody.asLiteralString();
    String str = jsCode.dartString.slowToString();
    if (nativeRedirectionRegExp.hasMatch(str)) {
      compiler.internalError(
          nativeBody, "Deprecated syntax, use @JSName('name') instead.");
    }
    hasBody = true;
  }

  if (!hasBody) {
    nativeEmitter.nativeMethods.add(element);
  }

  FunctionSignature parameters = element.functionSignature;
  if (!hasBody) {
    List<String> arguments = <String>[];
    List<HInstruction> inputs = <HInstruction>[];
    String receiver = '';
    if (element.isInstanceMember) {
      receiver = '#.';
      inputs.add(builder.localsHandler.readThis());
    }
    parameters.forEachParameter((ParameterElement parameter) {
      DartType type = parameter.type.unalias(compiler);
      HInstruction input = builder.localsHandler.readLocal(parameter);
      if (type is FunctionType) {
        // The parameter type is a function type either directly or through
        // typedef(s).
        input = convertDartClosure(parameter, type);
      }
      inputs.add(input);
      arguments.add('#');
    });

    String foreignParameters = arguments.join(',');
    String nativeMethodCall;
    if (element.kind == ElementKind.FUNCTION) {
      nativeMethodCall = '$receiver$nativeMethodName($foreignParameters)';
    } else if (element.kind == ElementKind.GETTER) {
      nativeMethodCall = '$receiver$nativeMethodName';
    } else if (element.kind == ElementKind.SETTER) {
      nativeMethodCall = '$receiver$nativeMethodName = $foreignParameters';
    } else {
      builder.compiler.internalError(element,
                                     'Unexpected kind: "${element.kind}".');
    }

    builder.push(
        new HForeign(
            // TODO(sra): This could be cached.  The number of templates should
            // be proportional to the number of native methods, which is bounded
            // by the dart: libraries.
            js.js.uncachedExpressionTemplate(nativeMethodCall),
            backend.dynamicType,
            inputs, effects: new SideEffects()));
    builder.close(new HReturn(builder.pop())).addSuccessor(builder.graph.exit);
  } else {
    if (parameters.parameterCount != 0) {
      compiler.internalError(nativeBody,
          'native "..." syntax is restricted to '
          'functions with zero parameters.');
    }
    LiteralString jsCode = nativeBody.asLiteralString();
    builder.push(new HForeign.statement(
        js.js.statementTemplateYielding(
            new js.LiteralStatement(jsCode.dartString.slowToString())),
        <HInstruction>[],
        new SideEffects(),
        null,
        backend.dynamicType));
  }
}
