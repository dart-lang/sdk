// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

typedef TodoDiagnosticCode =
    DiagnosticWithArguments<
      LocatableDiagnostic Function({required String message})
    >;

/// Static helper methods and properties for working with [DiagnosticType.TODO]
/// codes.
class Todo {
  static const _codes = {
    'TODO': diag.todo,
    'FIXME': diag.fixme,
    'HACK': diag.hack,
    'UNDONE': diag.undone,
  };

  Todo._() {
    throw UnimplementedError('Do not construct');
  }

  /// Returns the TodoCode for [kind], falling back to [diag.todo].
  static TodoDiagnosticCode forKind(String kind) => _codes[kind] ?? diag.todo;
}
