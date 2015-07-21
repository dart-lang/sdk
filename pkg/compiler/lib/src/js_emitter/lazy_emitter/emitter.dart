// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.lazy_emitter;

import 'package:js_runtime/shared/embedded_names.dart' show
    JsBuiltin,
    METADATA,
    TYPES;

import '../program_builder/program_builder.dart' show ProgramBuilder;
import '../model.dart';
import 'model_emitter.dart';
import '../../common.dart';
import '../../elements/elements.dart' show FieldElement;
import '../../js/js.dart' as js;

import '../../js_backend/js_backend.dart' show
    JavaScriptBackend,
    Namer;

import '../js_emitter.dart' show
    NativeEmitter;

import '../js_emitter.dart' as emitterTask show
    Emitter;

import '../../util/util.dart' show
    NO_LOCATION_SPANNABLE;

class Emitter implements emitterTask.Emitter {
  final Compiler _compiler;
  final Namer namer;
  final ModelEmitter _emitter;

  JavaScriptBackend get _backend => _compiler.backend;

  Emitter(Compiler compiler, Namer namer, NativeEmitter nativeEmitter)
      : this._compiler = compiler,
        this.namer = namer,
        _emitter = new ModelEmitter(compiler, namer, nativeEmitter);

  @override
  int emitProgram(ProgramBuilder programBuilder) {
    Program program = programBuilder.buildProgram();
    return _emitter.emitProgram(program);
  }

  @override
  bool get supportsReflection => false;

  // TODO(floitsch): copied from full emitter. Adjust or share.
  @override
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    return _emitter.isConstantInlinedOrAlreadyEmitted(constant);
  }

  // TODO(floitsch): copied from full emitter. Adjust or share.
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
    // Some interceptors are eagerly constructed. However, native interceptors
    // aren't.
    return js.js('#.ensureResolved()', _globalPropertyAccess(element));
  }

  @override
  js.Expression typeAccess(Element element) {
    // TODO(floitsch): minify 'ensureResolved'.
    // TODO(floitsch): don't emit `ensureResolved` for eager classes.
    return js.js('#.ensureResolved()', _globalPropertyAccess(element));
  }

  @override
  js.Template templateForBuiltin(JsBuiltin builtin) {
    String typeNameProperty = ModelEmitter.typeNameProperty;

    switch (builtin) {
      case JsBuiltin.dartObjectConstructor:
        return js.js.expressionTemplateYielding(
            typeAccess(_compiler.objectClass));

      case JsBuiltin.isCheckPropertyToJsConstructorName:
        int isPrefixLength = namer.operatorIsPrefix.length;
        return js.js.expressionTemplateFor('#.substring($isPrefixLength)');

      case JsBuiltin.isFunctionType:
        return _backend.rti.representationGenerator.templateForIsFunctionType;

      case JsBuiltin.rawRtiToJsConstructorName:
        return js.js.expressionTemplateFor("#.$typeNameProperty");

      case JsBuiltin.rawRuntimeType:
        return js.js.expressionTemplateFor("#.constructor");

      case JsBuiltin.createFunctionTypeRti:
        return _backend.rti.representationGenerator
            .templateForCreateFunctionType;

      case JsBuiltin.isSubtype:
        // TODO(floitsch): move this closer to where is-check properties are
        // built.
        String isPrefix = namer.operatorIsPrefix;
        return js.js.expressionTemplateFor("('$isPrefix' + #) in #.prototype");

      case JsBuiltin.isGivenTypeRti:
        return js.js.expressionTemplateFor('#.$typeNameProperty === #');

      case JsBuiltin.getMetadata:
        return _emitter.templateForReadMetadata;

      case JsBuiltin.getType:
        return _emitter.templateForReadType;

      default:
        _compiler.internalError(NO_LOCATION_SPANNABLE,
                                "Unhandled Builtin: $builtin");
        return null;
    }
  }

  @override
  void invalidateCaches() {
  }
}
