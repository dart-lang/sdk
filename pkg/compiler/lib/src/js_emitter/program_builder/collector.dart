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

  final Set<ClassEntity> neededClasses = {};
  final Set<ClassEntity> neededClassTypes = {};
  final Set<ClassEntity> classesOnlyNeededForRti = {};
  final Set<ClassEntity> classesOnlyNeededForConstructor = {};
  final Map<OutputUnit, List<ClassEntity>> outputClassLists = {};
  final Map<OutputUnit, List<ClassEntity>> outputClassTypeLists = {};
  final Map<OutputUnit, List<ConstantValue>> outputConstantLists = {};
  final Map<OutputUnit, List<MemberEntity>> outputStaticLists = {};
  final Map<OutputUnit, List<FieldEntity>> outputStaticNonFinalFieldLists = {};
  final Map<OutputUnit, List<FieldEntity>> outputLazyStaticFieldLists = {};
  final Map<OutputUnit, Set<LibraryEntity>> outputLibraryLists = {};

  /// True, if the output contains a constant list.
  ///
  /// This flag is updated in [computeNeededConstants].
  bool outputContainsConstantList = false;

  final List<ClassEntity> nativeClassesAndSubclasses = [];

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
    Set<ClassEntity> classes = {};
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
    Set<ClassEntity> unneededClasses = {};
    // The [Bool] class is not marked as abstract, but has a factory
    // constructor that always throws. We never need to emit it.
    unneededClasses.add(_commonElements.boolClass);

    // Go over specialized interceptors and then constants to know which
    // interceptors are needed.
    Set<ClassEntity> needed = {};
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
    return [
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
      outputConstantLists.putIfAbsent(constantUnit, () => []).add(constant);
    }
  }

  /// Compute all the classes and typedefs that must be emitted.
  void computeNeededDeclarations() {
    Set<ClassEntity> backendTypeHelpers =
        getBackendTypeHelpers(_commonElements).toSet();

    /// A class type is 'shadowed' if the class is needed for direct
    /// instantiation in one OutputUnit while its type is needed in another
    /// OutputUnit.
    bool isClassTypeShadowed(ClassEntity cls) {
      return !backendTypeHelpers.contains(cls) &&
          _rtiNeededClasses.contains(cls) &&
          !classesOnlyNeededForRti.contains(cls) &&
          _outputUnitData.outputUnitForClass(cls) !=
              _outputUnitData.outputUnitForClassType(cls);
    }

    // Compute needed classes.
    Set<ClassEntity> instantiatedClasses =
        // TODO(johnniwinther): This should be accessed from a codegen closed
        // world.
        _codegenWorld.directlyInstantiatedClasses
            .where(computeClassFilter(backendTypeHelpers))
            .toSet();

    void addClassesWithSuperclasses(Iterable<ClassEntity> classes) {
      for (ClassEntity cls in classes) {
        neededClasses.add(cls);
        _elementEnvironment.forEachSuperClass(
            cls, (superClass) => neededClasses.add(superClass));
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

    // 3. Add classes only needed for their constructors.
    for (var cls in _codegenWorld.constructorReferences) {
      if (neededClasses.add(cls)) {
        classesOnlyNeededForConstructor.add(cls);
      }
    }

    // 4. Find all classes needed for rti.
    // It is important that this is the penultimate step, at this point,
    // neededClasses must only contain classes that have been resolved and
    // codegen'd. The rtiNeededClasses may contain additional classes, but
    // these are thought to not have been instantiated, so we need to be able
    // to identify them later and make sure we only emit "empty shells" without
    // fields, etc.
    for (ClassEntity cls in _rtiNeededClasses) {
      if (backendTypeHelpers.contains(cls)) continue;
      while (cls != null && !neededClasses.contains(cls)) {
        if (!classesOnlyNeededForRti.add(cls)) break;
        // TODO(joshualitt) delete classesOnlyNeededForRti when the
        // no-defer-class_types flag is removed.
        neededClassTypes.add(cls);
        cls = _elementEnvironment.getSuperClass(cls);
      }
    }

    // 5. Sort classes and add them to their respective OutputUnits.
    for (ClassEntity cls in _sorter.sortClasses(neededClasses)) {
      if (_nativeData.isNativeOrExtendsNative(cls) &&
          !classesOnlyNeededForConstructor.contains(cls)) {
        // For now, native classes and related classes cannot be deferred.
        nativeClassesAndSubclasses.add(cls);
        assert(!_outputUnitData.isDeferredClass(cls), failedAt(cls));
        outputClassLists
            .putIfAbsent(_outputUnitData.mainOutputUnit, () => [])
            .add(cls);
      } else {
        outputClassLists
            .putIfAbsent(_outputUnitData.outputUnitForClass(cls), () => [])
            .add(cls);
      }
    }

    // 6. Collect any class types 'shadowed' by direct instantiation.
    for (ClassEntity cls in _rtiNeededClasses) {
      if (isClassTypeShadowed(cls)) {
        neededClassTypes.add(cls);
      }
    }

    // 7. Sort classes needed for type checking and then add them to their
    // respective OutputUnits.
    for (ClassEntity cls in _sorter.sortClasses(neededClassTypes)) {
      outputClassTypeLists
          .putIfAbsent(_outputUnitData.outputUnitForClassType(cls), () => [])
          .add(cls);
    }
  }

  void computeNeededStatics() {
    bool isStaticFunction(MemberEntity element) =>
        !element.isInstanceMember && !element.isField;

    Iterable<MemberEntity> elements =
        _generatedCode.keys.where(isStaticFunction);

    for (MemberEntity member in _sorter.sortMembers(elements)) {
      List<MemberEntity> list = outputStaticLists.putIfAbsent(
          _outputUnitData.outputUnitForMember(member), () => []);
      list.add(member);
    }
  }

  void computeNeededStaticNonFinalFields() {
    addToOutputUnit(FieldEntity element) {
      List<FieldEntity> list = outputStaticNonFinalFieldLists.putIfAbsent(
          _outputUnitData.outputUnitForMember(element), () => []);
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
      outputLibraryLists.putIfAbsent(unit, () => {}).add(library);
    });
    neededClasses.forEach((ClassEntity element) {
      OutputUnit unit = _outputUnitData.outputUnitForClass(element);
      LibraryEntity library = element.library;
      outputLibraryLists.putIfAbsent(unit, () => {}).add(library);
    });
    neededClassTypes.forEach((ClassEntity element) {
      OutputUnit unit = _outputUnitData.outputUnitForClassType(element);
      LibraryEntity library = element.library;
      outputLibraryLists.putIfAbsent(unit, () => {}).add(library);
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
