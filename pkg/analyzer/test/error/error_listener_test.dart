// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordingErrorListenerTest);
  });
}

@reflectiveTest
class RecordingErrorListenerTest {
  test_orderedAsReported() {
    var listener = RecordingDiagnosticListener();
    listener.onError(_MockDiagnostic(expectedIndex: 0, hashCode: 1));
    listener.onError(_MockDiagnostic(expectedIndex: 1, hashCode: 10));
    listener.onError(_MockDiagnostic(expectedIndex: 2, hashCode: -50));
    listener.onError(_MockDiagnostic(expectedIndex: 3, hashCode: 20));
    listener.onError(_MockDiagnostic(expectedIndex: 4, hashCode: 1));

    // Expect the errors are returned in the order they are reported, and not
    // affected by their hashcodes.
    expect(
      listener.diagnostics.cast<_MockDiagnostic>().map((e) => e.expectedIndex),
      [0, 1, 2, 3, 4],
    );
  }
}

/// An [Diagnostic] that allows setting an explicit hash code.
class _MockDiagnostic implements Diagnostic {
  @override
  int hashCode;

  int expectedIndex;

  _MockDiagnostic({required this.expectedIndex, required this.hashCode});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
