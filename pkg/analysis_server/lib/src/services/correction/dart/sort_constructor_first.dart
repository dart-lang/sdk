// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SortConstructorFirst extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.SORT_CONSTRUCTOR_FIRST;

  @override
  FixKind get multiFixKind => DartFixKind.SORT_CONSTRUCTOR_FIRST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructor = coveredNode?.parent;
    var clazz = constructor?.parent;
    if (clazz is! ClassDeclaration || constructor is! ConstructorDeclaration) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      var deletionRange = range.endEnd(
        constructor.beginToken.previous!,
        constructor.endToken,
      );

      builder.addDeletion(deletionRange);
      builder.addSimpleInsertion(
        clazz.leftBracket.end,
        utils.getRangeText(deletionRange),
      );
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static SortConstructorFirst newInstance() => SortConstructorFirst();
}
