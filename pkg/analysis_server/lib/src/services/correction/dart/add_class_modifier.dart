// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddClassModifier extends ResolvedCorrectionProducer {
  final String modifier;

  @override
  final FixKind fixKind;

  @override
  final FixKind multiFixKind;

  AddClassModifier.baseModifier({required CorrectionProducerContext context})
    : this._(
        context: context,
        modifier: 'base',
        fixKind: DartFixKind.addClassModifierBase,
        multiFixKind: DartFixKind.addClassModifierBaseMulti,
      );
  AddClassModifier.finalModifier({required CorrectionProducerContext context})
    : this._(
        context: context,
        modifier: 'final',
        fixKind: DartFixKind.addClassModifierFinal,
        multiFixKind: DartFixKind.addClassModifierFinalMulti,
      );
  AddClassModifier.sealedModifier({required CorrectionProducerContext context})
    : this._(
        context: context,
        modifier: 'sealed',
        fixKind: DartFixKind.addClassModifierSealed,
        multiFixKind: DartFixKind.addClassModifierSealedMulti,
      );

  AddClassModifier._({
    required super.context,
    required this.modifier,
    required this.fixKind,
    required this.multiFixKind,
  });

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;

    var declaration = node.ifTypeOrNull<CompilationUnitMember>() ?? node.parent;
    if (declaration is! CompilationUnitMember) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(
        declaration.firstTokenAfterCommentAndMetadata.offset,
        '$modifier ',
      );
    });
  }
}
