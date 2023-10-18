// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/type_algebra.dart';

/// Transforms a given class by cloning any mixed in methods that use super.
void transformClass(Class cls) {
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
      Field clone = cloneVisitor.cloneField(
          field, null, existingGetter?.reference, existingSetter?.reference);
      cls.addField(clone);
      clone.transformerFlags = field.transformerFlags;
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
      Procedure clone =
          cloneVisitor.cloneProcedure(procedure, existingProcedure?.reference);
      cls.addProcedure(clone);
      clone.transformerFlags = procedure.transformerFlags;
      continue;
    }
  }
}
