// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveConst extends _RemoveConst {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_CONST;

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveConst newInstance() => RemoveConst();
}

class RemoveUnnecessaryConst extends _RemoveConst {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_CONST;

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveUnnecessaryConst newInstance() => RemoveUnnecessaryConst();
}

abstract class _RemoveConst extends CorrectionProducer {
  @override
  Future<void> compute(ChangeBuilder builder) async {
    final expression = node;

    Token constToken;
    if (expression is InstanceCreationExpression) {
      constToken = expression.keyword;
    } else if (expression is TypedLiteralImpl) {
      constToken = expression.constKeyword;
    }

    // Might be an implicit `const`.
    if (constToken == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(constToken, constToken.next));
    });
  }
}
