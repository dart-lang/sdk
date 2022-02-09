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
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_RELATIVE_IMPORT;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_RELATIVE_IMPORT_MULTI;

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
    if (targetNode.uriSource == null) {
      return;
    }

    // Ignore if the uri is not a package: uri.
    var sourceUri = resolvedResult.uri;
    if (!sourceUri.isScheme('package')) {
      return;
    }

    Uri importUri;
    try {
      var uriContent = targetNode.uriContent;
      if (uriContent == null) {
        return;
      }
      importUri = Uri.parse(uriContent);
    } on FormatException {
      return;
    }

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

    final node_final = targetNode;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(node_final.uri).getExpanded(-1),
        relativePath,
      );
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToRelativeImport newInstance() => ConvertToRelativeImport();
}
