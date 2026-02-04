// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithNotNullAwareElementOrEntry extends ResolvedCorrectionProducer {
  final _ReplaceWithNotNullAwareElementOrEntryKind _kind;

  ReplaceWithNotNullAwareElementOrEntry.entry({required super.context})
    : _kind = _ReplaceWithNotNullAwareElementOrEntryKind.entry;

  ReplaceWithNotNullAwareElementOrEntry.mapKey({required super.context})
    : _kind = _ReplaceWithNotNullAwareElementOrEntryKind.mapKey;

  ReplaceWithNotNullAwareElementOrEntry.mapValue({required super.context})
    : _kind = _ReplaceWithNotNullAwareElementOrEntryKind.mapValue;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.replaceWithNotNullAwareElementOrEntry;

  @override
  FixKind get multiFixKind =>
      DartFixKind.replaceWithNotNullAwareElementOrEntryMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveringNode;
    switch (_kind) {
      case _ReplaceWithNotNullAwareElementOrEntryKind.entry:
        // This covers both list and set entries.
        if (node is NullAwareElement) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addDeletion(range.token(node.question));
          });
        }
      case _ReplaceWithNotNullAwareElementOrEntryKind.mapKey:
        if (node is MapLiteralEntry && node.keyQuestion != null) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addDeletion(range.token(node.keyQuestion!));
          });
        }
      case _ReplaceWithNotNullAwareElementOrEntryKind.mapValue:
        if (node is MapLiteralEntry && node.valueQuestion != null) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addDeletion(range.token(node.valueQuestion!));
          });
        }
    }
  }
}

enum _ReplaceWithNotNullAwareElementOrEntryKind { entry, mapKey, mapValue }
