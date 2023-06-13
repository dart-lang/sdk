// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveCharacter extends CorrectionProducer {
  String _codePoint = '';

  @override
  // Not predictably the correct action.
  bool get canBeAppliedInBulk => false;

  @override
  // Not predictably the correct action.
  bool get canBeAppliedToFile => false;

  @override
  List<Object> get fixArguments => [_codePoint];

  @override
  FixKind get fixKind => DartFixKind.REMOVE_CHARACTER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var problemMessage = diagnostic?.problemMessage;
    if (problemMessage == null) return;

    var offset = problemMessage.offset;
    var content = unitResult.content;
    var codeUnit = content.codeUnitAt(offset);
    _codePoint = codeUnit.toRadixString(16).toUpperCase();
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startOffsetEndOffset(offset, offset + 1));
    });
  }
}
