// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.program_builder;

/// Generates the code for all used classes in the program. Static fields (even
/// in classes) are ignored, since they can be treated as non-class elements.
///
/// The code for the containing (used) methods must exist in the `universe`.
class Collector {
  final JCommonElements _commonElements;
  final JElementEnvironment _elementEnvironment;
  final OutputUnitData _outputUnitData;
  final CodegenWorld _codegenWorld;
  final Emitter _emitter;
  final NativeData _nativeData;
  final InterceptorData _interceptorData;
  final OneShotInterceptorData _oneShotInterceptorData;
  final JClosedWorld _closedWorld;
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
  final Map<OutputUnit, List<FieldEntity>> outputLazyStaticFieldLists = {};
  final Map<OutputUnit, Set<LibraryEntity>> outputLibraryLists =
      new Map<OutputUnit, Set<LibraryEntity>>();

  /// True, if the output contains a constant list.
  ///
  /// This flag is updated in [computeNeededConstants].
  bool outputContainsConstantList = false;

  final List<ClassEntity> nativeClassesAndSubclasses = <ClassEntity>[];

  Collector(
      this._commonElements,
      this._elementEnvironment,
      this._outputUnitData,
      this._codegenWorld,
      this._emitter,
      this._nativeData,
      this._interceptorData,
      this._oneShotInterceptorData,
      this._closedWorld,
      this._rtiNeededClasses,
      this._generatedCode,
      this._sorter);

  Set<ClassEntity> computeInterceptorsReferencedFromConstants() {
    Set<ClassEntity> classes = new Set<ClassEntity>();
    Iterable<ConstantValue> constants = _codegenWorld.getConstantsForEmission();
    for (ConstantValue constant in constants) {
      if (constant is InterceptorConstantValue) {
        InterceptorConstantValue interceptorConstant = constant;
        classes.add(interceptorConstant.cls);
      }
    }
    return classes;
  }

  /// Return a function that returns true if its argument is a class
  /// that needs to be emitted.
  Function computeClassFilter(Iterable<ClassEntity> backendTypeHelpers) {
    Set<ClassEntity> unneededClasses = new Set<ClassEntity>();
    // The [Bool] class is not marked as abstract, but has a factory
    // constructor that always throws. We never need to emit it.
    unneededClasses.add(_commonElements.boolClass);

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassEntity> needed = new Set<ClassEntity>();
    for (SpecializedGetInterceptor interceptor
        in _oneShotInterceptorData.specializedGetInterceptors) {
      needed.addAll(interceptor.classes);
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
      JCommonElements commonElements) {
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

  /// Compute all the constants that must be emitted.
  void computeNeededConstants() {
    Iterable<ConstantValue> constants =
        _codegenWorld.getConstantsForEmission(_emitter.compareConstants);
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
        _codegenWorld.directlyInstantiatedClasses
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
          _outputUnitData.outputUnitForMember(element),
          () => new List<FieldEntity>());
      list.add(element);
    }

    List<FieldEntity> eagerFields = [];
    _codegenWorld.forEachStaticField((FieldEntity field) {
      if (_closedWorld.fieldAnalysis.getFieldData(field).isEager) {
        eagerFields.add(field);
      }
    });

    eagerFields.sort((FieldEntity a, FieldEntity b) {
      FieldAnalysisData aFieldData = _closedWorld.fieldAnalysis.getFieldData(a);
      FieldAnalysisData bFieldData = _closedWorld.fieldAnalysis.getFieldData(b);
      int aIndex = aFieldData.eagerCreationIndex;
      int bIndex = bFieldData.eagerCreationIndex;
      if (aIndex != null && bIndex != null) {
        return aIndex.compareTo(bIndex);
      } else if (aIndex != null) {
        // Sort [b] before [a].
        return 1;
      } else if (bIndex != null) {
        // Sort [a] before [b].
        return -1;
      } else {
        return _sorter.compareMembersByLocation(a, b);
      }
    });
    eagerFields.forEach(addToOutputUnit);
  }

  void computeNeededLazyStaticFields() {
    List<FieldEntity> lazyFields = [];
    _codegenWorld.forEachStaticField((FieldEntity field) {
      if (_closedWorld.fieldAnalysis.getFieldData(field).isLazy) {
        lazyFields.add(field);
      }
    });

    for (FieldEntity field in _sorter.sortMembers(lazyFields)) {
      OutputUnit unit = _outputUnitData.outputUnitForMember(field);
      (outputLazyStaticFieldLists[unit] ??= []).add(field);
    }
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
    computeNeededLazyStaticFields();
    computeNeededLibraries();
  }
}
