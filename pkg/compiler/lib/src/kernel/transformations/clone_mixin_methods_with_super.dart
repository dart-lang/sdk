// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/type_algebra.dart';

/// Transforms the libraries in [libraries] by cloning any mixed in methods that
/// use super.
void transformLibraries(List<Library> libraries) {
  _CloneMixinMethodsWithSuper.transform(libraries);
}

class _CloneMixinMethodsWithSuper {
  /// Transform the given new [libraries].  It is expected that all other
  /// libraries have already been transformed.
  static void transform(List<Library> libraries) {
    // Clone any mixed in methods that uses super.
    var processedClasses = Set<Class>();
    for (var library in libraries) {
      for (var cls in library.classes) {
        if (processedClasses.add(cls)) {
          transformClass(cls);
        }
      }
    }
  }

  /// Transforms a given class by cloning any mixed in methods that use super.
  static void transformClass(Class cls) {
    var mixedInClass = cls.mixedInClass;
    if (mixedInClass == null) return;
    var mixedInType = cls.mixedInType!;
    bool hasProcedureMaps = false;
    Map<Name, Procedure> existingNonSetters = {};
    Map<Name, Procedure> existingSetters = {};

    void ensureExistingProcedureMaps() {
      if (hasProcedureMaps) return;
      for (Procedure procedure in cls.procedures) {
        if (procedure.kind == ProcedureKind.Setter) {
          existingSetters[procedure.name] = procedure;
        } else {
          existingNonSetters[procedure.name] = procedure;
        }
      }
      hasProcedureMaps = true;
    }

    CloneVisitorWithMembers? cloneVisitor;
    for (var field in mixedInClass.mixin.fields) {
      if (field.containsSuperCalls) {
        cloneVisitor ??= MixinApplicationCloner(cls,
            typeSubstitution: getSubstitutionMap(mixedInType));
        // TODO(jensj): Provide a "referenceFrom" if we need to support
        // the incremental compiler.
        ensureExistingProcedureMaps();
        Procedure? existingGetter = existingNonSetters[field.name];
        Procedure? existingSetter = existingSetters[field.name];
        cls.addField(cloneVisitor.cloneField(
            field, null, existingGetter?.reference, existingSetter?.reference));
        if (existingGetter != null) {
          cls.procedures.remove(existingGetter);
        }
        if (existingSetter != null) {
          cls.procedures.remove(existingSetter);
        }
        continue;
      }
    }
    for (var procedure in mixedInClass.mixin.procedures) {
      if (procedure.containsSuperCalls) {
        cloneVisitor ??= MixinApplicationCloner(cls,
            typeSubstitution: getSubstitutionMap(mixedInType));
        // TODO(jensj): Provide a "referenceFrom" if we need to support
        // the incremental compiler.
        ensureExistingProcedureMaps();
        Procedure? existingProcedure = procedure.kind == ProcedureKind.Setter
            ? existingSetters[procedure.name]
            : existingNonSetters[procedure.name];
        if (existingProcedure != null) {
          cls.procedures.remove(existingProcedure);
        }
        cls.addProcedure(cloneVisitor.cloneProcedure(
            procedure, existingProcedure?.reference));
        continue;
      }
    }
  }
}
