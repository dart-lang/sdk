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

  void emitGetInterceptorMethod(CodeOutput output,
                                String key,
                                Set<ClassElement> classes) {
    InterceptorStubGenerator stubGenerator =
        new InterceptorStubGenerator(compiler, namer, backend);
    jsAst.Expression function =
        stubGenerator.generateGetInterceptorMethod(classes);

    output.addBuffer(jsAst.prettyPrint(
        js('${namer.globalObjectFor(backend.interceptorsLibrary)}.# = #',
           [key, function]),
        compiler));
    output.add(N);
  }

  /**
   * Emit all versions of the [:getInterceptor:] method.
   */
  void emitGetInterceptorMethods(CodeOutput output) {
    emitter.addComment('getInterceptor methods', output);
    Map<String, Set<ClassElement>> specializedGetInterceptors =
        backend.specializedGetInterceptors;
    for (String name in specializedGetInterceptors.keys.toList()..sort()) {
      Set<ClassElement> classes = specializedGetInterceptors[name];
      emitGetInterceptorMethod(output, name, classes);
    }
  }

  void emitOneShotInterceptors(CodeOutput output) {
    List<String> names = backend.oneShotInterceptors.keys.toList();
    names.sort();

    InterceptorStubGenerator stubGenerator =
        new InterceptorStubGenerator(compiler, namer, backend);
    String globalObject = namer.globalObjectFor(backend.interceptorsLibrary);
    for (String name in names) {
      jsAst.Expression function =
          stubGenerator.generateOneShotInterceptor(name);
      jsAst.Expression assignment =
          js('${globalObject}.# = #', [name, function]);

      output.addBuffer(jsAst.prettyPrint(assignment, compiler));
      output.add(N);
    }
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

    int index = 0;
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
   * Emit initializer for [mapTypeToInterceptor] data structure used by
   * [findInterceptorForType].  See declaration of [mapTypeToInterceptor] in
   * `interceptors.dart`.
   */
  void emitMapTypeToInterceptor(CodeOutput output) {
    // TODO(sra): Perhaps inject a constant instead?
    CustomElementsAnalysis analysis = backend.customElementsAnalysis;
    if (!analysis.needsTable) return;

    List<jsAst.Expression> elements = <jsAst.Expression>[];
    JavaScriptConstantCompiler handler = backend.constants;
    List<ConstantValue> constants =
        handler.getConstantsForEmission(emitter.compareConstants);
    for (ConstantValue constant in constants) {
      if (constant is TypeConstantValue) {
        TypeConstantValue typeConstant = constant;
        Element element = typeConstant.representedType.element;
        if (element is ClassElement) {
          ClassElement classElement = element;
          if (!analysis.needsClass(classElement)) continue;

          elements.add(emitter.constantReference(constant));
          elements.add(backend.emitter.interceptorClassAccess(classElement));

          // Create JavaScript Object map for by-name lookup of generative
          // constructors.  For example, the class A has three generative
          // constructors
          //
          //     class A {
          //       A() {}
          //       A.foo() {}
          //       A.bar() {}
          //     }
          //
          // Which are described by the map
          //
          //     {"": A.A$, "foo": A.A$foo, "bar": A.A$bar}
          //
          // We expect most of the time the map will be a singleton.
          var properties = [];
          for (Element member in analysis.constructors(classElement)) {
            properties.add(
                new jsAst.Property(
                    js.string(member.name),
                    backend.emitter.staticFunctionAccess(member)));
          }

          var map = new jsAst.ObjectInitializer(properties);
          elements.add(map);
        }
      }
    }

    jsAst.ArrayInitializer array = new jsAst.ArrayInitializer(elements);
    jsAst.Expression mapTypeToInterceptor = emitter
        .generateEmbeddedGlobalAccess(embeddedNames.MAP_TYPE_TO_INTERCEPTOR);
    jsAst.Expression assignment = js('# = #', [mapTypeToInterceptor, array]);

    output.addBuffer(jsAst.prettyPrint(assignment, compiler));
    output.add(N);
  }
}
