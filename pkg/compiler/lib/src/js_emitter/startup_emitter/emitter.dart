// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.startup_emitter;

import 'package:js_runtime/shared/embedded_names.dart' show
    JsBuiltin,
    METADATA,
    STATIC_FUNCTION_NAME_TO_CLOSURE,
    TYPES;

import '../../common.dart';
import '../../compiler.dart' show
    Compiler;
import '../../constants/values.dart' show
    ConstantValue;
import '../../elements/elements.dart' show
    ClassElement,
    Element,
    FieldElement,
    FunctionElement;
import '../../js/js.dart' as js;
import '../../js_backend/js_backend.dart' show
    JavaScriptBackend,
    Namer;

import '../js_emitter.dart' show
    NativeEmitter;
import '../js_emitter.dart' as emitterTask show
    Emitter;
import '../program_builder/program_builder.dart' show ProgramBuilder;
import '../model.dart';

import 'model_emitter.dart';

class Emitter implements emitterTask.Emitter {
  final Compiler _compiler;
  final Namer namer;
  final ModelEmitter _emitter;

  JavaScriptBackend get _backend => _compiler.backend;

  Emitter(Compiler compiler, Namer namer, NativeEmitter nativeEmitter,
      bool shouldGenerateSourceMap)
      : this._compiler = compiler,
        this.namer = namer,
        _emitter = new ModelEmitter(
            compiler, namer, nativeEmitter, shouldGenerateSourceMap);

  DiagnosticReporter get reporter => _compiler.reporter;

  @override
  String get patchVersion => "startup";

  @override
  int emitProgram(ProgramBuilder programBuilder) {
    Program program = programBuilder.buildProgram();
    return _emitter.emitProgram(program);
  }

  @override
  bool get supportsReflection => false;

  @override
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    return _emitter.isConstantInlinedOrAlreadyEmitted(constant);
  }

  @override
  int compareConstants(ConstantValue a, ConstantValue b) {
    return _emitter.compareConstants(a, b);
  }

  @override
  js.Expression constantReference(ConstantValue value) {
    return _emitter.generateConstantReference(value);
  }

  @override
  js.Expression generateEmbeddedGlobalAccess(String global) {
    return _emitter.generateEmbeddedGlobalAccess(global);
  }

  @override
  // TODO(herhut): Use a single shared function.
  js.Expression generateFunctionThatReturnsNull() {
    return js.js('function() {}');
  }

  js.PropertyAccess _globalPropertyAccess(Element element) {
    js.Name name = namer.globalPropertyName(element);
    js.PropertyAccess pa = new js.PropertyAccess(
        new js.VariableUse(namer.globalObjectFor(element)), name);
    return pa;
  }

  @override
  js.Expression isolateLazyInitializerAccess(FieldElement element) {
    return js.js('#.#', [namer.globalObjectFor(element),
    namer.lazyInitializerName(element)]);
  }

  @override
  js.Expression isolateStaticClosureAccess(FunctionElement element) {
    return _emitter.generateStaticClosureAccess(element);
  }

  @override
  js.PropertyAccess staticFieldAccess(FieldElement element) {
    return _globalPropertyAccess(element);
  }

  @override
  js.PropertyAccess staticFunctionAccess(FunctionElement element) {
    return _globalPropertyAccess(element);
  }

  @override
  js.PropertyAccess constructorAccess(ClassElement element) {
    return _globalPropertyAccess(element);
  }

  @override
  js.PropertyAccess prototypeAccess(ClassElement element,
                                    bool hasBeenInstantiated) {
    js.Expression constructor =
        hasBeenInstantiated ? constructorAccess(element) : typeAccess(element);
    return js.js('#.prototype', constructor);
  }

  @override
  js.Expression interceptorClassAccess(ClassElement element) {
    return _globalPropertyAccess(element);
  }

  @override
  js.Expression typeAccess(Element element) {
    return _globalPropertyAccess(element);
  }

  @override
  js.Template templateForBuiltin(JsBuiltin builtin) {
    String typeNameProperty = ModelEmitter.typeNameProperty;

    switch (builtin) {
      case JsBuiltin.dartObjectConstructor:
        return js.js.expressionTemplateYielding(
            typeAccess(_compiler.coreClasses.objectClass));

      case JsBuiltin.isCheckPropertyToJsConstructorName:
        int isPrefixLength = namer.operatorIsPrefix.length;
        return js.js.expressionTemplateFor('#.substring($isPrefixLength)');

      case JsBuiltin.isFunctionType:
        return _backend.rtiEncoder.templateForIsFunctionType;

      case JsBuiltin.rawRtiToJsConstructorName:
        return js.js.expressionTemplateFor("#.$typeNameProperty");

      case JsBuiltin.rawRuntimeType:
        return js.js.expressionTemplateFor("#.constructor");

      case JsBuiltin.createFunctionTypeRti:
        return _backend.rtiEncoder.templateForCreateFunctionType;

      case JsBuiltin.isSubtype:
      // TODO(floitsch): move this closer to where is-check properties are
      // built.
        String isPrefix = namer.operatorIsPrefix;
        return js.js.expressionTemplateFor("('$isPrefix' + #) in #.prototype");

      case JsBuiltin.isGivenTypeRti:
        return js.js.expressionTemplateFor('#.$typeNameProperty === #');

      case JsBuiltin.getMetadata:
        String metadataAccess =
            _emitter.generateEmbeddedGlobalAccessString(METADATA);
        return js.js.expressionTemplateFor("$metadataAccess[#]");

      case JsBuiltin.getType:
        String typesAccess =
            _emitter.generateEmbeddedGlobalAccessString(TYPES);
        return js.js.expressionTemplateFor("$typesAccess[#]");

      case JsBuiltin.createDartClosureFromNameOfStaticFunction:
        String functionAccess = _emitter.generateEmbeddedGlobalAccessString(
            STATIC_FUNCTION_NAME_TO_CLOSURE);
        return js.js.expressionTemplateFor("$functionAccess(#)");

      default:
        reporter.internalError(NO_LOCATION_SPANNABLE,
            "Unhandled Builtin: $builtin");
        return null;
    }
  }

  @override
  void invalidateCaches() {
  }
}
