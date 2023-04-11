// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertToWildcardPattern extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_WILDCARD_PATTERN;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_WILDCARD_PATTERN_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final namedType = node.parent;
    if (namedType is! NamedType) {
      return;
    }

    final typeLiteral = namedType.parent;
    if (typeLiteral is! TypeLiteral) {
      return;
    }

    final constantPattern = typeLiteral.parent;
    if (constantPattern is! ConstantPattern) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(constantPattern.end, (builder) {
        builder.write(' _');
      });
    });
  }
}
