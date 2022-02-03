// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertToRawString extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_RAW_STRING;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_RAW_STRING_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var stringLiteral = node;
    if ((stringLiteral is! SimpleStringLiteral) || stringLiteral.isRaw) {
      return;
    }

    var literal = stringLiteral.literal;
    var deletionOffsets = <int>[];
    for (var offset = stringLiteral.contentsOffset;
        offset < stringLiteral.contentsEnd;
        offset++) {
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToRawString newInstance() => ConvertToRawString();
}
