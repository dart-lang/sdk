// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithEightDigitHex extends CorrectionProducer {
  /// The replacement text, used as an argument to the fix message.
  String _replacement;

  @override
  List<Object> get fixArguments => [_replacement];

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_EIGHT_DIGIT_HEX;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Extract the information needed to build the edit.
    //
    if (node is! IntegerLiteral) {
      return;
    }
    var value = (node as IntegerLiteral).value;
    _replacement = '0x' + value.toRadixString(16).padLeft(8, '0');
    //
    // Build the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(node), _replacement);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithEightDigitHex newInstance() => ReplaceWithEightDigitHex();
}
