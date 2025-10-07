// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart' as path;

class ConvertToRelativeImport extends ResolvedCorrectionProducer {
  ConvertToRelativeImport({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertToRelativeImport;

  @override
  FixKind get fixKind => DartFixKind.convertToRelativeImport;

  @override
  FixKind get multiFixKind => DartFixKind.convertToRelativeImportMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;
    if (targetNode is StringLiteral) {
      targetNode = targetNode.parent!;
    }
    if (targetNode is! ImportDirective) {
      return;
    }

    // Ignore if invalid URI.
    var elementUri = targetNode.libraryImport?.uri;
    if (elementUri is! DirectiveUriWithSource) {
      return;
    }

    // Ignore if the uri is not a package: uri.
    var sourceUri = unitResult.uri;
    if (!sourceUri.isScheme('package')) {
      return;
    }

    var importUri = elementUri.relativeUri;

    // Ignore if import uri is not a package: uri.
    if (!importUri.isScheme('package')) {
      return;
    }

    // Verify that the source's uri and the import uri have the same package
    // name.
    var sourceSegments = sourceUri.pathSegments;
    var importSegments = importUri.pathSegments;
    if (sourceSegments.isEmpty ||
        importSegments.isEmpty ||
        sourceSegments.first != importSegments.first) {
      return;
    }

    // We only write posix style paths in import directives.
    var relativePath = path.posix.relative(
      importUri.path,
      from: path.dirname(sourceUri.path),
    );

    var uriNode = targetNode.uri;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(uriNode).getExpanded(-1),
        relativePath,
      );
    });
  }
}
