// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../constants/values.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../js/js.dart' as js;
import '../js_emitter/js_emitter.dart' show NativeEmitter;
import '../ssa/builder.dart' show SsaAstGraphBuilder;
import '../ssa/nodes.dart' show HInstruction, HForeignCode, HReturn;
import '../tree/tree.dart';
import '../universe/side_effects.dart' show SideEffects;

final RegExp nativeRedirectionRegExp = new RegExp(r'^[a-zA-Z][a-zA-Z_$0-9]*$');

void handleSsaNative(SsaAstGraphBuilder builder, Expression nativeBody) {
  MethodElement element = builder.target;
  NativeEmitter nativeEmitter = builder.nativeEmitter;

  HInstruction convertDartClosure(
      ParameterElement parameter, ResolutionFunctionType type) {
    HInstruction local = builder.localsHandler.readLocal(parameter);
    ConstantValue arityConstant =
        builder.constantSystem.createInt(type.parameterTypes.length);
    HInstruction arity =
        builder.graph.addConstant(arityConstant, builder.closedWorld);
    // TODO(ngeoffray): For static methods, we could pass a method with a
    // defined arity.
    MethodElement helper = builder.commonElements.closureConverter;
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
  assert(builder.nativeData.isNativeMember(element));
  String nativeMethodName = builder.nativeData.getFixedBackendName(element);
  if (nativeBody != null) {
    LiteralString jsCode = nativeBody.asLiteralString();
    String str = jsCode.dartString.slowToString();
    if (nativeRedirectionRegExp.hasMatch(str)) {
      throw new SpannableAssertionFailure(
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
    parameters.forEachParameter((_parameter) {
      ParameterElement parameter = _parameter;
      ResolutionDartType type = parameter.type.unaliased;
      HInstruction input = builder.localsHandler.readLocal(parameter);
      if (type is ResolutionFunctionType) {
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
      throw new SpannableAssertionFailure(
          element, 'Unexpected kind: "${element.kind}".');
    }

    builder.push(new HForeignCode(
        // TODO(sra): This could be cached.  The number of templates should
        // be proportional to the number of native methods, which is bounded
        // by the dart: libraries.
        js.js.uncachedExpressionTemplate(nativeMethodCall),
        builder.commonMasks.dynamicType,
        inputs,
        effects: new SideEffects()));
    // TODO(johnniwinther): Provide source information.
    builder
        .close(new HReturn(builder.pop(), null))
        .addSuccessor(builder.graph.exit);
  } else {
    if (parameters.parameterCount != 0) {
      throw new SpannableAssertionFailure(
          nativeBody,
          'native "..." syntax is restricted to '
          'functions with zero parameters.');
    }
    LiteralString jsCode = nativeBody.asLiteralString();
    builder.push(new HForeignCode.statement(
        js.js.statementTemplateYielding(
            new js.LiteralStatement(jsCode.dartString.slowToString())),
        <HInstruction>[],
        new SideEffects(),
        null,
        builder.commonMasks.dynamicType));
  }
}
