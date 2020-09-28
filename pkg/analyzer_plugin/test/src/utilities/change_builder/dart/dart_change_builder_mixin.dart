// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:test/test.dart';

import '../../../../support/abstract_context.dart';

mixin DartChangeBuilderMixin implements AbstractContextTest {
  SourceEdit getEdit(ChangeBuilder builder) {
    var edits = getEdits(builder);
    expect(edits, hasLength(1));
    return edits[0];
  }

  List<SourceEdit> getEdits(ChangeBuilder builder) {
    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);

    var fileEdits = sourceChange.edits;
    expect(fileEdits, hasLength(1));

    var fileEdit = fileEdits[0];
    expect(fileEdit, isNotNull);
    return fileEdit.edits;
  }

  /// Return a newly created Dart change builder.
  ChangeBuilder newBuilder() => ChangeBuilder(session: session);
}
