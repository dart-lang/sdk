// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Recognition and validation of usage recording annotations.
///
/// A static method to be recorded can be annotated with `@RecordUse()`.
library;

import 'package:kernel/ast.dart';

import '../base/messages.dart' show codeRecordUseCannotBePlacedHere;
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

// Coverage-ignore(suite): Not run.
bool hasRecordUseAnnotation(Annotatable node) =>
    findRecordUseAnnotation(node).isNotEmpty;

// Coverage-ignore(suite): Not run.
final Uri _metaLibraryUri = new Uri(scheme: 'package', path: 'meta/meta.dart');

bool isRecordUse(Class cls) =>
    cls.name == 'RecordUse' &&
    // Coverage-ignore(suite): Not run.
    cls.enclosingLibrary.importUri == _metaLibraryUri;

// Coverage-ignore(suite): Not run.
bool isBeingRecorded(Class cls) => isRecordUse(cls) || hasRecordUse(cls);

// Coverage-ignore(suite): Not run.
/// If [cls] annotation is in turn annotated by a recording annotation.
bool hasRecordUse(Class cls) => cls.annotations
    .whereType<ConstantExpression>()
    .map((e) => e.constant)
    .whereType<InstanceConstant>()
    .any((annotation) => isRecordUse(annotation.classNode));

// Coverage-ignore(suite): Not run.
/// Report if the resource annotations is placed on anything but a static
/// method or a class without a const constructor.
void validateRecordUseDeclaration(
  Annotatable node,
  ErrorReporter errorReporter,
  Iterable<InstanceConstant> resourceAnnotations,
) {
  final bool onNonStaticMethod =
      node is! Procedure || !node.isStatic || node.kind != ProcedureKind.Method;

  final bool onClassWithoutConstConstructor = node is! Class ||
      !node.constructors.any((constructor) => constructor.isConst);
  if (onNonStaticMethod && onClassWithoutConstConstructor) {
    errorReporter.report(codeRecordUseCannotBePlacedHere.withLocation(
        node.location!.file, node.fileOffset, 1));
  }
}
