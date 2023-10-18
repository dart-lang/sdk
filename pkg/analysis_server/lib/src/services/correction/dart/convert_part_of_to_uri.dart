// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertPartOfToUri extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_PART_OF_TO_URI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var directive = node.thisOrAncestorOfType<PartOfDirective>();
    if (directive == null) {
      return;
    }

    var libraryName = directive.libraryName;
    if (libraryName == null) {
      return;
    }

    var pathContext = resourceProvider.pathContext;
    var libraryPath = unitResult.libraryElement.source.fullName;
    var partPath = unitResult.path;
    var relativePath =
        pathContext.relative(libraryPath, from: pathContext.dirname(partPath));
    var uri = pathContext.toUri(relativePath).toString();
    var replacementRange = range.node(libraryName);
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(replacementRange, "'$uri'");
    });
  }
}
