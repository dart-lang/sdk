// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateNoSuchMethod extends ResolvedCorrectionProducer {
  CreateNoSuchMethod({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.createNoSuchMethod;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetClass = node.parent;
    if (targetClass is! ClassDeclaration) {
      return;
    }
    // prepare environment
    var body = targetClass.body;
    var prefix = utils.oneIndent;

    int insertOffset, insertEnd;
    bool insertBlockBody, insertLeadingEol;

    switch (body) {
      case EmptyClassBody():
        insertOffset = body.semicolon.offset;
        insertEnd = body.semicolon.end;
        insertBlockBody = true;
        insertLeadingEol = true;
      case BlockClassBody():
        insertOffset = targetClass.end - 1;
        insertEnd = insertOffset;
        insertBlockBody = false;
        insertLeadingEol =
            body.members.isNotEmpty ||
            body.leftBracket.end == body.rightBracket.offset;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(
        range.startOffsetEndOffset(insertOffset, insertEnd),
        (builder) {
          builder.selectHere();
          if (insertBlockBody) {
            builder.write(' {');
          }
          if (insertLeadingEol) {
            builder.writeln();
          }
          // append method
          builder.write(prefix);
          builder.write('@override');
          builder.writeln();
          builder.write(prefix);
          builder.write(
            'dynamic noSuchMethod(Invocation invocation) => '
            'super.noSuchMethod(invocation);',
          );
          builder.writeln();
          if (insertBlockBody) {
            builder.write('}');
          }
        },
      );
    });
  }
}
