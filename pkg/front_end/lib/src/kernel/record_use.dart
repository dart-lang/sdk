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

import '../api_prototype/lowering_predicates.dart';
import '../codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';

import 'constant_evaluator.dart' show ErrorReporter;

// Coverage-ignore(suite): Not run.
/// Get all of the `@RecordUse` annotations from `package:meta`
/// that are attached to the specified [node].
Iterable<InstanceConstant> findRecordUseAnnotation(Annotatable node) {
  List<InstanceConstant>? result;
  List<Expression> annotations = node.annotations;
  final int length = annotations.length;
  if (length == 0) return const [];

  for (int i = 0; i < length; i++) {
    Expression annotation = annotations[i];
    if (annotation is! ConstantExpression) continue;
    Constant constant = annotation.constant;
    if (constant is! InstanceConstant) continue;
    if (!isRecordUse(constant.classNode)) continue;
    (result ??= []).add(constant);
  }
  return result ?? const [];
}

bool hasRecordUseAnnotation(Annotatable node) {
  List<Expression> annotations = node.annotations;
  final int length = annotations.length;
  if (length == 0) return false;

  for (int i = 0; i < length; i++) {
    Expression annotation = annotations[i];
    if (annotation is! ConstantExpression) continue;
    Constant constant = annotation.constant;
    if (constant is! InstanceConstant) continue;
    if (!isRecordUse(constant.classNode)) continue;
    return true;
  }
  return false;
}

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
    Extension e => e.enclosingLibrary,
    ExtensionTypeDeclaration e => e.enclosingLibrary,
    Typedef t => t.enclosingLibrary,
    _ => null,
  };
  return library?.importUri.isScheme('package') ?? false;
}

bool isBeingRecorded(Annotatable node) {
  if (hasRecordUseAnnotation(node)) {
    // Coverage-ignore-block(suite): Not run.
    return _enclosedInLibraryWithPackageUri(node);
  }

  if (node is Constructor) {
    // Coverage-ignore-block(suite): Not run.
    final Class? cls = node.enclosingClass;
    if (cls != null && isBeingRecorded(cls)) return true;
  }

  if (node is Field &&
      // Coverage-ignore(suite): Not run.
      node.isEnumElement) {
    // Coverage-ignore-block(suite): Not run.
    final Class? cls = node.enclosingClass;
    if (cls != null && isBeingRecorded(cls)) return true;
  }

  if (node is Procedure) {
    // Coverage-ignore-block(suite): Not run.
    Procedure? implementation = getExtensionMemberImplementation(node);
    if (implementation != null) {
      return isBeingRecorded(implementation);
    }
    Extension? extension = node.extension;
    if (extension != null) {
      if (isBeingRecorded(extension)) return true;
    }
    ExtensionTypeDeclaration? extensionTypeDeclaration =
        node.extensionTypeDeclaration;
    if (extensionTypeDeclaration != null) {
      if (isBeingRecorded(extensionTypeDeclaration)) return true;
    }

    if (node.isRedirectingFactory) {
      final Member? target = node.function.redirectingFactoryTarget?.target;
      if (target != null) return isBeingRecorded(target);
    }

    if (node.isStatic || node.isFactory) {
      final Class? cls = node.enclosingClass;
      if (cls != null && isBeingRecorded(cls)) return true;
    }

    if (isConstructorTearOffLowering(node) || isTypedefTearOffLowering(node)) {
      final Member? target = getConstructorTearOffLoweringTarget(node);
      if (target != null) {
        return isBeingRecorded(target);
      }
    }
  }

  return false;
}

// Coverage-ignore(suite): Not run.
Uri? _getFileUri(Annotatable node) {
  if (node is Library) return node.fileUri;
  if (node is Class) return node.fileUri;
  if (node is Member) return node.fileUri;
  return node.location?.file;
}

/// Performs all validations for `@RecordUse` on the given [node].
void validateAnnotations(
  List<Expression> annotations,
  Annotatable parent,
  ErrorReporter errorReporter,
) {
  if (annotations.length > 0) {
    if (hasRecordUseAnnotation(parent)) {
      // Coverage-ignore-block(suite): Not run.
      _validateRecordUseDeclaration(
        parent,
        errorReporter,
        findRecordUseAnnotation(parent),
      );
      _validateClassIsFinal(parent, errorReporter);
    }
  }

  if (parent is Class) {
    _validateSubtyping(parent, errorReporter);
  }
}

// Coverage-ignore(suite): Not run.
void _validateClassIsFinal(Annotatable node, ErrorReporter errorReporter) {
  if (node is Class && !node.isFinal && !node.isEnum) {
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

void _validateSuper(
  Supertype superType,
  Class node,
  ErrorReporter errorReporter,
) {
  Class classNode = superType.classNode;
  // TODO(jensj): Consider if we should add a flag on class.
  // See also https://dart-review.googlesource.com/c/sdk/+/486201.
  if (isBeingRecorded(classNode)) {
    // Coverage-ignore-block(suite): Not run.
    final Uri? fileUri = _getFileUri(node);
    if (fileUri != null) {
      errorReporter.report(
        diag.recordUseSubtypingNotSupported
            .withArguments(name: classNode.name)
            .withLocation(fileUri, node.fileOffset, node.name.length),
      );
    }
  }
}

void _validateSubtyping(Class node, ErrorReporter errorReporter) {
  Supertype? supertype = node.supertype;
  if (supertype != null) {
    _validateSuper(supertype, node, errorReporter);
  }
  Supertype? mixedInType = node.mixedInType;
  if (mixedInType != null) {
    _validateSuper(mixedInType, node, errorReporter);
  }
  for (final Supertype supertype in node.implementedTypes) {
    _validateSuper(supertype, node, errorReporter);
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

  final ExtensionTypeMemberDescriptor? descriptor = node is Procedure
      ? node.extensionTypeMemberDescriptor
      : null;

  // Validation is performed on Kernel nodes. Some high-level Dart constructs
  // (like extension type factories or constructor tear-offs) are lowered into
  // regular static procedures in Kernel. Since annotations are copied from
  // source to these lowered nodes, we must explicitly check for them to
  // ensure factories and constructors are consistently disallowed.
  final bool isExtensionTypeFactory =
      descriptor != null &&
      (descriptor.kind == ExtensionTypeMemberKind.Constructor ||
          descriptor.kind == ExtensionTypeMemberKind.Factory ||
          descriptor.kind == ExtensionTypeMemberKind.RedirectingFactory);

  final bool onStaticMethod =
      node is Procedure &&
      node.isStatic &&
      node.kind != ProcedureKind.Factory &&
      !isExtensionTypeFactory &&
      !isTearOffLowering(node);

  final bool onClass = node is Class;

  if (!onStaticMethod && !onClass) {
    errorReporter.report(
      diag.recordUseCannotBePlacedHere.withLocation(
        fileUri,
        node.fileOffset,
        1,
      ),
    );
  }
}
