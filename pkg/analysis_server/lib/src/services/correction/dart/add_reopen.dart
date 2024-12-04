// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddReopen extends ResolvedCorrectionProducer {
  AddReopen({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.ADD_REOPEN;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_REOPEN_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var decl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (decl == null) return;

    var token = decl.beginToken;
    if (token is CommentToken) token = token.parent!;

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.startLength(token, 0), (builder) {
        builder.write('@');
        builder.writeImportedName([
          Uri.parse('package:meta/meta.dart'),
        ], 'reopen');
        builder.writeln();
      });
    });
  }
}
