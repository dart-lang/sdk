// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.full_emitter.interceptor_emitter;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;
import '../../elements/entities.dart';
import '../../js/js.dart' as jsAst;
import '../../js/js.dart' show js;
import '../../world.dart' show ClosedWorld;
import '../js_emitter.dart' hide Emitter, EmitterFactory;
import '../model.dart';
import 'emitter.dart';

class InterceptorEmitter extends CodeEmitterHelper {
  final ClosedWorld closedWorld;
  final Set<jsAst.Name> interceptorInvocationNames = new Set<jsAst.Name>();

  InterceptorEmitter(this.closedWorld);

  void recordMangledNameOfMemberMethod(MemberEntity member, jsAst.Name name) {
    if (closedWorld.interceptorData.isInterceptedMethod(member)) {
      interceptorInvocationNames.add(name);
    }
  }

  jsAst.Expression buildGetInterceptorMethod(
      jsAst.Name key, Set<ClassEntity> classes) {
    InterceptorStubGenerator stubGenerator = new InterceptorStubGenerator(
        compiler.options,
        compiler.commonElements,
        backend.emitter,
        backend.nativeCodegenEnqueuer,
        backend.constants,
        namer,
        backend.oneShotInterceptorData,
        backend.customElementsCodegenAnalysis,
        compiler.codegenWorldBuilder,
        closedWorld);
    jsAst.Expression function =
        stubGenerator.generateGetInterceptorMethod(classes);

    return function;
  }

  /**
   * Emit all versions of the [:getInterceptor:] method.
   */
  jsAst.Statement buildGetInterceptorMethods() {
    List<jsAst.Statement> parts = <jsAst.Statement>[];

    parts.add(js.comment('getInterceptor methods'));

    Iterable<jsAst.Name> names =
        backend.oneShotInterceptorData.specializedGetInterceptorNames;
    for (jsAst.Name name in names) {
      Set<ClassEntity> classes =
          backend.oneShotInterceptorData.getSpecializedGetInterceptorsFor(name);
      parts.add(js.statement('#.# = #', [
        namer
            .globalObjectForLibrary(backend.commonElements.interceptorsLibrary),
        name,
        buildGetInterceptorMethod(name, classes)
      ]));
    }

    return new jsAst.Block(parts);
  }

  jsAst.Statement buildOneShotInterceptors() {
    List<jsAst.Statement> parts = <jsAst.Statement>[];
    Iterable<jsAst.Name> names =
        backend.oneShotInterceptorData.oneShotInterceptorNames;

    InterceptorStubGenerator stubGenerator = new InterceptorStubGenerator(
        compiler.options,
        compiler.commonElements,
        backend.emitter,
        backend.nativeCodegenEnqueuer,
        backend.constants,
        namer,
        backend.oneShotInterceptorData,
        backend.customElementsCodegenAnalysis,
        compiler.codegenWorldBuilder,
        closedWorld);
    String globalObject = namer
        .globalObjectForLibrary(backend.commonElements.interceptorsLibrary);
    for (jsAst.Name name in names) {
      jsAst.Expression function =
          stubGenerator.generateOneShotInterceptor(name);
      parts.add(js.statement('${globalObject}.# = #', [name, function]));
    }

    return new jsAst.Block(parts);
  }

  /**
   * If [JSInvocationMirror._invokeOn] has been compiled, emit all the
   * possible selector names that are intercepted into the
   * [interceptedNames] embedded global. The implementation of
   * [_invokeOn] will use it to determine whether it should call the
   * method with an extra parameter.
   */
  jsAst.ObjectInitializer generateInterceptedNamesSet() {
    // We could also generate the list of intercepted names at
    // runtime, by running through the subclasses of Interceptor
    // (which can easily be identified).
    if (!closedWorld.backendUsage.isInvokeOnUsed) return null;

    Iterable<jsAst.Name> invocationNames = interceptorInvocationNames.toList()
      ..sort();
    ;
    List<jsAst.Property> properties = invocationNames.map((jsAst.Name name) {
      return new jsAst.Property(js.quoteName(name), js.number(1));
    }).toList();
    return new jsAst.ObjectInitializer(properties, isOneLiner: true);
  }

  /**
   * Emit initializer for `typeToInterceptorMap` data structure used by
   * `findInterceptorForType`.  See declaration of `typeToInterceptor` in
   * `interceptors.dart`.
   */
  jsAst.Statement buildTypeToInterceptorMap(Program program) {
    jsAst.Expression array = program.typeToInterceptorMap;
    if (array == null) return js.comment("Empty type-to-interceptor map.");

    jsAst.Expression typeToInterceptorMap = emitter
        .generateEmbeddedGlobalAccess(embeddedNames.TYPE_TO_INTERCEPTOR_MAP);
    return js.statement('# = #', [typeToInterceptorMap, array]);
  }
}
