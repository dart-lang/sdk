// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ChangeToNearestPreciseValue extends CorrectionProducer {
  /// The value to which the code will be changed.
  String _correction = '';

  @override
  List<Object> get fixArguments => [_correction];

  @override
  FixKind get fixKind => DartFixKind.CHANGE_TO_NEAREST_PRECISE_VALUE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    IntegerLiteral integer = node;
    var lexeme = integer.literal.lexeme;
    var precise = BigInt.from(IntegerLiteralImpl.nearestValidDouble(lexeme));
    _correction = lexeme.toLowerCase().contains('x')
        ? '0x${precise.toRadixString(16).toUpperCase()}'
        : precise.toString();
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(integer), _correction);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ChangeToNearestPreciseValue newInstance() =>
      ChangeToNearestPreciseValue();
}
