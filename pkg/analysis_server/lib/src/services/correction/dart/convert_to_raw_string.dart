// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertToRawString extends ResolvedCorrectionProducer {
  ConvertToRawString({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.convertToRawString;

  @override
  FixKind get multiFixKind => DartFixKind.convertToRawStringMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var stringLiteral = node;
    if ((stringLiteral is! SimpleStringLiteral) || stringLiteral.isRaw) {
      return;
    }

    var literal = stringLiteral.literal;
    var deletionOffsets = <int>[];
    for (
      var offset = stringLiteral.contentsOffset;
      offset < stringLiteral.contentsEnd;
      offset++
    ) {
      var character = literal.lexeme[offset - literal.offset];
      if (character == r'\') {
        deletionOffsets.add(offset);
        offset++;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(stringLiteral.offset, 'r');
      for (var offset in deletionOffsets) {
        builder.addDeletion(SourceRange(offset, 1));
      }
    });
  }
}
