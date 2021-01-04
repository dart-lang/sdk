// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class ConvertToMutilineString extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_MULTILINE_STRING;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is InterpolationElement) {
      node = (node as InterpolationElement).parent;
    }
    if (node is SingleStringLiteral) {
      var literal = node;
      if (!literal.isSynthetic && !literal.isMultiline) {
        await builder.addDartFileEdit(file, (builder) {
          var newQuote = literal.isSingleQuoted ? "'''" : '"""';
          builder.addReplacement(
            SourceRange(literal.offset + (literal.isRaw ? 1 : 0), 1),
            (builder) {
              builder.writeln(newQuote);
            },
          );
          builder.addSimpleReplacement(
            SourceRange(literal.end - 1, 1),
            newQuote,
          );
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertToMutilineString newInstance() => ConvertToMutilineString();
}
