// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.program_builder;

/**
 * Generates the code for all used classes in the program. Static fields (even
 * in classes) are ignored, since they can be treated as non-class elements.
 *
 * The code for the containing (used) methods must exist in the `universe`.
 */
class Collector {
  // TODO(floitsch): the code-emitter task should not need a namer.
  final Namer namer;
  final Compiler compiler;
  final Set<ClassElement> rtiNeededClasses;
  final Emitter emitter;

  final Set<ClassElement> neededClasses = new Set<ClassElement>();
  // This field is set in [computeNeededDeclarations].
  Set<ClassElement> classesOnlyNeededForRti;
  final Map<OutputUnit, List<ClassElement>> outputClassLists =
      new Map<OutputUnit, List<ClassElement>>();
  final Map<OutputUnit, List<ConstantValue>> outputConstantLists =
      new Map<OutputUnit, List<ConstantValue>>();
  final Map<OutputUnit, List<Element>> outputStaticLists =
      new Map<OutputUnit, List<Element>>();
  final Map<OutputUnit, List<VariableElement>> outputStaticNonFinalFieldLists =
      new Map<OutputUnit, List<VariableElement>>();
  final Map<OutputUnit, Set<LibraryElement>> outputLibraryLists =
      new Map<OutputUnit, Set<LibraryElement>>();

  /// True, if the output contains a constant list.
  ///
  /// This flag is updated in [computeNeededConstants].
  bool outputContainsConstantList = false;

  final List<ClassElement> nativeClassesAndSubclasses = <ClassElement>[];

  List<TypedefElement> typedefsNeededForReflection;

  JavaScriptBackend get backend => compiler.backend;

  BackendHelpers get helpers => backend.helpers;

  CoreClasses get coreClasses => compiler.coreClasses;

  Collector(this.compiler, this.namer, this.rtiNeededClasses, this.emitter);

  Set<ClassElement> computeInterceptorsReferencedFromConstants() {
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
    unneededClasses.add(coreClasses.boolClass);

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassElement> needed = new Set<ClassElement>();
    backend.specializedGetInterceptors.forEach(
        (_, Iterable<ClassElement> elements) {
          needed.addAll(elements);
        }
    );

    // Add interceptors referenced by constants.
    needed.addAll(computeInterceptorsReferencedFromConstants());

    // Add unneeded interceptors to the [unneededClasses] set.
    for (ClassElement interceptor in backend.interceptedClasses) {
      if (!needed.contains(interceptor)
          && interceptor != coreClasses.objectClass) {
        unneededClasses.add(interceptor);
      }
    }

    // These classes are just helpers for the backend's type system.
    unneededClasses.add(helpers.jsMutableArrayClass);
    unneededClasses.add(helpers.jsFixedArrayClass);
    unneededClasses.add(helpers.jsExtendableArrayClass);
    unneededClasses.add(helpers.jsUInt32Class);
    unneededClasses.add(helpers.jsUInt31Class);
    unneededClasses.add(helpers.jsPositiveIntClass);

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
          if (shouldRetainMetadata &&
              (element.isFunction || element.isConstructor ||
               element.isSetter)) {
            FunctionElement function = element;
            function.functionSignature.forEachParameter(
                backend.retainMetadataOf);
          }
        }
      }
      for (ClassElement cls in neededClasses) {
        final onlyForRti = classesOnlyNeededForRti.contains(cls);
        if (!onlyForRti) {
          backend.retainMetadataOf(cls);
          new FieldVisitor(compiler, namer).visitFields(cls, false,
              (Element member,
               js.Name name,
               js.Name accessorName,
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

    // 3. Find all classes needed for rti.
    // It is important that this is the penultimate step, at this point,
    // neededClasses must only contain classes that have been resolved and
    // codegen'd. The rtiNeededClasses may contain additional classes, but
    // these are thought to not have been instantiated, so we neeed to be able
    // to identify them later and make sure we only emit "empty shells" without
    // fields, etc.
    classesOnlyNeededForRti = rtiNeededClasses.difference(neededClasses);

    neededClasses.addAll(classesOnlyNeededForRti);

    // TODO(18175, floitsch): remove once issue 18175 is fixed.
    if (neededClasses.contains(helpers.jsIntClass)) {
      neededClasses.add(coreClasses.intClass);
    }
    if (neededClasses.contains(helpers.jsDoubleClass)) {
      neededClasses.add(coreClasses.doubleClass);
    }
    if (neededClasses.contains(helpers.jsNumberClass)) {
      neededClasses.add(coreClasses.numClass);
    }
    if (neededClasses.contains(helpers.jsStringClass)) {
      neededClasses.add(coreClasses.stringClass);
    }
    if (neededClasses.contains(helpers.jsBoolClass)) {
      neededClasses.add(coreClasses.boolClass);
    }
    if (neededClasses.contains(helpers.jsArrayClass)) {
      neededClasses.add(coreClasses.listClass);
    }

    // 4. Finally, sort the classes.
    List<ClassElement> sortedClasses = Elements.sortedByPosition(neededClasses);

    for (ClassElement element in sortedClasses) {
      if (backend.isNativeOrExtendsNative(element) &&
          !classesOnlyNeededForRti.contains(element)) {
        // For now, native classes and related classes cannot be deferred.
        nativeClassesAndSubclasses.add(element);
        assert(invariant(element,
                         !compiler.deferredLoadTask.isDeferred(element)));
        outputClassLists.putIfAbsent(compiler.deferredLoadTask.mainOutputUnit,
            () => new List<ClassElement>()).add(element);
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
      List<Element> list = outputStaticLists.putIfAbsent(
          compiler.deferredLoadTask.outputUnitForElement(element),
          () => new List<Element>());
      list.add(element);
    }
  }

  void computeNeededStaticNonFinalFields() {
    JavaScriptConstantCompiler handler = backend.constants;
    addToOutputUnit(Element element) {
      List<VariableElement> list = outputStaticNonFinalFieldLists.putIfAbsent(
          compiler.deferredLoadTask.outputUnitForElement(element),
              () => new List<VariableElement>());
      list.add(element);
    }

    Iterable<VariableElement> staticNonFinalFields = handler
        .getStaticNonFinalFieldsForEmission()
        .where(compiler.codegenWorld.allReferencedStaticFields.contains);

    Elements.sortedByPosition(staticNonFinalFields).forEach(addToOutputUnit);

    // We also need to emit static const fields if they are available for
    // reflection.
    compiler.codegenWorld.allReferencedStaticFields
        .where((FieldElement field) => field.isConst)
        .where(backend.isAccessibleByReflection)
        .forEach(addToOutputUnit);
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

  void collect() {
    computeNeededDeclarations();
    computeNeededConstants();
    computeNeededStatics();
    computeNeededStaticNonFinalFields();
    computeNeededLibraries();
  }
}