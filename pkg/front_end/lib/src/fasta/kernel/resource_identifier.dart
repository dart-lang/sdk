// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Recognition and validation of resource identification annotations.
///
/// A static method to be collected as a resource identifier can be annotated
/// with `@ResourceIdentifier('some-id-string')`.
library;

import 'package:kernel/ast.dart';

import '../messages.dart'
    show
        messageResourceIdentifiersNotStatic,
        messageResourceIdentifiersMultiple;
import 'constant_evaluator.dart' show ErrorReporter;

/// Get all annotations for the given [node] of the form
/// `@ResourceIdentifier(...)`
Iterable<InstanceConstant> findResourceAnnotations(Annotatable node) =>
    node.annotations
        .whereType<ConstantExpression>()
        .map((expression) => expression.constant)
        .whereType<InstanceConstant>()
        .where((instance) => isResourceIdentifier(instance.classNode));

bool isResourceIdentifier(Class classNode) =>
    classNode.name == 'ResourceIdentifier';

/// Report if the resource annotations is placed on anything but a static
/// method.
void validateResourceIdentifierDeclaration(
  Annotatable node,
  ErrorReporter errorReporter,
  Iterable<InstanceConstant> resourceAnnotations,
) {
  if (node is! Procedure ||
      !node.isStatic ||
      node.kind != ProcedureKind.Method) {
    errorReporter.report(messageResourceIdentifiersNotStatic.withLocation(
        node.location!.file, node.fileOffset, 1));
  } else if (resourceAnnotations.length > 1) {
    errorReporter.report(messageResourceIdentifiersMultiple.withLocation(
        node.location!.file, node.fileOffset, 1));
  }
}
