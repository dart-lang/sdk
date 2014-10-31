// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

const USE_NEW_EMITTER = const bool.fromEnvironment("dart2js.use.new.emitter");

/**
 * Generates the code for all used classes in the program. Static fields (even
 * in classes) are ignored, since they can be treated as non-class elements.
 *
 * The code for the containing (used) methods must exist in the [:universe:].
 */
class CodeEmitterTask extends CompilerTask {
  // TODO(floitsch): the code-emitter task should not need a namer.
  final Namer namer;
  final TypeTestEmitter typeTestEmitter = new TypeTestEmitter();
  NativeEmitter nativeEmitter;
  OldEmitter oldEmitter;
  Emitter emitter;

  final Set<ClassElement> neededClasses = new Set<ClassElement>();
  final Map<OutputUnit, List<ClassElement>> outputClassLists =
      new Map<OutputUnit, List<ClassElement>>();
  final Map<OutputUnit, List<ConstantValue>> outputConstantLists =
      new Map<OutputUnit, List<ConstantValue>>();
  final Map<OutputUnit, List<Element>> outputStaticLists =
      new Map<OutputUnit, List<Element>>();
  final Map<OutputUnit, Set<LibraryElement>> outputLibraryLists =
      new Map<OutputUnit, Set<LibraryElement>>();

  /// True, if the output contains a constant list.
  ///
  /// This flag is updated in [computeNeededConstants].
  bool outputContainsConstantList = false;

  final List<ClassElement> nativeClasses = <ClassElement>[];

  /// Records if a type variable is read dynamically for type tests.
  final Set<TypeVariableElement> readTypeVariables =
      new Set<TypeVariableElement>();

  List<TypedefElement> typedefsNeededForReflection;

  JavaScriptBackend get backend => compiler.backend;

  CodeEmitterTask(Compiler compiler, Namer namer, bool generateSourceMap)
      : super(compiler),
        this.namer = namer {
    oldEmitter = new OldEmitter(compiler, namer, generateSourceMap, this);
    emitter = USE_NEW_EMITTER
        ? new new_js_emitter.Emitter(compiler, namer)
        : oldEmitter;
    nativeEmitter = new NativeEmitter(this);
    typeTestEmitter.emitter = this.oldEmitter;
  }


  jsAst.Expression generateEmbeddedGlobalAccess(String global) {
    return emitter.generateEmbeddedGlobalAccess(global);
  }

  jsAst.Expression constantReference(ConstantValue value) {
    return emitter.constantReference(value);
  }

  void registerReadTypeVariable(TypeVariableElement element) {
    readTypeVariables.add(element);
  }

  Set<ClassElement> interceptorsReferencedFromConstants() {
    Set<ClassElement> classes = new Set<ClassElement>();
    JavaScriptConstantCompiler handler = backend.constants;
    List<ConstantValue> constants = handler.getConstantsForEmission();
    for (ConstantValue constant in constants) {
      if (constant is InterceptorConstantValue) {
        InterceptorConstantValue interceptorConstant = constant;
        classes.add(interceptorConstant.dispatchedType.element);
      }
    }
    return classes;
  }

  /**
   * Return a function that returns true if its argument is a class
   * that needs to be emitted.
   */
  Function computeClassFilter() {
    if (backend.isTreeShakingDisabled) return (ClassElement cls) => true;

    Set<ClassElement> unneededClasses = new Set<ClassElement>();
    // The [Bool] class is not marked as abstract, but has a factory
    // constructor that always throws. We never need to emit it.
    unneededClasses.add(compiler.boolClass);

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassElement> needed = new Set<ClassElement>();
    backend.specializedGetInterceptors.forEach(
        (_, Iterable<ClassElement> elements) {
          needed.addAll(elements);
        }
    );

    // Add interceptors referenced by constants.
    needed.addAll(interceptorsReferencedFromConstants());

    // Add unneeded interceptors to the [unneededClasses] set.
    for (ClassElement interceptor in backend.interceptedClasses) {
      if (!needed.contains(interceptor)
          && interceptor != compiler.objectClass) {
        unneededClasses.add(interceptor);
      }
    }

    // These classes are just helpers for the backend's type system.
    unneededClasses.add(backend.jsMutableArrayClass);
    unneededClasses.add(backend.jsFixedArrayClass);
    unneededClasses.add(backend.jsExtendableArrayClass);
    unneededClasses.add(backend.jsUInt32Class);
    unneededClasses.add(backend.jsUInt31Class);
    unneededClasses.add(backend.jsPositiveIntClass);

    return (ClassElement cls) => !unneededClasses.contains(cls);
  }

  /**
   * Compute all the constants that must be emitted.
   */
  void computeNeededConstants() {
    // Make sure we retain all metadata of all elements. This could add new
    // constants to the handler.
    if (backend.mustRetainMetadata) {
      // TODO(floitsch): verify that we don't run through the same elements
      // multiple times.
      for (Element element in backend.generatedCode.keys) {
        if (backend.isAccessibleByReflection(element)) {
          bool shouldRetainMetadata = backend.retainMetadataOf(element);
          if (shouldRetainMetadata && element.isFunction) {
            FunctionElement function = element;
            function.functionSignature.forEachParameter(
                backend.retainMetadataOf);
          }
        }
      }
      for (ClassElement cls in neededClasses) {
        final onlyForRti = typeTestEmitter.rtiNeededClasses.contains(cls);
        if (!onlyForRti) {
          backend.retainMetadataOf(cls);
          oldEmitter.classEmitter.visitFields(cls, false,
              (Element member,
               String name,
               String accessorName,
               bool needsGetter,
               bool needsSetter,
               bool needsCheckedSetter) {
            bool needsAccessor = needsGetter || needsSetter;
            if (needsAccessor && backend.isAccessibleByReflection(member)) {
              backend.retainMetadataOf(member);
            }
          });
        }
      }
      typedefsNeededForReflection.forEach(backend.retainMetadataOf);
    }

    JavaScriptConstantCompiler handler = backend.constants;
    List<ConstantValue> constants = handler.getConstantsForEmission(
        compiler.hasIncrementalSupport ? null : emitter.compareConstants);
    for (ConstantValue constant in constants) {
      if (emitter.isConstantInlinedOrAlreadyEmitted(constant)) continue;

      if (constant.isList) outputContainsConstantList = true;

      OutputUnit constantUnit =
          compiler.deferredLoadTask.outputUnitForConstant(constant);
      if (constantUnit == null) {
        // The back-end introduces some constants, like "InterceptorConstant" or
        // some list constants. They are emitted in the main output-unit.
        // TODO(sigurdm): We should track those constants.
        constantUnit = compiler.deferredLoadTask.mainOutputUnit;
      }
      outputConstantLists.putIfAbsent(
          constantUnit, () => new List<ConstantValue>()).add(constant);
    }
  }

  /// Compute all the classes and typedefs that must be emitted.
  void computeNeededDeclarations() {
    // Compute needed typedefs.
    typedefsNeededForReflection = Elements.sortedByPosition(
        compiler.world.allTypedefs
            .where(backend.isAccessibleByReflection)
            .toList());

    // Compute needed classes.
    Set<ClassElement> instantiatedClasses =
        compiler.codegenWorld.directlyInstantiatedClasses
            .where(computeClassFilter()).toSet();

    void addClassWithSuperclasses(ClassElement cls) {
      neededClasses.add(cls);
      for (ClassElement superclass = cls.superclass;
          superclass != null;
          superclass = superclass.superclass) {
        neededClasses.add(superclass);
      }
    }

    void addClassesWithSuperclasses(Iterable<ClassElement> classes) {
      for (ClassElement cls in classes) {
        addClassWithSuperclasses(cls);
      }
    }

    // 1. We need to generate all classes that are instantiated.
    addClassesWithSuperclasses(instantiatedClasses);

    // 2. Add all classes used as mixins.
    Set<ClassElement> mixinClasses = neededClasses
        .where((ClassElement element) => element.isMixinApplication)
        .map(computeMixinClass)
        .toSet();
    neededClasses.addAll(mixinClasses);

    // 3. If we need noSuchMethod support, we run through all needed
    // classes to figure out if we need the support on any native
    // class. If so, we let the native emitter deal with it.
    if (compiler.enabledNoSuchMethod) {
      String noSuchMethodName = Compiler.NO_SUCH_METHOD;
      Selector noSuchMethodSelector = compiler.noSuchMethodSelector;
      for (ClassElement element in neededClasses) {
        if (!element.isNative) continue;
        Element member = element.lookupLocalMember(noSuchMethodName);
        if (member == null) continue;
        if (noSuchMethodSelector.applies(member, compiler.world)) {
          nativeEmitter.handleNoSuchMethod = true;
          break;
        }
      }
    }

    // 4. Find all classes needed for rti.
    // It is important that this is the penultimate step, at this point,
    // neededClasses must only contain classes that have been resolved and
    // codegen'd. The rtiNeededClasses may contain additional classes, but
    // these are thought to not have been instantiated, so we neeed to be able
    // to identify them later and make sure we only emit "empty shells" without
    // fields, etc.
    typeTestEmitter.computeRtiNeededClasses();
    typeTestEmitter.rtiNeededClasses.removeAll(neededClasses);
    // rtiNeededClasses now contains only the "empty shells".
    neededClasses.addAll(typeTestEmitter.rtiNeededClasses);

    // TODO(18175, floitsch): remove once issue 18175 is fixed.
    if (neededClasses.contains(backend.jsIntClass)) {
      neededClasses.add(compiler.intClass);
    }
    if (neededClasses.contains(backend.jsDoubleClass)) {
      neededClasses.add(compiler.doubleClass);
    }
    if (neededClasses.contains(backend.jsNumberClass)) {
      neededClasses.add(compiler.numClass);
    }
    if (neededClasses.contains(backend.jsStringClass)) {
      neededClasses.add(compiler.stringClass);
    }
    if (neededClasses.contains(backend.jsBoolClass)) {
      neededClasses.add(compiler.boolClass);
    }
    if (neededClasses.contains(backend.jsArrayClass)) {
      neededClasses.add(compiler.listClass);
    }

    // 5. Finally, sort the classes.
    List<ClassElement> sortedClasses = Elements.sortedByPosition(neededClasses);

    for (ClassElement element in sortedClasses) {
      if (Elements.isNativeOrExtendsNative(element) &&
          !typeTestEmitter.rtiNeededClasses.contains(element)) {
        // For now, native classes and related classes cannot be deferred.
        nativeClasses.add(element);
        if (!element.isNative) {
          assert(invariant(element,
                           !compiler.deferredLoadTask.isDeferred(element)));
          outputClassLists.putIfAbsent(compiler.deferredLoadTask.mainOutputUnit,
              () => new List<ClassElement>()).add(element);
        }
      } else {
        outputClassLists.putIfAbsent(
            compiler.deferredLoadTask.outputUnitForElement(element),
            () => new List<ClassElement>())
            .add(element);
      }
    }
  }

  void computeNeededStatics() {
    bool isStaticFunction(Element element) =>
        !element.isInstanceMember && !element.isField;

    Iterable<Element> elements =
        backend.generatedCode.keys.where(isStaticFunction);

    for (Element element in Elements.sortedByPosition(elements)) {
      outputStaticLists.putIfAbsent(
          compiler.deferredLoadTask.outputUnitForElement(element),
          () => new List<Element>())
          .add(element);
    }
  }

  void computeNeededLibraries() {
    void addSurroundingLibraryToSet(Element element) {
      OutputUnit unit = compiler.deferredLoadTask.outputUnitForElement(element);
      LibraryElement library = element.library;
      outputLibraryLists.putIfAbsent(unit, () => new Set<LibraryElement>())
          .add(library);
    }

    backend.generatedCode.keys.forEach(addSurroundingLibraryToSet);
    neededClasses.forEach(addSurroundingLibraryToSet);
}

  void assembleProgram() {
    measure(() {
      emitter.invalidateCaches();

      // Compute the required type checks to know which classes need a
      // 'is$' method.
      typeTestEmitter.computeRequiredTypeChecks();

      computeNeededDeclarations();
      computeNeededConstants();
      computeNeededStatics();
      computeNeededLibraries();


      Program program;
      if (USE_NEW_EMITTER) {
        program = new ProgramBuilder(compiler, namer, this).buildProgram();
      }
      emitter.emitProgram(program);
    });
  }
}

abstract class Emitter {
  void emitProgram(Program program);

  jsAst.Expression generateEmbeddedGlobalAccess(String global);
  jsAst.Expression constantReference(ConstantValue value);

  int compareConstants(ConstantValue a, ConstantValue b);
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant);

  void invalidateCaches();
}
