// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.runtime_types_new_migrated;

import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js_model/type_recipe.dart';
import '../universe/class_hierarchy.dart';
import '../world.dart';
import 'runtime_types_codegen.dart' show RuntimeTypesSubstitutions;

class RecipeEncoding {
  final jsAst.Literal recipe;
  final Set<TypeVariableType> typeVariables;

  const RecipeEncoding(this.recipe, this.typeVariables);
}

int? indexTypeVariable(
    JClosedWorld world,
    RuntimeTypesSubstitutions rtiSubstitutions,
    FullTypeEnvironmentStructure environment,
    TypeVariableType type,
    {bool metadata = false}) {
  int i = environment.bindings.indexOf(type);
  if (i >= 0) {
    // Indices are 1-based since '0' encodes using the entire type for the
    // singleton structure.
    return i + 1;
  }

  TypeVariableEntity element = type.element;
  // TODO(48820): remove `!`. Added to increase coverage of null assertions
  // while the compiler runs in unsound null safety.
  ClassEntity cls = element.typeDeclaration! as ClassEntity;

  if (metadata) {
    if (identical(environment.classType!.element, cls)) {
      // Indexed class type variables come after the bound function type
      // variables.
      return 1 + environment.bindings.length + element.index;
    }
  }

  // TODO(sra): We might be in a context where the class type variable has an
  // index, even though in the general case it is not at a specific index.

  ClassHierarchy classHierarchy = world.classHierarchy;
  var test = mustCheckAllSubtypes(world, cls)
      ? classHierarchy.anyStrictSubtypeOf
      : classHierarchy.anyStrictSubclassOf;
  if (test(cls, (ClassEntity subclass) {
    return !rtiSubstitutions.isTrivialSubstitution(subclass, cls);
  })) {
    return null;
  }

  // Indexed class type variables come after the bound function type
  // variables.
  return 1 + environment.bindings.length + element.index;
}

bool mustCheckAllSubtypes(JClosedWorld world, ClassEntity cls) =>
    world.isUsedAsMixin(cls) ||
    world.extractTypeArgumentsInterfacesNewRti.contains(cls);
