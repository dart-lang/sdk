// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class NativeEmitter {

  CodeEmitterTask emitter;
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

  NativeEmitter(this.emitter)
      : subtypes = new Map<ClassElement, List<ClassElement>>(),
        directSubtypes = new Map<ClassElement, List<ClassElement>>(),
        nativeMethods = new Set<FunctionElement>(),
        nativeBuffer = new CodeBuffer();

  Compiler get compiler => emitter.compiler;
  JavaScriptBackend get backend => compiler.backend;

  String get _ => emitter._;
  String get n => emitter.n;
  String get N => emitter.N;

  String get dynamicName {
    Element element = compiler.findHelper(
        const SourceString('dynamicFunction'));
    return backend.namer.isolateAccess(element);
  }

  String get dynamicFunctionTableName {
    Element element = compiler.findHelper(
        const SourceString('dynamicFunctionTable'));
    return backend.namer.isolateAccess(element);
  }

  String get typeNameOfName {
    Element element = compiler.findHelper(
        const SourceString('getTypeNameOf'));
    return backend.namer.isolateAccess(element);
  }

  String get defPropName {
    Element element = compiler.findHelper(
        const SourceString('defineProperty'));
    return backend.namer.isolateAccess(element);
  }

  String get toStringHelperName {
    Element element = compiler.findHelper(
        const SourceString('toStringForNativeObject'));
    return backend.namer.isolateAccess(element);
  }

  String get hashCodeHelperName {
    Element element = compiler.findHelper(
        const SourceString('hashCodeForNativeObject'));
    return backend.namer.isolateAccess(element);
  }

  String get dispatchPropertyNameVariable {
    Element element = compiler.findInterceptor(
        const SourceString('dispatchPropertyName'));
    return backend.namer.isolateAccess(element);
  }

  String get defineNativeMethodsName {
    Element element = compiler.findHelper(
        const SourceString('defineNativeMethods'));
    return backend.namer.isolateAccess(element);
  }

  String get defineNativeMethodsNonleafName {
    Element element = compiler.findHelper(
        const SourceString('defineNativeMethodsNonleaf'));
    return backend.namer.isolateAccess(element);
  }

  String get defineNativeMethodsFinishName {
    Element element = compiler.findHelper(
        const SourceString('defineNativeMethodsFinish'));
    return backend.namer.isolateAccess(element);
  }

  bool isNativeGlobal(String quotedName) {
    return identical(quotedName[1], '@');
  }

  String toNativeTag(ClassElement cls) {
    String quotedName = cls.nativeTagInfo.slowToString();
    if (isNativeGlobal(quotedName)) {
      // Global object, just be like the other types for now.
      return quotedName.substring(3, quotedName.length - 1);
    } else {
      return quotedName.substring(2, quotedName.length - 1);
    }
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
   */
  void generateNativeClasses(List<ClassElement> classes,
                             CodeBuffer mainBuffer) {
    // Compute a pre-order traversal of the subclass forest.  We actually want a
    // post-order traversal but it is easier to compute the pre-order and use it
    // in reverse.

    List<ClassElement> preOrder = <ClassElement>[];
    Set<ClassElement> seen = new Set<ClassElement>();
    void walk(ClassElement element) {
      if (seen.contains(element) || element == compiler.objectClass) return;
      seen.add(element);
      walk(element.superclass);
      preOrder.add(element);
    }
    classes.forEach(walk);

    // Generate code for each native class into [ClassBuilder]s.

    Map<ClassElement, ClassBuilder> builders =
        new Map<ClassElement, ClassBuilder>();
    for (ClassElement classElement in classes) {
      ClassBuilder builder = generateNativeClass(classElement);
      builders[classElement] = builder;
    }

    // Find which classes are needed and which are non-leaf classes.  Any class
    // that is not needed can be treated as a leaf class equivalent to some
    // needed class.

    Set<ClassElement> neededClasses = new Set<ClassElement>();
    Set<ClassElement> nonleafClasses = new Set<ClassElement>();
    neededClasses.add(compiler.objectClass);

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
      } else {
        // TODO(9556): We can't remove any unneeded classes until the class
        // builders contain all the information.  [emitRuntimeTypeSupport] must
        // no longer add information to a class definition.
        needed = true;
      }

      // BUG.  There is a missing proto in the picture the DOM gives of the
      // proto chain.
      // TODO(9907): Fix DOM generation. We might need an annotation.
      if (classElement.isNative()) {
        String nativeTag = toNativeTag(classElement);
        if (nativeTag == 'HTMLElement') {
          nonleafClasses.add(classElement);
          needed = true;
        }
      }

      if (needed || neededClasses.contains(classElement)) {
        neededClasses.add(classElement);
        neededClasses.add(classElement.superclass);
        nonleafClasses.add(classElement.superclass);
      }
    }

    // Collect all the tags that map to each class.

    Map<ClassElement, Set<String>> leafTags =
        new Map<ClassElement, Set<String>>();
    Map<ClassElement, Set<String>> nonleafTags =
        new Map<ClassElement, Set<String>>();

    for (ClassElement classElement in classes) {
      String nativeTag = toNativeTag(classElement);

      if (nonleafClasses.contains(classElement)) {
        nonleafTags
            .putIfAbsent(classElement, () => new Set<String>())
            .add(nativeTag);
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
            .add(nativeTag);
      }
    }

    // Emit code to set up dispatch data that maps tags to the interceptors.

    void generateDefines(ClassElement classElement) {
      generateDefineNativeMethods(leafTags[classElement], classElement,
          defineNativeMethodsName);
      generateDefineNativeMethods(nonleafTags[classElement], classElement,
          defineNativeMethodsNonleafName);
    }
    generateDefines(backend.jsInterceptorClass);
    for (ClassElement classElement in classes) {
      generateDefines(classElement);
    }

    // Emit the native class interceptors that were actually used.

    for (ClassElement classElement in classes) {
      if (neededClasses.contains(classElement)) {
        ClassBuilder builder = builders[classElement];
        // Define interceptor class for [classElement].
        String className = backend.namer.getName(classElement);
        jsAst.Expression init =
            js(emitter.classesCollector)[className].assign(
                builder.toObjectInitializer());
        mainBuffer.write(jsAst.prettyPrint(init, compiler));
        mainBuffer.write('$N$n');
        emitter.needsDefineClass = true;
      }
    }
  }

  ClassBuilder generateNativeClass(ClassElement classElement) {
    assert(!classElement.hasBackendMembers);
    nativeClasses.add(classElement);

    ClassElement superclass = classElement.superclass;
    assert(superclass != null);
    // Fix superclass.  TODO(sra): make native classes inherit from Interceptor.
    if (superclass == compiler.objectClass) {
      superclass = backend.jsInterceptorClass;
    }

    String superName = backend.namer.getName(superclass);

    ClassBuilder builder = new ClassBuilder();
    emitter.emitClassConstructor(classElement, builder);
    emitter.emitSuper(superName, builder);
    bool hasFields = emitter.emitClassFields(classElement, builder,
        classIsNative: true,
        superClass: superName);
    int propertyCount = builder.properties.length;
    emitter.emitClassGettersSetters(classElement, builder);
    emitter.emitInstanceMembers(classElement, builder);

    if (!hasFields && builder.properties.length == propertyCount) {
      builder.isTrivial = true;
    }

    return builder;
  }

  void generateDefineNativeMethods(
      Set<String> tags, ClassElement classElement, String definer) {
    if (tags == null) return;

    String tagsString = (tags.toList()..sort()).join('|');
    jsAst.Expression definition =
        js(definer)(
            [js.string(tagsString),
             js(backend.namer.isolateAccess(classElement))]);

    nativeBuffer.add(jsAst.prettyPrint(definition, compiler));
    nativeBuffer.add('$N$n');
  }


  void finishGenerateNativeClasses() {
    // TODO(sra): Put specialized version of getNativeMethods on
    // `Object.prototype` to avoid checking in `getInterceptor` and
    // specializations.

    // jsAst.Expression call = js(defineNativeMethodsFinishName)([]);
    // nativeBuffer.add(jsAst.prettyPrint(call, compiler));
    // nativeBuffer.add('$N$n');
  }

  void potentiallyConvertDartClosuresToJs(
      List<jsAst.Statement> statements,
      FunctionElement member,
      List<jsAst.Parameter> stubParameters) {
    FunctionSignature parameters = member.computeSignature(compiler);
    Element converter =
        compiler.findHelper(const SourceString('convertDartClosureToJS'));
    String closureConverter = backend.namer.isolateAccess(converter);
    Set<String> stubParameterNames = new Set<String>.from(
        stubParameters.map((param) => param.name));
    parameters.forEachParameter((Element parameter) {
      String name = parameter.name.slowToString();
      // If [name] is not in [stubParameters], then the parameter is an optional
      // parameter that was not provided for this stub.
      for (jsAst.Parameter stubParameter in stubParameters) {
        if (stubParameter.name == name) {
          DartType type = parameter.computeType(compiler).unalias(compiler);
          if (type is FunctionType) {
            // The parameter type is a function type either directly or through
            // typedef(s).
            int arity = type.computeArity();
            statements.add(
                js('$name = $closureConverter($name, $arity)').toStatement());
            break;
          }
        }
      }
    });
  }

  List<jsAst.Statement> generateParameterStubStatements(
      Element member,
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

    ClassElement classElement = member.enclosingElement;
    String nativeTagInfo = classElement.nativeTagInfo.slowToString();

    List<jsAst.Statement> statements = <jsAst.Statement>[];
    potentiallyConvertDartClosuresToJs(statements, member, stubParameters);

    String target;
    jsAst.Expression receiver;
    List<jsAst.Expression> arguments;

    if (!nativeMethods.contains(member)) {
      // When calling a method that has a native body, we call it with our
      // calling conventions.
      target = backend.namer.getName(member);
      arguments = argumentsBuffer;
    } else {
      // When calling a JS method, we call it with the native name, and only the
      // arguments up until the last one provided.
      target = member.fixedBackendName();

      if (isInterceptedMethod) {
        receiver = argumentsBuffer[0];
        arguments = argumentsBuffer.sublist(1,
            indexOfLastOptionalArgumentInParameters + 1);
      } else {
        receiver = js('this');
        arguments = argumentsBuffer.sublist(0,
            indexOfLastOptionalArgumentInParameters + 1);
      }
    }
    statements.add(new jsAst.Return(receiver[target](arguments)));

    return statements;
  }

  bool isSupertypeOfNativeClass(Element element) {
    if (element.isTypeVariable()) {
      compiler.cancel("Is check for type variable", element: element);
      return false;
    }
    if (element.computeType(compiler).unalias(compiler) is FunctionType) {
      // The element type is a function type either directly or through
      // typedef(s).
      return false;
    }

    if (!element.isClass()) {
      compiler.cancel("Is check does not handle element", element: element);
      return false;
    }

    return subtypes[element] != null;
  }

  bool requiresNativeIsCheck(Element element) {
    // TODO(sra): Remove this function.  It determines if a native type may
    // satisfy a check against [element], in whcih case an interceptor must be
    // used.  We should also use an interceptor if the check can't be satisfied
    // by a native class in case we get a natibe instance that tries to spoof
    // the type info.  i.e the criteria for whether or not to use an interceptor
    // is whether the receiver can be native, not the type of the test.
    if (!element.isClass()) return false;
    ClassElement cls = element;
    if (cls.isNative()) return true;
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
        emitter.emitNoSuchMethodHandlers(addProperty);
      }
    }

    // If we have any properties to add to Object.prototype, we run
    // through them and add them using defineProperty.
    if (!objectProperties.isEmpty) {
      jsAst.Expression init =
          js.fun(['table'],
              new jsAst.ForIn(
                  new jsAst.VariableDeclarationList(
                      [new jsAst.VariableInitialization(
                          new jsAst.VariableDeclaration('key'),
                          null)]),
                  js('table'),
                  new jsAst.ExpressionStatement(
                      js('$defPropName(Object.prototype, key, table[key])'))))(
              new jsAst.ObjectInitializer(objectProperties));

      if (emitter.compiler.enableMinification) targetBuffer.add(';');
      targetBuffer.add(jsAst.prettyPrint(
          new jsAst.ExpressionStatement(init), compiler));
      targetBuffer.add('\n');
    }

    targetBuffer.add(nativeBuffer);
    targetBuffer.add('\n');
  }
}
