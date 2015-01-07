// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.new_js_emitter.emitter;

import '../model.dart';
import 'model_emitter.dart';
import '../../common.dart';
import '../../elements/elements.dart' show FieldElement;
import '../../js/js.dart' as js;

import '../../js_backend/js_backend.dart' show Namer, JavaScriptBackend;
import '../../js_emitter/js_emitter.dart' as emitterTask show
    CodeEmitterTask,
    Emitter;

class Emitter implements emitterTask.Emitter {
  final Compiler _compiler;
  final Namer namer;
  final ModelEmitter _emitter;

  Emitter(Compiler compiler, Namer namer)
      : this._compiler = compiler,
        this.namer = namer,
        _emitter = new ModelEmitter(compiler, namer);

  @override
  int emitProgram(Program program) {
    return _emitter.emitProgram(program);
  }

  // TODO(floitsch): copied from OldEmitter. Adjust or share.
  @override
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    if (constant.isFunction) return true;    // Already emitted.
    if (constant.isPrimitive) return true;   // Inlined.
    if (constant.isDummy) return true;       // Inlined.
    // The name is null when the constant is already a JS constant.
    // TODO(floitsch): every constant should be registered, so that we can
    // share the ones that take up too much space (like some strings).
    if (namer.constantName(constant) == null) return true;
    return false;
  }

  // TODO(floitsch): copied from OldEmitter. Adjust or share.
  @override
  int compareConstants(ConstantValue a, ConstantValue b) {
    // Inlined constants don't affect the order and sometimes don't even have
    // names.
    int cmp1 = isConstantInlinedOrAlreadyEmitted(a) ? 0 : 1;
    int cmp2 = isConstantInlinedOrAlreadyEmitted(b) ? 0 : 1;
    if (cmp1 + cmp2 < 2) return cmp1 - cmp2;

    // Emit constant interceptors first. Constant interceptors for primitives
    // might be used by code that builds other constants.  See Issue 18173.
    if (a.isInterceptor != b.isInterceptor) {
      return a.isInterceptor ? -1 : 1;
    }

    // Sorting by the long name clusters constants with the same constructor
    // which compresses a tiny bit better.
    int r = namer.constantLongName(a).compareTo(namer.constantLongName(b));
    if (r != 0) return r;
    // Resolve collisions in the long name by using the constant name (i.e. JS
    // name) which is unique.
    return namer.constantName(a).compareTo(namer.constantName(b));
  }

  @override
  js.Expression generateEmbeddedGlobalAccess(String global) {
    return _emitter.generateEmbeddedGlobalAccess(global);
  }

  @override
  js.Expression constantReference(ConstantValue value) {
    return _emitter.constantEmitter.reference(value);
  }

  js.PropertyAccess _globalPropertyAccess(Element element) {
     String name = namer.getNameX(element);
     js.PropertyAccess pa = new js.PropertyAccess.field(
         new js.VariableUse(namer.globalObjectFor(element)),
         name);
     return pa;
   }

  @override
  js.Expression isolateLazyInitializerAccess(FieldElement element) {
    return js.js('#.#', [namer.globalObjectFor(element),
                         namer.getLazyInitializerName(element)]);
  }

  @override
  js.Expression isolateStaticClosureAccess(FunctionElement element) {
    return js.js('#.#()',
        [namer.globalObjectFor(element), namer.getStaticClosureName(element)]);
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
  js.PropertyAccess interceptorClassAccess(ClassElement element) {
    // Interceptors are eagerly constructed. It's safe to just access them.
    return _globalPropertyAccess(element);
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
