// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart' as path;

class SimplifyDirectivePath extends ResolvedCorrectionProducer {
  SimplifyDirectivePath({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.simplifyDirectivePath;

  @override
  FixKind get multiFixKind => DartFixKind.simplifyDirectivePathMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;
    if (targetNode is StringLiteral) {
      targetNode = targetNode.parent!;
    }

    // Determine the URI node from the various directive types.
    var uriNode = switch (targetNode) {
      UriBasedDirective() => targetNode.uri,
      PartOfDirective() => targetNode.uri,
      Configuration() => targetNode.uri,
      _ => null,
    };

    if (uriNode == null) return;

    var uriString = uriNode.stringValue;
    if (uriString == null || uriString.isEmpty) return;

    Uri? parsedUri = Uri.tryParse(uriString);
    if (parsedUri == null) return;

    String? simplifiedPath;
    // 1. Check for URI normalization (handles '.', '..', and unnecessary escapes).
    if (uriString != parsedUri.toString()) {
      simplifiedPath = parsedUri.toString();
    }
    // 2. Check for path minimality if it's a relative, non-absolute path.
    else if (!parsedUri.hasScheme &&
        !parsedUri.hasAuthority &&
        !parsedUri.hasAbsolutePath &&
        parsedUri.path.isNotEmpty) {
      var contextUri = unitResult.libraryFragment.source.uri;
      var resolvedUri = contextUri.resolveUri(parsedUri);

      simplifiedPath = path.url.relative(
        resolvedUri.path,
        from: path.url.dirname(contextUri.path),
      );
    }

    if (simplifiedPath == null || simplifiedPath == uriString) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      if (uriNode is SingleStringLiteral) {
        builder.addSimpleReplacement(
          range.startOffsetEndOffset(
            uriNode.contentsOffset,
            uriNode.contentsEnd,
          ),
          simplifiedPath!,
        );
      } else {
        builder.addSimpleReplacement(
          range.node(uriNode),
          "'${simplifiedPath!}'",
        );
      }
    });
  }
}
