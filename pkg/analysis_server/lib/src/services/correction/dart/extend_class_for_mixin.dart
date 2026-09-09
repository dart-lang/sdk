// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic_data.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ExtendClassForMixin extends ResolvedCorrectionProducer {
  String _typeName = '';

  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_typeName];

  @override
  FixKind get fixKind => DartFixKind.extendClassForMixin;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic == null) {
      return;
    }

    var constraint =
        mixinApplicationNotImplementedInterfaceConstraint[diagnostic];
    if (constraint == null || constraint.element is! ClassElement) {
      return;
    }

    var declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration != null && declaration.extendsClause == null) {
      _typeName = constraint.getDisplayString();
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(
          declaration.namePart.typeParameters?.end ??
              declaration.namePart.typeName.end,
          ' extends $_typeName',
        );
      });
    }
  }
}
