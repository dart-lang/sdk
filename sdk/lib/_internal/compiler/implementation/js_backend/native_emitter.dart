// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class NativeEmitter {

  final Map<Element, ClassBuilder> cachedBuilders;

  final CodeEmitterTask emitter;
  CodeBuffer nativeBuffer;

  // Native classes found in the application.
  Set<ClassElement> nativeClasses = new Set<ClassElement>();

  // Caches the native subtypes of a native class.
  Map<ClassElement, List<ClassElement>> subtypes;

  // Caches the direct native subtypes of a native class.
  Map<ClassElement, List<ClassElement>> directSubtypes;

  // Caches the methods that have a native body.
  Set<FunctionElement> nativeMethods;

  // Do we need the native emitter to take care of handling
  // noSuchMethod for us? This flag is set to true in the emitter if
  // it finds any native class that needs noSuchMethod handling.
  bool handleNoSuchMethod = false;

  NativeEmitter(CodeEmitterTask emitter)
      : this.emitter = emitter,
        subtypes = new Map<ClassElement, List<ClassElement>>(),
        directSubtypes = new Map<ClassElement, List<ClassElement>>(),
        nativeMethods = new Set<FunctionElement>(),
        nativeBuffer = new CodeBuffer(),
        cachedBuilders = emitter.compiler.cacheStrategy.newMap();

  Compiler get compiler => emitter.compiler;
  JavaScriptBackend get backend => compiler.backend;

  String get _ => emitter.space;
  String get n => emitter.n;
  String get N => emitter.N;

  jsAst.Expression get defPropFunction {
    Element element = backend.findHelper('defineProperty');
    return backend.namer.elementAccess(element);
  }

  /**
   * Writes the class definitions for the interceptors to [mainBuffer].
   * Writes code to associate dispatch tags with interceptors to [nativeBuffer].
   *
   * The interceptors are filtered to avoid emitting trivial interceptors.  For
   * example, if the program contains no code that can distinguish between the
   * numerous subclasses of `Element` then we can pretend that `Element` is a
   * leaf class, and all instances of subclasses of `Element` are instances of
   * `Element`.
   *
   * There is also a performance benefit (in addition to the obvious code size
   * benefit), due to how [getNativeInterceptor] works.  Finding the interceptor
   * of a leaf class in the hierarchy is more efficient that a non-leaf, so it
   * improves performance when more classes can be treated as leaves.
   *
   * [classes] contains native classes, mixin applications, and user subclasses
   * of native classes.  ONLY the native classes are generated here.  [classes]
   * is sorted in desired output order.
   *
   * [additionalProperties] is used to collect properties that are pushed up
   * from the above optimizations onto a non-native class, e.g, `Interceptor`.
   */
  void generateNativeClasses(
      List<ClassElement> classes,
      CodeBuffer mainBuffer,
      Map<ClassElement, Map<String, jsAst.Expression>> additionalProperties) {
    // Compute a pre-order traversal of the subclass forest.  We actually want a
    // post-order traversal but it is easier to compute the pre-order and use it
    // in reverse.

    List<ClassElement> preOrder = <ClassElement>[];
    Set<ClassElement> seen = new Set<ClassElement>();
    seen..add(compiler.objectClass)
        ..add(backend.jsInterceptorClass);
    void walk(ClassElement element) {
      if (seen.contains(element)) return;
      seen.add(element);
      walk(element.superclass);
      preOrder.add(element);
    }
    classes.forEach(walk);

    // Generate code for each native class into [ClassBuilder]s.

    Map<ClassElement, ClassBuilder> builders =
        new Map<ClassElement, ClassBuilder>();
    for (ClassElement classElement in classes) {
      if (classElement.isNative) {
        ClassBuilder builder = generateNativeClass(classElement);
        builders[classElement] = builder;
      }
    }

    // Find which classes are needed and which are non-leaf classes.  Any class
    // that is not needed can be treated as a leaf class equivalent to some
    // needed class.

    Set<ClassElement> neededClasses = new Set<ClassElement>();
    Set<ClassElement> nonleafClasses = new Set<ClassElement>();

    Map<ClassElement, List<ClassElement>> extensionPoints =
        computeExtensionPoints(preOrder);

    neededClasses.add(compiler.objectClass);

    Set<ClassElement> neededByConstant =
        emitter.interceptorEmitter.interceptorsReferencedFromConstants();
    Set<ClassElement> modifiedClasses =
        emitter.typeTestEmitter.classesModifiedByEmitRuntimeTypeSupport();

    for (ClassElement classElement in preOrder.reversed) {
      // Post-order traversal ensures we visit the subclasses before their
      // superclass.  This makes it easy to tell if a class is needed because a
      // subclass is needed.
      ClassBuilder builder = builders[classElement];
      bool needed = false;
      if (builder == null) {
        // Mixin applications (native+mixin) are non-native, so [classElement]
        // has already been emitted as a regular class.  Mark [classElement] as
        // 'needed' to ensure the native superclass is needed.
        needed = true;
      } else if (!builder.isTrivial) {
        needed = true;
      } else if (neededByConstant.contains(classElement)) {
        needed = true;
      } else if (modifiedClasses.contains(classElement)) {
        // TODO(9556): Remove this test when [emitRuntimeTypeSupport] no longer
        // adds information to a class prototype or constructor.
        needed = true;
      } else if (extensionPoints.containsKey(classElement)) {
        needed = true;
      }
      if (classElement.isNative &&
          native.nativeTagsForcedNonLeaf(classElement)) {
        needed = true;
        nonleafClasses.add(classElement);
      }

      if (needed || neededClasses.contains(classElement)) {
        neededClasses.add(classElement);
        neededClasses.add(classElement.superclass);
        nonleafClasses.add(classElement.superclass);
      }
    }

    // Collect all the tags that map to each native class.

    Map<ClassElement, Set<String>> leafTags =
        new Map<ClassElement, Set<String>>();
    Map<ClassElement, Set<String>> nonleafTags =
        new Map<ClassElement, Set<String>>();

    for (ClassElement classElement in classes) {
      if (!classElement.isNative) continue;
      List<String> nativeTags = native.nativeTagsOfClass(classElement);

      if (nonleafClasses.contains(classElement) ||
          extensionPoints.containsKey(classElement)) {
        nonleafTags
            .putIfAbsent(classElement, () => new Set<String>())
            .addAll(nativeTags);
      } else {
        ClassElement sufficingInterceptor = classElement;
        while (!neededClasses.contains(sufficingInterceptor)) {
          sufficingInterceptor = sufficingInterceptor.superclass;
        }
        if (sufficingInterceptor == compiler.objectClass) {
          sufficingInterceptor = backend.jsInterceptorClass;
        }
        leafTags
            .putIfAbsent(sufficingInterceptor, () => new Set<String>())
            .addAll(nativeTags);
      }
    }

    // Add properties containing the information needed to construct maps used
    // by getNativeInterceptor and custom elements.
    if (compiler.enqueuer.codegen.nativeEnqueuer
        .hasInstantiatedNativeClasses()) {
      void generateClassInfo(ClassElement classElement) {
        // Property has the form:
        //
        //    "%": "leafTag1|leafTag2|...;nonleafTag1|...;Class1|Class2|...",
        //
        // If there is no data following a semicolon, the semicolon can be
        // omitted.

        String formatTags(Iterable<String> tags) {
          if (tags == null) return '';
          return (tags.toList()..sort()).join('|');
        }

        List<ClassElement> extensions = extensionPoints[classElement];

        String leafStr = formatTags(leafTags[classElement]);
        String nonleafStr = formatTags(nonleafTags[classElement]);

        StringBuffer sb = new StringBuffer(leafStr);
        if (nonleafStr != '') {
          sb..write(';')..write(nonleafStr);
        }
        if (extensions != null) {
          sb..write(';')
            ..writeAll(extensions.map(backend.namer.getNameOfClass), '|');
        }
        String encoding = sb.toString();

        ClassBuilder builder = builders[classElement];
        if (builder == null) {
          // No builder because this is an intermediate mixin application or
          // Interceptor - these are not direct native classes.
          if (encoding != '') {
            Map<String, jsAst.Expression> properties =
                additionalProperties.putIfAbsent(classElement,
                    () => new LinkedHashMap<String, jsAst.Expression>());
            properties[backend.namer.nativeSpecProperty] = js.string(encoding);
          }
        } else {
          builder.addProperty(
              backend.namer.nativeSpecProperty, js.string(encoding));
        }
      }
      generateClassInfo(backend.jsInterceptorClass);
      for (ClassElement classElement in classes) {
        generateClassInfo(classElement);
      }
    }

    // Emit the native class interceptors that were actually used.
    for (ClassElement classElement in classes) {
      if (!classElement.isNative) continue;
      if (neededClasses.contains(classElement)) {
        // Define interceptor class for [classElement].
        emitter.classEmitter.emitClassBuilderWithReflectionData(
            backend.namer.getNameOfClass(classElement),
            classElement, builders[classElement],
            emitter.getElementDecriptor(classElement));
        emitter.needsDefineClass = true;
      }
    }
  }

  /**
   * Computes the native classes that are extended (subclassed) by non-native
   * classes and the set non-mative classes that extend them.  (A List is used
   * instead of a Set for out stability).
   */
  Map<ClassElement, List<ClassElement>> computeExtensionPoints(
      List<ClassElement> classes) {
    ClassElement nativeSuperclassOf(ClassElement element) {
      if (element == null) return null;
      if (element.isNative) return element;
      return nativeSuperclassOf(element.superclass);
    }

    ClassElement nativeAncestorOf(ClassElement element) {
      return nativeSuperclassOf(element.superclass);
    }

    Map<ClassElement, List<ClassElement>> map =
        new Map<ClassElement, List<ClassElement>>();

    for (ClassElement classElement in classes) {
      if (classElement.isNative) continue;
      ClassElement nativeAncestor = nativeAncestorOf(classElement);
      if (nativeAncestor != null) {
        map
          .putIfAbsent(nativeAncestor, () => <ClassElement>[])
          .add(classElement);
      }
    }
    return map;
  }

  ClassBuilder generateNativeClass(ClassElement classElement) {
    ClassBuilder builder;
    if (compiler.hasIncrementalSupport) {
      builder = cachedBuilders[classElement];
      if (builder != null) return builder;
      builder = new ClassBuilder(backend.namer);
      cachedBuilders[classElement] = builder;
    } else {
      builder = new ClassBuilder(backend.namer);
    }

    // TODO(sra): Issue #13731- this is commented out as part of custom element
    // constructor work.
    //assert(!classElement.hasBackendMembers);
    nativeClasses.add(classElement);

    ClassElement superclass = classElement.superclass;
    assert(superclass != null);
    // Fix superclass.  TODO(sra): make native classes inherit from Interceptor.
    assert(superclass != compiler.objectClass);
    if (superclass == compiler.objectClass) {
      superclass = backend.jsInterceptorClass;
    }

    String superName = backend.namer.getNameOfClass(superclass);

    emitter.classEmitter.emitClassConstructor(classElement, builder);
    bool hasFields = emitter.classEmitter.emitFields(
        classElement, builder, superName, classIsNative: true);
    int propertyCount = builder.properties.length;
    emitter.classEmitter.emitClassGettersSetters(classElement, builder);
    emitter.classEmitter.emitInstanceMembers(classElement, builder);
    emitter.typeTestEmitter.emitIsTests(classElement, builder);

    if (!hasFields &&
        builder.properties.length == propertyCount &&
        superclass is! MixinApplicationElement) {
      builder.isTrivial = true;
    }

    return builder;
  }

  void finishGenerateNativeClasses() {
    // TODO(sra): Put specialized version of getNativeMethods on
    // `Object.prototype` to avoid checking in `getInterceptor` and
    // specializations.
  }

  void potentiallyConvertDartClosuresToJs(
      List<jsAst.Statement> statements,
      FunctionElement member,
      List<jsAst.Parameter> stubParameters) {
    FunctionSignature parameters = member.functionSignature;
    Element converter = backend.findHelper('convertDartClosureToJS');
    jsAst.Expression closureConverter = backend.namer.elementAccess(converter);
    parameters.forEachParameter((ParameterElement parameter) {
      String name = parameter.name;
      // If [name] is not in [stubParameters], then the parameter is an optional
      // parameter that was not provided for this stub.
      for (jsAst.Parameter stubParameter in stubParameters) {
        if (stubParameter.name == name) {
          DartType type = parameter.type.unalias(compiler);
          if (type is FunctionType) {
            // The parameter type is a function type either directly or through
            // typedef(s).
            FunctionType functionType = type;
            int arity = functionType.computeArity();
            statements.add(
                js.statement('# = #(#, $arity)',
                    [name, closureConverter, name]));
            break;
          }
        }
      }
    });
  }

  List<jsAst.Statement> generateParameterStubStatements(
      FunctionElement member,
      bool isInterceptedMethod,
      String invocationName,
      List<jsAst.Parameter> stubParameters,
      List<jsAst.Expression> argumentsBuffer,
      int indexOfLastOptionalArgumentInParameters) {
    // The target JS function may check arguments.length so we need to
    // make sure not to pass any unspecified optional arguments to it.
    // For example, for the following Dart method:
    //   foo([x, y, z]);
    // The call:
    //   foo(y: 1)
    // must be turned into a JS call to:
    //   foo(null, y).

    ClassElement classElement = member.enclosingClass;

    List<jsAst.Statement> statements = <jsAst.Statement>[];
    potentiallyConvertDartClosuresToJs(statements, member, stubParameters);

    String target;
    jsAst.Expression receiver;
    List<jsAst.Expression> arguments;

    assert(invariant(member, nativeMethods.contains(member)));
    // When calling a JS method, we call it with the native name, and only the
    // arguments up until the last one provided.
    target = member.fixedBackendName;

    if (isInterceptedMethod) {
      receiver = argumentsBuffer[0];
      arguments = argumentsBuffer.sublist(1,
          indexOfLastOptionalArgumentInParameters + 1);
    } else {
      receiver = js('this');
      arguments = argumentsBuffer.sublist(0,
          indexOfLastOptionalArgumentInParameters + 1);
    }
    statements.add(
        js.statement('return #.#(#)', [receiver, target, arguments]));

    return statements;
  }

  bool isSupertypeOfNativeClass(Element element) {
    if (element.isTypeVariable) {
      compiler.internalError(element, "Is check for type variable.");
      return false;
    }
    if (element.computeType(compiler).unalias(compiler) is FunctionType) {
      // The element type is a function type either directly or through
      // typedef(s).
      return false;
    }

    if (!element.isClass) {
      compiler.internalError(element, "Is check does not handle element.");
      return false;
    }

    if (backend.classesMixedIntoInterceptedClasses.contains(element)) {
      return true;
    }

    return subtypes[element] != null;
  }

  bool requiresNativeIsCheck(Element element) {
    // TODO(sra): Remove this function.  It determines if a native type may
    // satisfy a check against [element], in which case an interceptor must be
    // used.  We should also use an interceptor if the check can't be satisfied
    // by a native class in case we get a native instance that tries to spoof
    // the type info.  i.e the criteria for whether or not to use an interceptor
    // is whether the receiver can be native, not the type of the test.
    if (element == null || !element.isClass) return false;
    ClassElement cls = element;
    if (Elements.isNativeOrExtendsNative(cls)) return true;
    return isSupertypeOfNativeClass(element);
  }

  void assembleCode(CodeBuffer targetBuffer) {
    List<jsAst.Property> objectProperties = <jsAst.Property>[];

    void addProperty(String name, jsAst.Expression value) {
      objectProperties.add(new jsAst.Property(js.string(name), value));
    }

    if (!nativeClasses.isEmpty) {
      // If the native emitter has been asked to take care of the
      // noSuchMethod handlers, we do that now.
      if (handleNoSuchMethod) {
        emitter.nsmEmitter.emitNoSuchMethodHandlers(addProperty);
      }
    }

    // If we have any properties to add to Object.prototype, we run
    // through them and add them using defineProperty.
    if (!objectProperties.isEmpty) {
      jsAst.Expression init = js(r'''
          (function(table) {
            for(var key in table)
              #(Object.prototype, key, table[key]);
           })(#)''',
          [ defPropFunction,
            new jsAst.ObjectInitializer(objectProperties)]);

      if (emitter.compiler.enableMinification) targetBuffer.add(';');
      targetBuffer.add(jsAst.prettyPrint(
          new jsAst.ExpressionStatement(init), compiler));
      targetBuffer.add('\n');
    }

    targetBuffer.add(nativeBuffer);
    targetBuffer.add('\n');
  }
}
