// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemovePrimaryConstructorBody extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removePrimaryConstructorBody;

  @override
  FixKind get multiFixKind => DartFixKind.removePrimaryConstructorBodyMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var body = node.thisOrAncestorOfType<PrimaryConstructorBody>();
    if (body == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(utils.getLinesRange(body.sourceRange));
    });
  }
}
