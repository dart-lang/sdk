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

class ConvertToPackageImport extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_PACKAGE_IMPORT;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_PACKAGE_IMPORT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is StringLiteral) {
      node = node.parent;
    }
    if (node is ImportDirective) {
      var importDirective = node;
      var uriSource = importDirective.uriSource;

      // Ignore if invalid URI.
      if (uriSource == null) {
        return;
      }

      var importUri = uriSource.uri;
      if (importUri.scheme != 'package') {
        return;
      }

      // Don't offer to convert a 'package:' URI to itself.
      try {
        if (Uri.parse(importDirective.uriContent).scheme == 'package') {
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToPackageImport newInstance() => ConvertToPackageImport();
}
