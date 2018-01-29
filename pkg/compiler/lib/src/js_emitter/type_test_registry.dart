// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.type_test_registry;

import '../common.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
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

  /// After [computeNeededClasses] this set only contains classes that are only
  /// used for RTI.
  Set<ClassEntity> _rtiNeededClasses;

  /// The required checks on classes.
  // TODO(johnniwinther): Currently this is wrongfully computed twice. Once
  // in [computeRequiredTypeChecks] and once in [computeRtiNeededClasses]. The
  // former is stored in [RuntimeTypeChecks] and used in the
  // [TypeRepresentationGenerator] and the latter is used to compute the
  // classes needed for RTI.
  TypeChecks _requiredChecks;

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

  TypeChecks get requiredChecks {
    assert(
        _requiredChecks != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "requiredChecks has not been computed yet."));
    return _requiredChecks;
  }

  /**
   * Returns the classes with constructors used as a 'holder' in
   * [emitRuntimeTypeSupport].
   * TODO(9556): Some cases will go away when the class objects are created as
   * complete.  Not all classes will go away while constructors are referenced
   * from type substitutions.
   */
  Set<ClassEntity> computeClassesModifiedByEmitRuntimeTypeSupport() {
    TypeChecks typeChecks = rtiChecks.requiredChecks;
    Set<ClassEntity> result = new Set<ClassEntity>();
    for (ClassEntity cls in typeChecks.classes) {
      if (typeChecks[cls].isNotEmpty) result.add(cls);
    }
    return result;
  }

  void computeRtiNeededClasses(RuntimeTypesSubstitutions rtiSubstitutions,
      MirrorsData mirrorsData, Iterable<MemberEntity> liveMembers) {
    _rtiNeededClasses = new Set<ClassEntity>();

    void addClassWithSuperclasses(ClassEntity cls) {
      _rtiNeededClasses.add(cls);
      for (ClassEntity superclass = _elementEnvironment.getSuperClass(cls);
          superclass != null;
          superclass = _elementEnvironment.getSuperClass(superclass)) {
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
    _requiredChecks = rtiSubstitutions.computeChecks(
        rtiNeededClasses, rtiChecks.checkedClasses);
    Set<ClassEntity> classesUsedInSubstitutions =
        rtiSubstitutions.getClassesUsedInSubstitutions(requiredChecks);
    addClassesWithSuperclasses(classesUsedInSubstitutions);

    // 3.  Add classes that contain checked generic function types. These are
    //     needed to store the signature encoding.
    for (FunctionType type in rtiChecks.checkedFunctionTypes) {
      ClassEntity contextClass = DartTypes.getClassContext(type);
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
      FunctionEntity function = _function;
      FunctionType type = _elementEnvironment.getFunctionType(function);
      for (ClassEntity cls in _rtiChecks.getReferencedClasses(type)) {
        while (cls != null) {
          _rtiNeededClasses.add(cls);
          cls = _elementEnvironment.getSuperClass(cls);
        }
      }
    });
  }

  void computeRequiredTypeChecks(RuntimeTypesChecksBuilder rtiChecksBuilder) {
    _rtiChecks = rtiChecksBuilder.computeRequiredChecks(_codegenWorldBuilder);
  }
}
