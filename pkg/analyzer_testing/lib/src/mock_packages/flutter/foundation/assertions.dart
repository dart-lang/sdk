// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final foundationAssertionsLibrary = MockLibraryUnit(
  'lib/src/foundation/assertions.dart',
  r'''
class FlutterErrorDetails {
  const FlutterErrorDetails({
    required Object exception,
    StackTrace? stack,
    String? library = 'Flutter framework',
    DiagnosticsNode? context,
    Iterable<String> Function(Iterable<String>)? stackFilter,
    Iterable<DiagnosticsNode> Function()? informationCollector,
    bool silent = false,
  });
}

class FlutterError extends Error implements AssertionError {
  static void reportError(FlutterErrorDetails details) {}
}
''',
);
