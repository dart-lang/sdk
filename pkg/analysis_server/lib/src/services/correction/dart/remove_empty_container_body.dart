// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveEmptyContainerBody extends ResolvedCorrectionProducer {
  late String containerKind;

  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  List<String>? get fixArguments => [containerKind];

  @override
  FixKind get fixKind => DartFixKind.removeEmptyContainerBody;

  @override
  FixKind get multiFixKind => DartFixKind.removeEmptyContainerBodyMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    containerKind = switch (node.parent) {
      ClassDeclaration() => 'class',
      MixinDeclaration() => 'mixin',
      ExtensionDeclaration() => 'extension',
      ExtensionTypeDeclaration() => 'extension type',
      // This should never happen.
      _ => 'container',
    };

    await builder.addDartFileEdit(file, (builder) {
      var start = node.beginToken.previous?.end ?? node.offset;
      var end = node.end;
      builder.addSimpleReplacement(range.startOffsetEndOffset(start, end), ';');
    });
  }
}
