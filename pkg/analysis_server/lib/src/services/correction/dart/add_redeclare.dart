// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddRedeclare extends ResolvedCorrectionProducer {
  AddRedeclare({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.addRedeclare;

  @override
  FixKind get multiFixKind => DartFixKind.addRedeclareMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var member = node.thisOrAncestorOfType<ClassMember>();
    if (member == null) return;

    var token = member.firstTokenAfterCommentAndMetadata;
    var indent = utils.oneIndent;
    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      builder.addInsertion(token.offset, (builder) {
        builder.write('@');
        builder.writeImportedName([
          Uri.parse('package:meta/meta.dart'),
        ], 'redeclare');
        builder.write('$eol$indent');
      });
    });
  }
}
