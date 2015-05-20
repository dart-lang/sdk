// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class InterceptorEmitter extends CodeEmitterHelper {
  final Set<String> interceptorInvocationNames = new Set<String>();

  void recordMangledNameOfMemberMethod(FunctionElement member, String name) {
    if (backend.isInterceptedMethod(member)) {
      interceptorInvocationNames.add(name);
    }
  }

  jsAst.Expression buildGetInterceptorMethod(String key,
                                             Set<ClassElement> classes) {
    InterceptorStubGenerator stubGenerator =
        new InterceptorStubGenerator(compiler, namer, backend);
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

    Map<String, Set<ClassElement>> specializedGetInterceptors =
        backend.specializedGetInterceptors;
    for (String name in specializedGetInterceptors.keys.toList()..sort()) {
      Set<ClassElement> classes = specializedGetInterceptors[name];
      parts.add(
          js.statement('#.# = #',
                       [namer.globalObjectFor(backend.interceptorsLibrary),
                        name,
                        buildGetInterceptorMethod(name, classes)]));
    }

    return new jsAst.Block(parts);
  }

  jsAst.Statement buildOneShotInterceptors() {
    List<jsAst.Statement> parts = <jsAst.Statement>[];
    List<String> names = backend.oneShotInterceptors.keys.toList();
    names.sort();

    InterceptorStubGenerator stubGenerator =
        new InterceptorStubGenerator(compiler, namer, backend);
    String globalObject = namer.globalObjectFor(backend.interceptorsLibrary);
    for (String name in names) {
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
    if (!compiler.enabledInvokeOn) return null;

    List<String> invocationNames = interceptorInvocationNames.toList()..sort();
    List<jsAst.Property> properties =
        new List<jsAst.Property>(invocationNames.length);
    for (int i = 0; i < invocationNames.length; i++) {
      String name = invocationNames[i];
      properties[i] = new jsAst.Property(js.string(name), js.number(1));
    }
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
