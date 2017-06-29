// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.startup_emitter;

import 'package:js_runtime/shared/embedded_names.dart'
    show JsBuiltin, METADATA, STATIC_FUNCTION_NAME_TO_CLOSURE, TYPES;

import '../../common.dart';
import '../../compiler.dart' show Compiler;
import '../../constants/values.dart' show ConstantValue;
import '../../deferred_load.dart' show OutputUnit;
import '../../elements/elements.dart' show ClassElement, MethodElement;
import '../../elements/entities.dart';
import '../../js/js.dart' as js;
import '../../js_backend/js_backend.dart' show JavaScriptBackend, Namer;
import '../../world.dart' show ClosedWorld;
import '../js_emitter.dart' show CodeEmitterTask, NativeEmitter;
import '../js_emitter.dart' as emitterTask show EmitterBase, EmitterFactory;
import '../model.dart';
import '../program_builder/program_builder.dart' show ProgramBuilder;
import 'model_emitter.dart';

class EmitterFactory implements emitterTask.EmitterFactory {
  final bool generateSourceMap;

  EmitterFactory({this.generateSourceMap});

  @override
  bool get supportsReflection => false;

  @override
  Emitter createEmitter(
      CodeEmitterTask task, Namer namer, ClosedWorld closedWorld) {
    return new Emitter(task.compiler, namer, task.nativeEmitter, closedWorld,
        task, generateSourceMap);
  }
}

class Emitter extends emitterTask.EmitterBase {
  final Compiler _compiler;
  final ClosedWorld _closedWorld;
  final Namer namer;
  final ModelEmitter _emitter;

  JavaScriptBackend get _backend => _compiler.backend;

  Emitter(this._compiler, this.namer, NativeEmitter nativeEmitter,
      this._closedWorld, CodeEmitterTask task, bool shouldGenerateSourceMap)
      : _emitter = new ModelEmitter(_compiler, namer, nativeEmitter,
            _closedWorld, task, shouldGenerateSourceMap);

  DiagnosticReporter get reporter => _compiler.reporter;

  @override
  int emitProgram(ProgramBuilder programBuilder) {
    Program program = programForTesting = programBuilder.buildProgram();
    return _emitter.emitProgram(program);
  }

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

  @override
  js.Expression isolateLazyInitializerAccess(FieldEntity element) {
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
  js.Template templateForBuiltin(JsBuiltin builtin) {
    String typeNameProperty = ModelEmitter.typeNameProperty;

    switch (builtin) {
      case JsBuiltin.dartObjectConstructor:
        ClassElement objectClass = _closedWorld.commonElements.objectClass;
        return js.js.expressionTemplateYielding(typeAccess(objectClass));

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
        String typesAccess = _emitter.generateEmbeddedGlobalAccessString(TYPES);
        return js.js.expressionTemplateFor("$typesAccess[#]");

      case JsBuiltin.createDartClosureFromNameOfStaticFunction:
        String functionAccess = _emitter.generateEmbeddedGlobalAccessString(
            STATIC_FUNCTION_NAME_TO_CLOSURE);
        return js.js.expressionTemplateFor("$functionAccess(#)");

      default:
        reporter.internalError(
            NO_LOCATION_SPANNABLE, "Unhandled Builtin: $builtin");
        return null;
    }
  }

  @override
  int generatedSize(OutputUnit unit) {
    Fragment key = _emitter.outputBuffers.keys
        .firstWhere((Fragment fragment) => fragment.outputUnit == unit);
    return _emitter.outputBuffers[key].length;
  }
}
