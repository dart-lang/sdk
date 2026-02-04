// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SortConstructorFirst extends ResolvedCorrectionProducer {
  SortConstructorFirst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.sortConstructorFirst;

  @override
  FixKind get multiFixKind => DartFixKind.sortConstructorFirstMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructor = coveringNode?.parent;
    var clazz = constructor?.parent?.parent;
    if (clazz is! ClassDeclaration || constructor is! ConstructorDeclaration) {
      return;
    }

    var body = clazz.body;
    if (body is! BlockClassBody) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      var deletionRange = range.endEnd(
        constructor.firstNonCommentToken.previous!,
        constructor.endToken,
      );

      builder.addDeletion(deletionRange);
      builder.addSimpleInsertion(
        body.leftBracket.end,
        utils.getRangeText(deletionRange),
      );
    });
  }
}
