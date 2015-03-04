// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.emitter;

import '../program_builder.dart' show ProgramBuilder;
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

class Emitter implements emitterTask.Emitter {
  final Compiler _compiler;
  final Namer namer;
  final ModelEmitter _emitter;

  Emitter(Compiler compiler, Namer namer, NativeEmitter nativeEmitter)
      : this._compiler = compiler,
        this.namer = namer,
        _emitter = new ModelEmitter(compiler, namer, nativeEmitter);

  @override
  int emitProgram(ProgramBuilder programBuilder) {
    Program program = programBuilder.buildProgram();
    return _emitter.emitProgram(program);
  }

  // TODO(floitsch): copied from OldEmitter. Adjust or share.
  @override
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    return _emitter.isConstantInlinedOrAlreadyEmitted(constant);
  }

  // TODO(floitsch): copied from OldEmitter. Adjust or share.
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
     String name = namer.globalPropertyName(element);
     js.PropertyAccess pa = new js.PropertyAccess.field(
         new js.VariableUse(namer.globalObjectFor(element)),
         name);
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
  void invalidateCaches() {}
}
