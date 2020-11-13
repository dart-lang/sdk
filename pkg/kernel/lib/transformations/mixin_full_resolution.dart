// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.mixin_full_resolution;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../clone.dart';
import '../core_types.dart';
import '../reference_from_index.dart';
import '../target/targets.dart' show Target;
import '../type_algebra.dart';

/// Transforms the libraries in [libraries].
/// Note that [referenceFromIndex] can be null, and is generally only needed
/// when (ultimately) called from the incremental compiler.
void transformLibraries(
    Target targetInfo,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    ReferenceFromIndex referenceFromIndex) {
  new MixinFullResolution(targetInfo, coreTypes, hierarchy)
      .transform(libraries, referenceFromIndex);
}

/// Replaces all mixin applications with regular classes, cloning all fields
/// and procedures from the mixed-in class, cloning all constructors from the
/// base class.
class MixinFullResolution {
  final Target targetInfo;
  final CoreTypes coreTypes;

  /// The [ClassHierarchy] that should be used after applying this transformer.
  /// If any class was updated, in general we need to create a new
  /// [ClassHierarchy] instance, with new dispatch targets; or at least let
  /// the existing instance know that some of its dispatch tables are not
  /// valid anymore.
  ClassHierarchy hierarchy;

  MixinFullResolution(this.targetInfo, this.coreTypes, this.hierarchy);

  /// Transform the given new [libraries].  It is expected that all other
  /// libraries have already been transformed.
  void transform(
      List<Library> libraries, ReferenceFromIndex referenceFromIndex) {
    if (libraries.isEmpty) return;

    var transformedClasses = new Set<Class>();

    // Desugar all mixin application classes by copying in fields/methods from
    // the mixin and constructors from the base class.
    var processedClasses = new Set<Class>();
    for (var library in libraries) {
      for (var class_ in library.classes) {
        transformClass(libraries, processedClasses, transformedClasses, class_,
            referenceFromIndex);
      }
    }

    // We might need to update the class hierarchy.
    hierarchy =
        hierarchy.applyMemberChanges(transformedClasses, findDescendants: true);
  }

  transformClass(
      List<Library> librariesToBeTransformed,
      Set<Class> processedClasses,
      Set<Class> transformedClasses,
      Class class_,
      ReferenceFromIndex referenceFromIndex) {
    // If this class was already handled then so were all classes up to the
    // [Object] class.
    if (!processedClasses.add(class_)) return;

    Library enclosingLibrary = class_.enclosingLibrary;

    if (!librariesToBeTransformed.contains(enclosingLibrary) &&
        enclosingLibrary.importUri?.scheme == "dart") {
      // If we're not asked to transform the platform libraries then we expect
      // that they will be already transformed.
      return;
    }

    // Ensure super classes have been transformed before this class.
    if (class_.superclass != null) {
      transformClass(librariesToBeTransformed, processedClasses,
          transformedClasses, class_.superclass, referenceFromIndex);
    }

    // If this is not a mixin application we don't need to make forwarding
    // constructors in this class.
    if (!class_.isMixinApplication) return;
    assert(librariesToBeTransformed.contains(enclosingLibrary));

    transformedClasses.add(class_);

    // Clone fields and methods from the mixin class.
    var substitution = getSubstitutionMap(class_.mixedInType);
    var cloner = new CloneVisitorWithMembers(typeSubstitution: substitution);

    // When we copy a field from the mixed in class, we remove any
    // forwarding-stub getters/setters from the superclass, but copy their
    // covariance-bits onto the new field.
    var nonSetters = <Name, Procedure>{};
    var setters = <Name, Procedure>{};
    for (var procedure in class_.procedures) {
      if (procedure.isSetter) {
        setters[procedure.name] = procedure;
      } else {
        nonSetters[procedure.name] = procedure;
      }
    }

    IndexedLibrary indexedLibrary =
        referenceFromIndex?.lookupLibrary(enclosingLibrary);
    IndexedClass indexedClass = indexedLibrary?.lookupIndexedClass(class_.name);

    for (var field in class_.mixin.fields) {
      Field clone =
          cloner.cloneField(field, indexedClass?.lookupField(field.name.text));
      Procedure setter = setters[field.name];
      if (setter != null) {
        setters.remove(field.name);
        VariableDeclaration parameter =
            setter.function.positionalParameters.first;
        clone.isGenericCovariantImpl = parameter.isGenericCovariantImpl;
      }
      nonSetters.remove(field.name);
      class_.addField(clone);
    }
    class_.procedures.clear();
    class_.procedures..addAll(nonSetters.values)..addAll(setters.values);

    // Existing procedures in the class should only be forwarding stubs.
    // Replace them with methods from the mixin class if they have the same
    // name, but keep their parameter flags.
    int originalLength = class_.procedures.length;
    outer:
    for (var procedure in class_.mixin.procedures) {
      // Forwarding stubs in the mixin class are used when calling through the
      // mixin class's interface, not when calling through the mixin
      // application.  They should not be copied.
      if (procedure.isForwardingStub) continue;

      // Factory constructors are not cloned.
      if (procedure.isFactory) continue;

      // NoSuchMethod forwarders aren't cloned.
      if (procedure.isNoSuchMethodForwarder) continue;

      Procedure referenceFrom;
      if (procedure.isSetter) {
        referenceFrom =
            indexedClass?.lookupProcedureSetter(procedure.name.text);
      } else {
        referenceFrom =
            indexedClass?.lookupProcedureNotSetter(procedure.name.text);
      }

      // Linear search for a forwarding stub with the same name.
      int originalIndex;
      for (int i = 0; i < originalLength; ++i) {
        var originalProcedure = class_.procedures[i];
        if (originalProcedure.name == procedure.name &&
            originalProcedure.kind == procedure.kind) {
          FunctionNode src = originalProcedure.function;
          FunctionNode dst = procedure.function;

          if (src.positionalParameters.length !=
                  dst.positionalParameters.length ||
              src.namedParameters.length != dst.namedParameters.length) {
            // A compile time error has already occurred, but don't crash below,
            // and don't add several procedures with the same name to the class.
            continue outer;
          }
          originalIndex = i;
          break;
        }
      }
      if (originalIndex != null) {
        referenceFrom ??= class_.procedures[originalIndex];
      }
      Procedure clone = cloner.cloneProcedure(procedure, referenceFrom);
      if (originalIndex != null) {
        Procedure originalProcedure = class_.procedures[originalIndex];
        FunctionNode src = originalProcedure.function;
        FunctionNode dst = clone.function;
        assert(src.typeParameters.length == dst.typeParameters.length);
        for (int j = 0; j < src.typeParameters.length; ++j) {
          dst.typeParameters[j].flags = src.typeParameters[j].flags;
        }
        for (int j = 0; j < src.positionalParameters.length; ++j) {
          dst.positionalParameters[j].flags = src.positionalParameters[j].flags;
        }
        // TODO(kernel team): The named parameters are not sorted,
        // this might not be correct.
        for (int j = 0; j < src.namedParameters.length; ++j) {
          dst.namedParameters[j].flags = src.namedParameters[j].flags;
        }

        class_.procedures[originalIndex] = clone;
      } else {
        class_.addProcedure(clone);
      }
    }
    assert(class_.constructors.isNotEmpty);

    // This class implements the mixin type. Also, backends rely on the fact
    // that eliminated mixin is appended into the end of interfaces list.
    class_.implementedTypes.add(class_.mixedInType);

    // This class is now a normal class.
    class_.mixedInType = null;

    // Leave breadcrumbs for backends (e.g. for dart:mirrors implementation).
    class_.isEliminatedMixin = true;
  }
}
