// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This imports 'codes/cfe_codes.dart' instead of 'api_prototype/codes.dart' to
// avoid cyclic dependency between `package:vm/modular` and `package:front_end`.
import 'package:front_end/src/codes/cfe_codes.dart'
    show
        codeFfiDeeplyImmutableClassesMustBeFinalOrSealed,
        codeFfiDeeplyImmutableFieldsModifiers,
        codeFfiDeeplyImmutableFieldsMustBeDeeplyImmutable,
        codeFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable,
        codeFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;

void validateLibraries(
  Component component,
  List<Library> libraries,
  CoreTypes coreTypes,
  DiagnosticReporter diagnosticReporter,
) {
  final LibraryIndex index = LibraryIndex(component, const [
    'dart:ffi',
    'dart:nativewrappers',
  ]);
  final validator = DeeplyImmutableValidator(
    index,
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
  // Can be null if nativewrappers library is not available.
  final Class? nativeFieldWrapperClass1Class;
  // Can be null if ffi library is not available.
  final Class? structClass;
  final Class? unionClass;

  DeeplyImmutableValidator(
    LibraryIndex index,
    this.coreTypes,
    this.diagnosticReporter,
  ) : pragmaClass = coreTypes.pragmaClass,
      pragmaName = coreTypes.pragmaName,
      nativeFieldWrapperClass1Class = index.tryGetClass(
        'dart:nativewrappers',
        'NativeFieldWrapperClass1',
      ),
      structClass = index.tryGetClass('dart:ffi', 'Struct'),
      unionClass = index.tryGetClass('dart:ffi', 'Union');

  void visitLibrary(Library library) {
    for (final cls in library.classes) {
      visitClass(cls);
    }
  }

  void visitClass(Class node) {
    _validateDeeplyImmutable(node);
  }

  bool _isOrExtendsNativeFieldWrapper1Class(Class? node) {
    while (node != null && node != nativeFieldWrapperClass1Class) {
      node = node.superclass;
    }
    return node != null;
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
            codeFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable,
            node.fileOffset,
            node.name.length,
            node.location!.file,
          );
        }
      }
      return;
    }

    final superClass = node.superclass;
    if (superClass != null &&
        superClass != coreTypes.objectClass &&
        node != structClass &&
        node != unionClass &&
        !_isOrExtendsNativeFieldWrapper1Class(superClass)) {
      if (!_isDeeplyImmutableClass(superClass)) {
        diagnosticReporter.report(
          codeFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable,
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
    // Exception being ffi Struct and Union classes which are extended, but
    // have custom treatment.
    if (node != structClass &&
        node != unionClass &&
        superClass != structClass &&
        superClass != unionClass) {
      if (!(node.isFinal || node.isSealed)) {
        diagnosticReporter.report(
          codeFfiDeeplyImmutableClassesMustBeFinalOrSealed,
          node.fileOffset,
          node.name.length,
          node.location!.file,
        );
      }
    }

    if (node.name == 'ScopedThreadLocal') {
      final uri = node.enclosingLibrary.importUri;
      if (uri.isScheme('dart') && uri.path == '_vm') {
        // ScopedThreadLocal has non-deeply-immutable initializer,
        // but we allow it.
        // TODO(dartbug.com/61962): remove this once the bug is fixed.
        return;
      }
    }

    // All instance fields should be non-late final and deeply immutable.
    for (final field in node.fields) {
      if (field.isStatic) {
        // Static fields are not part of instances.
        continue;
      }
      if (!_isDeeplyImmutableDartType(field.type)) {
        diagnosticReporter.report(
          codeFfiDeeplyImmutableFieldsMustBeDeeplyImmutable,
          field.fileOffset,
          field.name.text.length,
          field.location!.file,
        );
      }
      if (!field.isFinal || field.isLate) {
        diagnosticReporter.report(
          codeFfiDeeplyImmutableFieldsModifiers,
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
