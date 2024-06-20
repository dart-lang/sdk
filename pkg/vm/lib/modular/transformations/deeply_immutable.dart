// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/cfe_codes.dart'
    show
        messageFfiDeeplyImmutableClassesMustBeFinalOrSealed,
        messageFfiDeeplyImmutableFieldsModifiers,
        messageFfiDeeplyImmutableFieldsMustBeDeeplyImmutable,
        messageFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable,
        messageFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;

void validateLibraries(
  List<Library> libraries,
  CoreTypes coreTypes,
  DiagnosticReporter diagnosticReporter,
) {
  final validator = DeeplyImmutableValidator(
    coreTypes,
    diagnosticReporter,
  );
  for (final library in libraries) {
    validator.visitLibrary(library);
  }
}

/// Implements the `vm:deeply-immutable` semantics.
class DeeplyImmutableValidator {
  static const vmDeeplyImmutable = "vm:deeply-immutable";

  final CoreTypes coreTypes;
  final DiagnosticReporter diagnosticReporter;
  final Class pragmaClass;
  final Field pragmaName;

  DeeplyImmutableValidator(
    this.coreTypes,
    this.diagnosticReporter,
  )   : pragmaClass = coreTypes.pragmaClass,
        pragmaName = coreTypes.pragmaName;

  void visitLibrary(Library library) {
    for (final cls in library.classes) {
      visitClass(cls);
    }
  }

  void visitClass(Class node) {
    _validateDeeplyImmutable(node);
  }

  void _validateDeeplyImmutable(Class node) {
    if (!_isDeeplyImmutableClass(node)) {
      // If class is not marked deeply immutable, check that none of the super
      // types is marked deeply immutable.
      final classes = [
        if (node.superclass != null) node.superclass!,
        for (final superType in node.implementedTypes) superType.classNode,
        if (node.mixedInClass != null) node.mixedInClass!,
      ];
      for (final superClass in classes) {
        if (_isDeeplyImmutableClass(superClass)) {
          diagnosticReporter.report(
            messageFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable,
            node.fileOffset,
            node.name.length,
            node.location!.file,
          );
        }
      }
      return;
    }

    final superClass = node.superclass;
    if (superClass != null && superClass != coreTypes.objectClass) {
      if (!_isDeeplyImmutableClass(superClass)) {
        diagnosticReporter.report(
          messageFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable,
          node.fileOffset,
          node.name.length,
          node.location!.file,
        );
      }
    }

    // Don't allow implementing, extending or mixing in deeply immutable classes
    // in other libraries. Adding a `vm:deeply-immutable` pragma to a class that
    // might be implemented, extended or mixed in would break subtypes that are
    // not marked deeply immutable. (We could consider relaxing this and
    // allowing breaking subtypes upon adding the pragma.)
    if (!(node.isFinal || node.isSealed)) {
      diagnosticReporter.report(
        messageFfiDeeplyImmutableClassesMustBeFinalOrSealed,
        node.fileOffset,
        node.name.length,
        node.location!.file,
      );
    }

    // All instance fields should be non-late final and deeply immutable.
    for (final field in node.fields) {
      if (field.isStatic) {
        // Static fields are not part of instances.
        continue;
      }
      if (!_isDeeplyImmutableDartType(field.type)) {
        diagnosticReporter.report(
          messageFfiDeeplyImmutableFieldsMustBeDeeplyImmutable,
          field.fileOffset,
          field.name.text.length,
          field.location!.file,
        );
      }
      if (!field.isFinal || field.isLate) {
        diagnosticReporter.report(
          messageFfiDeeplyImmutableFieldsModifiers,
          field.fileOffset,
          field.name.text.length,
          field.location!.file,
        );
      }
    }
  }

  bool _isDeeplyImmutableDartType(DartType dartType) {
    if (dartType is NullType) {
      return true;
    }
    if (dartType is InterfaceType) {
      final classNode = dartType.classNode;
      return _isDeeplyImmutableClass(classNode);
    }
    if (dartType is TypeParameterType) {
      return _isDeeplyImmutableDartType(dartType.bound);
    }
    return false;
  }

  bool _isDeeplyImmutableClass(Class node) {
    for (final annotation in node.annotations) {
      if (annotation is ConstantExpression) {
        final constant = annotation.constant;
        if (constant is InstanceConstant &&
            constant.classNode == pragmaClass &&
            constant.fieldValues[pragmaName.fieldReference] ==
                StringConstant(vmDeeplyImmutable)) {
          return true;
        }
      }
    }
    return false;
  }
}
