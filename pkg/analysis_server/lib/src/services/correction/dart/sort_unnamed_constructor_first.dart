// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class SortUnnamedConstructorFirst extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.SORT_UNNAMED_CONSTRUCTOR_FIRST;

  @override
  FixKind get multiFixKind => DartFixKind.SORT_UNNAMED_CONSTRUCTOR_FIRST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var clazz = coveredNode?.parent?.parent;
    if (clazz is! ClassDeclaration) return;

    final firstConstructor = clazz.childEntities
            .firstWhereOrNull((child) => child is ConstructorDeclaration)
        as ConstructorDeclaration?;
    if (firstConstructor == null ||
        firstConstructor.name == null ||
        firstConstructor.name?.name == 'new') return;

    final unnamedConstructor = clazz.childEntities.firstWhereOrNull(
            (child) => child is ConstructorDeclaration && child.name == null)
        as ConstructorDeclaration?;
    if (unnamedConstructor == null) return;

    await builder.addDartFileEdit(file, (builder) {
      var deletionRange = range.endEnd(
        unnamedConstructor.beginToken.previous!,
        unnamedConstructor.endToken,
      );

      builder.addDeletion(deletionRange);
      builder.addSimpleInsertion(
        firstConstructor.beginToken.previous!.end,
        utils.getRangeText(deletionRange),
      );
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static SortUnnamedConstructorFirst newInstance() =>
      SortUnnamedConstructorFirst();
}
