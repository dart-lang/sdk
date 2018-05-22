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
  final CompilerOptions _options;
  final CommonElements _commonElements;
  final ElementEnvironment _elementEnvironment;
  final OutputUnitData _outputUnitData;
  final CodegenWorldBuilder _worldBuilder;
  // TODO(floitsch): the code-emitter task should not need a namer.
  final Namer _namer;
  final Emitter _emitter;
  final JavaScriptConstantCompiler _constantHandler;
  final NativeData _nativeData;
  final InterceptorData _interceptorData;
  final OneShotInterceptorData _oneShotInterceptorData;
  final ClosedWorld _closedWorld;
  final Set<ClassEntity> _rtiNeededClasses;
  final Map<MemberEntity, js.Expression> _generatedCode;
  final Sorter _sorter;

  final Set<ClassEntity> neededClasses = new Set<ClassEntity>();
  // This field is set in [computeNeededDeclarations].
  Set<ClassEntity> classesOnlyNeededForRti;
  final Map<OutputUnit, List<ClassEntity>> outputClassLists =
      new Map<OutputUnit, List<ClassEntity>>();
  final Map<OutputUnit, List<ConstantValue>> outputConstantLists =
      new Map<OutputUnit, List<ConstantValue>>();
  final Map<OutputUnit, List<MemberEntity>> outputStaticLists =
      new Map<OutputUnit, List<MemberEntity>>();
  final Map<OutputUnit, List<FieldEntity>> outputStaticNonFinalFieldLists =
      new Map<OutputUnit, List<FieldEntity>>();
  final Map<OutputUnit, Set<LibraryEntity>> outputLibraryLists =
      new Map<OutputUnit, Set<LibraryEntity>>();

  /// True, if the output contains a constant list.
  ///
  /// This flag is updated in [computeNeededConstants].
  bool outputContainsConstantList = false;

  final List<ClassEntity> nativeClassesAndSubclasses = <ClassEntity>[];

  Collector(
      this._options,
      this._commonElements,
      this._elementEnvironment,
      this._outputUnitData,
      this._worldBuilder,
      this._namer,
      this._emitter,
      this._constantHandler,
      this._nativeData,
      this._interceptorData,
      this._oneShotInterceptorData,
      this._closedWorld,
      this._rtiNeededClasses,
      this._generatedCode,
      this._sorter);

  Set<ClassEntity> computeInterceptorsReferencedFromConstants() {
    Set<ClassEntity> classes = new Set<ClassEntity>();
    List<ConstantValue> constants = _worldBuilder.getConstantsForEmission();
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
  Function computeClassFilter(Iterable<ClassEntity> backendTypeHelpers) {
    Set<ClassEntity> unneededClasses = new Set<ClassEntity>();
    // The [Bool] class is not marked as abstract, but has a factory
    // constructor that always throws. We never need to emit it.
    unneededClasses.add(_commonElements.boolClass);

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassEntity> needed = new Set<ClassEntity>();
    for (js.Name name
        in _oneShotInterceptorData.specializedGetInterceptorNames) {
      needed.addAll(
          _oneShotInterceptorData.getSpecializedGetInterceptorsFor(name));
    }

    // Add interceptors referenced by constants.
    needed.addAll(computeInterceptorsReferencedFromConstants());

    // Add unneeded interceptors to the [unneededClasses] set.
    for (ClassEntity interceptor in _interceptorData.interceptedClasses) {
      if (!needed.contains(interceptor) &&
          interceptor != _commonElements.objectClass) {
        unneededClasses.add(interceptor);
      }
    }

    // These classes are just helpers for the backend's type system.
    unneededClasses.addAll(backendTypeHelpers);

    return (ClassEntity cls) => !unneededClasses.contains(cls);
  }

  // Return the classes that are just helpers for the backend's type system.
  static Iterable<ClassEntity> getBackendTypeHelpers(
      CommonElements commonElements) {
    return <ClassEntity>[
      commonElements.jsMutableArrayClass,
      commonElements.jsFixedArrayClass,
      commonElements.jsExtendableArrayClass,
      // TODO(johnniwinther): Mark this as a backend type helper:
      //commonElements.jsUnmodifiableArrayClass,
      commonElements.jsUInt32Class,
      commonElements.jsUInt31Class,
      commonElements.jsPositiveIntClass
    ];
  }

  /**
   * Compute all the constants that must be emitted.
   */
  void computeNeededConstants() {
    List<ConstantValue> constants =
        _worldBuilder.getConstantsForEmission(_emitter.compareConstants);
    for (ConstantValue constant in constants) {
      if (_emitter.isConstantInlinedOrAlreadyEmitted(constant)) continue;

      if (constant.isList) outputContainsConstantList = true;

      OutputUnit constantUnit = _outputUnitData.outputUnitForConstant(constant);
      if (constantUnit == null) {
        // The back-end introduces some constants, like "InterceptorConstant" or
        // some list constants. They are emitted in the main output-unit.
        // TODO(sigurdm): We should track those constants.
        constantUnit = _outputUnitData.mainOutputUnit;
      }
      outputConstantLists
          .putIfAbsent(constantUnit, () => new List<ConstantValue>())
          .add(constant);
    }
  }

  /// Compute all the classes and typedefs that must be emitted.
  void computeNeededDeclarations() {
    Set<ClassEntity> backendTypeHelpers =
        getBackendTypeHelpers(_commonElements).toSet();

    // Compute needed classes.
    Set<ClassEntity> instantiatedClasses =
        // TODO(johnniwinther): This should be accessed from a codegen closed
        // world.
        _worldBuilder.directlyInstantiatedClasses
            .where(computeClassFilter(backendTypeHelpers))
            .toSet();

    void addClassWithSuperclasses(ClassEntity cls) {
      neededClasses.add(cls);
      for (ClassEntity superclass = _elementEnvironment.getSuperClass(cls);
          superclass != null;
          superclass = _elementEnvironment.getSuperClass(superclass)) {
        neededClasses.add(superclass);
      }
    }

    void addClassesWithSuperclasses(Iterable<ClassEntity> classes) {
      for (ClassEntity cls in classes) {
        addClassWithSuperclasses(cls);
      }
    }

    // 1. We need to generate all classes that are instantiated.
    addClassesWithSuperclasses(instantiatedClasses);

    // 2. Add all classes used as mixins.
    Set<ClassEntity> mixinClasses = neededClasses
        .where(_elementEnvironment.isMixinApplication)
        .map(_elementEnvironment.getEffectiveMixinClass)
        .toSet();
    neededClasses.addAll(mixinClasses);

    // 3. Find all classes needed for rti.
    // It is important that this is the penultimate step, at this point,
    // neededClasses must only contain classes that have been resolved and
    // codegen'd. The rtiNeededClasses may contain additional classes, but
    // these are thought to not have been instantiated, so we need to be able
    // to identify them later and make sure we only emit "empty shells" without
    // fields, etc.
    classesOnlyNeededForRti = new Set<ClassEntity>();
    for (ClassEntity cls in _rtiNeededClasses) {
      if (backendTypeHelpers.contains(cls)) continue;
      while (cls != null && !neededClasses.contains(cls)) {
        if (!classesOnlyNeededForRti.add(cls)) break;
        cls = _elementEnvironment.getSuperClass(cls);
      }
    }

    neededClasses.addAll(classesOnlyNeededForRti);

    // TODO(18175, floitsch): remove once issue 18175 is fixed.
    if (neededClasses.contains(_commonElements.jsIntClass)) {
      neededClasses.add(_commonElements.intClass);
    }
    if (neededClasses.contains(_commonElements.jsDoubleClass)) {
      neededClasses.add(_commonElements.doubleClass);
    }
    if (neededClasses.contains(_commonElements.jsNumberClass)) {
      neededClasses.add(_commonElements.numClass);
    }
    if (neededClasses.contains(_commonElements.jsStringClass)) {
      neededClasses.add(_commonElements.stringClass);
    }
    if (neededClasses.contains(_commonElements.jsBoolClass)) {
      neededClasses.add(_commonElements.boolClass);
    }
    if (neededClasses.contains(_commonElements.jsArrayClass)) {
      neededClasses.add(_commonElements.listClass);
    }

    // 4. Finally, sort the classes.
    List<ClassEntity> sortedClasses = _sorter.sortClasses(neededClasses);

    for (ClassEntity cls in sortedClasses) {
      if (_nativeData.isNativeOrExtendsNative(cls) &&
          !classesOnlyNeededForRti.contains(cls)) {
        // For now, native classes and related classes cannot be deferred.
        nativeClassesAndSubclasses.add(cls);
        assert(!_outputUnitData.isDeferredClass(cls), failedAt(cls));
        outputClassLists
            .putIfAbsent(
                _outputUnitData.mainOutputUnit, () => new List<ClassEntity>())
            .add(cls);
      } else {
        outputClassLists
            .putIfAbsent(_outputUnitData.outputUnitForClass(cls),
                () => new List<ClassEntity>())
            .add(cls);
      }
    }
  }

  void computeNeededStatics() {
    bool isStaticFunction(MemberEntity element) =>
        !element.isInstanceMember && !element.isField;

    Iterable<MemberEntity> elements =
        _generatedCode.keys.where(isStaticFunction);

    for (MemberEntity member in _sorter.sortMembers(elements)) {
      List<MemberEntity> list = outputStaticLists.putIfAbsent(
          _outputUnitData.outputUnitForMember(member),
          () => new List<MemberEntity>());
      list.add(member);
    }
  }

  void computeNeededStaticNonFinalFields() {
    addToOutputUnit(FieldEntity element) {
      List<FieldEntity> list = outputStaticNonFinalFieldLists.putIfAbsent(
          // ignore: UNNECESSARY_CAST
          _outputUnitData.outputUnitForMember(element as MemberEntity),
          () => new List<FieldEntity>());
      list.add(element);
    }

    Iterable<FieldEntity> fields =
        // TODO(johnniwinther): This should be accessed from a codegen closed
        // world.
        _worldBuilder.allReferencedStaticFields.where((FieldEntity field) {
      return field.isAssignable &&
          _worldBuilder.hasConstantFieldInitializer(field);
    });

    _sorter.sortMembers(fields).forEach((MemberEntity e) => addToOutputUnit(e));
  }

  void computeNeededLibraries() {
    _generatedCode.keys.forEach((MemberEntity element) {
      OutputUnit unit = _outputUnitData.outputUnitForMember(element);
      LibraryEntity library = element.library;
      outputLibraryLists
          .putIfAbsent(unit, () => new Set<LibraryEntity>())
          .add(library);
    });
    neededClasses.forEach((ClassEntity element) {
      OutputUnit unit = _outputUnitData.outputUnitForClass(element);
      LibraryEntity library = element.library;
      outputLibraryLists
          .putIfAbsent(unit, () => new Set<LibraryEntity>())
          .add(library);
    });
  }

  void collect() {
    computeNeededDeclarations();
    computeNeededConstants();
    computeNeededStatics();
    computeNeededStaticNonFinalFields();
    computeNeededLibraries();
  }
}
