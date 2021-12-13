// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:meta/meta.dart';

extension SourceChangeExtension on CheckTarget<SourceChange> {
  @useResult
  CheckTarget<List<SourceFileEdit>> get edits {
    return nest(value.edits, (value) => 'has edits ${valueStr(value)}');
  }

  CheckTarget<SourceFileEdit> hasFileEdit(String path) {
    return nest(
      value.edits.singleWhere((e) => e.file == path),
      (selected) => 'has edit ${valueStr(selected)}',
    );
  }
}

extension SourceFileEditExtension on CheckTarget<SourceFileEdit> {
  @useResult
  CheckTarget<String> appliedTo(String applyTo) {
    var actual = SourceEdit.applySequence(applyTo, value.edits);
    return nest(
      actual,
      (selected) => 'produces ${valueStr(selected)}',
    );
  }
}
