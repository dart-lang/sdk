// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class NativeEmitter {

  final Map<Element, ClassBuilder> cachedBuilders;

  final CodeEmitterTask emitterTask;

  // Whether the application contains native classes.
  bool hasNativeClasses = false;

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

  NativeEmitter(CodeEmitterTask emitterTask)
      : this.emitterTask = emitterTask,
        subtypes = new Map<ClassElement, List<ClassElement>>(),
        directSubtypes = new Map<ClassElement, List<ClassElement>>(),
        nativeMethods = new Set<FunctionElement>(),
        cachedBuilders = emitterTask.compiler.cacheStrategy.newMap();

  Compiler get compiler => emitterTask.compiler;
  JavaScriptBackend get backend => compiler.backend;

  jsAst.Expression get defPropFunction {
    Element element = backend.findHelper('defineProperty');
    return emitterTask.staticFunctionAccess(element);
  }

  /**
   * Prepares native classes for emission. Returns the unneeded classes.
   *
   * Removes trivial classes (that can be represented by a super type) and
   * generates properties that have to be added to classes (native or not).
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
   * of native classes.
   *
   * [allAdditionalProperties] is used to collect properties that are pushed up
   * from the above optimizations onto a non-native class, e.g, `Interceptor`.
   */
  Set<Class> prepareNativeClasses(
      List<Class> classes,
      Map<Class, Map<String, jsAst.Expression>> allAdditionalProperties) {
    assert(classes.every((Class cls) => cls != null));

    hasNativeClasses = classes.isNotEmpty;

    // Compute a pre-order traversal of the subclass forest.  We actually want a
    // post-order traversal but it is easier to compute the pre-order and use it
    // in reverse.
    List<Class> preOrder = <Class>[];
    Set<Class> seen = new Set<Class>();

    Class objectClass = null;
    Class jsInterceptorClass = null;
    void walk(Class cls) {
      if (cls.element == compiler.objectClass) {
        objectClass = cls;
        return;
      }
      if (cls.element == backend.jsInterceptorClass) {
        jsInterceptorClass = cls;
        return;
      }
      if (seen.contains(cls)) return;
      seen.add(cls);
      walk(cls.superclass);
      preOrder.add(cls);
    }
    classes.forEach(walk);

    // Find which classes are needed and which are non-leaf classes.  Any class
    // that is not needed can be treated as a leaf class equivalent to some
    // needed class.

    Set<Class> neededClasses = new Set<Class>();
    Set<Class> nonleafClasses = new Set<Class>();

    Map<Class, List<Class>> extensionPoints = computeExtensionPoints(preOrder);

    neededClasses.add(objectClass);

    Set<ClassElement> neededByConstant = emitterTask
        .computeInterceptorsReferencedFromConstants();
    Set<ClassElement> modifiedClasses = emitterTask.typeTestRegistry
        .computeClassesModifiedByEmitRuntimeTypeSupport();

    for (Class cls in preOrder.reversed) {
      ClassElement classElement = cls.element;
      // Post-order traversal ensures we visit the subclasses before their
      // superclass.  This makes it easy to tell if a class is needed because a
      // subclass is needed.
      bool needed = false;
      if (!cls.isNative) {
        // Mixin applications (native+mixin) are non-native, so [classElement]
        // has already been emitted as a regular class.  Mark [classElement] as
        // 'needed' to ensure the native superclass is needed.
        needed = true;
      } else if (!isTrivialClass(cls)) {
        needed = true;
      } else if (neededByConstant.contains(classElement)) {
        needed = true;
      } else if (modifiedClasses.contains(classElement)) {
        // TODO(9556): Remove this test when [emitRuntimeTypeSupport] no longer
        // adds information to a class prototype or constructor.
        needed = true;
      } else if (extensionPoints.containsKey(cls)) {
        needed = true;
      }
      if (cls.isNative &&
          native.nativeTagsForcedNonLeaf(classElement)) {
        needed = true;
        nonleafClasses.add(cls);
      }

      if (needed || neededClasses.contains(cls)) {
        neededClasses.add(cls);
        neededClasses.add(cls.superclass);
        nonleafClasses.add(cls.superclass);
      }
    }

    // Collect all the tags that map to each native class.

    Map<Class, Set<String>> leafTags = new Map<Class, Set<String>>();
    Map<Class, Set<String>> nonleafTags = new Map<Class, Set<String>>();

    for (Class cls in classes) {
      if (!cls.isNative) continue;
      List<String> nativeTags = native.nativeTagsOfClass(cls.element);

      if (nonleafClasses.contains(cls) ||
          extensionPoints.containsKey(cls)) {
        nonleafTags
            .putIfAbsent(cls, () => new Set<String>())
            .addAll(nativeTags);
      } else {
        Class sufficingInterceptor = cls;
        while (!neededClasses.contains(sufficingInterceptor)) {
          sufficingInterceptor = sufficingInterceptor.superclass;
        }
        if (sufficingInterceptor == objectClass) {
          sufficingInterceptor = jsInterceptorClass;
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
      void generateClassInfo(Class cls) {
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

        List<Class> extensions = extensionPoints[cls];

        String leafStr = formatTags(leafTags[cls]);
        String nonleafStr = formatTags(nonleafTags[cls]);

        StringBuffer sb = new StringBuffer(leafStr);
        if (nonleafStr != '') {
          sb..write(';')..write(nonleafStr);
        }
        if (extensions != null) {
          sb..write(';')
            ..writeAll(extensions.map((Class cls) => cls.name), '|');
        }
        String encoding = sb.toString();

        if (cls.isNative || encoding != '') {
          Map<String, jsAst.Expression> properties =
              allAdditionalProperties.putIfAbsent(cls,
                  () => new Map<String, jsAst.Expression>());
          properties[backend.namer.nativeSpecProperty] = js.string(encoding);
        }
      }
      generateClassInfo(jsInterceptorClass);
      for (Class cls in classes) {
        if (!cls.isNative || neededClasses.contains(cls)) {
          generateClassInfo(cls);
        }
      }
    }

    // TODO(sra): Issue #13731- this is commented out as part of custom
    // element constructor work.
    // (floitsch: was run on every native class.)
    //assert(!classElement.hasBackendMembers);

    return classes
        .where((Class cls) => cls.isNative && !neededClasses.contains(cls))
        .toSet();
  }

  /**
   * Computes the native classes that are extended (subclassed) by non-native
   * classes and the set non-mative classes that extend them.  (A List is used
   * instead of a Set for out stability).
   */
  Map<Class, List<Class>> computeExtensionPoints(List<Class> classes) {
    Class nativeSuperclassOf(Class cls) {
      if (cls == null) return null;
      if (cls.isNative) return cls;
      return nativeSuperclassOf(cls.superclass);
    }

    Class nativeAncestorOf(Class cls) {
      return nativeSuperclassOf(cls.superclass);
    }

    Map<Class, List<Class>> map = new Map<Class, List<Class>>();

    for (Class cls in classes) {
      if (cls.isNative) continue;
      Class nativeAncestor = nativeAncestorOf(cls);
      if (nativeAncestor != null) {
        map
          .putIfAbsent(nativeAncestor, () => <Class>[])
          .add(cls);
      }
    }
    return map;
  }

  bool isTrivialClass(Class cls) {
    bool needsAccessor(Field field) {
      return field.needsGetter ||
          field.needsUncheckedSetter ||
          field.needsCheckedSetter;
    }

    return
        cls.methods.isEmpty &&
        cls.isChecks.isEmpty &&
        cls.callStubs.isEmpty &&
        !cls.superclass.isMixinApplication &&
        !cls.fields.any(needsAccessor);
  }

  void potentiallyConvertDartClosuresToJs(
      List<jsAst.Statement> statements,
      FunctionElement member,
      List<jsAst.Parameter> stubParameters) {
    FunctionSignature parameters = member.functionSignature;
    Element converter = backend.findHelper('convertDartClosureToJS');
    jsAst.Expression closureConverter =
        emitterTask.staticFunctionAccess(converter);
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

  void assembleCode(CodeOutput targetOutput) {
    List<jsAst.Property> objectProperties = <jsAst.Property>[];

    jsAst.Property addProperty(String name, jsAst.Expression value) {
      jsAst.Property prop = new jsAst.Property(js.string(name), value);
      objectProperties.add(prop);
      return prop;
    }

    if (hasNativeClasses) {
      // If the native emitter has been asked to take care of the
      // noSuchMethod handlers, we do that now.
      if (handleNoSuchMethod) {
        emitterTask.oldEmitter.nsmEmitter.emitNoSuchMethodHandlers(addProperty);
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

      if (emitterTask.compiler.enableMinification) {
        targetOutput.add(';');
      }
      targetOutput.addBuffer(jsAst.prettyPrint(
          new jsAst.ExpressionStatement(init), compiler));
      targetOutput.add('\n');
    }

    targetOutput.add('\n');
  }
}
