// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This imports 'codes/cfe_codes.dart' instead of 'api_prototype/codes.dart' to
// avoid cyclic dependency between `package:vm/modular` and `package:front_end`.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
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

class _CheckResult {
  final bool isImmutable;
  final bool requiresRuntimeCheck;

  const _CheckResult({
    this.isImmutable = false,
    this.requiresRuntimeCheck = false,
  });
}

/// Implements the `vm:deeply-immutable` semantics.
class DeeplyImmutableValidator {
  static const vmDeeplyImmutable = "vm:deeply-immutable";
  late final InstanceConstant vmDeeplyImmutableConstant =
      InstanceConstant(coreTypes.pragmaClass.reference, [], {
        coreTypes.pragmaName.fieldReference: StringConstant(vmDeeplyImmutable),
        coreTypes.pragmaOptions.fieldReference: NullConstant(),
      });
  static const vmShared = "vm:shared";

  final CoreTypes coreTypes;
  final DiagnosticReporter diagnosticReporter;
  final Class pragmaClass;
  final Field pragmaName;
  // Can be null if nativewrappers library is not available.
  final Class? nativeFieldWrapperClass1Class;
  // Can be null if ffi library is not available.
  final Class? structClass;
  final Class? unionClass;
  final Class mapClass;

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
      unionClass = index.tryGetClass('dart:ffi', 'Union'),
      mapClass = coreTypes.mapClass;

  void visitLibrary(Library library) {
    for (final cls in library.classes) {
      visitClass(cls);
    }
    for (final field in library.fields) {
      if (_isVmSharedField(field)) {
        addDeeplyImmutableAnnotationIfNeeded(field);
      }
    }
  }

  void visitClass(Class node) {
    _validateDeeplyImmutable(node);
  }

  // pragma("vm:deeply-immutable") on a field indicates that the field static
  // type guarantees that it always have deeply-immutable value, therefore
  // at a runtime there is no need to check the value being assigned to the
  // field.
  // This pragma is added only for "vm:shared" static fields and to all fields
  // of "vm:deeply-immutable" class because those are the only ones that are
  // sensitive to having deeply-immutable values in them.
  _CheckResult addDeeplyImmutableAnnotationIfNeeded(Field field) {
    final checkResult = _isDeeplyImmutableDartType(field.type);
    if (checkResult.isImmutable && !checkResult.requiresRuntimeCheck) {
      field.addAnnotation(ConstantExpression(vmDeeplyImmutableConstant));
    }
    return checkResult;
  }

  bool _isOrExtendsNativeFieldWrapper1Class(Class? node) {
    while (node != null && node != nativeFieldWrapperClass1Class) {
      node = node.superclass;
    }
    return node != null;
  }

  bool _isConstMap(Class node) {
    return node.name == "_ConstMap" &&
        node.enclosingLibrary.name == "dart._compact_hash";
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
            diag.ffiDeeplyImmutableSubtypesMustBeDeeplyImmutable,
            node.fileOffset,
            node.name.length,
            node.location!.file,
          );
        }
      }
      for (final field in node.fields) {
        if (field.isStatic && _isVmSharedField(field)) {
          addDeeplyImmutableAnnotationIfNeeded(field);
        }
      }
      return;
    }

    final superClass = node.superclass;
    if (superClass != null &&
        superClass != coreTypes.objectClass &&
        node != structClass &&
        node != unionClass &&
        !_isOrExtendsNativeFieldWrapper1Class(superClass) &&
        // ConstMap extends mutable class, but has all mutating functions
        // disabled. Further, during construction the map is verified to have
        // only deeply immutable values.
        !_isConstMap(node)) {
      if (!_isDeeplyImmutableClass(superClass)) {
        diagnosticReporter.report(
          diag.ffiDeeplyImmutableSupertypeMustBeDeeplyImmutable,
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
          diag.ffiDeeplyImmutableClassesMustBeFinalOrSealed,
          node.fileOffset,
          node.name.length,
          node.location!.file,
        );
      }
    }

    // All instance fields should be non-late final and deeply immutable.
    for (final field in node.fields) {
      final checkResult = addDeeplyImmutableAnnotationIfNeeded(field);
      if (field.isStatic) {
        // Static fields are not part of instances.
        continue;
      }
      if (!checkResult.isImmutable) {
        diagnosticReporter.report(
          diag.ffiDeeplyImmutableFieldsMustBeDeeplyImmutable,
          field.fileOffset,
          field.name.text.length,
          field.location!.file,
        );
      }
      if (!field.isFinal || field.isLate) {
        diagnosticReporter.report(
          diag.ffiDeeplyImmutableFieldsModifiers,
          field.fileOffset,
          field.name.text.length,
          field.location!.file,
        );
      }
    }
  }

  _CheckResult _isDeeplyImmutableDartType(DartType dartType) {
    if (dartType is NullType) {
      return _CheckResult(isImmutable: true, requiresRuntimeCheck: false);
    }
    if (dartType is InterfaceType) {
      final classNode = dartType.classNode;
      if (classNode == mapClass) {
        // Relies on dynamic check of whether map is actually const map.
        return _CheckResult(isImmutable: true, requiresRuntimeCheck: true);
      }
      return _CheckResult(
        isImmutable: _isDeeplyImmutableClass(classNode),
        requiresRuntimeCheck: false,
      );
    }
    if (dartType is TypeParameterType) {
      return _isDeeplyImmutableDartType(dartType.bound);
    }
    if (dartType is FunctionType) {
      // Relies on dynamic check of whether closure actually captures only
      // deeply-immutable values.
      return _CheckResult(isImmutable: true, requiresRuntimeCheck: true);
    }
    return _CheckResult(isImmutable: false, requiresRuntimeCheck: false);
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

  bool _isVmSharedField(Field node) {
    for (final annotation in node.annotations) {
      if (annotation is ConstantExpression) {
        final constant = annotation.constant;
        if (constant is InstanceConstant &&
            constant.classNode == pragmaClass &&
            constant.fieldValues[pragmaName.fieldReference] ==
                StringConstant(vmShared)) {
          return true;
        }
      }
    }
    return false;
  }
}
