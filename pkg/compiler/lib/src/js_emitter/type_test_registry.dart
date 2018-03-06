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
        RuntimeTypesSubstitutions;
import '../js_backend/mirrors_data.dart';
import '../universe/world_builder.dart';
import '../world.dart' show ClosedWorld;

class TypeTestRegistry {
  final ElementEnvironment _elementEnvironment;

  /// After [computeNeededClasses] this set only contains classes that are only
  /// used for RTI.
  Set<ClassEntity> _rtiNeededClasses;

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
    addClassesWithSuperclasses(rtiChecks.requiredClasses);

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

    // 2. Find all types referenced from the types of elements that can be
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
