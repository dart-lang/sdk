// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemoveUnnecessaryStringEscape extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_STRING_ESCAPE;

  @override
  FixKind get multiFixKind =>
      DartFixKind.REMOVE_UNNECESSARY_STRING_ESCAPE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var offset = diagnostic?.problemMessage.offset;
    if (offset == null) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(offset, 1));
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveUnnecessaryStringEscape newInstance() =>
      RemoveUnnecessaryStringEscape();
}
