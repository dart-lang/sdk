// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of native;

/**
 * This could be an abstract class but we use it as a stub for the dart_backend.
 */
class NativeEnqueuer {
  /// Initial entry point to native enqueuer.
  void processNativeClasses(Iterable<LibraryElement> libraries) {}

  /// Notification of a main Enqueuer worklist element.  For methods, adds
  /// information from metadata attributes, and computes types instantiated due
  /// to calling the method.
  void registerElement(Element element) {}

  /// Notification of native field.  Adds information from metadata attributes.
  void handleFieldAnnotations(Element field) {}

  /// Computes types instantiated due to getting a native field.
  void registerFieldLoad(Element field) {}

  /// Computes types instantiated due to setting a native field.
  void registerFieldStore(Element field) {}

  NativeBehavior getNativeBehaviorOf(Send node) => NativeBehavior.NONE;

  /// Returns whether native classes are being used.
  bool hasInstantiatedNativeClasses() => false;

  /**
   * Handles JS-calls, which can be an instantiation point for types.
   *
   * For example, the following code instantiates and returns native classes
   * that are `_DOMWindowImpl` or a subtype.
   *
   *     JS('_DOMWindowImpl', 'window')
   *
   */
  // TODO(sra): The entry from codegen will not have a resolver.
  void registerJsCall(Send node, ResolverVisitor resolver) {}

  /**
   * Handles JS-embedded global calls, which can be an instantiation point for
   * types.
   *
   * For example, the following code instantiates and returns a String class
   *
   *     JS_EMBEDDED_GLOBAL('String', 'foo')
   *
   */
  // TODO(sra): The entry from codegen will not have a resolver.
  void registerJsEmbeddedGlobalCall(Send node, ResolverVisitor resolver) {}

  /// Emits a summary information using the [log] function.
  void logSummary(log(message)) {}

  // Do not use annotations in dart2dart.
  ClassElement get annotationCreatesClass => null;
  ClassElement get annotationReturnsClass => null;
  ClassElement get annotationJsNameClass => null;
}


abstract class NativeEnqueuerBase implements NativeEnqueuer {

  /**
   * The set of all native classes.  Each native class is in [nativeClasses] and
   * exactly one of [unusedClasses], [pendingClasses] and [registeredClasses].
   */
  final Set<ClassElement> nativeClasses = new Set<ClassElement>();

  final Set<ClassElement> registeredClasses = new Set<ClassElement>();
  final Set<ClassElement> pendingClasses = new Set<ClassElement>();
  final Set<ClassElement> unusedClasses = new Set<ClassElement>();

  final Set<LibraryElement> processedLibraries;

  bool hasInstantiatedNativeClasses() => !registeredClasses.isEmpty;

  final Set<ClassElement> nativeClassesAndSubclasses = new Set<ClassElement>();

  final Map<ClassElement, Set<ClassElement>> nonNativeSubclasses =
      new Map<ClassElement, Set<ClassElement>>();

  /**
   * Records matched constraints ([SpecialType] or [DartType]).  Once a type
   * constraint has been matched, there is no need to match it again.
   */
  final Set matchedTypeConstraints = new Set();

  /// Pending actions.  Classes in [pendingClasses] have action thunks in
  /// [queue] to register the class.
  final queue = new Queue();
  bool flushing = false;

  /// Maps JS foreign calls to their computed native behavior.
  final Map<Node, NativeBehavior> nativeBehaviors =
      new Map<Node, NativeBehavior>();

  final Enqueuer world;
  final Compiler compiler;
  final bool enableLiveTypeAnalysis;

  ClassElement _annotationCreatesClass;
  ClassElement _annotationReturnsClass;
  ClassElement _annotationJsNameClass;

  /// Subclasses of [NativeEnqueuerBase] are constructed by the backend.
  NativeEnqueuerBase(this.world, Compiler compiler, this.enableLiveTypeAnalysis)
      : this.compiler = compiler,
        processedLibraries = compiler.cacheStrategy.newSet();

  JavaScriptBackend get backend => compiler.backend;

  void processNativeClasses(Iterable<LibraryElement> libraries) {
    if (compiler.hasIncrementalSupport) {
      // Since [Set.add] returns bool if an element was added, this restricts
      // [libraries] to ones that haven't already been processed. This saves
      // time during incremental compiles.
      libraries = libraries.where(processedLibraries.add);
    }
    libraries.forEach(processNativeClassesInLibrary);
    if (backend.isolateHelperLibrary != null) {
      processNativeClassesInLibrary(backend.isolateHelperLibrary);
    }
    processSubclassesOfNativeClasses(libraries);
    if (!enableLiveTypeAnalysis) {
      nativeClasses.forEach((c) => enqueueClass(c, 'forced'));
      flushQueue();
    }
  }

  void processNativeClassesInLibrary(LibraryElement library) {
    // Use implementation to ensure the inclusion of injected members.
    library.implementation.forEachLocalMember((Element element) {
      if (element.isClass && element.isNative) {
        processNativeClass(element);
      }
    });
  }

  void processNativeClass(ClassElement classElement) {
    nativeClasses.add(classElement);
    unusedClasses.add(classElement);
    // Resolve class to ensure the class has valid inheritance info.
    classElement.ensureResolved(compiler);
  }

  void processSubclassesOfNativeClasses(Iterable<LibraryElement> libraries) {
    // Collect potential subclasses, e.g.
    //
    //     class B extends foo.A {}
    //
    // String "A" has a potential subclass B.

    var potentialExtends = new Map<String, Set<ClassElement>>();

    libraries.forEach((library) {
      library.implementation.forEachLocalMember((element) {
        if (element.isClass) {
          String name = element.name;
          String extendsName = findExtendsNameOfClass(element);
          if (extendsName != null) {
            Set<ClassElement> potentialSubclasses =
                potentialExtends.putIfAbsent(
                    extendsName,
                    () => new Set<ClassElement>());
            potentialSubclasses.add(element);
          }
        }
      });
    });

    // Resolve all the native classes and any classes that might extend them in
    // [potentialExtends], and then check that the properly resolved class is in
    // fact a subclass of a native class.

    ClassElement nativeSuperclassOf(ClassElement classElement) {
      if (classElement.isNative) return classElement;
      if (classElement.superclass == null) return null;
      return nativeSuperclassOf(classElement.superclass);
    }

    void walkPotentialSubclasses(ClassElement element) {
      if (nativeClassesAndSubclasses.contains(element)) return;
      element.ensureResolved(compiler);
      ClassElement nativeSuperclass = nativeSuperclassOf(element);
      if (nativeSuperclass != null) {
        nativeClassesAndSubclasses.add(element);
        if (!element.isNative) {
          nonNativeSubclasses.putIfAbsent(nativeSuperclass,
              () => new Set<ClassElement>())
            .add(element);
        }
        Set<ClassElement> potentialSubclasses = potentialExtends[element.name];
        if (potentialSubclasses != null) {
          potentialSubclasses.forEach(walkPotentialSubclasses);
        }
      }
    }

    nativeClasses.forEach(walkPotentialSubclasses);

    nativeClasses.addAll(nativeClassesAndSubclasses);
    unusedClasses.addAll(nativeClassesAndSubclasses);
  }

  /**
   * Returns the source string of the class named in the extends clause, or
   * `null` if there is no extends clause.
   */
  String findExtendsNameOfClass(ClassElement classElement) {
    //  "class B extends A ... {}"  --> "A"
    //  "class B extends foo.A ... {}"  --> "A"
    //  "class B<T> extends foo.A<T,T> with M1, M2 ... {}"  --> "A"

    // We want to avoid calling classElement.parseNode on every class.  Doing so
    // will slightly increase parse time and size and cause compiler errors and
    // warnings to me emitted in more unused code.

    // An alternative to this code is to extend the API of ClassElement to
    // expose the name of the extended element.

    // Pattern match the above cases in the token stream.
    //  [abstract] class X extends [id.]* id

    Token skipTypeParameters(Token token) {
      BeginGroupToken beginGroupToken = token;
      Token endToken = beginGroupToken.endGroup;
      return endToken.next;
      //for (;;) {
      //  token = token.next;
      //  if (token.stringValue == '>') return token.next;
      //  if (token.stringValue == '<') return skipTypeParameters(token);
      //}
    }

    String scanForExtendsName(Token token) {
      if (token.stringValue == 'abstract') token = token.next;
      if (token.stringValue != 'class') return null;
      token = token.next;
      if (!token.isIdentifier()) return null;
      token = token.next;
      //  class F<X extends B<X>> extends ...
      if (token.stringValue == '<') {
        token = skipTypeParameters(token);
      }
      if (token.stringValue != 'extends') return null;
      token = token.next;
      Token id = token;
      while (token.kind != EOF_TOKEN) {
        token = token.next;
        if (token.stringValue != '.') break;
        token = token.next;
        if (!token.isIdentifier()) return null;
        id = token;
      }
      // Should be at '{', 'with', 'implements', '<' or 'native'.
      return id.value;
    }

    return compiler.withCurrentElement(classElement, () {
      return scanForExtendsName(classElement.position);
    });
  }

  ClassElement get annotationCreatesClass {
    findAnnotationClasses();
    return _annotationCreatesClass;
  }

  ClassElement get annotationReturnsClass {
    findAnnotationClasses();
    return _annotationReturnsClass;
  }

  ClassElement get annotationJsNameClass {
    findAnnotationClasses();
    return _annotationJsNameClass;
  }

  void findAnnotationClasses() {
    if (_annotationCreatesClass != null) return;
    ClassElement find(name) {
      Element e = backend.findHelper(name);
      if (e == null || e is! ClassElement) {
        compiler.internalError(NO_LOCATION_SPANNABLE,
            "Could not find implementation class '${name}'.");
      }
      return e;
    }
    _annotationCreatesClass = find('Creates');
    _annotationReturnsClass = find('Returns');
    _annotationJsNameClass = find('JSName');
  }

  /// Returns the JSName annotation string or `null` if no JSName annotation is
  /// present.
  String findJsNameFromAnnotation(Element element) {
    String name = null;
    ClassElement annotationClass = annotationJsNameClass;
    for (Link<MetadataAnnotation> link = element.metadata;
         !link.isEmpty;
         link = link.tail) {
      MetadataAnnotation annotation = link.head.ensureResolved(compiler);
      ConstantValue value = annotation.constant.value;
      if (!value.isConstructedObject) continue;
      ConstructedConstantValue constructedObject = value;
      if (constructedObject.type.element != annotationClass) continue;

      List<ConstantValue> fields = constructedObject.fields;
      // TODO(sra): Better validation of the constant.
      if (fields.length != 1 || fields[0] is! StringConstantValue) {
        PartialMetadataAnnotation partial = annotation;
        compiler.internalError(annotation,
            'Annotations needs one string: ${partial.parseNode(compiler)}');
      }
      StringConstantValue specStringConstant = fields[0];
      String specString = specStringConstant.toDartString().slowToString();
      if (name == null) {
        name = specString;
      } else {
        PartialMetadataAnnotation partial = annotation;
        compiler.internalError(annotation,
            'Too many JSName annotations: ${partial.parseNode(compiler)}');
      }
    }
    return name;
  }

  enqueueClass(ClassElement classElement, cause) {
    assert(unusedClasses.contains(classElement));
    unusedClasses.remove(classElement);
    pendingClasses.add(classElement);
    queue.add(() { processClass(classElement, cause); });
  }

  void flushQueue() {
    if (flushing) return;
    flushing = true;
    while (!queue.isEmpty) {
      (queue.removeFirst())();
    }
    flushing = false;
  }

  processClass(ClassElementX classElement, cause) {
    // TODO(ahe): Fix this assertion to work in incremental compilation.
    assert(compiler.hasIncrementalSupport ||
           !registeredClasses.contains(classElement));

    bool firstTime = registeredClasses.isEmpty;
    pendingClasses.remove(classElement);
    registeredClasses.add(classElement);

    // TODO(ahe): Is this really a global dependency?
    world.registerInstantiatedClass(classElement, compiler.globalDependencies);

    // Also parse the node to know all its methods because otherwise it will
    // only be parsed if there is a call to one of its constructors.
    classElement.parseNode(compiler);

    if (firstTime) {
      queue.add(onFirstNativeClass);
    }
  }

  registerElement(Element element) {
    compiler.withCurrentElement(element, () {
      if (element.isFunction || element.isGetter || element.isSetter) {
        handleMethodAnnotations(element);
        if (element.isNative) {
          registerMethodUsed(element);
        }
      } else if (element.isField) {
        handleFieldAnnotations(element);
        if (element.isNative) {
          registerFieldLoad(element);
          registerFieldStore(element);
        }
      }
    });
  }

  handleFieldAnnotations(Element element) {
    if (element.enclosingElement.isNative) {
      // Exclude non-instance (static) fields - they not really native and are
      // compiled as isolate globals.  Access of a property of a constructor
      // function or a non-method property in the prototype chain, must be coded
      // using a JS-call.
      if (element.isInstanceMember) {
        setNativeName(element);
      }
    }
  }

  handleMethodAnnotations(Element method) {
    if (isNativeMethod(method)) {
      setNativeName(method);
    }
  }

  /// Sets the native name of [element], either from an annotation, or
  /// defaulting to the Dart name.
  void setNativeName(Element element) {
    String name = findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    element.setNative(name);
  }

  bool isNativeMethod(FunctionElementX element) {
    if (!element.library.canUseNative) return false;
    // Native method?
    return compiler.withCurrentElement(element, () {
      Node node = element.parseNode(compiler);
      if (node is! FunctionExpression) return false;
      FunctionExpression functionExpression = node;
      node = functionExpression.body;
      Token token = node.getBeginToken();
      if (identical(token.stringValue, 'native')) return true;
      return false;
    });
  }

  void registerMethodUsed(Element method) {
    processNativeBehavior(
        NativeBehavior.ofMethod(method, compiler),
        method);
      flushQueue();
  }

  void registerFieldLoad(Element field) {
    processNativeBehavior(
        NativeBehavior.ofFieldLoad(field, compiler),
        field);
    flushQueue();
  }

  void registerFieldStore(Element field) {
    processNativeBehavior(
        NativeBehavior.ofFieldStore(field, compiler),
        field);
    flushQueue();
  }

  void registerJsCall(Send node, ResolverVisitor resolver) {
    NativeBehavior behavior = NativeBehavior.ofJsCall(node, compiler, resolver);
    processNativeBehavior(behavior, node);
    nativeBehaviors[node] = behavior;
    flushQueue();
  }

  void registerJsEmbeddedGlobalCall(Send node, ResolverVisitor resolver) {
    NativeBehavior behavior =
        NativeBehavior.ofJsEmbeddedGlobalCall(node, compiler, resolver);
    processNativeBehavior(behavior, node);
    nativeBehaviors[node] = behavior;
    flushQueue();
  }

  NativeBehavior getNativeBehaviorOf(Send node) => nativeBehaviors[node];

  processNativeBehavior(NativeBehavior behavior, cause) {
    // TODO(ahe): Is this really a global dependency?
    Registry registry = compiler.globalDependencies;
    bool allUsedBefore = unusedClasses.isEmpty;
    for (var type in behavior.typesInstantiated) {
      if (matchedTypeConstraints.contains(type)) continue;
      matchedTypeConstraints.add(type);
      if (type is SpecialType) {
        if (type == SpecialType.JsObject) {
          world.registerInstantiatedClass(compiler.objectClass, registry);
        }
        continue;
      }
      if (type is InterfaceType) {
        if (type.element == compiler.intClass) {
          world.registerInstantiatedClass(compiler.intClass, registry);
        } else if (type.element == compiler.doubleClass) {
          world.registerInstantiatedClass(compiler.doubleClass, registry);
        } else if (type.element == compiler.numClass) {
          world.registerInstantiatedClass(compiler.doubleClass, registry);
          world.registerInstantiatedClass(compiler.intClass, registry);
        } else if (type.element == compiler.stringClass) {
          world.registerInstantiatedClass(compiler.stringClass, registry);
        } else if (type.element == compiler.nullClass) {
          world.registerInstantiatedClass(compiler.nullClass, registry);
        } else if (type.element == compiler.boolClass) {
          world.registerInstantiatedClass(compiler.boolClass, registry);
        } else if (compiler.types.isSubtype(
                      type, backend.listImplementation.rawType)) {
          world.registerInstantiatedClass(type.element, registry);
        }
      }
      assert(type is DartType);
      enqueueUnusedClassesMatching(
          (nativeClass) => compiler.types.isSubtype(nativeClass.thisType, type),
          cause,
          'subtypeof($type)');
    }

    // Give an info so that library developers can compile with -v to find why
    // all the native classes are included.
    if (unusedClasses.isEmpty && !allUsedBefore) {
      compiler.log('All native types marked as used due to $cause.');
    }
  }

  enqueueUnusedClassesMatching(bool predicate(classElement),
                               cause,
                               [String reason]) {
    Iterable matches = unusedClasses.where(predicate);
    matches.toList().forEach((c) => enqueueClass(c, cause));
  }

  onFirstNativeClass() {
    staticUse(name) {
      backend.enqueue(
          world, backend.findHelper(name), compiler.globalDependencies);
    }

    staticUse('defineProperty');
    staticUse('toStringForNativeObject');
    staticUse('hashCodeForNativeObject');
    staticUse('convertDartClosureToJS');
    addNativeExceptions();
  }

  addNativeExceptions() {
    enqueueUnusedClassesMatching((classElement) {
        // TODO(sra): Annotate exception classes in dart:html.
        String name = classElement.name;
        if (name.contains('Exception')) return true;
        if (name.contains('Error')) return true;
        return false;
      },
      'native exception');
  }
}


class NativeResolutionEnqueuer extends NativeEnqueuerBase {

  Map<String, ClassElement> tagOwner = new Map<String, ClassElement>();

  NativeResolutionEnqueuer(Enqueuer world, Compiler compiler)
    : super(world, compiler, compiler.enableNativeLiveTypeAnalysis);

  void processNativeClass(ClassElement classElement) {
    super.processNativeClass(classElement);

    // Since we map from dispatch tags to classes, a dispatch tag must be used
    // on only one native class.
    for (String tag in nativeTagsOfClass(classElement)) {
      ClassElement owner = tagOwner[tag];
      if (owner != null) {
        if (owner != classElement) {
          compiler.internalError(
              classElement, "Tag '$tag' already in use by '${owner.name}'");
        }
      } else {
        tagOwner[tag] = classElement;
      }
    }
  }

  void logSummary(log(message)) {
    log('Resolved ${registeredClasses.length} native elements used, '
        '${unusedClasses.length} native elements dead.');
  }
}


class NativeCodegenEnqueuer extends NativeEnqueuerBase {

  final CodeEmitterTask emitter;

  final Set<ClassElement> doneAddSubtypes = new Set<ClassElement>();

  NativeCodegenEnqueuer(Enqueuer world, Compiler compiler, this.emitter)
    : super(world, compiler, compiler.enableNativeLiveTypeAnalysis);

  void processNativeClasses(Iterable<LibraryElement> libraries) {
    super.processNativeClasses(libraries);

    // HACK HACK - add all the resolved classes.
    NativeEnqueuerBase enqueuer = compiler.enqueuer.resolution.nativeEnqueuer;
    for (final classElement in enqueuer.registeredClasses) {
      if (unusedClasses.contains(classElement)) {
        enqueueClass(classElement, 'was resolved');
      }
    }
    flushQueue();
  }

  processClass(ClassElement classElement, cause) {
    super.processClass(classElement, cause);
    // Add the information that this class is a subtype of its supertypes.  The
    // code emitter and the ssa builder use that information.
    addSubtypes(classElement, emitter.nativeEmitter);
  }

  void addSubtypes(ClassElement cls, NativeEmitter emitter) {
    if (!cls.isNative) return;
    if (doneAddSubtypes.contains(cls)) return;
    doneAddSubtypes.add(cls);

    // Walk the superclass chain since classes on the superclass chain might not
    // be instantiated (abstract or simply unused).
    addSubtypes(cls.superclass, emitter);

    for (DartType type in cls.allSupertypes) {
      List<Element> subtypes = emitter.subtypes.putIfAbsent(
          type.element,
          () => <ClassElement>[]);
      subtypes.add(cls);
    }

    // Skip through all the mixin applications in the super class
    // chain. That way, the direct subtypes set only contain the
    // natives classes.
    ClassElement superclass = cls.superclass;
    while (superclass != null && superclass.isMixinApplication) {
      assert(!superclass.isNative);
      superclass = superclass.superclass;
    }

    List<Element> directSubtypes = emitter.directSubtypes.putIfAbsent(
        superclass,
        () => <ClassElement>[]);
    directSubtypes.add(cls);
  }

  void logSummary(log(message)) {
    log('Compiled ${registeredClasses.length} native classes, '
        '${unusedClasses.length} native classes omitted.');
  }
}
