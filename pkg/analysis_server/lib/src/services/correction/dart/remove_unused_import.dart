// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedImport extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Bulk application is supported by a distinct import cleanup fix phase.
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => DartFixKind.removeUnusedImport;

  @override
  FixKind get multiFixKind => DartFixKind.removeUnusedImportMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare ImportDirective
    var importDirective = node.thisOrAncestorOfType<UriBasedDirective>();
    if (importDirective == null) {
      return;
    }
    var deletionRange = _deletionRange(importDirective);
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(deletionRange);
    });
  }

  SourceRange _deletionRange(UriBasedDirective directive) {
    var directives = unitResult.unit.directives;
    var index = directives.indexOf(directive);
    var lineInfo = unitResult.lineInfo;

    // Find the adjacent directives that share this line.
    Directive? previousOnSameLine;
    Directive? nextOnSameLine;
    if (index > 0) {
      var previous = directives[index - 1];
      var previousLine = lineInfo.getLocation(previous.end).lineNumber;
      var directiveLine = lineInfo.getLocation(directive.offset).lineNumber;
      if (previousLine == directiveLine) {
        previousOnSameLine = previous;
      }
    }
    if (index + 1 < directives.length) {
      var next = directives[index + 1];
      var directiveLine = lineInfo.getLocation(directive.end).lineNumber;
      var nextLine = lineInfo.getLocation(next.offset).lineNumber;
      if (directiveLine == nextLine) {
        nextOnSameLine = next;
      }
    }

    // Remove the whole line when it contains no other directives.
    if (previousOnSameLine == null && nextOnSameLine == null) {
      return utils.getLinesRange(range.node(directive));
    }

    var offset = directive.offset;
    if (previousOnSameLine != null) {
      if (applyingBulkFixes) {
        // The previous removal owns the separator between the directives.
        // If the previous directive remains, remove the separator here.
        if (!_hasRemovalDiagnostic(previousOnSameLine)) {
          offset = previousOnSameLine.end;
        }
      } else if (nextOnSameLine == null) {
        // A single fix normally removes the following separator. The last
        // directive on a line has no following separator, so remove the
        // preceding one instead.
        offset = previousOnSameLine.end;
      }
    }

    // Include the whitespace before the next directive, but preserve the line
    // ending when this is the last directive on the line.
    var end = nextOnSameLine?.offset ?? directive.end;
    return SourceRange(offset, end - offset);
  }

  bool _hasRemovalDiagnostic(Directive directive) {
    if (directive is! UriBasedDirective) {
      return false;
    }
    return unitResult.diagnostics.any(
      (diagnostic) =>
          diagnostic.offset == directive.uri.offset &&
          (diagnostic.diagnosticCode == diag.duplicateImport ||
              diagnostic.diagnosticCode == diag.unnecessaryImport ||
              diagnostic.diagnosticCode == diag.unusedImport),
    );
  }
}
