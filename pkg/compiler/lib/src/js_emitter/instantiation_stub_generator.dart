// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.instantiation_stub_generator;

import '../common_elements.dart' show JCommonElements, JElementEnvironment;
import '../elements/entities.dart';
import '../io/source_information.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/namer.dart' show Namer;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart' show SelectorConstraints;
import '../world.dart' show JClosedWorld;

import 'model.dart';

import 'code_emitter_task.dart' show CodeEmitterTask, Emitter;

// Generator of stubs required for Instantiation classes.
class InstantiationStubGenerator {
  final CodeEmitterTask _emitterTask;
  final Namer _namer;
  final CodegenWorld _codegenWorld;
  final JClosedWorld _closedWorld;
  // ignore: UNUSED_FIELD
  final SourceInformationStrategy _sourceInformationStrategy;

  InstantiationStubGenerator(this._emitterTask, this._namer, this._closedWorld,
      this._codegenWorld, this._sourceInformationStrategy);

  Emitter get _emitter => _emitterTask.emitter;

  JCommonElements get _commonElements => _closedWorld.commonElements;
  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;

  /// Generates a stub to forward a call selector with no type arguments to a
  /// call selector with stored types.
  ///
  /// [instantiationClass] is the class containing the captured type arguments.
  /// [callSelector] is the selector with no type arguments. [targetSelector] is
  /// the selector accepting the type arguments.
  ParameterStubMethod _generateStub(
      ClassEntity instantiationClass,
      FieldEntity functionField,
      Selector callSelector,
      Selector targetSelector) {
    // TODO(sra): Generate source information for stub that has no member.
    //
    //SourceInformationBuilder sourceInformationBuilder =
    //    _sourceInformationStrategy.createBuilderForContext(member);
    //SourceInformation sourceInformation =
    //    sourceInformationBuilder.buildStub(member, callStructure);

    assert(callSelector.typeArgumentCount == 0);
    int typeArgumentCount = targetSelector.typeArgumentCount;
    assert(typeArgumentCount > 0);

    // The forwarding stub for three arguments of an instantiation with two type
    // arguments looks like this:
    //
    // ```
    // call$3: function(a0, a1, a2) {
    //   return this._f.call$2$3(a0, a1, a2, this.$ti[0], this.$ti[1]);
    // }
    // ```

    List<jsAst.Parameter> parameters = <jsAst.Parameter>[];
    List<jsAst.Expression> arguments = <jsAst.Expression>[];

    for (int i = 0; i < callSelector.argumentCount; i++) {
      String jsName = 'a$i';
      arguments.add(js('#', jsName));
      parameters.add(new jsAst.Parameter(jsName));
    }

    for (int i = 0; i < targetSelector.typeArgumentCount; i++) {
      arguments.add(js('this.#.#[#]', [
        _namer.rtiFieldJsName,
        _namer.fieldPropertyName(_commonElements.rtiRestField),
        js.number(i)
      ]));
    }

    jsAst.Fun function = js('function(#) { return this.#.#(#); }', [
      parameters,
      _namer.fieldPropertyName(functionField),
      _namer.invocationName(targetSelector),
      arguments,
    ]);
    // TODO(sra): .withSourceInformation(sourceInformation);

    jsAst.Name name = _namer.invocationName(callSelector);
    return new ParameterStubMethod(name, null, function);
  }

  /// Generates a stub for a 'signature' selector. The stub calls the underlying
  /// function's 'signature' method and calls a helper to subsitute the type
  /// parameters in the type term. The stub looks like this:
  ///
  /// ```
  /// $signature:: function() {
  ///   return H.instantiatedGenericFunctionTypeNewRti(
  ///       H.closureFunctionType(this._genericClosure),
  ///       this.$ti);
  /// }
  /// ```
  ParameterStubMethod _generateSignatureStub(FieldEntity functionField) {
    jsAst.Name operatorSignature =
        _namer.asName(_namer.fixedNames.operatorSignature);

    jsAst.Fun function = _generateSignatureNewRti(functionField);

    // TODO(sra): Generate source information for stub that has no member.
    // TODO(sra): .withSourceInformation(sourceInformation);

    return new ParameterStubMethod(operatorSignature, null, function);
  }

  jsAst.Fun _generateSignatureNewRti(FieldEntity functionField) =>
      js('function() { return #(#(this.#), this.#); }', [
        _emitter.staticFunctionAccess(
            _commonElements.instantiatedGenericFunctionTypeNewRti),
        _emitter.staticFunctionAccess(_commonElements.closureFunctionType),
        _namer.fieldPropertyName(functionField),
        _namer.rtiFieldJsName,
      ]);

  // Returns all stubs for an instantiation class.
  //
  List<StubMethod> generateStubs(
      ClassEntity instantiationClass, FunctionEntity member) {
    // 1. Find the number of type parameters in [instantiationClass].
    int typeArgumentCount = _closedWorld.dartTypes
        .getThisType(instantiationClass)
        .typeArguments
        .length;
    assert(typeArgumentCount > 0);

    // 2. Find the function field access path.
    FieldEntity functionField;
    _elementEnvironment.forEachInstanceField(instantiationClass,
        (ClassEntity enclosing, FieldEntity field) {
      if (_closedWorld.fieldAnalysis.getFieldData(field).isElided) return;
      if (field.name == '_genericClosure') functionField = field;
    });
    assert(functionField != null,
        "Can't find Closure field of $instantiationClass");

    String call = _namer.closureInvocationSelectorName;
    Map<Selector, SelectorConstraints> callSelectors =
        _codegenWorld.invocationsByName(call);

    Set<ParameterStructure> computeLiveParameterStructures() {
      Set<ParameterStructure> parameterStructures =
          new Set<ParameterStructure>();

      void process(FunctionEntity function) {
        if (function.parameterStructure.typeParameters == typeArgumentCount) {
          parameterStructures.add(function.parameterStructure);
        }
      }

      _codegenWorld.closurizedStatics.forEach(process);
      _codegenWorld.closurizedMembers.forEach(process);
      _codegenWorld.forEachGenericClosureCallMethod(process);

      return parameterStructures;
    }

    List<StubMethod> stubs = <StubMethod>[];

    // For every call-selector generate a stub to the corresponding selector
    // with filled-in type arguments.

    if (callSelectors != null) {
      Set<ParameterStructure> parameterStructures;
      for (Selector selector in callSelectors.keys) {
        CallStructure callStructure = selector.callStructure;
        if (callStructure.typeArgumentCount != 0) continue;
        CallStructure genericCallStructure =
            callStructure.withTypeArgumentCount(typeArgumentCount);
        parameterStructures ??= computeLiveParameterStructures();
        for (ParameterStructure parameterStructure in parameterStructures) {
          if (genericCallStructure.signatureApplies(parameterStructure)) {
            Selector genericSelector =
                new Selector.call(selector.memberName, genericCallStructure);
            stubs.add(_generateStub(
                instantiationClass, functionField, selector, genericSelector));
            break;
          }
        }
      }
    }

    stubs.add(_generateSignatureStub(functionField));

    return stubs;
  }
}
