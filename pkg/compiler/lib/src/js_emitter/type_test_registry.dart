// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.type_test_registry;

import '../common.dart';
import '../common_elements.dart';
import '../elements/elements.dart' show ClassElement, MethodElement;
import '../elements/entities.dart';
import '../elements/types.dart' show DartType;
import '../elements/resolution_types.dart'
    show ResolutionFunctionType, ResolutionTypeVariableType;
import '../elements/types.dart';
import '../js_backend/runtime_types.dart'
    show
        RuntimeTypesChecks,
        RuntimeTypesChecksBuilder,
        RuntimeTypesSubstitutions,
        TypeChecks;
import '../js_backend/mirrors_data.dart';
import '../universe/world_builder.dart';
import '../world.dart' show ClosedWorld;

class TypeTestRegistry {
  final ElementEnvironment _elementEnvironment;

  /**
   * Raw ClassElement symbols occurring in is-checks and type assertions.  If the
   * program contains parameterized checks `x is Set<int>` and
   * `x is Set<String>` then the ClassElement `Set` will occur once in
   * [checkedClasses].
   */
  Set<ClassEntity> checkedClasses;

  /**
   * The set of function types that checked, both explicity through tests of
   * typedefs and implicitly through type annotations in checked mode.
   */
  Set<FunctionType> checkedFunctionTypes;

  /// After [computeNeededClasses] this set only contains classes that are only
  /// used for RTI.
  Set<ClassEntity> _rtiNeededClasses;

  Iterable<ClassEntity> cachedClassesUsingTypeVariableTests;

  Iterable<ClassEntity> get classesUsingTypeVariableTests {
    if (cachedClassesUsingTypeVariableTests == null) {
      cachedClassesUsingTypeVariableTests = _codegenWorldBuilder.isChecks
          .where((DartType t) => t is ResolutionTypeVariableType)
          .map((DartType _v) {
        ResolutionTypeVariableType v = _v;
        return v.element.enclosingClass;
      }).toList();
    }
    return cachedClassesUsingTypeVariableTests;
  }

  final CodegenWorldBuilder _codegenWorldBuilder;
  final ClosedWorld _closedWorld;

  RuntimeTypesChecks _rtiChecks;

  TypeTestRegistry(
      this._codegenWorldBuilder, this._closedWorld, this._elementEnvironment);

  RuntimeTypesChecks get rtiChecks {
    assert(
        _rtiChecks != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesChecks has not been computed yet."));
    return _rtiChecks;
  }

  Iterable<ClassEntity> get rtiNeededClasses {
    assert(
        _rtiNeededClasses != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "rtiNeededClasses has not been computed yet."));
    return _rtiNeededClasses;
  }

  /**
   * Returns the classes with constructors used as a 'holder' in
   * [emitRuntimeTypeSupport].
   * TODO(9556): Some cases will go away when the class objects are created as
   * complete.  Not all classes will go away while constructors are referenced
   * from type substitutions.
   */
  Set<ClassElement> computeClassesModifiedByEmitRuntimeTypeSupport() {
    TypeChecks typeChecks = rtiChecks.requiredChecks;
    Set<ClassElement> result = new Set<ClassElement>();
    for (ClassElement cls in typeChecks.classes) {
      if (typeChecks[cls].isNotEmpty) result.add(cls);
    }
    return result;
  }

  void computeRtiNeededClasses(RuntimeTypesSubstitutions rtiSubstitutions,
      MirrorsData mirrorsData, Iterable<MemberEntity> liveMembers) {
    _rtiNeededClasses = new Set<ClassEntity>();

    void addClassWithSuperclasses(ClassElement cls) {
      _rtiNeededClasses.add(cls);
      for (ClassElement superclass = cls.superclass;
          superclass != null;
          superclass = superclass.superclass) {
        _rtiNeededClasses.add(superclass);
      }
    }

    void addClassesWithSuperclasses(Iterable<ClassEntity> classes) {
      for (ClassEntity cls in classes) {
        addClassWithSuperclasses(cls);
      }
    }

    // 1.  Add classes that are referenced by type arguments or substitutions in
    //     argument checks.
    // TODO(karlklose): merge this case with 2 when unifying argument and
    // object checks.
    rtiChecks
        .getRequiredArgumentClasses()
        .forEach((e) => addClassWithSuperclasses(e));

    // 2.  Add classes that are referenced by substitutions in object checks and
    //     their superclasses.
    TypeChecks requiredChecks =
        rtiSubstitutions.computeChecks(rtiNeededClasses, checkedClasses);
    Set<ClassEntity> classesUsedInSubstitutions =
        rtiSubstitutions.getClassesUsedInSubstitutions(requiredChecks);
    addClassesWithSuperclasses(classesUsedInSubstitutions);

    // 3.  Add classes that contain checked generic function types. These are
    //     needed to store the signature encoding.
    for (ResolutionFunctionType type in checkedFunctionTypes) {
      ClassElement contextClass = DartTypes.getClassContext(type);
      if (contextClass != null) {
        _rtiNeededClasses.add(contextClass);
      }
    }

    bool canTearOff(MemberEntity function) {
      if (!function.isFunction ||
          function.isConstructor ||
          function.isGetter ||
          function.isSetter) {
        return false;
      } else if (function.isInstanceMember) {
        if (!function.enclosingClass.isClosure) {
          return _codegenWorldBuilder.hasInvokedGetter(function, _closedWorld);
        }
      }
      return false;
    }

    bool canBeReflectedAsFunction(MemberEntity element) {
      return !element.isField;
    }

    bool canBeReified(MemberEntity element) {
      return (canTearOff(element) ||
          mirrorsData.isMemberAccessibleByReflection(element));
    }

    // Find all types referenced from the types of elements that can be
    // reflected on 'as functions'.
    liveMembers.where((MemberEntity element) {
      return canBeReflectedAsFunction(element) && canBeReified(element);
    }).forEach((_function) {
      MethodElement function = _function;
      FunctionType type = function.type;
      for (ClassEntity cls in _rtiChecks.getReferencedClasses(type)) {
        while (cls != null) {
          _rtiNeededClasses.add(cls);
          cls = _elementEnvironment.getSuperClass(cls);
        }
      }
    });
  }

  void computeRequiredTypeChecks(RuntimeTypesChecksBuilder rtiChecksBuilder) {
    assert(checkedClasses == null && checkedFunctionTypes == null);

    rtiChecksBuilder.registerImplicitChecks(
        _codegenWorldBuilder, classesUsingTypeVariableTests);
    _rtiChecks = rtiChecksBuilder.computeRequiredChecks(_codegenWorldBuilder);

    checkedClasses = new Set<ClassEntity>();
    checkedFunctionTypes = new Set<FunctionType>();
    _codegenWorldBuilder.isChecks.forEach((DartType t) {
      if (t is InterfaceType) {
        checkedClasses.add(t.element);
      } else if (t is FunctionType) {
        checkedFunctionTypes.add(t);
      }
    });
  }
}
