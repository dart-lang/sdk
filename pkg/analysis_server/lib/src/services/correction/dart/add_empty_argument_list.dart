// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddEmptyArgumentList extends ResolvedCorrectionProducer {
  AddEmptyArgumentList({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.ADD_EMPTY_ARGUMENT_LIST;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_EMPTY_ARGUMENT_LIST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    int? offset;
    if (node is AnnotationImpl) {
      offset = node.end;
    } else if (node is FunctionTypeAlias) {
      // endToken is the trailing `;`.
      offset = node.endToken.previous?.end;
    }
    if (offset == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(offset!, '()');
    });
  }
}
