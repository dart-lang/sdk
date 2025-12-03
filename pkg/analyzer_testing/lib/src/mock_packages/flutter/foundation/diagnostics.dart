// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final foundationDiagnosticsLibrary = MockLibraryUnit(
  'lib/src/foundation/diagnostics.dart',
  r'''
mixin Diagnosticable {
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

abstract class DiagnosticableTree with Diagnosticable {
  const DiagnosticableTree();

  List<DiagnosticsNode> debugDescribeChildren() => const [];
}

class DiagnosticPropertiesBuilder {
  void add(DiagnosticsNode property) {}
}

abstract class DiagnosticsNode {}

class DiagnosticsProperty<T> extends DiagnosticsNode {
  DiagnosticsProperty(
    String? name,
    T? value, {
    String? description,
    String? ifNull,
    String? ifEmpty,
    super.showName,
    super.showSeparator,
    Object? defaultValue = kNoDefaultValue,
    String? tooltip,
    bool missingIfNull = false,
    super.linePrefix,
    bool expandableValue = false,
    bool allowWrap = true,
    bool allowNameWrap = true,
    DiagnosticsTreeStyle super.style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  });
}
''',
);
