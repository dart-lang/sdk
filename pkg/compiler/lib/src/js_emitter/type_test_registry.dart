// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.type_test_registry;

import '../common.dart';
import '../elements/resolution_types.dart'
    show
        ResolutionDartType,
        ResolutionFunctionType,
        ResolutionInterfaceType,
        Types,
        ResolutionTypeVariableType;
import '../elements/elements.dart'
    show ClassElement, Element, ElementKind, MemberElement, MethodElement;
import '../js_backend/js_backend.dart'
    show
        RuntimeTypesChecks,
        RuntimeTypesChecksBuilder,
        RuntimeTypesSubstitutions,
        TypeChecks;
import '../js_backend/mirrors_data.dart';
import '../universe/world_builder.dart';
import '../world.dart' show ClosedWorld;

class TypeTestRegistry {
  /**
   * Raw ClassElement symbols occurring in is-checks and type assertions.  If the
   * program contains parameterized checks `x is Set<int>` and
   * `x is Set<String>` then the ClassElement `Set` will occur once in
   * [checkedClasses].
   */
  Set<ClassElement> checkedClasses;

  /**
   * The set of function types that checked, both explicity through tests of
   * typedefs and implicitly through type annotations in checked mode.
   */
  Set<ResolutionFunctionType> checkedFunctionTypes;

  /// After [computeNeededClasses] this set only contains classes that are only
  /// used for RTI.
  Set<ClassElement> _rtiNeededClasses;

  Iterable<ClassElement> cachedClassesUsingTypeVariableTests;

  Iterable<ClassElement> get classesUsingTypeVariableTests {
    if (cachedClassesUsingTypeVariableTests == null) {
      cachedClassesUsingTypeVariableTests = _codegenWorldBuilder.isChecks
          .where((ResolutionDartType t) => t is ResolutionTypeVariableType)
          .map((ResolutionTypeVariableType v) => v.element.enclosingClass)
          .toList();
    }
    return cachedClassesUsingTypeVariableTests;
  }

  final CodegenWorldBuilder _codegenWorldBuilder;
  final ClosedWorld _closedWorld;

  RuntimeTypesChecks _rtiChecks;

  TypeTestRegistry(this._codegenWorldBuilder, this._closedWorld);

  RuntimeTypesChecks get rtiChecks {
    assert(invariant(NO_LOCATION_SPANNABLE, _rtiChecks != null,
        message: "RuntimeTypesChecks has not been computed yet."));
    return _rtiChecks;
  }

  Iterable<ClassElement> get rtiNeededClasses {
    assert(invariant(NO_LOCATION_SPANNABLE, _rtiNeededClasses != null,
        message: "rtiNeededClasses has not been computed yet."));
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
      MirrorsData mirrorsData, Iterable<MemberElement> liveMembers) {
    _rtiNeededClasses = new Set<ClassElement>();

    void addClassWithSuperclasses(ClassElement cls) {
      _rtiNeededClasses.add(cls);
      for (ClassElement superclass = cls.superclass;
          superclass != null;
          superclass = superclass.superclass) {
        _rtiNeededClasses.add(superclass);
      }
    }

    void addClassesWithSuperclasses(Iterable<ClassElement> classes) {
      for (ClassElement cls in classes) {
        addClassWithSuperclasses(cls);
      }
    }

    // 1.  Add classes that are referenced by type arguments or substitutions in
    //     argument checks.
    // TODO(karlklose): merge this case with 2 when unifying argument and
    // object checks.
    rtiChecks.getRequiredArgumentClasses().forEach(addClassWithSuperclasses);

    // 2.  Add classes that are referenced by substitutions in object checks and
    //     their superclasses.
    TypeChecks requiredChecks =
        rtiSubstitutions.computeChecks(rtiNeededClasses, checkedClasses);
    Set<ClassElement> classesUsedInSubstitutions =
        rtiSubstitutions.getClassesUsedInSubstitutions(requiredChecks);
    addClassesWithSuperclasses(classesUsedInSubstitutions);

    // 3.  Add classes that contain checked generic function types. These are
    //     needed to store the signature encoding.
    for (ResolutionFunctionType type in checkedFunctionTypes) {
      ClassElement contextClass = Types.getClassContext(type);
      if (contextClass != null) {
        _rtiNeededClasses.add(contextClass);
      }
    }

    bool canTearOff(Element function) {
      if (!function.isFunction ||
          function.isConstructor ||
          function.isAccessor) {
        return false;
      } else if (function.isInstanceMember) {
        if (!function.enclosingClass.isClosure) {
          return _codegenWorldBuilder.hasInvokedGetter(function, _closedWorld);
        }
      }
      return false;
    }

    bool canBeReflectedAsFunction(MemberElement element) {
      return element.kind == ElementKind.FUNCTION ||
          element.kind == ElementKind.GETTER ||
          element.kind == ElementKind.SETTER ||
          element.kind == ElementKind.GENERATIVE_CONSTRUCTOR;
    }

    bool canBeReified(MemberElement element) {
      return (canTearOff(element) ||
          mirrorsData.isMemberAccessibleByReflection(element));
    }

    // Find all types referenced from the types of elements that can be
    // reflected on 'as functions'.
    liveMembers.where((MemberElement element) {
      return canBeReflectedAsFunction(element) && canBeReified(element);
    }).forEach((MethodElement function) {
      ResolutionDartType type = function.type;
      for (ClassElement cls in _rtiChecks.getReferencedClasses(type)) {
        while (cls != null) {
          _rtiNeededClasses.add(cls);
          cls = cls.superclass;
        }
      }
    });
  }

  void computeRequiredTypeChecks(RuntimeTypesChecksBuilder rtiChecksBuilder) {
    assert(checkedClasses == null && checkedFunctionTypes == null);

    rtiChecksBuilder.registerImplicitChecks(
        _codegenWorldBuilder, classesUsingTypeVariableTests);
    _rtiChecks = rtiChecksBuilder.computeRequiredChecks();

    checkedClasses = new Set<ClassElement>();
    checkedFunctionTypes = new Set<ResolutionFunctionType>();
    _codegenWorldBuilder.isChecks.forEach((ResolutionDartType t) {
      if (t is ResolutionInterfaceType) {
        checkedClasses.add(t.element);
      } else if (t is ResolutionFunctionType) {
        checkedFunctionTypes.add(t);
      }
    });
  }
}
