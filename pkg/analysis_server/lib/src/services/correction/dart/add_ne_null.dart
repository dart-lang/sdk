// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddNeNull extends CorrectionProducerWithDiagnostic {
  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => DartFixKind.ADD_NE_NULL;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_NE_NULL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is Expression &&
        node.staticType?.nullabilitySuffix == NullabilitySuffix.none) {
      return;
    }
    var problemMessage = diagnostic.problemMessage;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(
          problemMessage.offset + problemMessage.length, ' != null');
    });
  }
}
