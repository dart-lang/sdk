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
  final DeferredLoadTask _deferredLoadTask;
  final CodegenWorldBuilder _worldBuilder;
  // TODO(floitsch): the code-emitter task should not need a namer.
  final Namer _namer;
  final Emitter _emitter;
  final JavaScriptConstantCompiler _constantHandler;
  final NativeData _nativeData;
  final InterceptorData _interceptorData;
  final OneShotInterceptorData _oneShotInterceptorData;
  final MirrorsData _mirrorsData;
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

  final List<ClassElement> nativeClassesAndSubclasses = <ClassElement>[];

  List<TypedefElement> typedefsNeededForReflection;

  Collector(
      this._options,
      this._commonElements,
      this._deferredLoadTask,
      this._worldBuilder,
      this._namer,
      this._emitter,
      this._constantHandler,
      this._nativeData,
      this._interceptorData,
      this._oneShotInterceptorData,
      this._mirrorsData,
      this._closedWorld,
      this._rtiNeededClasses,
      this._generatedCode,
      this._sorter);

  Set<ClassElement> computeInterceptorsReferencedFromConstants() {
    Set<ClassElement> classes = new Set<ClassElement>();
    JavaScriptConstantCompiler handler = _constantHandler;
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
    if (_mirrorsData.isTreeShakingDisabled) {
      return (ClassElement cls) => true;
    }

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
    unneededClasses.add(_commonElements.jsMutableArrayClass);
    unneededClasses.add(_commonElements.jsFixedArrayClass);
    unneededClasses.add(_commonElements.jsExtendableArrayClass);
    unneededClasses.add(_commonElements.jsUInt32Class);
    unneededClasses.add(_commonElements.jsUInt31Class);
    unneededClasses.add(_commonElements.jsPositiveIntClass);

    return (ClassEntity cls) => !unneededClasses.contains(cls);
  }

  /**
   * Compute all the constants that must be emitted.
   */
  void computeNeededConstants() {
    // Make sure we retain all metadata of all elements. This could add new
    // constants to the handler.
    if (_mirrorsData.mustRetainMetadata) {
      // TODO(floitsch): verify that we don't run through the same elements
      // multiple times.
      for (MemberElement element in _generatedCode.keys) {
        if (_mirrorsData.isMemberAccessibleByReflection(element)) {
          bool shouldRetainMetadata =
              _mirrorsData.retainMetadataOfMember(element);
          if (shouldRetainMetadata &&
              (element.isFunction ||
                  element.isConstructor ||
                  element.isSetter)) {
            MethodElement function = element;
            function.functionSignature
                .forEachParameter(_mirrorsData.retainMetadataOfParameter);
          }
        }
      }
      for (ClassElement cls in neededClasses) {
        final onlyForRti = classesOnlyNeededForRti.contains(cls);
        if (!onlyForRti) {
          _mirrorsData.retainMetadataOfClass(cls);
          new FieldVisitor(_options, _worldBuilder, _nativeData, _mirrorsData,
                  _namer, _closedWorld)
              .visitFields(cls, false, (FieldElement member,
                  js.Name name,
                  js.Name accessorName,
                  bool needsGetter,
                  bool needsSetter,
                  bool needsCheckedSetter) {
            bool needsAccessor = needsGetter || needsSetter;
            if (needsAccessor &&
                _mirrorsData.isMemberAccessibleByReflection(member)) {
              _mirrorsData.retainMetadataOfMember(member);
            }
          });
        }
      }
      typedefsNeededForReflection.forEach(_mirrorsData.retainMetadataOfTypedef);
    }

    JavaScriptConstantCompiler handler = _constantHandler;
    List<ConstantValue> constants =
        handler.getConstantsForEmission(_emitter.compareConstants);
    for (ConstantValue constant in constants) {
      if (_emitter.isConstantInlinedOrAlreadyEmitted(constant)) continue;

      if (constant.isList) outputContainsConstantList = true;

      OutputUnit constantUnit =
          _deferredLoadTask.outputUnitForConstant(constant);
      if (constantUnit == null) {
        // The back-end introduces some constants, like "InterceptorConstant" or
        // some list constants. They are emitted in the main output-unit.
        // TODO(sigurdm): We should track those constants.
        constantUnit = _deferredLoadTask.mainOutputUnit;
      }
      outputConstantLists
          .putIfAbsent(constantUnit, () => new List<ConstantValue>())
          .add(constant);
    }
  }

  /// Compute all the classes and typedefs that must be emitted.
  void computeNeededDeclarations() {
    // Compute needed typedefs.
    typedefsNeededForReflection = Elements.sortedByPosition(_closedWorld
        .allTypedefs
        .where(_mirrorsData.isTypedefAccessibleByReflection)
        .toList());

    // Compute needed classes.
    Set<ClassEntity> instantiatedClasses =
        // TODO(johnniwinther): This should be accessed from a codegen closed
        // world.
        _worldBuilder.directlyInstantiatedClasses
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

    void addClassesWithSuperclasses(Iterable<ClassEntity> classes) {
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
    classesOnlyNeededForRti = new Set<ClassElement>();
    for (ClassElement cls in _rtiNeededClasses) {
      while (cls != null && !neededClasses.contains(cls)) {
        if (!classesOnlyNeededForRti.add(cls)) break;
        cls = cls.superclass;
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
        assert(!_deferredLoadTask.isDeferredClass(cls), failedAt(cls));
        outputClassLists
            .putIfAbsent(_deferredLoadTask.mainOutputUnit,
                () => new List<ClassElement>())
            .add(cls);
      } else {
        outputClassLists
            .putIfAbsent(_deferredLoadTask.outputUnitForClass(cls),
                () => new List<ClassElement>())
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
          _deferredLoadTask.outputUnitForMember(member),
          () => new List<MemberEntity>());
      list.add(member);
    }
  }

  void computeNeededStaticNonFinalFields() {
    addToOutputUnit(FieldEntity element) {
      List<FieldEntity> list = outputStaticNonFinalFieldLists.putIfAbsent(
          // ignore: UNNECESSARY_CAST
          _deferredLoadTask.outputUnitForMember(element as MemberEntity),
          () => new List<FieldEntity>());
      list.add(element);
    }

    Iterable<FieldEntity> fields =
        // TODO(johnniwinther): This should be accessed from a codegen closed
        // world.
        _worldBuilder.allReferencedStaticFields.where((FieldElement field) {
      if (!field.isConst) {
        return field.isField &&
            !field.isInstanceMember &&
            !field.isFinal &&
            field.constant != null;
      } else {
        // We also need to emit static const fields if they are available for
        // reflection.
        return _mirrorsData.isMemberAccessibleByReflection(field);
      }
    });

    _sorter.sortMembers(fields).forEach(addToOutputUnit);
  }

  void computeNeededLibraries() {
    _generatedCode.keys.forEach((MemberEntity element) {
      OutputUnit unit = _deferredLoadTask.outputUnitForMember(element);
      LibraryEntity library = element.library;
      outputLibraryLists
          .putIfAbsent(unit, () => new Set<LibraryEntity>())
          .add(library);
    });
    neededClasses.forEach((ClassEntity element) {
      OutputUnit unit = _deferredLoadTask.outputUnitForClass(element);
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
