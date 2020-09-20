// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart';

class ConvertPartOfToUri extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_PART_OF_TO_URI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var directive = node.thisOrAncestorOfType<PartOfDirective>();
    if (directive == null || directive.libraryName == null) {
      return;
    }
    var libraryPath = resolvedResult.libraryElement.source.fullName;
    var partPath = resolvedResult.path;
    var relativePath = relative(libraryPath, from: dirname(partPath));
    var uri = Uri.file(relativePath).toString();
    var replacementRange = range.node(directive.libraryName);
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(replacementRange, "'$uri'");
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertPartOfToUri newInstance() => ConvertPartOfToUri();
}
