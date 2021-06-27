// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceNewWithConst extends CorrectionProducer {
  @override
  // TODO(brianwilkerson) This fix can produce changes that are inconsistent
  //  with the `unnecessary_const` lint. Fix it and then enable it for both
  //  uses.
  bool get canBeAppliedInBulk => false;

  @override
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_NEW_WITH_CONST;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_NEW_WITH_CONST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? targetNode = node;
    if (targetNode is ConstructorName) {
      targetNode = targetNode.parent;
    }
    if (targetNode is InstanceCreationExpression) {
      final keyword = targetNode.keyword;
      if (keyword != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.token(keyword), 'const');
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceNewWithConst newInstance() => ReplaceNewWithConst();
}
