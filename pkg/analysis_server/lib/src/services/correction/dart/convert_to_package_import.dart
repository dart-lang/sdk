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

class ConvertToPackageImport extends ResolvedCorrectionProducer {
  ConvertToPackageImport({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_PACKAGE_IMPORT;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_PACKAGE_IMPORT;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_PACKAGE_IMPORT_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;
    if (targetNode is StringLiteral) {
      targetNode = targetNode.parent!;
    }
    if (targetNode is ImportDirective) {
      var elementUri = targetNode.element?.uri;
      if (elementUri is! DirectiveUriWithSource) {
        return;
      }

      var importDirective = targetNode;
      var uriSource = elementUri.source;

      var importUri = uriSource.uri;
      if (!importUri.isScheme('package')) {
        return;
      }

      // Don't offer to convert a 'package:' URI to itself.
      try {
        var uriContent = elementUri.relativeUriString;
        if (Uri.parse(uriContent).isScheme('package')) {
          return;
        }
      } on FormatException {
        return;
      }

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.node(importDirective.uri),
          "'$importUri'",
        );
      });
    }
  }
}
