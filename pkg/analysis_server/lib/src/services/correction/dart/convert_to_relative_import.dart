// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart' as path;

class ConvertToRelativeImport extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_RELATIVE_IMPORT;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_RELATIVE_IMPORT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is StringLiteral) {
      node = node.parent;
    }
    if (node is! ImportDirective) {
      return;
    }

    ImportDirective importDirective = node;

    // Ignore if invalid URI.
    if (importDirective.uriSource == null) {
      return;
    }

    // Ignore if the uri is not a package: uri.
    var sourceUri = resolvedResult.uri;
    if (sourceUri.scheme != 'package') {
      return;
    }

    Uri importUri;
    try {
      importUri = Uri.parse(importDirective.uriContent);
    } on FormatException {
      return;
    }

    // Ignore if import uri is not a package: uri.
    if (importUri.scheme != 'package') {
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

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(importDirective.uri).getExpanded(-1),
        relativePath,
      );
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToRelativeImport newInstance() => ConvertToRelativeImport();
}
