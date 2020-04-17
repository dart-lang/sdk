// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartFixListenerTest);
  });
}

@reflectiveTest
class DartFixListenerTest {
  DartFixListener listener;

  void setUp() {
    listener = DartFixListener(null);
  }

  void test_clear_clears_edits() {
    listener.addSourceChange(
        "Example",
        null,
        SourceChange("foo")
          ..edits = [
            SourceFileEdit("foo", 2, edits: [SourceEdit(0, 0, "foo")])
          ]);
    expect(listener.sourceChange.edits, hasLength(1));
    listener.reset();
    expect(listener.sourceChange.edits, isEmpty);
  }
}
