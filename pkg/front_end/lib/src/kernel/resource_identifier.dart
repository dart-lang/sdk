// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Recognition and validation of resource identification annotations.
///
/// A static method to be collected as a resource identifier can be annotated
/// with `@ResourceIdentifier('some-id-string')`.
library;

import 'package:kernel/ast.dart';

import '../fasta/messages.dart'
    show
        messageResourceIdentifiersNotStatic,
        messageResourceIdentifiersMultiple;
import 'constant_evaluator.dart' show ErrorReporter;

/// Get all of the `@ResourceIdentifier` annotations from `package:meta`
/// that are attached to the specified [node].
Iterable<InstanceConstant> findResourceAnnotations(Annotatable node) =>
    node.annotations
        .whereType<ConstantExpression>()
        .map((expression) => expression.constant)
        .whereType<InstanceConstant>()
        .where((instance) => isResourceIdentifier(instance.classNode))
        .toList(growable: false);

final Uri _metaLibraryUri = new Uri(scheme: 'package', path: 'meta/meta.dart');

bool isResourceIdentifier(Class classNode) =>
    classNode.name == 'ResourceIdentifier' &&
    classNode.enclosingLibrary.importUri == _metaLibraryUri;

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
