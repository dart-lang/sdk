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
  final ClosedWorld closedWorld;
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

  CommonElements get commonElements => compiler.commonElements;

  Collector(this.compiler, this.namer, this.closedWorld, this.rtiNeededClasses,
      this.emitter);

  Set<ClassElement> computeInterceptorsReferencedFromConstants() {
    Set<ClassElement> classes = new Set<ClassElement>();
    JavaScriptConstantCompiler handler = backend.constants;
    List<ConstantValue> constants = handler.getConstantsForEmission();
    for (ConstantValue constant in constants) {
      if (constant is InterceptorConstantValue) {
        InterceptorConstantValue interceptorConstant = constant;
        classes.add(interceptorConstant.cls);
      }
    }
    return classes;
  }

  /**
   * Return a function that returns true if its argument is a class
   * that needs to be emitted.
   */
  Function computeClassFilter() {
    if (backend.mirrorsData.isTreeShakingDisabled) {
      return (ClassElement cls) => true;
    }

    Set<ClassEntity> unneededClasses = new Set<ClassEntity>();
    // The [Bool] class is not marked as abstract, but has a factory
    // constructor that always throws. We never need to emit it.
    unneededClasses.add(commonElements.boolClass);

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassEntity> needed = new Set<ClassEntity>();
    for (js.Name name
        in backend.oneShotInterceptorData.specializedGetInterceptorNames) {
      needed.addAll(backend.oneShotInterceptorData
          .getSpecializedGetInterceptorsFor(name));
    }

    // Add interceptors referenced by constants.
    needed.addAll(computeInterceptorsReferencedFromConstants());

    // Add unneeded interceptors to the [unneededClasses] set.
    for (ClassEntity interceptor
        in backend.interceptorData.interceptedClasses) {
      if (!needed.contains(interceptor) &&
          interceptor != commonElements.objectClass) {
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

    return (ClassEntity cls) => !unneededClasses.contains(cls);
  }

  /**
   * Compute all the constants that must be emitted.
   */
  void computeNeededConstants() {
    // Make sure we retain all metadata of all elements. This could add new
    // constants to the handler.
    if (backend.mirrorsData.mustRetainMetadata) {
      // TODO(floitsch): verify that we don't run through the same elements
      // multiple times.
      for (Element element in backend.generatedCode.keys) {
        if (backend.mirrorsData.isAccessibleByReflection(element)) {
          bool shouldRetainMetadata =
              backend.mirrorsData.retainMetadataOf(element);
          if (shouldRetainMetadata &&
              (element.isFunction ||
                  element.isConstructor ||
                  element.isSetter)) {
            FunctionElement function = element;
            function.functionSignature
                .forEachParameter(backend.mirrorsData.retainMetadataOf);
          }
        }
      }
      for (ClassElement cls in neededClasses) {
        final onlyForRti = classesOnlyNeededForRti.contains(cls);
        if (!onlyForRti) {
          backend.mirrorsData.retainMetadataOf(cls);
          new FieldVisitor(compiler, namer, closedWorld).visitFields(cls, false,
              (Element member, js.Name name, js.Name accessorName,
                  bool needsGetter, bool needsSetter, bool needsCheckedSetter) {
            bool needsAccessor = needsGetter || needsSetter;
            if (needsAccessor &&
                backend.mirrorsData.isAccessibleByReflection(member)) {
              backend.mirrorsData.retainMetadataOf(member);
            }
          });
        }
      }
      typedefsNeededForReflection.forEach(backend.mirrorsData.retainMetadataOf);
    }

    JavaScriptConstantCompiler handler = backend.constants;
    List<ConstantValue> constants =
        handler.getConstantsForEmission(emitter.compareConstants);
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
      outputConstantLists
          .putIfAbsent(constantUnit, () => new List<ConstantValue>())
          .add(constant);
    }
  }

  /// Compute all the classes and typedefs that must be emitted.
  void computeNeededDeclarations() {
    // Compute needed typedefs.
    typedefsNeededForReflection = Elements.sortedByPosition(closedWorld
        .allTypedefs
        .where(backend.mirrorsData.isAccessibleByReflection)
        .toList());

    // Compute needed classes.
    Set<ClassElement> instantiatedClasses = compiler
        // TODO(johnniwinther): This should be accessed from a codegen closed
        // world.
        .codegenWorldBuilder
        .directlyInstantiatedClasses
        .where(computeClassFilter())
        .toSet();

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
      neededClasses.add(commonElements.intClass);
    }
    if (neededClasses.contains(helpers.jsDoubleClass)) {
      neededClasses.add(commonElements.doubleClass);
    }
    if (neededClasses.contains(helpers.jsNumberClass)) {
      neededClasses.add(commonElements.numClass);
    }
    if (neededClasses.contains(helpers.jsStringClass)) {
      neededClasses.add(commonElements.stringClass);
    }
    if (neededClasses.contains(helpers.jsBoolClass)) {
      neededClasses.add(commonElements.boolClass);
    }
    if (neededClasses.contains(helpers.jsArrayClass)) {
      neededClasses.add(commonElements.listClass);
    }

    // 4. Finally, sort the classes.
    List<ClassElement> sortedClasses = Elements.sortedByPosition(neededClasses);

    for (ClassElement element in sortedClasses) {
      if (backend.nativeData.isNativeOrExtendsNative(element) &&
          !classesOnlyNeededForRti.contains(element)) {
        // For now, native classes and related classes cannot be deferred.
        nativeClassesAndSubclasses.add(element);
        assert(
            invariant(element, !compiler.deferredLoadTask.isDeferred(element)));
        outputClassLists
            .putIfAbsent(compiler.deferredLoadTask.mainOutputUnit,
                () => new List<ClassElement>())
            .add(element);
      } else {
        outputClassLists
            .putIfAbsent(
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
    addToOutputUnit(Element element) {
      List<VariableElement> list = outputStaticNonFinalFieldLists.putIfAbsent(
          compiler.deferredLoadTask.outputUnitForElement(element),
          () => new List<VariableElement>());
      list.add(element);
    }

    Iterable<Element> fields = compiler
        // TODO(johnniwinther): This should be accessed from a codegen closed
        // world.
        .codegenWorldBuilder
        .allReferencedStaticFields
        .where((FieldElement field) {
      if (!field.isConst) {
        return field.isField &&
            !field.isInstanceMember &&
            !field.isFinal &&
            field.constant != null;
      } else {
        // We also need to emit static const fields if they are available for
        // reflection.
        return backend.mirrorsData.isAccessibleByReflection(field);
      }
    });

    Elements.sortedByPosition(fields).forEach(addToOutputUnit);
  }

  void computeNeededLibraries() {
    void addSurroundingLibraryToSet(Element element) {
      OutputUnit unit = compiler.deferredLoadTask.outputUnitForElement(element);
      LibraryElement library = element.library;
      outputLibraryLists
          .putIfAbsent(unit, () => new Set<LibraryElement>())
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
