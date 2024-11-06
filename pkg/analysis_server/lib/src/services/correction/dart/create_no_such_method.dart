// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateNoSuchMethod extends ResolvedCorrectionProducer {
  CreateNoSuchMethod({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.CREATE_NO_SUCH_METHOD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetClass = node;
    if (targetClass is! ClassDeclaration) {
      return;
    }
    // prepare environment
    var prefix = utils.oneIndent;
    var insertOffset = targetClass.end - 1;
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(insertOffset, (builder) {
        builder.selectHere();
        // insert empty line before existing member
        if (targetClass.members.isNotEmpty) {
          builder.write(eol);
        }
        // append method
        builder.write(prefix);
        builder.write('@override');
        builder.write(eol);
        builder.write(prefix);
        builder.write(
          'dynamic noSuchMethod(Invocation invocation) => '
          'super.noSuchMethod(invocation);',
        );
        builder.write(eol);
      });
    });
  }
}
