// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertToNullAwareMapEntryKey extends ResolvedCorrectionProducer {
  ConvertToNullAwareMapEntryKey({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.convertToNullAwareMapEntryKey;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = coveringNode?.parent;
    if (parent is MapLiteralEntry &&
        coveringNode == parent.key &&
        parent.keyQuestion == null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(coveringNode!.offset, '?');
      });
    }
  }
}

class ConvertToNullAwareMapEntryValue extends ResolvedCorrectionProducer {
  ConvertToNullAwareMapEntryValue({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.convertToNullAwareMapEntryValue;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = coveringNode?.parent;
    if (parent is MapLiteralEntry &&
        coveringNode == parent.value &&
        parent.valueQuestion == null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(coveringNode!.offset, '?');
      });
    }
  }
}
