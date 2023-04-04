// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnnecessaryWildcardPattern extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_WILDCARD_PATTERN;

  @override
  FixKind get multiFixKind =>
      DartFixKind.REMOVE_UNNECESSARY_WILDCARD_PATTERN_MULTI;

  DartPattern? get _wildcardOrParenthesized {
    final wildcard = node;
    if (wildcard is! WildcardPattern) {
      return null;
    }

    DartPattern result = wildcard;
    while (true) {
      final parent = result.parent;
      if (parent is ParenthesizedPattern) {
        result = parent;
      } else {
        return result;
      }
    }
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final wildcard = _wildcardOrParenthesized;
    if (wildcard == null) {
      return;
    }

    final parent = wildcard.parent;

    if (parent is LogicalAndPattern) {
      await builder.addDartFileEdit(file, (builder) {
        if (parent.leftOperand == wildcard) {
          builder.addDeletion(range.startStart(parent, parent.rightOperand));
        } else if (parent.rightOperand == wildcard) {
          builder.addDeletion(range.endEnd(parent.leftOperand, parent));
        }
      });
    }
  }
}
