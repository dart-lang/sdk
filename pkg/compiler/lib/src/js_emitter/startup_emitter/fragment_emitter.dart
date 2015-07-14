// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.startup_emitter.model_emitter;

/**
 * This class builds a JavaScript tree for a given fragment.
 *
 * A fragment is generally written into a separate file so that it can be
 * loaded dynamically when a deferred library is loaded.
 *
 * This class is stateless and can be reused for different fragments.
 */
class FragmentEmitter {
  final Compiler compiler;
  final Namer namer;
  final JavaScriptBackend backend;
  final ConstantEmitter constantEmitter;
  final ModelEmitter modelEmitter;

  FragmentEmitter(this.compiler, this.namer, this.backend, this.constantEmitter,
      this.modelEmitter);

  js.Expression generateEmbeddedGlobalAccess(String global) =>
      modelEmitter.generateEmbeddedGlobalAccess(global);

  js.Expression generateConstantReference(ConstantValue value) =>
      modelEmitter.generateConstantReference(value);

  js.Statement emitMainFragment(Program program) {
    MainFragment fragment = program.fragments.first;
    throw new UnimplementedError('emitMain');
  }

  js.Statement emitDeferredFragment(DeferredFragment fragment,
                                    js.Expression deferredTypes,
                                    List<Holder> holders) {
    throw new UnimplementedError('emitDeferred');
  }
}