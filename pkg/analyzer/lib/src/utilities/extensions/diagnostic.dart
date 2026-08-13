// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';

extension ListOfDiagnosticExtension on List<Diagnostic> {
  /// The diagnostics in this list with [Severity.error].
  Iterable<Diagnostic> get errors => where((d) => d.severity == Severity.error);
}
