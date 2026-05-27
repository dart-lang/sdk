// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertDefaultToPrimaryConstructor extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind? get fixKind => DartFixKind.convertDefaultToPrimaryConstructor;

  @override
  FixKind? get multiFixKind =>
      DartFixKind.convertDefaultToPrimaryConstructorMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!isEnabled(Feature.primary_constructors)) return;
    if (node case ClassNamePart namePart) {
      var container = namePart.parent;
      var members = switch (container) {
        ClassDeclaration() => container.body.members,
        EnumDeclaration() => container.body.members,
        _ => null,
      };
      if (members == null) return;
      if (namePart is! PrimaryConstructorDeclaration &&
          (!members.any((e) => e is ConstructorDeclaration))) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(namePart.typeName.end, '()');
        });
      }
    }
  }
}
