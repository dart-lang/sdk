// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class SortUnnamedConstructorFirst extends ResolvedCorrectionProducer {
  SortUnnamedConstructorFirst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.SORT_UNNAMED_CONSTRUCTOR_FIRST;

  @override
  FixKind get multiFixKind => DartFixKind.SORT_UNNAMED_CONSTRUCTOR_FIRST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var clazz = coveringNode?.parent?.parent;
    if (clazz is! ClassDeclaration) {
      return;
    }

    var members = clazz.members;
    var constructors = members.whereType<ConstructorDeclaration>().toList();

    var firstConstructor = constructors.firstOrNull;
    if (firstConstructor == null) {
      return;
    }

    var unnamedConstructor = constructors.firstWhereOrNull((constructor) {
      var name = constructor.name;
      return name == null || name.lexeme == 'new';
    });

    // Should not happen, if this fix is invoked.
    if (unnamedConstructor == null || unnamedConstructor == firstConstructor) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      var unnamedIndex = members.indexOf(unnamedConstructor);
      var moveRange = range.endEnd(
        members[unnamedIndex - 1],
        unnamedConstructor,
      );

      builder.addDeletion(moveRange);

      var firstIndex = members.indexOf(firstConstructor);
      var tokenBeforeFirst = firstIndex != 0
          ? members[firstIndex - 1].endToken
          : clazz.leftBracket;
      builder.addSimpleInsertion(
        tokenBeforeFirst.end,
        utils.getRangeText(moveRange),
      );
    });
  }
}
