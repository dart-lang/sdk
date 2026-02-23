// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Recognition and validation of usage recording annotations.
///
/// A static method or class to be recorded can be annotated with
/// `@RecordUse()`.
///
/// Only usages in reachable code (executable code) are tracked. Usages
/// appearing within metadata (annotations) are ignored.
library;

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';

import 'constant_evaluator.dart' show ErrorReporter;

/// Get all of the `@RecordUse` annotations from `package:meta`
/// that are attached to the specified [node].
Iterable<InstanceConstant> findRecordUseAnnotation(Annotatable node) {
  List<InstanceConstant>? result;
  for (int i = 0; i < node.annotations.length; i++) {
    Expression annotation = node.annotations[i];
    if (annotation is! ConstantExpression) continue;
    Constant constant = annotation.constant;
    if (constant is! InstanceConstant) continue;
    if (!isRecordUse(constant.classNode)) continue;
    // Coverage-ignore-block(suite): Not run.
    (result ??= []).add(constant);
  }
  return result ?? const [];
}

bool hasRecordUseAnnotation(Annotatable node) =>
    findRecordUseAnnotation(node).isNotEmpty;

// Coverage-ignore(suite): Not run.
final Uri _metaLibraryUri = new Uri(scheme: 'package', path: 'meta/meta.dart');

bool isRecordUse(Class cls) =>
    cls.name == 'RecordUse' &&
    // Coverage-ignore(suite): Not run.
    cls.enclosingLibrary.importUri == _metaLibraryUri;

// Coverage-ignore(suite): Not run.
bool _enclosedInLibraryWithPackageUri(Annotatable node) {
  final Library? library = switch (node) {
    Library l => l,
    Class c => c.enclosingLibrary,
    Member m => m.enclosingLibrary,
    _ => null,
  };
  return library?.importUri.isScheme('package') ?? false;
}

bool isBeingRecorded(Annotatable node) {
  final bool hasAnnotation = hasRecordUseAnnotation(node);

  if (!hasAnnotation) return false;

  // Coverage-ignore(suite): Not run.
  return _enclosedInLibraryWithPackageUri(node);
}

// Coverage-ignore(suite): Not run.
Uri? _getFileUri(Annotatable node) {
  if (node is Library) return node.fileUri;
  if (node is Class) return node.fileUri;
  if (node is Member) return node.fileUri;
  return node.location?.file;
}

/// Performs all validations for `@RecordUse` on the given [node].
void validateAnnotations(Annotatable node, ErrorReporter errorReporter) {
  final Iterable<InstanceConstant> annotations = findRecordUseAnnotation(node);

  if (annotations.isNotEmpty) {
    // Coverage-ignore-block(suite): Not run.
    _validateRecordUseDeclaration(node, errorReporter, annotations);
    _validateClassIsFinal(node, errorReporter);
  }

  if (node is Class) {
    _validateSubtyping(node, errorReporter);
  }
}

// Coverage-ignore(suite): Not run.
void _validateClassIsFinal(Annotatable node, ErrorReporter errorReporter) {
  if (node is Class && !node.isFinal) {
    final Uri? fileUri = _getFileUri(node);
    if (fileUri != null) {
      errorReporter.report(
        diag.recordUseClassesMustBeFinal.withLocation(
          fileUri,
          node.fileOffset,
          node.name.length,
        ),
      );
    }
  }
}

void _validateSubtyping(Class node, ErrorReporter errorReporter) {
  final List<Class> supertypes = node.supers.map((e) => e.classNode).toList();

  for (final Class supertype in supertypes) {
    if (isBeingRecorded(supertype)) {
      // Coverage-ignore-block(suite): Not run.
      final Uri? fileUri = _getFileUri(node);
      if (fileUri != null) {
        errorReporter.report(
          diag.recordUseSubtypingNotSupported
              .withArguments(name: supertype.name)
              .withLocation(fileUri, node.fileOffset, node.name.length),
        );
      }
    }
  }
}

// Coverage-ignore(suite): Not run.
/// Report if the resource annotations is placed on anything but a static
/// method or a class without a const constructor.
void _validateRecordUseDeclaration(
  Annotatable node,
  ErrorReporter errorReporter,
  Iterable<InstanceConstant> resourceAnnotations,
) {
  if (resourceAnnotations.isEmpty) return;

  final Uri? fileUri = _getFileUri(node);
  if (fileUri == null) return;

  if (!_enclosedInLibraryWithPackageUri(node)) {
    errorReporter.report(
      diag.recordUseOutsideOfPackage.withLocation(fileUri, node.fileOffset, 1),
    );
  }

  final bool onNonStaticMethod =
      node is! Procedure || !node.isStatic || node.kind != ProcedureKind.Method;

  final bool onClassWithoutConstConstructor =
      node is! Class ||
      !node.constructors.any((constructor) => constructor.isConst);
  if (onNonStaticMethod && onClassWithoutConstConstructor) {
    errorReporter.report(
      diag.recordUseCannotBePlacedHere.withLocation(
        fileUri,
        node.fileOffset,
        1,
      ),
    );
  }
}
