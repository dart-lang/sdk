// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.lazy_emitter;

import 'package:js_runtime/shared/embedded_names.dart' show JsBuiltin;

import '../../common.dart';
import '../../compiler.dart' show Compiler;
import '../../constants/values.dart' show ConstantValue;
import '../../deferred_load.dart' show OutputUnit;
import '../../elements/elements.dart'
    show ClassElement, FieldElement, MethodElement;
import '../../elements/entities.dart';
import '../../js/js.dart' as js;
import '../../js_backend/js_backend.dart' show JavaScriptBackend, Namer;
import '../../world.dart' show ClosedWorld;
import '../js_emitter.dart' show CodeEmitterTask, NativeEmitter;
import '../js_emitter.dart' as emitterTask show EmitterBase, EmitterFactory;
import '../model.dart';
import '../program_builder/program_builder.dart' show ProgramBuilder;
import '../sorter.dart' show Sorter;
import 'model_emitter.dart';

class EmitterFactory implements emitterTask.EmitterFactory {
  @override
  bool get supportsReflection => false;

  @override
  Emitter createEmitter(CodeEmitterTask task, Namer namer,
      ClosedWorld closedWorld, Sorter sorter) {
    return new Emitter(
        task.compiler, namer, task.nativeEmitter, closedWorld, sorter, task);
  }
}

class Emitter extends emitterTask.EmitterBase {
  final Compiler _compiler;
  final ClosedWorld _closedWorld;
  final Namer namer;
  final ModelEmitter _emitter;

  JavaScriptBackend get _backend => _compiler.backend;

  Emitter(this._compiler, this.namer, NativeEmitter nativeEmitter,
      this._closedWorld, Sorter sorter, CodeEmitterTask task)
      : _emitter = new ModelEmitter(
            _compiler, namer, nativeEmitter, _closedWorld, sorter, task);

  DiagnosticReporter get reporter => _compiler.reporter;

  @override
  int emitProgram(ProgramBuilder programBuilder) {
    Program program = programForTesting = programBuilder.buildProgram();
    return _emitter.emitProgram(program);
  }

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

  @override
  js.Expression isolateLazyInitializerAccess(FieldElement element) {
    return js.js('#.#', [
      namer.globalObjectForMember(element),
      namer.lazyInitializerName(element)
    ]);
  }

  @override
  js.Expression isolateStaticClosureAccess(MethodElement element) {
    return _emitter.generateStaticClosureAccess(element);
  }

  @override
  js.PropertyAccess prototypeAccess(
      ClassElement element, bool hasBeenInstantiated) {
    js.Expression constructor =
        hasBeenInstantiated ? constructorAccess(element) : typeAccess(element);
    return js.js('#.prototype', constructor);
  }

  @override
  js.Expression interceptorClassAccess(ClassEntity element) {
    // Some interceptors are eagerly constructed. However, native interceptors
    // aren't.
    return js.js('#.ensureResolved()', globalPropertyAccessForClass(element));
  }

  @override
  js.Expression typeAccess(Entity element) {
    // TODO(floitsch): minify 'ensureResolved'.
    // TODO(floitsch): don't emit `ensureResolved` for eager classes.
    return js.js('#.ensureResolved()', globalPropertyAccessForType(element));
  }

  @override
  js.Template templateForBuiltin(JsBuiltin builtin) {
    String typeNameProperty = ModelEmitter.typeNameProperty;

    switch (builtin) {
      case JsBuiltin.dartObjectConstructor:
        return js.js.expressionTemplateYielding(
            typeAccess(_closedWorld.commonElements.objectClass));

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
        return _emitter.templateForReadMetadata;

      case JsBuiltin.getType:
        return _emitter.templateForReadType;

      case JsBuiltin.createDartClosureFromNameOfStaticFunction:
        throw new UnsupportedError('createDartClosureFromNameOfStaticFunction');

      default:
        reporter.internalError(
            NO_LOCATION_SPANNABLE, "Unhandled Builtin: $builtin");
        return null;
    }
  }

  @override
  // TODO(het): Generate this correctly
  int generatedSize(OutputUnit unit) => 0;
}
