// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddClassModifier extends ResolvedCorrectionProducer {
  final String _modifier;

  AddClassModifier.base() : this._('base');

  AddClassModifier._(this._modifier);

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  List<String> get fixArguments => [_modifier];

  @override
  FixKind get fixKind => DartFixKind.ADD_CLASS_MODIFIER;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_CLASS_MODIFIER_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! NamedCompilationUnitMember) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(
          node.firstTokenAfterCommentAndMetadata.offset, '$_modifier ');
    });
  }
}
