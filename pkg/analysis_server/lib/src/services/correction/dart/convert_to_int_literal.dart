// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertToIntLiteral extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_INT_LITERAL;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_INT_LITERAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! DoubleLiteral) {
      return;
    }
    DoubleLiteral literal = node;
    int intValue;
    try {
      intValue = literal.value?.truncate();
    } catch (e) {
      // Double cannot be converted to int
    }
    if (intValue == null || intValue != literal.value) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(SourceRange(literal.offset, literal.length),
          (builder) {
        builder.write('$intValue');
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToIntLiteral newInstance() => ConvertToIntLiteral();
}
