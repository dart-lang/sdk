// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.type_test_registry;

import '../common.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../js_backend/runtime_types.dart'
    show RuntimeTypesChecks, RuntimeTypesChecksBuilder;
import '../js_backend/runtime_types_codegen.dart'
    show RuntimeTypesSubstitutions;
import '../options.dart';
import '../universe/codegen_world_builder.dart';

class TypeTestRegistry {
  final ElementEnvironment _elementEnvironment;

  /// After [computeNeededClasses] this set only contains classes that are only
  /// used for RTI.
  Set<ClassEntity> _rtiNeededClasses;

  final CompilerOptions _options;

  RuntimeTypesChecks _rtiChecks;

  TypeTestRegistry(this._options, this._elementEnvironment);

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
      Iterable<MemberEntity> liveMembers) {
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

    // Add classes that are referenced by type arguments or substitutions in
    // argument checks.
    addClassesWithSuperclasses(rtiChecks.requiredClasses);
  }

  void computeRequiredTypeChecks(
      RuntimeTypesChecksBuilder rtiChecksBuilder, CodegenWorld codegenWorld) {
    _rtiChecks = rtiChecksBuilder.computeRequiredChecks(codegenWorld, _options);
  }
}
