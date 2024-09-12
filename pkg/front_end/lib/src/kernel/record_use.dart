// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Recognition and validation of usage recording annotations.
///
/// A static method to be recorded can be annotated with `@RecordUse()`.
library;

import 'package:kernel/ast.dart';

import '../base/messages.dart' show messageRecordUseCannotBePlacedHere;
import 'constant_evaluator.dart' show ErrorReporter;

/// Get all of the `@RecordUse` annotations from `package:meta`
/// that are attached to the specified [node].
Iterable<InstanceConstant> findRecordUseAnnotation(Annotatable node) =>
    node.annotations
        .whereType<ConstantExpression>()
        .map((expression) => expression.constant)
        .whereType<InstanceConstant>()
        .where((instance) => isRecordUse(instance.classNode))
        .toList(growable: false);

// Coverage-ignore(suite): Not run.
final Uri _metaLibraryUri = new Uri(scheme: 'package', path: 'meta/meta.dart');

bool isRecordUse(Class classNode) =>
    classNode.name == 'RecordUse' &&
    // Coverage-ignore(suite): Not run.
    classNode.enclosingLibrary.importUri == _metaLibraryUri;

// Coverage-ignore(suite): Not run.
/// Report if the resource annotations is placed on anything but a static
/// method.
void validateRecordUseDeclaration(
  Annotatable node,
  ErrorReporter errorReporter,
  Iterable<InstanceConstant> resourceAnnotations,
) {
  final bool onNonStaticMethod =
      node is! Procedure || !node.isStatic || node.kind != ProcedureKind.Method;
  if (onNonStaticMethod) {
    errorReporter.report(messageRecordUseCannotBePlacedHere.withLocation(
        node.location!.file, node.fileOffset, 1));
  }
}
